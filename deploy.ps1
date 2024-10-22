#---------------------------------------------------------
# This simulates the Azure marketplace experience for the customer in terms of parameters and deployment
#---------------------------------------------------------
# https://aka.ms/mgdirectoryadmin  |
# https://go.microsoft.com/fwlink/?linkid=2026780

#---------------------------------------------------------
# Elevate access to manage all Azure subscriptions and management groups https://go.microsoft.com/fwlink/?linkid=2026780
# When you elevate your access, you will be assigned the User Access Administrator role in Azure at root scope (/)
#---------------------------------------------------------

# Sign-in
Clear-AzContext -Force
Connect-AzAccount -UseDeviceAuthentication

. .\variables.ps1 # Dot Source the variables
Set-AzContext -SubscriptionId $variables.subscription_id

$TimeNow = Get-Date -Format yyyyMMdd-hhmm

#---------------------------------------------------------
# Resource Group Deployment
#---------------------------------------------------------

$paramObject = @{
  'subscriptionID'    = $variables.subscription_id
  'ResourceGroupName' = $variables.resourceGroupName
  'location'          = $variables.location
  'PrefixName'        = 'nswdac'
}

# Parameters necessary for deployment
$rgInputObject = @{
  Location                = $variables.location
  ResourceGroupName       = $variables.resourceGroupName
  TemplateFile            = '.\main.bicep'
  Name                    = $(Get-Date -Format yyyyMMdd-hhmm)
  TemplateParameterObject = $paramObject
  DeploymentDebugLogLevel = 'All'
  Verbose                 = $true
  Mode                    = 'Complete'   # Complete, Incremental In complete mode, Resource Manager deletes resources that exist in the resource group but are not specified in the template
}

# Deploy ResourceGroup
New-AzResourceGroupDeployment @rgInputObject

#---------------------------------------------------------
# Subscription Deployment
#---------------------------------------------------------

$paramObject = @{
  'subscriptionID'         = $variables.subscription_id
  'location'               = $variables.location
  'PrefixName'             = 'm-nswdac'
  'userAssignedMI_RG'      = 'nswdac-asal-serviceaccounts-rg'
  'webUserAssignedMI_name' = 'nswdac-webapp-mi'
  'deploy_Az_firewall'     = 'true'
  'deploymentEnvironment'  = 'non-prod'
}

# Parameters necessary for deployment
$subInputObject = @{
  Location                = $variables.location
  TemplateFile            = '.\main.bicep'
  Name                    = $(Get-Date -Format yyyyMMdd-hhmm)
  TemplateParameterObject = $paramObject
  DeploymentDebugLogLevel = 'All'
  Verbose                 = $true
}

# Deploy Subscription
New-AzSubscriptionDeployment @subInputObject

#---------------------------------------------------------
# Subscription Deployment - Merged Layers 0 & 1
#---------------------------------------------------------

$paramObject = @{
  'subscriptionID'                    = $variables.subscription_id
  'tenantID'                          = $variables.tenant_id
  'location'                          = $variables.location
  'PrefixName'                        = 'mmm-test'
  'deploy_Az_firewall'                = 'true'
  'deploymentEnvironment'             = 'non-prod'
  'KeyVaultName'                      = 'mmmkv'
  'keyVaultResourceGroupName'         = 'mm-test'
  'appConfigurationName'              = 'mmmac'
  'appConfigurationResourceGroupName' = 'mm-test'
  'userAssignedMI_name'               = 'nswdac-projects-mi'
  'userAssignedMI_RG'                 = 'nswdac-asal-serviceaccounts-rg'
  'webUserAssignedMI_name'            = 'nswdac-webapp-mi'
}

# Parameters necessary for deployment
$subInputObject = @{
  Location                = $variables.location
  TemplateFile            = '.\main01.bicep'
  Name                    = $(Get-Date -Format yyyyMMdd-hhmm)
  TemplateParameterObject = $paramObject
  DeploymentDebugLogLevel = 'All'
  Verbose                 = $true
}

# Deploy Subscription
New-AzSubscriptionDeployment @subInputObject

# # Deploy Subscription
# New-AzSubscriptionDeployment -Location $variables.location -TemplateFile '.\main.bicep' -Name $TimeNow -TemplateParameterObject $paramObject -Verbose -DeploymentDebugLogLevel All

# # Deploy Management Group
# New-AzManagementGroupDeployment -Location $variables.location -TemplateFile '.\SaaaS\main.bicep' -ManagementGroupId $variables.ManagementGroupId -Name $TimeNow -TemplateParameterObject $paramObject -Verbose -DeploymentDebugLogLevel All

# Deploy What-If
# New-AzManagementGroupDeployment -Location $variables.location -TemplateFile '.\SaaaS\main.bicep' -ManagementGroupId $variables.ManagementGroupId -Name $TimeNow -TemplateParameterObject $paramObject -Verbose -WhatIf


# Check your work
# At this point, you've routed all network traffic for Azure Virtual Desktop through the firewall. Let's make sure the firewall is working as expected. Outbound network traffic from the host pool should filter through the firewall to the Azure Virtual Desktop service. You can verify that the firewall allows traffic through to the service by checking the status of the service components.
"rdgateway", "rdbroker", "rdweb" | % { Invoke-RestMethod -Method:Get -Uri https://$_.wvd.microsoft.com/api/health } | ft -Property Health, TimeStamp, ClusterUrl
