#Start off with taking password from parameter 

param ([string]$newPassword="")

#Stores password as encrypted file (Also can set requriements in If statement for password)

if($newPassword.Length -gt 0){
echo $newPassword;

#ConvertTo-SecureString [-String] $newPassword
#ConvertTo-SecureString [-String] $newPassword [-SecureKey SecureString]
#ConvertTo-SecureString [-String] $newPassword [-Key Byte[]]
#ConvertTo-SecureString [-String] $newPassword [-AsPlainText] [-Force]

$newPassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File ".\passEncrypt.pw"
exit;
}else{
echo "NO NEW PASSWORD, CONTINUING PROGRAM";
}
echo "REST OF PROGRAM";

#Updates Scheduled Tasks | Searches for all tasks that have specified user as owner and updates password

$taskname = Get-ScheduledTask | Select-Object TaskName -ExpandProperty Principal
foreach($task in $taskname){
    if($task.UserId -eq 'axis_qvs'){
        echo $task.TaskName $task.UserId 
        Set-ScheduledTask -Password $newPassword -User "user" -TaskName $task.TaskName
    }
}

#Updates data connections that have service account as user

$exportedCertName="test01"

$certToUse = Get-PfxCertificate -FilePath "C:\ProgramData\Qlik\Sense\Repository\Exported Certificates\$exportedCertName\client.pfx"
$set="abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray();
$xrfkey="";
for($x=0;$x -lt 16;$x++){$xrfkey+=$set|Get-Random;}

$hostname = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content -Path "C:\ProgramData\Qlik\Sense\Host.cfg")))

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Qlik-Xrfkey",$xrfKey)
$headers.Add("X-Qlik-User", "UserDirectory=internal; UserId=sa_repository")
$headers.Add("Content-Type", "application/json")

$(Invoke-RestMethod $("https://"+$hostname+":4242/qrs/dataconnection/full?xrfkey="+$xrfkey) -Headers $headers -method "GET" -certificate $certToUse)|foreach-object{
    if($_.username -eq "domain\service_account"){
        $_.password="NEWPASSWORD";
        Invoke-RestMethod $("https://"+$hostname+":4242/qrs/dataconnection/$($_.id)?xrfkey="+$xrfkey) -Headers $headers -method "PUT" -body $($_|ConvertTo-Json) -certificate $certToUse
    }
}