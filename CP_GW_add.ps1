#--------------------------------------------------------------------------------------
#RN-Exploration CP gateway changer utility
#Date: 23.12.2020
#Version: 1.0
#Author: Satalkin Oleg
#
#----------SETTINGS--------------------------------------------------------------------
#--------------------------------------------------------------------------------------
[CmdletBinding()]
    param(
		[Parameter(Mandatory = $true, Position=1, ValueFromPipeline = $true)]
        [String]$RNEXP_GW_new,
        [Parameter(Mandatory = $true, Position=2, ValueFromPipeline = $true)]
		[String]$RNEXP_GW_old,
		[switch]$IsCheckpointMobile
    )
#--------------------------------------------------------------------------------------
#
#Select CP type: full or mobile:
#CP full
$tracPathFull='C:\Program Files (x86)\CheckPoint\Endpoint Security\Endpoint Connect\trac.exe'
#CP Mobile 
$tracPathMobile='C:\Program Files (x86)\CheckPoint\Endpoint Connect\trac.exe'

if ($IsCheckpointMobile) {$tracPath=$tracPathMobile} else {$tracPath=$tracPathFull}

#Set new GW
$gatewayName=$RNEXP_GW_new
#checking new GW already exists
$status = & $tracPath 'info' '-s' $gatewayName
if (($status|Select-String -SimpleMatch("Connection could not be found")).count -gt 0) {
	#disconnecting from any GW
	$status = & $tracPath 'info'
    if (($status|Select-String -SimpleMatch("Connected")).count -gt 0) {& $tracPath 'disconnect'}
	
	#get dn of user certificate
	$userCertificateString = & $tracPath 'list' | Select-String -SimpleMatch "OU=CheckPoint_Users,OU=ITB,DC=ITB,DC=local"
	$userCertificate=$userCertificateString.line.split('(')[0].trim()
	"User certificate dn: "+$userCertificate
	#adding new GW
	& $tracPath 'create' '-s' $gatewayName '-a' 'certificate' 
	#connecting new GW
	& $tracPath 'connect' '-s' $gatewayName '-d' $userCertificate
	#checking new GW for readiness
	$status = & $tracPath 'info' '-s' $gatewayName
	if (($status|Select-String -SimpleMatch("Connected")).count -gt 0) {
		#removing old GW
		& $tracPath 'delete' '-s' $RNEXP_GW_old
		"GW was successfully changed. Well done!"
		
		#folder renaming
		if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") { $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
		else { $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
			if (!$ScriptPath){ $ScriptPath = "." } }
		
		$oldFolderPath=$ScriptPath+"\"+$RNEXP_GW_old
		if (Test-Path $oldFolderPath) {
			Rename-Item -Path $oldFolderPath -NewName $RNEXP_GW_new
			"Old folder "+$RNEXP_GW_old+" was renamed to "+$RNEXP_GW_new
		} else {"Old folder "+$RNEXP_GW_old+" not found"}
	} else {
		"New GW is not ready yet. Please, try later."
	}
} else {
	#New GW is already exists
	"New GW is already exists. Nothing was changed."
}
Write-Host "Press any key..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null