#########################################################################################################
# Purpose  : This script is used to add Users and groups to anenterprise application                    #
#                                                                                                       # 
# Parameters : It takes 2 parameters                                                                    #
#		1. Service principal object id of the application 					#
#		2. path where data file kept with details of users and groups to be added		#
#########################################################################################################

param([string] $serviceprincipal,
      [string] $path)
$sp = Get-AzureADServicePrincipal -ObjectId $serviceprincipal
$File = Import-Csv -Delimiter "," $path\data.csv
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
