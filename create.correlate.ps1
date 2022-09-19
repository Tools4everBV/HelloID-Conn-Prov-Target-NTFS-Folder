#####################################################
# HelloID-Conn-Prov-Target-NTFS-Folder-Create-Correlate
#
# Version: 1.0.1
#####################################################
# Initialize default values
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

#Get Primary Domain Controller
$pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
#endregion Initialize default properties

# Change mapping here
$account = [PSCustomObject]@{
    SamAccountName = $p.Accounts.MicrosoftAD.SamAccountName;
};

#region Execute
try {
    Write-Verbose "Querying AD account with $SamAccountName '$($account.SamAccountName)'"
    
    $currentAccount = Get-ADUser -Identity $account.SamAccountName -Property sAMAccountName -Server $pdc
	
    if ($null -eq $currentAccount) { throw "Failed to return an AD account" }

    # Set aRef object for use in futher actions
    $aRef = [PSCustomObject]@{
        objectGUID     = $currentAccount.objectGUID
        SID            = $currentAccount.SID.Value
        sAMAccountName = $currentAccount.sAMAccountName
    }

    $auditLogs.Add([PSCustomObject]@{
            Action  = "CreateAccount"
            Message = "Successfully correlated to account $($currentAccount.sAMAccountName) ($($currentAccount.objectGUID))";
            IsError = $false;
        });    
    $success = $true;
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

    if ($auditErrorMessage -Like "Failed to return an AD account" -or $auditErrorMessage -Like "Cannot find an object with identity: '$($account.SamAccountName)'*") {
        $success = $false
        $auditLogs.Add([PSCustomObject]@{
                Action  = "CreateAccount"
                Message = "No AD account found with SAMaccountName '$($account.SamAccountName)'. Possibly deleted."
                IsError = $true
            })     
    }
    else {
        $success = $false  
        $auditLogs.Add([PSCustomObject]@{
                Action  = "CreateAccount"
                Message = "Error querying AD account with SAMaccountName '$($account.SamAccountName)'. Error Message: $auditErrorMessage"
                IsError = $True
            })
    }
}
finally{
    # Send results
    $result = [PSCustomObject]@{
        Success          = $success;
        AccountReference = $aRef
        AuditLogs        = $auditLogs
        Account          = $account;
    };

    Write-Output $result | ConvertTo-Json -Depth 10
}
