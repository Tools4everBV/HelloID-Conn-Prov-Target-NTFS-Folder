#####################################################
# HelloID-Conn-Prov-Target-NTFS-GrantPermission-HomeDir
#
# Version: 1.0.0
#####################################################
#region Initialize default properties
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$pp = $previousPerson | ConvertFrom-Json
$pd = $personDifferences | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$success = $false # Set to false at start, at the end, only when no error occurs it is set to true
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

# The accountReference object contains the Identification object provided in the create account call
$aRef = $accountReference | ConvertFrom-Json

# The managerAccountReference object contains the Identification object of the manager provided in the create account call for the manager
$mRef = $managerAccountReference | ConvertFrom-Json

# The permissionReference object contains the Identification object provided in the retrieve permissions call
$pRef = $permissionReference | ConvertFrom-Json

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($c.isDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#Get Primary Domain Controller
try {
    $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
}
catch {
    Write-Warning ("PDC Lookup Error: {0}" -f $_.Exception.InnerException.Message)
    Write-Warning "Retrying PDC Lookup"
    $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
}

#Get AD account object
try {
    $adUser = Get-ADUser -Identity $aRef.SID -server $pdc
}
catch {
    Write-Warning "Error querying AD user $($aRef.SID). Error: $_"
    Write-Warning "Using data from aRef instead of AD data" 
}

#endregion Initialize default properties

#region Change mapping here
$directory = @{
    ad_user         = $adUser
    path            = "\\HelloID001\HelloID\Home\$($adUser.sAMAccountName)"
    setADAttributes = $true
    drive           = "H:"
    fsr             = [System.Security.AccessControl.FileSystemRights]"Modify" #File System Rights
    act             = [System.Security.AccessControl.AccessControlType]::Allow #Access Control Type
    inf             = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" #Inheritance Flags
    pf              = [System.Security.AccessControl.PropagationFlags]"None" #Propagation Flags
}
#endregion Change mapping here

# # Troubleshooting
# $aRef = "9f4b2474-3c8d-4f92-94bc-58fed6e2d09b"
# $dryRun = $false

try {
    # Create directory if it doesn't exist yet
    try {
        $path_exists = test-path $directory.path
        if (-Not $path_exists) {
            if ($dryRun -eq $false) {
                Write-Verbose "Creating directory at path '$($directory.path)'"

                $newDirectory = New-Item -path $directory.path -ItemType Directory -force

                $auditLogs.Add([PSCustomObject]@{
                        # Action  = "CreateResource"
                        Message = "Successfully created directory at path '$($directory.path)'"
                        IsError = $false
                    })
            }
            else {
                Write-Warning "DryRun: Would create directory at path '$($directory.path)'"
            }         
        }
    }
    catch {
        # Clean up error variables
        $verboseErrorMessage = $null
        $auditErrorMessage = $null

        $ex = $PSItem
        # If error message empty, fall back on $ex.Exception.Message
        if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
            $verboseErrorMessage = $ex.Exception.Message
        }
        if ([String]::IsNullOrEmpty($auditErrorMessage)) {
            $auditErrorMessage = $ex.Exception.Message
        }

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

        $auditLogs.Add([PSCustomObject]@{
                # Action  = "CreateResource"
                Message = "Error creating directory at path '$($directory.path)'. Error Message: $auditErrorMessage"
                IsError = $true
            })
    }

    # Update AD User
    if ($null -ne $directory.ad_user -and $setADAttributes -eq $true) {
        try {
            $adUserParams = @{
                HomeDrive     = $directory.drive
                HomeDirectory = $directory.path
                Server        = $pdc
            }

            if ($dryRun -eq $false) {
                Write-Verbose "Updating AD user '$($directory.ad_user)' attributes: $($adUserParams|ConvertTo-Json)"

                Set-ADUser $directory.ad_user @adUserParams

                $auditLogs.Add([PSCustomObject]@{
                        Action  = "UpdateAccount"
                        Message = "Successfully updated AD user '$($directory.ad_user)' attributes: $($adUserParams|ConvertTo-Json)"
                        IsError = $false
                    })
            }
            else {
                Write-Warning "DryRun: Would update AD user '$($directory.ad_user)' attributes: $($adUserParams|ConvertTo-Json)"
            }         
        }
        catch {
            # Clean up error variables
            $verboseErrorMessage = $null
            $auditErrorMessage = $null
        
            $ex = $PSItem
            # If error message empty, fall back on $ex.Exception.Message
            if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
                $verboseErrorMessage = $ex.Exception.Message
            }
            if ([String]::IsNullOrEmpty($auditErrorMessage)) {
                $auditErrorMessage = $ex.Exception.Message
            }
        
            Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"
        
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "UpdateAccount"
                    Message = "Error updating AD user '$($directory.ad_user)' attributes: $($adUserParams|ConvertTo-Json). Error Message: $auditErrorMessage"
                    IsError = $true
                })
        }
    }

    # Set directory Permissions
    if ($null -ne $directory.ad_user) {
        try {
            if ($dryRun -eq $false) {
                Write-Verbose "Setting ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                
                #Return ACL to modify
                $acl = Get-Acl $directory.path
                                    
                #Assign rights to user
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($directory.ad_user.SID, $directory.fsr, $directory.inf, $directory.pf, $directory.act)
                $acl.AddAccessRule($accessRule)

                # Set-Acl docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.3
                # $setAclOwner = TAKEOWN /F $directory.path /A #<- Optional setting owner if needed
                # Since HelloID has a timeout of 30 seconds, we create a job that performs the action. We do not get the results of this job, so HelloID always treats this as a succes.
                $setAcl = Start-Job -ScriptBlock { Set-Acl -path $args[0].path -AclObject $args[1] } -ArgumentList @($directory, $acl)
                # When troubleshooting is needed, please perform the action directly, so the actual results of the action are logged. This can be done by using the line below.
                # Set-Acl -path $directory.path -AclObject $acl

                $auditLogs.Add([PSCustomObject]@{
                        Action  = "GrantPermission"
                        Message = "Successfully set ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
                        IsError = $False
                    })
            }
            else {
                Write-Warning "DryRun: Would set ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'"
            }         
        }
        catch {
            # Clean up error variables
            $verboseErrorMessage = $null
            $auditErrorMessage = $null
        
            $ex = $PSItem
            # If error message empty, fall back on $ex.Exception.Message
            if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
                $verboseErrorMessage = $ex.Exception.Message
            }
            if ([String]::IsNullOrEmpty($auditErrorMessage)) {
                $auditErrorMessage = $ex.Exception.Message
            }
        
            Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"
        
            $auditLogs.Add([PSCustomObject]@{
                    Action  = "UpdateAccount"
                    Message = "Error setting ACL permissions for user '$($directory.ad_user.sAMAccountName)' to directory '$($directory.path)'. File System Rights '$($directory.fsr)', Inheritance Flags '$($directory.inf)', Propagation Flags '$($directory.pf)', Access Control Type '$($directory.act)'. Error Message: $auditErrorMessage"
                    IsError = $true
                })
        }
    }
}
finally {
    # Check if auditLogs contains errors, if no errors are found, set success to true
    if (-NOT($auditLogs.IsError -contains $true)) {
        $success = $true
    }

    # Send results
    $result = [PSCustomObject]@{
        Success   = $success
        AuditLogs = $auditLogs
    }

    Write-Output ($result | ConvertTo-Json -Depth 10)
}