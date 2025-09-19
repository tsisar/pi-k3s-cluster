configs:
  params:
    server.insecure: ${server_insecure}

  cm:
    logoutRedirectURL: ${host}
    url: ${host}
    accounts.terraform: apiKey

  rbac:
    policy.csv: |
      g, terraform, role:admin