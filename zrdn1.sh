#!/bin/bash

RangeXY=(13000000 9000000)

PlaneSpeedL=50
PlaneSpeedH=250
KRSpeedL=250
KRSpeedH=1000

CoordsZRDNXY=(5500000 3725000)
RadiusZRDN=500000

# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
pathD="/tmp/GenTargets/Destroy"
# Путь до файла с актуальными данными о целях (Пока не используется)
targetsFile="files/targets_zrdn1.txt"
ammunitionFile="temp/ZRDN1_Missiles"
echo "" > $targetsFile

#Boezapas
> $ammunitionFile
NumOfMissiles=3


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

    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        deltaX=$(( $X - ${CoordsZRDNXY[0]} ))
        deltaY=$(( $Y - ${CoordsZRDNXY[1]} ))

        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusZRDN)^2)" | bc` -eq 1 ]]
        then
            TargetCheck=`grep $id $targetsFile | wc -l`

            if [[ $TargetCheck -eq 0 ]]
            then
                echo "$id;$X;$Y" >> $targetsFile
            else
                if [[ $TargetCheck -eq 1 ]]
                then
                    PrevX=`grep $id $targetsFile | cut -d ";" -f2`
                    PrevY=`grep $id $targetsFile | cut -d ";" -f3`
                    if [[ ($PrevX != $X) || ($PrevY != $Y) ]]
                    then
                        Distance=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`

                        if [[ ($Distance -ge $PlaneSpeedL) && ($Distance -le $PlaneSpeedH) ]]
                        then
                            echo -e "\e[1;32m __ZRDN_1__ Обнаружена цель Самолет ID:$id с координатами $X $Y"
                            echo -e "\e[1;32m __ZRDN_1__ Shoots at the target ID:$id "
                            touch "$pathD/$id"
                            echo "shoot" >> $ammunitionFile
                            L=`cat $ammunitionFile | wc -l`
                            Missilesremained=`echo "$NumOfMissiles - $L" | bc`
                            echo -e "\e[1;32m __ZRDN_1__ $Missilesremained Missiles remained"
                            if [[ $Missilesremained -eq 0 ]]
                            then 
                                echo -e "\e[1;32m __ZRDN_1__ Ammunition is empty"
                                > $ammunitionFile
                                echo -e "\e[1;32m __ZRDN_1__Ammunition replenished"
                            fi
                        else
                            if [[ ($Distance -ge $KRSpeedL) && ($Distance -le $KRSpeedH) ]]
                            then
                                echo -e "\e[1;32m __ZRDN_1__ Обнаружена цель К.ракета ID:$id с координатами $X $Y"
                                echo -e "\e[1;32m __ZRDN_1__ Shoots at the target ID:$id "
                                touch "$pathD/$id"
                                echo "shoot" >> $ammunitionFile
                                L=`cat $ammunitionFile | wc -l`
                                Missilesremained=`echo "$NumOfMissiles - $L" | bc`
                                echo -e "\e[1;32m __ZRDN_1__ $Missilesremained Missiles remained"
                                if [[ $Missilesremained -eq 0 ]]
                                then 
                                    echo -e "\e[1;32m __ZRDN_1__ Ammunition is empty"
                                    > $ammunitionFile
                                    echo -e "\e[1;32m __ZRDN_1__ Ammunition replenished"
                                fi
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