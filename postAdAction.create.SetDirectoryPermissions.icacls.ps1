#####################################################
# HelloID-Conn-Prov-Target-NTFS-PostADAction-Create-Set-HomeDir-Permissions-ICACLS
#
# Version: 1.0.1
#####################################################

#Initialize default properties
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
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

# Get Primary Domain Controller
# Use data from eRef to avoid a query to the external AD system
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

#Get AD account object
# Use data from eRef to avoid a query to the external AD system
if (-NOT([String]::IsNullOrEmpty($eRef.adUser.SamAccountName))) {
    $adUser = $eRef.adUser
}
else {
    try {
        $adUser = Get-ADUser -Identity $aRef.ObjectGuid -server $pdc
    }
    catch {
        throw "Error querying AD user '$($aRef.ObjectGuid)'. Error: $_"
    }
}

# Troubleshooting
# $dryRun = $false
# $adUser = Get-ADUser -Filter "UserPrincipalName -eq `"jdoe@enyoi.nu`""

#region Change mapping here
# HomeDir
$directories = @(
    # HomeDir
    [PSCustomObject]@{
        ad_user     = $adUser
        path        = "\\fileserver\users\$($adUser.sAMAccountName)"
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
Write-Verbose "Directories: $($directories.path)"
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
                if ($dryRun -eq $false) {
                    Write-Verbose "Setting permissions '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'"

                    $perm = $null
                    switch ($directory.permission) {
                        "Full Control" { $perm = "(F)" }
                        "Modify " { $perm = "(M)" }
                        "Read and execute" { $perm = "(RX)" }
                        "Read-only" { $perm = "(R)" }
                        "Write-only" { $perm = "(W)" }
                    }
                
                    $inher = $null
                    switch ($($directory.inheritance)) {
                        "This folder only" { $inher = "" }
                        "This folder and subfolders " { $inher = "(CI)" }
                        "This folder, subfolders and files" { $inher = "(CI)(OI)" }
                    }
                
                    # Icacls docs: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls 
                    # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                    $setAcl = icacls $directory.path /grant "$($directory.ad_user.sAMAccountName):$($inher)$($perm)" /T

                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = "Successfully set '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'"
                            IsError = $False
                        })

                    # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                    Write-Information "Successfully set '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'"
                }
                else {
                    Write-Warning "DryRun: would set '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'"
                }
            }
        }
        catch {
            $ex = $PSItem
            $verboseErrorMessage = $ex.Exception.Message
            $auditErrorMessage = $ex.Exception.Message

            Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

            $auditLogs.Add([PSCustomObject]@{
                    Action  = "CreateAccount"
                    Message = "Error setting permissions '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error setting permissions '$($directory.permission)' for user '$($directory.ad_user.sAMAccountName)' to '$($directory.inheritance)' for directory '$($directory.path)'. Error Message: $auditErrorMessage"
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
