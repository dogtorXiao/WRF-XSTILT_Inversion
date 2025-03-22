#' utilize Dienwu's script to convert the tiff file to nc file
#'@author DogtorX'

convert.tif2nc = function(site, timestr, vname, xstilt_wd, tiff.path, ODIAC_YYYY, emiss_file){

    foot.path.wind              = list.files(file.path(xstilt_wd, paste0('XSTILT_output_wind')), 
                                'out_20', full.names = T)
    byid_path.wind              = file.path(foot.path.wind, 'by-id')
    foot.file                   = list.files(byid_path.wind, 'X_foot.nc', full.names = T, recursive = T)[1]

    setwd(xstilt_wd); source('r/dependencies.r')
    library(raster)
    ODIAC_timestr = paste0(ODIAC_YYYY, substr(timestr,5,10))

    foot.extent = extent(raster(foot.file))
    tif2nc.odiacv3(site, ODIAC_timestr, vname, xstilt_wd, foot.extent, 
                            tiff.path, gzTF = T)

    ODIAC_emiss_fn              = file.path(xstilt_wd, 'in', paste0('odiac', vname, '_1kmx1km_', ODIAC_YYYY, 
                            substr(timestr, 5,6), '_', site, '.nc'))            # the nc emiss file converted
    file.rename(ODIAC_emiss_fn, emiss_file)
}