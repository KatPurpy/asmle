@echo off
set /p BS=Assemble for Boot Sector (bs) or COM (*)?: 
set /p RUN=Run? (y/n): 

if %BS% == bs (
call :COMPILE bs asmle.img
call :RUN dosbox -c "mount C: ." -c "C:" -c "boot asmle.img"
) else (
call :COMPILE com asmle.com
call :RUN dosbox -console -debug asmle.com
)
exit /b

:COMPILE 
if %1 == bs set BOOTSECTOR=-dBOOT_SECTOR
nasm %BOOTSECTOR% -Werror -f bin main.asm -o %2
exit /b

:RUN
if not %RUN% == y exit /b
if %ERRORLEVEL% == 0 ( 
start "Don't be afraid of this window." %* 
) else (
pause
)
exit /b