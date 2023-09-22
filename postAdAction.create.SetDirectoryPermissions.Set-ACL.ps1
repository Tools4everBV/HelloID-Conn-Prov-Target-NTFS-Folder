#####################################################
# HelloID-Conn-Prov-Target-NTFS-PostADAction-Create-Set-HomeDir-Permissions-Set-ACL
#
# Version: 1.0.1
#####################################################

#Initialize default properties
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json

# The entitlementContext contains the domainController, adUser, configuration, exchangeConfiguration and exportData
# - domainController: The IpAddress and name of the domain controller used to perform the action on the account
# - adUser: Information about the adAccount: objectGuid, SID and distinguishedName
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
# $dryRun = $false
# $adUser = Get-ADUser -Filter "UserPrincipalName -eq `"jdoe@enyoi.nu`""

#region Change mapping here
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
                    Write-Verbose "Setting ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"

                    #Return ACL to modify
                    $acl = Get-Acl $directory.path
                    
                    #Assign rights to user
                    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($directory.ad_user.SID, $directory.fsr, $directory.inf, $directory.pf, $directory.act)
                    $acl.AddAccessRule($accessRule)
                
                    # Set-Acl docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.3
                    # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                    # Since HelloID has a timeout of 30 seconds, we create a job that performs the action. We do not get the results of this job, so HelloID always treats this as a succes.
                    # $setAcl = Start-Job -ScriptBlock { Set-Acl -path $args[0].path -AclObject $args[1] } -ArgumentList @($directory, $acl)
                    # When troubleshooting is needed, please perform the action directly, so the actual results of the action are logged. This can be done by using the line below.
                    Set-Acl -path $directory.path -AclObject $acl

                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = "Successfully ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                            IsError = $False
                        })

                    # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                    Write-Information "Successfully set ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                }
                else {
                    Write-Warning "DryRun: would set ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
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
                    Message = "Error setting ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'. Error Message: $auditErrorMessage"
                    IsError = $True
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning "Error setting ACL permissions for user '$($directory.ad_user.SID)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'. Error Message: $auditErrorMessage"
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
