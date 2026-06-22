<#
.SYNOPSIS
    Windows Troubleshooter Toolkit
.DESCRIPTION
    Menu-driven Windows, Microsoft 365, OneDrive, network, printer and system repair toolkit for IT support use.
    Designed to avoid interactive PowerShell prompts by using explicit parameters and safe helper functions.
.AUTHOR
    Dewald Pretorius
.VERSION
    10.2
#>

[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

$Script:ToolkitRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:LogRoot = Join-Path $env:ProgramData 'WinTroubleshooter'
$Script:AuditLog = Join-Path $Script:LogRoot 'AuditLog.csv'

function Initialize-Toolkit {
    if (-not (Test-Path -LiteralPath $Script:LogRoot)) {
        New-Item -Path $Script:LogRoot -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Script:AuditLog)) {
        'Timestamp,User,Computer,Action,Result' | Out-File -FilePath $Script:AuditLog -Encoding UTF8 -Force
    }
}

function Write-AuditLog {
    param(
        [Parameter(Mandatory)] [string] $Action,
        [Parameter(Mandatory)] [string] $Result
    )

    $line = '"{0}","{1}","{2}","{3}","{4}"' -f (Get-Date -Format s), $env:USERNAME, $env:COMPUTERNAME, ($Action -replace '"','""'), ($Result -replace '"','""')
    Add-Content -Path $Script:AuditLog -Value $line -Encoding UTF8
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Pause-Toolkit {
    Write-Host ''
    Read-Host 'Press Enter to continue' | Out-Null
}

function Show-Header {
    param([Parameter(Mandatory)] [string] $Title)
    Clear-Host
    Write-Host '============================================================'
    Write-Host "  $Title"
    Write-Host '============================================================'
    Write-Host ''
}

function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory)] [string] $Action,
        [Parameter(Mandatory)] [scriptblock] $ScriptBlock
    )

    try {
        & $ScriptBlock
        Write-AuditLog -Action $Action -Result 'Completed'
        Write-Host "[OK] $Action completed." -ForegroundColor Green
    }
    catch {
        Write-AuditLog -Action $Action -Result $_.Exception.Message
        Write-Host "[ERROR] $Action failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-RegistryValueIfExists {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name
    )

    if (Test-Path -LiteralPath $Path) {
        $property = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $property) {
            Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "Removed registry value: $Path :: $Name"
        }
    }
}

function Rename-FolderIfExists {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Suffix
    )

    if (Test-Path -LiteralPath $Path) {
        $parent = Split-Path -Parent $Path
        $leaf = Split-Path -Leaf $Path
        $newName = '{0}.{1}.{2}' -f $leaf, $Suffix, (Get-Date -Format 'yyyyMMddHHmmss')
        Rename-Item -LiteralPath $Path -NewName $newName -Force
        Write-Host "Renamed: $Path -> $(Join-Path $parent $newName)"
    }
}

function Get-BasicSystemHealth {
    Show-Header 'BASIC SYSTEM HEALTH CHECK'
    Invoke-CommandSafe -Action 'Basic system health check' -ScriptBlock {
        $results = @()
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

        $results += [pscustomobject]@{ Check = 'Computer'; Value = $env:COMPUTERNAME }
        $results += [pscustomobject]@{ Check = 'User'; Value = $env:USERNAME }
        $results += [pscustomobject]@{ Check = 'OS'; Value = $os.Caption }
        $results += [pscustomobject]@{ Check = 'OS Build'; Value = $os.BuildNumber }
        $results += [pscustomobject]@{ Check = 'Manufacturer'; Value = $cs.Manufacturer }
        $results += [pscustomobject]@{ Check = 'Model'; Value = $cs.Model }
        $results += [pscustomobject]@{ Check = 'RAM GB'; Value = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) }
        $results += [pscustomobject]@{ Check = 'C Drive Free GB'; Value = [math]::Round($disk.FreeSpace / 1GB, 2) }
        $results += [pscustomobject]@{ Check = 'Last Boot'; Value = $os.LastBootUpTime }

        $results | Format-Table -AutoSize -Wrap
    }
    Pause-Toolkit
}

function Invoke-NetworkDiagnostics {
    Show-Header 'NETWORK DIAGNOSTICS'
    Invoke-CommandSafe -Action 'Network diagnostics' -ScriptBlock {
        Write-Host 'IP configuration:' -ForegroundColor Cyan
        Get-NetIPConfiguration | Format-Table -AutoSize -Wrap

        Write-Host ''
        Write-Host 'DNS client servers:' -ForegroundColor Cyan
        Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table -AutoSize -Wrap

        Write-Host ''
        Write-Host 'Connectivity tests:' -ForegroundColor Cyan
        $targets = @('127.0.0.1', '8.8.8.8', '1.1.1.1', 'www.microsoft.com')
        $testResults = foreach ($target in $targets) {
            $ok = Test-Connection -ComputerName $target -Count 2 -Quiet -ErrorAction SilentlyContinue
            [pscustomobject]@{ Target = $target; Reachable = $ok }
        }
        $testResults | Format-Table -AutoSize
    }
    Pause-Toolkit
}

function Invoke-DnsRepair {
    Show-Header 'DNS AND NETWORK CACHE REPAIR'
    Invoke-CommandSafe -Action 'DNS and network cache repair' -ScriptBlock {
        ipconfig /flushdns | Out-Host
        ipconfig /registerdns | Out-Host
        netsh winsock reset | Out-Host
        netsh int ip reset | Out-Host
        Write-Host 'Restart the computer to complete TCP/IP and Winsock reset.' -ForegroundColor Yellow
    }
    Pause-Toolkit
}

function Invoke-WindowsUpdateRepair {
    Show-Header 'WINDOWS UPDATE REPAIR'
    Invoke-CommandSafe -Action 'Windows Update repair' -ScriptBlock {
        $services = 'bits','wuauserv','cryptsvc','msiserver'
        foreach ($service in $services) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        }

        Rename-FolderIfExists -Path (Join-Path $env:SystemRoot 'SoftwareDistribution') -Suffix 'old'
        Rename-FolderIfExists -Path (Join-Path $env:SystemRoot 'System32\catroot2') -Suffix 'old'

        foreach ($service in $services) {
            Start-Service -Name $service -ErrorAction SilentlyContinue
        }

        Get-Service -Name $services | Format-Table Name, Status, StartType -AutoSize
    }
    Pause-Toolkit
}

function Invoke-SystemFileRepair {
    Show-Header 'SYSTEM FILE REPAIR'
    Invoke-CommandSafe -Action 'System file repair' -ScriptBlock {
        DISM.exe /Online /Cleanup-Image /RestoreHealth | Out-Host
        sfc.exe /scannow | Out-Host
    }
    Pause-Toolkit
}

function Invoke-PrinterDiagnostics {
    Show-Header 'PRINTER DIAGNOSTICS'
    Invoke-CommandSafe -Action 'Printer diagnostics' -ScriptBlock {
        Get-Service -Name Spooler | Format-Table Name, Status, StartType -AutoSize
        Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus, Shared | Format-Table -AutoSize -Wrap
        Get-PrinterPort | Select-Object Name, PrinterHostAddress, Protocol | Format-Table -AutoSize -Wrap
    }
    Pause-Toolkit
}

function Invoke-PrinterSpoolerRepair {
    Show-Header 'PRINTER SPOOLER REPAIR'
    Invoke-CommandSafe -Action 'Printer spooler repair' -ScriptBlock {
        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        $spoolPath = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
        if (Test-Path -LiteralPath $spoolPath) {
            Get-ChildItem -LiteralPath $spoolPath -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        Start-Service -Name Spooler
        Get-Service -Name Spooler | Format-Table Name, Status, StartType -AutoSize
    }
    Pause-Toolkit
}

function Invoke-OfficeQuickRepairLaunch {
    Show-Header 'MICROSOFT OFFICE QUICK REPAIR LAUNCHER'
    Invoke-CommandSafe -Action 'Office quick repair launcher' -ScriptBlock {
        $clickToRun = Join-Path ${env:ProgramFiles} 'Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe'
        $clickToRunX86 = Join-Path ${env:ProgramFiles(x86)} 'Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe'
        $exe = @($clickToRun, $clickToRunX86) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

        if ($exe) {
            Start-Process -FilePath $exe -ArgumentList 'scenario=Repair', 'platform=x64', 'culture=en-us', 'RepairType=QuickRepair', 'DisplayLevel=True' -Wait:$false
            Write-Host 'Office repair window launched. Follow the Microsoft prompts.' -ForegroundColor Green
        }
        else {
            Write-Host 'Office Click-to-Run repair executable was not found on this device.' -ForegroundColor Yellow
        }
    }
    Pause-Toolkit
}

function Invoke-OneDriveSyncCacheRepair {
    Show-Header 'ONEDRIVE SYNC CACHE REPAIR'
    Invoke-CommandSafe -Action 'OneDrive sync cache repair' -ScriptBlock {
        Write-Host 'Stopping OneDrive processes...' -ForegroundColor Cyan
        Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        $oneDriveExeCandidates = @(
            (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\OneDrive.exe'),
            (Join-Path ${env:ProgramFiles} 'Microsoft OneDrive\OneDrive.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Microsoft OneDrive\OneDrive.exe')
        )

        $cacheFolders = @(
            (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\settings'),
            (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\logs'),
            (Join-Path $env:LOCALAPPDATA 'Microsoft\Office\16.0\OfficeFileCache')
        )

        foreach ($folder in $cacheFolders) {
            Rename-FolderIfExists -Path $folder -Suffix 'backup'
        }

        Write-Host 'Cleaning known OneDrive registry path lock values...' -ForegroundColor Cyan
        $registryValueTargets = @(
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive'; Name = 'UserFolder' },
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive'; Name = 'DisablePersonalSync' },
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive'; Name = 'SilentBusinessConfigCompleted' },
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1'; Name = 'UserFolder' },
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1'; Name = 'LastSignInUser' },
            @{ Path = 'HKCU:\Software\Microsoft\OneDrive\Accounts\Personal'; Name = 'UserFolder' }
        )

        foreach ($target in $registryValueTargets) {
            Remove-RegistryValueIfExists -Path $target.Path -Name $target.Name
        }

        Write-Host 'Resetting OneDrive client if available...' -ForegroundColor Cyan
        $oneDriveExe = $oneDriveExeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($oneDriveExe) {
            Start-Process -FilePath $oneDriveExe -ArgumentList '/reset' -Wait:$false -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            Start-Process -FilePath $oneDriveExe -Wait:$false -ErrorAction SilentlyContinue
            Write-Host 'OneDrive reset command sent and OneDrive restart attempted.' -ForegroundColor Green
        }
        else {
            Write-Host 'OneDrive executable was not found. Reinstall or repair OneDrive if sync still fails.' -ForegroundColor Yellow
        }

        Write-Host 'No Remove-ItemProperty command is called without a -Name parameter in this routine.' -ForegroundColor Green
    }
    Pause-Toolkit
}

function Invoke-WamTokenCacheReset {
    Show-Header 'WAM TOKEN CACHE RESET'
    Invoke-CommandSafe -Action 'WAM token cache reset' -ScriptBlock {
        Get-Process -Name Teams,ms-teams,OUTLOOK,OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        $tokenFolders = @(
            (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker'),
            (Join-Path $env:LOCALAPPDATA 'Microsoft\TokenBroker'),
            (Join-Path $env:LOCALAPPDATA 'Microsoft\IdentityCache')
        )

        foreach ($folder in $tokenFolders) {
            Rename-FolderIfExists -Path $folder -Suffix 'backup'
        }

        Write-Host 'WAM token cache folders were backed up/renamed where present. Sign in again to M365 apps.' -ForegroundColor Yellow
    }
    Pause-Toolkit
}

function Invoke-DiskCleanupReport {
    Show-Header 'DISK CLEANUP AND STORAGE REPORT'
    Invoke-CommandSafe -Action 'Disk cleanup and storage report' -ScriptBlock {
        $drives = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
            [pscustomobject]@{
                Drive = $_.DeviceID
                SizeGB = [math]::Round($_.Size / 1GB, 2)
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                FreePercent = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 }
            }
        }
        $drives | Format-Table -AutoSize
        cleanmgr.exe /verylowdisk | Out-Null
    }
    Pause-Toolkit
}

function Invoke-EventLogTriage {
    Show-Header 'EVENT LOG TRIAGE'
    Invoke-CommandSafe -Action 'Event log triage' -ScriptBlock {
        $events = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1,2; StartTime = (Get-Date).AddDays(-3) } -MaxEvents 50 -ErrorAction SilentlyContinue |
            Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message

        if ($events) {
            $events | Format-Table -AutoSize -Wrap
        }
        else {
            Write-Host 'No critical/error System events found in the last 3 days.' -ForegroundColor Green
        }
    }
    Pause-Toolkit
}

function Export-SupportEvidencePackage {
    Show-Header 'SUPPORT EVIDENCE PACKAGE'
    Invoke-CommandSafe -Action 'Support evidence package export' -ScriptBlock {
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $outDir = Join-Path $Script:LogRoot "Evidence_$stamp"
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null

        Get-ComputerInfo | Out-File -FilePath (Join-Path $outDir 'ComputerInfo.txt') -Encoding UTF8
        Get-NetIPConfiguration | Format-List * | Out-File -FilePath (Join-Path $outDir 'NetworkConfig.txt') -Encoding UTF8
        Get-Service | Sort-Object Status, Name | Format-Table -AutoSize | Out-File -FilePath (Join-Path $outDir 'Services.txt') -Encoding UTF8
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 50 | Format-Table -AutoSize | Out-File -FilePath (Join-Path $outDir 'TopProcesses.txt') -Encoding UTF8

        Write-Host "Evidence package created: $outDir" -ForegroundColor Green
    }
    Pause-Toolkit
}

function Show-OfficeMenu {
    do {
        Show-Header 'MS OFFICE, ONEDRIVE & SP SUITE'
        Write-Host '  1. Launch Microsoft Office Quick Repair'
        Write-Host '  2. Reset OneDrive Synchronization App Engine Cache'
        Write-Host '  3. Clean Stuck OneDrive Directory Registry Path Locks'
        Write-Host '  4. Tear Down Corrupt Web Account Manager Token Cache (WAM Core Reset)'
        Write-Host '  0. Back'
        Write-Host ''
        $choice = Read-Host 'Choice'

        switch ($choice) {
            '1' { Invoke-OfficeQuickRepairLaunch }
            '2' { Invoke-OneDriveSyncCacheRepair }
            '3' { Invoke-OneDriveSyncCacheRepair }
            '4' { Invoke-WamTokenCacheReset }
            '0' { return }
            default { Write-Host 'Invalid choice.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

function Show-MainMenu {
    do {
        Show-Header 'WINDOWS TROUBLESHOOTER TOOLKIT v10.2'
        if (-not (Test-IsAdministrator)) {
            Write-Host 'WARNING: Not running as Administrator. Some repairs will fail.' -ForegroundColor Yellow
            Write-Host ''
        }

        Write-Host '  1. Basic System Health Check'
        Write-Host '  2. Network Diagnostics'
        Write-Host '  3. DNS and Network Cache Repair'
        Write-Host '  4. Windows Update Repair'
        Write-Host '  5. System File Repair (DISM + SFC)'
        Write-Host '  6. Printer Diagnostics'
        Write-Host '  7. Printer Spooler Repair'
        Write-Host '  8. MS Office, OneDrive & SP Suite'
        Write-Host '  9. Disk Cleanup and Storage Report'
        Write-Host ' 10. Event Log Triage'
        Write-Host ' 11. Export Support Evidence Package'
        Write-Host '  0. Exit'
        Write-Host ''
        $choice = Read-Host 'Choice'

        switch ($choice) {
            '1' { Get-BasicSystemHealth }
            '2' { Invoke-NetworkDiagnostics }
            '3' { Invoke-DnsRepair }
            '4' { Invoke-WindowsUpdateRepair }
            '5' { Invoke-SystemFileRepair }
            '6' { Invoke-PrinterDiagnostics }
            '7' { Invoke-PrinterSpoolerRepair }
            '8' { Show-OfficeMenu }
            '9' { Invoke-DiskCleanupReport }
            '10' { Invoke-EventLogTriage }
            '11' { Export-SupportEvidencePackage }
            '0' { Write-AuditLog -Action 'Toolkit exit' -Result 'User exited'; return }
            default { Write-Host 'Invalid choice.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Initialize-Toolkit
Show-MainMenu
