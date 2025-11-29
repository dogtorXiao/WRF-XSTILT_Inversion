#' forward running xstilt
#' @author DogtorX

run_forward_xstilt = function(namelist){

    xstilt_wd     = namelist$xstilt_wd
    site          = namelist$site
    site_lon_lat  = namelist$site_lon_lat
    timestr       = namelist$timestr
    data_path     = namelist$data_path
    oco_path      = namelist$oco_path
    store_path    = namelist$store_path
    raob_path     = namelist$raob_path
    box.len       = namelist$box.len
    dtime.from    = namelist$dtime.from     
    dtime.to      = namelist$dtime.to   
    dtime.sep     = namelist$dtime.sep    
    nhrs          = namelist$nhrs
    met_path      = namelist$met_path
    met           = namelist$met
    met_res       = namelist$met_res   
    met_file_format = namelist$met_file_format
    job_time      = namelist$job_time
    n_cores       = namelist$n_cores
    slurm_account   = namelist$slurm_account
    slurm_partition = namelist$slurm_partition
    mem_per_core    = namelist$mem_per_core
    mem_per_node    = namelist$mem_per_node

    dlon      = 1      # e.g., dlon = 0.5 means 1 x 1 degree box around the site
    dlat      = 1      # dlat/dlon in degrees 

    # ----------- Dependencies and API key for geolocation (must-have) ---------- #
    setwd(xstilt_wd); source('r/dependencies.r')
    api.key = readLines('insert_ggAPI.csv')

    lon_lat = get.lon.lat(site, dlon, dlat, site.loc = data.frame(lon = site_lon_lat[1] , lat = site_lon_lat[2] ))

    site_lon  = lon_lat$site_lon
    site_lat  = lon_lat$site_lat

    #------------------------------ STEP 1 --------------------------------------- #
    # time string in format of YYYYMMDDHH or YYYYMMDD, can be a vector
    # If HH is NOT provided, one can provide the satellite path/file
    # inner function will automatically look for overpass HH
    all_timestr = c(timestr)
    sensor      = namelist$sensor
    sensor_gas  = namelist$sensor_gas
    sensor_ver  = namelist$sensor_ver
    trp_path    = file.path(data_path, sensor, sensor_gas)
    sensor_path = ifelse(sensor == 'TROPOMI', trp_path, oco_path)

    # --------------------------------- STEP 2 ----------------------------------- #
    run_trajec   = T
    run_bg       = F
    run_hor_err  = F            # T: run trajec with horizontal wind errors 
    run_ver_err  = F            # T: run trajec with mixed layer height scaling
    run_wind_err = F            # T: run the wind error estimates using RAOB
                                # F: use the prescribed wind RMSE in m s-1, see siguverr
    siguverr     = 3            # if run_wind_err == F, specify wind RMSE value, m s-1

    # set zisf = 1 if run_ver_err = F
    zisf = c(0.6, 0.8, 1.0, 1.2, 1.4)[3]; if (!run_ver_err) zisf = 1.0       

    # release particles from a box around the site -------------------------
    # dxyp: if > 0, randomized horizontal release locations for this receptor 
    #       (xp +/- dxyp, yp +/- dxyp instead of xp, yp) in units of x, y-grid lengths
    # Final box length = 2 * dxyp * met.res, DW, 06/30/2020
    # default box.len = 0.5 meaning 0.5 deg x 0.5 deg box around site
    # specify the desired box size for recp in deg 

    # release particles from fixed levels, recort particles for every 2mins
    delt   = 2          # in mins
    agl    = 10         # in mAGL, if for power plants, use stack height
    numpar = 1000       # particle # per each time window

    # meteo info ------------------------------------------------------------------
    # met_indx = 3
    # metdir   = '/home/d/dylan/dogtorx/sproject/GFSarl'
    # met      = c('gfs0p25', 'hrrr')[1]
    # met_res  = c(0.25, 0.027, 0.009)[met_indx]         # horizontal grid spacing ~in degree
    # met_path = file.path(metdir, month)
    # met_file_format = c('%Y%m%d', '%Y%m%d', '%Y%m%d')[met_indx]
    cat(paste('\n\nDone with settings with receptor and meteo fields...\n'))


    # -------------------------------- STEP 3 ------------------------------------ #
    if (run_trajec) {       # parallel running, DW, 11/06/2019

        slurm = T
        n_nodes = ceiling(length(all_timestr) / n_cores)
        #n_nodes = 1
        slurm_options = list(time = job_time, account = slurm_account, partition = slurm_partition)
        jobname = paste0(site, '_XSTILT_forward', '_', sensor)
        xstilt_apply(FUN = run.forward.trajec, slurm, slurm_options, n_nodes, n_cores, 
                    jobname, site, site_lon, site_lat, timestr = all_timestr, 
                    run_trajec, run_hor_err, run_wind_err, run_ver_err, xstilt_wd, 
                    store_path, box.len, dtime.from, dtime.to, dtime.sep, nhrs, delt, 
                    agl, numpar, met, met_res, met_file_format, met_path, raob_path, 
                    siguverr, nhrs.zisf = 24, zisf, sensor, sensor_path, sensor_gas)
        q('no')
    }   # end of running forward trajec

}