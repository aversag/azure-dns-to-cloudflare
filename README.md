# Azure DNS to Cloudflare Export Script
This repository contains a small Bash script designed to facilitate the export of Azure DNS records into a format that can be easily imported into Cloudflare.

## prerequisites

- Azure CLI
- jq

## Usage

1. Clone the repository
2. Run the script with 2 parameters:
    - The name of the Azure DNS zone
    - The resource group that the zone is in

```bash
./azure-dns-to-cloudflare.sh mydomain.com myResourceGroup
```
