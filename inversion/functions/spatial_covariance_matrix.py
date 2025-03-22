import numpy as np
import pandas as pd
from haversine import haversine_vector, Unit

def calculate_spatial_covariance_matrix(df, L):
    """
    根据给定的经纬度数据框和特征长度计算归一化的协方差矩阵。

    参数:
        df (pandas.DataFrame): 包含经纬度的数据框。
        L (float): 特征长度。

    返回:
        numpy.ndarray: 归一化的协方差矩阵。
    """
    coords = df[['lat', 'lon']].values
    n = len(coords)
    
    # 计算距离矩阵
    distance_matrix = np.zeros((n, n))
    for i in range(n):
        rep = np.tile(coords[i], (len(coords), 1))
        distance_matrix[i, :] = haversine_vector(rep, coords, unit=Unit.METERS)
    
    # 计算协方差矩阵
    cov_matrix = np.exp(-distance_matrix / L)
    np.fill_diagonal(cov_matrix, 1)

    return cov_matrix

