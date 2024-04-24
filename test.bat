@echo off
cls
haxe build.hxml
cd bin/cpp
Main.exe
Main.exe help
Main.exe use 4.3.3 --force
Main.exe current