function AllocateMemory {
    Get-PSDrive -PSProvider 'FileSystem'
    $Drives = Get-PSDrive -PSProvider 'FileSystem' | Foreach-Object {$_.Name}
    #Write-Output "`nAvailable local drives:"
    #foreach ($DriveName in $Drives) {Write-Output $DriveName}
    $ChoosedDrive = Read-Host -Prompt "`nPlease choose your drive for test (write only letter, check 'Name' column)"

    $ChoosedDrivecolon = ($ChoosedDrive + ":")
    if ($Drives.Contains($ChoosedDrive)) {
	    $FreeSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ChoosedDrivecolon'" | Foreach-Object {$_.FreeSpace}
	    $FreeSpaceGiB = ([math]::Truncate($FreeSpace/1024/1024/1024))
	    Write-Output "Your Free Space: $FreeSpaceGiB GiB"
	    $SpaceToAllocateGiB = ($FreeSpaceGiB - 70)
	    # Variants of function without FreeSpaceGiB variable
	    #$SpaceToAllocateGiB = ([math]::Truncate(($FreeSpace-(70*1024*1024*1024))/1024/1024/1024))
	    Write-Output "Going to allocate: $SpaceToAllocateGiB GiB"

        if ($ChoosedDrive -eq "C") {
            $WritePath = "$HOME\Desktop\testmemory"
        } else {
            $WritePath = ($ChoosedDrive + ":\testmemory")
        }

	    if ($SpaceToAllocateGiB -gt 0) { 
		    if (Test-Path -LiteralPath $WritePath -PathType Any) { 
			    Write-Output "Path '$WritePath' already exists" 
		    } else { 
		    New-Item -ItemType directory -Path $WritePath | Foreach-Object {$_.FullName}
		    } 
            Write-Output "`nGenerating 1GiB of random data`n"
		    $out = new-object byte[] (1024*1024*1024)
		    (new-object Random).NextBytes($out)
            Write-Output "Writing random data to multiple files in '$WritePath'`n"
		    Measure-Command -Expression {for ($i=1; $i -le $SpaceToAllocateGiB; $i++) { 
			    $filename = Get-Date -Format HH.mm.ss.fff
			    [IO.File]::WriteAllBytes("$WritePath\$filename", $out) 
				Write-Host "`rAllocated $i/$SpaceToAllocateGiB GiB" -NoNewLine
				if ($i -eq $SpaceToAllocateGiB) {Write-Host "`rAllocated $i/$SpaceToAllocateGiB GiB"}
		    } }
            Write-Output "Done. `n"
	    } else { 
            Clear-Host
		    Write-Output "You don't need to allocate memory on your drive $ChoosedDrivecolon"
            Write-Output "Your free space is already lower or equal to 70 GiB"
            Write-Output "Please, try another drive."
            Write-Output "To exit press 'Ctrl+C' `n"
            AllocateMemory
	    }
    } else {
        Clear-Host
        Write-Output "You have entered wrong drive, please choose another one `n" 
        AllocateMemory
    }
}

AllocateMemory

pause