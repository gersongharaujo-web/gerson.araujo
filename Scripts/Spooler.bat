@echo off
title Spooler de Impressao
mode con: cols=60 lines=26
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:inicio
color 0B
cls
call :banner
set "PC="
set /p PC=   Equipamento: 
if "%PC%"=="" goto inicio
echo.
echo   Verificando conexao...
ping -n 1 -w 1500 %PC% >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo   [FALHA] %PC% nao responde na rede
    echo.
    pause
    goto inicio
)

:menu
color 0B
cls
call :banner
echo    Equipamento:  %PC%
echo   ----------------------------------------------
echo.
echo     [1]  Parar spooler
echo     [2]  Limpar fila de impressao
echo     [3]  Iniciar spooler
echo     [4]  Trocar equipamento
echo     [0]  Sair
echo.
echo   ----------------------------------------------
set "OP="
set /p OP=   Opcao: 
echo.
if "%OP%"=="1" goto parar
if "%OP%"=="2" goto limpar
if "%OP%"=="3" goto iniciar
if "%OP%"=="4" goto inicio
if "%OP%"=="0" exit /b
goto menu

:parar
echo   Parando spooler em %PC%...
sc \\%PC% stop spooler >nul 2>&1
timeout /t 3 /nobreak >nul
sc \\%PC% query spooler 2>nul | find "STOPPED" >nul
if errorlevel 1 (color 0C & echo. & echo   [FALHA] spooler nao parou) else (color 0A & echo. & echo   [ OK ] spooler PARADO)
goto fim

:limpar
echo   Limpando fila em %PC%...
if not exist "\\%PC%\c$\Windows\System32\spool\PRINTERS\" (
    color 0C
    echo.
    echo   [FALHA] sem acesso a fila
    goto fim
)
del /q /f "\\%PC%\c$\Windows\System32\spool\PRINTERS\*" >nul 2>&1
dir /b "\\%PC%\c$\Windows\System32\spool\PRINTERS" 2>nul | findstr "." >nul
if errorlevel 1 (color 0A & echo. & echo   [ OK ] fila LIMPA) else (color 0C & echo. & echo   [FALHA] restaram arquivos na fila)
goto fim

:iniciar
echo   Iniciando spooler em %PC%...
sc \\%PC% start spooler >nul 2>&1
timeout /t 3 /nobreak >nul
sc \\%PC% query spooler 2>nul | find "RUNNING" >nul
if errorlevel 1 (color 0C & echo. & echo   [FALHA] spooler nao iniciou) else (color 0A & echo. & echo   [ OK ] spooler INICIADO)
goto fim

:fim
echo.
echo   Pressione uma tecla para voltar ao menu...
pause >nul
goto menu

:banner
echo.
echo   ==============================================
echo            SPOOLER DE IMPRESSAO  -  REMOTO
echo   ==============================================
echo.
exit /b
