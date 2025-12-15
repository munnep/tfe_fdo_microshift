
terraform { 
  cloud { 
    hostname = "tfe2.munnep.com" 
    organization = "test" 

    workspaces { 
      name = "test" 
    } 
  } 
}

resource "null_resource" "test" {
}


data "external" "slow_delay" {
  program = ["bash", "-c", <<EOT
    sleep 300
    echo '{ "result": "done" }'
EOT
  ]
}

output "delay_result" {
  value = data.external.slow_delay.result
}