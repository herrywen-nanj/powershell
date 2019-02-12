#计划任务中需要执行的脚本，作用是进到Websites目录下，将所有子目录的InfoLog删除
$Filename = Get-ChildItem -Path D:\Websites -Name
foreach ($f in $Filename)
{
cd D:\Websites
Remove-Item $f\InfoLog -Recurse -Force
}
