config:
  argocd:
    serverAddr: "${server_addr}"
    insecure: ${server_insecure}
    grpcWeb: ${grpc_web}
  logLevel: "${log_level}"

  registries:
    - name: "nexus"
      prefix: "${nexus_prefix}"
      api_url: "${nexus_api_url}"
      ping: true
      default: true
      insecure: no
      credentials: secret:${argo_namespace}/${nexus_secret_name}#username:password

secret:
  create: true
