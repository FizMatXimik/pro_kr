#!/bin/bash
RangeXY=(13000000 9000000)
MaxKolTargets=0
path="/tmp/GenTargets/Targets"
targetsFile="temp/targets.txt"

PI=`echo "scale=1000; 4*a(1)" | bc -l`

tan ()
{
    echo "scale=5;s($1)/c($1)" | bc -l
}

CoordsRLS1XY=(6500000 6000000)
AngleForRLS=(170 370)
DestinationRLS1=4000000

AngleForRLSRadian=(`echo "scale=5;(360-(${AngleForRLS[0]}-90))*${PI}/180" | bc -l` `echo "scale=5;(360-(${AngleForRLS[1]}-90))*${PI}/180" | bc -l`)
TanForAngles=(`tan ${AngleForRLSRadian[0]}` `tan ${AngleForRLSRadian[1]}`)

while :
do 
    Targets=()
    temp=`ls $path -t`
    if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
    then 
        MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
    fi
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
                if [[ 1 -eq `echo "$deltaY<=(${TanForAngles[0]}*$deltaX)" | bc` || 1 -eq `echo "$deltaY>=(${TanForAngles[1]}*$deltaX)" | bc` ]]
                then
                    echo "ne whodit $id X$X Y$Y"
                else
                    echo "ebat whodit $id X$X Y$Y"
                fi
            else 
                echo "hyine ebana $id X$X Y$Y"
            fi
        done
        echo "------------------------------------"
    fi

    sleep .5
done


