
############################################################################################################
#          Info         #
#------------------------

$Title = "Unprotected Machines"
$Comment = "Backup status of VMs in vCenter"
$Author = "The Agreeable Cow"
$PluginDate = "August 2012"
$Version = "v1.0"

#	1.0		20/08/2012	The Agreeable Cow		Original Build
#	0.0		3/7/2012	tSightler			Original scripts (http://sightunseen.org/blog/?p=1)

############################################################################################################
#      Main Script      #
#------------------------

$PoweredOnVMsOnly = "Y"					# Change to "N" to include powered off VMs (eg Replicas and Templates)
$ExcludeVMs=@("Server1","Server2")	    # Specifically exclude more VMs eg ("vm1","vm2")
$AgeAlert = 7							# Alert on machines older than this many days
$ResultsData=@()

# Connect to vCenter 
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | out-null
Connect-ViServer $VMware_Server | out-null

# Build hash table with excluded VMs
$excludedvms=@{}
foreach ($vm in $excludevms) {
    $excludedvms.Add($vm, "Excluded")
}

# Get a list of all VMs from vCenter and add to hash table, assume Unprotected
$vms=@{}
foreach ($vm in (Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"} | ForEach-Object {$_ | Select-object @{Name="VMname";Expression={$_.Name}}}))  {
    if (!$excludedvms.ContainsKey($vm.VMname)) {
        $vms.Add($vm.VMname, "Unprotected")
    }
}

# Find all backup job sessions that have ended in the last week
$vbrsessions = Get-VBRBackupSession | Where-Object {$_.JobType -eq "Backup" -or $_.JobType -eq "Replica" -and $_.EndTime -ge (Get-Date).adddays(-$AgeAlert)}

# Find all successfully backed up VMs in selected sessions (i.e. VMs not ending in failure) and update status to "Protected"
$backedupvms=@{}
foreach ($session in $vbrsessions) {
    foreach ($vm in ($session.gettasksessions() | Where-Object {$_.Status -ne "Failed"} | ForEach-Object { $_ | Select-object @{Name="VMname";Expression={$_.Name}}})) {
        if($vms.ContainsKey($vm.VMname)) {
            $vms[$vm.VMname]="Protected"
        }
    }
}

# Output VMs in color coded format based on status.
$ResultsText = "All VMs matching your criteria have been backed up in the past " + $AgeAlert + " Day(s)"
$ResultsAlert = "Good"	
foreach ($vm in $vms.Keys){
    if ($vms[$vm] -ne "Protected") {
        $obj = New-Object PSobject
        $obj | Add-Member -MemberType NoteProperty -name "Server" -value $vm
        $ResultsData += $obj 
        $ResultsText = "The following machines have not been backed up in the past " + $AgeAlert + " Day(s)"
        $ResultsAlert = "Alert"	
    }
}


############################################################################################################
#        Output         #
#------------------------

$OutText = $ResultsText							# $OutText MUST be either $ResultsText or ""  	Valid $ResultsText is any text string
$OutData = $ResultsData							# $OutData MUST be either $ResultsData or "" 	Valid $ResultsData is any data array
$OutAlert = $ResultsAlert						# $OutAlert MUST be either $ResultsAlert or "" 	Valid $ResultsAlert are 'Good', 'Warning' or 'Alert'
$Attachment = ""								# $Attachment MUST be either UNC path or ""