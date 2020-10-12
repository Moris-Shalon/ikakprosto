cd /D %~dp0
@echo off
goto check_Permissions
:check_Permissions
    echo Checking admin rights.
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: admin rights were granted.
		goto regcpu
    ) else (
        echo Failure: couldn't check admin rights. Please, try again.
		goto quit
    )

:regcpu
REM activating Ultimate Performance power plan in Windows 10.
@echo on
REM for /f "delims=" %%a in ('powershell -command "Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00 | foreach { $_.Name } | Format-List | Out-String | ForEach-Object { $_.Trim() } "') do ( echo %%a )
for /f "delims=" %%a in ('powershell -command "Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00 | foreach { $_.Name } "') do ( reg add %%a /v Attributes /t REG_DWORD /d 2 /f )

:quit
pause
