
############################################################################################################
#          Info         #
#------------------------

$Title = "Replica Storage Status"
$Comment = "The following shows storage data and any alerts for Veeam Replica repositories"
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		16/08/2012	The Agreeable Cow		Original Build

############################################################################################################
#      Main Script      #
#------------------------

$ReplicaDiskWarning = 10								# Warning highlight for % free disk space
$ReplicaDiskAlert = 5									# Alert highlight for % free disk space

#Replica Storage Info
$repList = Get-VBRJob | ?{$_.IsReplica} 

#Low Disk Space Alerts
foreach ($replica in $repList) {
	$repHost = $replica.GetTargetHost()
	$ds =  $repHost | Find-VBRDatastore -Name $replica.ViReplicaTargetOptions.DatastoreName	
			
	$Target = $repHost.Name
	$Datastore = $replica.ViReplicaTargetOptions.DatastoreName
	$StorageFree = [Math]::Round([Decimal]$ds.FreeSpace/1GB,2)
	$StorageTotal = [Math]::Round([Decimal]$ds.Capacity/1GB,2)
	$FreePercent = [Math]::Round(($ds.FreeSpace/$ds.Capacity)*100)

	if ($FreePercent -le $ReplicaDiskAlert) {
		$ResultsText += "<span style='color:red'>Alert! Extremely low disk space for " + $Datastore + " (" + $StorageFree + "Gb left of " + $StorageTotal + "Gb) </br></span>"
		$ReplicaAlert += $ReplicaAlert.count + 1
	}
	elseif ($FreePercent -le $ReplicaDiskWarning) {
		$ResultsText += "<span style='color:orange'>Warning! Low disk space for " + $Datastore + " (" + $StorageFree + "Gb left of " + $StorageTotal + "Gb) </br></span>"
		$ReplicaWarning += $ReplicaWarning.count + 1
	}
}

#Replica Data
$ResultsData = $repList | Get-vPCReplicaTarget | Select @{Name="Replica Target"; Expression = {$_.Target}}, Datastore, @{Name="Free (GB)"; Expression = {$_.StorageFree}}, 
@{Name="Total (GB)"; Expression = {$_.StorageTotal}}, @{Name="Free (%)"; Expression = {$_.FreePercentage}} 

# Results Alert
if ($ReplicaAlert -ge 1){
	$ResultsAlert = "Alert"
}
elseif ($ReplicaWarning -ge 1){
	$ResultsAlert = "Warning"
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