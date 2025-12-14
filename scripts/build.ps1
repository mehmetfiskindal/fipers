# PowerShell build script for Windows
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows")]
    [string]$Platform,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Building Fipers for $Platform ($BuildType)..." -ForegroundColor Green

switch ($Platform) {
    "windows" {
        $BuildDir = Join-Path $ProjectRoot "windows\build"
        New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
        
        Push-Location $BuildDir
        
        cmake .. `
            -DCMAKE_BUILD_TYPE=$BuildType `
            -G "Visual Studio 17 2022" `
            -A x64
        
        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            Write-Error "CMake configuration failed"
            exit 1
        }
        
        cmake --build . --config $BuildType
        
        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            Write-Error "Build failed"
            exit 1
        }
        
        Pop-Location
        Write-Host "Windows build complete!" -ForegroundColor Green
    }
    
    default {
        Write-Error "Unknown platform: $Platform"
        exit 1
    }
}

