# In this example we will create a pipeline for the following:
# 1) Downloading the GFS0P25 2-Meter Temperature
# 2) Downloading the High Resolution ECMWF IFS 2-Meter Temperature
# 3) Downloading the ECMWF AIFS 2-meter temperature
# 4) Downloading the GDPS 2-Meter Temperature
# 5) Clean, process and convert the GRIB2 data into netCDF
# 6) Export a netCDF file for each model
# **These tasks will be done in parallel**
# **The netCDF files will reflect the subsetting of the GRIB2 data**
#-------------------------------------------------------------------
# Source Servers
# GFS0P25 - NCEP/NOMADS
# ECMWF High Resolution IFS - ECMWF Open Data
# ECMWF AIFS - Google Cloud
# GDPS - MSC Open Data (There are no alternative source servers for Canadian data)

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
$ENV_NAME = "wx_pipeline"

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
conda create -n $ENV_NAME python=3.12 -y

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

# Subset for CONUS
# Define our coordinates so we don't pass in negative numbers into the command
$WESTERN_BOUND=-130
$EASTERN_BOUND=-65
$NORTHERN_BOUND=50
$SOUTHERN_BOUND=20

# Define our paths to save the GRIB2 data files
$GFS_PATH="$CURRENT_DIR\GFS0P25\GRIB2"
$IFS_PATH="$CURRENT_DIR\High_Res_IFS\GRIB2"
$AIFS_PATH="$CURRENT_DIR\AIFS\GRIB2"
$GDPS_PATH="$CURRENT_DIR\GDPS\GRIB2"

# Starts our different jobs in parallel
$Proc1 = Start-Process -FilePath "wxdata-gfs" -PassThru -NoNewWindow -ArgumentList @(
    "0p25 latest",
    "-v temperature",
    "-l 2",
    "-lt height_above_ground",
    "-s noaa",
    "-wb=$WESTERN_BOUND -eb=$EASTERN_BOUND -nb=$NORTHERN_BOUND -sb=$SOUTHERN_BOUND",
    "-cdir=$GFS_PATH",
    "--netcdf True",
    "--ncdir $CURRENT_DIR\Example_6\GFS\NETCDF"
)
$Proc2 = Start-Process -FilePath "wxdata-ecmwf" -PassThru -NoNewWindow -ArgumentList @(
    "ifs latest",
    "-t hd -v 2-meter_temperature",
    "-lt surface",
    "-s ecmwf",
    "-wb=$WESTERN_BOUND -eb=$EASTERN_BOUND -nb=$NORTHERN_BOUND -sb=$SOUTHERN_BOUND",
    "-cdir=$IFS_PATH",
    "--netcdf True",
    "--ncdir $CURRENT_DIR\Example_6\ECMWF\IFS\NETCDF"
)
$Proc3 = Start-Process -FilePath "wxdata-ecmwf" -PassThru -NoNewWindow -ArgumentList @(
    "aifs latest",
    "-t d -v 2-meter_temperature",
    "-lt surface",
    "-s google",
    "-wb=$WESTERN_BOUND -eb=$EASTERN_BOUND -nb=$NORTHERN_BOUND -sb=$SOUTHERN_BOUND",
    "-cdir=$AIFS_PATH",
    "--netcdf True",
    "--ncdir $CURRENT_DIR\Example_6\ECMWF\AIFS\NETCDF"
)
$Proc4 = Start-Process -FilePath "wxdata-gdps" -PassThru -NoNewWindow -ArgumentList @(
    "fetch latest",
    "-v temperature",
    "-l 2",
    "-lt height_above_ground",
    "-wb=$WESTERN_BOUND -eb=$EASTERN_BOUND -nb=$NORTHERN_BOUND -sb=$SOUTHERN_BOUND",
    "-cdir=$GDPS_PATH",
    "--netcdf True",
    "--ncdir $CURRENT_DIR\Example_6\GDPS\NETCDF"
)

Write-Host "Waiting for GFS downloads to complete..."

# Track processes and hold the script until all three finish downloading
$Processes = @($Proc1, $Proc2, $Proc3, $Proc4)
$Processes | Wait-Process

Write-Output "All downloads completed successfully."