function WriteBatteryPercent ([int]$Append, [int]$Sleep) {
	if ($Append -ne 0) {
		Write-Output (([string](Get-WmiObject Win32_Battery).EstimatedChargeRemaining) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt" -Append;
	} else {
		Write-Output (([string](Get-WmiObject Win32_Battery).EstimatedChargeRemaining) + ';' + (Get-Date -Format "%H:%m:s")) `
		| Tee-Object -Filepath "battery_test_log.txt";
	}
	if ($Sleep -ne 0) {
		Start-Sleep -s $Sleep
	}
}

Write-Output "battery percentage;time" | Tee-Object -Filepath "battery_test_log.txt";
$BatteryPercent = (Get-WmiObject Win32_Battery).EstimatedChargeRemaining;
WriteBatteryPercent -Append 0 -Sleep 10;


while ($true) { `
    if ($BatteryPercent -ne (Get-WmiObject Win32_Battery).EstimatedChargeRemaining) {
		$BatteryPercent = (Get-WmiObject Win32_Battery).EstimatedChargeRemaining;
		WriteBatteryPercent -Append 1 -Sleep 10;
	}
}

pause;