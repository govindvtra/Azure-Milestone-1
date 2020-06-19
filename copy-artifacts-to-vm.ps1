#Login to Azure Service principal
$clientID = "74568bfe-295b-4140-b65e-60f3e04ac4a2"
$key = "CK8dOWkLgpc~FLhQWC6ZYsG_._tqF4VSE7"
$SecurePassword = $key | ConvertTo-SecureString -AsPlainText -Force 

$resourceGroup = "FFAzureDevops"

$SubscriptionId="3e3f43a7-ef53-469d-878d-8b495708c6be"
$DevTestLabName="MyPracticeLab"
$RepositoryName="Public Artifact Repo"
$ArtifactName="windows-chrome"
$VirtualMachineName="azureusergov001"


$cred = new-object -typename System.Management.Automation.PSCredential `
     -argumentlist $clientID, $SecurePassword
$tenantID = "88400c81-a389-4bbc-a198-069be0f704b1"

Add-AzureRmAccount -Credential $cred -TenantId $tenantID -ServicePrincipal



# Set the appropriate subscription
Set-AzureRmContext -SubscriptionId $SubscriptionId | Out-Null


# Get the internal repo name
$repository = Get-AzureRmResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.DevTestLab/labs/artifactsources' -ResourceName $DevTestLabName -ApiVersion 2016-05-15 `
                    | Where-Object { $RepositoryName -in ($_.Name, $_.Properties.displayName) } `
                    | Select-Object -First 1

if ($repository -eq $null) { "Unable to find repository $RepositoryName in lab $DevTestLabName." }

# Get the internal artifact name
$template = Get-AzureRmResource -ResourceGroupName $resourceGroup `
                -ResourceType "Microsoft.DevTestLab/labs/artifactSources/artifacts" `
                -ResourceName "$DevTestLabName/$($repository.Name)" `
                -ApiVersion 2016-05-15 `
                | Where-Object { $ArtifactName -in ($_.Name, $_.Properties.title) } `
                | Select-Object -First 1

if ($template -eq $null) { throw "Unable to find template $ArtifactName in lab $DevTestLabName." }

# Find the virtual machine in Azure
$FullVMId = "/subscriptions/$SubscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DevTestLab/labs/$DevTestLabName/virtualmachines/$virtualMachineName"

$virtualMachine = Get-AzureRmResource -ResourceId $FullVMId

# Generate the artifact id
$FullArtifactId = "/subscriptions/$SubscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DevTestLab/labs/$DevTestLabName/artifactSources/$($repository.Name)/artifacts/$($template.Name)"

# Handle the inputted parameters to pass through
$artifactParameters = @()

# Fill artifact parameter with the additional -param_ data and strip off the -param_
$Params | ForEach-Object {
   if ($_ -match '^-param_(.*)') {
      $name = $_.TrimStart('^-param_')
   } elseif ( $name ) {
      $artifactParameters += @{ "name" = "$name"; "value" = "$_" }
      $name = $null #reset name variable
   }
}

# Create structure for the artifact data to be passed to the action

$prop = @{
artifacts = @(
    @{
        artifactId = $FullArtifactId
        parameters = $artifactParameters
    }
    )
}

# Check the VM
if ($virtualMachine -ne $null) {
   # Apply the artifact by name to the virtual machine
   $status = Invoke-AzureRmResourceAction -Parameters $prop -ResourceId $virtualMachine.ResourceId -Action "applyArtifacts" -ApiVersion 2016-05-15 -Force
   if ($status.Status -eq 'Succeeded') {
      Write-Output "##[section] Successfully applied artifact: $ArtifactName to $VirtualMachineName"
   } else {
      Write-Error "##[error]Failed to apply artifact: $ArtifactName to $VirtualMachineName"
   }
} else {
   Write-Error "##[error]$VirtualMachine was not found in the DevTest Lab, unable to apply the artifact"
}