<#
.SYNOPSIS
This script helps to stop a VM in Azure.

.DESCRIPTION
The script could be used to stop or stop and deallocate the VM in Azure based on the VM name.

.PARAMETER SubscriptionId
The subscription id for the script to locate the VM in.

.PARAMETER VmName
The name of the VM to which the action should be executed on.

.PARAMETER StopState
The state which the VM stop process should take place. Valid values are: Stop and StopD
Stop - This will stop the VM but keep it allocated.
StopD - This would stop the VM and deallocate the VM. 

.EXAMPLE
.\IIS-ApplicationPoolManagement.ps1 -AppPoolName DefaultAppPool -IISAction Restart


.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$SubscriptionId,

	[Parameter(Mandatory=$True)]
	[string]$VmName,

	[Parameter(Mandatory=$True)]
	[ValidateSet('Stop', 'StopD', IgnoreCase=$True)]
	[string]$StopState
)

Select-AzureSubscription -SubscriptionId $SubscriptionId

$vm = Get-AzureVM -Name $VmName

if(!$vm)
{
	Write-Host "No VM with the given name." -ForegroundColor Red
	Exit 2
}

Write-Host "Current VM Status: " + $vm.OperationStatus + ", PowerState: " + $vm.PowerState + ", Status: " + $vm.Status + ";"

switch -Wildcard($StopState)
{
	Stop
	{ 
		Write-Host "Preparing to stop the vm."
		Stop-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name -StayProvisioned
		break 
	}
	StopD
	{ 
		Write-Host "Preparing to stop and deallocate the vm."
		Stop-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name -Force
		break 
	}
}