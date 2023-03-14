#!/bin/bash

RangeXY=(13000000 9000000)

CoordsRLS1XY=(6500000 6000000)
CoordsRLS2XY=(2500000 3650000)
CoordsRLS3XY=(5500000 3725000)

AngleForRLS1=(270 200)
AngleForRLS2=(135 90)
AngleForRLS3=(165 120)

DestinationRLS1=4000000
DestinationRLS2=7000000
DestinationRLS3=3000000


#!/bin/bash
declare -a TargetsId
RangeXY=(13000000 9000000)

CoordsRLS1XY=(6500000 6000000)
AngleForRLS1=(270 200)
DestinationRLS1=4000000

MaxKolTargets=0

while :
do 
    temp=`ls /tmp/GenTargets/Targets`
    if [[ "$temp" != "" && "$MaxKolTargets" == 0 ]]
    then 
        #find /tmp/GenTargets/Targets -type f -exec cp {} ./temp/ \;
        MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
        i=0
        for elem in $temp
        do
            id=${elem:11:6}
            TargetsId[$i]=$id
            i=$i+1
        done
        break
    fi
    echo "nofiles"
    sleep .5
done

echo "${TargetsId[@]}"