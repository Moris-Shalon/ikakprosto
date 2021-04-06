function AllocateMemory {
	Write-Output ""
	Get-PSDrive -PSProvider 'FileSystem'
	$Drives = Get-PSDrive -PSProvider 'FileSystem' | Foreach-Object {$_.Name} 
	#Write-Output "`nAvailable local drives:"
	#foreach ($DriveName in $Drives) {Write-Output $DriveName}
	$ChoosedDrive = Read-Host -Prompt "`nPlease choose your drive for test (write only letter, check 'Name' column)"
	$ChoosedDrivecolon = ($ChoosedDrive + ":")

	if ($Drives.Contains($ChoosedDrive)) {
		[uint64]$FreeSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$ChoosedDrivecolon'" | 
		Foreach-Object { $_.FreeSpace }
		[uint16]$FreeSpaceGiB = ([math]::Truncate($FreeSpace / 1024 / 1024 / 1024))
		# $FreeSpaceGiB.GetType().fullname
		Write-Output "Your Free Space: $FreeSpaceGiB GiB"
		[uint16]$SpaceToAllocateGiB = [uint16](Read-Host -Prompt @(
				"`nPlease, enter the number of GiB you would like to allocate (from 1 to $FreeSpaceGiB)."
				"`nYou can enter 0 or Enter (leave empty) to allocate all space (excluding 70 GiB)."
				"`nDon't enter anything except numbers!"
			))

		if ($SpaceToAllocateGiB -eq 0) {
			if ($FreeSpaceGiB -le 70) {
				Write-Output @( 
					"`nYou don't need to allocate memory on your drive $ChoosedDrivecolon"
					"`nYour free space is already lower or equal to 70 GiB"
					"`nPlease, try another drive."
					"`nTo exit press 'Ctrl+C' "
					"`nPress any key to continue..."
				);
				$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
				Clear-Host
				AllocateMemory
			}
			else {
				[uint16]$SpaceToAllocateGiB = $FreeSpaceGiB - 70
			}
		}
		# $SpacetoAllocateGiB.GetType().fullname
		# Variants of function without FreeSpaceGiB variable
		#$SpaceToAllocateGiB = ([math]::Truncate(($FreeSpace-(70*1024*1024*1024))/1024/1024/1024))

		if ($ChoosedDrive -eq "C") { $WritePath = "$HOME\Desktop\testmemory" } else {
			$WritePath = ($ChoosedDrive + ":\testmemory")
		}

		if (($SpaceToAllocateGiB -gt 0) -and ($SpaceToAllocateGiB -le $FreeSpaceGiB)) {

			if (Test-Path -LiteralPath $WritePath -PathType Any) { 
				Write-Output "`n$WritePath allready exist. Going to allocate: $SpaceToAllocateGiB GiB of test data"
			} 
			else {
				Write-Output "`n$WritePath will be creating to allocate: $SpaceToAllocateGiB GiB of test data"
				New-Item -ItemType directory -Path $WritePath | Foreach-Object { $_.FullName } | Out-Null
			}
						
			Write-Output "`nGenerating 1 GiB of random data"
			try {
				$out = new-object byte[] (1024 * 1024 * 1024)
				(new-object Random).NextBytes($out)				
			}
			catch {
				Write-Warning "`nNew-Object generating exception  $_.Exception.Message" 
			}

			Write-Output "Writing random data to multiple files in '$WritePath'`n"
			$MeasureCommand = Measure-Command -Expression {
				for ($i = 1; $i -le $SpaceToAllocateGiB; $i++) { 
					$filename = Get-Date -Format HH.mm.ss.fff
					Measure-Command -Expression { [IO.File]::WriteAllBytes("$WritePath\$filename", $out) } | Foreach-Object { 
						try {
							$AllocationSpeed = [Math]::Round(1024 / ($_.TotalSeconds), 2)
							Write-Host @(
								if ($i -le $SpaceToAllocateGiB) { 
									Write-Output "Allocated $i/$SpaceToAllocateGiB GiB Current file write speed = $AllocationSpeed MiB/sec"
								}
							)
						}
						catch {							
							Write-Warning "`nAllocationSpeed Calculation exception  $_.Exception.Message" 
						}
					}
				} 
			}

			Write-Output $MeasureCommand 
			ForEach ($i in $MeasureCommand) { 
				try {
					$AvgAllocationSpeed = [Math]::Round(1024 * $SpaceToAllocateGiB / ($MeasureCommand.TotalSeconds), 2) 
					Write-Output @(
						"`nAverage Allocation Speed = $AvgAllocationSpeed MiB/sec"
						"`nDone. `n"
					)						
				}
				catch {
					Write-Warning "AvgAllocationSpeed Calculation exception  $_.Exception.Message" 
				}
			}
		}
		else {
			Write-Output @(
				"`nYou have entered wrong value, please check your available free space."
				"`nTo exit press 'Ctrl+C'"
				"`nPress any key to continue..."
			)
			$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
			Clear-Host
			AllocateMemory
		}
	} 
	else {
		Write-Output @(
			"`nYou have entered wrong drive, please choose another one"
			"`nTo exit press 'Ctrl+C'"
			"`nPress any key to continue..."
		)

		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
		Clear-Host
		AllocateMemory
	}
}

AllocateMemory

Pause