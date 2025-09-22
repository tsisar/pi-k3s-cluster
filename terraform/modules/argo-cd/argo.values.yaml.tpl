configs:
  params:
    server.insecure: ${server_insecure}

  cm:
    logoutRedirectURL: ${host}
    url: ${host}
    accounts.terraform: apiKey
    resource.links: |-
      - title: Open (rule 0)
        url: >-
          http://{{ index .resource.spec.hostnames 0 }}{{ (index (index .resource.spec.rules 0).matches 0).path.value | default "/" }}
        if: resource.kind == "HTTPRoute" && len(resource.spec.hostnames) > 0 && len(resource.spec.rules) > 0 && len((index .resource.spec.rules 0).matches) > 0
      - title: Open (rule 1)
        url: >-
          http://{{ index .resource.spec.hostnames 0 }}{{ (index (index .resource.spec.rules 1).matches 0).path.value | default "/" }}
        if: resource.kind == "HTTPRoute" && len(resource.spec.hostnames) > 0 && len(resource.spec.rules) > 1 && len((index .resource.spec.rules 1).matches) > 0
      - title: Open (hostname only)
        url: >-
          http://{{ index .resource.spec.hostnames 0 }}/
        if: resource.kind == "HTTPRoute" && len(resource.spec.hostnames) > 0
    resource.customizations: |-
      gateway.networking.k8s.io/HTTPRoute:
        health.lua: |
          hs = {}
          hs.status = "Progressing"
          hs.message = "HTTPRoute is being processed"
          
          -- If no status, assume it's just created
          if obj.status == nil then
            hs.status = "Progressing"
            hs.message = "HTTPRoute created, waiting for status"
            return hs
          end
          
          -- If no parents, it might be pending
          if obj.status.parents == nil or #obj.status.parents == 0 then
            hs.status = "Progressing"
            hs.message = "No parent gateways found"
            return hs
          end
          
          local allHealthy = true
          local anyAccepted = false
          local anyProgrammed = false
          local anyResolvedRefs = false
          local messages = {}
          
          for _, parent in ipairs(obj.status.parents) do
            local accepted = false
            local programmed = false
            local resolvedRefs = false
            local parentMessage = ""
            
            if parent.conditions ~= nil then
              for _, condition in ipairs(parent.conditions) do
                if condition.type == "Accepted" then
                  if condition.status == "True" then
                    accepted = true
                    anyAccepted = true
                  else
                    parentMessage = parentMessage .. "Not accepted: " .. (condition.message or "Unknown reason") .. "; "
                  end
                elseif condition.type == "Programmed" then
                  if condition.status == "True" then
                    programmed = true
                    anyProgrammed = true
                  else
                    parentMessage = parentMessage .. "Not programmed: " .. (condition.message or "Unknown reason") .. "; "
                  end
                elseif condition.type == "ResolvedRefs" then
                  if condition.status == "True" then
                    resolvedRefs = true
                    anyResolvedRefs = true
                  else
                    parentMessage = parentMessage .. "Refs not resolved: " .. (condition.message or "Unknown reason") .. "; "
                  end
                end
              end
            else
              parentMessage = "No conditions found; "
            end
            
            -- For Envoy Gateway, Accepted + ResolvedRefs is usually enough
            -- Programmed condition might not always be present
            local isHealthy = accepted and resolvedRefs
            if programmed then
              isHealthy = isHealthy and programmed
            end
            
            if not isHealthy then
              allHealthy = false
              if parentMessage == "" then
                if not accepted then
                  parentMessage = "Waiting for Accepted condition; "
                elseif not resolvedRefs then
                  parentMessage = "Waiting for ResolvedRefs condition; "
                elseif programmed and not programmed then
                  parentMessage = "Waiting for Programmed condition; "
                end
              end
              table.insert(messages, parentMessage)
            end
          end
          
          if allHealthy then
            hs.status = "Healthy"
            if anyProgrammed then
              hs.message = "All parent gateways are Accepted, ResolvedRefs & Programmed"
            else
              hs.message = "All parent gateways are Accepted & ResolvedRefs"
            end
          elseif anyAccepted and anyResolvedRefs then
            hs.status = "Degraded"
            hs.message = "Some parent gateways have issues: " .. table.concat(messages, " ")
          else
            hs.status = "Progressing"
            hs.message = "Waiting for gateway conditions: " .. table.concat(messages, " ")
          end
          
          return hs

  rbac:
    policy.csv: |
      g, terraform, role:admin