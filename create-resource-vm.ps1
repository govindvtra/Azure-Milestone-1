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


# Creating a resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location 



# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name FFSubnet -AddressPrefix 192.168.1.0/24




# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig




# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4




# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow



# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP



# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id




# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_B2ms  | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred |
Set-AzureRmVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "16.04-LTS" -Version "latest" |
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig



