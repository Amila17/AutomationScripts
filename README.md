# AutomationScripts

This repository contains scripts that perform different functionality on different products / services. 

The repository is divided into two sections:

- Powershell Scripts
- Python Scripts

## Powershell Scripts ##

### ExecuteRundeckJob.ps1 ###

This script contains functionality to call the RunDeck API to get a job based on the group and job name and execute the job with the id provided.

To execute the script the following command could be used:


    ExecuteRundeckJob.ps1 -username "username" -password "password" -runDeckUrl "RunDeck_Url" -groupName "group_name" -jobName "job_name" -environment "environment"
 

## Python Scripts ##

###CacheBusting.py ###

This script cleans up the cache location of a service and restarts the service. This script it mainly written for clearing nginx proxy cache. Example execution of this script in linux is: 

    python CacheBusting.py -p '/var/cache/nginx/' -s 'nginx'

- `-p | -path -> path of where the proxy cache resides`.
- `-s | -serviceName -> name of the proxy service`.
