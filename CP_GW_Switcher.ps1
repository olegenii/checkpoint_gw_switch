#--------------------------------------------------------------------------------------
#RN-Exploration CP gateway switcher
#Date: 24.12.2020
#Version: 1.1
#Author: Satalkin Oleg
#--------------------------------------------------------------------------------------
[CmdletBinding()]
    param(
		[Parameter(Mandatory = $true, Position=1, ValueFromPipeline = $true)]
        [String]$gatewayName,
		[switch]$IsCheckpointMobile
    )

#Select CP type: full or mobile:
#CP full
$tracPathFull='C:\Program Files (x86)\CheckPoint\Endpoint Security\Endpoint Connect\trac.exe'
#CP Mobile 
$tracPathMobile='C:\Program Files (x86)\CheckPoint\Endpoint Connect\trac.exe'

if ($IsCheckpointMobile) {$tracPath=$tracPathMobile} else {$tracPath=$tracPathFull}

#get dn of user certificate
$userCertificateString = & $tracPath 'list' | Select-String -SimpleMatch "OU=CheckPoint_Users,OU=ITB,DC=ITB,DC=local"
$userCertificate=$userCertificateString.line.split('(')[0].trim()
"User certificate dn: "+$userCertificate

# check if gateway exist
$status = & $tracPath 'info' '-s' $gatewayName
if (($status.trim()).Contains("Connection could not be found")) {
	#disconnecting from any GW
	$status = & $tracPath 'info'
    if (($status|Select-String -SimpleMatch("Connected")).count -gt 0) {& $tracPath 'disconnect'}
	#adding new GW
	& $tracPath 'create' '-s' $gatewayName '-a' 'certificate'
	#connecting new GW
	& $tracPath 'connect' '-s' $gatewayName '-d' $userCertificate	
}
else{
	if (($status|Select-String -SimpleMatch("status: Idle")).count -gt 0){
		#disconnecting from any GW
		$status = & $tracPath 'info'
		if (($status|Select-String -SimpleMatch("Connected")).count -gt 0) {& $tracPath 'disconnect'}
		& $tracPath 'connect' '-s' $gatewayName '-d' $userCertificate	
	}
}
