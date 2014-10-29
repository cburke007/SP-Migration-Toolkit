Add-PSSnapin microsoft.sharepoint.powershell -EA 0

$curloc = Get-Location
$xmlFile = "Farm-130c2020-99a9-4803-afe6-d5680a3ab323_audit.xml"

[xml]$auditXML = Get-Content "$curloc\$xmlFile"

$solutions = $auditXML.SelectNodes("/Customer/Farm/FarmSolutions/Solution")

foreach($solution in $solutions)
{
    $solutionName = $solution.Name
    Add-SPSolution "$curloc\Exported Solutions\$solutionName"
}

