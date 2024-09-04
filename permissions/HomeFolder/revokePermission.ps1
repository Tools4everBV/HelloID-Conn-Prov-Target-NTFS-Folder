#################################################################
# HelloID-Conn-Prov-Target-NTFS-RevokePermission-Group
# PowerShell V2
#################################################################

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

    #Get Primary Domain Controller
    try {
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }
    catch {
        Write-Warning ("PDC Lookup Error: {0}" -f $_.Exception.InnerException.Message)
        Write-Warning "Retrying PDC Lookup"
        $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
    }

    Write-Information 'Verifying if a NTFS account exists'
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
        $action = 'RevokePermission'
    }
    else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'RevokePermission' {
            if (-not($actionContext.DryRun -eq $true)) {
                #region Change mapping here
                $directory = @{
                    ad_user         = $correlatedAccount
                    path            = "$($actionContext.Configuration.homeFolderShare)\$($correlatedAccount.sAMAccountName)"
                    archive_path    = "$($actionContext.Configuration.homeFolderArchiveShare)\$($correlatedAccount.sAMAccountName)"
                    setADAttributes = $actionContext.Configuration.setAttributes
                    drive           = "$($actionContext.Configuration.homeDrive)"
                }
                #endregion Change mapping here

                # Check if directory exists
                try {                   
                    $path_exists = test-path $directory.path
                    if (-Not $path_exists) {                        
                        Write-Warning "Directory at path '$($directory.path)' does not exist"
        
                        $outputContext.AuditLogs.Add([PSCustomObject]@{
                                # Action  = "CreateResource"
                                Message = "Directory at path '$($directory.path)' does not exist. Skipped revoke of permission to directory"
                                IsError = $false
                            }) 
                        
                    }
                    else {
                        # Archive directory
                        if ($null -ne $directory.ad_user) {
                            try {
                                if ($actionContext.DryRun -eq $false) {
                                    Write-Information "Moving directory at path '$($directory.path)' to archive path '$($directory.archive_path)'"
                
                                    # The scripts in HelloID Prov have a 30 second time-out limit. Therefore we use a job to archive (larger) folders
                                    $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop } -ArgumentList @($directory.path, $directory.archive_path)
                                    # If troubleshooting is need, use the action below instead of the job, as the job doesn't show any errors
                                    # $archivedDirectory = Move-Item -Path $directory.path -Destination $directory.archive_path -Force -ErrorAction Stop
                                    
                                    $outputContext.auditLogs.Add([PSCustomObject]@{
                                            # Action  = "DeleteResource"
                                            Message = "Successfully moved directory at path '$($directory.path)' to archive path '$($directory.archive_path)'"
                                            IsError = $false
                                        })
                                }
                                else {
                                    Write-Warning "DryRun: Would move directory at path '$($directory.path)' to archive path '$($directory.archive_path)'"
                                }        
                            }
                            catch {
                                $ex = $PSItem
                                $errorMessage = Get-ErrorMessage -ErrorObject $ex
                        
                                throw $_
                            }
                        }

                        # Update AD User
                        if ($null -ne $directory.ad_user -and $setADAttributes -eq $true) {
                            try {
                                $adUserParams = @{
                                    HomeDrive     = $directory.drive
                                    HomeDirectory = $directory.archive_path
                                    Server        = $pdc
                                }

                                if ($actionContext.dryRun -eq $false) {
                                    Write-Information "Updating AD user '$($directory.ad_user)' attributes: $($adUserParams|ConvertTo-Json)"

                                    Set-ADUser $directory.ad_user @adUserParams

                                    $outputContext.auditLogs.Add([PSCustomObject]@{
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
                                $ex = $PSItem
                                $errorMessage = Get-ErrorMessage -ErrorObject $ex
                        
                                throw $_
                            }
                        }
                    }
                }
                catch {
                    $ex = $PSItem
                    $errorMessage = Get-ErrorMessage -ErrorObject $ex
                
                    throw $_
                }

                

                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Action  = "RevokePermission"
                        Message = "Revoke permission [$($actionContext.References.Permission.DisplayName)] was successful"
                        IsError = $false
                    })
            }
            else {                
                Write-Information "[DryRun] Revoke NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)], will be executed during enforcement"
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Action  = "RevokePermission"
                        Message = "[DryRun] Revoke NTFS permission: [$($actionContext.References.Permission.DisplayName)] - [$($actionContext.References.Permission.Reference)], will be executed during enforcement"
                        IsError = $false
                    })
            }
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "RevokePermission"
                    Message = "Revoke permission [$($actionContext.References.Permission.DisplayName)] was successful"
                    IsError = $false
                })            
            break
        }

        'NotFound' {
            Write-Information "NTFS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "RevokePermission"
                    Message = "NTFS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
}
catch {
    $outputContext.success = $false
    $ex = $PSItem
    
    $auditMessage = "Could not revoke NTFS permission. Error: $($_.Exception.Message)"
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = "RevokePermission"
            Message = $auditMessage
            IsError = $true
        })
}