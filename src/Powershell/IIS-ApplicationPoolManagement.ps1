<#
.SYNOPSIS
Manages IIS Application Pools

.DESCRIPTION
This script could be used to manage IIS application pools.

.PARAMETER AppPoolName
The name of the application pool to apply the operation on.

.PARAMETER IISAction
The action to be performed on the IIS App pool. Valid values are: Start, Stop or Restart

.EXAMPLE
.\IIS-ApplicationPoolManagement.ps1 -AppPoolName DefaultAppPool -IISAction Restart


.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$AppPoolName,

	[Parameter(Mandatory=$True)]
	[ValidateSet('Start', 'Stop', 'Restart', IgnoreCase=$True)]
	[string]$IISAction
)

function StartApplicationPool($state, [string]$appPoolName)
{	
	if($state.Value -ne 'Started')
	{
		Start-WebAppPool -Name $appPoolName
	}
}

function StopApplicationPool($state, [string]$appPoolName)
{	
	if($state.Value -ne 'Stopped')
	{
		Stop-WebAppPool -Name $appPoolName
	}
}


########################
#   START OF SCRIPT    #
########################

Import-Module WebAdministration
$state = Get-WebAppPoolState $appPoolName

try
{
	switch -Wildcard($IISAction)
	{
		Start
		{ 
			Write-Output("Starting application pool with name: $AppPoolName")
			StartApplicationPool -state $state -appPoolName $AppPoolName; 
			break 
		}
		Stop
		{ 
			Write-Output("Stopping application pool with name: $AppPoolName")
			StopApplicationPool -state $state -appPoolName $AppPoolName; 
			break
		}
		Restart
		{ 
			Write-Output("Restarting application pool with name: $AppPoolName")
			StopApplicationPool -state $state -appPoolName $AppPoolName; 
			StartApplicationPool -state $state -appPoolName $AppPoolName;
			break
		}
	} 
}
catch [System.Exception]
{
    Write-Output ("Exception occured during execution of App Pool Management. " + $_.Exception.Message)
	Write-Output ("Failed items. " + $_.Exception.ItemName)
	Exit 2
}

