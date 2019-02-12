$Filename = Get-ChildItem -Path D:\Websites -Name
foreach ($f in $Filename)
{
cd D:\Websites
Remove-Item $f\InfoLog -Recurse -Force
}
