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
targetsFile="temp/targets.txt"
echo "" > $targetsFile

# Число ПИ, 1000 знаков после запятой
PI=`echo "scale=1000; 4*a(1)" | bc -l`

# Функция тангенса для вычисления коэффициентов наклона прямых РЛС
tan ()
{
    echo "scale=5;s($1)/c($1)" | bc -l
}

# Конфигурация РЛС-1 Воронеж-ДМ
CoordsRLS1XY=(6500000 6000000)
AngleForRLS=(170 370)
DestinationRLS1=4000000
# Перевод углов наклона прямых РЛС из градусов в радианы
AngleForRLSRadian=(`echo "scale=5;(360-(${AngleForRLS[0]}-90))*${PI}/180" | bc -l` `echo "scale=5;(360-(${AngleForRLS[1]}-90))*${PI}/180" | bc -l`)
# Вычисление коэффициентов наклона через тангенс
TanForAngles=(`tan ${AngleForRLSRadian[0]}` `tan ${AngleForRLSRadian[1]}`)

while :
do 
    # 
    temp=`ls $path -t`
    # if [[ $temp != "" && $MaxKolTargets -eq 0 ]]
    if [[ $temp == "" ]]
    then 
        # MaxKolTargets=`ls /tmp/GenTargets/Targets | wc -w`
        echo "..."
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
        deltaX=$(( ${CoordsRLS1XY[0]} - $X ))
        deltaY=$(( ${CoordsRLS1XY[1]} - $Y ))
        # echo "(($deltaX)^2 + ($deltaY)^2)" | bc
        # echo "($DestinationRLS1)^2" | bc
        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($DestinationRLS1)^2)" | bc` -eq 1 ]]
        then
            # echo "$deltaY  < `echo "(${TanForAngles[0]}*$deltaX)" | bc`"
            # echo "$deltaY  > `echo "(${TanForAngles[1]}*$deltaX)" | bc`"
            # Логика работает!!!! Но почему именно с такими знаками сравнения??? Надо подумать и проверить!
            if [[ (1 -eq `echo "$deltaY<(${TanForAngles[0]}*$deltaX)" | bc`) && (1 -eq `echo "$deltaY>(${TanForAngles[1]}*$deltaX)" | bc`) ]]
            then
                continue
            else
                TargetCheck=`grep $id $targetsFile | wc -l`

                if [[ $TargetCheck -eq 0 ]]
                then
                    # echo "$id;$X;$Y ----------- First check!!!!"
                    echo "$id;$X;$Y" >> $targetsFile
                else
                    if [[ $TargetCheck -eq 1 ]]
                    then
                        PrevX=`grep $id $targetsFile | cut -d ";" -f2`
                        PrevY=`grep $id $targetsFile | cut -d ";" -f3`
                        if [[ ($PrevX -ne $X) && ($PrevY -ne $Y) ]]
                        then
                            # echo "$id;$X;$Y ------------------- Second check!!!!"
                            Distance=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`
                            # echo $Distance
                            if [[ ($Distance -ge $BRSpeedL) && ($Distance -le $BRSpeedH) ]]
                            then
                                NameTarget="Бал.блок"
                            else
                                if [[ ($Distance -ge $KRSpeedL) && ($Distance -le $KRSpeedH) ]]
                                then
                                    NameTarget="К.ракета"
                                else
                                    NameTarget="Самолет"
                                fi
                            fi
                            echo “Обнаружена цель $NameTarget ID:$id с координатами $X $Y”
                            echo "$id;$X;$Y" >> $targetsFile
                        fi
                    fi
                fi
            fi
        else 
            continue
        fi
    done
    echo "..."
    # fi

    sleep .5
done


