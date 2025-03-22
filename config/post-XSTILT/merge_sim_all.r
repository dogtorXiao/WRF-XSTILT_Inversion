#' merge all the perturbed data
#'@author DogtorX'

merge_sim_all = function(xstilt_wd, output_dirs, standard_zisf){

    library(dplyr)

    xstilt.out = file.path(xstilt_wd, paste0('XSTILT_output'))
    save.file = file.path(xstilt.out, 'sim_all.csv')

    sim_all_file = file.path(xstilt.out, 'sim.obs.xco2.csv')
    sim_all = read.csv(sim_all_file)
    column = colnames(sim_all)
    output_dirs = output_dirs[output_dirs != standard_zisf]
    ver_name = c('ff.xco2', output_dirs)

    if (length(output_dirs)>0){

        for (i in 1:length(output_dirs)){

            ver_file = file.path(xstilt_wd, paste0('XSTILT_output_', output_dirs[i]), 'ff.xco2.csv')
            ver.data = read.csv(ver_file)
            sim_all = cbind(sim_all, c(ver.data$ff.xco2))
            column = c(column, output_dirs[i])
        }
    }

    wind_file = file.path(xstilt_wd, 'XSTILT_output_wind', 'ff.xco2.csv')
    wind.data = read.csv(wind_file)
    sim_all = cbind(sim_all, c(wind.data$ff.xco2))
    column = c(column, paste0('wind_ff.xco2'))
    
    colnames(sim_all) = column



    sim_all$uncert_ver          = apply(sim_all[, ver_name], 1, sd)
    sim_all$uncert_ver_percent  = sim_all$uncert_ver/sim_all$ff.xco2
    sim_all$uncert_wind         = apply(sim_all[, c('ff.xco2', 'wind_ff.xco2')], 1, sd)
    sim_all$uncert_wind_percent = sim_all$uncert_wind/sim_all$ff.xco2
    sim_all$uncert_trans        = sqrt(sim_all$uncert_ver*sim_all$uncert_ver + sim_all$uncert_wind*sim_all$uncert_wind)
    sim_all$uncert_trans_percent = sim_all$uncert_trans/sim_all$ff.xco2
    sim_all$uncert_total        = sqrt(sim_all$uncert_ver*sim_all$uncert_ver + sim_all$uncert_wind*sim_all$uncert_wind+sim_all$uncert*sim_all$uncert+sim_all$uncert_bg*sim_all$uncert_bg)
    sim_all$uncert_total_percent= sim_all$uncert_total/sim_all$ff.xco2

        # colnames(sim_all) = c(column, 'uncert_ver', 'uncert_ver_percent', 'uncert_wind', 'uncert_wind_percent', 'uncert_total', 'uncert_total_percent')
    

    write.csv(sim_all, save.file, row.names = FALSE)
}
