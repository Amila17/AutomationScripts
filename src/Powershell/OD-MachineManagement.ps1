<#
.SYNOPSIS
Execute a machine management action on Octopus Deploy Machine

.DESCRIPTION
The script could be used to enable, disable or delete a machine in Octopus Deploy

.PARAMETER ApiUrl
The url for the OD API.

.PARAMETER ApiKey
The API key for authentication.

.PARAMETER MachineName
The name of the machine to apply the change to.

.PARAMETER Action
The action that should be applied on a OD machine. Valid values are: Enable, Disable and Delete
Enable - This would enable an OD machine.
Disable - This would disable an OD machine
Delete - This would delete an OD machine.

.EXAMPLE
To enable the machine
.\OD-MachineManagement.ps1 -ApiUrl "http://company.od.com" -ApiKey "abc123" -MachineName "Testmachine" -Action Enable

.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$ApiUrl,

	[Parameter(Mandatory=$True)]
	[string]$ApiKey,

	[Parameter(Mandatory=$True)]
	[string]$MachineName,

	[Parameter(Mandatory=$True)]
	[ValidateSet('Disable', 'Enable', 'Delete', IgnoreCase=$True)]
	[string]$Action
)

function Make-Http-Get-Request([string]$url)
{
	$headers = Get-Request-Headers

	Try
	{
		$httpResponse = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 30 -Headers $headers -UseBasicParsing
		return $httpResponse
	}
	Catch [Exception]
	{
		$ex = $_.Exception.Message
        Write-Error -Message $ex
		exit 2
	}

}

function Make-Http-Put-Request([string]$url, $body)
{
	Try
	{
		$headers = Get-Request-Headers

		$httpResponse = Invoke-WebRequest -Uri $url -Method Put -TimeoutSec 30 -Headers $headers -Body (ConvertTo-Json $body) -UseBasicParsing
		return $httpResponse
	}
	Catch [Exception]
	{
		$ex = $_.Exception.Message
        Write-Error -Message $ex
		exit 2
	}
}

function Make-Http-Delete-Request([string]$url)
{
	$headers = Get-Request-Headers

	Try
	{
		$httpResponse = Invoke-WebRequest -Uri $url -Method Delete -TimeoutSec 30 -Headers $headers -UseBasicParsing
		return $httpResponse
	}
	Catch [Exception]
	{
		$ex = $_.Exception.Message
        Write-Error -Message $ex
		exit 2
	}
}

function Get-Request-Headers()
{
	$headers = @{}
	$headers.Add('ContentType','application/json')
	$headers.Add('X-Octopus-ApiKey',$ApiKey)

	return $headers;
}


function Get-All-OD-Machines()
{
	$getAllMachinesUrl = $ApiUrl + "/api/machines/all"
	$response = Make-Http-Get-Request -url $getAllMachinesUrl

	if($response.StatusCode -eq "200")
	{
		$machineResponse = $response | ConvertFrom-Json
		return $machineResponse
	}
	else
	{
		Write-Error -Message "Could not find any machines. Url : " + $url
		exit 2
	}
}

function Set-EnableFlagForMachine($machine, [bool]$isEnabled)
{
	if(!$isEnabled)
	{
		$machine.IsDisabled = $True
	}
	else
	{
		$machine.IsDisabled = $False
	}
	

	$updateMachineUrl = $ApiUrl + "/api/machines/"+$machine.id

	$response = Make-Http-Put-Request -url $updateMachineUrl -body $machine

	if($response.StatusCode -eq "200")
	{
		Write-Output ("Machine status updated.")
		Exit 0;
	}
	else
	{
		Write-Error -Message "Could not update the machine. Url : " + $url + " response : " + $response
		Exit 2
	}
}

function Delete-Machine($machine)
{
	$updateMachineUrl = $ApiUrl + "/api/machines/"+$machine.id

	$response = Make-Http-Delete-Request -url $updateMachineUrl

	if($httpResponse.StatusCode -eq "200")
	{
		Write-Output ("Machine has been deleted.")
		Exit 0;
	}
	else
	{
		Write-Error -Message "Could not delete the machine. Url : " + $url + " response : " + $response
		Exit 2
	}
}


########################
#   START OF SCRIPT    #
########################

try
{
	$machines = Get-All-OD-Machines

	$machine = $machines | where{$_.Name -match $MachineName}

	if(!$machine)
	{
		$errorMessage = "Machine name " + $MachineName + " does not yield any results."
		Write-Error -Message $errorMessage
		Exit 2
	}

	switch -Wildcard ($Action)
	{
		Disable
		{
			Write-Output("Disabling machine with id: " + $machine.Id)
			Set-EnableFlagForMachine -machine $machine -isEnabled $False
		}
		Enable
		{
			Write-Output("Enabling machine with id: " + $machine.Id)
			Set-EnableFlagForMachine -machine $machine -isEnabled $True
		}
		Delete
		{
			Write-Output("Enabling machine with id: " + $machine.Id)
			Delete-Machine -machine $machine
		}
	}

	Write-Output("Action $Action has been applied on Machine $MachineName successfully.")
	Exit 0 
}
catch [System.Exception]
{
    Write-Error -Message "Exception during execution. " + $_.Exception.Message 
	Write-Error -Message  "Failed Items. " + $_.Exception.ItemName 
	Exit 2;
}

