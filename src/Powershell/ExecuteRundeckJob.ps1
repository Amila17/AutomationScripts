param([string]$username = $OctopusParameters['username'], 
[string]$password = $OctopusParameters['password'], 
[string]$runDeckUrl = $OctopusParameters['runDeckUrl'], 
[string]$groupName = $OctopusParameters['groupName'], 
[string]$jobName = $OctopusParameters['jobName'], 
[string]$environment = $OctopusParameters['environment'])

$Global:sessionHolder = $null
$Global:runDeckUrl = $runDeckUrl

function Get-RunDeck-Job-Id([string]$runDeckGroup, [string]$runDeckJobName, [string]$environment)
{
	$jobsResponses = Get-RunDeck-Jobs $environment

	$selectedJob = ($jobsResponses|where{$_.group -match $runDeckGroup})|where{$_.name -match $runDeckJobName}

	if(!$selectedJob)
	{
		$errorMessage = "Passed in parameters: RunDeck Group " + $runDeckGroup + " and RunDeck Job Name: " + $runDeckJobName + " does not yield any results."
		Write-Error -Message $errorMessage
		exit 2
	}

	return $selectedJob.id;
}

function Get-RunDeck-Jobs([string]$environment)
{
	$url = $Global:runDeckUrl+"project/"+$environment+"/jobs?format=json"

	$httpResponse = Make-Http-Get-Request $url
	
	if($httpResponse.StatusCode -eq "200")
	{
		$jobsResponse = $httpResponse | ConvertFrom-Json
		return $jobsResponse
	}
	else
	{
		Write-Error -Message "Could not find any jobs for url : " + $url
		exit 2
	}
}

function Execute-RunDeck-Job([string]$jobId)
{
	if([string]::IsNullOrEmpty($jobId))
	{
		Write-Error -Message "Job Id cannot be null or empty";
		exit 2
	}

	$url = $Global:runDeckUrl+"job/"+$jobId+"/run?format=json"

	$httpResponse = Make-Http-Post-Request $url

	if($httpResponse.StatusCode -eq "200")
	{
		Write-Output -Message "Job Execution trigger successful for url : " + $url
		exit 0
	}
	else
	{
		Write-Error -Message "Job Execution trigger unsuccessful for url : " + $url
		exit 2
	}
}

function Make-Http-Get-Request([string]$url)
{
	$headers = Get-Request-Headers

	Try
	{
		$httpResponse = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 30 -Headers $headers -WebSession $Global:sessionHolder -UseBasicParsing
		return $httpResponse
	}
	Catch [Exception]
	{
		$ex = $_.Exception.Message
        Write-Error -Message $ex
		exit 2
	}

}

function Make-Http-Post-Request([string]$url, $body)
{
	Try
	{
		$headers = Get-Request-Headers

		if([string]::IsNullOrEmpty($sessionHolder))
		{
			$httpResponse = Invoke-WebRequest -Uri $url -Method Post -TimeoutSec 30 -Headers $headers -Body $body -SessionVariable sessionHolder -UseBasicParsing

			if($httpResponse.StatusCode -eq "200")
			{
				$Global:sessionHolder = $sessionHolder
			}

			return $httpResponse
		}

		$httpResponse = Invoke-WebRequest -Uri $url -Method Post -TimeoutSec 30 -Headers $headers -Body $body -WebSession $Global:sessionHolder -UseBasicParsing
		return $httpResponse
	}
	Catch [Exception]
	{
		$ex = $_.Exception.Message
        Write-Error -Message $ex
		exit 2
	}
}

function Authenticate-User([string]$username, [string]$password)
{
	$formData = @{}
	$formData.Add("j_username", $username)
	$formData.Add("j_password", $password)

	$url = $Global:runDeckUrl+"j_security_check"

	$response = Make-Http-Post-Request $url $formData

	if($response.StatusCode -ne "200")
	{
		Write-Error -Message "Authentication failed.";
		exit 2
	}
}

function Get-Request-Headers()
{
	$headers = @{}
	$headers.Add('ContentType','application/json')
	$headers.Add('Accept','application/json')

	return $headers;
}

Authenticate-User $username $password
$jobId = Get-RunDeck-Job-Id $groupName $jobName $environment
Execute-RunDeck-Job $jobId
