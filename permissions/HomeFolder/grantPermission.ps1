################################################################
# HelloID-Conn-Prov-Target-NTFS-GrantPermission-HomeFolder
# PowerShell V2
################################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($actionContext.Configuration.isDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
function Get-ErrorMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $errorMessage = [PSCustomObject]@{
            VerboseErrorMessage = $null
            AuditErrorMessage   = $null
        }

        $errorMessage.VerboseErrorMessage = $ErrorObject.Exception.Message
        $errorMessage.AuditErrorMessage = $ErrorObject.Exception.Message

        Write-Output $errorMessage
    }
}
#endregion

# Begin
try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    Write-Information 'Verifying if a NTFS account exists'
    #Get Primary Domain Controller
    try {
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }
    catch {
        Write-Warning ("PDC Lookup Error: {0}" -f $_.Exception.InnerException.Message)
        Write-Warning "Retrying PDC Lookup"
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }

    
    #region Get Microsoft Active Directory account
    try {
        $correlatedAccount = Get-ADUser -Identity $actionContext.References.Account -server $pdc
    }
    catch {
        Write-Warning "Error querying AD user $($actionContext.References.Account). Error: $_"
        Write-Warning "Using data from actionContext.References.Account instead of AD data"        
    }
    #endregion Get Microsoft Active Directory account

    if ($null -ne $correlatedAccount) {
        $action = 'GrantPermission'
    }
    else {
        $action = 'NotFound'
    }
    
    # Process    
    switch ($action) {        
        'GrantPermission' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Granting NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)]"
                # Make sure to test with special characters and if needed; add utf8 encoding.
                $directory = @{
                    ad_user         = $correlatedAccount
                    path            = "$($actionContext.Configuration.homeFolderShare)\$($correlatedAccount.sAMAccountName)"
                    setADAttributes = $actionContext.Configuration.setAttributes
                    drive           = "$($actionContext.Configuration.homeDrive)"
                    fsr             = [System.Security.AccessControl.FileSystemRights]"Modify" #File System Rights
                    act             = [System.Security.AccessControl.AccessControlType]::Allow #Access Control Type
                    inf             = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit" #Inheritance Flags
                    pf              = [System.Security.AccessControl.PropagationFlags]"None" #Propagation Flags
                }

                
                # Create directory if it doesn't exist yet                
                try {                
                    $path_exists = test-path $directory.path                
                    if (-Not $path_exists) {
                        if (-not($actionContext.DryRun -eq $true)) {
                            Write-Verbose "Creating directory at path [$($directory.path)]"

                            $newDirectory = New-Item -path $directory.path -ItemType Directory -force

                            $outputContext.auditLogs.Add([PSCustomObject]@{
                                    # Action  = "CreateResource"
                                    Message = "Successfully created directory at path [$($directory.path)]"
                                    IsError = $false
                                })
                        }
                        else {
                            Write-Warning "DryRun: Would create directory at path [$($directory.path)]"
                        }         
                    }
                }
                catch {
                    $ex = $PSItem
                    $errorMessage = Get-ErrorMessage -ErrorObject $ex
                
                    throw $_
                }

                # Update AD User
                if ($null -ne $directory.ad_user -and $directory.setADAttributes -eq $true) {
                    try {
                        $adUserParams = @{
                            HomeDrive     = $directory.drive
                            HomeDirectory = $directory.path
                            Server        = $pdc
                        }

                        if (-not($actionContext.DryRun -eq $true)) {
                            Write-Verbose "Updating AD user [$($directory.ad_user)] attributes: [$($adUserParams|ConvertTo-Json)]"

                            Set-ADUser $directory.ad_user @adUserParams

                            $outputContext.auditLogs.Add([PSCustomObject]@{
                                    Action  = "UpdateAccount"
                                    Message = "Successfully updated AD user [$($directory.ad_user)] attributes: [$($adUserParams|ConvertTo-Json)]"
                                    IsError = $false
                                })
                        }
                        else {
                            Write-Warning "DryRun: Would update AD user [$($directory.ad_user)] attributes: [$($adUserParams|ConvertTo-Json)]"
                        }         
                    }
                    catch {
                        $ex = $PSItem
                        $errorMessage = Get-ErrorMessage -ErrorObject $ex
                
                        throw $_
                    }
                }

                if ($null -ne $directory.ad_user) {
                    try {
                        if (-not($actionContext.DryRun -eq $true)) {
                            Write-Verbose "Setting ACL permissions for user [$($directory.ad_user.sAMAccountName)] to directory [$($directory.path)]. File System Rights [$($directory.fsr)], Inheritance Flags [$($directory.inf)], Propagation Flags [$($directory.pf)], Access Control Type [$($directory.act)]"
                
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

                            $outputContext.AuditLogs.Add([PSCustomObject]@{
                                    Action  = "GrantPermission"
                                    Message = "Successfully set ACL permissions for user [$($directory.ad_user.sAMAccountName)] to directory [$($directory.path)]. File System Rights [$($directory.fsr)], Inheritance Flags [$($directory.inf)], Propagation Flags [$($directory.pf)], Access Control Type [$($directory.act)]"
                                    IsError = $False
                                })
                    
                        
                        }
                        else {
                            Write-Information "[DryRun] Grant NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)], will be executed during enforcement"
                        }

                    
                    }
                    catch {
                        $ex = $PSItem
                        $errorMessage = Get-ErrorMessage -ErrorObject $ex
                
                        throw $_
                    }

                    
                }
            
            }
            else {
                Write-Information "[DryRun] Grant NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)], will be executed during enforcement"            
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Action  = "GrantPermission"
                        Message = "[DryRun] Grant NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)], will be executed during enforcement"            
                        IsError = $false
                    })
            }
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "GrantPermission"
                    Message = "Grant permission [$($actionContext.References.Permission.DisplayName)] was successful"
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "NTFS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $false
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "GrantPermission"
                    Message = "NTFS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $true
                })
            break
        }
    }
}
catch {
    $outputContext.success = $false
    $ex = $PSItem
    
    $auditMessage = "Could not grant NTFS permission. Error: $($_.Exception.Message)"
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = "GrantPermission"
            Message = $auditMessage
            IsError = $true
        })
}