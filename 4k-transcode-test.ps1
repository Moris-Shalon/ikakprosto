$outputdir = "$PSScriptRoot\ffmpeg-test"
$inputfile = "$PSScriptRoot\Sony Surfing 4K Demo.mp4"
$ffmpeg = "$PSScriptRoot\ffmpeg\bin\ffmpeg.exe"

while (-not (Test-Path -LiteralPath $inputfile -PathType Leaf)) {
	$inputfile = Read-Host -Prompt "`nCouldn't find Demo video. Please, specify it's location manually"
	$inputfile = $inputfile.Replace('"', '')
}


while (-not (Test-Path -LiteralPath $ffmpeg -PathType Leaf)) {
	$ffmpeg = Read-Host -Prompt "`nCouldn't find your ffmpeg binary location. Please, specify it's location manually"
	$ffmpeg = $ffmpeg.Replace('"', '')
}

function TranscodeTest ($inputfile, $outputdir, $ffmpeg) {
    # Here we are cutting everything beside QSV, CUDA and AMD Video Core Next (Video Coding Enging and Unified Video Decoder)
	#$hwaccels = @( Invoke-Expression -Command "& '$ffmpeg' -hwaccels -hide_banner -loglevel panic" | ?{$_ -notmatch 'Hardware acceleration methods:'} | ?{$_.trim() -ne "DXVA2"} | ?{$_.trim() -ne "D3D11VA"} | ?{$_.trim() -ne ""})
    $hwaccels = @( Invoke-Expression -Command "& '$ffmpeg' -hwaccels -hide_banner -loglevel panic" | ?{$_ -notmatch 'Hardware acceleration methods:'} | ?{$_.trim() -ne ""})
    #$hwaccels = @('cuda', 'qsv', 'amf')
    Write-Output "`nAvailable hardware acceleration methods:"
    
    foreach ($hwaccel in $hwaccels) {Write-Output $hwaccel}
	Write-Output "`n"
	if ($hwaccels.Contains("qsv")) {Write-Output "QSV stays for Intel Quick Sync Video"}
	if ($hwaccels.Contains("cuda")) {Write-Output "CUDA stays for NVidia NVENC encoder and CUVID decoder"}
    if ($hwaccels.Contains("d3d11va") -Or $hwaccels.Contains("dxva2")) {Write-Output "DXVA2 stays for Direct3D9 and D3D11VA stays for Direct3D11 Video Acceleration. Use them for universal hardware acceleration. You can also use them for AMD Universal Video Decode (automatically toggles AMF for AMD Video Coding Engine)"}
    if ($hwaccels.Count -ne 0) {$Choosedhwaccel = (Read-Host -Prompt "`nPlease choose your hardware acceleration method for test (enter it's name or leave empty to test without HW acceleration)").ToLower()}
    If ($hwaccels.Contains($Choosedhwaccel) -Or $Choosedhwaccel -eq "" -Or $Choosedhwaccel -eq $null) {
		If (Test-Path -LiteralPath $outputdir -PathType Any) { 
			Write-Output "`nPath '$outputdir' already exists`n" 
		} else { 
			New-Item -ItemType directory -Path $outputdir | Foreach-Object {$_.FullName}
		} 
		If ($hwaccels.Contains($Choosedhwaccel)) {
			If ($Choosedhwaccel -eq "qsv") { 
				$Manufacturer = "intel-"
				$Decoder = "_qsv"
				$Encoder = "_qsv"
			} ElseIf ($Choosedhwaccel -eq "d3d11va" -Or $Choosedhwaccel -eq "dxva2") { 
                $AMDchoose = $Host.UI.PromptForChoice("DirectX hardware acceleration", "Would you like to use AMD acceleration (UVD and VCE)?", @('&Yes', '&No'), 1)
                if ($AMDchoose -eq 0) {
                    $Manufacturer = "amd-"
				    $Decoder = ""
				    $Encoder = "_amf" 
                } Else {
                    $Manufacturer = ""
				    $Decoder = ""
				    $Encoder = "" 
                }
			}
			ElseIf ($Choosedhwaccel -eq "cuda") { 
				$Manufacturer = "nvidia-"
				$Decoder = "_cuvid"
				$Encoder = "_nvenc"
			}
            $ffmpegpre = "-benchmark -hide_banner -hwaccel $Choosedhwaccel -c:v hevc$Decoder -i"
            $OperationChoose = $Host.UI.PromptForChoice("Transcode/Decode Choose", "Would you like to transcode from H.265 to H.264, or just decode H.265 video, or do both operations?", @('&Transcode', '&Decode', '&Both'), 2)
			If ($OperationChoose -eq 0 -Or $OperationChoose -eq 2 ) {
				$outfile = "$outputdir\$Manufacturer$Choosedhwaccel-h265-4K-8-bit-60FPS-transcode-h264"
                $outfilecreationchoice = $Host.UI.PromptForChoice("MP4 file creation choice", "Would you like to create/store .mp4 output file after transcoding media?", @('&Yes', '&No'), 1)
				If ($outfilecreationchoice -eq 0) { 
					$outfilecreation = "'$outfile.mp4'"
				} Else { 
					$outfilecreation = "-f null -"
				}
				$ffmpegpost = "-c:v h264$Encoder -c:a copy -map 0:v:0 -map 0:a:0 -vsync 0 -qmin 18 -qmax 24 $outfilecreation"
				Measure-Command -Expression { Invoke-Expression "& '$ffmpeg' $ffmpegpre '$inputfile' $ffmpegpost" } | Tee-Object -file "$outfile.txt"
				If ($outfilecreationchoice -eq 0) {
					echo("File Size (bytes) = " + ((Get-Item "$outfile.mp4").Length)) | Tee-Object -file "$outfile.txt" -Append
					echo("File Size (KiB) = " + ((Get-Item "$outfile.mp4").Length)/1KB) | Tee-Object -file "$outfile.txt" -Append
					echo("File Size (MiB) = " + ((Get-Item "$outfile.mp4").Length)/1MB) | Tee-Object -file "$outfile.txt" -Append
					echo("File Size (GiB) = " + ((Get-Item "$outfile.mp4").Length)/1GB) | Tee-Object -file "$outfile.txt" -Append
					Write-output `n | Out-File "$outfile.txt" -Append
					& {Invoke-Expression "& '$ffmpeg' -hide_banner -i '$outfile.mp4'"} 2>&1 | % ToString | Tee-Object -file "$outfile.txt" -Append
				}
            }
            If ($OperationChoose -eq 1 -Or $OperationChoose -eq 2 ) {
                $outfile = "$outputdir\$Manufacturer$Choosedhwaccel-h265-4K-8-bit-60FPS-decode"
                Measure-Command -Expression { Invoke-Expression "& '$ffmpeg' $ffmpegpre '$inputfile' -f null -" } | Tee-Object -file "$outfile.txt"
            }
		} Else {
            $ffmpegpre = "-benchmark -hide_banner -c:v hevc -i"
			$OperationChoose = $Host.UI.PromptForChoice("Transcode/Decode Choose", "Would you like to transcode from H.265 to H.264, or just decode H.265 video, or do both operations?", @('&Transcode', '&Decode', '&Both'), 2)
			If ($OperationChoose -eq 0 -Or $OperationChoose -eq 2 ) {
				$outfilecreationchoice = $Host.UI.PromptForChoice("MP4 file creation choice", "Would you like to create/store .mp4 output file after transcoding media?", @('&Yes', '&No'), 1)
                ForEach ($crf in @('', '-crf 0')) {
                    if ($crf -eq '') {
                        $outfile = "$outputdir\cpuonly-h265-4K-8-bit-60FPS-transcode-h264"
                    } Else {
                        $outfile = "$outputdir\cpuonly-h265-4K-8-bit-60FPS-transcode-h264-crf0"
                    }
					If ($outfilecreationchoice -eq 0) { 
						$outfilecreation = "'$outfile.mp4'"
					} Else { 
						$outfilecreation = "-f null -"
					}
					$ffmpegpost = "-c:v h264 -c:a copy -map 0:v:0 -map 0:a:0 -vsync 0 $crf -qmin 18 -qmax 24 $outfilecreation"
			        Measure-Command -Expression { Invoke-Expression "& '$ffmpeg' $ffmpegpre '$inputfile' $ffmpegpost" } | Tee-Object -file "$outfile.txt"
					If ($outfilecreationchoice -eq 0) {
						echo("File Size (bytes) = " + ((Get-Item "$outfile.mp4").Length)) | Tee-Object -file "$outfile.txt" -Append
						echo("File Size (KiB) = " + ((Get-Item "$outfile.mp4").Length)/1KB) | Tee-Object -file "$outfile.txt" -Append
						echo("File Size (MiB) = " + ((Get-Item "$outfile.mp4").Length)/1MB) | Tee-Object -file "$outfile.txt" -Append
						echo("File Size (GiB) = " + ((Get-Item "$outfile.mp4").Length)/1GB) | Tee-Object -file "$outfile.txt" -Append
						Write-output `n | Out-File "$outfile.txt" -Append
						& {Invoke-Expression "& '$ffmpeg' -hide_banner -i '$outfile.mp4'"} 2>&1 | % ToString | Tee-Object -file "$outfile.txt" -Append
					}
                }
            }
            If ($OperationChoose -eq 1 -Or $OperationChoose -eq 2 ) {
                $outfile = "$outputdir\cpyonly-h265-4K-8-bit-60FPS-decode"
			    Measure-Command -Expression { Invoke-Expression "& '$ffmpeg' $ffmpegpre '$inputfile' -f null -"} | Tee-Object -file "$outfile.txt"
            }
		}
        Write-Output "`nDone. `n"
    } else {
        Clear-Host
        Write-Output "You have entered wrong hardware acceleration method, please choose another one `n" 
        TranscodeTest -inputfile $inputfile -outputdir $outputdir -ffmpeg $ffmpeg
    }
}

TranscodeTest -inputfile $inputfile -outputdir $outputdir -ffmpeg $ffmpeg

pause