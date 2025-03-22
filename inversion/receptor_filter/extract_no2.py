#' extract NO2 info around pp
#' @author DogtorX

import netCDF4 as nc
import pandas as pd
from matplotlib.path import Path
import os, sys
import glob
import numpy as np

timestr       = str(sys.argv[1])
trp_path      = str(sys.argv[2])             
NO2_save_path = str(sys.argv[3])          
site_lon      = float(sys.argv[4])
site_lat      = float(sys.argv[5])
buff_deg      = float(sys.argv[6])               

YYYYMMDD = timestr[0:8]
# define the polygon vertex
polygon = Path([(site_lon - buff_deg, site_lat - buff_deg), (site_lon - buff_deg, site_lat + buff_deg), (site_lon + buff_deg, site_lat + buff_deg), (site_lon + buff_deg,site_lat - buff_deg)]) 

pattern = os.path.join(trp_path, '*{}*'.format(YYYYMMDD))  
TROPOMI_file = glob.glob(pattern)

if os.path.exists(NO2_save_path+'/'+YYYYMMDD):
    print(f"'{NO2_save_path+'/'+YYYYMMDD}' exists.")
else:
    os.system(" mkdir -p "+NO2_save_path+'/'+YYYYMMDD)

dataset = nc.Dataset(TROPOMI_file[0])

lat_bounds = dataset['PRODUCT']['SUPPORT_DATA']['GEOLOCATIONS']['latitude_bounds'][0]
lon_bounds = dataset['PRODUCT']['SUPPORT_DATA']['GEOLOCATIONS']['longitude_bounds'][0]
latitude = dataset['PRODUCT']['latitude'][0]
longitude = dataset['PRODUCT']['longitude'][0]
no2_values = dataset['PRODUCT']['nitrogendioxide_tropospheric_column'][0]

selected_pixels = []

for i in range(np.shape(longitude)[0]):
    for j in range(np.shape(longitude)[1]):
        if polygon.contains_point((longitude[i][j], latitude[i][j])):
            selected_pixels.append({
                'latitude': latitude[i][j],
                'longitude': longitude[i][j],
                'no2': no2_values[i][j],
                'lat1': lat_bounds[i][j][0],
                'lat2': lat_bounds[i][j][1],
                'lat3': lat_bounds[i][j][2],
                'lat4': lat_bounds[i][j][3],
                'lon1': lon_bounds[i][j][0],
                'lon2': lon_bounds[i][j][1],
                'lon3': lon_bounds[i][j][2],
                'lon4': lon_bounds[i][j][3]
            })

df = pd.DataFrame(selected_pixels)
df.to_csv(NO2_save_path+'/'+YYYYMMDD+'/NO2_data.csv', index=False)
