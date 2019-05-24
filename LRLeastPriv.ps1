#This script will automaticaly configure Windows LogRhythm Agent with least privilage permissions. 
#You will still need to set the service username and password after the script runs.
#Be sure to update the variables below.

################################# SETTINGS ########################################

#Set the name of your least privilage service account here
$ServiceAccount = "domain\username"

#If you agent is installed to non-standard location change these variables to match. 
$InstallDir = "C:\Program Files\LogRhythm\LogRhythm System Monitor"
$InstallReg = "HKLM:\SYSTEM\CurrentControlSet\services\scsm"

#################################################################################


#Function from Ingo Karstein to add logon as a serivce rights
#https://gallery.technet.microsoft.com/scriptcenter/Grant-Log-on-as-a-service-11a50893

function AddLogonAsService{
param($accountToAdd)
#written by Ingo Karstein, http://blog.karstein-consulting.com
#  v1.0, 01/03/2014

## <--- Configure here

if( [string]::IsNullOrEmpty($accountToAdd) ) {
	Write-Host "no account specified"
	exit
}

## ---> End of Config

$sidstr = $null
try {
	$ntprincipal = new-object System.Security.Principal.NTAccount "$accountToAdd"
	$sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	$sidstr = $sid.Value.ToString()
} catch {
	$sidstr = $null
}

Write-Host "Account: $($accountToAdd)" -ForegroundColor DarkCyan

if( [string]::IsNullOrEmpty($sidstr) ) {
	Write-Host "Account not found!" -ForegroundColor Red
	exit -1
}

Write-Host "Account SID: $($sidstr)" -ForegroundColor DarkCyan

$tmp = [System.IO.Path]::GetTempFileName()

Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
secedit.exe /export /cfg "$($tmp)" 

$c = Get-Content -Path $tmp 

$currentSetting = ""

foreach($s in $c) {
	if( $s -like "SeServiceLogonRight*") {
		$x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		$currentSetting = $x[1].Trim()
	}
}

if( $currentSetting -notlike "*$($sidstr)*" ) {
	Write-Host "Modify Setting ""Logon as a Service""" -ForegroundColor DarkCyan
	
	if( [string]::IsNullOrEmpty($currentSetting) ) {
		$currentSetting = "*$($sidstr)"
	} else {
		$currentSetting = "*$($sidstr),$($currentSetting)"
	}
	
	Write-Host "$currentSetting"
	
	$outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@

	$tmp2 = [System.IO.Path]::GetTempFileName()
	
	
	Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
	$outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force

	#notepad.exe $tmp2
	Push-Location (Split-Path $tmp2)
	
	try {
		secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
		#write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
	} finally {	
		Pop-Location
	}
} else {
	Write-Host "NO ACTIONS REQUIRED! Account already in ""Logon as a Service""" -ForegroundColor DarkCyan
}

Write-Host "Done." -ForegroundColor DarkCyan
}


    AddLogonAsService $ServiceAccount

#Set ACLs on LogRhythm install dir.

    $acl = Get-Acl $InstallDir
    $accessRule = New-Object system.Security.AccessControl.FileSystemAccessRule($ServiceAccount, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $InstallDir

#Set ACL on LogRhythm Registry path.

    $acl = Get-Acl $InstallReg
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($ServiceAccount, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    $acl |Set-Acl -Path $InstallReg

#Add service account to required groups. 

    Add-LocalGroupMember -Group "Event Log Readers" -Member $ServiceAccount
    Add-LocalGroupMember -Group "Performance Log Users" -Member $ServiceAccount
