#####################################################
# HelloID-Conn-Prov-Target-NTFS-RevokePermission-HomeDir
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

# Troubleshooting
# $aRef = @{
#     objectGUID     = "60bef72d-4d33-49de-8286-f73a9a89e4cd"
#     SID            = "S-1-5-21-741916949-825606008-3913300161-1114"
#     sAMAccountName = "test01"
# }
# $dryRun = $false

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
    $adUser = $aRef
}

#endregion Initialize default properties

#region Change mapping here
$directory = @{
    ad_user         = $adUser
    path            = "\\HelloID001\HelloID\Home\$($adUser.sAMAccountName)"
    archive_path    = "\\HelloID001\HelloID\Home\_Archive\$($adUser.sAMAccountName)"
    setADAttributes = $true
    drive           = "H:"
}
#endregion Change mapping here

try {
    # Check if directory exists
    $path_exists = test-path $directory.path
    if (-Not $path_exists) {
        Write-Warning "Directory at path '$($directory.path)' does not exist"
        
        $auditLogs.Add([PSCustomObject]@{
                # Action  = "CreateResource"
                Message = "Directory at path '$($directory.path)' does not exist. Skipped revoke of permission to directory"
                IsError = $false
            })   
    }
    else {
        # Archive directory
        if ($null -ne $directory.ad_user) {
            try {
                if ($dryRun -eq $false) {
                    Write-Verbose "Moving directory at path '$($directory.path)' to archive path '$($directory.archive_path)'"

                    # The scripts in HelloID Prov have a 30 second time-out limit. Therefore we use a job to archive (larger) folders
                    $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop} -ArgumentList @($directory.path, $directory.archive_path)
                    # If troubleshooting is need, use the action below instead of the job, as the job doesn't show any errors
                    # $archivedDirectory = Move-Item -Path $directory.path -Destination $directory.archive_path -Force -ErrorAction Stop
                    
                    $auditLogs.Add([PSCustomObject]@{
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
                        # Action  = "DeleteResource"
                        Message = "Error moving directory at path '$($directory.path)' to archive path '$($directory.archive_path)'. Error Message: $auditErrorMessage"
                        IsError = $true
                    })
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