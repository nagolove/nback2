#!/usr/bin/env bash
archivename="nback$(date +"%m_%d_%Hh%Mm%Ss").zip"
dest=~/myprojects/autoupdate/server/archives_examples

apack $archivename gfx/* \
sfx/* \
libs/* \
README.md \
alignedlabels.lua \
background.lua \
bhupur.lua \
common.lua \
conf.lua \
dbg.lua \
devlog.md \
generator.lua \
geo.lua \
help.lua \
ihelp.lua \
inspect.lua \
kons.lua \
logclient.lua \
logthread.lua \
main.lua \
menu.lua \
nback.lua \
pallete.lua \
pviewer.lua \
ruler.lua \
serpent.lua \
setupmenu.lua \
signal.lua \
splash.lua

#mv $archivename $dest
scp $archivename dekar@visualdoj.ru:~/myprojects
rm $archivename
#ls $dest
