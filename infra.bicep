targetScope = 'resourceGroup'

//param tenantId string = subscription().tenantId

param envName string

@description('Location for all resources.')
param location string = resourceGroup().location


//
// Function App
//

resource funcStorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${envName}func'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${envName}-plan'
  location: location
  kind: 'windows'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    //reserved: true     // required for using linux
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${envName}-func-identity'
  location: location
}

resource functionApp 'Microsoft.Web/sites@2018-11-01' = {
  name: '${envName}-func'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      windowsFxVersion:'DOTNET|6.0'
      //alwaysOn: true  // not available on consumption
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${envName}-func'   
        }        
        {
          name: 'DeploymentEnvironmentName'
          value: envName
        } 
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}
