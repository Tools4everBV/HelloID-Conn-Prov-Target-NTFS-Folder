#region Initialize default properties
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json

# The permissionReference object contains the Identification object provided in the retrieve permissions call
$pRef = $permissionReference | ConvertFrom-Json

$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

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

# Change mapping here
$account = [PSCustomObject]@{
    path = "\\fs01\homefolders`$\$($aRef.sAMAccountName)"
    archivePath = "\\fs01\archiefhomefolders`$"
}

try {
    Write-Verbose "Moving folder '$($account.path)' to archive path '$($account.archivePath)'"

    if ($dryRun -eq $false) {
        # $job = Start-Job -ScriptBlock { Move-Item -Path $args[0] -Destination $args[1] -Force -ErrorAction Stop} -ArgumentList @($account.path, $account.archivePath)
        $null = Move-Item -Path $account.path -Destination $($account.archivePath) -Force -ErrorAction Stop

        $success = $true
        $auditLogs.Add([PSCustomObject]@{
                Action  = "RevokePermission"
                Message = "Successfully moved folder '$($account.path)' to archive path '$($account.archivePath)'"
                IsError = $false
            })
    }
    else {
        Write-Warning "DryRun: would move folder '$($account.path)' to archive path '$($account.archivePath)'"
    }
}
catch {
    $ex = $PSItem
    if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObject = Resolve-HTTPError -Error $ex
    
        $verboseErrorMessage = $errorObject.ErrorMessage
    
        $auditErrorMessage = $errorObject.ErrorMessage
    }
    
    # If error message empty, fall back on $ex.Exception.Message
    if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
        $verboseErrorMessage = $ex.Exception.Message
    }
    if ([String]::IsNullOrEmpty($auditErrorMessage)) {
        $auditErrorMessage = $ex.Exception.Message
    }

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"
    
    $success = $false
    $auditLogs.Add([PSCustomObject]@{
            Action  = "RevokePermission"
            Message = "Error moving folder '$($account.path)' to archive path '$($account.archivePath)'. Error Message: $auditErrorMessage"
            IsError = $True
        })
}
finally {
    # Send results
    $result = [PSCustomObject]@{
        Success   = $success
        AuditLogs = $auditLogs
    }

    Write-Output $result | ConvertTo-Json -Depth 10
}