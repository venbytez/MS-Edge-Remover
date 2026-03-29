@echo off
setlocal EnableExtensions DisableDelayedExpansion
title MS Edge Verify by venbytez
mode con: cols=104 lines=34
color 0F

set "EDGE_GUID={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
set "POLICY_KEY=HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate"
set "LEGACY_KEY=HKLM\SOFTWARE\Microsoft\EdgeUpdate"

set "GUARD_TASK=EdgeGuardStartup"
set "GUARD_SCRIPT=%ProgramData%\EdgeGuard\EdgeGuard.cmd"

set "PF86=%ProgramFiles(x86)%"
if not exist "%PF86%" set "PF86=%ProgramFiles%"

set /a PASS=0
set /a WARN=0
set /a INFO=0

cls
echo ================================================================================
echo   MS Edge Verify by venbytez
echo ================================================================================
echo.

call :CheckPathNotExists "%PF86%\Microsoft\Edge" "PF86 Edge folder"
call :CheckPathNotExists "%PF86%\Microsoft\EdgeUpdate" "PF86 EdgeUpdate folder"
call :CheckPathNotExists "%PF86%\Microsoft\EdgeCore" "PF86 EdgeCore folder"
call :CheckPathNotExists "%ProgramData%\Microsoft\EdgeUpdate" "ProgramData EdgeUpdate folder"
call :CheckPathNotExists "%LocalAppData%\Microsoft\Edge" "LocalAppData Edge folder"

call :CheckProcessNotRunning "msedge.exe"
call :CheckProcessNotRunning "MicrosoftEdgeUpdate.exe"
call :CheckProcessNotRunning "identity_helper.exe"

call :CheckServiceNotExists "edgeupdate"
call :CheckServiceNotExists "edgeupdatem"

call :CheckTaskNotExists "MicrosoftEdgeUpdateTaskMachineCore"
call :CheckTaskNotExists "MicrosoftEdgeUpdateTaskMachineUA"

call :CheckReg "%POLICY_KEY%" "InstallDefault" "0"
call :CheckReg "%POLICY_KEY%" "UpdateDefault" "0"
call :CheckReg "%POLICY_KEY%" "Install%EDGE_GUID%" "0"
call :CheckReg "%POLICY_KEY%" "Update%EDGE_GUID%" "0"
call :CheckReg "%LEGACY_KEY%" "DoNotUpdateToEdgeWithChromium" "1"

call :CheckTaskOptional "%GUARD_TASK%" "Guard task"
call :CheckPathOptional "%GUARD_SCRIPT%" "Guard script"

echo.
echo ================================================================================
echo   PASS: %PASS%   WARN: %WARN%   INFO: %INFO%
echo ================================================================================
echo.

if %WARN% GTR 0 (
    color 0E
    echo Result: PARTIAL (warnings found)
) else (
    color 0A
    echo Result: HEALTHY
)

echo.
pause
exit /b 0

:: ============================================================
:: Helpers
:: ============================================================

:ok
set /a PASS+=1
echo [OK]   %~1
goto :eof

:warn
set /a WARN+=1
echo [WARN] %~1
goto :eof

:info
set /a INFO+=1
echo [INFO] %~1
goto :eof

:CheckPathNotExists
if exist "%~1" (
    call :warn "%~2 exists"
) else (
    call :ok "%~2 missing"
)
goto :eof

:CheckProcessNotRunning
tasklist /fi "imagename eq %~1" | find /i "%~1" >nul 2>&1
if "%errorlevel%"=="0" (
    call :warn "Process running: %~1"
) else (
    call :ok "Process not running: %~1"
)
goto :eof

:CheckServiceNotExists
sc query "%~1" >nul 2>&1
if "%errorlevel%"=="0" (
    call :warn "Service exists: %~1"
) else (
    call :ok "Service missing: %~1"
)
goto :eof

:CheckTaskNotExists
schtasks /query /tn "%~1" >nul 2>&1
if "%errorlevel%"=="0" (
    call :warn "Task exists: %~1"
) else (
    call :ok "Task missing: %~1"
)
goto :eof

:CheckTaskOptional
schtasks /query /tn "%~1" >nul 2>&1
if "%errorlevel%"=="0" (
    call :ok "%~2 present"
) else (
    call :info "%~2 not present (optional)"
)
goto :eof

:CheckPathOptional
if exist "%~1" (
    call :ok "%~2 present"
) else (
    call :info "%~2 not present (optional)"
)
goto :eof

:CheckReg
set "RK=%~1"
set "RV=%~2"
set "RE=%~3"
set "FOUND="

for /f "tokens=1,2,3" %%A in ('reg query "%RK%" /v "%RV%" 2^>nul ^| find /i "%RV%"') do set "FOUND=%%C"

if not defined FOUND (
    call :warn "Registry missing: %RV%"
    goto :eof
)

if /i "%FOUND%"=="0x0" set "FOUND=0"
if /i "%FOUND%"=="0x1" set "FOUND=1"

if "%FOUND%"=="%RE%" (
    call :ok "Registry OK: %RV%=%RE%"
) else (
    call :warn "Registry mismatch: %RV%=%FOUND% expected %RE%"
)
goto :eof