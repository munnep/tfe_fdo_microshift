
#!/usr/bin/env bash

if [ -z $1 ] || [ -z $2 ] || [ -z $4 ] ; then
  echo "##################################################################################"
  echo "##    Script is missing an argument                                             ##"                               
  echo "##    syntax should be as the following:                                        ##"
  echo "##    ./configure_tfe.sh <tfe_fqdn> <email address> <password admin user>       ##" 
  echo "##                                                                              ##"
  echo "##    example                                                                   ##"                   
  echo "##    ./configure_tfe.sh tfe28.aws.munnep.com patrick@test.com Password#1       ##"
  echo "##################################################################################"
  exit 1
fi

HOSTNAME=$1
EMAIL_ADDRESS=$2
ADMIN_USER=$3
PASSWORD=$4

# We have to wait for TFE be fully functioning before we can continue
while true; do
    if curl -skI "https://$HOSTNAME/admin" 2>&1 | grep -w "200\|301" ; 
    then
        echo "TFE is up and running"
        echo "Will continue in a few seconds with the final steps"
        sleep 5
        break
    else
        echo "TFE is not available yet. Please wait..."
        sleep 4
    fi
done


# Get activation token
echo "Getting the initial activation token"
INITIAL_TOKEN=`curl -s https://$HOSTNAME/admin/retrieve-iact`

# Create iser admin and get the token
echo "Create the first user called admin and geting the token"
ADMIN_TOKEN=`curl -k --header "Content-Type: application/json" --request POST --data "{\"username\": \"$ADMIN_USER\",\"email\": \"$EMAIL_ADDRESS\", \"password\": \"$PASSWORD\"}"   --url https://$HOSTNAME/admin/initial-admin-user?token=$INITIAL_TOKEN`

TOKEN=`echo $ADMIN_TOKEN | jq -r .token`

# create organization test
echo "Creating organization test"
curl -k \
 --header "Authorization: Bearer $TOKEN" \
 --header "Content-Type: application/vnd.api+json" \
 --request POST \
 --data "{\"data\": {\"type\": \"organizations\", \"attributes\": {\"name\": \"test\",\"email\": \"$EMAIL_ADDRESS\"}}}" \
 https://$HOSTNAME/api/v2/organizations      

 echo "Script finished"
