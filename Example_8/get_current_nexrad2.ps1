# This script we will 
# 1) Download the latest NEXRAD II data from Upton, NY (OKX) for the past 4 hours 
# 2) Create and save the radar data in a directory called "NEXRAD_2/KOKX/Current" which is within the current working directory.

# This script is written by Eric J. Drewitz

# Define environment name
$ENV_NAME = "current_radar"

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

pip install wxdata

Write-Output "========================================="
Write-Output "Setup complete! Environment '$ENV_NAME' is ready."
Write-Output "To use it in your terminal, run: conda activate $ENV_NAME"
Write-Output "========================================="

# Gets current Directory
$CURRENT_DIR = (Get-Location).Path

# Retrieves radar data
wxdata-nexrad2 fetch latest -sid kokx -hr 4 -cdir="$CURRENT_DIR\NEXRAD_2\KOKX\Current"