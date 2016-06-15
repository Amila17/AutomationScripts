<#
.SYNOPSIS
This script helps to stop, delete or start a VM in Azure.

.DESCRIPTION
The script could be used to stop, stop and deallocate, delete or start a VM in Azure, based on the VM name.

.PARAMETER AzurePublishSettingsFilePath
The path location to the Azure Publish Settings File.

.PARAMETER SubscriptionName
The subscription name for the script to locate the VM in.

.PARAMETER ServiceName
The name of the Cloud Service to which the VM belongs to.

.PARAMETER VmName
The name of the VM to which the action should be executed on.

.PARAMETER Action
The state which the VM stop process should take place. Valid values are: Stop, StopD, Delete and Start
Stop - This will stop the VM but keep it allocated.
StopD - This would stop the VM and deallocate the VM. 
Delete - This would delete the VM and the VHD.
Start - This would start the VM if it exist.

.EXAMPLE
.\Azure-VMManagement.ps1 -AzurePublishSettingsFilePath "C:/AzureSettings/AzureSubs.publishsettings" -SubscriptionName "Testbed 01" -ServiceName "TestService" -VmName "TestService" -Action "Stop"


.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$AzurePublishSettingsFilePath,

	[Parameter(Mandatory=$True)]
	[string]$SubscriptionName,

	[Parameter(Mandatory=$True)]
	[string]$ServiceName,

	[Parameter(Mandatory=$True)]
	[string]$VmName,

	[Parameter(Mandatory=$True)]
	[ValidateSet('Stop', 'StopD', 'Delete', 'Start', IgnoreCase=$True)]
	[string]$Action
)

########################
#   START OF SCRIPT    #
########################

Import-AzurePublishSettingsFile -PublishSettingsFile $AzurePublishSettingsFilePath

Select-AzureSubscription -SubscriptionName $SubscriptionName

try
{
	$vm = Get-AzureVM -ServiceName $ServiceName -Name $VmName

	if(!$vm)
	{
		Write-Error ("No VM with the given name.")
		Exit 2
	}

	Write-Output ("Current VM Status: " + $vm.OperationStatus + ", PowerState: " + $vm.PowerState + ", Status: " + $vm.Status + ";")

	switch -Wildcard($Action)
	{
		Stop
		{ 
			Write-Output ("Stopping VM : " + $vm.Name)
			$response = Stop-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name -StayProvisioned
			break 
		}
		StopD
		{ 
			Write-Output ("Stopping and deallocating VM : " + $vm.Name)
			$response = Stop-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name -Force
			break 
		}
		Delete
		{
			Write-Output ("Deleting VM : " + $vm.Name + " and VHD : " + $vm.VM.OSVirtualHardDisk.MediaLink.AbsoluteUri)
			$response = Remove-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name -DeleteVHD
			break
		}
		Start
		{
			Write-Output ("Starting VM: " + $vm.Name)
			$response = Start-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name
			break			
		}
	}

	if($response.OperationStatus -ne "Succeeded")
	{
		Write-Warning ("The operation status was not successful. Please review the logs for operation id: " + $response.OperationId)
		Exit 1
	}

	Write-Output ("Process to $Action is complete.")
	Exit 0;
}
catch [System.Exception]
{
    Write-Error ("Exception occured during execution of Azure VM Deallocation Process. " + $_.Exception.Message)
	Write-Error ("Failed items. " + $_.Exception.ItemName)
	Exit 2
}
