#' convolve the footprint with ff
#'@author DogtorX'

foot_convolve = function(xstilt_wd, output_dirs, emiss_file, standard_zisf){
    library(raster)
    library(ncdf4)

    # output_dirs = c('ver_0.35','ver_0.4','ver_0.5','ver_0.6','ver_0.65','wind')

    for (output_dir in output_dirs){

        print('get foot files...')
        xstilt.out = file.path(xstilt_wd, paste0('XSTILT_output_', output_dir))
        foot.path = list.files(xstilt.out, 'out_20', full.names = T)
        byid.path = file.path(foot.path, 'by-id')
        foot.fns  = list.files(byid.path, 'X_foot.nc', full.names = T, recursive = T)

        recp.info = strsplit.to.df(basename(foot.fns))
        recp.lon = recp.info$V2
        recp.lat = recp.info$V3

        ff_emiss = raster(emiss_file)

        data     = as.data.frame(matrix(nrow=0, ncol=3))

        print('start calc sim ff.xco2')
        for (i in 1:length(foot.fns)){
            print(paste0('calc ', recp.lon[i], '_', recp.lat[i], ' ...'))
            foot_file = foot.fns[i]
            foot = raster(foot_file)
            ff_emiss.sim = sum(as.matrix(foot*ff_emiss))
            data = rbind(data, c(recp.lon[i], recp.lat[i], ff_emiss.sim))
        }

        data = as.data.frame(lapply(data, as.numeric))
        colnames(data) = c('lon','lat', 'ff.xco2')

        print('save in csv file...')
        csv_file = paste0(xstilt.out, '/ff.xco2.csv')
        write.csv(data,csv_file,row.names = FALSE)

    }
    old_name = file.path(xstilt_wd, paste0('XSTILT_output_', standard_zisf))
    new_name = file.path(xstilt_wd, paste0('XSTILT_output'))
    result = file.rename(old_name, new_name)

    # 检查操作是否成功
    if (result) {
    print("Standard output File renamed.")
    } else {
    print("File could not be renamed.")
    }

}