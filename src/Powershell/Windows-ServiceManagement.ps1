<#
.SYNOPSIS
Manages Windows Services

.DESCRIPTION
This script could be used to manage windows services.

.PARAMETER ServiceName
The name of the service to apply the operation on.

.PARAMETER ServiceAction
The action to be performed on the Service. Valid values are: Start, Stop or Restart

.EXAMPLE
.\Windows-ServiceManagement.ps1 -ServiceName DefaultAppPool -ServiceAction Restart


.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$ServiceName,

	[Parameter(Mandatory=$True)]
	[ValidateSet('Start', 'Stop', 'Restart')]
	[string]$ServiceAction
)

function Get-ServiceByName([string]$serviceName)
{
	$serviceInfo = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
	
	if(!$serviceInfo)
	{
		Write-Host "Service does not exist." -ForegroundColor Red
		Exit 2;
	}
}

## Start of Script ##

Get-ServiceByName -serviceName $ServiceName

switch -Wildcard($ServiceAction)
{
	Start
	{ 
		Start-Service $serviceName
		break 
	}
	Stop
	{ 
		Stop-Service $serviceName
		break
	}
	Restart
	{ 
		Restart-Service $serviceName
		break
	}
}

