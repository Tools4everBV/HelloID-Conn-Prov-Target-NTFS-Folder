#####################################################
# HelloID-Conn-Prov-Target-NTFS-PostADAction-Create-Set-HomeDir-Permissions-ICACLS
#
# Version: 1.1.0
#####################################################

#Initialize default properties
$aRef = $accountReference | ConvertFrom-Json

# The entitlementContext contains the domainController, adUser, configuration, exchangeConfiguration and exportData
# - domainController: The IpAddress and name of the domain controller used to perform the action on the account
# - adUser: Information about the adAccount: objectGuid, samAccountName and distinguishedName
# - configuration: The configuration that is set in the Custom PowerShell configuration
# - exchangeConfiguration: The configuration that was used for exchange if exchange is turned on
# - exportData: All mapping fields where 'Store this field in person account data' is turned on
# - mappedData: The output of the mapping script
# - account: The data available in the notification
$eRef = $entitlementContext | ConvertFrom-Json

$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

# logging preferences
$verbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region Actions to perform (set to $false to skip an action)
# Add the permissions defined in the mapping below
$setPermissions = $true
# Enable inheritance (from the parent folder) on the directory
$enableInheritance = $true
#endregion Actions to perform

# Get Primary Domain Controller
# Use domain controller from eRef if available, otherwise query primary domain controller
if (-NOT([String]::IsNullOrEmpty($eRef.domainController.Name))) {
    $pdc = $eRef.domainController.Name
}
else {
    try {
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }
    catch {
        Write-Warning ("PDC Lookup Error: {0}" -f $_.Exception.InnerException.Message)
        Write-Warning "Retrying PDC Lookup"
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }
}

# Get AD account object
# Use objectGuid from aRef if available, otherwise use objectGuid from eRef 
if (-NOT([String]::IsNullOrEmpty($aRef.ObjectGuid))) {
    $adUSerIdentity = $aRef.objectGuid
}
else {
    $adUSerIdentity = $eRef.adUser.objectGuid
}

try {
    $adUser = Get-ADUser -Identity $adUSerIdentity -server $pdc
}
catch {
    throw "Error querying AD user [$($adUSerIdentity)]. Error: $_"
}

# Troubleshooting
# $dryRun = $true
# $adUser = Get-ADUser -Filter "UserPrincipalName -eq `"jdoe@enyoi.nu`""

#region Change mapping here
# Mapping options (permission = rights, inheritance = the objects the permission applies to):
# - permission "Full Control" / "Modify" / "Read and execute" / "Read-only" / "Write-only"
# - this folder only                          -> inheritance "This folder only"
# - this folder and subfolders                -> inheritance "This folder and subfolders"
# - this folder, subfolders and files (default) -> inheritance "This folder, subfolders and files"
# HomeDir
$directories = @(
    # HomeDir
    [PSCustomObject]@{
        ad_user     = $adUser
        path        = "\\HELLOID001\Home\$($adUser.sAMAccountName)"
        # Supported permissions: Full Control,Modify,Read and execute,Read-only,Write-only
        permission  = "Full Control"
        # The objects the permissions apply to. Supported inheritance levels: This folder only,This folder and subfolders,This folder, subfolders and files
        inheritance = "This folder, subfolders and files"
    },
    # ProfileDir
    [PSCustomObject]@{
        ad_user     = $adUser
        path        = "\\HELLOID001\Profile\$($adUser.sAMAccountName)"
        # Supported permissions: Full Control,Modify,Read and execute,Read-only,Write-only
        permission  = "Full Control"
        # The objects the permissions apply to. Supported inheritance levels: This folder only,This folder and subfolders,This folder, subfolders and files
        inheritance = "This folder, subfolders and files"
    }
    # ProjectsDir
    [PSCustomObject]@{
        ad_user     = $adUser
        path        = "\\HELLOID001\projects\$($adUser.sAMAccountName)"
        # Supported permissions: Full Control,Modify,Read and execute,Read-only,Write-only
        permission  = "Full Control"
        # The objects the permissions apply to. Supported inheritance levels: This folder only,This folder and subfolders,This folder, subfolders and files
        inheritance = "This folder, subfolders and files"
    }
)
Write-Information "Directories: $($directories.path)"
#endregion Change mapping here

try {
    foreach ($directory in $directories) {
        # Set Directory Permissions
        try {
            $directoryExists = $null
            $directoryExists = test-path $directory.path
            if (-Not $directoryExists) {
                throw "No directory found at path: $($directory.path)"                
            }
            else {
                $changes = [System.Collections.Generic.List[string]]::new()
                if ($enableInheritance) { $changes.Add("enabled inheritance") }
                if ($setPermissions) { $changes.Add("granted user [$($directory.ad_user.sAMAccountName)] $($directory.permission) on $(($directory.inheritance).ToLower())") }

                # Readable message, e.g. "Enabled inheritance and granted user [jdoe] Full Control on this folder, subfolders and files to directory [path]"
                $preposition = if ($setPermissions) { "to" } else { "on" }
                $changesMessage = "$($changes -join ' and ') $preposition directory [$($directory.path)]"
                $changesMessage = $changesMessage.Substring(0, 1).ToUpper() + $changesMessage.Substring(1)

                if ($changes.Count -eq 0) {
                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = "Skipped updating directory [$($directory.path)]. Reason: No changes."
                            IsError = $false
                        })
                    Write-Information "Skipped updating directory [$($directory.path)]. Reason: No changes."
                }
                elseif (-not ($dryRun -eq $true)) {
                    $perm = $null
                    switch ($directory.permission) {
                        "Full Control" { $perm = "(F)" }
                        "Modify" { $perm = "(M)" }
                        "Read and execute" { $perm = "(RX)" }
                        "Read-only" { $perm = "(R)" }
                        "Write-only" { $perm = "(W)" }
                    }
                
                    $inher = $null
                    switch ($($directory.inheritance)) {
                        "This folder only" { $inher = "" }
                        "This folder and subfolders" { $inher = "(CI)" }
                        "This folder, subfolders and files" { $inher = "(CI)(OI)" }
                    }
                
                    # Icacls docs: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls 
                    # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                    if ($setPermissions) {
                        # The SID is prefixed with * so icacls treats it as a SID instead of trying to resolve it as an account name
                        $setAcl = icacls $directory.path /grant "*$($directory.ad_user.SID):$($inher)$($perm)" /T
                        if ($LASTEXITCODE -ne 0) { throw "icacls failed to set permissions (exit code $LASTEXITCODE): $($setAcl -join " ")" }
                    }

                    if ($enableInheritance) {
                        # /inheritance:e enables inheritance and keeps the existing permissions
                        $setInheritance = icacls $directory.path /inheritance:e
                        if ($LASTEXITCODE -ne 0) { throw "icacls failed to enable inheritance (exit code $LASTEXITCODE): $($setInheritance -join " ")" }
                    }

                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = $changesMessage
                            IsError = $False
                        })

                    # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                    Write-Information $changesMessage
                }
                else {
                    Write-Warning "DryRun: $changesMessage (not executed)"
                }
            }
        }
        catch {
            $ex = $PSItem
            $verboseErrorMessage = $ex.Exception.Message
            $auditErrorMessage = $ex.Exception.Message

            Write-Information "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

            $auditLogs.Add([PSCustomObject]@{
                    Action  = "CreateAccount"
                    Message = "Error updating directory [$($directory.path)]. Error: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error updating directory [$($directory.path)]. Error: $auditErrorMessage"
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