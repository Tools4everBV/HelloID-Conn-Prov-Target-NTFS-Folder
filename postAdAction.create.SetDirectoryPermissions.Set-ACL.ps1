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

#region Change mapping here
$adUser = Get-ADUser $eRef.adUser.ObjectGuid

# Troubleshooting
# $dryRun = $false
# $adUser = Get-ADUser '1a57e933-bd4d-48f8-bb32-34b1460a393d'

# HomeDir
$directories = @(
    # HomeDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\Home\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Optiong can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Remove
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
    },
    # ProfileDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\Profile\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Optiong can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Remove
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
    }
    # ProjectsDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\projects\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Optiong can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Remove
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
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
                    Write-Verbose "Setting ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"

                    #Return ACL to modify
                    $acl = Get-Acl $directory.path
                    
                    #Assign rights to user
                    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($directory.ad_user.SID, $directory.fsr, $directory.inf, $directory.pf, $directory.act)
                    $acl.AddAccessRule($accessRule)
                
                    # Icacls docs: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls 
                    # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                    $setAcl = Start-Job -ScriptBlock { Set-Acl -path $args[0].path -AclObject $args[1] } -ArgumentList @($directory, $acl)

                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = "Successfully ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                            IsError = $False
                        })

                    # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                    Write-Information "Successfully set ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                }
                else {
                    Write-Warning "DryRun: would set ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                }
            }
        }
        catch {
            $ex = $PSItem
            $verboseErrorMessage = $ex.Exception.Message
            $auditErrorMessage = $ex.Exception.Message

            Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

            $auditLogs.Add([PSCustomObject]@{
                    Action  = "DisableAccount"
                    Message = "Error setting ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error setting ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'. Error Message: $auditErrorMessage"
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