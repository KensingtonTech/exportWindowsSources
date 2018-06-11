### 
### exportWindowsSources
### Version 0.1
### 16 July, 2017
### Kensington Technology Associates, Limited
### info@knowledgekta.com
### http://knowledgekta.com
### 
### MIT License
### 
### Copyright (c) 2017, Kensington Technology Associates, Limited
### 
### Permission is hereby granted, free of charge, to any person obtaining a copy
### of this software and associated documentation files (the "Software"), to deal
### in the Software without restriction, including without limitation the rights
### to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
### copies of the Software, and to permit persons to whom the Software is
### furnished to do so, subject to the following conditions:
### 
### The above copyright notice and this permission notice shall be included in all
### copies or substantial portions of the Software.
### 
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
### FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
### AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
### LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
### OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
### SOFTWARE.
### 

Try {
  Import-Module ActiveDirectory -ErrorAction Stop
}
Catch {
  Write-Host "ERROR: Could not import the ActiveDirectory module for PowerShell.  Have you installed the 'Remote Server Administration Tools' Windows feature, and if so, have you enabled 'Active Directory module for Windows Powershell'?  See README for more info"
  exit
}

$version = '0.1'

$portNumber = '5985'
$transportMode = 'http'
$debug = '0'
$enabled = 'true'
$certName = ''
$validateServer = 'false'
$renderLocale = ''
$resolveSids = 'true'
$sidsInterval = '14400'
$sidsTimeout = '60'
$overrideChannels = ''


$scriptName = $MyInvocation.MyCommand.Name
$cpr = [char]0x00A9
$usage = @"
exportWindowsSources tool version $($version)
Copyright $($cpr) 2017, Kensington Technology Associates, Limited
Licensed under MIT License (See LICENSE file)

Usage: $($scriptName) domainSuffix [ [domainSearchBase] [domainControllerHost] ]

Outputs CSV notation describing enabled computers in a Windows AD domain.  This notation is in a format which can be imported into a NetWitness Log Collector automatically by Kensington Tech's addWindowsSources tool or manually via the RSA NetWitness console

Options:

domainSuffix - (required) is the DNS suffix for computer objects which do not possess the DNSHostName attribute, so that the Name attribute can be fully-qualified (i.e. a computer called 'mycomputer' can be named 'mycomputer.subdomain.mydomain.com'). This typically should be the domain suffix of the domain you're fetching from (e.g. 'mysubdomain.mydomain.com'). Do not include a leading period

domainSearchBase - (optional) is LDAP search DN of the domain to query, like 'DC=MyDomain,DC=com'. If specified, DomainControllerHost must also be specified

domainControllerHost - (optional) is the hostname of a domain controller for the domain you're accessing

"@

$sysArgsLen = $args.Length

if ($sysArgsLen -ne 1 -and $sysArgsLen -ne 3) {
  Write-Host $usage
  exit
}

$domainSuffix = $args[0]

$searchBase = ''
$domainController = ''
if ($args.length -eq 3) {
  $searchBase = $args[1]
  $domainController = $args[2]
}

function getSystems {
  $LDAPfilter = $args[0]
  #Write-Host $LDAPfilter
  $systems = @()
 
  Try {
   
    if ($sysArgsLen -eq 1) {
      $computers = Get-ADComputer -LDAPfilter $LDAPfilter -Properties 'DNSHostName','Name' -ErrorAction Stop
    }
    elseif ($sysArgsLen -eq 3) {
      $computers = Get-ADComputer -LDAPfilter $LDAPfilter -Properties 'DNSHostName','Name' -SearchBase $searchBase -Server $domainController -ErrorAction Stop
    }
    
    ForEach ($c in $computers) {
      if ( [bool]$c.DNSHostName -eq $True ) {
        $systems += $c.DNSHostName
      }
      elseif ([bool]$c.Name -eq $True) {
        $systems += "$($c.Name).$($domainSuffix)"
      }
    }
    return $systems
  }
  Catch {
    #$e = $_.Exception.GetType().FullName
    $e = $_.Exception.Message
    Write-Host "ERROR: $($e)"
    exit
  }
  
  
}

$dcFilter = "(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
$nonDCFilter = "(&(objectCategory=Computer)(!userAccountControl:1.2.840.113556.1.4.803:=8192)(!userAccountControl:1.2.840.113556.1.4.803:=2))"

$nonDCs = getSystems $nonDCFilter
$DCs = getSystems $dcFilter

#print header
echo "eventsource_address,port_number,transport_mode,debug,enabled,cert_name,validate_server,render_locale,windows_type,resolve_sids,sids_interval,sids_timeout,override_channels"

$windowsType = 'Non-Domain Controller'
ForEach ($h in $nonDCs) {
  #echo "$($h),5985,http,0,true,,false,,Non-Domain Controller,true,14400,60,"
  echo "$($h),$($portNumber),$($transportMode),$($debug),$($enabled),$($certName),$($validateServer),$($renderLocale),$($windowsType),$($resolveSids),$($sidsInterval),$($sidsTimeout),$($overrideChannels)"
}

$windowsType = 'Domain Controller'
ForEach ($h in $DCs) {
  #echo "$($h),5985,http,0,true,,false,,Domain Controller,true,14400,60,"
  echo "$($h),$($portNumber),$($transportMode),$($debug),$($enabled),$($certName),$($validateServer),$($renderLocale),$($windowsType),$($resolveSids),$($sidsInterval),$($sidsTimeout),$($overrideChannels)"
}
