#' Set up the configuration for X-STILT & Bayesian inversion, only to optimize
#' high magnitude facility scale CO2 emission
#'
#' Main Steps
#' -----------------------------------------------------------------------------
#' A.  SHARED CONFIGURES

#' B.  PREPARATIONS
#' B1) FORWARD_RUN == T
#'     1) run_forward == T, run X-STILT forward function with d.from hours ahead
#'     of the overpass time(timestr), generate 3D trajectory and 2D footprint
#'     2) run_bg_xstilt == T, plot X-STILT trajectory kernel density with map
#'     and OCO-3 XCO2, calc the bg in different region
#'     3) run_seg == T, manually get the lon_lat information of the forward
#'     downwind domain, and select the OCO-3 data pixels inside the domain as 
#'     the main run receptors 
#' B2) SAMPLE_RUN == T (optional, but it helps to keep the PBLH more accurate
#'     and determine how long for main running)
#'     1) run_sample_xstilt == T, click a sample set of receptors, usually no
#'     more than the cores of one node. Generate X-STILT backward trajectories 
#'     with these receptors.
#'     2) run_PBL_nhrs_calc == T, calc the mean and sd of the PBLH in X-STILT,
#'     and calc the longest time of particles pass the point source.

#' C.  MAIN XSTILT
#'     MAIN_RUN == T, generate trajectories and footprint for inversion
#'     1) run_ver_main == T, run X-STILT backward with a scaling of the PBLH (depend 
#'     on the mean PBLH in last step and any available PBL observation data), and 
#'     run vertical error with perturbed scalings (running in ideal mode), using
#'     the receptors obtained in step A3
#'     2) run_wind_main == T, run X-STILT backward with wind error (using radiosonde
#'     data as another set of met data)

#' D.  POST DATA DEALING
#'     POST_RUN == T
#'     1) convolving the footprint from all runs (main, vertical error, wind error)
#'     with the ODIAC emission
#'     2) merge the observation and simulated data with uncertainties in one dataframe
#'     and plot

#' E.  INVERSION
#'     INVERSION_RUN == T
#'     1) run_no2_dealing == T(optional), extract and plot the TROPOMI NO2 plume, 
#'     manually get the plume lon_lat information, extract the OCO-3 pixels insie
#'     the plume
#'     2) run_inversion == T, inversion depends on the receptors chosen (main run 
#'     receptors or receptors in the NO2 plume), extract the pp information

#' @NOTE Do not run multiple X-STILT jobs at the same time
#' @NOTE Requires R and python in the same environment, with python GUI visualized 
#'       interactive interface
#' @author DogtorX

########################### A. SHARED CONFIGURES #################################

#=============================Running Settings====================================
source('source.r.functions.r')

xstilt_wd            = 'WRF-XSTILT-Inversion/X-STILT'
key                  = readLines(file.path(xstilt_wd, 'insert_ggAPI.csv'))

#=========================domain and time config==================================

site                 = 'belchatow'
site_lon_lat         = c(19.3259,51.2687)                                       # lon_lat of the point source, find it on the
                                                                                # map, it may be not totally consistent with the
                                                                                # inventory, make sure if it's neccessary to modify
timestr              = '2020040813'                                             # time string of the OCO-3 overpass
month                = substr(timestr,1,6)

#=================================I/O data========================================

# observation data path,include OCO-3, TROPOMI, ODIAC, radiosonde
data_path            = './data'

oco_path             = file.path(data_path, 'OCO-3', 'irregular', month)
sensor               = 'OCO-3'                                                  # X-STILT has functions for other satellites
sensor_gas           = 'CO2'                                                    # and other tracers, but for pp, we only use the 
                                                                                # OCO-3 and CO2 functions here
sensor_ver           = c('V10', 'V10r')[2]                                      # OCO-3 data version
trp_path             = file.path(data_path, 'TROPOMI_NO2')
raob_path            = file.path(data_path, 'RAOB', month)
raob_fn              = list.files(raob_path, '.tmp', full.names = T)

vname                = c('2020', '2020b', '2022')[2]                            # version of ODIAC
ODIAC_YYYY           = c('2019', '2020', '2021')[1]                             # the ODIAC data may not match the OCO data
                                                                                #' @NOTE ODIAC data version name is like 2020,
                                                                                # 2020b, while its data may be for 2019. Version
                                                                                # name doesn't mean data time. Please specify 
                                                                                # both of them here
tiff.path            = file.path(data_path, 'ODIAC', vname, '1km', ODIAC_YYYY)  # ODIAC data path

met_path             = './wrf_arl'                                              # arl format met path
met                  = c('gdas0p5', 'gfs0p25', 'WRF')[3]
met_res              = c(0.5, 0.25, 1/120)[3]                                   # horizontal grid spacing in degree
met_file_format      = 'd04.%Y%m%d'

#=============================run xstilt config==================================
foot_res             = 1/120                                                    # output footprint spatial resolution in degree
numpar               = 10000                                                    # particle # per each time window
recp_fn              = file.path(xstilt_wd, 'receptor_demo.csv')                # manually chosen receptors
OCO3_data_file       = file.path(xstilt_wd, 'receptor_obs_uncert.csv')          # all the data extracted from OCO3 files,
                                                                                # including the vertex, uncertainties, etc
fig_demo_file        = file.path(xstilt_wd, 'receptor_demo.png')                # check the receptors

#===========================job slurm parameters=================================
# set slurm to FALSE, if system does not support slurm
slurm                = T                                                        # T: SLURM parallel computing
timeout              = 3 * 60 * 60                                              # time allowed before terminations in sec
job_time             = '3:00:00'                                                # total job time
slurm_account        = 'account'
slurm_partition      = 'compute'
n_nodes              = 1
n_cores              = 40
mem_per_core         = 4.375                                                    # max memory per core in GB
# mem_per_node = n_cores * mem_per_core * 1024                                  # max mem per node now in MB 
mem_per_node         = NULL

#============================inversion parameters===============================
bg                   = 414.73
bg_uncert            = 1.06                                                     # bg information, you can read from forward calc or 
                                                                                # the TROPOMI bg calc

spriorisf            = 0.4                                                      # the scaling factor of your prior uncertainty
length_scale_priori  = 10                                                       # the LS of prior uncertainty in km
length_scale_obs     = 10                                                       # the LS of obs uncertainty in km
domain_opt_deg       = 0.15                                                     # the range around pp to be optimized, can't be too large 
                                                                                # due to the memory limit, centered at the pp, 
                                                                                # 2xdomain_opt_deg as the side length
                                                                                # suggested to be half of the box.len

#==================================plot map=====================================
zoom                 = 10                                                       # R ggplot with ggmap, zoom into the map

############################### B. PREPARATIONS ################################

#===============================B1) forward run=================================

store_path_forward          = file.path(xstilt_wd, 'XSTILT_bg_forward')         # forward kernel density store path
box.len                     = 0.3                                               # specify the desired box size for recp in deg

# time window for continuously release particles
dtime.from                  = -3                                                # FROM how many hours before the overpass time (-10)
dtime.to                    = 0                                                 # TILL the overpass time (dtime.to = 0) 
dtime.sep                   = 0.5                                               # WITH 30-min interval (dtime.sep = 0.5 hr)

nhrs_forward                = 12                                                # numbers of hours before terminating 
                                                                                # the generation of forward-time particles, 
                                                                                #'@NOTE must be positive

# release particles from fixed levels, recort particles for every 2mins
delt                        = 2                                                 # in mins
agl                         = 10                                                # in mAGL, if for power plants, use stack height

td                          = 0.1                                               # threhold for plotting foreward dowonwind domain
                                                                                # range from 0.1 to 1 

FORWARD_RUN                 = F                                                 # main switch of this part
run_forward                 = F                                                 # T: run forward traj, will overwrite existing
run_bg_xstilt               = F                                                 # T: calculate background and plot 2D density 
                                                                                # requires forward trajec to be ready
run_seg                     = F                                                 # T: segmentation the downwind domain and get 
                                                                                # the receptors

if (FORWARD_RUN & run_forward){
    namelist_PRE_forward = list(xstilt_wd = xstilt_wd, site = site, site_lon_lat = site_lon_lat,
                timestr = timestr, data_path = data_path, oco_path = oco_path, 
                sensor = sensor, sensor_gas = sensor_gas, sensor_ver = sensor_ver, 
                store_path = store_path_forward, raob_path = raob_path, box.len = box.len,
                dtime.from = dtime.from, dtime.to = dtime.to, dtime.sep = dtime.sep,
                nhrs = nhrs_forward, met_path = met_path, met = met, met_res = met_res,
                met_file_format = met_file_format, job_time = job_time,
                n_cores = n_cores, slurm_account = slurm_account, 
                slurm_partition = slurm_partition, mem_per_core = mem_per_core,
                mem_per_node = mem_per_node)
    run_forward_xstilt(namelist_PRE_forward)
}

if (FORWARD_RUN & run_forward == F & run_bg_xstilt){
    namelist_PLOT_forward = list(xstilt_wd = xstilt_wd, site = site, site_lon_lat = site_lon_lat,
                                timestr = timestr, data_path = data_path, oco_path = oco_path,
                                store_path = store_path_forward, met = met, td = td)
    forward_plot_bg(namelist_PLOT_forward)
}

# segmentation the forward downwind domain & get all the receptors and related dataset

# consistent with X-STILT setting, never change
forward_fig_path            = file.path(store_path_forward, 'out_forward', 'plot', sensor_ver)
forward_fig_file            = file.path(forward_fig_path, paste0('forward_plume_', site, '_', 
                            timestr, '_', met, '_', sensor, '_', sensor_gas, '.png'))
segmentation_file           = file.path(forward_fig_path, paste0('forward_plume_', site, '_', 
                            timestr, '_', met, '_', sensor, '_', sensor_gas, '.csv'))

QF                          = c('true', 'false')[1]                             # whether use the QF to filter the soundings
OCO3_obs_file               = grep(substr(timestr,3,8), list.files(oco_path, full.names = TRUE, 
                            recursive = TRUE), value = TRUE)                    # the OCO3 file for the specified day

if (FORWARD_RUN & run_forward == F & run_bg_xstilt == F & run_seg){

    forward_python_path     = "config/preparation/forward"                      # related python script path

    segmentation            = file.path(forward_python_path, 'click_segmentation.py')
    seg_arguments           = c(forward_fig_file, segmentation_file)
    seg_arguments_str       = paste(seg_arguments, collapse = " ")
    command_seg             = paste("python", segmentation, seg_arguments_str)
    system(command_seg)                                                         # run python script to segmentation the 
                                                                                # forward downwind domain

    get_receptor            = file.path(forward_python_path, 'OCO3_get_receptors.py')
    get_arguments           = c(site, timestr, QF, segmentation_file, recp_fn, OCO3_data_file, 
                            OCO3_obs_file, fig_demo_file)
    get_arguments_str       = paste(get_arguments, collapse = " ")
    command_get             = paste("python", get_receptor, get_arguments_str)
    system(command_get)                                                         # run python script to extract the OCO3 pixels
}

#================================B2) sample run=================================

sample_recp_fn              = file.path(xstilt_wd, 'receptor_sample_demo.csv')
store_path_sample           = file.path(xstilt_wd, 'XSTILT_output_SAMPLE')

nhrs_sample                 = -36                                               # set the sample run, set to be long enough
                                                                                #'@NOTE must be negative
emiss_res                   = 1/120                                             # emission data resolution
PBL.save                    = file.path(store_path_sample, 'XSTILT.PBL.csv')    # the PBL information saved file

SAMPLE_RUN                  = F; if(FORWARD_RUN) SAMPLE_RUN = F                 # T: main switch to this step turn off 
                                                                                # other parts if the previous parts are running
run_sample_xstilt           = F                                                 # T: use the sample receptors to run xstilt backward
run_PBL_nhrs_calc           = T                                                 # T: Calc the mean PBLH and running time (in min)
                                                                                # from sample trajectories

if (SAMPLE_RUN & run_sample_xstilt){

    sample_python_path      = "config/preparation/sample"                       # related python script path

    click                   = file.path(sample_python_path, 'click.sample.py')
    click_arguments         = c(OCO3_data_file, site_lon_lat[1], site_lon_lat[2], sample_recp_fn)
    click_arguments_str     = paste(click_arguments, collapse = " ")
    command_click           = paste("python", click, click_arguments_str)
    system(command_click)                                                       # run python script to click and select the 
                                                                                # sample set of receptors

    namelist_SAMPLE_run = list(xstilt_wd = xstilt_wd, site = site, site_lon_lat = site_lon_lat,
                timestr = timestr, data_path = data_path, recp_fn = sample_recp_fn, 
                store_path = store_path_sample, nhrs = nhrs_sample, met_path = met_path, 
                met = met, slurm = slurm, n_nodes = n_nodes, n_cores = n_cores, 
                timeout = timeout, job_time = job_time, slurm_account = slurm_account, 
                slurm_partition = slurm_partition, mem_per_core = mem_per_core, 
                mem_per_node = mem_per_node, met_file_format = met_file_format, foot_res = foot_res)

    sample.run_xstilt(namelist_SAMPLE_run)
}

if (SAMPLE_RUN & run_sample_xstilt == F & run_PBL_nhrs_calc){

    hours_xstilt_run(store_path_sample, site_lon_lat, emiss_res)
    mean.PBL(store_path_sample, PBL.save)
}

################################ C. MAIN XSTILT ################################

#=============================main run with errors==============================

zisfs                       = c(0.6, 0.7)                                       # the PBLH scaling factors, including the 
                                                                                # standard sf and turbulent 
                                                                                #'@NOTE a running directory can only run 
                                                                                # one job at one time
zisf_indx                   = 2                                                 # currently running zisf index
zisf                        = zisfs[zisf_indx]
nhrs_back                   = -6                                                # the nhrs calculated by last step, or specify 
                                                                                # it manually. 
                                                                                #'@NOTE must be negative
minagl                      = 0                                                 # min release height in meter AGL
maxagl                      = 5000                                              # max release height in meter AGL

MAIN_RUN                    = F; if(FORWARD_RUN | SAMPLE_RUN) MAIN_RUN = F      # T: main switch to this step turn off 
                                                                                # other parts if the previous parts are running
run_ver_main                = F                                                 # T: generate trajectories with different zisfs
                                                                                # (vertical errors)
run_wind_main               = T                                                 # T: generate trajectories with wind error 
                                                                                # (ROAB required)

namelist_MAIN_run = list(zisf = zisf, xstilt_wd = xstilt_wd, site = site, 
                        site_lon_lat = site_lon_lat,met_path = met_path, 
                        data_path = data_path, recp_fn = recp_fn, timestr = timestr,
                        nhrs = nhrs_back, met = met, met_file_format = met_file_format, 
                        slurm = slurm, n_nodes = n_nodes, n_cores = n_cores, timeout = timeout, 
                        job_time = job_time, slurm_account = slurm_account, 
                        slurm_partition = slurm_partition, mem_per_core = mem_per_core,
                        mem_per_node = mem_per_node, minagl = minagl, maxagl = maxagl, 
                        numpar = numpar, foot_res = foot_res, raob_fn = raob_fn)

if (MAIN_RUN & run_ver_main)
    run_vertical_loop(namelist_MAIN_run)

if (MAIN_RUN & run_ver_main == F & run_wind_main)
    run_wind(namelist_MAIN_run)

################################ D. POST DATA DEALING ##########################

# convert the ODIAC to nac file, convolve, merge and plot

# consistent with X-STILT setting, never change
emiss_file                  = file.path(xstilt_wd, 'in', paste0('odiac', vname, '_1kmx1km_', 
                            substr(timestr, 1,6), '_', site, '.nc'))

output_dirs                 = c(paste0('ver_', zisfs), 'wind')                  # output directory names
standard_indx               = 1                                                 # the index which you see as the standard
standard_zisf               = output_dirs[standard_indx]

POST_RUN                    = F; if(FORWARD_RUN | SAMPLE_RUN |                  # T: main switch to this step turn off 
                                        MAIN_RUN) POST_RUN = F                  # other parts if the previous parts are running

if (POST_RUN){
    convert.tif2nc(site, timestr, vname, xstilt_wd, tiff.path, 
                    ODIAC_YYYY, emiss_file)                                     # generate nc format ODIAC data
    foot_convolve(xstilt_wd, output_dirs, emiss_file, standard_zisf)            # convolve all footprints with emission
    merge_obs_sim(xstilt_wd, bg, bg_uncert, OCO3_data_file)                     # 
    merge_sim_all(xstilt_wd, output_dirs, standard_zisf)
    plot_sim_err_obs(xstilt_wd, key, site_lon_lat, spriorisf, zoom)
}

############################# E. INVERSION #####################################

#=============================E1) NO2 dealing===================================

NO2_path                    = 'inversion/receptor_filter'                       # NO2 data and extraction path
buff_deg                    = 2                                                 # the buff area in degree you extract NO2 data, 
                                                                                # must larger than radius(in km)
bg_radius                   = 50                                                # radius used as the bg and filter NO2 plume

bg_NO2_file                 = file.path(NO2_path, substr(timestr, 1, 8),        # file to save CO2 bg info outside NO2 plume
                                'NO2_bg.info.csv')
NO2_segmentation_file       = file.path(NO2_path, substr(timestr, 1, 8),        # file to save NO2 plume lon_lat info
                                'NO2_plume_seg.csv')                            
recp_fn_in_NO2              = file.path(NO2_path, substr(timestr, 1, 8),        # file to save CO2 pixels inside NO2 plume
                                'receptor_demo.csv')                            
                                                                                #'@NOTE the pixels in NO2 plume should be the
                                                                                # subset of the pixels in forward downwind domain,
                                                                                # meaning generate enough trajectories in the main run
OCO3_data_in_NO2_file       = file.path(NO2_path, substr(timestr, 1, 8),        # file to save CO2 pixels info inside NO2 plume
                                'receptor_obs_uncert.csv')
fig_demo_in_NO2_file        = file.path(NO2_path, substr(timestr, 1, 8),        # check the receptors
                                'receptor_demo.png')

#============================E2) inversion run==================================

inversion_function_path     = 'WRF-XSTILT-Inversion/inversion/functions'
                                                                                # python function path for inversion

# main output directory, consistent with X-STILT setting, never change
foot.path                   = list.files(file.path(xstilt_wd, 'XSTILT_output'), 
                                'out_20', full.names = T)
byid_path                   = file.path(foot.path, 'by-id')

sim_all_file                = file.path(xstilt_wd, 'XSTILT_output',             # file to save all the simulated and observed 
                                'sim_all.csv')                                  # info in one dataframe
inversion_save_path         = file.path(xstilt_wd, 'XSTILT_output',             # file to save inversion output data
                                'inversion_output')
inversion_recp              = c(recp_fn, recp_fn_in_NO2)[2]                     # receptors used in inversion (all the receptors 
                                                                                # in the forward dowonwind domain or only in the 
                                                                                # NO2 plume)

INVERSION_RUN               = T; if(FORWARD_RUN | SAMPLE_RUN | MAIN_RUN |       # T: main switch to this step turn off 
                                    POST_RUN) INVERSION_RUN = F                 # other parts if the previous parts are running
run_no2_dealing             = F                                                 # T: extract NO2 data from TOPOMI nc file and 
                                                                                # plot the plume, extract CO2 pixels in NO2 plume 
run_inversion               = T                                                 # T: Bayesian inversion and output the pp 
                                                                                # optimization with related parameters

if (INVERSION_RUN & run_no2_dealing){

    extract                 = file.path(NO2_path, 'extract_no2.py')
    extract_arguments       = c(timestr, trp_path, NO2_path, site_lon_lat[1], 
                                site_lon_lat[2], buff_deg)
    extract_arguments_str   = paste(extract_arguments, collapse = " ")
    command_extract         = paste("python", extract, extract_arguments_str)
    system(command_extract)                                                     # extract NO2 data

    NO2_plume_fig_file      = plot_NO2(timestr, site_lon_lat, bg_radius,        # plot NO2 data and plume
                                NO2_path, key, zoom)

    NO2_click               = file.path(NO2_path, 'click_segmentation.py')
    NO2_click_arguments     = c(NO2_plume_fig_file, NO2_segmentation_file)
    NO2_click_arguments_str = paste(NO2_click_arguments, collapse = " ")
    command_NO2_click       = paste("python", NO2_click, NO2_click_arguments_str)
    system(command_NO2_click)                                                   # get the plume lon_lat info

    in_NO2_receptor         = file.path(NO2_path, 'OCO3_get_receptors_NO2_bg.py')
    in_NO2_arguments        = c(site, timestr, QF, NO2_segmentation_file, recp_fn_in_NO2, 
                            OCO3_data_in_NO2_file, OCO3_obs_file, fig_demo_in_NO2_file, 
                            site_lon_lat[1], site_lon_lat[2], bg_radius, bg_NO2_file)
    NO2_arguments_str       = paste(in_NO2_arguments, collapse = " ")
    command_in_NO2          = paste("python", in_NO2_receptor, NO2_arguments_str)
    system(command_in_NO2)                                                      # extract CO2 info in the NO2 plume

}

if (INVERSION_RUN & run_no2_dealing == F & run_inversion){

    inversion_python_path   = "inversion"

    inversion               = file.path(inversion_python_path, 'main.py')
    inversion_arguments     = c(inversion_function_path, spriorisf, length_scale_priori, 
                                        length_scale_obs, site_lon_lat[1], site_lon_lat[2], 
                                        domain_opt_deg, byid_path, sim_all_file, emiss_file, 
                                        inversion_save_path, inversion_recp, bg, bg_uncert)
    inversion_arguments_str = paste(inversion_arguments, collapse = " ")
    command_inversion       = paste("python", inversion, inversion_arguments_str)
    system(command_inversion)
}