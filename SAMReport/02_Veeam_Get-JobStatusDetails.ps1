
############################################################################################################
#          Info         #
#------------------------

$Title = "Job Status Details"
$Comment = "The following is a detailed report of the most recent session for all jobs."
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		16/08/2012	The Agreeable Cow		Original Build

############################################################################################################
#      Main Script      #
#------------------------

$WarningAge = 1												# warning highlight for days since last backup
$MaxAge = 7													# error highlight for days since last backup
$ResultsData = @()

foreach($Job in $Jobs) {
	$Session = $Job.FindLastSession()
	if(!$Session){continue;}
	$Info = $Session.GetTaskSessions()
		
	foreach ($VM in $info) {
		# Get Array Data
		$JobName = $job.Name
		$Name = $VM.Name
		$Type = $job.jobtype
		$Status = $VM.status
		$Progress = $VM.Progress.DisplayName
		$Size = [Math]::Round([Decimal]$VM.Progress.ProcessedSize/1GB,2)
		$Start = $VM.progress.starttime 
		$Finish = $VM.progress.stoptime
		$Duration = '{0:00}:{1:00}:{2:00}' -f ($VM.progress.duration | % {$_.Hours, $_.Minutes, $_.Seconds})
		$schedule = $job.GetScheduleOptions()
			$NextRun = $schedule.NextRun
		$Age = ((Get-Date) - $Finish).Days
			if ($Status -eq "Success"){
				if ($age -gt $MaxAge) {
					$age = "!RED!" + $age
					$AgeAlert += $AgeAlert.count + 1			
				}
				if ($age -ge $WarningAge) {
					$age = "!ORANGE!" + $age
					$AgeWarning += $AgeWarning.count + 1
				}
				if ($age -lt $WarningAge) {
					$age = "!GREEN!" + $age
					$AgeGood += $AgeGood.count + 1
				}
			}
			else{
				$age = ""
			}
		$Message = $VM.GetDetails()
	
		# Status Count
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
		
		#Load Array
		$obj = New-Object PSobject
		$obj | Add-Member -MemberType NoteProperty -name "Job Name" -value $JobName
		$obj | Add-Member -MemberType NoteProperty -name Type -value $Type
		$obj | Add-Member -MemberType NoteProperty -name Name -value $Name
		$obj | Add-Member -MemberType NoteProperty -name Status -value $Status
		$obj | Add-Member -MemberType NoteProperty -name "Size Gb" -value $Size
		$obj | Add-Member -MemberType NoteProperty -name Start -value $Start
		$obj | Add-Member -MemberType NoteProperty -name Finish -value $Finish
		$obj | Add-Member -MemberType NoteProperty -name Duration -value $Duration
		$obj | Add-Member -MemberType NoteProperty -name Age -value $Age
		$obj | Add-Member -MemberType NoteProperty -name NextRun -value $NextRun
		$obj | Add-Member -MemberType NoteProperty -name Message -value $Message
		$ResultsData += $obj 
	}
}

$ResultsData = $ResultsData | sort -Property "Job Name"

# Results Alert
if ($JobsFailed -ge 1 -OR $JobsUnknown -ge 1 -OR $AgeAlert -ge 1){
	$ResultsAlert = "Alert"
}
elseif ($JobsPending -ge 1 -OR $JobsPending -ge 1 -OR $AgeWarning){
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