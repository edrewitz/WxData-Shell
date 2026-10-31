#!/bin/bash

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

# Exit immediately if a command exits with a non-zero status
set -e

# Define environment name
ENV_NAME="wx_pipeline"

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

# Subset for CONUS
# Define our coordinates so we don't pass in negative numbers into the command
western_bound=-130
eastern_bound=-65
northern_bound=50
southern_bound=20

# Define our paths to save the GRIB2 data files
gfs_path="$current_dir/GFS0P25/GRIB2"
ifs_path="$current_dir/High_Res_IFS/GRIB2"
aifs_path="$current_dir/AIFS/GRIB2"
gdps_path="$current_dir/GDPS/GRIB2"

wxdata-ecmwf ifs latest -t hd -v 2-meter_temperature -lt surface -s ecmwf -cdir=$ifs_path \
-wb=$western_bound -eb=$eastern_bound -nb=$northern_bound -sb=$southern_bound \
--netcdf True --ncdir ECMWF/High_Resolution_IFS/NETCDF --ncfname ecmwf_high_res_ifs_t2m.nc &
wxdata-ecmwf aifs latest -t d -v 2-meter_temperature -lt surface -s google -cdir=$aifs_path \
-wb=$western_bound -eb=$eastern_bound -nb=$northern_bound -sb=$southern_bound \
--netcdf True --ncdir ECMWF/AIFS/NETCDF --ncfname ecmwf_aifs_t2m.nc &
wxdata-gfs 0p25 latest -v temperature -lt height_above_ground -s noaa -l 2 -cdir=$gfs_path \
-wb=$western_bound -eb=$eastern_bound -nb=$northern_bound -sb=$southern_bound \
--netcdf True --ncdir GFS/0P25/NETCDF --ncfname gfs_0p25_t2m.nc & 
wxdata-gdps fetch latest -lt height_above_ground -l 2 -v temperature -cdir=$gdps_path \
-wb=$western_bound -eb=$eastern_bound -nb=$northern_bound -sb=$southern_bound \
--netcdf True --ncdir GDPS/NETCDF --ncfname gdps_t2m.nc

wait

echo "Weather Data Downloaded Successfully!"