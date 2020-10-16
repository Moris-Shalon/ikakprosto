function AllocateMemory {
	
	$dateTime = (Get-Date).ToString('yyyy-MM-dd-HH-mm-ss')
	Get-PSDrive -PSProvider 'FileSystem'
    $Drives = Get-PSDrive -PSProvider 'FileSystem' | Foreach-Object {$_.Name}
    #Write-Output "`nAvailable local drives:"
    #foreach ($DriveName in $Drives) {Write-Output $DriveName}
	$ChoosedDrive = Read-Host -Prompt "`nPlease choose your drive for test (write only letter, check 'Name' column)"
	# against Layer8
	$ChoosedDrive = $ChoosedDrive.ToUpper() 
	#$ChoosedDrivecolon = ($ChoosedDrive + ":")

	$ChoosedDrivecolon = ( $ChoosedDrive + ":")

	if ($Drives.Contains($ChoosedDrive)) {
		$FreeSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ChoosedDrivecolon'" | Foreach-Object {"{0:N0}" -f ($_.FreeSpace / 1GB)}
		$FreeSpace = $FreeSpace -as [uint16]

		Write-Output "Your Free Space: $FreeSpace GB" #Get-PSDrive gives info in GB

	    [uint16]$SpaceToAllocateGB = Read-Host -Prompt "Please, enter the number of GiB you would like to allocate (from 1 to $FreeSpace GB)"
	    # Variants of function without FreeSpaceGiB variable
	    #$SpaceToAllocateGB = ([math]::Truncate(($FreeSpace-(70*1024*1024*1024))/1024/1024/1024))

		if ($ChoosedDrive -eq "C") 
		{
            $WritePath = "$HOME\Desktop\" + $dateTime + "testmemory"
		} 
		else
		{
            $WritePath = ($ChoosedDrive + ":\" + $dateTime + "testmemory")
        }

		if (($SpaceToAllocateGB -gt 0) -and ($SpaceToAllocateGB -le $FreeSpace)) 
		{
			Write-Output "Going to allocate: $SpaceToAllocateGB GB"
			
			if (Test-Path -LiteralPath $WritePath -PathType Any) 
			{ 
			    Write-Output "Path '$WritePath' already exists" 
			} 
			else 
			{
		    	New-Item -ItemType directory -Path $WritePath | Foreach-Object {$_.FullName}
			} 
			
			Write-Output "`nGenerating 1 GB of random data`n"

		    $out = new-object byte[] (1000*1000*1000) # stay in GB metric
			(new-object Random).NextBytes($out)
			Write-Output "Writing random data to multiple files in '$WritePath'`n"
			Measure-Command -Expression{
					for ($i=1; $i -le $SpaceToAllocateGB; $i++) 
					{ 
						$filename = (Get-Date).ToString('yyyy-MM-dd-HH-mm-ss')
						[IO.File]::WriteAllBytes("$WritePath\$filename", $out)

						Write-Host "`rAllocated $i/$SpaceToAllocateGB GB" -NoNewline

						if ($i -eq $SpaceToAllocateGB) 
						{
							Write-Host "`rAllocated $i/$SpaceToAllocateGB GB"
						}
					}
			}

            Write-Output "Done. `n"
		} 
		else 
		{ 
            Clear-Host
		    Write-Output "You have entered wrong value, please check your available free space."
            AllocateMemory
	    }
	}

	else
	{
        Clear-Host
        Write-Output "You have entered wrong drive, please choose another one `n" 
        AllocateMemory
    }
}

AllocateMemory

pause