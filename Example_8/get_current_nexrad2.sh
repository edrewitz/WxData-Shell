#!/bin/bash

# This script we will 
# 1) Download the latest NEXRAD II data from Upton, NY (OKX) for the past 4 hours 
# 2) Create and save the radar data in a directory called "NEXRAD_2/KOKX/Current" which is within the current working directory.

# This script is written by Eric J. Drewitz

# Exit immediately if a command exits with a non-zero status
set -e

# Define environment name
ENV_NAME="current_radar"

echo "========================================="
echo "Creating new Conda environment: $ENV_NAME"
echo "========================================="

# 1. Initialize Conda for this script session
# This replicates how conda init injects conda commands into your shell
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    echo "Error: Conda installation not found in your home directory."
    exit 1
fi

# 2. Create the Conda environment
conda create -n "$ENV_NAME" python=3.14 -y

# 3. Activate the new environment
conda activate "$ENV_NAME"

pip uninstall wxdata

# 4. Install the wxdata package
echo "========================================="
echo "Installing wxdata package..."
echo "========================================="
pip install wxdata

echo "========================================="
echo "Setup complete! Environment '$ENV_NAME' is ready."
echo "To use it in your terminal, run: conda activate $ENV_NAME"
echo "========================================="

# Gets current Directory
current_dir=$(pwd)

# Retrieves radar data
wxdata-nexrad2 fetch latest -sid kokx -hr 4 -cdir=$current_dir/NEXRAD_2/KOKX/Current