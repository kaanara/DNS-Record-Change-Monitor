
#Variables - Paths
$Path = "C:\Scripts"
$DomainFile=$Path + "/Domain.csv"
$DomainValuesOldFile=$Path +"/DomainValuesOld.csv"

#Variables
$Domains = Import-Csv -Path $DomainFile
$DomainValuesNew = $null
$DomainValuesOld = Import-Csv -Path $DomainValuesOldFile -ErrorAction Continue
$ComparedDomainList= @()

#Mail Settings
$smtpServer="10.44.47.40"
$from = "dns@seturas.com"
$adminEmailAddr = "kaan.ara@setur.com.tr"

#Domain Name Control
ForEach ($Domain in $Domains){
    #Domain Query Types The possible enumeration values are "UNKNOWN,A_AAAA,A,NS,MD,MF,CNAME,SOA,MB,MG,MR,NULL,WKS,PTR,HINFO,MINFO,MX,TXT,RP,AFSDB,X25,ISDN,RT,AAAA,SRV,DNAME,OPT,DS,RRSIG,NSEC,DNSKEY,DHCID,NSEC3,NSEC3PARAM,ANY,ALL,WINS".
    $DomainValuesNew += Resolve-DnsName -Type ALL -Name $Domain.Domains -Server 8.8.8.8 -ErrorAction Continue
}

#Compare Old and New values 
    $Compareson = Compare-Object -ReferenceObject $DomainValuesOld -DifferenceObject $DomainValuesNew -IncludeEqual -ErrorAction Continue

    #Mail Body Conversion
ForEach ($Item in $Compareson){ 
    $ComparedDomainList +=  [pscustomobject]@{Name=$Item.InputObject.Name;Type=$Item.InputObject.Type;NameExchange=$Item.InputObject.NameExchange;IPAddress=$Item.InputObject.IPAddress;NameHost=$Item.InputObject.NameHost;TXT=$Item.InputObject.Strings | Out-String}
}

$body = $ComparedDomainList | ConvertTo-Html 

#Send Mail Domain Changed send mail othervise dont.
if ( $null -ne $Compareson ) {
    Send-Mailmessage -SmtpServer $smtpServer -From $from -to $adminEmailAddr -Subject "DNS Has Changed" -Body $body -BodyAsHtml -Priority High -ErrorAction Stop -ErrorVariable err
    
    #Write new values to as old and store
    #$DomainValuesOld = $DomainValuesNew
    #$DomainValuesOld | Export-Csv -Path $DomainValuesOldFile 
}

#IF no DomainValuesOld avalible remove comments for first run
$DomainValuesOld = $DomainValuesNew
$DomainValuesOld | Export-Csv -Path $DomainValuesOldFile 
