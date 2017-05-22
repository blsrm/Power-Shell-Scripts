###Input server list
$Computers = Get-Content "F:\sakthi\Mcafee\servers1.txt"


Function GetStatusCode 
{  
    Param([int] $StatusCode)   
    switch($StatusCode) 
    { 
        0       {"Success"} 
        11001   {"Buffer Too Small"} 
        11002   {"Destination Net Unreachable"} 
        11003   {"Destination Host Unreachable"} 
        11004   {"Destination Protocol Unreachable"} 
        11005   {"Destination Port Unreachable"} 
        11006   {"No Resources"} 
        11007   {"Bad Option"} 
        11008   {"Hardware Error"} 
        11009   {"Packet Too Big"} 
        11010   {"Request Timed Out"} 
        11011   {"Bad Request"} 
        11012   {"Bad Route"} 
        11013   {"TimeToLive Expired Transit"} 
        11014   {"TimeToLive Expired Reassembly"} 
        11015   {"Parameter Problem"} 
        11016   {"Source Quench"} 
        11017   {"Option Too Big"} 
        11018   {"Bad Destination"} 
        11032   {"Negotiating IPSEC"} 
        11050   {"General Failure"} 
        default {"Failed"} 
    } 
} 


foreach ($computername in $Computers)
{
    $datdate =  ""
    $status = ""
    $OS = ""
    $uptime = ""

    $pingStatus = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$computername'"
    $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computername 
    $uptime = $OS.ConvertToDateTime($OS.lastbootuptime)

    if($pingStatus.StatusCode -eq 0) 
    { 
        $StatusNew = GetStatusCode( $pingStatus.StatusCode ) 
    } 
    else 
    { 
        $StatusNew = GetStatusCode( $pingStatus.StatusCode ) 
    }

    "$(Get-Date) $computername and $StatusNew"  | Format-table -wrap 

    If ($StatusNew -eq "Success")
    { 


        try {
            #Set up the key that needs to be accessed and what registry tree it is under
            $key = "Software\McAfee\AVEngine"
            $type = [Microsoft.Win32.RegistryHive]::LocalMachine

            #open up the registry on the remote machine and read out the TOE related registry values
            $regkey = [Microsoft.win32.registrykey]::OpenRemoteBaseKey($type,$computername)
            $regkey = $regkey.opensubkey($key)
            $status = $regkey.getvalue("AVDatVersion")
            $datdate = $regkey.getvalue("AVDatDate")
    
        } catch {
                try {
                    $key = "Software\Wow6432Node\McAfee\AVEngine"
                    $type = [Microsoft.Win32.RegistryHive]::LocalMachine
                    #Write-output "Before calling OpenRemoteBasekey"
                    #open up the registry on the remote machine and read out the TOE related registry values
                    $regkey = [Microsoft.Win32.registrykey]::OpenRemoteBaseKey($type,$computername)
                    #Write-output $regkey 
                    $regkey = $regkey.opensubkey($key)
                    $status = $regkey.getvalue("AVDatVersion")
                    $datdate = $regkey.getvalue("AVDatDate")
                } catch {
                    $status = "Cannot read regkey"
                }

        }
 

    }
    else
    {	
        $status = "$StatusNew"
    }

    ### CSV file output

    New-Object PSobject -Property @{
        Computername = $computername
        DATVersion = $status
        DatDate = $datdate
        OS = $OS
        UPTIME = $uptime
    } |select Computername,DatVersion,DatDate, OS, UPTIME |Export-Csv .\McafeeInstalled.csv -Append


}
