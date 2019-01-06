#作用：钉钉机器人告警，@"  "@为多行命令写法http://blog.51cto.com/yoke88/2069906
function delivery($msg)
{
$uri="https://oapi.dingtalk.com/robot/send?access_token=420ba1861fa435046c04d87fc1770d0a96b7fe5efa1b989a8e059982a0723764"
$bodys=
@"
{"msgtype": "text","text": {"content": "$msg"}}
"@
Invoke-WebRequest -Uri $uri -ContentType "application/json;charset=utf-8" -Method POST  -Body $bodys
}
$null= Invoke-WebRequest -Uri http://www.baidu.com
if ($? -eq 0){
delivery "The website is not ok!"
exit 1
}
else {
delivery "The website is ok"
}
