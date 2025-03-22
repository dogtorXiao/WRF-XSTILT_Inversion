import xarray as xr
import pandas as pd

def extract_grid_data(nc_file, lon_range, lat_range, variable):
    """
    提取指定范围内的格点数据，并将经纬度和数据整合到一个数据框中。

    参数:
        nc_file (str): netCDF文件路径。
        lon_range (tuple): 经度范围，形式为（最小经度，最大经度）。
        lat_range (tuple): 纬度范围，形式为（最小纬度，最大纬度）。

    返回:
        pandas.DataFrame: 包含经纬度和数据的数据框。
    """
    # 读取netCDF文件
    ds = xr.open_dataset(nc_file)

    # 将纬度从大到小排列
    ds = ds.sortby('lat', ascending=False)

    if 'time' in ds.dims:
        ds = ds.sel(time=ds['time'].values[0])
    # 提取指定范围内的格点数据
    data_subset = ds.sel(lon=slice(lon_range[0], lon_range[1]), lat=slice(lat_range[0], lat_range[1]))

    # 将数据转换为DataFrame
    df = data_subset.to_dataframe().reset_index()

    # 保留经纬度和数据列
    df = df[['lon', 'lat', variable]]

    return df
