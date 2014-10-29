Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

Start-Transcript

$curloc = Get-Location
$xmlFile = "Farm-130c2020-99a9-4803-afe6-d5680a3ab323_audit.xml"

[xml]$auditXML = Get-Content "$curloc\$xmlFile"

$webApps = $auditXML.SelectNodes("/Customer/Farm/WebApplications/WebApplication")

foreach($webApp in $webApps)
{
    $wa = Get-SPWebApplication $webApp.Url

    $webAppName = $webApp.Name
    $webAppUrl = $webApp.Url

    $aamNodes = $webApp.AlternateDomains.AlternateDomain
    foreach($aamNode in $aamNodes)
    {
        $aamZone = $aamNode.UrlZone
        $aamIncUrl = $aamNode.IncomingUrl
        $aamMapUrl = $aamNode.MappedUrl
    
        if($aamZone -ne "Default")
        {
            if(!($aamNode.IISSettings))
            {
                New-SPAlternateURL -WebApplication $wa -Zone $aamZone -Url $aamIncUrl   
            }
            else
            {
                New-SPAlternateURL
            }
        }
    }

   
}
