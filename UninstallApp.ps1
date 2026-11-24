param(
    $logPath
)


if($psise -ne $null)
    {
        $ISEPath = $psise.CurrentFile.FullPath
        $ISEDisp = $psise.CurrentFile.DisplayName.Replace("*","")
        $Pwdir = $ISEPath.TrimEnd("$ISEDisp")
    }
else
    {
        $Pwdir = split-path -parent $MyInvocation.MyCommand.Path
    }

# Get the exe path
#$exePath = (Get-ChildItem $Pwdir | Where-Object { $_.Extension -eq ".exe" }).FullName

$exePath =  "C:\Program Files\Microsoft VS Code\unins000.exe"

$appNamePwd = split-path $Pwdir -Leaf
$logFile = "$($Pwdir)\$($appNamePwd)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Add-Content -Path $logFile -Value "INFO: Start of installing App Process @ $appNamePwd"

Try
    {
        Get-ChildItem $exePath -ErrorAction Stop
        if ($exePath)
            {
                $process = Start-Process -FilePath $exePath `
                    -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' `
                    -Wait `
                    -PassThru `
                    -RedirectStandardOutput "$logFile.out" `
                    -RedirectStandardError "$logFile.err" `
                    -ErrorAction Stop

                # Check exit code
                if ($process.ExitCode -eq 0) {
                    #WriteToScreen -Header "Status" -Value "Install SUCCESS: $($jsonApps.name)" -Color Green
                    Add-Content -Path $logFile -Value "EXIT CODE: $($process.ExitCode) - SUCCESS"
                }
                else {
                    #WriteToScreen -Header "Status" -Value "Install FAILED: $($jsonApps.name) (Exit code $($process.ExitCode))" -Color Red
                    Add-Content -Path $logFile -Value "EXIT CODE: $($process.ExitCode) - FAILED"
                }
                exit $process.ExitCode
            }
        else
                {
                    Add-Content -Path $logFile -Value "ERROR: No .exe found in $Pwdir"
                }
    }
catch
    {
        Add-Content -LiteralPath $logFile -Value "ERROR: Failed to run '$exePath'. $($_.Exception.Message)"
        exit 1
    }