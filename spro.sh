#!/bin/bash

RangeXY=(13000000 9000000)

BRSpeedL=8000
BRSpeedH=10000

CoordsSPROXY=(3250000 3350000)
RadiusSPRO=1000000

# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
pathD="/tmp/GenTargets/Destroy"
# Путь до файла с актуальными данными о целях (Пока не используется)
targetsFile="files/targets_spro.txt"
> $targetsFile
AtFile="temp/at_spro"
> $AtFile

ammunitionFile="temp/SPRO_Missiles"

#Boezapas
> $ammunitionFile
NumOfMissiles=10

while :
do 

    if ! [ -d $path ] 
    then
        #echo "..."
        sleep .5
        continue
    fi

    temp=`ls $path -t 2>/dev/null`
    if [[ $temp == "" ]]
    then 
        #echo "..."
        sleep .5
        continue
    fi

    Topfiles=`echo "$temp" | head -n $MaxKolTargets`

    echo $AtFile

    for idAT in `cat $AtFile`
    do
        echo $idAT
        TargetCheckAt=`echo $Topfiles | grep -o '......$' | grep $idAT | wc -l`
        echo $TargetCheckAt
        if [[ $TargetCheck -eq 0 ]]
        then
            echo -e "\e[4;35m __SPRO__ Hit ID:$idAT "
            echo $AtFile | sed 's/"$idAT"//' > $AtFile
        fi
    done


    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        # Flag=`grep $id $attentionTargets | wc -l`

        # if [[ $Flag -gt 0 ]]
        # then
        #     PrevXAt=`grep $id $attentionTargets | cut -d ";" -f2`
        #     PrevYAt=`grep $id $attentionTargets | cut -d ";" -f3`
        #     if [[ ($PrevXAt != $X) || ($PrevYAt != $Y) ]]
        #     then

        #     fi
        # fi

        deltaX=$(( $X - ${CoordsSPROXY[0]} ))
        deltaY=$(( $Y - ${CoordsSPROXY[1]} ))

        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusSPRO)^2)" | bc` -eq 1 ]]
        then
            TargetCheck=`grep $id $targetsFile | wc -l`

            if [[ $TargetCheck -eq 0 ]]
            then
                echo "$id;$X;$Y" >> $targetsFile
            else
                if [[ $TargetCheck -ge 1 ]]
                then
                    PrevX=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f2`
                    PrevY=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f3`
                    if [[ ($PrevX != $X) || ($PrevY != $Y) ]]
                    then
                        Distance=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`

                        if [[ ($Distance -ge $BRSpeedL) && ($Distance -le $BRSpeedH) ]]
                        then
                            if [[ $TargetCheck -eq 1 ]]
                            then
                            echo -e "\e[4;35m __SPRO__ Обнаружена цель Бал.блок ID:$id с координатами $X $Y"
                            else
                                echo -e "\e[4;35m __SPRO__ Miss ID:$id "
                            fi

                            echo -e "\e[4;35m __SPRO__ Shoots at the target ID:$id "
                           	touch "$pathD/$id"
                            echo "shoot" >> $ammunitionFile

                            echo "$id" >> $AtFile

                            L=`cat $ammunitionFile | wc -l`
                            Missilesremained=`echo "$NumOfMissiles - $L" | bc`
                            echo -e "\e[4;35m __SPRO__ $Missilesremained Missiles remained"

                            if [[ $Missilesremained -eq 0 ]]
                            then 
                                echo -e "\e[4;35m __SPRO__ Ammunition is empty"
                                > $ammunitionFile
                                echo -e "\e[4;35m __SPRO__ Ammunition replenished"
                            fi
                        fi
                        echo "$id;$X;$Y" >> $targetsFile
                    fi
                fi
            fi
        else 
            continue
        fi
    done
    echo -e "\033[0m ..."
    sleep .5
done