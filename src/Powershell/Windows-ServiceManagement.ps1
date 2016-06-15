<#
.SYNOPSIS
Manages Windows Services

.DESCRIPTION
This script could be used to manage windows services.

.PARAMETER ServiceName
The name of the service to apply the operation on.

.PARAMETER ServiceAction
The action to be performed on the Service. Valid values are: Start, Stop or Restart

.PARAMETER DisableService
A flag to indicate if the service should be disabled. 
Note: This is only applicable when the service is being requested to stop.

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
	[string]$ServiceAction,

	[switch]$DisableService
)

function Get-ServiceByName([string]$ServiceName)
{
	$serviceInfo = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
	
	if(!$serviceInfo)
	{
		Write-Output "Service does not exist." -ForegroundColor Red
		Exit 2;
	}

	return $serviceInfo
}

########################
#   START OF SCRIPT    #
########################

try
{
	if((!$DisableService) -and (($ServiceAction -eq "Start") -or ($ServiceAction -eq "Restart")))
	{
		Write-Output ("Service name : $ServiceName will not be disabled as the Service action is not to stop the service.")
	}

	$serviceInfo = Get-ServiceByName -serviceName $ServiceName

	switch -Wildcard($ServiceAction)
	{
		Start
		{ 
			Write-Output ("Starting service : $ServiceName.")
			Start-Service $ServiceName
			Write-Output ("$ServiceName service started.")
			break 
		}
		Stop
		{ 
			Write-Output ("Stopping service : $ServiceName")
			Stop-Service $ServiceName
			Write-Output ("$ServiceName service stopped.")

			if($DisableService)
			{
				Write-Output ("Disabling service : $ServiceName")
				Set-Service -Name $ServiceName -StartupType Disabled
				Write-Output ("$ServiceName service disabled.")
			}
			
			break
		}
		Restart
		{ 
			Write-Output ("Restarting service : $ServiceName")
			Restart-Service $ServiceName
			Write-Output ("$ServiceName service restarted.")
			break
		}
	} 

}
catch [System.Exception]
{
    Write-Output ("Exception occured during execution of Windows Service Management. " + $_.Exception.Message)
	Write-Output ("Failed items. " + $_.Exception.ItemName)
	Exit 2
}


