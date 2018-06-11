# exportWindowsSources: Export Windows Sources from Active Directory for import into NetWitness

## Version 0.1

*exportWindowsSources* is a Windows PowerShell tool which allows one to export enabled Windows Event sources from Active Directory, in bulk.  It outputs CSV text which can be either directly imported to a Log Collector through Kensington Tech's AddWindowsSources automated solution, or manually via the NetWitness user interface.

## IMPORTANT NOTE

This script returns only computer objects which are enabled on the target domain.  Disabled computers will not be displayed.


## Prerequisites
1.  A Windows host with PowerShell 2 or higher installed

2.  The 'Remote Server Administration Tools' Windows feature must be installed, and the 'Active Directory module for Windows Powershell' module of said feature must be enabled.  For more info, visit https://4sysops.com/archives/how-to-install-the-powershell-active-directory-module

3.  An Active Directory account with sufficient permissions to access Active Directory Computer objects for a given AD domain.  This user can run exportWindowsSources either interactively (through PowerShell itself) or as a service account through the Windows scheduler.


## Installation
1.  Copy the exportWindowsSources.ps1 script to the Windows host that you've chosen, placing it in a directory which the user has permission to access.


## Usage

Usage: `$($scriptName) domainSuffix [ [DomainSearchBase] [DomainControllerHost] ]`

Option | Description
------ | -----------
domainSuffix | (required) is the DNS suffix for computer objects which do not possess the DNSHostName attribute, so that the Name attribute can be fully-qualified (i.e. a computer called 'mycomputer' can be named 'mycomputer.subdomain.mydomain.com').  This typically should be the domain suffix of the domain you're fetching from (e.g. 'mysubdomain.mydomain.com').  Do not include a leading period
domainSearchBase | (optional) is LDAP search DN of the domain to query, like "DC=MyDomain,DC=com".  If specified, DomainControllerHost must also be specified
domainControllerHost | (optional) is the hostname of a domain controller for the domain you're accessing

## Examples

Runs on current AD domain (mydomain.com):   `& ".\exportWindowsSources.ps1" mydomain.com`
Runs on AD domain mydomain.com:             `& ".\exportWindowsSources.ps1" mydomain.com "DC=mydomain,DC=com" mydc.mydomain.com`
Runs on AD domain subdomain.mydomain.com:   `& ".\exportWindowsSources.ps1" subdomain.mydomain.com "DC=subdomain,DC=mydomain,DC=com" mydc.subdomain.mydomain.com`


## SAVING FILES TO DISK
Similar to many UNIX tools, this tool DOES NOT write files directly to disk.  By default, it outputs to the local console.  To write the CSV to disk, its output must be redirected to a file using the '>' (overwrite) or '>>' (append) operators.

E.g.

`& ".\exportWindowsSources.ps1" mydomain.com "DC=mydomain,DC=com" mydc.mydomain.com > mydomain.com_export.csv`


## Troubleshooting

* If Windows refuses to execute the script, please know that this script is distributed in an unsigned form, therefore the Powershell execution policy must be set to 'Bypass' (no warning displayed) or 'Unrestricted' (displays a warning first) to run it.  To check the policy, run 'Get-ExecutionPolicy' from Powershell.  For more info, visit https://technet.microsoft.com/en-us/library/ee176961.aspx

* If the script outputs empty CSV files, it will display an error on the command line.  If you are running the tool as a scheduled task, it may be necessary to run the command interactively with Windows Powershell using the service account of the scheduled task.  To do this, run Powershell, and type the command:

`start powershell -credential ""`


## Changing Default CSV Values
If it should be necessary for your environment to change the default values which are output by the tool, the script file itself must be edited.  Change the value of the below variables to suit your neeeds:

Variable | Description
-------- | -----------
$portNumber | Usually either 5985 (for HTTP) or 5986 (for HTTPS).  Defaults to 5985
$transportMode | Either 'http' or 'https'.  Defaults to 'http'
$debug | Either '0' (disabled - default) or '1' (enabled).  Enables debug logging in Log Collector logs for the event sources
$enabled | Either 'true' (default) or 'false'.  Enables or disables the event source.  Defaults to 'true'
$certName | The name of the certificate to use to authenticate to WinRM.  Defaults to an empty string ('').  Specified only if using HTTPS transport.  
$validateServer | Not documented by RSA
$renderLocale | The locale to render the event logs in.  Defaults to an empty string ('')
$resolveSids | Either 'true' (default) or 'false'.  Resolve Windows SID's to readable names
$sidsInterval | The number of seconds??? to cache resolved SID names before refreshing.  Defaults to 14400
$sidsTimeout | SID timeout, in seconds.  Defaults to 60
$overrideChannels | Defaults to an empty string ('')


## CSV Output Format and example
```
eventsource_address,port_number,transport_mode,debug,enabled,cert_name,validate_server,render_locale,windows_type,resolve_sids,sids_interval,sids_timeout,override_channels
dc1.mydomain.local,5985,http,0,true,,false,en-US,Domain Controller,true,14400,60,
dc2.mydomain.local,5985,http,0,true,,false,en-US,Domain Controller,true,14400,60,
host1.mydomain.local,5985,http,0,true,,false,en-US,Non-Domain Controller,true,14400,60,
```