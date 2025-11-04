# Introduction

This repository will create a Terraform Enterprise environment locally. 
It is tested on MacOS with Minikube as kubernetes environment.  
Minikube is run on Podman Desktop.  
Cloudflare is used for DNS record and TFE certificate creation.  
You must have a cloudflare api token configured with DNS and Tunnel permissions.  

# Prepare code
## Git
Clone this repository

## terraform.tfvars
Copy the example file `variables.example` to `variables.auto.tfvars`. 

# Podman Desktop
https://podman-desktop.io/docs/installation/macos-install

Install with brew:
`brew install --cask podman-desktop`

Once installed, start the app and setup a podman machine with 6cpu, 12GB mem and 40GB storage.  
(Or adjust to your likings, just make sure Minikube (and TFE) settings will fit.)

Example:
```
podman machine init --cpus 8 --memory 12000 --disk-size 100
```

Alter it if needed
```
podman machine stop
podman machine set --cpus 6 --memory 8192 --disk-size 150
```


# Minikube
https://minikube.sigs.k8s.io/docs/drivers/podman/  

Install with brew:  
```
brew install minikube
```

Set the driver to podman:  
```
minikube config set driver podman
```

Start minikube with additional parameters:  
```
minikube start -p tfe --driver=podman --container-runtime=cri-o --kubernetes-version=v1.34.0 --cpus=4 --memory=8192
```

This will put the config in kubectl automatically so the kubernetes provider can use it.  
Add the full path of the config file to the variable `kubectl_config_path` in `variables.auto.tfvars`

If you want to access Minio and Postgres (locally) you will need to start a Minikube tunnel.  
This can be done with the following command:  
```
sudo minikube tunnel --profile=tfe
```  
The name you enter at `--profile` must match the name you used in the start command with `-p`, here `tfe`.
The tunnel will automatically detect all services defined as type Loadbalancer and expose them on localhost.

## View in Podman Desktop
Under the Containers section you can now see your created container, named `tfe`.
![](media/2025-10-27-14-18-58.png)  

Also in the section Kubenetes -> Nodes:  
![](media/2025-10-27-14-19-56.png)  

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
   minikube_delete_cluster = "minikube delete --profile=tfe"
   minikube_tunnel = "sudo minikube tunnel --profile=tfe"
   minio_console_url = "http://localhost:9001/"
   minio_password = "minioadmin123456"
   minio_user = "minioadmin"
   postgres_url = "postgresql://postgres:postgresql@localhost:5432/postgres"
   tfe_execute_script_to_create_user_admin = "./scripts/configure_tfe.sh tfe1.munnep.com patrick.munne@ibm.com admin secret$321"
   tfe_url = "https://tfe1.munnep.com"
```

Once the apply is complete, run the config script to create an admin user and test organization in TFE.  
The command is given in the output with `tfe_execute_script_to_create_user_admin`.  

Note:  
`terraform destroy` will not destroy the cloudflare tunnel.  
You will need to delete this manually with the command shown after the apply.  
Default is `cloudflared tunnel delete tfe-tunnel`.  

Also the minikube cluster must be deleted manually.  
`minikube delete -p tfe`  