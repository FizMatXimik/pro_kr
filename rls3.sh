#!/bin/bash

# Размер карты
RangeXY=(13000000 9000000)

PlaneSpeedL=50
PlaneSpeedH=250
KRSpeedL=250
KRSpeedH=1000
BRSpeedL=8000
BRSpeedH=10000

# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
# Путь до файла с актуальными данными о целях (Пока не используется)
targetsFile="temp/targets3.txt"
echo "" > $targetsFile

# Число ПИ, 1000 знаков после запятой
PI=`echo "scale=1000; 4*a(1)" | bc -l`

# Функция тангенса для вычисления коэффициентов наклона прямых РЛС
tan ()
{
    echo "scale=5;s($1)/c($1)" | bc -l
}

# Конфигурация РЛС-3 Днепр
CoordsRLSXY=(5500000 3725000)
AngleForRLS=(165 285)
DestinationRLS=3000000
# Перевод углов наклона прямых РЛС из градусов в радианы
AngleForRLSRadian=(`echo "scale=5;(360-(${AngleForRLS[0]}-90))*${PI}/180" | bc -l` `echo "scale=5;(360-(${AngleForRLS[1]}-90))*${PI}/180" | bc -l`)
# Вычисление коэффициентов наклона через тангенс
TanForAngles=(`tan ${AngleForRLSRadian[0]}` `tan ${AngleForRLSRadian[1]}`)

CoordsSPROXY=(3250000 3350000)
RadiusSPRO=1000000

while :
do 
    if ! [ -d $path ] 
    then
        #echo "..."
        sleep .5
        continue
    fi
    temp=`ls $path -t`
    # if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
    if [[ $temp == "" ]]
    then 
        # MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
        #echo "..."
        sleep .5
        continue
    fi
    # if [[ "$MaxKolTargets" -ne 0 ]] 
    # then
    Topfiles=`echo "$temp" | head -n $MaxKolTargets`
    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`
        deltaX=$(( $X - ${CoordsRLSXY[0]} ))
        deltaY=$(( $Y - ${CoordsRLSXY[1]} ))
        # echo "(($deltaX)^2 + ($deltaY)^2)" | bc
        # echo "($DestinationRLS)^2" | bc
        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($DestinationRLS)^2)" | bc` -eq 1 ]]
        then
            if [[ (1 -eq `echo "$deltaY<(${TanForAngles[0]}*$deltaX)" | bc`) && (1 -eq `echo "$deltaY<(${TanForAngles[1]}*$deltaX)" | bc`) ]]
            then
                TargetCheck=`grep $id $targetsFile | wc -l`

                if [[ $TargetCheck -eq 0 ]]
                then
                    # echo "$id;$X;$Y ----------- First check!!!!"
                    echo -e "\n\033[36m __RLS_3__ Обнаружена цель ID:$id с координатами $X $Y"
                    echo "$id;$X;$Y" >> $targetsFile
                else
                    if [[ $TargetCheck -eq 1 ]]
                    then
                        PrevX=`grep $id $targetsFile | cut -d ";" -f2`
                        PrevY=`grep $id $targetsFile | cut -d ";" -f3`
                        if [[ ($PrevX != $X) || ($PrevY != $Y) ]]
                        then
                            # echo "$id;$X;$Y ------------------- Second check!!!!"
                            # echo "Обнаружена цель ID:$id с координатами $X $Y"
                            Distance=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`
                            # echo $Distance
                            if [[ ($Distance -ge $BRSpeedL) && ($Distance -le $BRSpeedH) ]]
                            then
                                # NameTarget="Бал.блок"
                                A=-1
                                B=`echo "scale=5;($PrevY-$Y)/($PrevX-$X)" | bc`
                                C=`echo "scale=5;$Y-($B*$X)" | bc`
                                chislitel=`echo "$A*${CoordsSPROXY[0]} + $B*${CoordsSPROXY[1]} + $C" | bc`
                                d=`echo "${chislitel#-}/(sqrt((($A)^2)+(($B)^2)))" | bc`

                                DistanceFirstPoint=`echo "sqrt((${CoordsSPROXY[0]}-$PrevX)^2 + (${CoordsSPROXY[1]}-$PrevY)^2)" | bc`
                                DistanceSecondPoint=`echo "sqrt((${CoordsSPROXY[0]}-$X)^2 + (${CoordsSPROXY[1]}-$Y)^2)" | bc`

                                if [[ ($d -le $RadiusSPRO) && ($DistanceFirstPoint -ge $DistanceSecondPoint) ]]
                                then
                                    echo -e "\n\033[36m __RLS_3__ Цель ID:$id движется в направлении СПРО"
                                    # echo "$PrevX $PrevY"
                                fi
                                # echo $d
                                # echo "y = $k * x + ($b)"

                            # else
                                # if [[ ($Distance -ge $KRSpeedL) && ($Distance -le $KRSpeedH) ]]
                                # then
                                #     NameTarget="К.ракета"
                                # else
                                #     NameTarget="Самолет"
                                # fi
                            fi
                            # echo "Обнаружена цель $NameTarget ID:$id с координатами $X $Y"
                            echo "$id;$X;$Y" >> $targetsFile
                        fi
                    fi
                fi
            fi
        else 
            continue
        fi
    done
    #echo -e "\033[0m ..."
    # fi

    sleep .5
done


