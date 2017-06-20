############################################################################################################
#   Module Variables - Veeam   #
#-------------------------------#

# Customise report Variables
$EmailTo = $EmailTo
$EmailSubject = $EmailSubject
$ReportTitle = $ReportTitle
$ReportSubTitle = $ReportSubTitle

# Load required plug-ins
if ( (Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin -Name VeeamPSSnapIn
}
if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin -Name VMware.VimAutomation.Core
}

 
# Load server and array information
$Servers = ($env:COMPUTERNAME)
$VMware_Server = "vcenter.mydomain.com.au"
$Proxies = @("vbrproxy1","vbrproxy2","vbrproxy7","vbrproxy8")
$ServiceArray = @("VeeamBackupService.exe","Veeam Backup Catalog Data Service","VeeamTransportSvc","Veeam Backup and Replication Service","VeeamDeploymentService","VeeamNFSSvc")
$ProxyServiceArray = @("VeeamTransportSvc","VeeamDeploymentService")
$Jobs = Get-VBRJob
$BackupList = Get-VBRBackupRepository
	
    <#
    $OU = "OU=MyServers,DC=mydomain,DC=com,DC=au"
    $Servers = Get-ADComputer -Filter {OperatingSystem -Like "Windows *Server*"} -SearchBase $OU | Select-Object –ExpandProperty Name

    $Servers = @("Server1","Server2","Server3")
    $Servers = Get-Content .\<path>\servers.txt
    $Servers = ($env:COMPUTERNAME)
    #>
    
#Miscellaneous 