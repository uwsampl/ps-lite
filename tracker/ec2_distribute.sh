rm hosts*
myIP="$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"
for region in `aws ec2 describe-regions --output text | cut -f3`
do
    echo "looking at region " $region
    aws ec2 describe-instances  --filters Name="instance-state-name",Values="running"  --query "Reservations[*].Instances[*].PrivateIpAddress" --output=text > hosts_raw --region $region

    if [ -s hosts_raw ]
    then
	cnt=`cat hosts_raw | wc -l`
	echo "instances found in this region: $cnt"
    else
	continue
    fi
    

    aws ec2 describe-instances --filters Name="instance-state-name",Values="running"  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text > hosts_raw1 --region $region

    aws ec2 describe-instances --filters Name="instance-state-name",Values="running"  --query "Reservations[*].Instances[*].Placement.GroupName" --output=text > hosts_placement_raw --region $region
    aws ec2 describe-instances --filters Name="instance-state-name",Values="running"  --query "Reservations[*].Instances[*].Placement.AvailabilityZone" --output=text > hosts_availability_raw --region $region
    #"Placement"
    sed -e 'y/\t/\n/' hosts_raw >> hosts_all
    sed -e 'y/\t/\n/' hosts_raw1 >> hosts_public
    sed -e 's/\t/:\n/g' hosts_placement_raw >> hosts_placement
    sed -e 's/\t/:\n/g' hosts_availability_raw >> hosts_availability

    #first, create local file of hosts
    #sed "/${myIP}/d" ./hosts_all > hosts
    if [ "$#" -lt 1 ]; then
	cp hosts_all hosts
    fi
done

if [ "$#" -lt 1 ]; then
    cp hosts_all hosts
fi

idx=`grep -Fxne "$myIP" hosts | cut -f1 -d:`

sed -i "${idx}d" hosts_availability
sed -i "${idx}d" hosts_placement
sed -i "${idx}d" hosts

