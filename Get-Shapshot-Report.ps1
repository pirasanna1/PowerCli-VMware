#Firstly, generate todays date and store in a variable
$date = (get-date -Format M/d/yyyy)
$FileDate = (Get-Date -Format yyyMMdd)

#Import the PowerCLI module and setup the credentials to connect to VI servers
Import-Module VMware.VimAutomation.Core
$VIServer = "VCENTERNAME"
$PasswordFile = Get-Content "‪C:\Scripts\Cred\Cred.txt" | ConvertTo-SecureString
$Credentials = New-Object System.Management.Automation.PSCredential ("DOMAIN\User", $PasswordFile)

#This is where the styling for the HTML report is done
$styles = @"
<style>
body {   font-family: 'Helvetica Neue', Helvetica, Arial;
         font-size: 14px;
         line-height: 20px;
         font-weight: 400;
         color: black;
    }
table{
  margin: 0 0 40px 0;
  width: 100%;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  display: table;
  border-collapse: collapse;
  border: 1px solid black;
  text-align: left;
}
th {
    font-weight: 900;
    color: #ffffff;
    background: black;
   }
td {
    border: 0px;
    border-bottom: 1px solid black
    }
.20 {
    width: 20%;
    }
.40 {
    width: 40%;
    }
</style>
"@

#Setup the header for the HTML report
$report = $report = "<!DOCTYPE html><html><head>$Styles<title>VMWare Snapshot Report</title></head><body>"

#Connect to Server
Connect-VIServer -Server $VIServer -Credential $Credentials
$report += "<h1>Snapshot Report for $VIServer $date</h1><table><th>VM Name</th><th>Snapshot Name</th><th>Description</th><th>Date Created</th><th>Created By</th>"
$Snap = Get-VM | Get-Snapshot | Select-Object Description, Created, VM, SizeMB, SizeGB, Name

foreach ($snap in Get-VM | Get-Snapshot)
    {
        $snapevent = Get-VIEvent -Entity $Snap.VM -Types Info -Finish $Snap.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'
    }
    if ($snapevent -ne $null)
    {
        $sVM = $Snap.VM
		$sSName = $Snap.Name
        $sDesc = $Snap.Description
        $sDate = $Snap.Created
        $sUser = $snapevent.UserName
        $report += "<tr><td>$sVM</td><td>$sSName</td><td>$sDesc</td><td>$sDate</td><td>$sUser</td></tr>"
     } else {

        $sVM = $Snap.VM
        $sSName = $Snap.Name
		$sDesc = $Snap.Description
        $sDate = $Snap.Created
        $sUser = "NoUserFound"
		$report += "<tr><td>$sVM</td><td>$sSName</td><td>$sDesc</td><td>$sDate</td><td>$sUser</td></tr>"
        }
 
    }
$report += "</table>"
Disconnect-VIServer -Server $VIServer -Confirm:$false

#Close out the report HTML code and export to file
$report += "</body></html>"
$report | Out-File "C:\Scripts\Snapshots\Snapshot-Report-$FileDate.html"

