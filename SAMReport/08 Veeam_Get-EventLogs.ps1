
############################################################################################################
#          Info         #
#------------------------

$Title = "Event Logs"
$Comment = "Event Log entries that match your criteria"
$Author = "The Agreeable Cow"
$PluginDate = "1/9/2012"
$Version = "v1.0"

#	1.0		01/9/2012	The Agreeable Cow	Original Build

############################################################################################################
#      Main Script      #
#------------------------

#Create an Array and run query
$ResultsData = @()
$AlertData = @()
$WarningData = @()
$AllServers = $Servers + $Proxies

foreach ($Server in $AllServers){
	#Customise an ALERT query via Event Viewer > Create Custom View > Copy query string from XML tab
	$AlertXML = 	'<QueryList>
						<Query Id="0" Path="System">
						<Select Path="System">*[System[(Level=1  or Level=2) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Select Path="HardwareEvents">*[System[(Level=1  or Level=2) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Select Path="Veeam Backup">*[System[(Level=1  or Level=2) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Suppress Path="System">*[System[(EventID=4)]]</Suppress>
						<Suppress Path="HardwareEvents">*[System[(EventID=4)]]</Suppress>
						<Suppress Path="Veeam Backup">*[System[(EventID=4)]]</Suppress>
						</Query>
						</QueryList>'
	$AlertEvents = Get-WinEvent -ea SilentlyContinue -ComputerName $Server -Filterxml $AlertXML
	
	ForEach ($LogEntry in $AlertEvents)	{ 
		if ($LogEntry.Level -eq 1){$LevelTxt = "!RED!Critical"}
		elseif ($LogEntry.Level -eq 2){$LevelTxt = "!RED!Error"}
		elseif ($LogEntry.Level -eq 3){$LevelTxt = "!ORANGE!Warning"}
		else {$LevelTxt = "Info"}
		
		if ($LogEntry.Message.Length -ge 75){$Msg = $LogEntry.Message.substring(0,75)}
		else {$Msg = $LogEntry.Message}
		
		$obj = New-Object PSobject
		$obj | Add-Member -MemberType NoteProperty -name "Level" -value $LevelTxt
		$obj | Add-Member -MemberType NoteProperty -name "Logged" -value $LogEntry.TimeCreated
		$obj | Add-Member -MemberType NoteProperty -name "Source" -value $LogEntry.ProviderName
		$obj | Add-Member -MemberType NoteProperty -name "ID" -value $LogEntry.ID
		$obj | Add-Member -MemberType NoteProperty -name "Computer" -value $Server
		$obj | Add-Member -MemberType NoteProperty -name "Event Data" -value $Msg
		$AlertData += $obj
		
		$AlertCount += $AlertCount.count + 1	
		}

	#Customise a WARNING query via Event Viewer > Create Custom View > Copy query string from XML tab
	$WarningXML = 	'<QueryList>
						<Query Id="0" Path="System">
						<Select Path="System">*[System[(Level=3) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Select Path="HardwareEvents">*[System[(Level=3) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Select Path="Veeam Backup">*[System[(Level=3) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
						<Suppress Path="System">*[System[(EventID=4)]]</Suppress>
						<Suppress Path="HardwareEvents">*[System[(EventID=4)]]</Suppress>
						<Suppress Path="Veeam Backup">*[System[(EventID=4)]]</Suppress>
						</Query>
					</QueryList>'
	$WarningEvents = Get-WinEvent -ea SilentlyContinue -ComputerName $Server -Filterxml $WarningXML
	
	ForEach ($LogEntry in $WarningEvents) { 
		if ($LogEntry.Level -eq 1){$LevelTxt = "!RED!Critical"}
		elseif ($LogEntry.Level -eq 2){$LevelTxt = "!RED!Error"}
		elseif ($LogEntry.Level -eq 3){$LevelTxt = "!ORANGE!Warning"}
		else {$LevelTxt = "Info"}
		
		if ($LogEntry.Message.Length -ge 75){$Msg = $LogEntry.Message.substring(0,75)}
		else {$Msg = $LogEntry.Message}
		
		$obj = New-Object PSobject
		$obj | Add-Member -MemberType NoteProperty -name "Level" -value $LevelTxt
		$obj | Add-Member -MemberType NoteProperty -name "Logged" -value $LogEntry.TimeCreated
		$obj | Add-Member -MemberType NoteProperty -name "Source" -value $LogEntry.ProviderName
		$obj | Add-Member -MemberType NoteProperty -name "ID" -value $LogEntry.ID
		$obj | Add-Member -MemberType NoteProperty -name "Computer" -value $Server
		$obj | Add-Member -MemberType NoteProperty -name "Event Data" -value $Msg
		$AlertData += $obj
		
		$WarningCount += $WarningCount.count + 1
		}
}

# Results Data
$ResultsData = $AlertData + $WarningData | sort -Property "Logged"

# Results Alert
if ($AlertCount -ge 1){
	$ResultsAlert = "Alert"
}
elseif ($WarningCount -ge 1){
	$ResultsAlert = "Warning"
}
else{
	$ResultsAlert = "Good"
}


############################################################################################################
#        Output         #
#------------------------

$OutText = ""									# $OutText MUST be either $ResultsText or ""  	Valid $ResultsText is any text string
$OutData = $ResultsData							# $OutData MUST be either $ResultsData or "" 	Valid $ResultsData is any data array
$OutAlert = $ResultsAlert						# $OutAlert MUST be either $ResultsAlert or "" 	Valid $ResultsAlert are 'Good', 'Warning' or 'Alert'
$Attachment = ""								# $Attachment MUST be either UNC path or ""