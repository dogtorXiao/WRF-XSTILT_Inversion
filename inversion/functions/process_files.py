import os
import glob
import pandas as pd

def extract_file_info(folder_path):
    """
    从给定文件夹递归提取包含关键字'foot'的文件路径，并解析文件名生成数据框。

    参数:
        folder_path (str): 文件夹路径。

    返回:
        pandas.DataFrame: 包含文件路径、文件名分解和经纬度的数据框。
    """
    # 递归搜索文件夹并提取符合条件的文件路径
    search_pattern = os.path.join(folder_path, '**', '*_X_foot.nc')
    file_paths = glob.glob(search_pattern, recursive=True)

    # 创建一个包含文件路径的数据框
    df = pd.DataFrame(file_paths, columns=['file_path'])

    # 将文件名分解成不同的列
    df['file_name'] = df['file_path'].apply(lambda x: os.path.basename(x))
    df[['day', 'lon', 'lat', 'X', 'key']] = df['file_name'].str.split('_', expand=True)

    # 将'lon'和'lat'列转换为整数类型
    df['lon'] = df['lon'].astype(float)
    df['lat'] = df['lat'].astype(float)

    return df
