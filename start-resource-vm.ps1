$SecurePassword = $key | ConvertTo-SecureString -AsPlainText -Force 
$resourceGroup = "FFAzureDevops"
$location = "centralus"
$vmName = "myLinuxVM"
#$SecurePassword |  Out-File "D:/secret.txt"

$cred = new-object -typename System.Management.Automation.PSCredential `
     -argumentlist $clientID, $SecurePassword
$tenantID = "88400c81-a389-4bbc-a198-069be0f704b1"

Add-AzureRmAccount -Credential $cred -TenantId $tenantID -ServicePrincipal

#Start VM
Start-AzureRmVM -ResourceGroupName FFAzureDevops -Name myLinuxVM 