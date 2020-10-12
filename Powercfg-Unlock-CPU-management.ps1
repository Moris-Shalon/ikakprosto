cd "$PSScriptRoot"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; 
	exit 
}

function CheckAdminRights 
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00 `
	| Select-Object Name `
		| foreach { `
			New-ItemProperty -Name Attributes -PropertyType DWord -Value 2 -Path ($_.Name).replace('HKEY_LOCAL_MACHINE','HKLM:') -Force `
		}

pause

