@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF kbdtest.asm kbdtest.com kbdtest.lst || exit /b

copy /Y kbdtest.com ..\..\..\..\Binary\Apps\Test\ || exit /b

