#' calc how many minutes for a case to run from the furthest pixel to the pp
#' @author DogtorX

hours_xstilt_run = function(store_path, site_lon_lat, emiss_res){

    library(dplyr)
    library(ggplot2)

    half_res = emiss_res/2

    traj.path = list.files(store_path, 'out_20', full.names = T)
    byid.path = file.path(traj.path, 'by-id')
    traj.fns  = list.files(byid.path, 'X_traj.rds', full.names = T, recursive = T)

    hrs = NULL
    for (i in 1:length(traj.fns)){
        print(i)
        df = readRDS(traj.fns[i])$particle %>% filter(long<site_lon_lat[1]+half_res & long>site_lon_lat[1]-half_res & lati<site_lon_lat[2]+half_res & lati>site_lon_lat[2]-half_res)
        df_sum <- df %>% 
        group_by(time) %>%
        summarise(total_foot = sum(foot))
        hrs = c(hrs, df_sum$time[nrow(df_sum)])
    }
    print(paste('the longest trajectory time is ',min(hrs)))

}