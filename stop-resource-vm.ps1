#Login to Azure Service principal
$clientID = "74568bfe-295b-4140-b65e-60f3e04ac4a2"
$key = "CK8dOWkLgpc~FLhQWC6ZYsG_._tqF4VSE7"
$SecurePassword = $key | ConvertTo-SecureString -AsPlainText -Force 
$resourceGroup = "FFAzureDevops"
$location = "centralus"
$vmName = "myLinuxVM"
#$SecurePassword |  Out-File "D:/secret.txt"

$cred = new-object -typename System.Management.Automation.PSCredential `
     -argumentlist $clientID, $SecurePassword
$tenantID = "88400c81-a389-4bbc-a198-069be0f704b1"

Add-AzureRmAccount -Credential $cred -TenantId $tenantID -ServicePrincipal

#stop vm

Stop-AzureRmVM -ResourceGroupName FFAzureDevops -Name myLinuxVM -Force 