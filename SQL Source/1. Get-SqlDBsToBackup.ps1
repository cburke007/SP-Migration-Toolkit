Add-PSSnapin SqlServerCmdletSnapin100 -EA 0
Add-PSSnapin SqlServerProviderSnapin100 -EA 0

[string]$curloc = get-location
$localServer = hostname
$instance = "sharepoint"

get-psprovider

$sqlDBs = dir sqlserver:\sql\$localServer\$instance\databases | foreach {$_.Name}

$sqlDBs | out-file -filepath "$curloc\DBs.txt"