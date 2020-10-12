cd /D %~dp0
@echo off
goto check_Permissions
:check_Permissions
    echo Checking admin rights.
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: admin rights were granted.
		goto powercfg
    ) else (
        echo Failure: couldn't check admin rights. Please, try again.
		goto quit
    )

:powercfg
REM activating Ultimate Performance power plan in Windows 10.
@echo on
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61

:quit
pause
