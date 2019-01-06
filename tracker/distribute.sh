#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
isEc2=`curl -s --max-time 1 http://169.254.169.254/latest/meta-data/instance-id`
MAC=""
IP=""
if [ "$isEc2" != "" ] && ! [[ "$isEc2" =~ "404 - File or directory not found." ]];
then
    bash $dir/ec2_distribute.sh
else
    bash $dir/az_distribute.sh
fi
