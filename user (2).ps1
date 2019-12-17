
$InvocatioPath = Split-Path $MyInvocation.MyCommand.Path


##===================================================================================================##
<### 

only below fields needs to be changed before executing the script.

###>
##===================================================================================================##

#####Enter the path where ssh module .psd1 is kept in your system
$sshModulePath = "D:\Posh-SSH-master\Posh-SSH-master\Posh-SSH.psd1"


##### Enter the ServerName/IP 'from' where id_rsa.pub is copied to the destination server
$sourcecomputer="192.168.56.101"


##### Enter the userName who have rights to use SCP command
$user="kanchan"


##### Enter the path of the serverList 'to' which you want to copy the id_rsa.pub file
$serverListPath="D:\Users\kanchan.u\Desktop\UCSF KC\unix\useradd\serverList.txt"


#enter the path of the file which is located in source server
$sourceFilePath="/home/oracle/.ssh/id_rsa.pub"


#Enter the destination pdath where you want to locate the file
$DestinationPath="/home/oracle/myorpath"



##===================================================================================================##



#### Logs are saved in the same path from where script is executed
$logPath="$InvocatioPath\log.txt"


#### output Report is saved in the same path from where script is executed
$outputPath="$InvocatioPath\output.txt"

#file to append

$fileToAppend="$DestinationPath/id_rsa.pub"

$pathToAppend="/home/oracle/.ssh/authorized_keys"


Function Get-Cred
{
    try
    {
        $a=get-credential
        $u = $a.username
        $user = $u.split("\")
        $p = $a.password
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p)
        $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }   
    catch
    {
            $l= New-Object -ComObject wscript.shell
            if($m -eq '1')
            {
                write-host 'Script cancelled'
                $host.SetShouldExit(1)
                exit
            }
            else
            {
                exit
            }
    }       
    return $a
}   


$cred=get-cred

$date=get-date -Format g


if(!(Get-Module Posh-SSH))
{
    try{
    Import-Module $sshModulePath -ErrorAction Stop
    }
    catch{
    Write-Warning "Posh-ssh module not imported. please give the correct path for Posh-SSH.psd1 file"  ; Read-Host "press any key to exit"; break;
    }
}

    $regex ="[pP]assword[\s+\w+\d+\p{P}\p{S}]*(:){1}[\s]*$"
    
    $serverList = Get-Content "$serverListPath"
   
   
    $report=foreach($serverName in $serverList){                
              
              
              
               if(Test-Connection -ComputerName $serverName -Count 1 -Quiet)
               {
               
               # Write-Verbose "Creating Session With $sourcecomputer"
                try{
                $session = New-SSHSession -ComputerName $sourcecomputer -Credential $cred -Port 22 -AcceptKey -ConnectionTimeout 60 -ErrorAction Stop
                if($session.Connected)
                {
                   # Write-Host "Connected to $serverName"
                    
                    
                        $ShellStream = New-SSHShellStream -SSHSession $session
                        $AddUserCmdText = "scp -pr $sourceFilePath $user@$serverName`:$DestinationPath"
                                
                                    $sshAction = $AddUserCmdText
                                    Write-Host "copying file from $sourcecomputer to $serverName"
                                    $null = Invoke-SSHStreamExpectAction -ShellStream $ShellStream -ExpectRegex $($regex) -Command $sshAction -Action $($Cred.GetNetworkCredential().Password) -timeout 3        
                                   
                                    $UserExists = $null
                                    $SSHContent = $ShellStream.read()
                                    Start-Sleep -Seconds 2



                        $shellstream.dispose()
                    
                    $session.Disconnect()
                
                }  #end of if connect
                else{
                  Write-Error "SSH Connection Failed" 
                }
                }
                catch
                {
                    Write-Error "Connection Error: $_" 
                     Write-Output  "SSH Connection Failed . Reason: $_"
                }
                Remove-SSHSession -SSHSession $session | Out-Null
            
                      }#end If test-connection
               else
               {
               
                Write-Host "Unable to copy file from $sourcecomputer to '$serverName'. Ping Fail" -ForegroundColor Yellow -BackgroundColor Black
                 Write-Output "$date"|Out-File $logPath -Append
                Write-Output "Unable to copy file from $sourcecomputer to '$serverName'. Ping Fail"|Out-File $logPath -Append
               }
            }#ForLoop End


if($report)
{
$report |ft
}




 $output=foreach($temp in $serverList){                
              
              
              
               if(Test-Connection -ComputerName $temp -Count 1 -Quiet)
               {
                Write-Verbose "Creating Session With $temp"
                try{
                $session = New-SSHSession -ComputerName $temp -Credential $cred -Port 22 -AcceptKey -ConnectionTimeout 60 -ErrorAction Stop
                if($session.Connected)
                {
                   # Write-Host "Connected to $serverName"
                    
                    
 $copyFile="`cat $fileToAppend>>$pathToAppend;if [ `$(echo `$?) -eq 0 ]; then echo `" $temp`: file appended True`"; else echo `"file appended False`"; fi"
 
  $checkStatus = Invoke-SSHCommand -SSHSession $session -Command $copyFile -EnsureConnection | select -exp Output    
                    
                    
  Write-Host "$checkStatus" -ForegroundColor DarkMagenta
   Write-Output "$date"|Out-File $outputPath -Append
    Write-outPUT "$checkStatus "|Out-File $outputPath -Append
                    
                    $session.Disconnect()
                
                }  #end of if connect
                else{
                    Write-Host "SSH Connection Failed $serverName" 
                    Write-Output "$date"|Out-File $logPath -Append
                    Write-Output  "SSH Connection Failed $serverName " |Out-File $logPath -Append


                }
                }
                catch
                {
                    Write-Error "Connection Error: $_" 
                    Write-Output "$date"|Out-File $logPath -Append
                    Write-Output  "SSH Connection Failed $serverName . Reason: $_" |Out-File $logPath -Append
                }
                Remove-SSHSession -SSHSession $session | Out-Null
            
                      }#end If test-connection
               else
               {
               
                    Write-Host "Unable to reach '$serverName'. Ping Fail" -ForegroundColor Yellow -BackgroundColor Black
                    Write-Output "$date"|Out-File $logPath -Append
                    Write-Output "Unable to reach '$serverName'. Ping Fail"|Out-File $logPath -Append
        
               
               }
            }#ForLoop End