<img src="https://github.com/edrewitz/WxData/blob/main/icons/wxdata_logo.png.png?raw=true" width="400" height="400" alt="Alt text" />


# WxData-Shell
A repository of examples of using WxData in both Linux Shell and Windows Powershell for creating automated ETL Pipelines for various types of weather data.

**Example 1**

In Example 1 we create a pipeline in both Linux Shell [`gfs_pipeline.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_1/gfs_pipeline.sh) and Windows Powershell [`gfs_pipeline.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_1/gfs_pipeline.ps1) that does the following:

1) Creates a Python 3.12 environment `gfs_850mb_temperature` and installs WxData via pip.
2) Using the WxData CLI - downloads the latest GFS0P25 850mb Temperature Forecast to a directory called `GFS0P25/Temperature`.
3) Executes a Python script [`gfs_graphics.py`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_1/gfs_graphics.py) that ingests the GRIB2 data and creates [graphics](https://github.com/edrewitz/WxData-Shell/tree/main/Example_1/GFS%20850mb%20Temperature%20Forecast) of the GFS0P25 850mb Temperature Forecast for CONUS. 

**Example 2**

In Example 2 we create automated ETL pipelines in both Linux Shell [`gfs_pipeline.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_2/gfs_pipeline.sh) and Windows Powershell [`gfs_pipeline.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_2/gfs_pipeline.ps1) that does the following:

*The WxData Function Handles all of these steps when prompted by the user*
1) Creates a Python 3.12 environment called `wx_env` and installs WxData via pip
2) Using the WxData CLI - downloads GFS data in parallel. We download various datasets from the GFS0P25 primary parameters & levels, GFS0P25 secondary parameters & levels and GFS0P50.
   - Since we download these datasets in parallel, we are also spreading out the network traffic between the 3 source servers (NCEP/NOMADS, Amazon Web Services and Google Cloud) to minimize the number of requests on each source server to prevent temporary rate-limit bans.
3) Subset the GFS data for CONUS.
4) Decode the GRIB2 keys into plain-language.
5) Convert from GRIB2 to NETCDF.
6) Export the NETCDF data as a `.nc` file.

**Example 3**

In Example 3 we create a pipeline in both Linux Shell [`gfs_pipeline.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_3/gfs_pipeline.sh) and Windows Powershell [`gfs_pipeline.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_3/gfs_pipeline.ps1) that does the following:

1) Creates a Python 3.12 environment called `gfs_pipeline` and installs WxData via conda-forge.
2) Executes a Python Wrapper Script [`wrapper.py`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_3/wrapper.py)
   - This wrapper script uses `run_external_scripts()` from WxData.
3) This Python wrapper script `wrapper.py` then executes two downstream Python scripts in the following order:

   i) [`download_gfs.py`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_3/download_gfs.py) which uses WxData to download the latest GFS0P25 850mb Temperature Forecast.
   
   ii) [`gfs_graphics.py`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_3/gfs_graphics.py) which creates [graphics](https://github.com/edrewitz/WxData-Shell/tree/main/Example_3/GFS%20850mb%20Temperature%20Forecast) of the GFS0P25 850mb Temperature Forecast for CONUS. 

**Example 4**

In Example 4 we create automated ETL pipelines in both Linux Shell [`gfs_pipeline_with_proxy.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_4/gfs_pipeline_with_proxy.sh) and Windows Powershell [`gfs_pipeline_with_proxy.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_4/gfs_pipeline_with_proxy.ps1) does the following:

1) Creates a Python 3.12 environment called `wx_env` and installs WxData via pip.
2) Using the WxData CLI - Downloads GFS data in parallel using a proxy server `https://proxy-address:proxy-port`. We download various datasets from the GFS0P25 primary parameters & levels, GFS0P25 secondary parameters & levels and GFS0P50.

   - Since we download these datasets in parallel, we are also spreading out the network traffic between the 3 source servers (NCEP/NOMADS, Amazon Web Services and Google Cloud) to minimize the number of requests on each source server to prevent temporary rate-limit bans.
3) Subset the GFS data for CONUS.
4) Decode the GRIB2 keys into plain-language.
5) Convert from GRIB2 to NETCDF.
6) Export the NETCDF data as a `.nc` file.

**Example 5**

In Example 5 we create automated ETL pipelines in both Linux Shell [`ecmwf_pipeline.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_5/ecmwf_pipeline.sh) and Windows Powershell [`ecmwf_pipeline.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_5/ecmwf_pipeline.ps1) that does the following:

1) Creates a Python 3.14 environment called `ecmwf_gph` and installs WxData via pip.
2) Using the WxData CLI - downloads the ECMWF IFS and ECMWF AIFS 500mb Geopotential Height Forecast for the first 144 hours in parallel.
   - Since we download these datasets in parallel, we are also spreading out the network traffic between different source servers. There are 3 available source servers for ECMWF data (ECMWF Open-Data, Amazon Web Services and Google Cloud). In this example, download the ECMWF IFS forecast from ECMWF Open-Data and ECMWF AIFS forecast from Google Cloud.

*For Both ECMWF IFS & ECMWF AIFS*

3) Subset the ECMWF 500mb Geopotential Height forecast data for Europe.
   
4) Decode the GRIB2 keys into plain-language.
   
5) Convert from GRIB2 to NETCDF.
   
6) Export the NETCDF data as a `.nc` file.

7) Executes a Python script [`ecmwf_500mb_gph.py`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_5/ecmwf_500mb_gph.py) that finds and creates [graphics](https://github.com/edrewitz/WxData-Shell/tree/main/Example_5/ECMWF%20IFS%20%2B%20AIFS%20500%20MB%20Mean%20Geopotential%20Height) of the ECMWF IFS + AIFS Mean 500mb Geopotential Height Forecast for Europe. 

**Example 6**

In Example 6 we create automated ETL pipelines in both Linux Shell [`weather_data_pipeline.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_6/weather_data_pipeline.sh) and Windows Powershell [`weather_data_pipeline.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_6/weather_data_pipeline.ps1) that does the following:

1) Creates a Python 3.14 environment called `wx_pipeline` and installs WxData via pip.
2) Using the WxData CLI - downloads the 2-meter temperature forecast for the following weather forecast models in parallel from the following source servers:

     *When doing bulk-data downloads it is good practice to spread out the traffic between multiple source servers if possible. This prevents temporary rate-limit bans that could disrupt your automation.*
    
    - GFS0P25 - NCEP/NOMADS
    - ECMWF High Resolution IFS - ECMWF Open Data
    - ECMWF AIFS - Google Cloud
    - GDPS - MSC Open Data (There are no alternative source servers for Canadian data)

*For All Datasets*

3) Subset the 2-meter temperature forecast for CONUS.
   
4) Decode the GRIB2 keys into plain-language.
   
5) Convert from GRIB2 to NETCDF.
   
6) Export the NETCDF data as a `.nc` file.

**Example 7**

In Example 7 we create automated ETL pipelines in both Linux Shell [`get_upper_air.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_7/get_upper_air.sh) and Windows Powershell [`get_upper_air.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_7/get_upper_air.ps1) that does the following:

1) Creates a Python 3.14 environment called `soundings` and installs WxData via pip
2) Using the WxData CLI - downloads the latest observed upper-air sounding data from University of Wyoming for San Diego, CA (NKX), Upton, NY (OKX) and Norman, OK (OUN) as `.csv` files to our current working directory. 

**Example 8**

In Example 8 we create automated ETL pipelines in both Linux Shell [`get_current_nexrad2.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_8/get_current_nexrad2.sh) [`get_archived_nexrad2.sh`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_8/get_archived_nexrad2.sh) and Windows Powershell [`get_current_nexrad2.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_8/get_current_nexrad2.ps1) [`get_archived_nexrad2.ps1`](https://github.com/edrewitz/WxData-Shell/blob/main/Example_8/get_archived_nexrad2.ps1) that does the following:

1) Creates a Python 3.14 environment `current_radar` or `archive_radar` depending on current or archived and installs WxData via pip.
2) Using the WxData CLI - downloads the NEXRAD II radar data for Upton, NY (KOKX). The archived data is for the starting point of `2025-12-25:18`. Both datasets go 4-hours back from the starting point. 




