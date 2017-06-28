#!/bin/bash


if [[ $# != 2 ]]; then
    echo "usage: ${0##*/} <resource-group-name> <share-name>"
    exit 1
fi

rgName=$1

#exit in case of error
set -e
az group create -l westus -n $rgName
output=$(az group deployment create -g $rgName --template-file storage.json --parameters @storage.parameters.json)

# get storage account name from template
storage_account=$(jq '.properties.outputs.accountName.value')
# get key from output
access_key=$(echo $output | jq '.properties.outputs.storagekey.value')
share_name="$2"

# HTTP Request headers
request_date=$(TZ=GMT date "+%a, %d %h %Y %H:%M:%S %Z")
x_ms_date_h="x-ms-date:$request_date"
storage_service_version="2015-02-21"
x_ms_version_h="x-ms-version:$storage_service_version"
file_service_url="file.core.windows.net"



function create_signature {

    local request_method="PUT"

    # Build the signature string
    local canonicalized_headers="${x_ms_date_h}\n${x_ms_version_h}"
    local canonicalized_resource="/${storage_account}/${share_name}"

    # This would be SharedKey, let's try SharedKeyLite first
    #local string_to_sign="${request_method}\n\n\n\n\n\n\n\n\n\n\n\n${canonicalized_headers}\n${canonicalized_resource}\ncomp:list\nrestype:container"
    local string_to_sign="${request_method}\n\n\n\n\n\n\n\n\n\n\n\n${canonicalized_headers}\n${canonicalized_resource}\nrestype:share"

    # Decode the Base64 encoded access key, convert to Hex.
    local decoded_hex_key="$(echo -n $access_key | base64 -d -w0 | xxd -p -c256)"

    # Create the HMAC signature for the Authorization header
    signature=$(printf "$string_to_sign" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$decoded_hex_key" -binary |  base64 -w0)
}


# populate $signature
create_signature

authorization="SharedKey"
authorization_header="Authorization: $authorization $storage_account:$signature"


curl \
  -X PUT \
  -H "$x_ms_date_h" \
  -H "$x_ms_version_h" \
  -H "$authorization_header" \
  -H "Content-Length: 0" \
  "https://${storage_account}.${file_service_url}/${share_name}?restype=share"