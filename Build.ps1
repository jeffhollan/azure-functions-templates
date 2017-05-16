param (    
    [ValidateSet('Portal', 'VS', 'All')]
    [System.String]$templateHost
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function LogErrorAndExit($errorMessage, $exception) {    
    Write-Host $errorMessage -ForegroundColor Yellow        
    if ($exception -ne $null) {
        Write-Host "Error occured at line:" + $exception.InvocationInfo.ScriptLineNumber -ForegroundColor Yellow
        Write-Host $exception.Message -ForegroundColor Red
    }    
    Exit
}

function LogSuccess($message) {
    Write-Host $message -ForegroundColor Green    
}

# utility functions
function Download([string]$url, [string]$outputFilePath) {        
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputFilePath 
        LogSuccess "Download complete for $url"
    } catch {        
        LogErrorAndExit "Download failed for $url" $_.Exception
    }   
}

function Unzip([string]$zipfilePath, [string]$outputpath) {    
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfilePath, $outputpath)        
        LogSuccess "Unzipped:$zipfilePath"
    }
    catch {
        LogErrorAndExit "Unzip failed for:$zipfilePath" $_.Exception
    }
}

function PortalHost($templateHost) {
    if ($templateHost -eq [HostMode]::All.ToString() -or $templateHost -eq [HostMode]::Portal.ToString()) {
        return $true
    }   
    return $false
}

function VSHost($templateHost) {
    if ($templateHost -eq [HostMode]::All.ToString() -or $templateHost -eq [HostMode]::VS.ToString()) {
        return $true
    }

    return $false
}

# Main Code Block
try {       
    $rootPath = Get-Location
    $binDirectory = Join-Path $rootPath -ChildPath "bin"
    $templatesPath = Join-Path $rootPath -ChildPath "\Templates\"    
       
    Enum HostMode {
        Portal
        VS
        All
    }

    # Start with a clean slate
    if (Test-Path $binDirectory) {
        Remove-Item $binDirectory -Recurse -Confirm:$false    
    }

    $toolsDir = Join-Path $binDirectory -ChildPath "\Tools\"
    New-Item -ItemType Directory $toolsDir

    # Download dotnet CLI
    $dotnetCliDownloadUrl = "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/release/2.0.0/dotnet-dev-win-x86.latest.zip"
    $dotnetCliZip = Join-Path $toolsDir -ChildPath "dotnet.zip"
    Download $dotnetCliDownloadUrl $dotnetCliZip

    # Unzip dotnet CLI
    $cliDir = Join-Path $toolsDir -ChildPath "\cli\"
    New-Item -ItemType Directory $cliDir
    Unzip $dotnetCliZip $cliDir    
        
    # Download code formatter tool
    $codeFormatterZip = Join-Path $toolsDir -ChildPath "codeFormatter.zip"
    $codeFormatterDownloadUrl = "https://github.com/dotnet/codeformatter/releases/download/v1.0.0-alpha6/CodeFormatter.zip"    
    Download $codeFormatterDownloadUrl $codeFormatterZip

    # Unzip code formatter tool    
    Unzip $codeFormatterZip $toolsDir
    
    $dotnetExe = Join-Path $binDirectory -ChildPath "\tools\cli\dotnet.exe"    
    $codeFormatterExe = Join-Path $binDirectory -ChildPath "tools\CodeFormatter\CodeFormatter.exe"

    # creating a directory to hold nuget packages
    $nugetPackageDir = Join-Path $binDirectory -ChildPath "nupkg"
    New-Item $nugetPackageDir -ItemType Directory

    # Install generic templates
    Invoke-Expression -Command "$dotnetExe new -i $templatesPath"
    if ($LastExitCode -ne 0) {
        LogErrorAndExit "Failed to install templates"
    }

    if (PortalHost $templateHost) {
        $portalTemplaeVersion = "1.0.0"
        $portalDirectory = Join-Path $binDirectory -ChildPath "portal"
        New-Item $portalDirectory -ItemType Directory

        $portalSourceDirectory = Join-Path $portalDirectory -ChildPath "portal"
        New-Item $portalSourceDirectory -ItemType Directory
        Set-Location $portalSourceDirectory
        
        # Use generic templates to generate templae for portal
        Invoke-Expression -Command "$dotnetExe new functions --portalTemplates true --vsTemplates false"
        if ($LastExitCode -ne 0) {
            LogErrorAndExit "Failed to execute templates"
        }        

        $codeFormatterPortalProj = Join-Path $portalSourceDirectory -ChildPath "codeFormat.csproj"
        Invoke-Expression -Command "$codeFormatterExe $codeFormatterPortalProj /nocopyright"

        $portalNuspec = Join-Path $portalSourceDirectory -ChildPath "PortalTemplates.nuspec"
        nuget.exe pack $portalNuspec -Version $portalTemplaeVersion -OutputDirectory $NugetPackageDir
        if ($LastExitCode -ne 0) {
            LogErrorAndExit "Error creating nuget package"
        }

        $portalReleaseDir = Join-Path $portalDirectory -ChildPath "release"
        New-Item $portalReleaseDir -ItemType Directory

        nuget.exe install Azure.Functions.Templates.Portal -Source $nugetPackageDir -OutputDirectory $portalReleaseDir
        if ($LastExitCode -ne 0) {
            LogErrorAndExit "Could not install Azure.Functions.Templates.Portal nuget package"
        }
    }    

    # #To-do: get version dynamically
    # nuget.exe pack ($templatesPath + "ItemTemplates.nuspec") -Version 1.0.0 -OutputDirectory $NugetPackageDir    

    # $projectTemplateBuildFile = Join-Path $rootPath -ChildPath "ProjectTemplate\Template.proj"
    # # msbuild $projectTemplateBuildFile /t:Clean;
    # # msbuild $projectTemplateBuildFile /p:PackageVersion=1.0.0

    # $projectTemplateNuget = Join-Path $rootPath -ChildPath "\ProjectTemplate\bin\*.nupkg"
    # Copy-Item $projectTemplateNuget $nugetPackageDir    

    # # To-do: Create file name using version nuber
    # $dotnetExe new -i "..\..\nupkg\Azure.Functions.Templates.Portal.1.0.0.nupkg"

    # # Generating templates for portal
    # Set-Location $binDirectory
    # New-Item -ItemType Directory "templates"
    # cd templates
    # $dotnetExe new portal    

    # # continue
    # Set-Location $binDirectory
    # $codeFormatterExe $codeFormatterProj / nocopyright
    # remove-item $codeFormatterProj

    # Steps - VS templates generation + Portal Templates
    # Use the templtaes folder to install the template - TemplatesA (Full repo contents)
    # Execute TemplatesA
    # Use code formatter to format cs files
    # Use TemplatesA (that has nuspec file), Create VS template package (Nuget Pack, etc selective files)
}
catch {
    LogErrorAndExit "UnKnown Error" $_.Exception
}