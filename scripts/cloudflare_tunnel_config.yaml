# Global defaults for origin requests
originRequest:

#   # TLS behavior
  noTLSVerify: true          
  originServerName: ${fqdn}  # must match TFE's certificate CN/SAN
  tlsTimeout: 30s

# You can omit originRequest here since it inherits from the global section
ingress:
  - hostname: ${fqdn}
    service: https://terraform-enterprise.${namespace}:443
  # Catch-all rule
  - service: http_status:404
