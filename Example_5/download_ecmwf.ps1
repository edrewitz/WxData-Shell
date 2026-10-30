# This script performs the following tasks
# -----------------------------------------
#
# 1) Downloads the latest ECMWF IFS & ECMWF AIFS 500mb Geopotential Height in parallel
# - ECMWF IFS will use ECMWF Open-Data as its source
# - ECMWF AIFS will use Google Cloud as its source
# 
# ECMWF IFS Has 144 Forecast Hours 06z & 18z runs
# ECMWF IFS Has 360 Forecast Hours 00z & 12z runs
# ECMWF AIFS Has 360 Forecast Hours all runs
#
# Let's ensure IFS and AIFS only go out to 144 hours to ensure this consistency
# We will set -f 144 to ensure 144 is the final forecast hour
#
# Using different source servers for downloading different datasets is recommended to avoid exceeding server rate-limits
#
# 2) Convert and export the ECMWF IFS & AIFS GRIB2 data to netCDF (.nc) files.
# - The first netCDF file will be named ecmwf_ifs_gph_500.nc
# - The second netCDF file will be named ecmwf_aifs_gph_500.nc
# - Will save to a folder called NETCDF in the current directory
#
# 3) Create forecast graphics showing the ECMWF IFS + AIFS Mean 500mb Geopotential Height Forecast for Europe
# - Graphics will be created in ecmwf_500mb_gph.py
#
# This script is written by Eric J. Drewitz

# Check if the script is already running in PowerShell 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Running in legacy PowerShell $($PSVersionTable.PSVersion.Major). Checking for PowerShell 7..." -ForegroundColor Yellow

    # Check if PowerShell 7 is already installed but not being used
    $pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $pwshPath) {
        # Search common default installation paths if it's not in the PATH environment variable yet
        $defaultPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        if (Test-Path $defaultPath) { $pwshPath = $defaultPath }
    }

    # If PowerShell 7 is not found, install it silently via Winget (or Microsoft's web installer)
    if (-not $pwshPath) {
        Write-Host "PowerShell 7 not found. Starting silent installation..." -ForegroundColor Cyan
        
        # Using winget (Recommended for Windows 10/11)
        winget install --id Microsoft.PowerShell --source winget --silent --accept-source-agreements --accept-package-agreements
        
        # Fallback if winget is unavailable (e.g., Windows Server without Desktop Experience)
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Winget failed or unavailable. Falling back to MSI web installer..." -ForegroundColor Yellow
            Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms) } -UseMSI -Quiet"
        }

        # Refresh path environment variable to find the newly installed pwsh.exe
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    }

    # Relaunch this exact script inside PowerShell 7 and exit the current PS5 session
    if (Test-Path $pwshPath) {
        Write-Host "Relaunching script inside PowerShell 7..." -ForegroundColor Green
        & $pwshPath -File $PSCommandPath $args
        Exit $LASTEXITCODE
    } else {
        Write-Error "Failed to install or locate PowerShell 7."
        Exit 1
    }
}

# ==============================================================================
# YOUR ACTUAL POWERSHELL 7+ CODE GOES HERE
# ==============================================================================
Write-Host "Success! The script is now running inside PowerShell v$($PSVersionTable.PSVersion.Major)." -ForegroundColor Green

# Stop execution on any error (equivalent to set -e)
$ErrorActionPreference = "Stop"

# Define environment name
$ENV_NAME = "ecmwf_gph"

Write-Output "========================================="
Write-Output "Creating new Conda environment: $ENV_NAME"
Write-Output "========================================="

# Initialize Conda for this script session
$condaPath = Get-Command conda -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($condaPath) {
    # Dynamically find the profiles script folder relative to the conda executable
    $condaDir = Split-Path (Split-Path $condaPath -Parent) -Parent
    $profileScript = Join-Path $condaDir "shell\condabin\conda-hook.ps1"
    if (Test-Path $profileScript) {
        & $profileScript
    }
} else {
    # Fallback to standard home directory paths if not in system environment variables
    $homeDir = $HOME
    $possiblePaths = @(
        "$homeDir\miniconda3\shell\condabin\conda-hook.ps1",
        "$homeDir\anaconda3\shell\condabin\conda-hook.ps1"
    )
    $initialized = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            & $path
            $initialized = $true
            break
        }
    }
    if (-not $initialized) {
        Write-Error "Error: Conda installation not found."
        Exit 1
    }
}

# Create the Conda environment
conda create -n $ENV_NAME python=3.14 -y

# Activate the new environment
conda activate $ENV_NAME

# Suppress errors if pip uninstall fails because the package isn't there yet
try {
    pip uninstall wxdata -y
} catch {
    # Package wasn't installed, safe to ignore
}

# Install the wxdata package
Write-Output "========================================="
Write-Output "Installing wxdata package..."
Write-Output "========================================="
pip install git+"https://github.com/edrewitz/WxData.git"

Write-Output "========================================="
Write-Output "Setup complete! Environment '$ENV_NAME' is ready."
Write-Output "To use it in your terminal, run: conda activate $ENV_NAME"
Write-Output "========================================="

# Gets our current directory
$CURRENT_DIR = (Get-Location).Path

# Here we use the WxData ECMWF CLI tool to download our data in parallel.
# Visit https://edrewitz.github.io/WxData/ECMWF%20IFS%20CLI for ECMWF IFS CLI Documentation
# Visit https://edrewitz.github.io/WxData/ECMWF%20AIFS%20CLI for ECMWF AIFS CLI Documentation
#
# Data Subset: Europe
# Western Bound = 30°W
# Eastern Bound = 50°E

$WESTERN_BOUND=-30

# ECMWF IFS & AIFS Data Pipelines
$Proc1 = Start-Process -FilePath "wxdata-ecmwf" `
        -ArgumentList "ifs latest -f 144 -v geopotential_height -l 500 -lt pressure -s ecmwf -wb=$WESTERN_BOUND -eb 50 -nb 75 -sb 30 -cdir $CURRENT_DIR/Example_5/ECMWF/IFS --netcdf True --ncdir $CURRENT_DIR/Example_5/NETCDF --ncfname ecmwf_ifs_gph_500.nc" `
        -PassThru `
        -NoNewWindow
$Proc2 = Start-Process -FilePath "wxdata-ecmwf" `
        -ArgumentList "aifs latest -f 144 -v geopotential_height -l 500 -lt pressure -s google -wb=$WESTERN_BOUND -eb 50 -nb 75 -sb 30 -cdir $CURRENT_DIR/Example_5/ECMWF/AIFS --netcdf True --ncdir $CURRENT_DIR/Example_5/NETCDF --ncfname ecmwf_aifs_gph_500.nc" `
        -PassThru `
        -NoNewWindow

Write-Host "Waiting for ECMWF downloads to complete..."

# Track processes and hold the script until all three finish downloading
$Processes = @($Proc1, $Proc2)
$Processes | Wait-Process

Write-Output "All downloads completed successfully."

# Executes our Python plotting script
& "C:\Users\drewi\miniconda3\envs\$ENV_NAME\python.exe" "$CURRENT_DIR\Example_5\ecmwf_500mb_gph.py"