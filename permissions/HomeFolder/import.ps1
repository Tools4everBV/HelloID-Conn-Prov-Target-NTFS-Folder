#################################################
# HelloID-Conn-Prov-Target-NTFS-ImportPermission-HomeFolder
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

try {
    # Configure, must be the same as the values used in retrieve permissions
    $permissionReference = 'NTFS'
    
    Write-Information 'Starting target permissions membership import'   
    $actionMessage = "getting primary domain controller"
    if ([string]::IsNullOrEmpty($actionContext.Configuration.fixedDomainController)) {
        try {
            $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
        }
        catch {
            Write-Warning ("PDC Lookup Error: {0}" -f $_.Exception.InnerException.Message)
            Write-Warning "Retrying PDC Lookup"
            $pdc = (Get-ADForest | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -Property PDCEmulator).PDCEmulator
        }
    }
    else {
        Write-Information "A fixed domain controller is configured [$($actionContext.Configuration.fixedDomainController)]"
        $pdc = $($actionContext.Configuration.fixedDomainController)
    }

    $actionMessage = "querying accounts"
    $getADUsersSplatParams = @{
        Filter      = '*'
        Properties  = @('homeDirectory', 'homeDrive') 
        Server      = $pdc
        ErrorAction = 'Stop'
    }
    $existingAccounts = Get-ADUser @getADUsersSplatParams
    Write-Information "Successfully queried [$($existingAccounts.count)] existing accounts"

    $actionMessage = "returning data to HelloID"
    foreach ($account in $existingAccounts) {
        $path = "$($actionContext.Configuration.homeFolderShare)\$($account.sAMAccountName)"
        $path_exists = test-path $path

        if (-not $path_exists) {
            continue
        }

        if ($actionContext.Configuration.setAttributes) {
            if ($account.HomeDirectory -ne $path) {
                continue
            }
        }

        Write-Output @(
            @{
                AccountReferences   = @( $($account.sAMAccountName) )
                PermissionReference = @{ Reference = $permissionReference }
            }
        )
    }
    Write-Information 'Permissions membership import completed'
}
catch {
    $ex = $PSItem
    $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    Write-Warning $warningMessage
    Write-Error $auditMessage
}