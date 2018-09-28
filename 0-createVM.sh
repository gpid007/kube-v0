#!/bin/bash

https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-resize
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest

# User var
ZUSER='user.name@domain.com'
ZPASS='XXXXXXXXXXX'
ACCOUNT='UI_B2B' # "UI_AAM"

# Resource var
RES_GROUP='kube-rg'
LOC='westeurope'

# VM var
VM_NAME='centos-0'
IMAGE='OpenLogic:CentOS:7.5:latest' #'Canonical:UbuntuServer:16.04-LTS:latest' #OpenLogic:CentOS:7.5:7.5.20180626
SIZE='Standard_B4ms' #'Standard_B2ms' #'Standard_B4ms' #'Standard_DS2_v2'
USER_NAME='greg'
USER_PASS='1232456789Aaa' #12 char

# Distro details
DISTRO='CentoS' #Ubuntu
PUBLISHER='OpenLogic' #Canonical
NVM=2 # number of vms

# Login and create resource group
az login -u $ZUSER -p $ZPASS
az account set -s $ACCOUNT


# Show VM locations, distros, sizes
az account list-locations
az vm list-sizes --location $LOC --output table
az vm image list --offer $DISTRO --publisher $PUBLISHER --all --output table
az vm list-sizes --location $LOC --output table


# Delete resource group
az group delete --name $RES_GROUP --yes --no-wait

# Create resource group
az group create --name $RES_GROUP --location $LOC


# VM create
for i in `seq 0 $NVM`; do
    echo -e "\t Creating $VM_NAME$i"
    az vm create \
        --resource-group $RES_GROUP \
        --name $VM_NAME$i \
        --image $IMAGE \
        --size $SIZE \
        --admin-username $USER_NAME \
        --admin-password $USER_PASS \
        --authentication-type password \
        --no-wait
    sleep 5
done


# Get VM info
az vm list
az vm list-usage --location $LOC
az vm show --resource-group $RES_GROUP --name $VM_NAME



# Show disk space
for i in `seq 0 2`; do
    echo "$RES_GROUP $VM_NAME$i"
    az disk show --resource-group $RES_GROUP --name $VM_NAME$i
    sleep 3
done


# Attach disk space
DISK_NAME='myDataDisk'

for i in `seq 0 2`; do
    az vm disk attach \
        -g $RES_GROUP \
        --vm-name $VM_NAME$i \
        --disk $DISK_NAME \
        --new \
        --size-gb 50
        sleep 3
done

