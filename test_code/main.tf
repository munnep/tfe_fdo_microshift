
terraform { 
  cloud { 
    hostname = "tfe1.munnep.com" 
    organization = "test" 

    workspaces { 
      name = "test" 
    } 
  } 
}

resource "null_resource" "test" {
}