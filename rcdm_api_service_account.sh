#!/bin/bash
#
# DESCRIPTION:
# This script sets up a demo to demonstrate Rubrik API throught RSC service account.
#
# DISCLAIMER:
# This script is developed for demonstration purposes only and should be used
# with caution. Always ensure the security of your data and use appropriate
# encryption methods in production environments.
# This script is not supported under any support program or service. 
# All scripts are provided AS IS without warranty of any kind. 
# The author further disclaims all implied warranties including, without
# limitation, any implied warranties of merchantability or of fitness for a
# particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. 
# In no event shall its authors, or anyone else involved in the creation,
# production, or delivery of the scripts be liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business
# interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation,
# even if the author has been advised of the possibility of such damages.
#
# REQUIREMENTS:
# - Linux platform: Debian 7+, Ubuntu 20/04+, RHEL 8+ or CentOS 9+
# - bash, jq, curl
#
# SETUP:
# - create RSC service account and get the JSON key
#

#######################################################################################################################################
# PARAMETERS
#######################################################################################################################################

CLUSTER_ADDRESS="XXX.XXX.XXX.XXX"
TOKEN_FILE="token.last"

#######################################################################################################################################
# FUNCTIONS
#######################################################################################################################################

# Function to retrieve a token from the API
get_token() {
    local cluster_address="$1"
    local account_id="$2"
    local secret="$3"

    local response
    response=$(curl -ks -X POST "https://$cluster_address/api/v1/service_account/session" -H 'accept: application/json' -H 'Content-Type: application/json' -d '{
      "serviceAccountId": "'"$account_id"'",
      "secret": "'"$secret"'",
      "organizationId": "",
      "sessionTtlMinutes": 60
    }')

    echo "$response"
}

# Function to retrieve the token from the file if it exists
get_token_from_file() {
    if [[ -f "$TOKEN_FILE" ]]; then
        cat "$TOKEN_FILE"
        return 0
    fi
    return 1
}

# Function to execute an API request with the token
my_curl() {
    curl -X "$1" "$2" -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -k
}

#######################################################################################################################################
# MAIN
#######################################################################################################################################

# Initialize variables
JSON_FILE=""

# Handle script options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json-key)
            if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                JSON_FILE="$2"
                shift 2
            else
                echo "Error: The --json-key option requires a file as an argument."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 --json-key <json_file>"
            exit 1
            ;;
    esac
done

# Check if the JSON file has been provided
if [[ -z "$JSON_FILE" ]]; then
    echo "Error: You must specify a JSON file with --json-key"
    exit 1
fi

# Check if the JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
    echo "Error: File $JSON_FILE not found!"
    exit 1
fi

# Check if a token already exists
if ! TOKEN=$(get_token_from_file); then
    echo "No token found, retrieving a new one..."

    # Extract variables from the JSON file
    CLIENT_ID=$(jq -r '.client_id' "$JSON_FILE")
    CLIENT_SECRET=$(jq -r '.client_secret' "$JSON_FILE")
    NAME=$(jq -r '.name' "$JSON_FILE")
    ACCESS_TOKEN_URI=$(jq -r '.access_token_uri' "$JSON_FILE")

    # Retrieve a new token
    result=$(get_token "$CLUSTER_ADDRESS" "$CLIENT_ID" "$CLIENT_SECRET")

    # Check if the request was successful
    if [[ -z "$result" ]]; then
        echo "Error: Failed to retrieve the token via the API" >&2
        exit 1
    fi

    # Extract the token from the JSON response
    TOKEN=$(echo "$result" | jq -r '.token')

    # Check if the token is valid
    if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
        echo "Error: Unable to extract a valid token" >&2
        exit 1
    fi

    # Store the token in the file for future use
    echo "$TOKEN" > "$TOKEN_FILE"
    echo "New token saved in $TOKEN_FILE"
else
    echo "Token retrieved from $TOKEN_FILE"
fi

#######################################################################################################################################
# Exécution d'une requête API avec le token
#######################################################################################################################################

my_curl GET "https://$CLUSTER_ADDRESS/api/v1/cluster/me"
