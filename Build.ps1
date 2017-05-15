Add-Type -AssemblyName System.IO.Compression.FileSystem

# utility functions
function Download([string]$url, [string]$outputFilePath) {        
    Invoke-WebRequest -Uri $url -OutFile $outputFilePath
}

function Unzip([string]$zipfilePath, [string]$outputpath) {    
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfilePath, $outputpath)
}

# Get Environmental Params
$currentPath = Get-Location
$binDirectory = Join-Path $currentPath -ChildPath "bin"
$templatesPath = Join-Path $currentPath -ChildPath "\Templates\"

# Start with a clean slate
if (Test-Path $binDirectory) {
    try {
        Remove-Item $binDirectory -Recurse -Confirm:$false
    }
    catch {
        $error[0]|format-list -force
        Write-Host -ForegroundColor Red "Unable to clean bin directory"        
        Exit 
    }    
}


$nugetPackageDir = Join-Path $binDirectory -ChildPath "nupkg"

nuget.exe pack ($templatesPath + "ItemTemplates.nuspec") -Version 1.0.0 -OutputDirectory $NugetPackageDir
nuget.exe pack ($templatesPath + "PortalTemplates.nuspec") -Version 1.0.0 -OutputDirectory $NugetPackageDir

$projectTemplateBuildFile = Join-Path $currentPath -ChildPath "ProjectTemplate\Template.proj"
msbuild $projectTemplateBuildFile /t:Clean;
msbuild $projectTemplateBuildFile /p:PackageVersion=1.0.0

$projectTemplateNuget = Join-Path $currentPath -ChildPath "\ProjectTemplate\bin\*.nupkg"
Copy-Item $projectTemplateNuget $nugetPackageDir

$tempDir = Join-Path $binDirectory -ChildPath "\temp\"
New-Item -ItemType Directory $tempDir

# Download and unzip dotnet CLI
$dotnetCliDownloadUrl = "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/release/2.0.0/dotnet-dev-win-x86.latest.zip"
$dotnetCliZip = Join-Path $tempDir -ChildPath "dotnet.zip"
Download $dotnetCliDownloadUrl $dotnetCliZip

$cliDir = Join-Path $tempDir -ChildPath "\cli\"
New-Item -ItemType Directory $cliDir
Unzip $dotnetCliZip $cliDir

# Download and unzip code formatter tool
$codeFormatterDownloadUrl = "https://github.com/dotnet/codeformatter/releases/download/v1.0.0-alpha6/CodeFormatter.zip"
$codeFormatterZip = Join-Path $tempDir -ChildPath "codeFormatter.zip"
Download $codeFormatterDownloadUrl $codeFormatterZip
Unzip $codeFormatterZip $tempDir