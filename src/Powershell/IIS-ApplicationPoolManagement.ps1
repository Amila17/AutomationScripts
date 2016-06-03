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


## Start of Script ##

Import-Module WebAdministration
$state = Get-WebAppPoolState $appPoolName

switch -Wildcard($IISAction)
{
	Start
	{ 
		StartApplicationPool -state $state -appPoolName $AppPoolName; 
		break 
	}
	Stop
	{ 
		StopApplicationPool -state $state -appPoolName $AppPoolName; 
		break
	}
	Restart
	{ 
		StopApplicationPool -state $state -appPoolName $AppPoolName; 
		StartApplicationPool -state $state -appPoolName $AppPoolName;
		break
	}
}

