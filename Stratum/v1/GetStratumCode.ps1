Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

$global:searchString = "Stratum"
$global:newSolutionName = ""
$global:outputDir = ""
$global:instanceDir = ""
$global:srcDir = ""

Function ProcessComplete{
    Write-Host "`n PROCESS COMPLETE `n" -ForegroundColor Green
}

Function CopyFilesFromInstance{
    if(-not($global:instanceDir -notmatch "\S")){
        Write-Host "Copying files from your instance to the Solution's Lib folder..."
        $instanceBinDir = $global:instanceDir + "\bin\" 

        if(Test-Path -Path $instanceBinDir){        
            $solnLibDir = -join($global:outputDir,"\",$global:newSolutionName,"\lib\")
    
            $fileName = "HtmlAgilityPack.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Microsoft.Extensions.DependencyInjection.Abstractions.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Microsoft.Extensions.DependencyInjection.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Newtonsoft.Json.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.Analytics.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.CES.GeoIp.Core.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.ContentSearch.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.ContentSearch.Linq.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.ExperienceForms.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.Kernel.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.Logging.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.Mvc.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "Sitecore.Mvc..Analytics.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force

            $fileName = "System.Web.Mvc.dll"
            #Write-Host ("Copying " + $fileName + "...")
            Copy-Item -Path (-join($instanceBinDir,$fileName)) -Destination $solnLibDir -Force
        }
        else{
            Write-Host (-join("`n","ERROR: Could not find path - ", $instanceBinDir)) -ForegroundColor Red
        }
    }
}

# Replace $global:searchString in file content with $global:newSolutionName
Function UpdateFileContent{
    if($global:newSolutionName -ne $global:searchString){
        Write-Host " Updating file content..." -ForegroundColor Cyan
        # Update content in .sln file
        $solnFileFullName = -join($global:outputDir,"\",$global:newSolutionName,"\",$global:newSolutionName,".sln")
        $newContent = (Get-Content $solnFileFullName) -replace $global:searchString, $global:newSolutionName
        Set-Content -Path $solnFileFullName -Value $newContent -ErrorAction Stop

        $files = Get-ChildItem -Path $global:srcDir -recurse

        foreach ($file in $files)   
        {
            $replaceStringInContent = $false  
            $fileFullName = $file.FullName
            $filename = $file.Name  
            $extension = ""
            if((-not (Test-Path -Path $fileFullName -PathType Container))){
                $extension = (Get-Item $fileFullName).Extension
            }
            
            if($fileFullName.EndsWith('\Views\web.config') -or ($filename -eq "gallery.js")){
                $replaceStringInContent = $true
            }
            else{
                if($filename -eq "packages.config" -or $filename -eq "web.config" -or
                $filename -eq "web.config.debug" -or $filename -eq "web.config.release" -or 
                $extension -eq ".js" -or $extension -eq ".css" -or $extension -eq ".sql" -or 
                $extension -eq ".json" -or $extension -eq ".js" -or $extension -eq ".map" -or 
                $extension -eq ".gif" -or $extension -eq ".woff2" -or $extension -eq ".woff" -or 
                $extension -eq ".ttf" -or $extension -eq ".asax" -or $extension -eq ".ico" -or 
                (Test-Path -Path $fileFullName -PathType Container)){
                        $replaceStringInContent = $false  
                }  
                else {
                   $replaceStringInContent = $true
                }
            }

            if($replaceStringInContent){
                $newContent = (Get-Content $file.FullName) -replace $global:searchString, $global:newSolutionName
                Set-Content -Path $fileFullName -Value $newContent -ErrorAction Stop
            }
        }           
    }
}

# Rename $global:searchString in file with $global:newSolutionName
Function RenameFiles{
if($global:newSolutionName -ne $global:searchString){
    Write-Host " Renaming files..." -ForegroundColor Cyan
    $dir = $global:outputDir + "\" + $global:newSolutionName

    if((Test-Path -Path (-join($dir,"\.vs\",$global:searchString)))){
            Rename-Item -Path (-join($dir,"\.vs\",$global:searchString)) -NewName $global:newSolutionName -ErrorAction Stop            
        }

        if((Test-Path -Path (-join($dir,"\",$global:searchString,".sln")))){
            Rename-Item -Path (-join($dir,"\",$global:searchString,".sln")) -NewName (-join($global:newSolutionName,".sln")) -ErrorAction Stop
        }

        Get-ChildItem -Path $global:srcDir -Recurse | ForEach-Object {
        if(($_.Name -like (-join($global:searchString,"*"))) -or ($_.Name -like (-join("*",".", $global:searchString)))){
          $newName = $_.Name -ireplace [regex]::Escape($global:searchString), $global:newSolutionName
          Rename-Item -Path $_.FullName -NewName $newName -ErrorAction Stop
          }
        }
    }
}

# Delete the bin & obj folders
Function DeleteBinAndObjFolders{  
    Write-Host " Deleting bin & obj folders..." -ForegroundColor Cyan  
        $files = Get-ChildItem -Path $global:srcDir -Recurse

        foreach ($file in $files){
            $filename = $file.Name 
            if($filename -eq "bin" -or $filename -eq "obj"){                   
                Remove-Item $file.FullName -Recurse -Force -ErrorAction SilentlyContinue                   
            }  
        }  
}

# Removes the Git files
Function RemoveGitFiles{
    Write-Host "`n Removing git files..." -ForegroundColor Cyan
    $solutionFolder = $global:outputDir + "\" + $global:newSolutionName
    Remove-Item (-join($solutionFolder, "\.git")) -Recurse -Force
    Remove-Item (-join($solutionFolder, "\.gitattributes"))  
    Remove-Item (-join($solutionFolder, "\.gitignore"))  
    
    # Remove the 'GetStratum' folder
    Remove-Item (-join($solutionFolder, "\GetStratum")) -Recurse -Force  
}

# Clone the git repo
Function CloneRepo{
    Write-Host "`n Cloning the repo... `n" -ForegroundColor Cyan
    $solnFolder = -join($global:outputDir,"\", $global:newSolutionName)    
    git clone -b master "https://github.com/sukesh-y/Stratum.git" $solnFolder
}

# Returns the folder path of the src folder
Function GetSrcFolderPath{    
    return $global:outputDir + "\" + $global:newSolutionName + "\src"
}

Function GetUserInputs{
    Write-Host "`n *************** STRATUM - A BOILERPLATE VISUAL STUDIO SOLUTION FOR SITECORE PROJECTS *************** " -ForegroundColor Yellow
    Write-Host "`n This script will create a Visual Studio solution with projects & code, commonly used in Sitecore solutions." -ForegroundColor DarkGray

    # Set your solution name
    Write-Host "`n ENTER A VALID NAME FOR YOUR VISUAL STUDIO SOLUTION (e.g. MyCompany): " -NoNewline -ForegroundColor Magenta
    $global:newSolutionName = Read-Host

    # The output directory where the files will be downloaded to. e.g. D:\Projects
    Write-Host "`n This should be an existing directory. Do not create the solution folder inside it, as it will be created by the script." -ForegroundColor DarkGray
    Write-Host " ENTER EXISTING TARGET DIRECTORY PATH WHERE THE SOLUTION SHOULD BE CREATED (e.g. D:\Projects): " -NoNewline -ForegroundColor Magenta
    $global:outputDir = Read-Host

    Write-Host "`n This input is optional. If you have an existing instance, the required DLLs will be copied from there into the Solution's Lib folder. If not, press Enter to continue." -ForegroundColor DarkGray
    Write-Host " ENTER PATH OF THE YOUR INSTANCE DIRECTORY (e.g. C:\inetpub\wwwroot\MyInstance): " -NoNewline -ForegroundColor Magenta
    $global:instanceDir = Read-Host
}


try{
    cls

    GetUserInputs

    $global:srcDir = GetSrcFolderPath
    
    CloneRepo    
    RemoveGitFiles    
    DeleteBinAndObjFolders    
    RenameFiles    
    UpdateFileContent
    CopyFilesFromInstance
    ProcessComplete
} 
catch { 
    $exception = $_ | Format-List * -Force | Out-String 
    Write-Host $exception -ForegroundColor Red -BackgroundColor Black
    throw
}