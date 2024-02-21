#!/bin/bash

if [ -z "$1" ]; then
  echo "No argument supplied"
  exit 1
fi

SECONDS=0

# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli
export subscriptionId=$1
export resourceGroup="vm"
export LOCATION=eastus
export VM_NAME=myVM
export VM_IMAGE=Debian11
export ADMIN_USERNAME=azureuser
export ADMIN_PASSWORD=Password@123


az account set --subscription "${subscriptionId}"
# Create resource group
az group create --name "${resourceGroup}" --location "${LOCATION}"

# Create VM
# https://learn.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-create
az vm create \
  --resource-group "${resourceGroup}" \
  --name "${VM_NAME}" \
  --image "${VM_IMAGE}" \
  --admin-username "${ADMIN_USERNAME}" \
  --admin-password "${ADMIN_PASSWORD}" \
  --public-ip-sku Standard

if [ $? -ne 0 ]; then
  echo "az create vm failed"
  exit 1
fi

export IP_ADDRESS=$(az vm show --show-details --resource-group $resourceGroup --name $VM_NAME --query publicIps --output tsv)

az vm run-command invoke \
  --resource-group $resourceGroup \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "sudo apt-get update && sudo apt-get install -y nginx"

# https://learn.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-open-port
az vm open-port \
  --port 80,22,443 \
  --resource-group $resourceGroup \
  --name $VM_NAME


echo "--> VM IP: $IP_ADDRESS"

# print elapsed time
duration=$SECONDS
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
