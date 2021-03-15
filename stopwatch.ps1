$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch;
$StopWatch.Start();
$timepassedticks = $StopWatch.Elapsed.Ticks
while ($true) {
	if (($StopWatch.Elapsed.Ticks - $timepassedticks) -ge 600000000) {
		$StopWatch.Stop();
		$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch;
		$StopWatch.Start();
	}
	$timepassedticks = $StopWatch.Elapsed.Ticks;
    $timepassedstring = $StopWatch.Elapsed.ToString();
    Write-Host "`r $timepassedstring" -NoNewLine;
    Start-Sleep 1	
};
$StopWatch.Stop();
$StopWatch.IsRunning;