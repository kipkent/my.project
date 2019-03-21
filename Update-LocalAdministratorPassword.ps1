<#
    .Synopsis 
        Change local administrator password on list of computers given in a text file.
        
    .Description
        This script picks up the computer names from given input file and changes the local administrator password.
 
    .Parameter InputFile    
        The full path of the text file name where computer account names are stored. Ex: C:\temp\computers.txt
        
    .Example
        Update-LocalAdministratorPassword.ps1 -InputFile c:\temp\Computers.txt
		
		This prompts you for the password for two times and updates the local administrator password on all computers to that.
       
    .Example
        Update-LocalAdministratorPassword.ps1 -InputFile c:\temp\Computers.txt -Verbose
        
        This tells you what exactly happening at every stage of the script.
        
    .Notes
        NAME:      Update-LocalAdministratorPassword.ps1
        AUTHOR:    Sitaram Pamarthi
		WEBSITE:   http://techibee.com

#>
[cmdletbinding()]
param (
[parameter(mandatory = $true)]
$InputFile,
$OutputDirectory

)


if(!$outputdirectory) {
	$outputdirectory = (Get-Item $InputFile).directoryname
}	
$failedcomputers	=	Join-Path $outputdirectory "failed-computers.txt"
$stream = [System.IO.StreamWriter] $failedcomputers
$stream.writeline("ComputerName `t IsOnline `t PasswordChangeStatus")
$stream.writeline("____________ `t ________ `t ____________________")

$faile	=	Join-Path $outputdirectory "PasswodrsList.txt"
$streamyy = [System.IO.StreamWriter] $faile
$streamyy.writeline("Passwodr `t ComputerName ")



$password = Read-Host "Enter the UserName" -AsSecureString
$confirmpassword = Read-Host "Confirm the UserName" -AsSecureString

$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmpassword))

if($pwd1_text -ne $pwd2_text) {
	Write-Error "Entered UserName are not same. Script is exiting"
	exit
}

if(!(Test-Path $InputFile)) {
	Write-Error "File ($InputFile) not found. Script is exiting"
	exit
}

$Computers = Get-Content -Path $InputFile

foreach ($Computer in $Computers) {
	$Computer	=	$Computer.toupper()
	$Isonline	=	"OFFLINE"
	$Status		=	"SUCCESS"
	Write-Verbose "Working on $Computer"
	if((Test-Connection -ComputerName $Computer -count 1 -ErrorAction 0)) {
		$Isonline = "ONLINE"
		Write-Verbose "`t$Computer is Online"
	} else { Write-Verbose "`t$Computer is OFFLINE" }

	try {
		Add-Type -AssemblyName System.Web
		$pwd3_text = [System.Web.Security.Membership]::GeneratePassword(8,1)
		$account = [ADSI]("WinNT://$Computer/$pwd1_text")
		$account.psbase.invoke("setpassword",$pwd3_text)
#		$account.psbase.invoke("setpassword",$pwd1_text + "$Computer")
		$streamyy.writeline("$pwd3_text   $Computer")
		Write-Verbose "`tPassword Change completed successfully"
	}
	catch {
		$status = "FAILED"
		Write-Verbose "`tFailed to Change the administrator password. Error: $_"
	}

	$obj = New-Object -TypeName PSObject -Property @{
 		ComputerName = $Computer
 		IsOnline = $Isonline
 		PasswordChangeStatus = $Status
	}

	$obj | Select ComputerName, IsOnline, PasswordChangeStatus
	
	if($Status -eq "FAILED" -or $Isonline -eq "OFFLINE") {
		$stream.writeline("$Computer `t $isonline `t $status")
	}
			
}
$streamyy.close()
$stream.close()
Write-Host "`n`nFailed computers list is saved to $failedcomputers"