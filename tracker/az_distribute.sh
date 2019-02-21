#!/bin/bash
az vm list -d --query "[?powerState=='VM running'].privateIps"  --output tsv > hosts


myIP=`hostname -i`
myIP="$(echo -e "${myIP}" | tr -d '[:space:]')"
awk -F "\"*,\"*" '{print $1}' hosts > hosts_tmp
cp hosts_tmp hosts
idx=`grep -Fxne "$myIP" hosts | cut -f1 -d:`
# sed -i "${idx}d" hosts_availability
# sed -i "${idx}d" hosts_placement
echo "removing index $idx ($myIP)"
sed -i "${idx}d" hosts
