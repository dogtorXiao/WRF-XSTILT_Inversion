case = 1
YYYYMMDD = c('20200408', '20200410', '20200417', '20210618', '20210619', '20210620', 
                '20211008', '20211009', '20221013')[case]

# for plot
site_lonlat = c(19.32917, 51.2625)
key ='' # your google api
spriorisf = 0.4

source('src/plot_sim_err_obs.r')
source('src/extract.all.data_plot.r')
source('src/plot_NO2.r')

# for compare
zoom = 10
height = 220
sim_obs_limit = rbind(c(-3,12), c(-3,7), c(-3,4), c(-3,8), c(-4,7), c(-2,6), 
                    c(-4,7), c(-3,4), c(-4,4))[case,]
mismatch_limit = rbind(c(-8,7), c(-4,6), c(-4,4), c(-6,7), c(-5,6), c(-6,3), 
                    c(-4,3), c(-3,4), c(-4,4))[case,]

plot_sim_err_obs(YYYYMMDD, zoom, height, sim_obs_limit, mismatch_limit, key)

# for inversion filter
zoom = 10
height =220
mismatch_limit = rbind(c(-8,7), c(-3,6), c(-4,4), c(-6,7), c(-5,6), c(-5,3), 
                    c(-4,3), c(-3,4), c(-2,2))[case,]
extract.all.data_plot(YYYYMMDD, zoom, height, mismatch_limit, key)

# for the CO2 in NO2 plume
distance = 50 # in km 
zoom = 10
height = 220
plot_NO2(YYYYMMDD, site_lonlat, distance, key, zoom, height)
