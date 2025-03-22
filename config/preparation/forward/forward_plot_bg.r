#' forward plotting
#' @author DogtorX

forward_plot_bg = function(namelist){

    xstilt_wd     = namelist$xstilt_wd
    site          = namelist$site
    site_lon_lat  = namelist$site_lon_lat
    timestr       = namelist$timestr
    data_path     = namelist$data_path
    oco_path      = namelist$oco_path
    store_path    = namelist$store_path
    met           = namelist$met

    dlon      = 1      # e.g., dlon = 0.5 means 1 x 1 degree box around the site
    dlat      = 1      # dlat/dlon in degrees 

    # ----------- Dependencies and API key for geolocation (must-have) ---------- #
    setwd(xstilt_wd); source('r/dependencies.r')
    api.key = readLines('insert_ggAPI.csv')

    lon_lat = get.lon.lat(site, dlon, dlat, site.loc = data.frame(lon = site_lon_lat[1] , lat = site_lon_lat[2] ))

    #------------------------------ STEP 1 --------------------------------------- #

    # time string in format of YYYYMMDDHH or YYYYMMDD, can be a vector
    # If HH is NOT provided, one can provide the satellite path/file
    # inner function will automatically look for overpass HH
    all_timestr = c(timestr)
    sensor      = 'OCO-3'
    sensor_gas  = 'CO2'
    sensor_ver  = 'V10r'
    trp_path    = file.path(data_path, sensor, sensor_gas)
    sensor_path = ifelse(sensor == 'TROPOMI', trp_path, oco_path)
    raob_path   = file.path(data_path, 'RAOB', site)    # path for radiosonde data

    # --------------------------------- STEP 2 ----------------------------------- #
    run_trajec   = F 
    run_bg       = T
    run_hor_err  = F            # T: run trajec with horizontal wind errors 
    run_ver_err  = F            # T: run trajec with mixed layer height scaling
    run_wind_err = F            # T: run the wind error estimates using RAOB
                                # F: use the prescribed wind RMSE in m s-1, see siguverr
    siguverr     = 3            # if run_wind_err == F, specify wind RMSE value, m s-1

    # -------------------------------- STEP 3 ------------------------------------ #
    #' @param for calculating background based on 2D kernel density 
    # threshold for outmost boundary of modeled urban plume (smaller td, more outwards)
    td      = namelist$td                            # range from 0.1 to 1 
    bg_deg = 0.3                            # buffer for bg region, in deg-lat
    bin_deg = 0.2                            # buffer for bg region, in deg-lon
    zoom    = 8                              # zoom for plotting ggmap, see ggmap()
    writeTF = T                              # T: output bg info to txt file
    qfTF    = T                              # T: use screened obs; F: use all obs
    sensor_qa = 0.5                          # quality assurance for TROPOMI, QA > 0.5
    rm_outlierTF = T                         #I don't know what it is but to match the parameters in calc.bg.forward

    if (run_trajec == F & run_bg) {         # need forward trajec ready

        bg_df = NULL
        for ( tt in 1 : length(all_timestr) ) {            # loop over each overpass
            timestr = all_timestr[tt]
            tmp_df = calc.bg.forward.trajec(site, timestr, sensor, sensor_path, 
                                            sensor_gas, sensor_ver, sensor_qa, qfTF, store_path, 
                                            met, td, bg_deg, bin_deg, zoom, rm_outlierTF, api.key)
            if ( is.null(tmp_df) ) next
            bg_df = rbind(bg_df, tmp_df)
        }   # end for tt

        if (writeTF) {
            if ( grepl('OCO', sensor) ) {           # label qfTF for OCO
                fn = paste0('bg_', site, '_', sensor, '_', sensor_gas, '_qf', qfTF, '.txt')
            } else if (sensor == 'TROPOMI') {       # label qa for TROPOMI
                fn = paste0('bg_', site, '_', sensor, '_', sensor_gas, '_qa', sensor_qa, '.txt')
            } else stop('Invalid sensor names...\n'); print(fn)

            write.table(bg_df, file.path(store_path, fn), quote = F, row.names = F, sep = ',')
        }   # end if writeTF
    }   # end if run_bg

}
