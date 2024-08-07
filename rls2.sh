#!/bin/bash

# Размеры карты
RangeXY=(13000000 9000000)
# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Название станции
SName="__RLS_2__"
# Цвет текста станции
SColor="\e[0;34m"
# Границы скоростей
BRSpeedL=8000
BRSpeedH=10000
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
# Путь до файла с засечками
targetsFile="files/targets2.txt"
> $targetsFile
# Path to messages
WarningsLog="./messages/WarningsLog"
StatusLog="./messages/StatusLog"
time_format="%d/%m/%Y %T.%3N"

SUPERSECRETNIYKLUCH="hihihaha"

# Число ПИ, 1000 знаков после запятой
PI=`echo "scale=1000; 4*a(1)" | bc -l`

# Функция тангенса для вычисления коэффициентов наклона прямых РЛС
tan ()
{
    echo "scale=5;s($1)/c($1)" | bc -l
}

# Конфигурация РЛС-2 Дарьял
CoordsRLSXY=(2500000 3650000)
AngleForRLS=(90 180)
RadiusRLS=7000000
# Координаты и радиус СПРО
CoordsSPROXY=(3250000 3350000)
RadiusSPRO=1000000
# Перевод углов наклона прямых РЛС из градусов в радианы
AngleForRLSRadian=(`echo "scale=5;(360-(${AngleForRLS[0]}-90))*${PI}/180" | bc -l` `echo "scale=5;(360-(${AngleForRLS[1]}-90))*${PI}/180" | bc -l`)

if [[ (${AngleForRLS[0]} -eq 0) || (${AngleForRLS[0]} -eq 180) ]]
then
    TanForAngles1=0

else 
    TanForAngles1=`tan ${AngleForRLSRadian[0]}`
fi
if [[ (${AngleForRLS[1]} -eq 0) || (${AngleForRLS[1]} -eq 180) ]]
then
    TanForAngles2=0

else 
    TanForAngles2=`tan ${AngleForRLSRadian[1]}`
fi

# Вычисление коэффициентов наклона через тангенс
TanForAngles=($TanForAngles1 $TanForAngles2)

echo -e "$SColor RLS-2 Started"
moscow_time=$(TZ=Europe/Moscow date +"$time_format")
logTime=$(TZ=Europe/Moscow date +"%T.%3N")
echo -e "$moscow_time,$SName,Start,NULL" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$StatusLog/$SName-status-$logTime.log"

# Основной цикл станции
while :
do 
    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
    logTime=$(TZ=Europe/Moscow date +"%T.%3N")
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
        deltaY=$(( $Y - ${CoordsRLSXY[1]} ))

        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusRLS)^2)" | bc` -eq 1 ]]
        then
            if [[ (1 -eq `echo "$deltaY<(${TanForAngles[0]}*$deltaX)" | bc`) && (1 -eq `echo "$deltaX>(${TanForAngles[1]}*$deltaY)" | bc`) ]]
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

                            if [[ ($Distance -ge $BRSpeedL) && ($Distance -le $BRSpeedH) ]]
                            then
                                A=-1
                                B=`echo "scale=5;($PrevY-$Y)/($PrevX-$X)" | bc`
                                C=`echo "scale=5;$Y-($B*$X)" | bc`
                                chislitel=`echo "$A*${CoordsSPROXY[1]} + $B*${CoordsSPROXY[0]} + $C" | bc`
                                d=`echo "${chislitel#-}/(sqrt((($A)^2)+(($B)^2)))" | bc`

                                DistanceFirstPoint=`echo "sqrt((${CoordsSPROXY[0]}-$PrevX)^2 + (${CoordsSPROXY[1]}-$PrevY)^2)" | bc`
                                DistanceSecondPoint=`echo "sqrt((${CoordsSPROXY[0]}-$X)^2 + (${CoordsSPROXY[1]}-$Y)^2)" | bc`
                                moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                echo -e "$SColor $moscow_time $SName Обнаружен Бал.блок ID:$id с координатами X$X Y$Y"
                                echo -e "$moscow_time,$SName,Обнаружен Бал.блок,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$WarningsLog/$SName-$id-detected-$logTime.log"

                                if [[ ($d -le $RadiusSPRO) && ($DistanceFirstPoint -ge $DistanceSecondPoint) ]]
                                then
                                    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                    echo -e "$SColor $moscow_time $SName Бал.блок ID:$id движется в направлении СПРО"
                                    echo -e "$moscow_time,$SName,Бал.блок движется в направлении СПРО,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$WarningsLog/$SName-$id-toSPRO-$logTime.log"
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
    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
    echo -e "$moscow_time,$SName,OK,NULL" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$StatusLog/$SName-status-$logTime.log"
    sleep .9
done


