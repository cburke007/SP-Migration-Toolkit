Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

Start-Transcript

$curloc = Get-Location
$xmlFile = "Farm-130c2020-99a9-4803-afe6-d5680a3ab323_audit.xml"

[xml]$auditXML = Get-Content "$curloc\$xmlFile"

$webApps = $auditXML.SelectNodes("/Customer/Farm/WebApplications/WebApplication")

foreach($webApp in $webApps)
{
    $webAppName = $webApp.Name
    $webAppUrl = $webApp.Url

    $dbNodes = $webApp.Databases.Database
    foreach($dbNode in $dbNodes)
    {
        $dbName = $dbNode.Name
    
        if(!(Get-SPContentDatabase | ? {$_.Name -eq $dbName}))
        {
            Mount-SPContentDatabase $dbName -WebApplication $webAppUrl
            Write-Host -ForegroundColor Green "Finished attaching database..."
        
        }
        else{Write-Host -ForegroundColor Red "Database appears to be mounted already..."}
    }

   
}
