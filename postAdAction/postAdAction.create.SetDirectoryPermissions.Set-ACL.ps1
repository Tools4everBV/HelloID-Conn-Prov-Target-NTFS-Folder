#####################################################
# HelloID-Conn-Prov-Target-NTFS-PostADAction-Create-Set-HomeDir-Permissions-Set-ACL
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
# Add the access rule (user permissions) defined in the mapping below
$setPermissions = $true
# Enable inheritance (from the parent folder) on the directory
$enableInheritance = $true
#endregion Actions to perform

# Translates the inheritance and propagation flags into readable text for the logging
function Get-ScopeDescription {
    param(
        [System.Security.AccessControl.InheritanceFlags]$InheritanceFlags,
        [System.Security.AccessControl.PropagationFlags]$PropagationFlags
    )
    $container = $InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ContainerInherit)
    $object = $InheritanceFlags.HasFlag([System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
    $inheritOnly = $PropagationFlags.HasFlag([System.Security.AccessControl.PropagationFlags]::InheritOnly)

    $scope = if ($container -and $object) { "subfolders and files" } elseif ($container) { "subfolders" } elseif ($object) { "files" } else { $null }
    if ($PropagationFlags.HasFlag([System.Security.AccessControl.PropagationFlags]::NoPropagateInherit) -and $scope) {
        $scope = "direct child " + $scope.Replace("subfolders", "folders")
    }

    if (-not $scope) { return "this folder only" }
    if ($inheritOnly) { return "$scope only (not this folder)" }
    return "this folder, $scope"
}

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
# Mapping options (fsr = rights, act = Allow/Deny, inf = InheritanceFlags, pf = PropagationFlags), the result of the inf / pf combinations:
# - this folder only                                  -> inf "None"                            + pf "None"
# - this folder and files                             -> inf "ObjectInherit"                   + pf "None"
# - this folder and subfolders                        -> inf "ContainerInherit"                + pf "None"
# - this folder, subfolders and files (default)       -> inf "ContainerInherit, ObjectInherit" + pf "None"
# - this folder and its direct child items, not deeper -> inf "ContainerInherit, ObjectInherit" + pf "NoPropagateInherit"
# - subfolders and files only, not the folder itself  -> inf "ContainerInherit, ObjectInherit" + pf "InheritOnly"
# - pf only has an effect when inf is not "None"
# - fsr examples: "FullControl", "Modify", "ReadAndExecute", "Write"
# HomeDir
$directories = @(
    # HomeDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\Home\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Options can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Deny
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
    },
    # ProfileDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\Profile\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Options can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Deny
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
    }
    # ProjectsDir
    [PSCustomObject]@{
        ad_user = $adUser
        path    = "\\HELLOID001\projects\$($adUser.sAMAccountName)"
        fsr     = [System.Security.AccessControl.FileSystemRights]"FullControl" # Options can de found at Microsoft docs: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-6.0
        act     = [System.Security.AccessControl.AccessControlType]::Allow # Options: Allow , Deny
        inf     = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" # Options: None , ContainerInherit , ObjectInherit
        pf      = [System.Security.AccessControl.PropagationFlags]"None" # Options: None , NoPropagateInherit , InheritOnly
    }
)

Write-Information "Directories: $($directories.path)"
#endregion Change mapping here

try {
    foreach ($directory in $directories) {
        try {
            $actionMessage = "checking if directory [$($directory.path)] exists"
            $directoryExists = Test-Path -Path $directory.path

            $actionMessage = "determining action for directory [$($directory.path)]"
            $acl = $null
            $changes = [System.Collections.Generic.List[string]]::new()

            if ($directoryExists) {
                # Only the Access section (DACL) is read and written. Get-Acl/Set-Acl also handle the audit section (SACL), which requires the 'SeSecurityPrivilege' privilege.
                $actionMessage = "reading ACL of directory [$($directory.path)]"
                $directoryInfo = New-Object System.IO.DirectoryInfo($directory.path)
                $acl = $directoryInfo.GetAccessControl([System.Security.AccessControl.AccessControlSections]::Access)

                $actionMessage = "determining action for directory [$($directory.path)]"
                if ($enableInheritance) {
                    $changes.Add("enabled inheritance")
                }
                if ($setPermissions) {
                    $verb = if ($directory.act -eq [System.Security.AccessControl.AccessControlType]::Allow) { "granted" } else { "denied" }
                    $changes.Add("$verb user [$($directory.ad_user.sAMAccountName)] $($directory.fsr) on $(Get-ScopeDescription -InheritanceFlags $directory.inf -PropagationFlags $directory.pf)")
                }

                # Readable message, e.g. "Enabled inheritance and granted user [jdoe] FullControl on this folder, subfolders and files to directory [path]"
                $preposition = if ($setPermissions) { "to" } else { "on" }
                $changesMessage = "$($changes -join ' and ') $preposition directory [$($directory.path)]"
                $changesMessage = $changesMessage.Substring(0, 1).ToUpper() + $changesMessage.Substring(1)

                if ($changes.Count -gt 0) {
                    $action = 'UpdateAcl'
                }
                else {
                    $action = 'NoChanges'
                }
            }
            else {
                $action = 'NotFound'
            }
            Write-Information "Determined action for directory [$($directory.path)]: [$action]"

            switch ($action) {
                'UpdateAcl' {
                    if ($setPermissions) {
                        $actionMessage = "adding access rule for user [$($directory.ad_user.SID)] to ACL of directory [$($directory.path)]"
                        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($directory.ad_user.SID, $directory.fsr, $directory.inf, $directory.pf, $directory.act)
                        $acl.AddAccessRule($accessRule)
                    }

                    if ($enableInheritance) {
                        # Always performed: isProtected = $false -> inheritance enabled, preserveInheritance = $true -> keep the existing rules
                        $actionMessage = "enabling inheritance in ACL of directory [$($directory.path)]"
                        $acl.SetAccessRuleProtection($false, $true)
                    }

                    $actionMessage = "updating ACL of directory [$($directory.path)]"

                    if (-not ($dryRun -eq $true)) {
                        # Set-Acl docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl
                        # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                        $directoryInfo.SetAccessControl($acl)

                        if ($enableInheritance) {
                            $actionMessage = "verifying inheritance on directory [$($directory.path)]"
                            $aclAfter = (New-Object System.IO.DirectoryInfo($directory.path)).GetAccessControl([System.Security.AccessControl.AccessControlSections]::Access)
                            if ($aclAfter.AreAccessRulesProtected) {
                                throw "Inheritance is still disabled after updating the ACL"
                            }
                        }

                        $auditLogs.Add([PSCustomObject]@{
                                Action  = "CreateAccount"
                                Message = $changesMessage
                                IsError = $false
                            })

                        # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
                        Write-Information $changesMessage
                    }
                    else {
                        Write-Warning "DryRun: $changesMessage (not executed)"
                    }
                    break
                }

                'NoChanges' {
                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "CreateAccount"
                            Message = "Skipped updating directory [$($directory.path)]. Reason: No changes."
                            IsError = $false
                        })
                    Write-Information "Skipped updating directory [$($directory.path)]. Reason: No changes."
                    break
                }

                'NotFound' {
                    throw "No directory found at path: [$($directory.path)]."
                }
            }
        }
        catch {
            $ex = $PSItem
            $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
            $errorMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
            Write-Warning $warningMessage

            $auditLogs.Add([PSCustomObject]@{
                    Action  = "CreateAccount"
                    Message = $errorMessage
                    IsError = $true
                })
            # Currently, Post AD action auditlog is not shown in entitlement log, therefore log in PS as well
            Write-Warning $errorMessage
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
