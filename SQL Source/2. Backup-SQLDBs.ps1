Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

Import-Module .\SQL.psm1

Start-Transcript

[string]$strcurloc = get-location 
$strDBs = Get-Content "$strcurloc\dbs.txt"
$strShare = read-Host "Where is the destination? (C:\backups for local backups for example) or (\\Server\Share) for UNC backups? "
$strComputerName = read-host "Enter the computer name (cluster name if it's a cluster) " 
$strSQLInstance = read-host "Enter the name of the SQL Instance (Default=Blank) "

$strdate = Get-Date -Format yyyyddMM
$strExtension = ".bak"
$strLoc = Set-Location SQLSERVER:\SQL\

$strSI = $strLoc + $strComputerName + "\" + $strSQLInstance

    foreach ($strdb in $strdbs)
   
       {
       $strQuery = "BACKUP DATABASE " + "[" + $strdb + "]" + "TO DISK=N'" + $strShare + "\" + $strdb + $strExtension + "'WITH COPY_ONLY, INIT, STATS = 10"
       Write-Host $strDB "..is backing up" -ForegroundColor Yellow; Invoke-Sqlcmd -SuppressProviderContextWarning -Query $strQuery -QueryTimeout 65535 -ServerInstance $strSI
       Write-Host $strDB "backup complete!" -ForegroundColor Green
       }

Stop-Transcript 

Write-Host "Session will close in 5 seconds ... "
Start-Sleep -s 5
#stop-process -Id $PID

