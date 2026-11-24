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
$exePath = (Get-ChildItem $Pwdir | Where-Object {$_.Extension -eq ".exe" -and $_.name -like "*VSCodeSetup*"}).FullName
$appNamePwd = split-path $Pwdir -Leaf

$logFile = "$($Pwdir)\$($appNamePwd)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"  
Add-Content -Path $logFile -Value "INFO: Start of uninstalling App Process @ $appNamePwd" 

    if ($exePath) 
        {
       
            $process = Start-Process -FilePath $exePath `
                                     -ArgumentList  @(
                                            '/VERYSILENT'
                                            '/SUPPRESSMSGBOXES'
                                            '/SP-'
                                            '/NORESTART'
                                            '/NORESTARTAPPLICATIONS' 
                                            '/LOG="{0}"' -f "C:\Windows\Temp\$appNamePwd.log"
                                            '/MERGETASKS="addtopath,associatewithfiles,!runcode"'
                                        ) `
                                     -Wait `
                                     -PassThru `
                                     -RedirectStandardOutput $logFile `
                                     -RedirectStandardError  "$logFile.err"

            # Merge error log into main log if it has content
            if (Test-Path "$logFile.err") {
                $errContent = Get-Content "$logFile.err"
                if ($errContent) {
                    Add-Content -Path $logFile -Value "`r`n--- ERRORS ---"
                    Add-Content -Path $logFile -Value $errContent
                }
                Remove-Item "$logFile.err" -Force
            }

            # Check exit code
            if ($process.ExitCode -eq 0) {
                #WriteToScreen -Header "Status" -Value "Install SUCCESS: $($jsonApps.name)" -Color Green
                Add-Content -Path $logFile -Value "EXIT CODE: $($process.ExitCode) - SUCCESS"
            }
            else {
                #WriteToScreen -Header "Status" -Value "Install FAILED: $($jsonApps.name) (Exit code $($process.ExitCode))" -Color Red
                Add-Content -Path $logFile -Value "EXIT CODE: $($process.ExitCode) - FAILED"
            }
        }
    else 
            {
                    Add-Content -Path $logFile -Value "ERROR: No .exe found in $Pwdir" 
            }

#Disable Autoupdate
$regPathKey = "HKLM:\SOFTWARE\Policies\Microsoft\VSCode"
    try   
        {
            New-Item -Path $regPathKey -Force -ErrorAction Stop
            Add-Content -Path $logFile -Value "New-Item -Path $regPathKey EXIT CODE: $($process.ExitCode) - SUCCESS"
        }
    catch
        {
            Add-Content -Path $logFile -Value "New-Item -Path $regPathKey EXIT CODE: $($process.ExitCode) - FAILED"
        }

    try   
        {
            Set-ItemProperty -Path $regPathKey -Name UpdateMode -Value "none" -Type String -Force -ErrorAction Stop
            Add-Content -Path $logFile -Value "Set-ItemProperty -Path $regPathKey -Name UpdateMode -Value none -Type String EXIT CODE: $($process.ExitCode) - SUCCESS"
        }
    catch
        {
            Add-Content -Path $logFile -Value "Set-ItemProperty -Path $regPathKey -Name UpdateMode -Value none -Type String EXIT CODE: $($process.ExitCode) - FAILED"
        }




<#$programsFolder = [Environment]::GetFolderPath('CommonPrograms')
$codeExe = 'C:\Program Files\Microsoft VS Code\Code.exe'

    if (-not (Test-Path -LiteralPath $codeExe -PathType Leaf)) {
        throw "VS Code executable not found at $codeExe"
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut(
        (Join-Path $programsFolder 'Visual Studio Code.lnk')
    )

    $shortcut.TargetPath = $codeExe
    $shortcut.Arguments = '--disable-extension vscode.microsoft-authentication'
    $shortcut.WorkingDirectory = Split-Path -LiteralPath $codeExe
    $shortcut.Save()
    #>