
############################################################################################################
#          Info        #
#------------------------

$Title = "Job Status Summary"
$Comment = "The following is a summary of the most recent session for all jobs."
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		16/08/2012	The Agreeable Cow		Original Build

############################################################################################################
#      Main Script      #
#------------------------

# Get Job Status
foreach($Job in $Jobs)
	{
	$Session = $Job.FindLastSession()
	if(!$Session){continue;}
	$Info = $Session.GetTaskSessions()

	foreach ($VM in $info) {
		$JobsTotal += $JobsTotal.count + 1
		$Status = $VM.status
		if ($Status -eq "Success"){
			$JobsSuccess += $JobsSuccess.count + 1
		}
		if ($Status -eq "InProgress" -or $Status -eq "Pending"){
			$JobsPending += $JobsPending.count + 1
		}			
		if ($Status -eq "Warning"){
			$JobsWarning += $JobsWarning.count + 1
		}	
		if ($Status -eq "Failed"){
			$JobsFailed += $JobsFailed.count + 1
		}	
	}
}

# Status Count and formatting
$JobsCount = $JobsSuccess + $JobsPending + $JobsWarning + $JobsFailed
$JobsUnknown = $JobsTotal - $JobsCount
	if ($JobsSuccess -eq $NULL){$JobsSuccess = "0"}
	if ($JobsPending -eq $NULL){$JobsPending = "0"}
	if ($JobsWarning -eq $NULL){$JobsWarning = "0"}
	if ($JobsFailed -eq $NULL){$JobsFailed = "0"}
	if ($JobsUnknown -eq $NULL){$JobsUnknown = "0"}

$ResultsText = "Total Jobs: " + $JobsTotal + "</br>" + "Success: " + $JobsSuccess  + "</br>" + "Pending: " + $JobsPending + "</br>" + "Warning: " + $JobsWarning + "</br>" + "Failed: " + $JobsFailed + "</br>" + "Unknown: "  + $JobsUnknown

# Results Alert
if ($JobsFailed -ge 1 -OR $JobsUnknown -ge 1){
	$ResultsAlert = "Alert"
}
elseif ($JobsPending -ge 1 -OR $JobsPending -ge 1){
	$ResultsAlert = "Warning"
}
else{
	$ResultsAlert = "Good"
}
############################################################################################################
#        Output         #
#------------------------

$OutText = $ResultsText							# $OutText MUST be either $ResultsText or ""  	Valid $ResultsText is any text string
$OutData = ""									# $OutData MUST be either $ResultsData or "" 	Valid $ResultsData is any data array
$OutAlert = $ResultsAlert						# $OutAlert MUST be either $ResultsAlert or "" 	Valid $ResultsAlert are 'Good', 'Warning' or 'Alert'
$Attachment = ""								# $Attachment MUST be either UNC path or ""

#Export-ModuleMember