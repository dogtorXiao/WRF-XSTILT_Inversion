#' run xstilt with different zisf and generate footprints
#' @author DogtorX'

run_vertical_loop = function(namelist){

  zisf         = namelist$zisf
  xstilt_wd    = namelist$xstilt_wd
  site         = namelist$site
  site_lon_lat = namelist$site_lon_lat
  met_path     = namelist$met_path
  data_path    = namelist$data_path
  recp_fn      = namelist$recp_fn
  timestr      = namelist$timestr  #'2021061809'
  nhrs         = namelist$nhrs
  met          = namelist$met
  met_file_format = namelist$met_file_format
  slurm        = namelist$slurm
  n_nodes      = namelist$n_nodes
  n_cores      = namelist$n_cores
  timeout      = namelist$timeout
  job_time     = namelist$job_time
  slurm_account   = namelist$slurm_account
  slurm_partition = namelist$slurm_partition
  mem_per_core    = namelist$mem_per_core
  mem_per_node    = namelist$mem_per_node
  minagl          = namelist$minagl               
  maxagl          = namelist$maxagl          
  numpar          = namelist$numpar
  foot_res        = namelist$foot_res

  # ----------- Dependencies and API key for geolocation (must-have) ---------- #
  setwd(xstilt_wd); source('r/dependencies.r')
  api.key = readLines('insert_ggAPI.csv')

  # --------------------- Site location params (must-have) --------------------- #
  nf_dlon = 0.3
  nf_dlat = 0.3
  dlon    = 1
  dlat    = 1
  lon_lat = get.lon.lat(site, dlon, dlat, site.loc = data.frame(lon = site_lon_lat[1] , lat = site_lon_lat[2] ))

  # ------------------------ I/O params (must-have) --------------------------- #

  store_path = file.path(xstilt_wd, paste0('XSTILT_output_ver_',zisf))
  obs_sensor  = obs_ver = obs_species = obs_path = sif_path = NA
  # obs_sensor  = c('OCO-2', 'OCO-3', 'TROPOMI', NA)[4]
  # obs_ver     = c('V10r', 'V10p4r', NA)[1]              # retrieval algo ver if applicable
  # obs_species = c('CO2', 'CO', 'NO2', 'CH4')[1]   # only allow 1 species at 1 time

  # (optional) paths for radiosonde (for transport error analysis) and ODIAC ----
  raob_path = file.path(data_path,'RAOB')         # NOAA radiosonde
  raob_fn   = list.files(raob_path, '.tmp', full.names = T)
  odiac_ver = c('2019', '2020')[2]                             # ODIAC version
  odiac_path = file.path(data_path, 'ODIAC/v2020b/1km/2019')

  # ---------------------- obtaining overpass time string --------------------- #

  cat('Done with choosing cities & overpasses...\n')

  # --------------------- Basis X-STILT flags (must-have) --------------------- #
  run_trajec    = T    # if to generate trajec; T: may overwrite existing trajec
  run_foot      = T    # if to generate footprint
  run_hor_err   = F    # T: set error parameters
  run_ver_err   = T    # T: set error parameters
  run_emiss_err = F    # T: get XCO2 error due to prior emiss err
  run_wind_err  = F    # T: calc wind error based on RAOB 
  run_sim       = F    # T: calc XFF or error with existing foot (only for CO2)

  # output variable names required in trajec.rds
  varstrajec = c('time', 'indx', 'lati', 'long', 'zagl', 'zsfc', 'foot', 'samt',
                  'dmas', 'mlht', 'temz', 'pres', 'sigw', 'tlgr', 'dens', 'sphu')

  # ------------------- ARL format meteo params (must-have) -------------------- #
  # see STILTv2 https://uataq.github.io/stilt/#/configuration?id=meteorological-data-input
  # met_path = file.path(metpath, met)               # path of met fields
  n_met_min = 1                                    # min number of files needed
  
  # ------- Transport error params (only needed for CO2 error, OPTIONAL) ------- #
  # if run_hor_err = T, require ODIAC and CT fluxes and mole fractions
  # to calculate horizontal transport error of total CO2, DW, 07/28/2018
  if (run_hor_err) {
    ct_ver      = ifelse(substr(timestr, 1, 4) >= '2016', 'v2017', 'v2016-1')
    ct_path     = file.path(data_path, 'CT-NRT') 
    ctflux_path = file.path(ct_path, 'flux/daily', month)
    ctmole_path = file.path(ct_path, 'molefractions_co2_total', month)
  } else ct_ver = ctflux_path = ctmole_path = NA       # end if run_hor_err

  # if run_emiss_err = T, calculating XCO2 error due to emiss error, 
  # need EDGAR and FFDAS files to compute emission spread, DW, 10/21/2018
  if (run_emiss_err) { 
    edgar_file = file.path(data_path, 'EDGAR/v6.0_CO2_excl_short-cycle_org_C_2018_TOTALS.0.1x0.1.nc')
    ffdas_path = file.path(data_path, 'FFDAS')
    ffdas_file = list.files(ffdas_path, 'flux')
    ffdas_file = file.path(ffdas_path, ffdas_file[grep('2015', ffdas_file)])
  } else edgar_file = ffdas_file = NA                   # end if run_emiss_err

  # Receptor selection (params are set as NA for ideal sim) ---------------------
  # T: create receptors within each satellite sounding besides centered lats/lons
  # F: place receptors ONLY at the centered lat/lon of a sounding, DW, 07/02/2021
  jitterTF   = FALSE            # T: works better for TROPOMI with larger polygons
  num_jitter = 5                # number of additional receptors per sounding

  #' Only place receptors for soundings that qualify @param obs_filter
  #' here are some choices for OCO-2/3 and TROPOMI (uncomment the one you need)
  #obs_filter = c('QF', 0)             # select OCO soundings with QF = 0
  obs_filter = c('QA', 0.5)            # select TROPOMI soundings with QA >= 0.5 
  #obs_filter = NULL                   # use all soundings regardless of QF or QA

  #' evenly select soundings within near-field or far-field (background) regions
  #' near-field: defined by @param nf_dlat & @param nf_dlon 
  #' far-field: defined by @param dlat & @param dlon except for near-field region
  # num of soundings/receptors along lat or lon within farfield or nearfield
  # if ALL are NA - NO need to select soundings (see github README for more clues)
  num_bg_lat = num_bg_lon = num_nf_lat = num_nf_lon = NA                
  #num_bg_lat = 5; num_bg_lon = 5; num_nf_lat = 10; num_nf_lon = 10

  # ------------------- ARL format meteo params (must-have) -------------------- #
  # OPTION for subseting met fields if met_subgrid_enable is on, 
  # useful for large met fields like GFS or HRRR
  met_subgrid_buffer = 0.1   # Percent to extend footprint area for met subdomain
  met_subgrid_enable = F    

  # if set, extracts the defined number of vertical levels from the 
  # meteorological data files to further accelerate simulations, default is NA
  met_subgrid_levels = NA    
  cat('Done with params for receptor and meteo- setup...\n')

  # -------------------- Footprint params (must-have) ------------------------- #
  # whether weight footprint by AK and PW for column simulations 
  # if F, AK = 1; if T, look for AK at the closest sounding from real data
  ak_wgt  = TRUE         # *** if obs_sensor is NA, ak_wgt is forced as FALSE 
  pwf_wgt = TRUE
  if (is.na(obs_sensor)) ak_wgt = FALSE 

  # footprint spatial domain defined as site.lat +/- foot_dlat and 
  # site.lon +/- foot_dlon in degrees, 10 here meaning 20 x 20deg box around site
  foot_dlat = 10     
  foot_dlon = 10 

  # ---------------------------------------------------------------------------- #
  # *** You can run multiple sets of footprints with different spatiotemporal 
  #     resolution from the same trajec at one time (see below), DW, 07/01/2021
  #' @param MAIN_RUN (e.g., 1km time-integrated footprint) -----------------------
  foot_nhrs = nhrs        # if foot_nhrs < nhrs, subset trajec before footprint
  time_integrate = TRUE   # F: hourly foot; T: time-integrated foot

  #' @param OPTIONAL_RUN with diff configurations (e.g., hourly 0.05 deg foot) ---
  #' both params can be a vector, footprint filename contains res info
  #' if no need for alternative runs, set @param foot_res to NA, DW, 02/11/2019
  foot_res2 = c(NA, 1/10, 1/20, 1)[3]     # spatial res in degree
  time_integrate2 = FALSE                 # ndim(time_integrate2) = ndim(foot_res2)

  # ---------------------------------------------------------------------------- #
  # other neccesary footprint params using STILTv2 (Fasoli et al., 2018)
  hnf_plume     = TRUE                # T: hyper near-field (HNP) for mixing hgts
  smooth_factor = 1                   # Gaussian smooth factor, 0 to disable
  projection    = '+proj=longlat'
  cat('Done with params for error analysis and footprint setup...\n')
  # ---------------------------------------------------------------------------- #


  #---------------------no need to change--------------------------------------- #
  # namelist required for generating trajec
  namelist = list(ak_wgt = ak_wgt, ct_ver = ct_ver, ctflux_path = ctflux_path, 
                  ctmole_path = ctmole_path, edgar_file = edgar_file, 
                  ffdas_file = ffdas_file, foot_res = foot_res, 
                  foot_res2 = list(foot_res2), foot_nhrs = foot_nhrs, 
                  foot_dlat = foot_dlat, foot_dlon = foot_dlon, 
                  hnf_plume = hnf_plume, jitterTF = jitterTF, 
                  job_time = job_time, lon_lat = list(lon_lat), 
                  mem_per_node = mem_per_node, met = met,                 
                  met_file_format = met_file_format, met_path = met_path, 
                  met_subgrid_buffer = met_subgrid_buffer, 
                  met_subgrid_enable = met_subgrid_enable, 
                  met_subgrid_levels = met_subgrid_levels, minagl = minagl, 
                  maxagl = maxagl, nhrs = nhrs, n_cores = n_cores, 
                  n_met_min = n_met_min, n_nodes = n_nodes, nf_dlat = nf_dlat, 
                  nf_dlon = nf_dlon, num_jitter = num_jitter, 
                  num_bg_lat = num_bg_lat, num_bg_lon = num_bg_lon, 
                  num_nf_lat = num_nf_lat, num_nf_lon = num_nf_lon, 
                  numpar = numpar, obs_filter = list(obs_filter),
                  obs_path = obs_path, obs_sensor = obs_sensor, 
                  obs_species = obs_species, odiac_path = odiac_path, 
                  odiac_ver = odiac_ver, projection = projection, 
                  pwf_wgt = pwf_wgt, raob_fn = raob_fn, recp_fn = recp_fn, 
                  run_emiss_err = run_emiss_err, run_foot = run_foot, 
                  run_hor_err = run_hor_err, run_sim = run_sim, 
                  run_trajec = run_trajec, run_ver_err = run_ver_err, 
                  run_wind_err = run_wind_err, site = site, slurm = slurm, 
                  slurm_account = slurm_account,slurm_partition = slurm_partition,
                  smooth_factor = smooth_factor, store_path = store_path, 
                  time_integrate = time_integrate, 
                  time_integrate2 = list(time_integrate2), 
                  timeout = timeout, timestr = timestr, varstrajec = varstrajec, 
                  xstilt_wd = xstilt_wd, zisf = zisf)
  cat('Done with creating namelist...\n')

  config_xstilt(namelist)  # start X-STILT, either calc traj, foot or simulation
  q('no')
  # end of main script
  # ---------------------------------------------------------------------------- #

}