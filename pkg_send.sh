#!/usr/bin/env bash

packagename="nback-xx.zip"

case "$(uname)" in
Linux*)     
    echo "Linux"
    find . -name "*.lua" -or -name "*.wav" -or -name "*.png" ! -name "correct-filelist.lua" | apack $packagename
    scp $packagename dekar@visualdoj.ru:/home/dekar/www/packages
    ssh dekar@visualdoj.ru /home/dekar/bin/update_index.lua
    rm $packagename
    ;;
MINGW*)     
    echo "MinGW"
    # изображения из gooi/imgs/* все равно попадают в список файлов.
    find . -name "*.lua" -or -name "*.wav" -or -name "*.ttf" -or -name "*.png" ! -path "gooi/imgs/*" ! -name "correct-filelist.lua" > files.txt
    ./correct-filelist.lua files.txt
    /c/Program\ Files/7-Zip/7z.exe a $packagename @files_.txt
    scp $packagename dekar@visualdoj.ru:/home/dekar/www/packages
    ssh dekar@visualdoj.ru /home/dekar/bin/update_index.lua

    rm files.txt
    rm files_.txt
    #rm $packagename
    ;;
*)          
    echo "Unknown system"
esac
