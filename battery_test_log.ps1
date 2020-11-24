function WriteBatteryPercent ([int]$Append) {
	if ($Append -ne 0) {
		Write-Output (([string]::Format((Get-WmiObject Win32_Battery).EstimatedChargeRemaining)) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt" -Append;
	} else {
		Write-Output (([string]::Format((Get-WmiObject Win32_Battery).EstimatedChargeRemaining)) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt";
	}
}

if (-not (Test-Path -LiteralPath "battery_test_log.txt" -PathType Leaf)) {
	Write-Output "battery percentage;time" | Tee-Object -Filepath "battery_test_log.txt";
} else {
	Write-Output "battery percentage;time";
}

while ($true) {
	$battery=(Get-WmiObject Win32_Battery);
	if($battery -ne $null) {
		$CurrentPercent=$battery.EstimatedChargeRemaining;
		if( $BatteryPercent -ne $CurrentPercent) {
			$BatteryPercent=$currentPercent;
			WriteBatteryPercent -Append 1;
		}
	} else {
		Write-Output "PowerShell function (Get-WmiObject Win32_Battery) didn't return any information about your battery.";
		Write-Output "Maybe it's because you are trying to run this script on desktop PC.";
		Write-Output "If not and you are trying to run this script on laptop, then, please, contact your laptop manufacturer.";
		break;
	}
	Start-Sleep -Seconds 10;
}

pause;
