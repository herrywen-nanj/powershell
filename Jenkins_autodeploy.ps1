#接收参数
$version = $env:version
$JOB_NAME = $ENV:JOB_NAME
$website_ip = $env:machine
#设置工作目录
$work_dir = $ENV:WORKSPACE
$script:build_dir = Get-ChildItem -Path $work_dir -Recurse -ErrorAction SilentlyContinue -Filter *.Http | Where-Object { $_.Extension -eq '.Http' }
$publish_dir = "$work_dir\$script:build_dir\bin\Release\netcoreapp2.1\win7-x64\publish"
echo "push_dir是$publish_dir"
#获取发布uri，并自动获取ip和端口
$parttern = "\b\d{1,5}"
$JOB_NAME -match $parttern
$script:port = $Matches[0]
$script:uri = "http://$website_ip`:" + "$script:port"
#获取编译时间
$script:date = (Get-Date).ToString("yyyyMMddHHmmss")
#定义编译失败内容
$build_failure = "$JOB_NAME" + "项目编译出现问题，请检查环境配置!" + ",发布在服务器" + "$website_ip"
#定义成功消息内容
$content = "$JOB_NAME" + "项目发布成功" + ",发布在服务器" + "$website_ip" + ",发布在服务器" + "$website_ip"
#定义失败消息内容
$content_failure = "$JOB_NAME" + "发布失败，post版本号或者填写的目标ip不能为空!" + ",发布在服务器" + "$website_ip"
#定义拷贝失败消息
$copy_failure = "$JOB_NAME" + "拷贝文件出现问题，请检查目标服务器winrm连接!" + ",发布在服务器" + "$website_ip"
#定义恢复通知
$content_recovery = "$JOB_NAME" + "发布失败，你上传的代码可能有问题，已经恢复到上个稳定版本" + ",发布在服务器" + "$website_ip"




#设置IIS服务器的用户名
$website_username = "administrator"
#设置IIS服务器的密码
$website_password = "Aecg1qaz@wsx"
#设置IIS站点根目录地址
$website_dir = "D:\WebSites\"
$website_tag_dir = "D:\WebSites-tag\"
$website_bak_dir = "D:\WebSites-bak\"
#设置主程序目录名
$website_name = $ENV:JOB_NAME




#执行远程服务器代码
function ExecCmd($cmd){
    $pass = ConvertTo-SecureString -AsPlainText $website_password -Force
    $cred = New-Object pscredential($website_username, $pass)
    $session = New-PSSession -ComputerName $website_ip -credential $cred
    Invoke-Command -Session $session -ArgumentList $cmd  -ScriptBlock { 
        Invoke-Expression $using:cmd
    }
}

#发送钉钉消息
function delivery($msg)
{
$uri="https://oapi.dingtalk.com/robot/send?access_token=420ba1861fa435046c04d87fc1770d0a96b7fe5efa1b989a8e059982a0723764"
$bodys=
@"
{"msgtype": "text","text": {"content": "$msg"}}
"@
Invoke-WebRequest -Uri $uri -ContentType "application/json;charset=utf-8" -Method POST  -Body $bodys
}


#发布到Website
function PublishWebsite($websites){
        echo "开始clean $website_name ………………………"
        dotnet clean --configuration Release
        echo "开始build $website_name ………………………"
        dotnet build --configuration Release
        if($? -ne 1) {           
            delivery $build_failure
            exit 1    
        }
        else {
               echo "开始生成$website_name 的web文件……………………"
               dotnet publish .\$build_dir\$build_dir.csproj -r win7-x64 -c Release
        }
}  


#远程拷贝生成的文件,创建对应tag目录和启动iis站点服务
function remote_copy_and_restart_website() {
        echo "-----------检测tag目录是否存在，不存在则创建，此目录是tag版本目录-----------"
        $null = ExecCmd "Test-Path $website_tag_dir"
        if($? -ne 1){
            ExecCmd "mkdir $website_tag_dir"
        }
        echo "-----------检测bak目录是否存在，不存在则创建，此目录是本地备份目录-----------"
        $null_directory = ExecCmd "Test-Path $website_bak_dir"
        if($null_directory -ne 1){
            ExecCmd "mkdir $website_bak_dir"
        }       
        echo "拷贝发布代码到$website_ip $website_dir$website_name-new……………………"
        $hasBak = ExecCmd "Test-Path $website_dir$website_name-new"
        if($hasBak -eq 1){
            ExecCmd "Remove-Item $website_dir$website_name-new -Recurse -Force"
        }
        $password = ConvertTo-SecureString -AsPlainText $website_password -Force
        $autocopy_cred = New-Object System.Management.Automation.PSCredential -ArgumentList $website_username,$password
        $copy_session = New-PSSession -ComputerName $website_ip -Credential $autocopy_cred
        Copy-Item -Path $publish_dir -Destination $website_dir$website_name-new -ToSession $copy_session -Recurse
        if($? -ne 1) {
                    echo "拷贝失败，跳出整个程序"
                    delivery $copy_failure
                    exit 1
        }
        else {    
                  echo "----------------------------发布目录拷贝到$website_name-new全部完成-------------------------------------------------"
		  $hasBak_tag = ExecCmd "Test-Path $website_tag_dir$website_name-$version-$date"
                  if($hasBak_tag -eq 1){
                         ExecCmd "Remove-Item $website_tag_dir$website_name-$version-$date -Recurse -Force"
                  }   
                  echo "拷贝最新发布目录到tag目录下"
                  ExecCmd "Copy-Item -Path  $website_dir$website_name-new -Destination $website_tag_dir$website_name-$version-$date -Recurse -Force"
                  echo "---------------------------发布目录拷贝到$website_tag_dir目录下全部完成---------------------------------------------"
                  echo "远程停止$website_ip 站点$website_name……………………"
                  ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe stop site $website_name"
                  ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe stop apppool $website_name"       
                  $hasDir = ExecCmd "Test-Path $website_dir$website_name"
                  if($hasDir -eq 1){
                         ExecCmd "mv $website_dir$website_name $website_bak_dir$website_name-bak-$date"
                  }
                  echo "检测$website_ip 是否存在站点$website_name……………………"
                  $hasSite = ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe list site /name:$website_name"
                  if (!$hasSite){
                             echo "未检测到此站点，远程创建$website_ip 站点$website_name……………………"
                             ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe add site /name:$website_name /bindings:$website_address /physicalPath:$website_dir$website_name"
                  }
                  else {
                             echo "$website_ip 站点$website_name 已存在 ，无需创建"
                  } 
                  echo "远程拷贝$website_ip $website_dir$website_name-new 到网站根目录 $website_dir$website_name"
                  ExecCmd "mv $website_dir$website_name-new $website_dir$website_name"
                  echo "远程启动$website_ip 站点$website_name……………………"
                  ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe start site $website_name"
                  ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe start apppool $website_name"
                  echo "#############################################"
                  echo "站点地址：$script:uri"
                  echo "#############################################"
         }
}
#检测网站发布是否成功，不成功执行回滚操作
function checkout_website() {
    if (!$website_ip) {
          delivery $content_failure
          exit 1
    }    
    else {
          echo "开始编译................"
          PublishWebsite  $websites
          if($? -ne 1) {
                       echo "退出编译程序，且不拷贝目录"
                       exit 1
          }      
          else {
              echo "开始部署……………………"    
              remote_copy_and_restart_website
              sleep -s 20
              if ($? -ne 1) {
                    exit 1
              }
              else {
                    $status_code = Invoke-WebRequest -Uri $script:uri
                    if ($status_code.StatusCode -eq 200) {
                           delivery $content
                    }
                    else {
                           echo "恢复bak文件到原有文件夹"
                           ExecCmd "Copy-Item -Path $website_bak_dir$website_name-bak-$date\* -Destination $website_dir$website_name"
                           #ExecCmd "Copy-Item -Path $website_dir$website_name-bak\* -Destination $website_dir$website_name"
                           echo "正在删除错误的tag版本"
                           ExecCmd "Remove-Item $website_tag_dir$website_name-$version-$date  -Recurse -Force"
                           echo "远程重启并恢复$website_ip 站点$website_name……………………"
                           ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe stop site $website_name"
                           ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe start site $website_name"
                           ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe stop apppool $website_name"
                           ExecCmd "C:\Windows\System32\inetsrv\appcmd.exe start apppool $website_name"
                           echo "#############################################”
                           echo "恢复站点地址：$script:uri"
                           echo "#############################################"
                           delivery $content_recovery
                    }  
              }    
          } 
      }     
} 
checkout_website
