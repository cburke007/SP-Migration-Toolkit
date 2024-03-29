param([string]$dbLoc = (Read-Host "Enter the location for the MDF Files "), [string]$logLoc = (Read-Host "Enter the location for the Log Files "))

[string]$curloc = get-location

$text = "$curloc\SQLRestoreCMDs.txt"

function Remove-TextAfter 
{   
    param (
        [Parameter(Mandatory=$true)]
        $string, 
        [Parameter(Mandatory=$true)]
        $value,
        [Switch]$Insensitive
    )

    $comparison = [System.StringComparison]"Ordinal"
    if($Insensitive) {
        $comparison = [System.StringComparison]"OrdinalIgnoreCase"
    }

    $position = $string.IndexOf($value, $comparison)

    if($position -ge 0) {
        $string.Substring(0, $position + $value.Length)
    }
}

# Get collection of SQL Backups
$sqlBackups = (Get-ChildItem "$curloc" -Name -Include *.bak -ErrorAction SilentlyContinue)

ForEach ($sqlBackup in $sqlBackups)
{
    
    $string = Remove-TextAfter "$sqlBackup" "_backup" -Insensitive
    $dbname = [system.IO.Path]::GetFileNameWIthoutExtension($sqlbackup)
    $dbLog = $dbName + "_log"
    
	"RESTORE DATABASE [$dbName] FROM  DISK = N'$curloc\$sqlBackup' WITH  FILE = 1,  MOVE N'$dbName' TO N'$dbLoc\$dbName.mdf',  MOVE N'$dbLog' TO N'$logLoc\$dbLog.LDF',  NOUNLOAD,  STATS = 10" | out-file "$text" -append
    "GO" | out-file "$text" -append
    "" | out-file "$text" -append
    
}