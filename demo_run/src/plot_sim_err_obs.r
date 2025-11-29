### ### pre required: bio_ff_add_crop.py, foot_convolve.r for the all runnings, merge_obs_sim.r, merge_sim_all.r, OSSE_true_signal.r 
### after merge the obs and sim_all, plot what you want #######

plot_sim_err_obs = function(YYYYMMDD, zoom, height, sim_obs_limit, mismatch_limit, key){

    library(dplyr)
    library(ggmap)
    library(ggplot2)
    library(lubridate)
    library(grDevices) 
    library(RColorBrewer)
    # library(directlabels) 
    library(reshape2)
    library(patchwork)

    source('src/plot_compare.r')

    register_google(key = key)

    xstilt.out = file.path('DataFigures', YYYYMMDD)
    save.file = file.path(xstilt.out,'sim_all.csv')
    sim_all = read.csv(save.file)
    picpath = file.path(xstilt.out, 'plot')
    if(!dir.exists(picpath)) dir.create(picpath) 

    # plot the initial compare...

    print('start to plot...')
    pic_name_1 = file.path(xstilt.out, 'plot', 'sim_obs_compare.png')
    pic_name_2 = file.path(xstilt.out, 'plot', 'mismatch.png')
    plot_compare_obs_enhance(sim_all, pic_name_1, zoom, height, sim_obs_limit)
    plot_mismatch(sim_all, pic_name_2, zoom, height, mismatch_limit)

}
