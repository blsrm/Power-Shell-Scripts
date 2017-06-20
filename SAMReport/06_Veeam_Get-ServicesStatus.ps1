
############################################################################################################
#          Info         #
#------------------------

$Title = "Services Status"
$Comment = "Current Status of all Veeam Services"
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		17/08/2012	The Agreeable Cow		Original Build

############################################################################################################
#      Main Script      #
#------------------------

$ServerData = @()
$ProxyData = @()
$ResultsData = @()

foreach ($Server in $Servers){
	foreach ($Service in $ServiceArray){
		#CheckService $Server $Service

		$GetService = Get-Service -computername $Server -Name $Service
	
		if ($GetService.Status -ne “Running”){
			$ServerText += "<span style='color:red'>" + $GetService.displayname + " is not running on " + $Server + ". Please check Veeam Services! </br></span>" 
			$ServiceAlert += $ServiceAlert.count + 1
		}
		
		$obj = New-Object PSobject
		$obj | Add-Member -MemberType NoteProperty -name "Server" -value $Server
		$obj | Add-Member -MemberType NoteProperty -name "Status" -value $GetService.status
		$obj | Add-Member -MemberType NoteProperty -name "Service" -value $GetService.displayname
		$ServerData += $obj
	}
}

foreach ($Server in $Proxies){
	foreach ($Service in $ProxyServiceArray){
		$GetService = Get-Service -computername $Server -Name $Service
	
		if ($GetService.Status -ne “Running”){
			$ProxyText += "<span style='color:red'>" + $GetService.displayname + " is not running on " + $Server + ". Please check Veeam Services! </br></span>" 
			$ServiceAlert += $ServiceAlert.count + 1
		}
		
		$obj = New-Object PSobject
		$obj | Add-Member -MemberType NoteProperty -name "Server" -value $Server
		$obj | Add-Member -MemberType NoteProperty -name "Status" -value $GetService.status
		$obj | Add-Member -MemberType NoteProperty -name "Service" -value $GetService.displayname
		$ProxyData += $obj
	}
}

# Collate Results
$ResultsText = $ServerText + $ProxyText
$ResultsData = $ServerData + $ProxyData
$ResultsData = $ResultsData | sort -Property "Server"

# Results Alert
if ($ServiceAlert -ge 1){
	$ResultsAlert = "Alert"
}
else{
	$ResultsAlert = "Good"
}

############################################################################################################
#        Output         #
#------------------------

$OutText = $ResultsText							# $OutText MUST be either $ResultsText or ""  	Valid $ResultsText is any text string
$OutData = $ResultsData							# $OutData MUST be either $ResultsData or "" 	Valid $ResultsData is any data array
$OutAlert = $ResultsAlert						# $OutAlert MUST be either $ResultsAlert or "" 	Valid $ResultsAlert are 'Good', 'Warning' or 'Alert'
$Attachment = ""								# $Attachment MUST be either UNC path or ""