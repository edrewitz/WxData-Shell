# In this script we will perform the following tasks:
# 1) Create a conda environment called gfs_pipeline
# 2) Activate our conda environment called gfs_pipeline
# 3) Install the WxData Python package from conda-forge
# 4) Execute our Python wrapper script that holds our downstream processes

# Downstream Processes in Python Scripts
# 1) Download the GFS0P25 850mb Temperature Forecast from NCEP/NOMADS
# 2) Create a set of forecast graphics for the GFS0P25 850mb Temperature

# This script was written by Eric J. Drewitz

# Define environment name
$ENV_NAME = "gfs_pipeline"

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
    conda uninstall wxdata -y
} catch {
    # Package wasn't installed, safe to ignore
}

# Install the wxdata package
Write-Output "========================================="
Write-Output "Installing wxdata package..."
Write-Output "========================================="

conda install wxdata -y

Write-Output "========================================="
Write-Output "Setup complete! Environment '$ENV_NAME' is ready."
Write-Output "To use it in your terminal, run: conda activate $ENV_NAME"
Write-Output "========================================="

# Gets our current directory
$CURRENT_DIR = Get-Location

conda run -n $ENV_NAME python "$CURRENT_DIR\Example_3\wrapper.py"