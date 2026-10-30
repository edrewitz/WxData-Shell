#!/bin/bash

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

# Exit immediately if a command exits with a non-zero status
set -e

# Define environment name
ENV_NAME="ecmwf_gph"

# Sets current directory
current_dir=$(pwd)

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
pip install git+"https://github.com/edrewitz/WxData.git"

echo "========================================="
echo "Setup complete! Environment '$ENV_NAME' is ready."
echo "To use it in your terminal, run: conda activate $ENV_NAME"
echo "========================================="

# Here we use the WxData ECMWF CLI tool to download our data in parallel.
# Visit https://edrewitz.github.io/WxData/ECMWF%20IFS%20CLI for ECMWF IFS CLI Documentation
# Visit https://edrewitz.github.io/WxData/ECMWF%20AIFS%20CLI for ECMWF AIFS CLI Documentation
#
# Data Subset: Europe
# Western Bound = 30°W
# Eastern Bound = 50°E
# 

western_bound=-30

# ECMWF IFS & AIFS Data Pipelines
wxdata-ecmwf ifs latest -f 144 -v geopotential_height -l 500 -lt pressure \
-s ecmwf -wb=$western_bound -eb 50 -nb 75 -sb 30 -cdir $current_dir/ECMWF/IFS \
--netcdf True --ncdir $current_dir/NETCDF --ncfname ecmwf_ifs_gph_500.nc & 
wxdata-ecmwf aifs latest -f 144 -v geopotential_height -l 500 -lt pressure \
-s google -wb=$western_bound -eb 50 -nb 75 -sb 30 -cdir $current_dir/ECMWF/AIFS \
--netcdf True --ncdir $current_dir/NETCDF --ncfname ecmwf_aifs_gph_500.nc

wait 
# Executes our Python plotting script
python $current_dir/ecmwf_500mb_gph.py