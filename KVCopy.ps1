#requires -version 2
<#
.SYNOPSIS
  Copies secrets between keyvaults
.DESCRIPTION
For some reason Microsoft don't allow Azure Keyvault backups and restores across subscriptions, this script facilitates that.
.PARAMETER SourceSubID
The source Azure subscription ID that the source keyvault is in

.PARAMETER DestinationSubID
The destination Azure subscription ID that the source keyvault is in

.PARAMETER SourceKV
The source keyvault to copy from

.PARAMETER DestinationKV
The destination keyvault to copy to
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Stop Noisily, and ask if we're unsure.
$ErrorActionPreference = "Stop"
$ConfirmPreference = "High"
#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#----------------------------------------------------------------[Main]------------------------------------------------------------

param (
  [string][Parameter(Mandatory = $true)] $SourceKV,
  [string][Parameter(Mandatory = $true)] $DestinationKV,
  [string][Parameter(Mandatory = $true)] $SourceSubID,
  [string][Parameter(Mandatory = $true)] $DestinationSubID
)

$sourceVault = Get-AzKeyvault -VaultName $sourceKV
$destinationVault = Get-AzKeyvault -VaultName $destinationKV

# Test that PS modules are installed
if (Get-Module -ListAvailable -Name "Az.Keyvault") {
  Write-Host "Az.Keyvault modules exist"
}
else {
  $Choice = Read-Host -Prompt "You need to install the Az.Keyvault module before running this, do you want to do that now? Y/N"
  if ($Choice.ToLower() -eq 'y') {
    Install-Module Az.Keyvault -Force -Confirm:$false
  } else {
    Write-Host "Suit yourself."
    Exit-PSSession
  }
}

try {
  Select-AzSubscription -Subscription $SourceSubID
} catch {
  Write-Host "Was not able to log into source subscription. Please confirm your permissions."
}

$sourceSecrets = @{}

Write-Host "Getting source secrets" -ForegroundColor Green
try {
  foreach ($secret in Get-AzKeyvaultSecret -VaultName $sourceVault) {
    $sourceSecrets.Add($Secret.Name,$(Get-AzKeyvaultSecret -VaultName $sourceVault -SecretName $secret.Name).SecretValueText)
  } } catch {
  Write-Host "Was not able to get source secrets, please confirm you are logged in and then check the source subscription and keyvault name, then try again"
}

try {
  Select-AzSubscription -Subscription $DestinationSubID
} catch {
  Write-Host "Was not able to log into destination subscription. Please confirm your permissions."
}

try {
  foreach ($entry in $sourceSecrets.Keys) {
    $password = $sourceSecrets[$entry]
    $passwordValue = ConvertTo-SecureString $password -AsPlainText -Force
    Set-AzKeyvaultSecret -VaultName $destinationVault -Name $entry -SecretValue $passwordValue
  } } catch {
  Write-Host "Was not able to insert secrets into destination keyvault, please confirm you are logged in and then check the source subscription and keyvault name, then try again"
}
