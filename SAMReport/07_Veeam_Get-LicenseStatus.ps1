
############################################################################################################
#          Info         #
#------------------------

$Title = "License Check"
$Comment = "Information regarding Veeam Licensing"
$Author = "The Agreeable Cow"
$PluginDate = "27/08/2012"
$Version = "v1.0"

#	1.0		01/01/2013	The Agreeable Cow	Original Build
#	0.0		29/12/2011	Arne Fokkema	Script Source	http://ict-freak.nl/2011/12/29/powershell-veeam-br-get-total-days-before-the-license-expires/

############################################################################################################
#      Main Script      #
#------------------------

$WarningDays = 60				# Number of days before license expires to flag a warning
$AlertDays = 30					# Number of days before license expires to flag an alert

#Get version and Licenses Info
$VeeamVersion = Get-VeeamVersion
$regBinary = (Get-Item 'HKLM:\SOFTWARE\VeeaM\Veeam Backup and Replication\license').GetValue('Lic1')
$veeamLicInfo = [string]::Join($null, ($regBinary | % { [char][int]$_; }))

if($VeeamVersion -like "6*"){
    $pattern = "Expiration date\=\d{1,2}\/\d{1,2}\/\d{1,4}"
}
elseif($VeeamVersion -like "5*"){
    $pattern = "EXPIRATION DATE\=\d{1,2}\/\d{1,2}\/\d{1,4}"
}

# Convert Binary key
if($VeeamVersion -like "5*" -OR $VeeamVersion -like "6*"){
	$expirationDate = [regex]::matches($VeeamLicInfo, $pattern)[0].Value.Split("=")[1]
	$totalDaysLeft = ((Get-Date $expirationDate) - (get-date)).Totaldays.toString().split(",")[0]
	$totalDaysLeft = [int]$totalDaysLeft

	if($totalDaysLeft -lt $AlertDays){
		$ResultsText = "Alert: The Veeam License will expire in $($totalDaysLeft) days"
		$ResultsAlert = "Alert"
	}
	elseif($totalDaysLeft -lt $WarningDays){
		$ResultsText = "Warning: The Veeam License will expire in $($totalDaysLeft) days"
		$ResultsAlert = "Warning"
	}
	else{
		$ResultsText = "The Veeam License will expire in $($totalDaysLeft) days"
		$ResultsAlert = "Good"
	}
}
else{
	$ResultsText = "Warning: Unable to process Veeam version"
    $ResultsAlert = "Warning"
}

	
############################################################################################################
#        Output         #
#------------------------

$OutText = $ResultsText							# $OutText MUST be either $ResultsText or ""  	Valid $ResultsText is any text string
$OutData = ""									# $OutData MUST be either $ResultsData or "" 	Valid $ResultsData is any data array
$OutAlert = $ResultsAlert						# $OutAlert MUST be either $ResultsAlert or "" 	Valid $ResultsAlert are 'Good', 'Warning' or 'Alert'
$Attachment = ""								# $Attachment MUST be either UNC path or ""