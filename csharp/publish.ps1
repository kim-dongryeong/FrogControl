# Publish FrogControl (.NET port). Three variants (the user asked for options to test):
#
#   ./publish.ps1              # self-contained single-file .exe (zero-dependency; needs internet
#                              #   the first time to restore the win-x64 runtime packs)
#   ./publish.ps1 -Framework   # framework-dependent single-file .exe (small; needs .NET 8 Desktop
#                              #   Runtime on the target; also needs internet the first time)
#   ./publish.ps1 -Folder      # framework-dependent FOLDER publish (offline-safe; a folder of
#                              #   DLLs + FrogControl.exe; needs .NET 8 Desktop Runtime on the target)
param([switch]$Framework, [switch]$Folder)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $proj = 'FrogControl/FrogControl.csproj'
    if ($Folder) {
        dotnet publish $proj -c Release -nologo
        $out = Join-Path $PSScriptRoot 'FrogControl/bin/Release/net8.0-windows/publish'
    }
    elseif ($Framework) {
        dotnet publish $proj -c Release -r win-x64 --self-contained false `
            -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -nologo
        $out = Join-Path $PSScriptRoot 'FrogControl/bin/Release/net8.0-windows/win-x64/publish'
    }
    else {
        dotnet publish $proj -c Release -r win-x64 --self-contained true `
            -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
            -p:EnableCompressionInSingleFile=true -nologo
        $out = Join-Path $PSScriptRoot 'FrogControl/bin/Release/net8.0-windows/win-x64/publish'
    }
    Write-Host "Published to: $out"
    Get-ChildItem $out | Where-Object { $_.Name -match 'FrogControl\.exe|frog|shortcut' } | Select-Object Name, Length
}
finally { Pop-Location }
