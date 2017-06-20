
############################################################################################################
#          Info         #
#------------------------

$Title = "Backup Storage Status"
$Comment = "The following shows storage data and any alerts for Veeam Backup repositories"
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		16/08/2012	The Agreeable Cow		Original Build

############################################################################################################
#      Main Script      #
#------------------------

$BackupDiskWarning = 10									# Warning highlight for % free disk space
$BackupDiskAlert = 5									# Alert highlight for % free disk space

# Get Backup data
$ResultsData = $BackupList | Get-vPCRepoInfo | Select @{Name="Repository Name"; Expression = {$_.Target}}, @{Name="Path"; Expression = {$_.Storepath}}, 
@{Name="Free (GB)"; Expression = {$_.StorageFree}}, @{Name="Total (GB)"; Expression = {$_.StorageTotal}}, @{Name="Free (%)"; Expression = {$_.FreePercentage}}

# Get Low Disk Space Alerts
foreach ($r in $BackupList) {
	if ($r.Type -eq "WinLocal") {
		$Server = $r.GetHost()
		$FileCommander = [Veeam.Backup.Core.CRemoteWinFileCommander]::Create($Server.Info)
		$storage = $FileCommander.GetDrives([ref]$null) | ?{$_.Name -eq $r.Path.Substring(0,3)}
		$RepoFree = $storage.FreeSpace
		$RepoTotal = $storage.TotalSpace
	}
	elseif ($r.Type -eq "LinuxLocal") {
		$Server = $r.GetHost()
		$FileCommander = new-object Veeam.Backup.Core.CSshFileCommander $server.info
		$storage = $FileCommander.FindDirInfo($r.Path)
		$RepoFree = $storage.FreeSpace
		$RepoTotal = $storage.TotalSize
	}
	elseif ($r.Type -eq "CifsShare") {
		$fso = New-Object -Com Scripting.FileSystemObject
		$storage = $fso.GetDrive($r.Path)
		$RepoFree = $storage.AvailableSpace
		$RepoTotal = $storage.TotalSize
	}

	$RepoType = $r.Type
	$RepoName = $r.Name
	$RepoPath = $r.Path
	$RepoFree = [Math]::Round([Decimal]$RepoFree/1GB,2)
	$RepoTotal = [Math]::Round([Decimal]$RepoTotal/1GB,2)
	$RepoFreePercent = [Math]::Round(($RepoFree/$RepoTotal)*100)
	
	if ($RepoFreePercent -le $BackupDiskAlert) {
		$ResultsText += "<span style='color:red'>Alert! Extremely low disk space for " + $RepoPath + " (" + $RepoFree + "Gb left of " + $RepoTotal + "Gb) </br></span>"
		$BackupAlert += $BackupAlert.count + 1
	}
	elseif ($RepoFreePercent -le $BackupDiskWarning) {
		$ResultsText += "<span style='color:orange'>Warning! Low disk space for " + $RepoPath + " (" + $RepoFree + "Gb left of " + $RepoTotal + "Gb) </br></span>"
		$BackupWarning += $BackupWarning.count + 1
	}
}

# Results Alert
if ($BackupAlert -ge 1){
	$ResultsAlert = "Alert"
}
elseif ($BackupWarning -ge 1){
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