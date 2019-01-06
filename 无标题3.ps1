#作用：powershell非交互式远程执行脚本，目标机器herrywen,herrywen，远程ip：192.168.255.135
#远程机器开启Enable-PSRemoting –Force
#远程机器设置访问列表Set-Item wsman:\localhost\client\trustedhosts *
#                    Restart-Service WinRM
$username = "herrywen"
$password = "herrywen"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username,$pass
#设置超时时间3600毫秒，也就是10分钟，默认三分钟，看具体项目，参考：https://docs.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/new-pssessionoption?view=powershell-5.0
$timeout = New-PSSessionOption -OperationTimeout 3600
$session_many = new-pssession -computername 192.168.255.135 -Credential $Cred -SessionOption $timeout
#-ScriptBlock {}是执行一段命令，-Filepath是指定脚本
#Invoke-Command -ComputerName 192.168.255.135 -Credential $Cred  -FilePath .\无标题4.ps1 -SessionOption 
Invoke-Command -Session $session_many  -FilePath .\无标题4.ps1