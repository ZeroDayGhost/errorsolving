@echo off
setlocal
:: FixIt Safe Edition v2.3.1 
:: Author: cleaned and updated for Collins

:: --- Privilege check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 4f
    title FixIt (Safe) requires ADMINISTRATOR PRIVILEGES
    echo The script is not running with administrative privileges.
    echo Please run the script as administrator.
    pause
    goto :Exit
)

:: Create logs folder (no automatic deletion of user files in this safe version)
if not exist "%~dp0/logs" (
    mkdir "%~dp0/logs"
)

:: ----- Parameters (basic) -----
if "%1"=="" goto :App
if /I "%1"=="-H" goto :Help
if /I "%1"=="-help" goto :Help
if /I "%1"=="/?" goto :Help
if /I "%1"=="-R" (
    call :Repair_Simple
    pause
    goto :Exit
)
if /I "%1"=="-repair" (
    call :Repair_Simple
    pause
    goto :Exit
)
if /I "%1"=="-C" (
    call :Disk_Cleanup
    pause
    goto :Exit
)
if /I "%1"=="-clean" (
    call :Disk_Cleanup
    pause
    goto :Exit
)
echo flag "%1" not recognized

:Help
echo Use: fixit_safe.bat [-H / -R / -C]
echo.
echo Command line options:
echo   -H   Displays this help screen.
echo   -R   Run the basic system repair (SFC + DISM scan/check).
echo   -C   Run Disk Cleanup (opens cleanmgr non-destructively).
echo.
goto :Exit

:: --- Main interactive app ---
:App
color 17
title FixIt Safe V2.3.1
goto :View_Menu

:View_Menu
cls
echo.
echo.       ===================================================================================
echo.       =                                      FIXIT (SAFE)                              =
echo.       ===================================================================================
echo.       =                                                                                 =
echo.       =        s]     Quick Repair                                                      =
echo.       =        c]     Disk Cleanup (cleanmgr)                                           =
echo.       =                                                                                 =
echo.       =        WEB TOOLS                                                                =
echo.       =        1]   DNS Cache / Network Info                                            =
echo.       =                                                                                 =
echo.       =        SYSTEM TOOLS                                                            =
echo.       =        2]   System File Check (SFC)                                             =
echo.       =        3]   DISM Health Scan / Check                                            =
echo.       =        4]   DISM RestoreHealth (Online)                                         =
echo.       =        5]   DISM RestoreHealth (Offline - requires ISO/USB)                     =
echo.       =                                                                                 =
echo.       =        0]   Exit                                                                =
echo.       ===================================================================================
echo.
set /p option="Option: "
if "%option%"=="0" (
    goto :Exit
) else if /I "%option%"=="s" (
    call :Quick_Repair
) else if /I "%option%"=="c" (
    call :Disk_Cleanup
) else if "%option%"=="1" (
    call :View_Network_Tools
) else if "%option%"=="2" (
    call :Sfc
) else if "%option%"=="3" (
    call :DISM_Scan
    call :DISM_Check
) else if "%option%"=="4" (
    call :DISM_Restore
) else if "%option%"=="5" (
    call :DISM_Offline
) else (
    echo Invalid Option
)
goto :View_Menu

:View_Network_Tools
cls
echo.
echo.       ========================= NETWORK & DNS TOOLS ==============================
echo.
echo.       1]   Show DNS client cache (read-only)
echo.       2]   Flush DNS client cache (safe)
echo.       3]   Show Wi-Fi profiles (names only; no keys)
echo.       0]   Go Back
echo.
set /p opt="Option: "
if "%opt%"=="0" goto :EOF
if "%opt%"=="1" (
    call :Get_Dns_Cache
) else if "%opt%"=="2" (
    call :Clear_Dns_Cache
) else if "%opt%"=="3" (
    echo Listing Wi-Fi profiles (no keys will be shown)...
    netsh wlan show profiles
) else (
    echo Invalid Option
)
pause
goto :View_Network_Tools

:: --- Safe system tools ---
:Sfc
echo Running System File Check (sfc /scannow)...
sfc /scannow
if %errorlevel% neq 0 (
    echo NOTE: sfc reported issues or failed. Review the output above.
) else (
    echo SFC completed successfully.
)
goto :EOF

:DISM_Scan
echo Running DISM ScanHealth (read-only scan)...
dism /Online /Cleanup-Image /ScanHealth
goto :EOF

:DISM_Check
echo Running DISM CheckHealth (read-only check)...
dism /Online /Cleanup-Image /CheckHealth
goto :EOF

:DISM_Restore
echo WARNING: DISM /RestoreHealth modifies the system image. 
echo Do you want to continue? [1-Yes / 0-No]
set /p ans=
if "%ans%"=="1" (
    dism /Online /Cleanup-Image /RestoreHealth
) else (
    echo Skipping DISM /RestoreHealth.
)
goto :EOF

:DISM_Offline
cls
echo Running DISM in Offline Mode...
echo You need a Windows ISO or installation USB mounted.
set /p isoDrive=Enter the drive letter of your mounted ISO/USB (e.g., D): 

if not exist %isoDrive%:\\sources\\install.wim if not exist %isoDrive%:\\sources\\install.esd (
    echo Could not locate install.wim or install.esd on %isoDrive%:
    echo Please insert a USB drive with a Windows ISO and try again.
    pause
    goto :EOF
)

echo Found Windows image. Running offline DISM repair...
dism /image:C:\\ /cleanup-image /restorehealth /source:%isoDrive%:\\sources\\install.wim /limitaccess

if %errorlevel% neq 0 (
    echo Offline DISM failed. Please check your ISO/USB and try again.
) else (
    echo Offline DISM completed successfully.
)
pause
goto :EOF

:: --- DNS tools (safe) ---
:Get_Dns_Cache
echo Getting Dns Client Cache (read-only)...
powershell -Command "Get-DnsClientCache" 2>nul || (
    echo This system may not support the DNSClient PowerShell module.
)
goto :EOF

:Clear_Dns_Cache
echo Attempting to clear DNS cache (safe)...
powershell -Command "Clear-DnsClientCache" >nul 2>&1
if %errorlevel% neq 0 (
    echo Could not clear DNS client cache via PowerShell. Attempting ipconfig /flushdns...
    ipconfig /flushdns
) else (
    echo DNS cache flushed successfully.
)
goto :EOF

:Disk_Cleanup
echo Starting Disk Cleanup UI (non-destructive) ...
cleanmgr
goto :EOF

:Quick_Repair
call :Sfc
call :DISM_Scan
call :DISM_Check
echo Quick repair finished.
pause
goto :EOF

:Repair_Simple
call :Sfc
call :DISM_Scan
call :DISM_Check
goto :EOF

:Exit
endlocal
exit /b
