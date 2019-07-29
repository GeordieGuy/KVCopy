# KVCopy
KVCopy copies Azure Key Vault secrets between Key Vaults, even if they are in different subscriptions and the key vault backup and restore functionality doesn't work

## Usage

KVCopy.ps1 -SourceSubID [source subscription ID] -SourceKV [source key vault name] -DestinationSubID [destination subscription ID] -DestinationKV [destination key vault name]
