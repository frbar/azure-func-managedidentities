# Purpose

Set up User Assigned identity for an Azure Function using Bicep.

# Build and Deploy

```powershell
az login

$subscription = "Training Subscription"
az account set --subscription $subscription

$rgName = "frbar-func-mi"
$envName = "frbarmi003"
$location = "West Europe"

function Deploy-Infra() { 
    az group create --name $rgName --location $location
    az deployment group create --resource-group $rgName --template-file infra.bicep --mode complete --parameters envName=$envName    
}

Deploy-Infra

```

# Tear down

```powershell
az group delete --name $rgName
```
