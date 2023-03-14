#!/bin/bash
declare -a TargetsId
RangeXY=(13000000 9000000)

CoordsRLS1XY=(6500000 6000000)
AngleForRLS1=(270 200)
DestinationRLS1=4000000

kLine1=1
kLine2=-1

MaxKolTargets=0
path="/tmp/GenTargets/Targets"
targetsFile="temp/targets.txt"

while :
do 
    Targets=()
    temp=`ls $path -t`
    if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
    then 
        MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
    fi
    #echo `date`
    if [[ "$MaxKolTargets" -ne 0 ]] 
    then
        Topfiles=`echo "$temp" | head -n $MaxKolTargets`
        for file in $Topfiles
        do
            id=${file: -6}
            X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
            Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`
            deltaX=$(( ${CoordsRLS1XY[0]} - $X ))
            deltaY=$(( ${CoordsRLS1XY[1]} - $Y ))
            if [[ `echo "sqrt(($deltaX)^2 + ($deltaY)^2)" | bc` -le $DestinationRLS1 ]]
            then
                #echo "hihi $id"
                if [[ $deltaY -le $(( $kLine1 * $deltaX / 10 )) && $deltaY -le $(( $kLine2 * $deltaX / 10 )) ]]
                then
                    echo "ne whodit $id"
                else
                    echo "ebat whodit $id"
                fi
            else 
                echo "hyine ebana $id"
            fi
        done

    fi


    echo "---------------------------"

    sleep .5
done


