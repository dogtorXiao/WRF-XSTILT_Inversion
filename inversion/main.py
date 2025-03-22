#' Bayesian inversion wrapping all data
#' @author DogtorX

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import sys, os
from pathlib import Path

inversion_function_path = sys.argv[1]
sys.path.append(str(Path(inversion_function_path).resolve()))

from geo_data_extraction import extract_grid_data
from spatial_covariance_matrix import calculate_spatial_covariance_matrix
from process_files import extract_file_info
from filter_matching import filter_matching_coordinates

# inversion config
spriorisf           = float(sys.argv[2])
length_scale_priori = float(sys.argv[3])
length_scale_obs    = float(sys.argv[4])
site_lon_lat        = [float(sys.argv[5]), float(sys.argv[6])]
domain_opt_deg      = float(sys.argv[7])

byid_path           = sys.argv[8] 
sim_all_file        = sys.argv[9] 
emiss_file          = sys.argv[10] 
inversion_save_path = sys.argv[11] 
inversion_save_file = inversion_save_path+'/pp_posterier.csv' 
inversion_recp      = sys.argv[12]
bg                  = float(sys.argv[13])
bg_uncert           = float(sys.argv[14])

sim_all             = pd.read_csv(sim_all_file)
receptor            = pd.read_csv(inversion_recp)
receptor            = receptor.rename(columns={'lati': 'lat', 'long': 'lon'})
sim_all             = filter_matching_coordinates(sim_all, receptor)

if not os.path.exists(inversion_save_path):
    # 创建目录
    os.makedirs(inversion_save_path)

lon_range           = (site_lon_lat[0]-domain_opt_deg, site_lon_lat[0]+domain_opt_deg)
lat_range           = (site_lon_lat[1]+domain_opt_deg, site_lon_lat[1]-domain_opt_deg)

'''generate spriori diag matrix'''
print('######## spriori ########')
# 调用 extract_grid_data 函数
df_priori = extract_grid_data(emiss_file, lon_range, lat_range, 'emiss')
# 查看数据框
print(df_priori)
spriori = np.array(df_priori['emiss']).reshape(-1, 1)

'''generate sigma array as prior uncertainty'''
print('######## sigma ########')
sigma = spriorisf * np.diag(spriori.ravel())

'''extract obs data and uncertainty'''
print('######## read the obs enhancement and obs uncert ########')
y            = np.array(sim_all['obs_enhance']).reshape(-1, 1)
uncert_total = np.diag(sim_all['uncert_total'])

'''use extract function to generate the adjoint matrix'''
print('######## adjoint  ########')
df_files = extract_file_info(byid_path)
df_filtered = filter_matching_coordinates(df_files, receptor)

H = []
for i in range(len(df_filtered)):

    foot = extract_grid_data(df_filtered['file_path'][i], lon_range, lat_range, 'foot')
    new_foot = np.array(foot['foot']).reshape(1, -1)
    H.append(new_foot)

H = np.vstack(H)
# print(H)

'''generate prior uncertainty cov matrix'''
print('######## apriori covirance ########')
B_cov = calculate_spatial_covariance_matrix(df_priori, length_scale_priori)
B = np.dot( np.dot(sigma, B_cov), sigma)
print(B)

print('######## transport covirances ########')
R_cov = calculate_spatial_covariance_matrix(sim_all, length_scale_obs)
R = np.dot( np.dot(uncert_total, R_cov), uncert_total)
print(R)

print('######## posterior ########')

HBT      = np.transpose( np.dot(H, B) )
HBHTR    = np.dot( np.dot(H,B), np.transpose(H)) + R
HBHTRinv = np.linalg.inv(HBHTR)
yHsp     = y - np.dot(H,spriori)

s_hat              = spriori + np.dot( np.dot(HBT, HBHTRinv), yHsp)
df_priori['s_hat'] = s_hat
# print('pp post is '+str(int(np.max(s_hat))))
# indx               = np.where(s_hat == np.max(s_hat))[0]

print('######## posterior uncertainty ########')

HB       = np.dot(H, B)
V_hat    = B - np.dot( np.dot(HBT, HBHTRinv), HB)
df_priori['uncert_hat'] = np.sqrt(np.diag(V_hat))
# df_priori.to_csv(inversion_save_file,sep=',',index=0, header=1)
# print('pp post uncert is '+str(int(np.sqrt(np.diag(V_hat))[indx])))

# function calc the distance between 2 sites
def haversine(lon1, lat1, lon2, lat2):
    # convert lon_lat to rad
    lon1, lat1, lon2, lat2 = map(np.radians, [lon1, lat1, lon2, lat2])

    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2)**2
    c = 2 * np.arcsin(np.sqrt(a))
    r = 6371 
    return c * r

# calc distance between every row and the pp
df_priori['distance'] = df_priori.apply(lambda row: haversine(site_lon_lat[0], site_lon_lat[1], row['lon'], row['lat']), axis=1)

# select the most nearby 20s
nearest_estimate = df_priori.nsmallest(20, 'distance')
pp_poster_row    = nearest_estimate.nlargest(1,'s_hat')

'''计算reduced chi-squared'''

# print('######## reduced chi-squared ########')

# nu       = len(df_filtered)
# yHs_hat  = y - np.dot(H,s_hat)
# reduced_chi = (np.dot( np.dot( np.transpose(yHs_hat), np.linalg.inv(R) ), yHs_hat) + np.dot( np.dot( np.transpose(s_hat - spriori), np.linalg.inv(B) ), s_hat - spriori)) / nu
# print('reduced chi is '+str(int(reduced_chi)))

pp_poster_row['spriorisf'] = spriorisf
pp_poster_row['length_scale_priori'] = length_scale_priori
pp_poster_row['length_scale_obs'] = length_scale_obs
# pp_poster_row['reduced_chi_sq'] = reduced_chi

pp_poster_row = pp_poster_row.drop('distance', axis=1)
pp_poster_row['bg'] = bg
pp_poster_row['bg_uncert'] = bg_uncert
if os.path.exists(inversion_save_file):
    poster_data = pd.read_csv(inversion_save_file)
    poster_data = poster_data.append(pp_poster_row, ignore_index=True)
    poster_data.to_csv(inversion_save_file,sep=',',index=0, header=1)
else:
    pp_poster_row.to_csv(inversion_save_file,sep=',',index=0, header=1)

print('********** done *********')