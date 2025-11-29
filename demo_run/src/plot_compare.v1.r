plot_compare_obs_enhance_old = function(sim, pic_name){

        # plot for the site
    rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
    colormap <- colorRampPalette(rev(brewer.pal(11,'Spectral')))(32) #set coloabar

        m1 = ggplot(sim,aes(x=lon,y=lat))+
        geom_point(aes(color=ff.xco2),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(-1, 5))+
        labs(x='lon',y="lat") +
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 12)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值


        m3 = ggplot(sim,aes(x=lon,y=lat))+
        geom_point(aes(color=obs_enhance),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(-1, 5))+
        labs(x='lon',y="lat") +
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 12)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值

    m = m1+m3+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 640, height = 320, units = 'mm')

}

plot_compare_ver_wind_err_old = function(sim, pic_name){

        # plot for the site
    rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
    colormap <- colorRampPalette(rev(brewer.pal(11,'Spectral')))(32) #set coloabar

        m1 = ggplot(sim,aes(x=lon,y=lat))+
        geom_point(aes(color=uncert_total),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(-1, 5))+
        labs(x='lon',y="lat") +
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 12)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值

        m2 = ggplot(sim,aes(x=lon,y=lat))+
        geom_point(aes(color=uncert_total_percent),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(-1, 5))+
        labs(x='lon',y="lat") +
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 12)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值

    m = m1+m2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 640, height = 320, units = 'mm')

}

plot_band = function(pic_name_band, sim_all_lat, sim_all_lon){

    sim_lat = data.frame(lon = sim_all_lat$lon, ff.xco2 = sim_all_lat$ff.xco2, obs_enhance = sim_all_lat$obs_enhance, obs_bg = sim_all_lat$obs_xco2-bg)
    sim_lat_m = melt(sim_lat, 'lon')
    sim_lon = data.frame(lat = sim_all_lon$lat, ff.xco2 = sim_all_lon$ff.xco2, obs_enhance = sim_all_lon$obs_enhance, obs_bg = sim_all_lon$obs_xco2-bg)
    sim_lon_m = melt(sim_lon, 'lat')
    b1 = ggplot(aes(x=lon, y=value, color = variable), data = sim_lat_m)+
        #  geom_point(alpha=0.5, size = 2)+geom_smooth()+
         geom_point(alpha=0.5, size = 0.5)+ geom_line()+geom_smooth(span = 0.3)+
         labs(x="lon",y="FF XCO_2")+
         theme(legend.text=element_text(size=17),
            legend.title = element_text(size=23),
            legend.position = c(0.85,0.85))
    b2 = ggplot(aes(x=lat, y=value, color = variable), data = sim_lon_m)+
         geom_point(alpha=0.5, size = 0.5)+ geom_line()+geom_smooth(span = 0.3)+
        #  geom_point(alpha=0.5, size = 2)+geom_smooth()+
         labs(x="lat",y="FF XCO_2")+
         theme(legend.text=element_text(size=17),
            legend.title = element_text(size=23),
            legend.position = c(0.85,0.85))
    b = b1+b2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name_band, width = 840, height = 320, units = 'mm')

}

plot_err_ratio = function(err_ratio.pic, sim_all, HQHt_R, z_Hsp){

        # plot for the site
    rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
    colormap <- colorRampPalette(rev(brewer.pal(11,'Spectral')))(32) #set coloabar

        m1 = ggplot(sim_all, aes(x=lon,y=lat))+
        geom_point(aes(color=HQHt_R),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(0, 0.7))+
        labs(x='lon',y="lat") + #纵坐标名称
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 7)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值
        # ggsave(err_ratio.pic, width = 320, height = 320, units = 'mm')

        m2 = ggplot(sim_all, aes(x=lon,y=lat))+
        geom_point(aes(color=z_Hsp),size=5)+
        scale_color_gradientn(colours=colormap, limits = c(-4, 3))+
        labs(x='lon',y="lat") + #纵坐标名称
        geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 7)+
        theme(legend.text=element_text(size=17),
        legend.title = element_text(size=23),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))#更改横坐标刻度值
        ggsave(err_ratio.pic, width = 320, height = 320, units = 'mm')

        m = m1+m2+plot_layout(nrow = 1, ncol = 2)
        ggsave(err_ratio.pic, width = 640, height = 320, units = 'mm')
}