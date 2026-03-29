@echo off
setlocal EnableExtensions DisableDelayedExpansion
title MS Edge Remover by venbytez
mode con: cols=104 lines=34
color 0F

:: ============================================================
:: MS Edge Remover by venbytez
:: ============================================================

set "APP_NAME=MS Edge Remover by venbytez"
set "EDGE_GUID={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
set "POLICY_KEY=HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate"
set "LEGACY_KEY=HKLM\SOFTWARE\Microsoft\EdgeUpdate"

set "GUARD_DIR=%ProgramData%\EdgeGuard"
set "GUARD_SCRIPT=%GUARD_DIR%\EdgeGuard.cmd"
set "GUARD_TASK=EdgeGuardStartup"

set "PF86=%ProgramFiles(x86)%"
if not exist "%PF86%" set "PF86=%ProgramFiles%"

set "LOG=%~dp0EdgeRemover_%date:~-4,4%-%date:~-7,2%-%date:~-10,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%.log"
set "LOG=%LOG: =0%"

call :RequireAdmin || exit /b 1
call :Log "Script started"

:MENU
cls
echo ================================================================================
echo                               %APP_NAME%
echo ================================================================================
echo.
echo   [1] Remove Edge  ^|  Clean leftovers  ^|  Apply block  ^|  Install guard
echo   [2] Install / Update guard
echo   [3] Remove guard
echo   [4] Quick verify
echo   [5] Exit
echo.
choice /c 12345 /n /m "Select [1-5]: "

if errorlevel 5 goto :END
if errorlevel 4 goto :QUICK_VERIFY
if errorlevel 3 goto :REMOVE_GUARD
if errorlevel 2 goto :INSTALL_GUARD_ONLY
if errorlevel 1 goto :FULL_REMOVE
goto :MENU

:FULL_REMOVE
cls
echo ================================================================================
echo   FULL REMOVE
echo ================================================================================
echo.
echo   Running...
call :Log "Start full remove flow"

call :KillProcesses
call :UninstallEdge
call :RemoveEdgeFolders
call :RemoveEdgeRegistry
call :RemoveEdgeServicesTasks
call :ApplyPolicies
call :InstallGuard

echo.
echo ------------------------------------------------------------------------------
echo   [OK] Completed
echo   [i] Reboot recommended
echo   [i] Log: %LOG%
echo ------------------------------------------------------------------------------
goto :PauseToMenu

:INSTALL_GUARD_ONLY
cls
echo ================================================================================
echo   INSTALL / UPDATE GUARD
echo ================================================================================
echo.
call :InstallGuard
echo.
echo ------------------------------------------------------------------------------
echo   [OK] Guard installed/updated
echo   [i] Log: %LOG%
echo ------------------------------------------------------------------------------
goto :PauseToMenu

:REMOVE_GUARD
cls
echo ================================================================================
echo   REMOVE GUARD
echo ================================================================================
echo.
call :DoRemoveGuard
echo.
echo ------------------------------------------------------------------------------
echo   [OK] Guard removed (if existed)
echo   [i] Log: %LOG%
echo ------------------------------------------------------------------------------
goto :PauseToMenu

:QUICK_VERIFY
cls
echo ================================================================================
echo   QUICK VERIFY
echo ================================================================================
echo.

call :CheckPathNotExists "%PF86%\Microsoft\Edge" "PF86 Edge folder"
call :CheckPathNotExists "%PF86%\Microsoft\EdgeUpdate" "PF86 EdgeUpdate folder"
call :CheckPathNotExists "%PF86%\Microsoft\EdgeCore" "PF86 EdgeCore folder"
call :CheckPathNotExists "%ProgramData%\Microsoft\EdgeUpdate" "ProgramData EdgeUpdate folder"
call :CheckPathNotExists "%LocalAppData%\Microsoft\Edge" "LocalAppData Edge folder"

call :CheckServiceNotExists "edgeupdate"
call :CheckServiceNotExists "edgeupdatem"
call :CheckTaskNotExists "MicrosoftEdgeUpdateTaskMachineCore"
call :CheckTaskNotExists "MicrosoftEdgeUpdateTaskMachineUA"

call :CheckReg "%POLICY_KEY%" "InstallDefault" "0"
call :CheckReg "%POLICY_KEY%" "UpdateDefault" "0"
call :CheckReg "%POLICY_KEY%" "Install%EDGE_GUID%" "0"
call :CheckReg "%POLICY_KEY%" "Update%EDGE_GUID%" "0"
call :CheckReg "%LEGACY_KEY%" "DoNotUpdateToEdgeWithChromium" "1"

call :CheckTaskExists "%GUARD_TASK%" "Guard task"
call :CheckPathExists "%GUARD_SCRIPT%" "Guard script"

echo.
echo ------------------------------------------------------------------------------
echo   [i] Verify done
echo ------------------------------------------------------------------------------
goto :PauseToMenu

:PauseToMenu
echo.
echo Press any key to return menu...
pause >nul
goto :MENU

:END
exit /b 0

:: ============================================================
:: Core operations
:: ============================================================

:KillProcesses
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
taskkill /f /im identity_helper.exe >nul 2>&1
call :Log "Processes kill attempted"
goto :eof

:UninstallEdge
set "EPATH=%PF86%\Microsoft\Edge\Application"
if exist "%EPATH%" (
  for /d %%I in ("%EPATH%\*") do (
    if exist "%%~I\Installer\setup.exe" (
      start /wait "" "%%~I\Installer\setup.exe" --uninstall --system-level --force-uninstall --verbose-logging >nul 2>&1
      call :Log "Uninstall attempted via %%~I\Installer\setup.exe"
    )
  )
) else (
  call :Log "Edge application path not found; uninstall skipped"
)
goto :eof

:RemoveEdgeFolders
call :RemoveFolder "%PF86%\Microsoft\Edge"
call :RemoveFolder "%PF86%\Microsoft\EdgeUpdate"
call :RemoveFolder "%PF86%\Microsoft\EdgeCore"
call :RemoveFolder "%ProgramData%\Microsoft\EdgeUpdate"
call :RemoveFolder "%LocalAppData%\Microsoft\Edge"
call :Log "Folder cleanup completed"
goto :eof

:RemoveEdgeRegistry
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >nul 2>&1
call :Log "Registry cleanup completed"
goto :eof

:RemoveEdgeServicesTasks
sc delete edgeupdate >nul 2>&1
sc delete edgeupdatem >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1
call :Log "Service/task cleanup completed"
goto :eof

:ApplyPolicies
reg add "%POLICY_KEY%" /f >nul 2>&1
reg add "%POLICY_KEY%" /v InstallDefault /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%POLICY_KEY%" /v UpdateDefault /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%POLICY_KEY%" /v CreateDesktopShortcutDefault /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%POLICY_KEY%" /v Install%EDGE_GUID% /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%POLICY_KEY%" /v Update%EDGE_GUID% /t REG_DWORD /d 0 /f >nul 2>&1

reg add "%LEGACY_KEY%" /f >nul 2>&1
reg add "%LEGACY_KEY%" /v DoNotUpdateToEdgeWithChromium /t REG_DWORD /d 1 /f >nul 2>&1
call :Log "Policy block applied"
goto :eof

:InstallGuard
if not exist "%GUARD_DIR%" mkdir "%GUARD_DIR%" >nul 2>&1

> "%GUARD_SCRIPT%" echo @echo off
>>"%GUARD_SCRIPT%" echo taskkill /f /im msedge.exe ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo taskkill /f /im MicrosoftEdgeUpdate.exe ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo taskkill /f /im identity_helper.exe ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo rd /s /q "%PF86%\Microsoft\Edge" ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo rd /s /q "%PF86%\Microsoft\EdgeUpdate" ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo rd /s /q "%PF86%\Microsoft\EdgeCore" ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo rd /s /q "%ProgramData%\Microsoft\EdgeUpdate" ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo rd /s /q "%LocalAppData%\Microsoft\Edge" ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo sc delete edgeupdate ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo sc delete edgeupdatem ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f ^>nul 2^>^&1
>>"%GUARD_SCRIPT%" echo exit /b 0

schtasks /create /tn "%GUARD_TASK%" /sc onstart /ru "SYSTEM" /rl HIGHEST /tr "\"%GUARD_SCRIPT%\"" /f >nul 2>&1
call :Log "Guard installed/updated"
goto :eof

:DoRemoveGuard
schtasks /delete /tn "%GUARD_TASK%" /f >nul 2>&1
if exist "%GUARD_SCRIPT%" del /f /q "%GUARD_SCRIPT%" >nul 2>&1
if exist "%GUARD_DIR%" rd /s /q "%GUARD_DIR%" >nul 2>&1
call :Log "Guard removed"
goto :eof

:RemoveFolder
if exist "%~1" (
  takeown /f "%~1" /r /d Y >nul 2>&1
  icacls "%~1" /grant administrators:F /t >nul 2>&1
  rd /s /q "%~1" >nul 2>&1
)
goto :eof

:: ============================================================
:: Verify helpers
:: ============================================================

:CheckPathNotExists
if exist "%~1" (echo [WARN] %~2 exists) else (echo [OK] %~2 missing)
goto :eof

:CheckPathExists
if exist "%~1" (echo [OK] %~2 exists) else (echo [WARN] %~2 missing)
goto :eof

:CheckServiceNotExists
sc query "%~1" >nul 2>&1
if "%errorlevel%"=="0" (echo [WARN] Service exists: %~1) else (echo [OK] Service missing: %~1)
goto :eof

:CheckTaskNotExists
schtasks /query /tn "%~1" >nul 2>&1
if "%errorlevel%"=="0" (echo [WARN] Task exists: %~1) else (echo [OK] Task missing: %~1)
goto :eof

:CheckTaskExists
schtasks /query /tn "%~1" >nul 2>&1
if "%errorlevel%"=="0" (echo [OK] %~2 exists) else (echo [WARN] %~2 missing)
goto :eof

:CheckReg
set "RK=%~1"
set "RV=%~2"
set "RE=%~3"
set "FOUND="
for /f "tokens=1,2,3" %%A in ('reg query "%RK%" /v "%RV%" 2^>nul ^| find /i "%RV%"') do set "FOUND=%%C"

if not defined FOUND (
  echo [WARN] Registry missing: %RV%
  goto :eof
)

if /i "%FOUND%"=="0x0" set "FOUND=0"
if /i "%FOUND%"=="0x1" set "FOUND=1"

if "%FOUND%"=="%RE%" (
  echo [OK] Registry OK: %RV%=%RE%
) else (
  echo [WARN] Registry mismatch: %RV%=%FOUND% expected %RE%
)
goto :eof

:: ============================================================
:: Utility
:: ============================================================

:RequireAdmin
net session >nul 2>&1
if "%errorlevel%"=="0" goto :eof
cls
color 0C
echo ================================================================================
echo   ACCESS DENIED - RUN AS ADMINISTRATOR
echo ================================================================================
echo.
pause
exit /b 1

:Log
>>"%LOG%" echo [%date% %time%] %~1
goto :eof