#parseMsgDir works with resultsArray
function parseMsgDir {
    
    Param (
        [Parameter(mandatory = $true)]
        $resultsArray,
        [String]$sourceDir = 'Z:\scripts\phishing\',
        [String]$headerDir = 'Z:\scripts\phishing\headers\',
        [String]$bodyDir = 'Z:\scripts\phishing\body\',
        [String]$msgDir = 'Z:\scripts\phishing\msg\',
        [String]$otherDir = 'Z:\scripts\phishing\other\'
    )

    $outlook = New-Object -comobject outlook.application
    
    Get-ChildItem $sourceDir -Filter *.msg | 
    ForEach-Object {
        $r = createResultsObject
        $msg = $outlook.Session.OpenSharedItem($_.FullName)
        
        $uid = $msg.Attachments[1].FileName.substring(8) -replace ".{4}$"
        $r.uid = $uid

        $attachments = $msg.Attachments 
        
        foreach($a in $attachments) {
            
            if ($a.FileName -Match "body-") {
                $filePath = $bodyDir + $a.FileName
                $r.bodyPath = $filePath
                if (-Not(Test-Path -literalPath $filePath)) {$a.SaveAsFile($filePath)}
            } elseif ($a.FileName -Match "headers-") {
                $filePath = $headerDir + $a.FileName
                if (-Not(Test-Path -literalPath $filePath)) {$a.SaveAsFile($filePath)}
                $r.headerPath = $filePath
            } elseif ($a.FileName -Match ".msg") {
                $filePath = $msgDir + $a.FileName
                if (-Not(Test-Path -literalPath $filePath)) {$a.SaveAsFile($filePath)}
                $r.msgPath = $filePath
            } else {
                $filePath = $otherDir + $a.FileName
                if (-Not(Test-Path -literalPath $filePath)) {$a.SaveAsFile($filePath)}
                $r.otherPath = $filePath
            }   
        }
        $resultsArray += $r
    }
    #$outlook.Quit()

    return $resultsArray
}

function getLinksDir {
    
    Param (
        [String]$sourceDir = 'Z:\scripts\phishing\body\'
    )
    $links = @()
     
    Get-ChildItem $sourceDir -Filter *.txt | 
    ForEach-Object {
        $text = Get-Content $_.FullName | Out-String
        $text -match '(?:http|s?ftp)s?://[^\s,<>"]+'   
        $links += $Matches.Values
    }

    return $links
}

function submitUrlScan {
    
    Param (
        [Parameter(mandatory = $true)]
        $links,
        $urlToken = 'c5422430-7055-4d4f-b3ef-a5e117cb3595'
    )
    
    #$link = $links[0]

    $uri = "https://urlscan.io/api/v1/scan/"
    $results = @()
     
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    foreach ($url in $links){
        write-host "Submitting $url"
        #$Invoke = Invoke-WebRequest -Headers @{"API-Key" = "$apikey"} -Method Post -Body "{`"url`":`"$url`"}" -Uri 'https://urlscan.io/api/v1/scan/' -ContentType application/json
        #$Invoke
        $restMethod = Invoke-RestMethod -Method 'Post' -Uri $uri -Headers @{"API-Key" = "$urlToken"} -Body "{`"url`":`"$url`"}" -ContentType application/json
        $results += $restMethod.api
        start-sleep 2
    }
    return $results
   
}
 
function submitVirusScan {
    
    Param (
        [Parameter(mandatory = $true)]
        $links,
        $virusToken = '6fe093c8a778a29692b9aa624b6723e13e7d8aaeb48e7953e44e16552a99affa'
    )

    $uri = 'https://www.virustotal.com/vtapi/v2/url/scan'
    $results = @()
    foreach ($url in $links){
        write-host "Submitting $url"
        $body = @{url = $url;apikey=$virusToken}
        #$body
        #$uri
        $restMethod = Invoke-RestMethod -Method 'Post' -Uri $uri -Body $body
        #$restMethod
        $results += $restMethod.scan_id
        start-sleep 15    
    }
    return $results
}

function getUrlScan {
    Param (
        [Parameter(mandatory = $true)]
        $results
    )

    $screenshots = @()

    foreach ($r in $results) {
        write-host "Getting report for $r"
        $rest = Invoke-RestMethod -Method 'Get' -Uri $r
        Write-Host "rest: $rest"

        $meta = $rest.meta | ConvertTo-Json | ConvertFrom-Json
        $gsb = $meta.processors.gsb
        
        $task = $rest.task | ConvertTo-Json | ConvertFrom-Json
        Write-Host "Task: $task"

        $screenshotUrl = $task.screenshotURL
        Write-Host "screenshotURL: $screenshotUrl"

        $screenshots += $screenshotUrl
        start-sleep 2
    }
    $screenshots
    getUrlScreenshots($screenshots)
}

function getUrlscreenshots {
    Param (
        [Parameter(mandatory = $true)]
        $screenshots
    )

    foreach ($s in $screenshots) {
        Write-Host "Screenshot URL: $s"
        $fileName = $s.split("/")[-1]
        write-host "Filename $fileName"
        $outPath = "Z:\scripts\phishing\urlScreenshots\" + $fileName + ".png"
        write-host "Saving $outPath"

        Invoke-WebRequest -Uri $s -OutFile $outPath
    }
}

function getVirusTotalReport {
    Param (
        [Parameter(mandatory = $true)]
        $results,
        $virusToken = '6fe093c8a778a29692b9aa624b6723e13e7d8aaeb48e7953e44e16552a99affa'
    )

    $uri = "https://www.virustotal.com/vtapi/v2/url/report"

    foreach ($r in $results) {
        $body = @{resource = $r; apikey = $virusToken}
        $report = Invoke-RestMethod -Uri $uri -Body $body
        
        $report

        $pDetection = $report.positives / $report.total
        $pDetection
    }
}

function createResultsObject {

    $resultsObject = New-Object -TypeName psobject

    $resultsObject | Add-Member -MemberType NoteProperty -Name subject -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name uid -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name bodyPath -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name headerPath -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name msgPath -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name otherPath -Value $null
    $resultsObject | Add-Member -MemberType NoteProperty -Name links -Value @()
    $resultsObject | Add-Member -MemberType NoteProperty -Name urlScanResults -Value @()
    $resultsObject | Add-Member -MemberType NoteProperty -Name urlScanScreenshots -Value @()
    $resultsObject | Add-Member -MemberType NoteProperty -Name virusTotalResults -Value @()
    $resultsObject | Add-Member -MemberType NoteProperty -Name virusTotalDetection -Value @()

    return $resultsObject
}

function exportResultsCsv {
    Param (
        [Parameter(mandatory = $true)]
        $resultsArray
    )

    foreach ($r in $resultsArray) {
        $r.links -join ";"
        $r.urlScanResults -join ";"
        $r.urlScanScreenshots -join ";"
        $r.virusTotalResults -join ";"
        $r.virusTotalDetection -join ";"

        $r | Export-Csv -NoTypeInformation -Append 'Z:\scripts\phishing\test.csv'
    }
}

#Test resultsArray with parseMsgDir
$resultsArray = @()

$resultsArray = parseMsgDir($resultsArray)


exportResultsCsv($resultsArray)



#$links = getLinksDir
#$links = @()
#$links += "https://www.google.com"
#$results = submitUrlScan($links)
#start-sleep 30

#$results = @()
#$results += '3a0fdb4d5b063ed77c73919e9ad06f200fc02ba0de50ead4d521545af2d23ad4-1553316503'
#getUrlScan($results)
#submitVirusScan($links)
#getVirusTotalReport($results)
#$r = createResultsObject
#$r.urlScanResults += "foo"
#$r.urlScanResults += "bar"
#$r.urlScanResults = $r.urlScanResults -join ";"
#$r | Export-Csv -NoTypeInformation -Append 'Z:\scripts\phishing\test.csv'

    