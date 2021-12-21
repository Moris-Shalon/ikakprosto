function AllocateMemory {
    Write-Output "";
    Get-PSDrive -PSProvider 'FileSystem';
    $Drives = Get-PSDrive -PSProvider 'FileSystem' | Foreach-Object {$_.Name};
    #Write-Output "`nAvailable local drives:";
    $ChoosedDrive = Read-Host -Prompt "`nPlease choose your drive for test (write only letter, check 'Name' column)";

    $ChoosedDrivecolon = ($ChoosedDrive + ":");
    if ($Drives.Contains($ChoosedDrive)) {
        [uint64]$FreeSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ChoosedDrivecolon'" | Foreach-Object {$_.FreeSpace};
        [uint16]$FreeSpaceGiB = ([math]::Truncate($FreeSpace/1024/1024/1024));
        # $FreeSpaceGiB.GetType().fullname;
        Write-Output "Your Free Space: $FreeSpaceGiB GiB";
        [uint16]$SpaceToAllocateGiB = [uint16](Read-Host -Prompt "Please, enter the number of GiB you would like to allocate (from 1 to $FreeSpaceGiB).`nYou can enter 0 or Enter (leave empty) to allocate all space (excluding 70 GiB). `nDon't enter anything except numbers!`n");
        if ($SpaceToAllocateGiB -eq 0) {
            if ($FreeSpaceGiB -le 70) {
                Write-Output "You don't need to allocate memory on your drive $ChoosedDrivecolon";
                Write-Output "Your free space is already lower or equal to 70 GiB";
                Write-Output "Please, try another drive.";
                Write-Output "To exit press 'Ctrl+C' ";
                Write-Output "Press any key to continue...";
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                Clear-Host;
                AllocateMemory;
            } else {
                [uint16]$SpaceToAllocateGiB = $FreeSpaceGiB - 70;
            }
        }
        # Variants of function without FreeSpaceGiB variable;
        # $SpaceToAllocateGiB = ([math]::Truncate(($FreeSpace-(70*1024*1024*1024))/1024/1024/1024));

        if ($ChoosedDrive -eq "C") {
            $WritePath = "$HOME\Desktop\testmemory";
        } else {
            $WritePath = ($ChoosedDrive + ":\testmemory");
        }

        if (($SpaceToAllocateGiB -gt 0) -and ($SpaceToAllocateGiB -le $FreeSpaceGiB)) {
            Write-Output "`nGoing to allocate: $SpaceToAllocateGiB GiB";
            if (Test-Path -LiteralPath $WritePath -PathType Any) {
                Write-Output "Path '$WritePath' already exists";
            } else { 
                New-Item -ItemType directory -Path $WritePath | Foreach-Object {$_.FullName};
            }
            Write-Output "`nGenerating 1 GiB of random data`n";
            $out = new-object byte[] (1024*1024*1024);
            (new-object Random).NextBytes($out);
            #$logfile="$PSScriptRoot\Allocate-Memory-log.csv";
            $logfile="Allocate-Memory-log.csv";
            if (-not (Test-Path -LiteralPath "$logfile" -PathType Leaf)) {
                Set-Content -Path "$logfile" -Value "GiBwritten;Speed (MiB/sec);TimeSpent (seconds);";
            } else {
                Add-Content -Path "$logfile" -Value ";;;running test one more time at $(Get-Date -Format 'yyyy.MM.dd_HH:mm:ss.fff')";
                Add-Content -Path "$logfile" -Value "GiBwritten;Speed (MiB/sec);TimeSpent (seconds);";
            }
            $MaxAllocationSpeed = $([Double]::MinValue);
            $MinAllocationSpeed = $([Double]::MaxValue);
            Write-Output "Writing random data to multiple files in '$WritePath'`n";
            $MeasureCommand = Measure-Command -Expression {for ($i=1; $i -le $SpaceToAllocateGiB; $i++) {
                $filename = Get-Date -Format HH.mm.ss.fff;
                Measure-Command -Expression {[IO.File]::WriteAllBytes("$WritePath\$filename", $out)} | ForEach { 
                    [Double]$AllocationSpeed = $([Math]::Round(1024/($_.TotalSeconds), 2));
                    if ($AllocationSpeed -gt $MaxAllocationSpeed) { $MaxAllocationSpeed = $AllocationSpeed; };
                    if ($AllocationSpeed -lt $MinAllocationSpeed) { $MinAllocationSpeed = $AllocationSpeed; };
                    [String]$AllocationSpeedString = $AllocationSpeed -replace "\.",",";
                    $TimeSpent = [String]$_.TotalSeconds -replace "\.",",";
                };
                Write-Host "`rAllocated $i/$SpaceToAllocateGiB GiB. Current file write speed = $AllocationSpeed MiB/sec." -NoNewLine;
                Add-Content -Path "$logfile" -Value "$i;$AllocationSpeedString;$TimeSpent;";
                if ($i -eq $SpaceToAllocateGiB) {Write-Host ""};
                }
            }
            Write-Output $MeasureCommand;
            ForEach ($i in $MeasureCommand) { $AvgAllocationSpeed = [Math]::Round(1024*$SpaceToAllocateGiB/($MeasureCommand.TotalSeconds), 2) };
            Write-Output "Allocation Speed (MiB/sec): Average = $AvgAllocationSpeed, Min = $MinAllocationSpeed, Max = $MaxAllocationSpeed.`n";
            Write-Output "Done. `n";
        } else {
            Write-Output "You have entered wrong value, please check your available free space.";
            Write-Output "To exit press 'Ctrl+C'";
            Write-Output "Press any key to continue...";
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
            Clear-Host;
            AllocateMemory;
        }
    } else {
        Write-Output "You have entered wrong drive, please choose another one";
        Write-Output "To exit press 'Ctrl+C'";
        Write-Output "Press any key to continue...";
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        Clear-Host;
        AllocateMemory;
    }
}

AllocateMemory;

pause;
