#!/bin/bash

MaxKolTargets=0

temp=`ls /tmp/GenTargets/Targets -t`
if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
then 
    MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
    echo "$MaxKolTargets -----------------------"
fi

if [[ "$MaxKolTargets" != "0" ]] 
then
    echo `$temp | head -n $MaxKolTargets`
    echo $MaxKolTargets
    echo "----------------------------------"
fi

