#Requires -Version 5.1
<#	
	.NOTES
	===========================================================================
	 Created on:   	30-July-2018
	 Created by:   	Tito D. Castillote Jr.
					june.castillote@gmail.com
	 Filename:     	Get-MXReport.ps1
	 Version:		1.0 (30-July-2018)
	===========================================================================

	.LINK
		https://www.lazyexchangeadmin.com/2018/08/GetMXReport.html

	.SYNOPSIS
		Use Get-MXReport.ps1 to query and report the availability of the
		MX records for your listed domains

	.DESCRIPTION
		This will query the Public MX record of your domains, create HTML report which cand
		also be sent as email.
		
	.EXAMPLE
		.\Get-MXReport.ps1

#>

$scriptVersion = "1.0"
$now = (Get-Date -Format g) + " " + (Get-TimeZone).ToString().Split(" ")[0]
$script_root = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition


#set the error flag to false as default
$errorFlag = $false

#...................................
# Output Files
#...................................
$outputHTMLFile = $script_root +"\Reports\MX_Report_$((get-date).tostring("yyyy_MM_dd")).html"
$outputCsvFile = $script_root +"\Reports\MX_Report_$((get-date).tostring("yyyy_MM_dd")).csv"

#...................................
# Email Settings
#...................................
$sendEmail = $true
$sendCsvAttachment = $true
$senderAddress = "MX Report <mailer@lazyexchangeadmin.com>"
$recipients = "june.castillote@lazyexchangeadmin.com","admin1@lazyexchangeadmin.com"
$subject = "MX Record Report - $now"
$smtpServer = "smtp.lazyexchangeadmin.com"
$smtpPort = "25"
#...................................

#...................................
# DNS Setting
#...................................
$dnsServer = "8.8.8.8"

#...................................
# Office 365 Credentials - ONLY IF YOU USE Exchange Online as SMTP Relay
#...................................
#NOTE - replace the $userName and $userPassword
#$userName = ""
#$userPassword = ""
#$secpasswd = ConvertTo-SecureString $userPassword -AsPlainText -Force
#$onlineCredential = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
#...................................

#...................................
# Domains
# Import list from "domains.txt"
#...................................
$domains = Get-Content "$($script_root)\domains.txt"
#...................................


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
	Write-Host "Processing $($domain)... " -NoNewLine
	$x = "" | Select-Object Name,NameExchange,Preference
	$records = resolve-dnsname -Type MX -Server $dnsServer -Name $domain -ErrorAction SilentlyContinue | Where-Object {$_.QueryType -eq "MX"}
	
	#if there are records found
	if ($records.count -gt 0) {
		foreach ($record in $records) {
			$x.Name = $domain
			$x.NameExchange = $record.NameExchange
			$x.Preference = $record.Preference
			$finalResult += $x
		}
		Write-Host "OK" -ForegroundColor Green
	}
	#if there are no records found or if an error is encountered
	else {
		#trip the error flag to $true
		$errorFlag = $true
		$x.Name = $domain
		$x.NameExchange = "Error"
		$x.Preference = "Error"
		$finalResult += $x
		Write-Host "NOT OK" -ForegroundColor Red
	}
}

$finalResult | Export-Csv -NoTypeInformation $outputCsvFile

#create the HTML report
#html title
$mailBody = "<html><head><title>$($subject)</title><meta http-equiv=""Content-Type"" content=""text/html; charset=ISO-8859-1"" />"
$mailBody += $css_string
		
#heading
$mailBody += '<table id="HeadingInfo">'
$mailBody += "<tr><th>$($subject)</th></tr>"
$mailBody += "</table>"
$mailBody += '<table id="data">'

foreach ($result in $finalResult){
	if ($currentDomain -ne $result.Name)
	{
		$mailBody += "<tr><th>$($result.Name)</th><th>MX</th><th>Preference</th><th>Status</th></tr>"
		$currentDomain = $result.Name
		#$mailBody += "<tr><td>$($result.Name)</td>"
		$mailBody += "<tr><td></td>"
		
		if ($result.NameExchange -eq "Error")
		{
			$mailBody += "<td class = ""bad"">Error</td>"
			$mailBody += "<td></td>"
			$mailBody += "<td class = ""bad"">Error resolving MX, click here to <a href=https://intodns.com/$($result.Name) target=""_blank"">Analyze</a></td></tr>"
		}
		else
		{
			$mailBody += "<td>$($result.NameExchange)</td>"
			$mailBody += "<td>$($result.Preference)</td>"
			$mailBody += "<td class = ""good"">OK</td></tr>"
		}
	}
	elseif ($currentDomain -eq $result.Name)
	{
		$mailBody += "<tr><td></td>"
		if ($result.NameExchange -eq "Error")
		{
			$mailBody += "<td class = ""bad"">Error</td>"
			$mailBody += "<td></td>"
			$mailBody += "<td class = ""bad"">Error resolving MX, click here to <a href=https://intodns.com/$($result.Name) target=""_blank"">Analyze</a></td></tr>"
		}
		else
		{
			$mailBody += "<td>$($result.NameExchange)</td>"
			$mailBody += "<td>$($result.Preference)</td>"
			$mailBody += "<td class = ""good"">OK</td></tr>"
		}
	}
}
$mailBody += '</table>'
$mailBody += '<p><table id="SectionLabels">'
$mailBody += '<tr><th>----END of REPORT----</th></tr></table></p>'
$mailBody += '<p><font size="2" face="Tahoma"><u>Report Settings</u><br /><br />'
$mailBody += '<b>[EMAIL SETTINGS]</b><br />'
$mailBody += 'Sender: ' +  $senderAddress + '<br />'
$mailBody += 'Recipient: ' +  $recipients + '<br />'
$mailBody += 'SMTP Server: ' +  $smtpServer + '<br />'
$mailBody += 'Attach CSV: ' +  $sendCsvAttachment + '<br /><br />'
$mailBody += '<b>[DNS SETTINGS]</b><br />'
$mailBody += 'DNS Server: ' +  $dnsServer + '<br /><br />'
$mailBody += '<b>[CONFIGURATION]</b><br />'
$mailBody += 'Generated from Server: ' + (Get-Content env:computername) + '<br />'
$mailBody += 'Script File: ' + $MyInvocation.MyCommand.Definition + '<br />'
$mailBody += 'Report File: ' + $outputCsvFile + '<br /><br />'
$mailBody += '</p><p>'
$mailBody += "<a href=""https://www.lazyexchangeadmin.com/2018/08/GetMXReport.html"">Get-MXReport v.$($scriptVersion)</a></p>"
$mailBody += '</html>'
$mailBody | Out-File $outputHTMLFile

Write-host "HTML Report save to $($outputHTMLFile)"
Write-host "Csv Report save to $($outputCsvFile)"

if ($sendEmail -eq $true)
	{
		Write-Host "Sending email report"
		[string]$mailBody = Get-Content $outputHTMLFile
		if ($errorFlag -eq $true)
		{
			$subject = "ALERT!!! $($subject)"
		}
		#Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -To $recipients -From $senderAddress -Subject $subject -Body $mailBody -BodyAsHTML -Credential $onlineCredential -UseSSL
				
		if ($sendCsvAttachment -eq $true)
		{
			Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -To $recipients -From $senderAddress -Subject $subject -Body $mailBody -BodyAsHTML -Attachments $outputCsvFile
		}
		else
		{
			Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -To $recipients -From $senderAddress -Subject $subject -Body $mailBody -BodyAsHTML
		}	
	}
