# Introduction

This repository will create a Terraform Enterprise environment locally. 
It is tested on MacOS with MicroShift as an OpenShift environment.  
OpenShift is run on Podman Desktop.  
Cloudflare is used for DNS record and TFE certificate creation.  
You must have a cloudflare api token configured with DNS and Tunnel permissions.  

# Prepare code
## Git
Clone this repository

## variables.auto.tfvars
Copy the example file `variables.example` to `variables.auto.tfvars`. 

# Podman Desktop
https://podman-desktop.io/docs/installation/macos-install

Install with brew:
`brew install --cask podman-desktop`

Once installed, start the app and setup a podman machine with 6cpu, 12GB mem and 40GB storage.  
(Or adjust to your likings, just make sure Minikube (and TFE) settings will fit.)

Example:
```
podman machine init --cpus 8 --memory 12000 --disk-size 100 --rootful
```

Alter it if needed
```
podman machine stop
podman machine set --cpus 6 --memory 8192 --disk-size 150
```


# Microshift
MicroShift is a lightweight, containerized version of OpenShift designed for edge computing and resource-constrained environments.

Here’s the comparison in short:

OpenShift: A full-featured enterprise Kubernetes platform for large-scale, centralized deployments—complete with developer tools, CI/CD pipelines, and full cluster management.

MicroShift: A trimmed-down, optimized variant of OpenShift that reuses its core components (like the API server, scheduler, and CRI-O) but runs with minimal resource overhead, suitable for edge devices, IoT gateways, or single-node setups.


To enable this in Podman: https://podman-desktop.io/docs/openshift/microshift

Enable the MINC extension  
![](media/2025-11-03-13-29-58.png)  


## View in Podman Desktop
Under the Containers section you can now see your created container
![](media/2025-11-04-10-46-13.png)   
This is also the place to stop and start the environment

Also in the section Kubenetes -> Nodes:  

![](media/2025-11-04-10-46-59.png)   

## Terraform Enterprise Agent
Terraform Enterprise on OpenShift requires a specific OpenShift agent as described [here](https://developer.hashicorp.com/terraform/enterprise/deploy/openshift#create-a-custom-hcp-terraform-agent)

If this environment is started on a Mac with ARM architecture it also requires a ARM build of the agent. The easiest is to use the following on docker hub [here](https://hub.docker.com/r/patrickmunne3/custom-agent-openshift)



# Cloudflare
Cloudflare is used for DNS a record and a tunnel, to be able to reach TFE from externally.  

Fill your Cloudflare account id in at `cloudflare_account_id` in the `variables.auto.tfvars`.  
Fill your Cloudflare api token in at `cloudflare_api_token` in the `variables.auto.tfvars`.  
(Your api token must have edit permissions for DNS and Tunnels.). 

## Create Cloudflare api token
Log in to your Cloudflare account and go to: https://dash.cloudflare.com/profile/api-tokens  
![](media/2025-10-27-13-45-05.png)  
Click `Create Token`.

![](media/2025-10-27-13-46-19.png)  
Click `Get started` under `Custom token`.  

![](media/2025-10-27-14-55-35.png)
Give your token a useful name.
And select the permissions:
- Account   Cloudflare Tunnel   edit  
- Zone      DNS                 edit

There are other options to further restrict access, like which Zone, Account or client ip have access.
You can also set a TTL on your token.
Edit these as you see fit.

Click `Continue to summary`.  
Click `Create Token`.  
Copy the token and enter it as the value for `cloudflare_api_token`.  


# Terraform Enterprise
Check the `variables.auto.tfvars` file and adjust all settings to your needs.  

```
terraform init  
terraform apply  
```

```
Plan: 22 to add, 0 to change, 0 to destroy.

Outputs:
   cloudflare_delete_tunnel_command = "cloudflared tunnel delete tfe-tunnel"
   cloudflare_list_tunnels_command = "cloudflared tunnel list"
   cloudflare_login_command = "cloudflared login"
   minio_console_url = "http://localhost:9001/"
   minio_password = "minioadmin123456"
   minio_user = "minioadmin"
   postgres_url = "postgresql://postgres:postgresql@localhost:5432/postgres"
   tfe_execute_script_to_create_user_admin = "./scripts/configure_tfe.sh tfe2.munnep.com patrick.munne@ibm.com admin secret$321"
   tfe_url = "https://tfe2.munnep.com"
```

Once the apply is complete, run the config script to create an admin user and test organization in TFE.  
The command is given in the output with `tfe_execute_script_to_create_user_admin`.  

Note:  
`terraform destroy` will not destroy the cloudflare tunnel.  
You will need to delete this manually with the command shown after the apply.  
Default is `cloudflared tunnel delete tfe-tunnel`.  
