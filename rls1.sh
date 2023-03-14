#!/bin/bash
declare -a TargetsId
RangeXY=(13000000 9000000)

CoordsRLS1XY=(6500000 6000000)
AngleForRLS1=(270 200)
DestinationRLS1=4000000

MaxKolTargets=0
path="/tmp/GenTargets/Targets"
targetsFile="temp/targets.txt"

while :
do 
    temp=`ls $path -t`
    if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
    then 
        MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
    fi

    if [[ "$MaxKolTargets" -ne 0 ]] 
    then
        Topfiles=`echo "$temp" | head -n $MaxKolTargets`
        echo "" > $targetsFile
        for file in $Topfiles
        do
            id=${file:11:6}
            X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
            Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`
            echo "$id,$X,$Y" >> $targetsFile
        done

    fi


    sleep .5
done


