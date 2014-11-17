Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0
 
$environ = Read-Host "How would you describe this Farm (PROD, DEV, etc.) "

#Take command line arguments
#$custName == Customer Name
#$custNum == Customer Account Number
#Param($custName = "", $custNum = "")

#Region Global Variables
#Create global counting variables to keep track of SiteCollections and Users in Farm
$global:farmSiteCount=0
$global:userObj = @()
# Get the Current Directory that the script is operating from
$global:curloc = get-location
#EndRegion Global Variables

#Region Functions
function Bindings()
{
	return [System.Reflection.BindingFlags]::CreateInstance -bor
	[System.Reflection.BindingFlags]::GetField -bor
	[System.Reflection.BindingFlags]::Instance -bor
	[System.Reflection.BindingFlags]::NonPublic
}

function GetFieldValue([object]$o, [string]$fieldName)
{
	$bindings = Bindings
	return $o.GetType().GetField($fieldName, $bindings).GetValue($o);
}

function ConvertTo-UnsecureString([System.Security.SecureString]$string)
{
	$intptr = [System.IntPtr]::Zero
	$unmanagedString = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($string)
	$unsecureString = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($unmanagedString)
	[System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($unmanagedString)
	return $unsecureString
}
#EndRegion Functions

#Region Get Domain Data
#Get the current Active Directory Domain
$forestName = [System.DirectoryServices.ActiveDirectory.Domain]::getcomputerdomain()

#Extract the NetBios name of the domain from Net Config
if ($forestName)
{
	$nb = net config workstation | findstr /C:"Workstation domain"
	$domainName = $nb -replace "Workstation domain                   ",""
}
#If no domain exists, use the computer name. Should only happen with 2007 Farms
else
{
	$domainName = gc env:computername
}

#EndRegion Get Domain Data

# Region Build XML Template
# Build Base XML Template variable to be used throughout the rest of the script
[xml]$auditxml = '<?xml version="1.0" ?>
    <Configuration Environment="" Version="3.96" CustName="" CustNum="">
    </Configuration>
    '
# EndRegion Build XML Template

# Region Set Customer Data
#Set the Customer Name and Number taken from Script Arguments
if($custName -eq "" -or $custNum -eq ""){Write-Host "No Customer Data was entered"}
else
{
	$auditxml.Configuration.SetAttribute("Name",$custName)
	$auditxml.Configuration.SetAttribute("Number",$custNum)
}
# EndRegion Set Customer Data

# Create an Instance of the Local Farm Object
$spFarm = Get-SPFarm