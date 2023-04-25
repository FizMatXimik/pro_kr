#!/bin/bash

# Размеры карты
RangeXY=(13000000 9000000)
# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Название станции
SName="__SPRO__"
# Цвет текста станции
SColor="\e[4;35m"
# Границы скорости Бал.блоков
BRSpeedL=8000
BRSpeedH=10000
# Координаты и радиус СПРО (Москва)
CoordsSPROXY=(3150000 3800000)
RadiusSPRO=1200000
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
# Путь до папки для уничтожения целей
pathD="/tmp/GenTargets/Destroy"
# Путь до папки временных файлов целей, по котором был произведен выстрел
pathShoot="./temp/SPRO"
# Путь до файла с засечками
targetsFile="files/targets_spro.txt"
> $targetsFile
# Путь до файла с id новых засеченных целей
targetsFileIds="files/targets_spro_ids.txt"
> $targetsFileIds
# Путь до файла с боезапасом СПРО
ammunitionFile="files/SPRO_Missiles"
> $ammunitionFile
NumOfMissiles=10
# Path to messages
TargetsLog="./messages/TargetsLog"
WarningsLog="./messages/WarningsLog"
StatusLog="./messages/StatusLog"
time_format="%d/%m/%Y %T.%3N"

SUPERSECRETNIYKLUCH="hihihaha"

echo -e "$SColor SPRO Started"
moscow_time=$(TZ=Europe/Moscow date +"$time_format")
logTime=$(TZ=Europe/Moscow date +"%T.%3N")
echo -e "$moscow_time,$SName,Start,NULL" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$StatusLog/$SName-status-$logTime.log"

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

    # Очистка файла с целями для записи новых
    > $targetsFileIds
    # Заполнение файла айдишниками замеченных целей на данной итерации цикла
    for file in $Topfiles
    do
        idL=${file: -6}
        echo $idL >> $targetsFileIds
    done

    # Считываем все айдишники целей на данной итерации цикла
    IdsOfNewTargets=`cat $targetsFileIds`
    # Пробегаемся по списку файлов, то есть целей по которым был произведен выстрел
    for idAT in `ls $pathShoot -t`
    do
        # Проверка есть ли среди новых айдишников тот, по которому был произведен выстрел.
        TargetCheckAt=`echo $IdsOfNewTargets | grep $idAT | wc -l`
        # Если нет, то есть совпадений ноль, то значит цель была сбита и можно выводить сообщение и удалять файл 
        if [[ $TargetCheckAt -eq 0 ]]
        then
            moscow_time=$(TZ=Europe/Moscow date +"$time_format")
            echo -e "$SColor $moscow_time $SName Цель ID:$idAT сбита"
            echo -e "$moscow_time,$SName,Сбита,$idAT,NULL" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$TargetsLog/$SName-$idAT-destroyed-$logTime.log"
            rm "$pathShoot/$idAT"
        fi
    done

    # Цикл, где на каждой итерации берем новую информацию по одной из целей
    for file in $Topfiles
    do
        moscow_time=$(TZ=Europe/Moscow date +"$time_format")
        logTime=$(TZ=Europe/Moscow date +"%T.%3N")
        # Парсим айдишник и координаты
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        # Высчитываем координаты цели относительно станции
        deltaX=$(( $X - ${CoordsSPROXY[0]} ))
        deltaY=$(( $Y - ${CoordsSPROXY[1]} ))

        # Если расстояние до цели от станции меньше радиуса станции, то значит, что цель в зоне обзора станции
        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusSPRO)^2)" | bc` -eq 1 ]]
        then
            # Находим записи по айдишнику цели в файле засечек
            TargetCheck=`grep $id $targetsFile | wc -l`
            # Если до этого не было записей, то это первая засечка, мы просто ее записываем
            if [[ $TargetCheck -eq 0 ]]
            then
                echo "$id;$X;$Y" >> $targetsFile
            else
                # Если же засечек 1 или больше, то считываем координаты последней засечки
                if [[ $TargetCheck -ge 1 ]]
                then
                    PrevX=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f2`
                    PrevY=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f3`
                    # Проверяем, чтобы они не были равны новым
                    if [[ ($PrevX != $X) || ($PrevY != $Y) ]]
                    then
                        # Высчитываем скорость цели
                        Speed=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`
                        # Если это бал.блок
                        if [[ ($Speed -ge $BRSpeedL) && ($Speed -le $BRSpeedH) ]]
                        then
                            # то проверяем, что это только вторая засечка 
                            if [[ $TargetCheck -eq 1 ]]
                            then
                                # пишем информацию о том, что цель обнаружена
                                moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                echo -e "$SColor $moscow_time $SName Обнаружен Бал.блок ID:$id с координатами X$X Y$Y"
                                echo -e "$moscow_time,$SName,Обнаружен Бал.блок,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$WarningsLog/$SName-$id-detected-$logTime.log"
                                # производим выстрел
                                moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                echo -e "$SColor $moscow_time $SName Выстрел по цели ID:$id "
                                echo -e "$moscow_time,$SName,Выстрел,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$TargetsLog/$SName-$id-shoot-$logTime.log"
                                # создаем файл в папке уничтожения целей
                                touch "$pathD/$id"
                                # записываем выстрел в файл арсенала
                                echo "shoot" >> $ammunitionFile
                                # создание файла цели, по которой был произведен выстрел
                                echo 2 > "$pathShoot/$id"
                            else
                                numOfChecks=`cat "$pathShoot/$id"`
                                if [[ $numOfChecks -eq 0 ]]
                                then 
                                    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                    echo -e "$SColor $moscow_time $SName Промах по цели ID:$id"
                                    echo -e "$moscow_time,$SName,Промах,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$TargetsLog/$SName-$id-miss-$logTime.log"
                                    # производим выстрел
                                    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                    echo -e "$SColor $moscow_time $SName Выстрел по цели ID:$id "
                                    echo -e "$moscow_time,$SName,Выстрел,$id,X$X Y$Y" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$TargetsLog/$SName-$id-shoot-$logTime.log"
                                    # создаем файл в папке уничтожения целей
                                    touch "$pathD/$id"
                                    # записываем выстрел в файл арсенала
                                    echo "shoot" >> $ammunitionFile
                                    # создание файла цели, по которой был произведен выстрел
                                    echo 2 > "$pathShoot/$id"
                                else
                                    newNumOfChecks=`echo "$numOfChecks - 1" | bc`
                                    echo $newNumOfChecks > "$pathShoot/$id"
                                fi
                            fi
                            # проверка файла с боекомплектом
                            L=`cat $ammunitionFile | wc -l`
                            Missilesremained=`echo "$NumOfMissiles - $L" | bc`

                            # если боекомплект пуст то перезагружаем его
                            if [[ $Missilesremained -eq 0 ]]
                            then 
                                > $ammunitionFile
                                moscow_time=$(TZ=Europe/Moscow date +"$time_format")
                                echo -e "$SColor $moscow_time $SName Боекомплект перезаряжен"
                                echo -e "$moscow_time,$SName,Боекомплект перезаряжен,NULL,NULL" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$WarningsLog/$SName-$id-reloaded-$logTime.log"
                            fi
                        fi
                        # записываем засечку в файл
                        echo "$id;$X;$Y" >> $targetsFile
                    fi
                fi
            fi
        else 
            continue
        fi
    done

    L=`cat $ammunitionFile | wc -l`
    Missilesremained=`echo "$NumOfMissiles - $L" | bc`
    moscow_time=$(TZ=Europe/Moscow date +"$time_format")
    echo -e "$moscow_time,$SName,OK,$Missilesremained" | openssl aes-256-cbc -pbkdf2 -a -salt -pass pass:$SUPERSECRETNIYKLUCH > "$StatusLog/$SName-status-$logTime.log"
    sleep .9
done