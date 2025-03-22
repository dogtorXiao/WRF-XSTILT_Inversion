#' find the pixels in a sector area and write them into a csv file to
#' @author DogtorX

import warnings
warnings.filterwarnings("ignore")
import netCDF4 as nc
import numpy as np
import pandas as pd
import os, sys
from matplotlib.path import Path
import matplotlib.pyplot as plt
import matplotlib
from datetime import datetime, timedelta
import time

def str_to_bool(s):
    if s.lower() == 'true':
        return True
    elif s.lower() == 'false':
        return False
    else:
        raise ValueError("Cannot covert {} to a bool".format(s))

site                    = sys.argv[1]
timestr                 = sys.argv[2]
QF                      = str_to_bool(sys.argv[3]) 
NO2_segmentation_file   = sys.argv[4]
recp_fn_in_NO2          = sys.argv[5]
OCO3_data_in_NO2_file   = sys.argv[6]
OCO3_obs_file           = sys.argv[7]
fig_demo_in_NO2_file    = sys.argv[8]
site_lon                = float(sys.argv[9])
site_lat                = float(sys.argv[10])
bg_radius               = float(sys.argv[11])        # circle selected as the bg
bg_NO2_file             = sys.argv[12]

YYYYMN                  = timestr[0:6]
month                   = timestr[2:6]
date                    = timestr[4:8]

plume = pd.read_csv(NO2_segmentation_file)
domain_opt = []
for i in range(len(plume)):
    domain_opt.append((plume['lon'][i],plume['lat'][i]))

domain_opt = Path(domain_opt)

print('start...')

def start_end_time(timestr):
    time_dt = datetime.strptime(timestr, '%Y%m%d%H')
    time_dt_plus_one_hour = time_dt + timedelta(hours=1)
    time_dt_minus_one_hour = time_dt - timedelta(hours=1)

    return time_dt_minus_one_hour, time_dt_plus_one_hour

start, end = start_end_time(timestr)


def get_data(OCO3_obs_file):
    
    f = nc.Dataset(OCO3_obs_file)
    time = np.array(f.variables["time"])
    lat = np.round(np.array(f.variables["latitude"]),6)
    lon = np.round(np.array(f.variables["longitude"]),6)
    xco2 = np.array(f.variables["xco2"])
    qf = np.array(f.variables["xco2_quality_flag"])
    uncert = np.array(f.variables['xco2_uncertainty'])
    vertex_lat = np.array(f.variables["vertex_latitude"])
    vertex_lon = np.array(f.variables["vertex_longitude"])

    lat_lon_data = np.vstack((time, lon, lat, xco2, uncert, qf))
    lat_lon_data = lat_lon_data.transpose()
    lat_lon_data = pd.DataFrame(np.hstack((lat_lon_data, vertex_lat, vertex_lon)))
    lat_lon_data.columns = ['time', 'lon', 'lat', 'obs', 'uncert', 'qf', 'lat1', 'lat2', 'lat3', 'lat4', 'lon1', 'lon2', 'lon3', 'lon4']
    lat_lon_data['time'] = pd.to_datetime(lat_lon_data['time'], unit='s')
    lat_lon_data = lat_lon_data[(lat_lon_data['time'] >= start) & (lat_lon_data['time'] <= end)]
    lat_lon_data['time'] = lat_lon_data['time'].dt.strftime('%Y-%m-%d %H:%M:%S')
    lat_lon_data = lat_lon_data.round(6)
    
    return lat_lon_data

f_lat_lon_data = get_data(OCO3_obs_file)

circle_lat_lon_data = f_lat_lon_data[((f_lat_lon_data['lon'] - site_lon)**2 + (f_lat_lon_data['lat'] - site_lat)**2) < (bg_radius/100)**2]

def main():

    lat_lon_data = filter_pair(domain_opt, recp_fn_in_NO2, OCO3_data_in_NO2_file)
    merged = pd.merge(circle_lat_lon_data, lat_lon_data, 
                  how='outer', 
                  on=circle_lat_lon_data.columns.tolist(), 
                  indicator=True)
    bg_data = merged[merged['_merge'] == 'left_only'].drop(columns=['_merge'])
    print('The NO2_bg is '+str(np.mean(bg_data['obs']))+', the bg uncertainty is '+str(np.std(bg_data['obs'])))
    bg = {'NO2_bg':np.mean(bg_data['obs']), 'NO2_bg_sd':np.std(bg_data['obs'])}
    bg = pd.DataFrame([bg])
    bg.to_csv(bg_NO2_file, sep=',',index=0, header=1)
    pic_map(lat_lon_data, date, fig_demo_in_NO2_file)
    return 0

def filter_pair(domain_opt, recp_fn_in_NO2, OCO3_data_in_NO2_file):

    points = f_lat_lon_data[['lon', 'lat']].to_numpy()
    opt_indx = domain_opt.contains_points(points)
    lat_lon_data = f_lat_lon_data[opt_indx]
    if QF:
        lat_lon_data = lat_lon_data[lat_lon_data['qf']==0]

    lat_lon_data.to_csv(OCO3_data_in_NO2_file,sep=',',index=0, header=1)

    lat_lon = pd.DataFrame({'lati':lat_lon_data['lat'], 'long':lat_lon_data['lon']})
    lat_lon.to_csv(recp_fn_in_NO2,sep=',',index=0, header=1)

    return lat_lon_data


def pic_map(lat_lon_data, date, fig_demo_in_NO2_file):

    plt.figure()

    plt.scatter(lat_lon_data['lon'], lat_lon_data['lat'], c=lat_lon_data['obs'], cmap='viridis')
    plt.colorbar()
    plt.title(r'OCO-3 soundings, date={0}'.format(date))
    plt.xlabel('lontitude')
    plt.ylabel('latitude')
    plt.xticks(fontsize=10)
    plt.yticks(fontsize=10)

    plt.savefig(fig_demo_in_NO2_file)
    return 0

main()