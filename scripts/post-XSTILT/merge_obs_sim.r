#' merge the obs, obs_uncert and sim ff.xco2 together
#'@author DogtorX'

merge_obs_sim = function(xstilt_wd, bg, bg_uncert, OCO3_data_file){

    library(dplyr)

    xstilt.out = file.path(xstilt_wd, 'XSTILT_output')
    sim_file = file.path(xstilt.out, 'ff.xco2.csv')

    sim = read.csv(sim_file)
    obs = read.csv(OCO3_data_file)
    sim = sim %>% mutate(across(where(is.numeric), ~ round(.x, 6)))
    obs = obs %>% mutate(across(where(is.numeric), ~ round(.x, 6)))
    save_file = file.path(xstilt.out, 'sim.obs.xco2.csv')
    save = sim %>% inner_join(obs, by = c("lon", "lat")) # attach obs and obs_uncert after the sim, comment out if you have done it

    save$obs_enhance = save$obs - bg
    save$uncert_bg = rep(bg_uncert, times = nrow(save))
    write.csv(save, save_file ,row.names = FALSE)
}
