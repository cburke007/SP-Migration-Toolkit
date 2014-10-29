#requires -pssnapin Microsoft.SharePoint.Powershell 
 
Function Invoke-AlertFixup 
{ 
<#  
.Synopsis  
    Fixes alert links for the provided Site Collection 
.Description  
    Fixes alert links for the provided Site Collection 
         
    THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
         
.Parameter Site  
    The url of the site collection to fix.  Should be the actual URL of the site which has already had a URL change. Required Parameter. 
.Parameter OldUrl 
    The original URL of the site collection prior to the change. Required Parameter. 
.Example 
    Commit changes to update all alerts (in all subwebs) in the given SPSite.  This operation can not be undone! 
     
    PS >  Invoke-AlertFixup -site "http://teams/sites/newteam"  -Oldurl "http://teams/sites/oldteam" 
.Example          
    Preview all alerts that would be updated with the given command. 
         
    PS >  Invoke-AlertFixup -site "http://teams/sites/newteam"  -Oldurl "http://teams/sites/oldteam" -whatif 
                 
.ReturnValue  
    Microsoft.SharePoint.SPSiteSubscription     
.Notes  
        NAME:      Invoke-AlertFixup 
        AUTHOR:    Microsoft 
        LASTEDIT:  5/26/2010 
#>  
 
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')] 
Param( 
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)][ValidateNotNullOrEmpty()][Microsoft.SharePoint.PowerShell.SPSitePipeBind] $Site, 
    [Parameter(Mandatory=$true, ValueFromPipeline=$False)][ValidateNotNullOrEmpty()][string] $OldUrl 
    ) 
 
    try{ 
        Write-Host -ForegroundColor Yellow "Scanning Alerts for $($Site.SiteURL)" 
        Get-SPWeb -site ([string]$Site.SiteUrl)-limit all |Foreach{  #for each spweb 
            try{  
                Write-Host ("  = "+($_.Alerts.Count.ToString())+" alerts for subweb "+($_.Title)+","+($_.URL))         
                
                #counters 
                $FixCount = 0; 
                $SkipCount = 0; 
                 
                #Fix URL for usage (remove trailing /) 
                $NewUrl = $Site.SiteUrl 
                if($NewUrl[($NewUrl.Length-1)] -eq '/'){ $NewUrl = $NewUrl.Substring(0, $NewUrl.Length-1) } 
                if($OldUrl[($OldUrl.Length-1)] -eq '/'){ $OldUrl = $OldUrl.Substring(0, $OldUrl.Length-1) } 
                 
                $_.Alerts |Foreach{  #for each alert 
                    try{ 
                        #Make sure we only fix for this zone 
                        if($_.Properties["siteUrl"]-eq $null){ $_.Properties["siteUrl"] = $OldUrl } 
                        if($_.Properties["siteUrl"].ToLower() -eq $OldUrl.tolower()){ 
                             
                            #Fix URL 
                            $_.Properties["siteUrl"] = $NewUrl 
                             
                            #if in use, fix the Mobile URL 
                            if( $_.Properties["MobileUrl"] -ne "" -and $_.Properties["MobileUrl"] -ne $null){ 
                              if( (([string]$_.Properties["MobileUrl"]).ToLower()).Contains($OldUrl.ToLower()) ){ 
                                   $_.Properties["MobileUrl"] = (([string]$_.Properties["MobileUrl"]).ToLower()).Replace($OldUrl.ToLower(),$NewUrl) 
                                } 
                            } 
                         
                            #preserve the frequency: 
                            $Frequency = $_.AlertFrequency; 
                            $Status = $_.Status 
                            if($Frequency -eq [Microsoft.SharePoint.SPAlertFrequency]::Immediate){ 
                            $_.AlertFrequency = [Microsoft.SharePoint.SPAlertFrequency]::Weekly 
                            } 
                            else{ 
                            $_.AlertFrequency = [Microsoft.SharePoint.SPAlertFrequency]::Immediate 
                            } 
                         
                            try{ 
                            if($pscmdlet.ShouldProcess($_.ID, "Fix Alert (List=$($_.ListUrl))")){ 
                                $_.Status = [Microsoft.SharePoint.SPAlertStatus]::Off 
                                $_.Update(); 
                                 
                                #Reset Values 
                                $_.AlertFrequency = $Frequency 
                                $_.Status = $Status 
                                $_.Update();                 
                                 
                                $FixCount++ 
                            } 
                            }catch{ 
                                Write-Error "Failure changing alert ($_) in SPWeb {$_.URL}" 
                            } 
                        }#End "Zone Check" 
                        else{ $SkipCount++ } 
                     
                    }catch{ 
                        Write-Error "Failure accessing the alert object ($_) in SPWeb {$_.URL}" 
                    } 
                } 
                 
                Write-Host -ForegroundColor Green "      Alerts Fixed: $FixCount" 
                if($SkipCount -gt 0){ Write-Host -ForegroundColor Yellow "      Alerts Skipped (Zone): $SkipCount" } 
            }catch{ 
              Write-Error "Failure reading alerts from SPWeb {$_.URL}" 
              throw 
            } 
        } 
    }catch{ 
        Write-Error $_        
        throw 
    } 
 
}