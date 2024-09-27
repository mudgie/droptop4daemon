# Global variables
#############################################################################
$rainmeterLocalPath = "${Env:ProgramFiles}\Rainmeter\Rainmeter.exe"
$pollRate = 5 # Adjust for older/shit CPUs
$testedWinVersion = 22621 #22621 = v22H2
$testedPSVersion = 7.4
$topValueThreshold = 1
$scriptVersion = 1.0


# Welcome message
#############################################################################
$reset = "`e[0m" # Set back to system colour default
$red = "`e[31m"
$cyan = "`e[36m"
Write-Output ""
Write-Output "${red}DropTopFourDaemon v${scriptVersion}!$reset"
Write-Output "${cyan}github.com/mudgie/droptop4daemon$reset"
Write-Output ""


# Timestamp
#############################################################################
function Global:timeStamp {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}


# Compatability warnings
#############################################################################
function powerShellBuildNumber {
    $version = $PSVersionTable.PSVersion
    return "$($version.Major).$($version.Minor)"
}


# System warnings array
$Global:systemWarnings = New-Object System.Collections.ArrayList
# Clear old session
$systemWarnings.Clear()


# Check tested version is installed locally (7.4)
#############################################################################
if ((powerShellBuildNumber) -lt $testedPSVersion) {
    $systemWarnings.Add(( 
        [Pscustomobject]@{
            Status = "Warning";
            timeStamp = timeStamp;
            Value = "Not tested on lower than PowerShell 7.4"
        }
    ))
}


# Get Windows build number
#############################################################################
function Global:windowsBuild {
    $formattedNumber = [System.Environment]::OSVersion.Version.Build
    return $formattedNumber
}

if (-not $windowsBuild -lt $testedWinVersion) {
    $systemWarnings.Add(( 
        [Pscustomobject]@{
            Status = "Warning";
            timeStamp = timeStamp;
            Value = "Not tested on lower than Windows 11 Pro 22H2"
        }
    ))
}

# Display system warnings
$systemWarnings


# Get the reserved screen coords from user32.dll
#############################################################################
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ScreenWorkArea {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int left, top, right, bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(int uAction, int uParam, ref RECT lpvParam, int fuWinIni);

    public static RECT GetWorkArea() {
        RECT rect = new RECT();
        SystemParametersInfo(48, 0, ref rect, 0);
        return rect;
    }
}
"@


# Check if RainMeter process is responding
#############################################################################
function rainmeterResponding {
    if (Get-Process -Name "rainmeter" -ErrorAction SilentlyContinue | Select-Object -Property Responding) {
        return $true
    }
    else {
        return $false
    }
}


# Restart DropTop
#############################################################################
$Global:errorTable = New-Object System.Collections.ArrayList

function restartDropTop {
    if (-not (rainmeterResponding))
    {
        # Kill RainMeter process
        $errorTable.Add(( 
            [Pscustomobject]@{
                Status = "Error";
                timeStamp = timeStamp;
                Value = "RainMeter.exe is not running"
            }
        ))

        $rainMeterProcess = Get-Process -Name "rainmeter" -ErrorAction SilentlyContinue

        if ($rainMeterProcess) {
            Stop-Process -Name $rainMeterProcess -Force

            # Pause script until process has been killed
            while (Get-Process -Name $rainMeterProcess -ErrorAction SilentlyContinue) {
                Start-Sleep -Seconds 1 
            }
        } else {
            # Start RainMeter and DropTop again
            Start-Process $rainmeterLocalPath -ArgumentList "!ActivateConfig Droptop\Other\BackgroundProcesses BackgroundProcesses.ini"

            # Wait for RainMeter process to start before continuing
            while (-not (Get-Process -Name $rainMeterProcess -ErrorAction SilentlyContinue)) {
                Start-Sleep -Seconds 1 
            }
        }
    }
}


# Check if DropTop is okay every X seconds
#############################################################################
$resultsTable = New-Object System.Collections.ArrayList

# Get current screen reserved space info
$workArea = [ScreenWorkArea]::GetWorkArea()

$infoTable = @()
$infoTable += [PSCustomObject]@{
    Info = "Timestamp";
    Value = timeStamp
}
$infoTable += [PSCustomObject]@{
    Info = "Top reserved area value";
    Value =  $workArea.top
}
$infoTable += [PSCustomObject]@{
    Info = "Local system build number";
    Value = windowsBuild
}

$infoTable | Format-Table -AutoSize

# Start the check loop
while ($true) {    
    # Top reserved space value is wrong!
    if ($($workArea.top) -lt $topValueThreshold) {
        $errorTable.Add(( 
            [Pscustomobject]@{
                Status = "Error";
                timeStamp = timeStamp;
                Message = "The Windows top reserved space coord is wrong, restarting DropTop"
           }
        ))
        restartDropTop
    }
    else {
        $resultsTable += [PSCustomObject]@{
            Status = "Success";
            TimeStamp = timeStamp;
            Message = "Top reserved space coord is acceptable"
        }
    }
    
    # Everything appears okay
    if (rainmeterResponding) {
        $resultsTable += [PSCustomObject]@{
            Status = "Success";
            TimeStamp = timeStamp;
            Message = "RainMeter.exe process is responding"
        }
        $resultsTable += [PSCustomObject]@{
            Status = "Success";
            TimeStamp = timeStamp;
            Message = "Everything appears okay, no action required"
        }
    }
    
    $resultsTable | Format-Table -AutoSize
    
    Start-Sleep -Seconds $pollRate
}
