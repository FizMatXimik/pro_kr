#!/bin/bash

# Размеры карты
RangeXY=(13000000 9000000)
# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Название станции
SName="__RLS_1__"
# Цвет текста станции
SColor="\e[0;33m"
# Границы скоростей
PlaneSpeedL=50
PlaneSpeedH=250
KRSpeedL=250
KRSpeedH=1000
BRSpeedL=8000
BRSpeedH=10000
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
# Путь до файла с засечками
targetsFile="files/targets1.txt"
> $targetsFile

# Число ПИ, 1000 знаков после запятой
PI=`echo "scale=1000; 4*a(1)" | bc -l`

# Функция тангенса для вычисления коэффициентов наклона прямых РЛС
tan ()
{
    echo "scale=5;s($1)/c($1)" | bc -l
}

# Конфигурация РЛС-1 Воронеж-ДМ
CoordsRLSXY=(6500000 6000000)
AngleForRLS=(170 370)
RadiusRLS=4000000
# Координаты и радиус СПРО
CoordsSPROXY=(3250000 3350000)
RadiusSPRO=1000000
# Перевод углов наклона прямых РЛС из градусов в радианы
AngleForRLSRadian=(`echo "scale=5;(360-(${AngleForRLS[0]}-90))*${PI}/180" | bc -l` `echo "scale=5;(360-(${AngleForRLS[1]}-90))*${PI}/180" | bc -l`)
# Вычисление коэффициентов наклона через тангенс
TanForAngles=(`tan ${AngleForRLSRadian[0]}` `tan ${AngleForRLSRadian[1]}`)

# Основной цикл станции
while :
do 

    # Пропускать цикл если пока нет папки с целями
    if ! [ -d $path ] 
    then
        sleep .5
        continue
    fi
    # Считать названия файлов из папки с целями и если там пока нет ни одного файла, то пропустить цикл
    temp=`ls $path -t 2>/dev/null`

    if [[ $temp == "" ]]
    then 
        sleep .5
        continue
    fi
    # Считать последние 30 созданных файлов, если целей 30
    Topfiles=`echo "$temp" | head -n $MaxKolTargets`

    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        deltaX=$(( $X - ${CoordsRLSXY[0]} ))
        deltaY=$(( $Y - ${CoordsRLSXY[1]}))

        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusRLS)^2)" | bc` -eq 1 ]]
        then
            if [[ (1 -eq `echo "$deltaY>(${TanForAngles[0]}*$deltaX)" | bc`) && (1 -eq `echo "$deltaY<(${TanForAngles[1]}*$deltaX)" | bc`) ]]
            then
                continue
            else
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

                            if [[ ($Distance -ge $BRSpeedL) && ($Distance -le $BRSpeedH) ]]
                            then
                                A=-1
                                B=`echo "scale=5;($PrevY-$Y)/($PrevX-$X)" | bc`
                                C=`echo "scale=5;$Y-($B*$X)" | bc`
                                chislitel=`echo "$A*${CoordsSPROXY[0]} + $B*${CoordsSPROXY[1]} + $C" | bc`
                                d=`echo "${chislitel#-}/(sqrt((($A)^2)+(($B)^2)))" | bc`

                                DistanceFirstPoint=`echo "sqrt((${CoordsSPROXY[0]}-$PrevX)^2 + (${CoordsSPROXY[1]}-$PrevY)^2)" | bc`
                                DistanceSecondPoint=`echo "sqrt((${CoordsSPROXY[0]}-$X)^2 + (${CoordsSPROXY[1]}-$Y)^2)" | bc`

                                echo -e "$SColor $SName Обнаружен Бал.блок ID:$id с координатами X$X Y$Y"

                                if [[ ($d -le $RadiusSPRO) && ($DistanceFirstPoint -ge $DistanceSecondPoint) ]]
                                then
                                    echo -e "$SColor $SName Бал.блок ID:$id движется в направлении СПРО"
                                fi
                            else
                                if [[ ($Distance -ge $KRSpeedL) && ($Distance -le $KRSpeedH) ]]
                                then
                                    echo -e "$SColor $SName Обнаружена К.ракета ID:$id с координатами X$X Y$Y"
                                else
                                    echo -e "$SColor $SName Обнаружен Самолет ID:$id с координатами X$X Y$Y"
                                fi
                            fi
                            echo "$id;$X;$Y" >> $targetsFile
                        fi
                    fi
                fi
            fi
        else 
            continue
        fi
    done
    # echo -e "\033[0m ..."
    sleep .5
done


