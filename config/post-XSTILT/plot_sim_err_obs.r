#'plot and compare'
#'@author DogtorX'

plot_sim_err_obs = function(xstilt_wd, key, site_lon_lat, spriorisf, zoom){

    library(dplyr)
    library(ggmap)
    library(ggplot2)
    library(lubridate)
    library(grDevices) #绘图颜色相关
    library(RColorBrewer)#绘图颜色相关
    # library(directlabels) #等高线相关
    library(reshape2)
    library(patchwork)

    # source('src/plot_compare.r')
    register_google(key = key)

    save.file = file.path(xstilt_wd, 'XSTILT_output','sim_all.csv')
    sim_all = read.csv(save.file)
    picpath = file.path(xstilt_wd, 'XSTILT_output', 'plot')
    if(!dir.exists(picpath)) dir.create(picpath) 

    print('start to plot...')
    pic_name_1 = file.path(xstilt_wd, 'XSTILT_output', 'plot', 'sim_obs_compare.png')
    pic_name_2 = file.path(xstilt_wd, 'XSTILT_output', 'plot', 'uncert_compare.png')
    pic_name_3 = file.path(xstilt_wd, 'XSTILT_output', 'plot', 'mismatch.png')
    # pic_name_4 = file.path(xstilt_wd, 'XSTILT_output', 'plot', 'ver_diff.png')
    plot_compare_obs_enhance(sim_all, pic_name_1, zoom, site_lon_lat)
    plot_compare_trans_obs_err(spriorisf, sim_all, pic_name_2, zoom, site_lon_lat)
    plot_mismatch(sim_all, pic_name_3, zoom, site_lon_lat)


}