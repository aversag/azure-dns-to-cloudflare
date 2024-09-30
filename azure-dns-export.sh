#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <ZONE_NAME> <RESOURCE_GROUP>"
  exit 1
fi

ZONE_NAME="$1"
RESOURCE_GROUP="$2"
ORIGIN="$ZONE_NAME."
TTL=3600  # Set default TTL
SERIAL=$(date +%Y%m%d01)  # Serial based on current date
OUTPUT_FILE="zonefile_bind_$ZONE_NAME.zone"

# Start writing the BIND zone file
echo "\$ORIGIN $ORIGIN" > $OUTPUT_FILE
echo "\$TTL $TTL" >> $OUTPUT_FILE

# Add SOA record manually (adjust the SOA fields as needed)
echo "@    IN SOA ns1.$ZONE_NAME. admin.$ZONE_NAME. (" >> $OUTPUT_FILE
echo "            $SERIAL ; Serial number" >> $OUTPUT_FILE
echo "            3600    ; Refresh time" >> $OUTPUT_FILE
echo "            1800    ; Retry time" >> $OUTPUT_FILE
echo "            1209600 ; Expire time" >> $OUTPUT_FILE
echo "            86400   ; Minimum TTL" >> $OUTPUT_FILE
echo ")" >> $OUTPUT_FILE

# Read DNS records from the JSON file
az network dns record-set list --resource-group $RESOURCE_GROUP --zone-name $ZONE_NAME -o json | jq -c '.[]' | while read -r record; do
    NAME=$(echo $record | jq -r '.name // "@."')
    TYPE=$(echo $record | jq -r '.type' | sed 's/Microsoft.Network\/dnszones\///g')
    TTL=$(echo $record | jq -r '.TTL // 3600')

    case "$TYPE" in
        "A")
            ADDRESS=$(echo $record | jq -r '.ARecords[].ipv4Address // empty')
            if [[ -n "$ADDRESS" ]]; then
                echo "$NAME IN A $ADDRESS" >> $OUTPUT_FILE
            fi
            ;;
        "AAAA")
            ADDRESS=$(echo $record | jq -r '.AAAARecords[].ipv6Address // empty')
            if [[ -n "$ADDRESS" ]]; then
                echo "$NAME IN AAAA $ADDRESS" >> $OUTPUT_FILE
            fi
            ;;
        "CNAME")
            CNAME=$(echo $record | jq -r '.CNAMERecord.cname // empty')
            if [[ -n "$CNAME" ]]; then
                echo -n "$NAME IN CNAME $CNAME" >> $OUTPUT_FILE
                echo '.' >> $OUTPUT_FILE
            fi
            ;;
        "MX")
            PREFERENCE=$(echo $record | jq -r '.mxRecords[].preference // empty')
            EXCHANGE=$(echo $record | jq -r '.mxRecords[].exchange // empty')
            if [[ -n "$PREFERENCE" && -n "$EXCHANGE" ]]; then
                echo "$NAME IN MX $PREFERENCE $EXCHANGE" >> $OUTPUT_FILE
            fi
            ;;
        "TXT")
            echo $record | jq -r '.TXTRecords[].value[]' | while read -r TXT_VALUE; do
                if [[ -n "$TXT_VALUE" ]]; then
                    echo "$NAME IN TXT \"$TXT_VALUE\"" >> $OUTPUT_FILE
                fi
            done
            ;;
    esac

done

# Display the zone file content
cat $OUTPUT_FILE
