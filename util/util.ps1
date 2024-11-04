$ErrorActionPreference = "Stop"

$runtime = Resolve-Path "$PSScriptRoot/../runtime"
$dynamips = Resolve-Path "$runtime/dynamips.exe"
$dynagen = Resolve-Path "$runtime/dynagen.exe"
$program = Resolve-Path "$PSScriptRoot/auto.py"

function Start-Experiment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ([string] $workspace)

    $config = Get-Content -Path "$workspace/config.json" -Raw | ConvertFrom-Json
    $netfile = Resolve-Path "$workspace/$($config.netfile)"
    $distribution = $config.deviceDistribution
    $delay = $config.startupDelay

    function Start-DynamipsInstance {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param ([array] $distribution)

        $tmpDir = "dynamips-tmp"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        Set-Location $tmpDir
        foreach ($info in $distribution) {
            $port = $info.port
            Start-Process -FilePath $dynamips -ArgumentList "-H $port -l $port.log" -NoNewWindow
        }
        Set-Location ..
    }

    # Start Dynamips
    Write-Output "Ready To Start Dynamips..."
    Start-DynamipsInstance `
        -distribution $distribution
    Start-Sleep -Seconds $delay
    Write-Output "Dynamips Started."

    function Start-Dynagen {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param ([string] $netfile, [array] $distribution)

        $tmpDir = "dynagen-tmp"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        Set-Location $tmpDir
        foreach ($info in $distribution) {
            New-Item -ItemType Directory -Path $info.directory -Force | Out-Null
        }
        & $dynagen $netfile
        Set-Location ..
    }

    # Start dynagen
    Write-Output "Ready To Start Dynagen..."
    Start-Dynagen `
        -netfile $netfile `
        -distribution $distribution

    # Stop Dynamips
    Write-Output "Ready To Stop Dynamips..."
    $processes = Get-Process dynamips -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | Stop-Process
    }

    Start-Sleep -Seconds $delay
    Write-Output "Dynagen and Dynamips Stopped."
}

function Start-Configuration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ([string] $workspace)

    $config = Get-Content -Path "$workspace/config.json" -Raw | ConvertFrom-Json
    $limit = $config.autoConfiguration.maxParallelTaskLimit
    $configurations = $config.autoConfiguration.devices

    $setupScript = {
        param ([int] $port, [string] $file)

        $startTime = Get-Date
        python $using:program $port "configuration/$file" "logs/$port.log"
        $endTime = Get-Date
        $duration = $endTime - $startTime
        return [PSCustomObject] @{
            Port      = $port
            File      = $file
            StartTime = $startTime
            Duration  = $duration
            Message   = "Configured device on port $port with file $file, used $($duration.TotalSeconds) seconds."
        }
    }

    function Wait-ConfigurationJob {
        param ([ref] $jobs)

        Wait-Job -Job $jobs.Value | Out-Null
        foreach ($job in $jobs.Value) {
            Receive-Job -Job $job
        }
        Remove-Job -Job $jobs.Value
        $jobs.Value = @()
    }

    $logDir = "logs"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null

    Write-Output "Starting configuration process using $program..."
    $startTime = Get-Date
    $jobs = @()
    foreach ($item in $configurations) {
        $job = Start-Job -ScriptBlock $setupScript -ArgumentList $item.port, $item.file
        $jobs += $job
        if ($jobs.Count -ge $limit) {
            Wait-ConfigurationJob -Jobs ([ref] $jobs)
        }
    }
    if ($jobs.Count -gt 0) {
        Wait-ConfigurationJob -Jobs ([ref] $jobs)
    }
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Output "Configuration process completed, used $($duration.TotalSeconds) seconds."
}
