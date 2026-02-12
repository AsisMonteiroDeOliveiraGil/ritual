@echo off
REM Script para debugging inalámbrico de Flutter en Windows
REM Uso: wireless_debug.bat [comando]

setlocal enabledelayedexpansion

REM Colores para output (Windows 10+)
if "%1"=="enable" goto :enable
if "%1"=="connect" goto :connect
if "%1"=="disconnect" goto :disconnect
if "%1"=="status" goto :status
if "%1"=="run" goto :run
if "%1"=="help" goto :help
if "%1"=="" goto :help

echo [ERROR] Comando desconocido: %1
goto :help

:enable
echo [INFO] Habilitando debugging inalámbrico...
adb tcpip 5555
if %errorlevel% neq 0 (
    echo [ERROR] No se pudo habilitar debugging inalámbrico
    echo [INFO] Verifica que tengas un dispositivo conectado por USB
    exit /b 1
)
echo [SUCCESS] Debugging inalámbrico habilitado en puerto 5555

REM Obtener IP del dispositivo
for /f "tokens=2 delims= " %%i in ('adb shell ip route ^| findstr "wlan0"') do set ip=%%i
if "%ip%"=="" (
    for /f "tokens=2 delims=:" %%i in ('adb shell ifconfig wlan0 ^| findstr "inet addr"') do set ip=%%i
)

if not "%ip%"=="" (
    echo [SUCCESS] IP del dispositivo: %ip%
    echo [INFO] Ahora puedes desconectar el cable USB
    echo [INFO] Para conectar inalámbricamente: adb connect %ip%:5555
) else (
    echo [WARNING] No se pudo obtener la IP del dispositivo
)
goto :end

:connect
set ip=%2
if "%ip%"=="" (
    set /p ip="Ingresa la IP de tu dispositivo Android: "
)

if "%ip%"=="" (
    echo [ERROR] IP no válida
    exit /b 1
)

echo [INFO] Conectando a %ip%:5555...
adb connect %ip%:5555

adb devices | findstr "%ip%:5555" >nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Conectado exitosamente a %ip%:5555
    echo [INFO] Ahora puedes ejecutar: flutter run
) else (
    echo [ERROR] No se pudo conectar a %ip%:5555
    echo [INFO] Verifica que:
    echo [INFO] 1. El dispositivo esté en la misma red WiFi
    echo [INFO] 2. El debugging inalámbrico esté habilitado
    echo [INFO] 3. La IP sea correcta
)
goto :end

:disconnect
echo [INFO] Desconectando dispositivos inalámbricos...
for /f "tokens=1" %%i in ('adb devices ^| findstr ":5555"') do (
    echo [INFO] Desconectando %%i...
    adb disconnect %%i
)
echo [SUCCESS] Dispositivos inalámbricos desconectados
goto :end

:status
echo [INFO] Estado de dispositivos ADB:
adb devices
echo.
echo [INFO] Dispositivos inalámbricos:
adb devices | findstr ":5555" 2>nul || echo [INFO] Ninguno
goto :end

:run
echo [INFO] Ejecutando Flutter en modo inalámbrico...
flutter run
goto :end

:help
echo Uso: %0 [comando]
echo.
echo Comandos disponibles:
echo   enable     - Habilitar debugging inalámbrico (requiere USB)
echo   connect    - Conectar a dispositivo inalámbrico
echo   disconnect - Desconectar dispositivos inalámbricos
echo   status     - Mostrar estado de dispositivos
echo   run        - Ejecutar Flutter inalámbricamente
echo   help       - Mostrar esta ayuda
echo.
echo Ejemplos:
echo   %0 enable                    # Habilitar debugging inalámbrico
echo   %0 connect 192.168.1.100    # Conectar a IP específica
echo   %0 run                      # Ejecutar Flutter
goto :end

:end
endlocal
