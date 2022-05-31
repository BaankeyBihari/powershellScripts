$hostname = hostname
$resourcePath = "$env:localappdata/powershellScripts/resource.json"
echo $resourcePath

if($hostname.toLower().contains("dungeon")) {
    Write-Output "Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/work.json
} else {
    Write-Output "No Match"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/BaankeyBihari/powershellScripts/main/work.json
}