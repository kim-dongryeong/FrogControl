# Build FrogControl (.NET port) in Release and run it.
# Usage:  ./build.ps1            # build + launch
#         ./build.ps1 -NoRun     # build only
param([switch]$NoRun)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    dotnet build FrogControl/FrogControl.csproj -c Release -nologo
    if (-not $NoRun) {
        $exe = Join-Path $PSScriptRoot 'FrogControl/bin/Release/net8.0-windows/FrogControl.exe'
        Write-Host "Launching $exe"
        Start-Process $exe
    }
}
finally { Pop-Location }
