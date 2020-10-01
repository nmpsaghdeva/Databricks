param([string] $applicationName = "Testapp")
$sp = Get-AzureADServicePrincipal -SearchString $applicationName
$File = Import-Csv -Delimiter "," .\data.csv
$File | ForEach-Object {
        $ObjectName = $_.ObjectName
        $ObjectType = $_.ObjectType
                if ($ObjectType -eq 'User')
                {
                        Write-Host "Adding User => " $ObjectName " As ==> " $ObjectType
                        $user = Get-AzureADUser -ObjectId "$ObjectName"
                        $appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $ObjectType }
                        New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id
                }
                if ($ObjectType -eq 'Group')
                {
                        Write-Host "Adding Group => " $ObjectName " As ==> " $ObjectType
                        $group = Get-AzureADGroup -SearchString "$ObjectName"
                        $appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq 'User' }
                        Write-Host "App Role==> " $appRole
                        New-AzureADGroupAppRoleAssignment -ObjectId $group.ObjectId -PrincipalId $group.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id
                }
        }
