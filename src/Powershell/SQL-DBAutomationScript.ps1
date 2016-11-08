<#
.SYNOPSIS
Creates a database on the sql server and the required user and login credentials. If it is an sql cluster, the process will add the database
to a high availability group.

.DESCRIPTION
Automates database creation and adds the database onto a high availability group if it is a cluster.

.PARAMETER DbName
Name of the database.

.PARAMETER SqlServerName
Name of the primary sql server.

.PARAMETER DbUserName
Name of the database sql user accessing the database. This will also be used as the sql login name.

.PARAMETER DbUserPassword
Password for the database sql user.

.PARAMETER DbRoleNameName
Role that needs to be assigned to the newly created user.

.PARAMETER IsClusterMode
Flag to determine if the sql is a cluster setup.

.PARAMETER SecondarySqlServerName
Name of the secondary sql server

.PARAMETER AvailabilityGroupName
Name of the availability group the database should be added to.

.PARAMETER FileShareForBackUpFilesLocation
Location for the backup file to be places. Should be a shared location so the primary and secondary node can access the file.

.EXAMPLE
.\SQL-DBAutomationScript.ps1 -DbName "dbName" -SqlServerName "primarySqlServerName" -DbUserName "dbUserName" -DbUserPassword "dbPassword" -DbRoleName "db_owner" -IsClusterMode -SecondarySqlServerName "secondarySqlServerName" -AvailabilityGroupName "sqlAG" -FileShareForBackUpFilesLocation "\\share\AGSyncBackup"

.NOTES
    Author: P G Amila Prabandhika
#>

param(
	[Parameter(Mandatory=$True)]
	[string]$DbName,

	[Parameter(Mandatory=$True)]
	[string]$SqlServerName,

	[Parameter(Mandatory=$True)]
	[string]$DbUserName,

	[Parameter(Mandatory=$True)]
	[string]$DbUserPassword,

	[Parameter(Mandatory=$True)]
	[string]$DbRoleName,

	[Parameter(Mandatory=$True)]
	[switch]$IsClusterMode,

	[Parameter(Mandatory=$False)]
	[string]$SecondarySqlServerName,

	[Parameter(Mandatory=$False)]
	[string]$AvailabilityGroupName,
	
	[Parameter(Mandatory=$False)]
	[string]$FileShareForBackUpFilesLocation
)

Import-Module SQLPS -DisableNameChecking


function CreateSqlDatabase($dbServerName, $dbName)
{
	try
	{
		Write-Output "Adding Database '$dbName' to '$dbServerName'"

		$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server($dbServerName)

		if($sqlServer.Databases[$dbName] -ne $null)
		{
			Write-Output "Database '$dbName' exits in '$dbServerName'"
			return
		}

		$db = New-Object Microsoft.SqlServer.Management.Smo.Database($sqlServer, $dbName)
		$db.Create()

		Write-Output "Database creation is successful."
	}
	catch [System.Exception]
	{
		Write-Error ("Exception occured during DB Creation. " + $_.Exception.Message)
		Write-Error ("Failed items. " + $_.Exception.ItemName)
		Exit 2
	}
}

function CreateSqlUserAndLogin($dbServerName, $dbUserName, $dbLoginName, $dbUserPassword, $roleName, $dbName)
{
	try
	{
		Write-Output "Adding User '$dbUserName' and Login '$dbLoginName' with role '$roleName' to database '$dbName' on '$dbServerName'"

		$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server($dbServerName)

		if($sqlServer.Logins[$dbLoginName] -eq $null)
		{
			$login = New-Object Microsoft.SqlServer.Management.Smo.Login($dbServerName, $dbLoginName)
			$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
			$login.PasswordExpirationEnabled = $false
			$login.Create($dbUserPassword)
		}		

		$database = $sqlServer.Databases[$dbName]
		if(!$database.Users[$dbUserName])
		{
			$dbUser = New-Object Microsoft.SqlServer.Management.Smo.User($database, $dbUserName)
			$dbUser.Login = $dbLoginName
			$dbUser.Create()
		}

		if($database.Roles[$roleName] -eq $null)
		{
			$dbRole = $database.Roles[$roleName]
			$dbRole.AddMember($dbUserName)
			$dbRole.Alter()
		}

		Write-Output "User and Login creation is successful."
	}
	catch [System.Exception]
	{
		Write-Error ("Exception occured during DB Creation. " + $_.Exception.Message)
		Write-Error ("Failed items. " + $_.Exception.ItemName)
		Exit 2
	}
}

function AddDatabaseToAG($dbName, $primarySqlServer, $secondarySqlServers, $availabilityGroup, $dbBackupFile)
{
	try
	{
		Write-Output "Adding database '$dbName' to availability group '$availabilityGroup'"

		Write-Output "Creating backup of database '$dbName' from sql server '$primarySqlServer' and saving backup file to '$dbBackupFile'"
		Backup-SqlDatabase -Database $dbName -BackupFile $dbBackupFile -ServerInstance $primarySqlServer -BackupAction Database

		foreach($secondarySqlServer in $secondarySqlServers)
		{
			Write-Output "Restoring database to secondary sql server '$secondardSqlServer'"
			Restore-SqlDatabase -Database $dbName -BackupFile $dbBackupFile -ServerInstance $secondarySqlServer -NoRecovery -RestoreAction Database

			Write-Output "Adding database '$dbName' to availability group '$availabilityGroup' on primary sql server '$primarySqlServer'"
            Add-SqlAvailabilityDatabase -Database $dbName -Path SQLSERVER:\SQL\$primarySqlServer\Default\AvailabilityGroups\$availabilityGroup

			Write-Output "Adding database '$dbName' to availability group '$availabilityGroup' on secondary sql server '$secondarySqlServer'"
			Add-SqlAvailabilityDatabase -Database $dbName -Path SQLSERVER:\SQL\$secondarySqlServer\Default\AvailabilityGroups\$availabilityGroup
		}
		
		Write-Output "Database successfully added to high availability group." 
	}
	catch [System.Exception]
	{
		Write-Error ("Exception occured during addition of DB into AG group. " + $_.Exception.Message)
		Write-Error ("Failed items. " + $_.Exception.ItemName)
		Exit 2
	}
}


try
{
	##Start of script

	Write-Output "Database automated creation process initiating."

	Write-Output "Executing Sql Database Creation."
	CreateSqlDatabase -dbServerName $SqlServerName -dbName $DbName


	Write-Output "Executing Sql User and Login Creation."
	CreateSqlUserAndLogin -dbServerName $SqlServerName -dbUserName $DbUserName -dbLoginName $DbUserName -dbUserPassword $DbUserPassword -roleName $DbRoleName -dbName $DbName

	if($IsClusterMode)
	{	
		if(!$SecondarySqlServerName)
		{
			Write-Error "Secondary SQL Server Name is required."
			Exit 2
		}

		if(!$AvailabilityGroupName)
		{
			Write-Error "Availability Group Name is required."
			Exit 2
		}

		if(!$FileShareForBackUpFilesLocation)
		{
			Write-Error "BackUp File Location is required."
			Exit 2
		}

		Write-Output "Executing Sql Database Addition to Availability Group."
		$timestamp = Get-Date -Format "ddMMyyyyHHmmss"
		AddDatabaseToAG -dbName $DbName -primarySqlServer $SqlServerName -secondarySqlServer $SecondarySqlServerName -availabilityGroup $AvailabilityGroupName -dbBackupFile "$FileShareForBackUpFilesLocation\$DbName$timestamp.bak"

		Write-Output "Executing Sql User and Login Creation on Secondary Node."
		CreateSqlUserAndLogin -dbServerName $SecondarySqlServerName -dbUserName $DbUserName -dbLoginName $DbUserName -dbUserPassword $DbUserPassword -roleName $DbRoleName -dbName $DbName
	}

	Write-Output "Database automated creation process completed successfully."
	Exit 0
}
catch [System.Exception]
{
    Write-Error ("Exception occured during execution " + $_.Exception.Message)
	Write-Error ("Failed items. " + $_.Exception.ItemName)
	Exit 2
}
