[void] [System.reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | out-null

#---------------------------------------Functions----------------------------------------------------------------

function New-Zip 
{
	param([string]$zipfilename)
	set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
	(dir $zipfilename).IsReadOnly = $false
}

function Add-Zip
{
	param([string]$zipfilename)

	if(-not (test-path($zipfilename)))
	{
		set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
		(dir $zipfilename).IsReadOnly = $false	
	}
	
	$shellApplication = new-object -com shell.application
	$zipPackage = $shellApplication.NameSpace($zipfilename)
	
	foreach($file in $input) 
	{ 
            # Copy the selected file into the Zip File
            $zipPackage.CopyHere($file.FullName)
            
            # give up to 2 minutes for the file copy to complete
            $maxLoops = 2*60*10
            
            # Check to see if the file has shown up in the zip file yet    
            while ($zipPackage.Items().Item($file.name) -eq $null) 
            {
                
                if (--$maxLoops -le 0) {Throw "timeout exceeded for $file.Name"}
                Start-sleep -milliseconds 100
            }
            
            rm $file
	}
}


#-----------------------------------------Main Loop-----------------------------
# Get the Current Directory that the script is operating from
[string]$curloc = get-location

# Create an Instance of the Local Farm Object
$spFarm = [Microsoft.SharePoint.Administration.SPfarm]::Local

# Query Farm Solutions
$farmSolutions = $spFarm.Solutions

# Loop through each Solution and extract it to disk
foreach ($solution in $farmSolutions)
{  

    # Make a folder to store exported solution packages
    if (-not (Test-Path "$curloc\Exported Solution Packages"))
    {
        md "$curloc\Exported Solution Packages"
    }
        
    # Extract all solutions from SharePoint and save them to disk
    [string]$solutionOutputPath = "$curloc\Exported Solution Packages\" + $solution.Name
    $solution.SolutionFile.SaveAs($solutionOutputPath)
}


# If the Exported Solutions folder exists
if (Test-Path "$curloc\Exported Solution Packages")
{
    # Test if an Exported Solutions zip file already exists and delete it and recreate it empty
    if (Test-Path "$curloc\Exported Solutions.zip")
    {
        rm "$curloc\Exported Solutions.zip" | out-null
        New-Zip "$curloc\Exported Solutions.zip"
    }
    else
    {
        New-Zip "$curloc\Exported Solutions.zip"
    }
    
    # Put any files into a zip file and delete them
    dir "$curloc\Exported Solution Packages\*.*" -Recurse | Add-Zip "$curloc\Exported Solutions.zip"

    if ((dir "$curloc\Exported Solution Packages\*.*" -Recurse) -eq $null)
    {
        rmdir "$curloc\Exported Solution Packages\" -Recurse
    }       
}
