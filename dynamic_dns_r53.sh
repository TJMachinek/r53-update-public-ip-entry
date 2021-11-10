#!/bin/bash

re_number='^[0-9]+$'
if ! [[ ${SLEEP_BETWEEN_RUNS:=0} =~ $re_number ]] ; then
  echo "error: SLEEP_BETWEEN_RUNS must be a number" >&2; exit 1
fi

function r53_update_public_ip_entry {

  #Variable Declaration - Change These
  TYPE="A"

  #get current IP address
  IP=$(curl -s http://checkip.amazonaws.com/)

  #validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
  if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "got an malformed IP:"
    echo $IP
    return
  fi

  echo "Current Public IP: ${IP}"

  #get current
  R53_IP=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --output text --query "ResourceRecordSets[?Name == '${NAME}'].[ResourceRecords]")

  echo "Current R53 IP:    ${R53_IP}"

  #check if IP is different from Route 53
  if [ "$IP" = "$R53_IP" ]; then
    echo "IP Has Not Changed."
    return
  fi


  echo "IP Changed, Updating Records"

  #prepare route 53 payload
  cat > /tmp/route53_changes.json << EOF
      {
        "Comment":"Updated From DDNS Shell Script",
        "Changes":[
          {
            "Action":"UPSERT",
            "ResourceRecordSet":{
              "ResourceRecords":[
                {
                  "Value":"$IP"
                }
              ],
              "Name":"$NAME",
              "Type":"$TYPE",
              "TTL":$TTL
            }
          }
        ]
      }
EOF

  #update records
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/route53_changes.json >> /dev/null
}

while true; do

  r53_update_public_ip_entry || exit 1

  if [ $SLEEP_BETWEEN_RUNS -eq 0 ]; then
    echo "exiting"
    exit
  fi

  echo "Waiting for ${SLEEP_BETWEEN_RUNS} seconds before checking again."
  sleep $SLEEP_BETWEEN_RUNS

done