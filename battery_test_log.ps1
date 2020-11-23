function WriteBatteryPercent ([int]$Append) {
	if ($Append -ne 0) {
		Write-Output (([string](Get-WmiObject Win32_Battery).EstimatedChargeRemaining) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt" -Append;
	} else {
		Write-Output (([string](Get-WmiObject Win32_Battery).EstimatedChargeRemaining) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt";
	}
}

if (-not (Test-Path -LiteralPath "battery_test_log.txt" -PathType Leaf)) {
	Write-Output "battery percentage;time" | Tee-Object -Filepath "battery_test_log.txt";
	WriteBatteryPercent -Append 0 -Sleep 10;
}


while ($true) { `
    if ($BatteryPercent -ne (Get-WmiObject Win32_Battery).EstimatedChargeRemaining) {
		$BatteryPercent = (Get-WmiObject Win32_Battery).EstimatedChargeRemaining;
		WriteBatteryPercent -Append 1;
	}
	Start-Sleep -s 10;
}

pause;