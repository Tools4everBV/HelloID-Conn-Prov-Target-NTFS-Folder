#Initialize default properties
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json

# The entitlementContext contains the domainController, adUser, configuration, exchangeConfiguration and exportData
# - domainController: The IpAddress and name of the domain controller used to perform the action on the account
# - adUser: Information about the adAccount: objectGuid, samAccountName and distinguishedName
# - configuration: The configuration that is set in the Custom PowerShell configuration
# - exchangeConfiguration: The configuration that was used for exchange if exchange is turned on
# - exportData: All mapping fields where 'Store this field in person account data' is turned on
$eRef = $entitlementContext | ConvertFrom-Json

$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

# logging preferences
$verbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region Change mapping here
$adUser = Get-ADUser $aRef.ObjectGuid

# Troubleshooting
# $dryRun = $false
# $adUser = Get-ADUser '1a57e933-bd4d-48f8-bb32-34b1460a393d'

# HomeDir
$homeDir = [PSCustomObject]@{
    path        = "\\HELLOID001\Home\guido.janssen"#"\\HELLOID001\Home\$($adUser.sAMAccountName)"
    archivePath = "\\HELLOID001\Home\_Archive\"
}

# ProfileDir
$profileDir = [PSCustomObject]@{
    path        = "\\HELLOID001\Profile\$($adUser.sAMAccountName)"
    archivePath = "\\HELLOID001\Profile\_Archive\"
}

# ProjectsDir
$projectsDir = [PSCustomObject]@{
    path        = "\\HELLOID001\projects\$($adUser.sAMAccountName)"
    archivePath = "\\HELLOID001\projects\_Archive\"
}

#endregion Change mapping here

try {
    # Archive HomeDir
    try {
        $homeDirExists = test-path $homeDir.path
        if (-Not $homeDirExists) {
            throw "No directory found at path: $($homeDir.path)"                
        }
        else {
            if ($dryRun -eq $false) {
                Write-Verbose "Moving folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'"

                # $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop} -ArgumentList @($homeDir.path, $homeDir.archivePath)
                $null = Move-Item -Path $homeDir.path -Destination $($homeDir.archivePath) -Force -ErrorAction Stop
        
                $auditLogs.Add([PSCustomObject]@{
                        Action  = "DisableAccount"
                        Message = "Successfully moved folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'"
                        IsError = $false
                    })
                # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                Write-Information "Successfully moved folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'"
            }
            else {
                Write-Warning "DryRun: would move folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'"
            }
        }
    }
    catch {
        $ex = $PSItem
        $verboseErrorMessage = $ex.Exception.Message
        $auditErrorMessage = $ex.Exception.Message

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

        # Treat missing folder as success
        if ($auditErrorMessage -Like "No directory found at path: $($homeDir.path)") {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "No folder found at '$($homeDir.path)'. Skipping archive action"
                    IsError = $false
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "No folder found at '$($homeDir.path)'. Skipping archive action"
        }
        else {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "Error moving folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error moving folder '$($homeDir.path)' to archive path '$($homeDir.archivePath)'. Error Message: $auditErrorMessage"
        }
    }

    # Archive ProfileDir
    try {
        $fsLogixExists = test-path $profileDir.path
        if (-Not $fsLogixExists) {
            throw "No directory found at path: $($profileDir.path)"                
        }
        else {
            if ($dryRun -eq $false) {
                Write-Verbose "Moving folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'"

                # $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop} -ArgumentList @($profileDir.path, $profileDir.archivePath)
                $null = Move-Item -Path $profileDir.path -Destination $($profileDir.archivePath) -Force -ErrorAction Stop
        
                $auditLogs.Add([PSCustomObject]@{
                        Action  = "DisableAccount"
                        Message = "Successfully moved folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'"
                        IsError = $false
                    })
                # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                Write-Information "Successfully moved folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'"
            }
            else {
                Write-Warning "DryRun: would move folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'"
            }
        }
    }
    catch {
        $ex = $PSItem
        $verboseErrorMessage = $ex.Exception.Message
        $auditErrorMessage = $ex.Exception.Message

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

        # Treat missing folder as success
        if ($auditErrorMessage -Like "No directory found at path: $($profileDir.path)") {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "No folder found at '$($profileDir.path)'. Skipping archive action"
                    IsError = $false
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "No folder found at '$($profileDir.path)'. Skipping archive action"
        }
        else {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "Error moving folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error moving folder '$($profileDir.path)' to archive path '$($profileDir.archivePath)'. Error Message: $auditErrorMessage"
        }
    }

    # Archive ProjectsDir
    try {
        $fsLogix365Exists = test-path $projectsDir.path
        if (-Not $fsLogix365Exists) {
            throw "No directory found at path: $($projectsDir.path)"                
        }
        else {
            if ($dryRun -eq $false) {
                Write-Verbose "Moving folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'"

                # $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop} -ArgumentList @($projectsDir.path, $projectsDir.archivePath)
                $null = Move-Item -Path $projectsDir.path -Destination $($projectsDir.archivePath) -Force -ErrorAction Stop
    
                $auditLogs.Add([PSCustomObject]@{
                        Action  = "DisableAccount"
                        Message = "Successfully moved folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'"
                        IsError = $false
                    })
                # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                Write-Information "Successfully moved folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'"
            }
            else {
                Write-Warning "DryRun: would move folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'"
            }
        }
    }
    catch {
        $ex = $PSItem     
        $verboseErrorMessage = $ex.Exception.Message
        $auditErrorMessage = $ex.Exception.Message

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

        # Treat missing folder as success
        if ($auditErrorMessage -Like "No directory found at path: $($projectsDir.path)") {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "No folder found at '$($projectsDir.path)'. Skipping archive action"
                    IsError = $false
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "No folder found at '$($projectsDir.path)'. Skipping archive action"
        }
        else {
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "Error moving folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error moving folder '$($projectsDir.path)' to archive path '$($projectsDir.archivePath)'. Error Message: $auditErrorMessage"
        }
    }
}
finally {
    # Check if auditLogs doesn't contain errors, if so, set success to true
    if ($auditLogs.IsError -notcontains $true) {
        $success = $true
    }    

    #build up result
    $result = [PSCustomObject]@{
        Success   = $success
        AuditLogs = $auditLogs

        # Return data for use in other systems.
        # If not present or empty the default export data will be used
        # The $eRef.exportData contains the export data from the mapping which is the default
        # When an object is returned the export data will be overwritten with the provided data
        # ExportData = $eRef.exportData

        # Return data for use in notifications.
        # If not present or empty the default account data will be used    
        # When an object is returned this data will be available in the notification
        # Account = $eRef.account
    }

    #send result back
    Write-Output $result | ConvertTo-Json -Depth 10
}