import pandas as pd

def filter_matching_coordinates(df_A, df_B):
    """
    筛选出数据框A中与数据框B匹配的'lon'和'lat'对。

    参数:
        df_A (pandas.DataFrame): 第一个数据框，包含'lon'和'lat'列。
        df_B (pandas.DataFrame): 第二个数据框，包含'lon'和'lat'列。

    返回:
        pandas.DataFrame: 包含匹配的'lon'和'lat'对的数据框A的子集并与B合并,按B的顺序排列
    """
    merged_df = pd.merge(df_B, df_A, on=["lon", "lat"], how="inner")

    return merged_df
