# Define the log file path
$logFilePath = "C:\path\to\your\logfile.log"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFilePath -Append
}

# Function to update environment variable and inform the system
function Update-EnvironmentVariable {
    param (
        [string]$variableName,
        [string]$oldValue,
        [string]$newValue,
        [string]$pathHKLM,
        [string]$pathHKCU
    )

    try {
        # Update in HKLM
        $currentValueHKLM = (Get-ItemProperty -Path $pathHKLM -Name $variableName -ErrorAction SilentlyContinue).$variableName
        if ($currentValueHKLM -contains $oldValue) {
            $updatedValueHKLM = $currentValueHKLM -replace [regex]::Escape($oldValue), $newValue
            Set-ItemProperty -Path $pathHKLM -Name $variableName -Value $updatedValueHKLM
            [System.Environment]::SetEnvironmentVariable($variableName, $updatedValueHKLM, [System.EnvironmentVariableTarget]::Machine)
            Log-Message "$variableName environment variable updated successfully in HKLM."
        } else {
            Log-Message "$variableName environment variable in HKLM does not contain the specified path."
        }

        # Update in HKCU
        $currentValueHKCU = (Get-ItemProperty -Path $pathHKCU -Name $variableName -ErrorAction SilentlyContinue).$variableName
        if ($currentValueHKCU -contains $oldValue) {
            $updatedValueHKCU = $currentValueHKCU -replace [regex]::Escape($oldValue), $newValue
            Set-ItemProperty -Path $pathHKCU -Name $variableName -Value $updatedValueHKCU
            [System.Environment]::SetEnvironmentVariable($variableName, $updatedValueHKCU, [System.EnvironmentVariableTarget]::User)
            Log-Message "$variableName environment variable updated successfully in HKCU."
        } else {
            Log-Message "$variableName environment variable in HKCU does not contain the specified path."
        }

        # Broadcast change to all windows
        $sig = [System.Runtime.InteropServices.Marshal]::GetType('HWND_BROADCAST')
        $msg = [System.Runtime.InteropServices.Marshal]::GetType('WM_SETTINGCHANGE')
        SendMessageTimeout $sig $msg 0 "Environment" 0x2 5000

        Log-Message "Broadcast message sent to update environment variables."
    } catch {
        Log-Message "Error updating $variableName environment variable: $_"
    }
}

# Update LIB in HKLM and HKCU
Update-EnvironmentVariable -variableName "LIB" `
    -oldValue "C:\PROGRA~1\IBM\SQLLIB\LIB" `
    -newValue "" `
    -pathHKLM "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" `
    -pathHKCU "Registry::HKEY_CURRENT_USER\Environment"

# Update INCLUDE in HKLM and HKCU
Update-EnvironmentVariable -variableName "INCLUDE" `
    -oldValue "C:\PROGRA~1\IBM\SQLLIB\INCLUDE;C:\PROGRA~1\IBM\SQLLIB\LIB" `
    -newValue "" `
    -pathHKLM "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" `
    -pathHKCU "Registry::HKEY_CURRENT_USER\Environment"