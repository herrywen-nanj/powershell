#作用：钉钉机器人告警，@"  "@为多行命令写法http://blog.51cto.com/yoke88/2069906
#args是powershell的默认数组，格式是元素1 元素2 元素3，不支持元素之间用逗号分隔，要带逗号也可以，加双引号即可，这样在双引号里的就看成一个元素
#范例:
#    $JOB_NAME = "148金龙鱼测试"
#    $content = "成功"
# delivery "148金龙鱼测试成功"
# delivery $JOB_NAME$content
# delivery $JOB_NAME,$content    (不支持加逗号这种写法)
#另外需要注意的是 delivery $JOB_NAME(元素之间无论空多少个空格，钉钉那边接收消息都是一个空格)$content
function delivery
{
$uri="https://oapi.dingtalk.com/robot/send?access_token=420ba1861fa435046c04d87fc1770d0a96b7fe5efa1b989a8e059982a0723764"

Invoke-WebRequest -Uri $uri -ContentType "application/json;charset=utf-8" -Method POST  -Body @"
{"msgtype": "text","text": {"content": "$args"}}
"@
}
$null= Invoke-WebRequest -Uri http://www.baidu.com
if ($? -eq 0){
delivery "The website is not ok!"
exit 1
}
else {
delivery "The website is ok"
}
