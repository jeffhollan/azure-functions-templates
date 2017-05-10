$nugetExe = d:\tools\nuget.exe

# Get Environmental Params
$currentPath = Get-Location
$binDirectory = Split-Path $currentPath -Parent | Join-Path -ChildPath "bin"
$templatesPath = Split-Path $currentPath -Parent | Join-Path -ChildPath "\Templates\"

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

New-Item $binDirectory -ItemType Directory

# Visual Studio Build

# \bin\VisualStudio\Content
$VisualStudioBuildOutputPath = Join-Path $binDirectory -ChildPath "VisualStudio"
$VsContentDirectory = Join-Path $binDirectory -ChildPath "VisualStudio\Content"
New-Item $VsContentDirectory -ItemType Directory

# Copy Build\VisualStudio\Azure.Functions.nuspec
$VisualStudioBuildArtifacts = $currentPath.Path + "\VisualStudio\*"

# \bin\VisualStudio\Azure.Functions.nuspec
Copy-Item $VisualStudioBuildArtifacts $VisualStudioBuildOutputPath

# \bin\VisualStudio\Content\BlobTrigger-CSharp
Get-ChildItem $templatesPath -Directory |
    Foreach-Object {    
    $configFolder = $_.FullName + "\.template.config"
    $sourcePath = $templatesPath + "\" + $_.Name
    if (Test-Path $configFolder) {        
        Copy-Item $sourcePath $VsContentDirectory -Recurse -Force
    }
}

# Portal Build
# \bin\Portal\Content
$PortalBuildOutputPath = Join-Path $binDirectory -ChildPath "Portal"
$PortalContentDirectory = Join-Path $binDirectory -ChildPath "Portal\Content"
New-Item $PortalContentDirectory -ItemType Directory

# Copy Build\Portal\Azure.Functions.nuspec
$PortalBuildArtifacts = $currentPath.Path + "\Portal\*"

# \bin\Portal\Azure.Functions.nuspec
Copy-Item $PortalBuildArtifacts $PortalBuildOutputPath
Copy-Item ($templatesPath + "\*") $PortalContentDirectory -Recurse -Force

# #portal
# /Templates/content/AllFolders
# /Templates/content/.templateconfig file
# /Templates/portal nuspec respective files
# #VSBuild
# md D:\azureFun\vsTemplates\TemplatePackage\content
# $target = "D:\azureFun\vsTemplates\TemplatePackage\content";
# Get-ChildItem "D:\azurefun\azure-webjobs-sdk-templates\Templates" -Directory |
#     Foreach-Object {    
#     $x = $_.FullName + "\VS\*"
#     $y = $target + "\" + $_.Name
#     if (Test-Path $x) {
#         md $y
#         Copy-Item $x $y -Recurse -Force
#     }
# }

# Copy-Item D:\azurefun\azure-webjobs-sdk-templates\Templates\Azure.Functions.nuspec D:\azureFun\vsTemplates\TemplatePackage\
# Set-Location D:\azureFun\vsTemplates\TemplatePackage\
# d:\tools\nuget.exe pack D:\azureFun\vsTemplates\TemplatePackage\Azure.Functions.nuspec

# # Copy-Item D:\azurefun\azure-webjobs-sdk-templates\Templates\$templateName\VS\* D:\azureFun\vsTemplates\TemplatePackage\$nuspecFile\content\ -Recurse -Force
# # $filename = "$nuspecFile.nuspec"
# # Move-Item D:\azureFun\vsTemplates\TemplatePackage\$nuspecFile\content\$filename D:\azureFun\vsTemplates\TemplatePackage\$nuspecFile\
# # Set-Location D:\azureFun\vsTemplates\TemplatePackage\

# # Remove-Item -recurse D:\azureFun\vsTemplates\TemplatePackage\* -Force