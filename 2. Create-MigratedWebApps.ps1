Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

Start-Transcript

$appPoolSegment = "0"

while($appPoolSegment -ne "1" -and $appPoolSegment -ne "2")
{ 
    Write-Host -ForegroundColor Cyan "Choose how you want to segment the Web Application App Pools"
    Write-Host -ForegroundColor Cyan "1. Single App Pool for all Web Apps (named SharePoint Sites)"
    Write-Host -ForegroundColor Cyan "2. Segment sites based on XML"
    $appPoolSegment = Read-Host "Choose one of the above selections "
}


$curloc = Get-Location
$xmlFile = "Farm-130c2020-99a9-4803-afe6-d5680a3ab323_audit.xml"

[xml]$auditXML = Get-Content "$curloc\$xmlFile"

$webApps = $auditXML.SelectNodes("/Customer/Farm/WebApplications/WebApplication")

foreach($webApp in $webApps)
{
    $webAppName = $webApp.Name
    
    $webAppUrlReplace = $webApp.Url.Replace("http://","")
    $webAppUrlWithPort = $webAppUrlReplace.Replace("/","")
    $webAppUrlArray = $webAppUrlWithPort.Split(":")
    $webAppUrl = $webAppUrlArray[0]

    $aamNode = $webApp.AlternateDomains.AlternateDomain | ? {$_.UrlZone -eq "Default"}
    $webAppPort = $aamNode.IISSettings.ServerBindings.Port

    $webAppAppPoolName = $webApp.AppPoolName
    $webAppAppPoolUser = Get-SPManagedAccount | ? {$_.UserName -like "*sp_site_ap*"}

    $webAppDBName = "DELETE_ME_" + $webAppName + "_TEMP"
    $ap = New-SPAuthenticationProvider
    
    if($appPoolSegment -eq "1")
    {
        $appPoolName = "SharePoint Sites"
    }
    else{$appPoolName = $webAppAppPoolName}

    if(!(Get-SPWebApplication $webAppName))
    {
        if(!(Get-SPWebApplication | ? {$_.ApplicationPool.Name -eq "$appPoolName"}))
        {
            New-SPWebApplication -ApplicationPool $appPoolName -ApplicationPoolAccount $webAppAppPoolUser -Name $webAppName -HostHeader $webAppUrl -Port $webAppPort -DatabaseName $webAppDBName -AuthenticationMethod NTLM -AuthenticationProvider $ap
        }
        else{New-SPWebApplication -ApplicationPool $appPoolName -Name $webAppName -HostHeader $webAppUrl -Port $webAppPort -DatabaseName $webAppDBName -AuthenticationMethod NTLM -AuthenticationProvider $ap}

        Write-Host -ForegroundColor Green "Finished creating Web App. Cleaning up temp content database..."
        Get-SPContentDatabase | ? {$_.Name -eq $webAppDBName} | Remove-SPContentDatabase -confirm:$false -force
        
    }
    else{Write-Host -ForegroundColor Red "Web App already exists! Skipping..."}

   
}










Stop-Transcript