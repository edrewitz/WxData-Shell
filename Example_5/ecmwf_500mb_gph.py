"""
In this script we will perform the following:

1) Extract the data from the ECMWF IFS & ECMWF AIFS netCDF files created from our shell scripts into an xarray.array

2) Find the mean 500mb geopotential height between ECMWF IFS & AIFS across Europe

3) Plot the ECMWF IFS + AIFS Mean 500mb Geopotential Height Forecast across Europe.

This script is written by Eric J. Drewitz
"""

### IMPORTS ###
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import numpy as np
import pandas as pd
import xarray as xr
import os

# Get the absolute directory where this python script lives
# This is necessary for automating Python scripts via Windows Powershell
script_dir = os.path.dirname(os.path.abspath(__file__))

# Join it with your folder name to create an absolute path for where the graphics will save
target_folder = os.path.join(script_dir, "ECMWF IFS + AIFS 500 MB Mean Geopotential Height")

# Create our graphics directory
os.makedirs(target_folder, exist_ok=True)

# Extract our ECMWF IFS & AIFS netCDF data
# IFS
ifs = xr.open_dataset(f"{script_dir}/NETCDF/ecmwf_ifs_gph_500.nc", engine='netcdf4')

# AIFS
aifs = xr.open_dataset(f"{script_dir}/NETCDF/ecmwf_aifs_gph_500.nc", engine='netcdf4')

# IFS is in 3-hourly increments and AIFS is 6-hourly increments
# We need to decimate IFS by 2 along ifs['step'] to make IFS & AIFS of equal length
# If these two arrays are of unequal length - this process will error out
ifs = ifs.isel(step=slice(None, None, 2))

# Combine ECMWF IFS & AIFS datasets after re-sizing IFS
ds = xr.concat([ifs, aifs], dim="dataset", join='outer')

# Find the ECMWF IFS + AIFS Mean 500 MB Geopotential Height
ds['mean_geopotential_height'] = (ds['geopotential_height'][0, :, :, :] + ds['geopotential_height'][1, :, :, :])/2

# Drop the old variable and free it from memory
ds = ds.drop_vars('geopotential_height')

# Create our graphics
for i in range(0, len(ds['step']), 1):
    fig = plt.figure(figsize=(12,12))
    
    # Create our subplot with a PlateCarree (lat/lon) projection
    ax = fig.add_subplot(1,1,1, projection=ccrs.PlateCarree())
    
    # Set our boundaries in a latlon format of [western_bound, eastern_bound, southern_bound, northern_bound] followed by our PlateCarree projection
    ax.set_extent([-30, 50, 30, 75], ccrs.PlateCarree())
    
    # Add our features to the map 
    # Add our coastlines
    ax.add_feature(cfeature.COASTLINE.with_scale('50m'), linewidth=0.75, zorder=3)
    
    # Add the oceans, land, states, lakes and Canadian provinces and color them light cyan
    ax.add_feature(cfeature.OCEAN, color='lightcyan', zorder=1)
    ax.add_feature(cfeature.LAKES, color='lightcyan', zorder=1)
    ax.add_feature(cfeature.LAND, color='navajowhite', zorder=1)
    ax.add_feature(cfeature.BORDERS, edgecolor='black', linewidth=0.5, zorder=5)
    
    # Add our filled contours for temperature
    cs = ax.contourf(ds['longitude'], 
                   ds['latitude'], 
                   (ds['mean_geopotential_height'][i, :, :])/10, 
                   levels=np.arange(520, 604, 4), 
                   transform=ccrs.PlateCarree(),
                   alpha=0.45,
                   cmap='inferno',
                   extend='both')
    
    # Create our colorbar for our filled contours
    fig.colorbar(cs, 
                 shrink=0.5, 
                 pad=0.01,
                 ticks=np.arange(520, 610, 10))
    # Plot title
    plt.title(f"ECMWF IFS + AIFS Mean 500 MB Geopotential Height", 
                   fontsize=10, 
                   fontweight='bold',
                   bbox=dict(boxstyle='round', 
                                facecolor='bisque'),
                   loc='left')
    
    # Extract our valid time as a datetime object
    valid_time = pd.to_datetime(ifs['valid_time'].values)
    
    # Gets our new forecast hour (eventhough we are plotting the initial frame)
    times = pd.to_datetime(ds['time'].values)
    
    # Secondary title for our model runtime
    plt.title(f"Forecast Valid: {times[i].strftime('%m/%d/%Y %H:00')} (t+{int(ds['step'][i])} HR)\nModel Initialization: {times[0].strftime('%m/%d/%Y %H:00')} UTC", 
                    fontsize=7, 
                    fontweight='bold',
                    bbox=dict(boxstyle='round', 
                                facecolor='bisque'),
                    loc='right')
    
    # Adding my signature on the plot
    ax.text(0, 
            -0.001, 
            f"Plot Created by Eric J. Drewitz - Powered by WxData", 
            transform=ax.transAxes, 
            fontsize=6, 
            fontweight='bold', 
            bbox=dict(boxstyle='round', 
                    facecolor='bisque'),
           zorder=10)
    
    # Names our file for the forecast hour frame
    filename = f"{times[i].strftime('%m%d%Y%H')}.png"
    
    # Saves our frame to our graphics directory
    fig.savefig(f"{target_folder}/{filename}", bbox_inches='tight')
    
    # Closes figure to preserve memory
    plt.close(fig)
    