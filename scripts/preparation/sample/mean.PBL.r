#' function to calc the mean PBL height in xstilt
#' @author DogtorX

mean.PBL = function(store_path, PBL.save){

    print('get traj files...')
    foot.path = list.files(store_path, 'out_20', full.names = T)
    byid.path = file.path(foot.path, 'by-id')
    foot.fns  = list.files(byid.path, 'X_traj.rds', full.names = T, recursive = T)

    # calc the mean PBL height for every sample pixel and the mean of all
    PBL = NULL
    for (i in 1:length(foot.fns)){
        print(foot.fns[i])
        mean.PBL = 2*mean(readRDS(foot.fns[i])$particle$mlht)
        PBL = c(PBL, mean.PBL)
    }

    PBL = c(PBL, mean(PBL))
    print(paste('the mean PBLH is ', mean(PBL), 'm'))
    write.csv(PBL, PBL.save, row.names = FALSE)
}