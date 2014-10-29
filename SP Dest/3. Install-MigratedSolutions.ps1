Add-PSSnapin microsoft.sharepoint.powershell -EA 0

function WaitForSPSolutionJobToComplete([string]$solutionName)
{
    $solution = Get-SPSolution -Identity $solutionName -ErrorAction SilentlyContinue
 
    if ($solution)
    {
        if ($solution.JobExists)
        {
            Write-Host -NoNewLine "Waiting for timer job to complete for solution '$solutionName'."
        }
         
        # Check if there is a timer job still associated with this solution and wait until it has finished
        while ($solution.JobExists)
        {
            $jobStatus = $solution.JobStatus
             
            # If the timer job succeeded then proceed
            if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Succeeded)
            {
                Write-Host "Solution '$solutionName' timer job suceeded"
                return $true
            }
             
            # If the timer job failed or was aborted then fail
            if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Aborted -or
                $jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Failed)
            {
                Write-Host "Solution '$solutionName' has timer job status '$jobStatus'."
                return $false
            }
             
            # Otherwise wait for the timer job to finish
            Write-Host -NoNewLine "."
            Sleep 1
        }
         
        # Write a new line to the end of the '.....'
        Write-Host
    }
     
    return $true
}

$curloc = Get-Location
$xmlFile = "Farm-130c2020-99a9-4803-afe6-d5680a3ab323_audit.xml"

[xml]$auditXML = Get-Content "$curloc\$xmlFile"

$solutions = $auditXML.SelectNodes("/Customer/Farm/FarmSolutions/Solution")

foreach($solution in $solutions)
{
    $solutionName = $solution.Name
    $installedSolution = Get-SPSolution $solutionName
    $solutionID = $installedSolution.SolutionID

    $cmd = "Install-SPSolution -Identity $solutionID "

    If($solution.ContainsGlobalAssembly -eq "True"){$cmd += "-GACDeployment "}
    If($solution.ContainsContainsCASPolicy -eq "True"){$cmd += "-CASPolicies "}

    if(!($solution.DeployedUrls.DeployedUrl))
    {
         Invoke-Expression $cmd
         WaitForSPSolutionJobToComplete $solutionName
    }
    else
    {
        foreach($url in $solution.DeployedUrls.DeployedUrl)
        {
            $wa = Get-SPWebApplication $url
            $waCMD = $cmd + "-WebApplication " + $wa.ID
            Invoke-Expression $waCMD
            WaitForSPSolutionJobToComplete $solutionName
        }
    }
}





