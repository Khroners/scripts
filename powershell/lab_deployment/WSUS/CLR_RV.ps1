$TempDir = "C:\temp"

$URLRV = "https://download.microsoft.com/download/6/2/6/6263245B-E25C-4631-BFAA-07BA4099E67A/ReportViewer.msi"
$URLCLR = "http://go.microsoft.com/fwlink/?LinkID=239644&clcid=0x409"
Start-BitsTransfer -Source "$URLCLR" -Destination "$TempDir\SQLSysClrTypes.msi" -RetryInterval 60 -RetryTimeout 180 -ErrorVariable err

Start-BitsTransfer -Source "$URLRV" -Destination "$TempDir\ReportViewer.msi" -RetryInterval 60 -RetryTimeout 180 -ErrorVariable err

write-host "Installing Microsoft System CLR Types for Microsoft SQL Server 2012..."

msiexec /i $TempDir\SQLSysClrTypes.msi /qn
write-host "Installing Installing Microsoft Report Viewer 2012 Runtime..."

msiexec /i $TempDir\ReportViewer.msi /qn
