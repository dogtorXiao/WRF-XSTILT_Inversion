extract.all.data_plot = function(YYYYMMDD, zoom, height, mismatch_limit, key){

    library(ggplot2)
    library(dplyr)
    library(ggmap)
    library(lubridate)
    library(grDevices) #绘图颜色相关
    library(RColorBrewer)#绘图颜色相关
    # library(directlabels) #等高线相关
    library(reshape2)
    library(patchwork)

    source('src/plot_compare.r')

    register_google(key = key)

    xstilt.out = file.path('DataFigures', YYYYMMDD)

    df1.file = file.path(xstilt.out, 'sim_all.csv')
    df2.file = paste0(xstilt.out, '/receptor.csv')
    df1 = read.csv(df1.file)
    df2 = read.csv(df2.file)
    data = semi_join(df1, df2, by = c("lon", "lat"))

    pic_name = paste0(xstilt.out, '/OCO3-filtered.png')

    plot_mismatch(data, pic_name, zoom, height, mismatch_limit)
}