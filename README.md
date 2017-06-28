# Scripted Provisioning of Azure File Share

It's a 2 step process since ARM can only create the storage account. ARM does not allow creation of the share. 

Run create-share.sh rg-name share-name to:

1. execute the ARM template to create the storage account. The template will `output` the storage key and the name of the account. 

2. Add the share to the storage account.

If you'd like to run the script here, simply edit `storageAccountName` in `storage.parameters.json` to define your storage account name. 