#
# Windows_FileCreation.ps1
#
param([string]$path = $OctopusParameters['nagioactivatorpath'], 
[string]$filename = $OctopusParameters['applicationname'])

if(!(Test-Path -Path $path))
{
	New-Item -ItemType Directory -Path $path -Force
	New-Item -ItemType File -Path "$path/$filename" -Force
}
else
{
	New-Item -ItemType File -Path "$path/$filename" -Force
}