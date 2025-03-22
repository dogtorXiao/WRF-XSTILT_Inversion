rsc = dir('config', pattern = '.*\\.r$',
                  full.names = T, recursive = T)
rsc = c(rsc, dir('inversion', pattern = '.*\\.r$',
                  full.names = T, recursive = T))

invisible(lapply(rsc, source))