@echo off
title Spooler de Impressao
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:inicio
cls
set "PC="
set /p PC=Equipamento: 
if "%PC%"=="" goto inicio
ping -n 1 -w 1500 %PC% >nul 2>&1
if errorlevel 1 (
    echo.
    echo FALHOU: %PC% nao responde
    echo.
    pause
    goto inicio
)

:menu
cls
echo %PC%
echo.
echo 1 - Parar
echo 2 - Limpar
echo 3 - Iniciar
echo 4 - Trocar equipamento
echo 0 - Sair
echo.
set "OP="
set /p OP=Opcao: 
echo.
if "%OP%"=="1" goto parar
if "%OP%"=="2" goto limpar
if "%OP%"=="3" goto iniciar
if "%OP%"=="4" goto inicio
if "%OP%"=="0" exit /b
goto menu

:parar
sc \\%PC% stop spooler >nul 2>&1
timeout /t 3 /nobreak >nul
sc \\%PC% query spooler 2>nul | find "STOPPED" >nul
if errorlevel 1 (echo FALHOU: spooler nao parou) else (echo OK: spooler PARADO)
goto fim

:limpar
if not exist "\\%PC%\c$\Windows\System32\spool\PRINTERS\" (
    echo FALHOU: sem acesso a fila
    goto fim
)
del /q /f "\\%PC%\c$\Windows\System32\spool\PRINTERS\*" >nul 2>&1
dir /b "\\%PC%\c$\Windows\System32\spool\PRINTERS" 2>nul | findstr "." >nul
if errorlevel 1 (echo OK: fila LIMPA) else (echo FALHOU: restaram arquivos na fila)
goto fim

:iniciar
sc \\%PC% start spooler >nul 2>&1
timeout /t 3 /nobreak >nul
sc \\%PC% query spooler 2>nul | find "RUNNING" >nul
if errorlevel 1 (echo FALHOU: spooler nao iniciou) else (echo OK: spooler INICIADO)
goto fim

:fim
echo.
pause
goto menu
