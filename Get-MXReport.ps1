#Requires -Version 5.1
<#PSScriptInfo

.VERSION 1.4.1

.GUID e9aab4f9-ec6e-4594-a3b9-465d0af991eb

.AUTHOR June Castillote

.COMPANYNAME www.lazyexchanegadmin.com

.COPYRIGHT june.castillote@gmail.com

.TAGS MX DNS Report PowerShell Script Query

.LICENSEURI

.PROJECTURI https://github.com/junecastillote/Get-MXReport

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#> 





<# 

.DESCRIPTION 
Query MX record and create reports which can also be sent by email

#> 


param (
	[cmdletbinding()]

	# list of domains to query, accepts array.
	[Parameter(Mandatory=$true)]
	[string[]]
	$domains,

	#path to the output/Report directory (eg. c:\scripts\output)
	[Parameter(Mandatory=$true)]
	[string]
	$outputDirectory,

	# Parameter help description
	[Parameter()]
	[string]
	$nameServer,	

	#path to the log directory (eg. c:\scripts\logs)
	[Parameter()]
	[string]
	$logDirectory,

	#prefix string for the report (ex. COMPANY)
	[Parameter()]
	[string]
	$headerPrefix,
	
	#Switch to enable email report
	[Parameter()]
    [ValidateSet("ErrorOnly","Always")]
    [string]
	$sendEmail,

	#Sender Email Address
	[Parameter()]
	[string]
	$sender,

	#Recipient Email Addresses - separate with comma
	[Parameter()]
	[string[]]
	$recipients,

	#smtpServer
	[Parameter()]
	[string]
	$smtpServer,

	#smtpPort
	[Parameter()]
	[string]
	$smtpPort,

	#switch to indicate whether SMTP server requires authentication
	[Parameter()]
	[switch]
	$smtpServerRequiresAuthentication,

	#credential for SMTP server (if applicable)
	[Parameter()]
	[pscredential]
	$smtpCredential,

	#switch to indicate if SSL will be used for SMTP relay
	[Parameter()]
	[switch]
    $smtpSSL,
    
    # switch to attach CSV file
    [Parameter()]
    [switch]
    $attachCSVReport
)

#...................................
# Start FUNCTIONS
#...................................
Function Stop-TxnLogging
{
	$txnLog=""
	Do {
		try {
			Stop-Transcript | Out-Null
		} 
		catch [System.InvalidOperationException]{
			$txnLog="stopped"
		}
    } While ($txnLog -ne "stopped")
}

#Function to Start Transaction Logging
Function Start-TxnLogging 
{
    param 
    (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$logDirectory
    )
	Stop-TxnLogging
    Start-Transcript $logDirectory -Append
}
#...................................
# End FUNCTIONS
#...................................

Stop-TxnLogging
Clear-Host
$scriptInfo = Test-ScriptFileInfo -Path $MyInvocation.MyCommand.Definition

#...................................
# Start PARAMETER CHECK
#...................................
$isAllGood = $true

if ($sendEmail)
{
    if (!$sender)
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: A valid sender email address is not specified." -ForegroundColor Yellow
        $isAllGood = $false
    }

    if (!$recipients)
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: No recipients specified." -ForegroundColor Yellow
        $isAllGood = $false
    }

    if (!$smtpServer )
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: No SMTP Server specified." -ForegroundColor Yellow
        $isAllGood = $false
    }

    if (!$smtpPort )
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: No SMTP Port specified." -ForegroundColor Yellow
        $isAllGood = $false
	}
	
	if ($smtpServerRequiresAuthentication)
	{
		if (!$smtpCredential)
		{
			Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: SMTP Server requires authentication, but no credential was specified. Please specify using the -smtpCredential parameter." -ForegroundColor Yellow
        	$isAllGood = $false
		}
	}
}

if ($isAllGood -eq $false)
{
    Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": ERROR: Exiting Script." -ForegroundColor Yellow
    EXIT
}
#...................................
# End PARAMETER CHECK
#...................................

#...................................
# Start PATHS
#...................................
#$today = Get-Date
#[string]$fileSuffix = '{0:dd-MMM-yyyy_hh-mm_tt}' -f $today
$logFile = $logDirectory +"\Log_$((get-date).tostring("yyyy_MM_dd")).log"
$outputCSVFile = $outputDirectory +"\MX_Report_$((get-date).tostring("yyyy_MM_dd")).csv"
$outputHTMLFile = $outputDirectory +"\MX_Report_$((get-date).tostring("yyyy_MM_dd")).html"

#Create folders if not found
if ($logDirectory)
{
    if (!(Test-Path $logDirectory)) 
    {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
        #start transcribing----------------------------------------------------------------------------------
        Start-TxnLogging $logFile
        #----------------------------------------------------------------------------------------------------
    }
	else
	{
		Start-TxnLogging $logFile
	}
}

if (!(Test-Path $outputDirectory))
{
	New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
#...................................
# End PATHS
#...................................

#...................................
# start SCRIPT
#...................................

$now = (Get-Date -Format ("MMM-dd-yyyy hh:mm tt")) + " " + (Get-TimeZone).ToString().Split(" ")[0]

#set the error flag to false as default
$errorFlag = $false

$css_string = @'
<style type="text/css">
#HeadingInfo 
	{
		font-family:"Segoe UI";
		width:100%;
		border-collapse:collapse;
	} 
#HeadingInfo td, #HeadingInfo th 
	{
		font-size:0.8em;
		padding:3px 7px 2px 7px;
	} 
#HeadingInfo th  
	{ 
		font-size:2.0em;
		font-weight:normal;
		text-align:left;
		padding-top:5px;
		padding-bottom:4px;
		background-color:#604767;
		color:#fff;
	} 
#SectionLabels
	{ 
		font-family:"Segoe UI";
		width:100%;
		border-collapse:collapse;
	}
#SectionLabels th.data
	{
		font-size:2.0em;
		text-align:left;
		padding-top:5px;
		padding-bottom:4px;
		background-color:#fff;
		color:#000; 
	} 
#data 
	{
		font-family:"Segoe UI";
		width:100%;
		border-collapse:collapse;
	} 
#data td, #data th
	{ 
		font-size:0.8em;
		border:1px solid #DDD;
		padding:3px 7px 2px 7px; 
	} 
#data th  
	{
		font-size:0.8em;
		padding-top:5px;
		padding-bottom:4px;
		background-color:#00B388;
		color:#fff; text-align:left;
	} 
#data td 
	{ 	font-size:0.8em;
		padding-top:5px;
		padding-bottom:4px;
		text-align:left;
	} 
#data td.bad
	{ 	font-size:0.8em;
		font-weight: bold;
		padding-top:5px;
		padding-bottom:4px;
		color:#f04953;
	} 
#data td.good
	{ 	font-size:0.8em;
		font-weight: bold;
		padding-top:5px;
		padding-bottom:4px;
		color:#01a982;
	}

.status {
	width: 10px;
	height: 10px;
	margin-right: 7px;
	margin-bottom: 0px;
	background-color: #CCC;
	background-position: center;
	opacity: 0.8;
	display: inline-block;
}
.green {
	background: #01a982;
}
.purple {
	background: #604767;
}
.orange {
	background: #ffd144;
}
.red {
	background: #f04953;
}
</style>
</head> 
<body> 
'@

$finalResult = @()
foreach ($domain in $domains) {
	$queryParams = @{
		name = $domain
		type = "MX"
	}
	if ($nameServer) {$queryParams += @{Server = $nameServer}}
    
    
    try 
    {
        $mxRecords = resolve-dnsname @queryParams -ErrorAction Stop | Where-Object {$_.QueryType -eq "MX"} | Sort-Object -Property Preference
        #$mxRecords = $allRecords | Where-Object {$_.QueryType -eq "MX"} | Sort-Object -Property Preference
        if ($mxRecords) {
            foreach ($mxRecord in $mxRecords) {
            
                $x = "" | Select-Object Name,NameExchange,Preference,IPAddresses,Status,Error
                $x.Name = $domain
                $x.NameExchange = $mxRecord.NameExchange
                $x.Preference = $mxRecord.Preference
                $queryParams = @{
                    name = $mxRecord.NameExchange
                }
                if ($nameServer) {$queryParams += @{Server = $nameServer}}
    
                $x.IPAddresses = ((resolve-dnsname @queryParams -ErrorAction SilentlyContinue).IPAddress | Where-Object {$_ -notmatch ":"}) -join ";"
                $x.Status = "Passed"
                #$x.Error = ""
                $finalResult += $x
            }
            Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": $($domain): OK" -ForegroundColor Green
        }
    }
    Catch 
    {
        $errorFlag = $true
        $x = "" | Select-Object Name,NameExchange,Preference,IPAddresses,Status,Error
        $x.Name = $domain
        $x.NameExchange = "Error"
        $x.Preference = "Error"
        $x.IPAddresses = "Error"
        $x.Status = "Failed"
        $x.Error = $_.Exception.Message
        $finalResult += $x
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": $($domain): NOT OK" -ForegroundColor Red
    }

    
}
$finalResult | Export-Csv -NoTypeInformation $outputCsvFile

#create the HTML report
#html title
if ($headerPrefix)
{
    $subject = "[$($headerPrefix)] MX Record Validity Report"
    #$mailBody = "<html><head><title>$($subject)</title><meta http-equiv=""Content-Type"" content=""text/html; charset=ISO-8859-1"" />"
}
else {
    $subject = "MX Record Validity Report"
}

$mailBody = "<html><head><title>$($subject) - $($now)</title><meta http-equiv=""Content-Type"" content=""text/html; charset=ISO-8859-1"" />"
$mailBody += $css_string
		
#heading
$mailBody += "<hr>"	
$mailBody += '<table id="HeadingInfo">'
$mailBody += "<tr><th>$($subject)<br />$($now)</th></tr>"
$mailBody += "</table>"
$mailBody += "<hr>"	


$failedResults = $finalResult | Where-Object {$_.Status -eq "Failed"}
$passedResults = $finalResult | Where-Object {$_.Status -eq "Passed"} | Group-Object Name

if ($failedResults)
{
    $mailBody += '<table id="SectionLabels"><tr><th class="data">Failed MX Lookup</th></tr></table>'
    $mailBody += '<table id="data">'
    $mailBody += "<tr><th>Domain</th><th>Error</th></tr>"
    foreach ($result in $failedResults)
    {
        $mailBody += "<tr><td>$($result.Name)</td><td class = ""bad"">$($result.error) <a href=https://intodns.com/$($result.Name) target=""_blank""> > Analyze</a></td></tr>"
    }
    $mailBody += '</table>'
}

if ($passedResults)
{
    $mailBody += '<table id="SectionLabels"><tr><th class="data">Successful MX Lookup</th></tr></table>'
    
    $mailBody += '<table id="data">'
    $mailBody += "<tr><th>Domain</th><th>Mail Exchange | Preference</th></tr>"
    foreach ($result in $passedResults)
    {
        $mx = @()
        foreach ($item in $result.Group)
        {
            $mx += "$($item.NameExchange) | $($item.Preference)"
        }
        $mailBody += "<tr><td>$($result.Name)</td><td>" + ($mx -join "<br />")+ "</td></tr>"
    }
    $mailBody += '</table>'
}
$mailBody += "<hr>"
$mailBody += '<p><table id="SectionLabels">'
$mailBody += '<tr><th>----END of REPORT----</th></tr></table></p>'
$mailBody += '<p><font size="2" face="Tahoma"><u>Report Settings</u><br /><br />'

if ($sendEmail)
{
    $mailBody += '<b>[EMAIL SETTINGS]</b><br />'
    $mailBody += 'Email Report: ' +  $sendEmail + '<br />'
    $mailBody += 'Sender: ' +  $sender + '<br />'
    $mailBody += 'Recipients: ' +  ($recipients -join ";") + '<br />'
    $mailBody += 'SMTP Server: ' +  $smtpServer + '<br />'
    $mailBody += 'SMTP Port: ' +  $smtpPort + '<br />'
    $mailBody += 'SMTP SSL: ' +  $smtpSSL + '<br />'
    $mailBody += 'SMTP Authentication: ' +  $smtpServerRequiresAuthentication + '<br />'
    $mailBody += 'Attach CSV: ' +  $attachCSVReport + '<br /><br />'
}

if ($nameServer)
{
    $mailBody += '<b>[DNS SETTINGS]</b><br />'
    $mailBody += 'DNS Server: ' +  $nameServer + '<br /><br />'
}

$mailBody += '<b>[CONFIGURATION]</b><br />'
$mailBody += 'Generated from Server: ' + (Get-Content env:computername) + '<br />'
$mailBody += 'Script File: ' + $MyInvocation.MyCommand.Definition + '<br />'
if ($logDirectory)
{
    $mailBody += 'Log File: ' + $logFile + '<br />'
}
$mailBody += 'CSV Report File: ' + $outputCsvFile + '<br />'
$mailBody += 'HTML Report File: ' + $outputHTMLFile + '<br /><br />'


$mailBody += '</p><p>'
$mailBody += "<a href=""$($scriptInfo.ProjectURI)"">$($MyInvocation.MyCommand.Definition.ToString().Split("\")[-1].Split(".")[0]) $($scriptInfo.version)</a></p>"
$mailBody += '</body></html>'
$mailBody | Out-File $outputHTMLFile

Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": HTML Report save to $($outputHTMLFile)" -ForegroundColor Yellow 
Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": Csv Report save to $($outputCsvFile)" -ForegroundColor Yellow 

#...................................
# Start MAIL
#...................................
if ($sendEmail)
{    
    [string]$mailBody = Get-Content $outputHTMLFile
    $mailParams = @{
        From = $sender
        To = $recipients
        smtpServer = $smtpServer
        Port = $smtpPort
        useSSL = $smtpSSL
        body = $mailBody
        bodyashtml = $true
    }

    if ($errorFlag -eq $true)
	{
        $subject = "ALERT!!! $($subject)"
        $mailParams += @{priority = "HIGH"}        
    }
    else {
        $subject = $subject
        $mailParams += @{priority = "LOW"}
    }

    $mailParams += @{subject = $subject}

    if ($smtpServerRequiresAuthentication)
    {
        $mailParams += @{credential = $smtpCredential}
    }

    if ($attachCSVReport)
    {
        $mailParams += @{Attachments = $outputCSVFile}
    }

    #Always
    if ($sendEmail -eq 'Always')
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": Sending email to" ($recipients -join ", ") -ForegroundColor Yellow
        Send-MailMessage @mailParams
    }

    #ErrorOnly AND errorFlag=$true
    if ($sendEmail -eq 'ErrorOnly' -and $errorFlag -eq $true)
    {
        Write-Host (get-date -Format "dd-MMM-yyyy hh:mm:ss tt") ": Sending email to" ($recipients -join ", ") -ForegroundColor Yellow
        Send-MailMessage @mailParams
    }
}
#...................................
# Start MAIL
#...................................

Stop-TxnLogging
