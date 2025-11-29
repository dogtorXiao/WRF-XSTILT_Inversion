plot_compare_obs_enhance = function(sim, pic_name, zoom, height, sim_obs_limit){

    polygon_data <- data.frame(
    id = rep(1:nrow(sim), times = 4),
    longitude = c(sim$lon1, sim$lon2, sim$lon3, sim$lon4),
    latitude = c(sim$lat1, sim$lat2, sim$lat3, sim$lat4),
    obs_enhance = rep(sim$obs_enhance, times = 4),
    ff.xco2 = rep(sim$ff.xco2, times = 4)
    )

    map_boundaries <- c(left = min(polygon_data$longitude)-0.01, bottom = min(polygon_data$latitude)-0.01, right = max(polygon_data$longitude)+0.01, top = max(polygon_data$latitude)+0.01)

    map <- get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
    # 添加底图
    m1 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = ff.xco2),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = sim_obs_limit, 
    name = expression(paste('X-STILT modeled ', XCO[2])), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m2 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = obs_enhance),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = sim_obs_limit, 
    name = expression(paste("OCO-3 observed ", Delta, XCO[2])), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m = m1+m2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 2*height, height = height, units = 'mm')

}    

plot_compare_trans_obs_err = function(spriorisf, sim, pic_name, zoom, height, trans_obs_err_limit){

    polygon_data <- data.frame(
    id = rep(1:nrow(sim), times = 4),
    longitude = c(sim$lon1, sim$lon2, sim$lon3, sim$lon4),
    latitude = c(sim$lat1, sim$lat2, sim$lat3, sim$lat4),
    uncert_trans = rep(sim$uncert_trans, times = 4),
    uncert_obs = rep(sim$uncert, times = 4)
    )

    map_boundaries <- c(left = min(polygon_data$longitude)-0.01, bottom = min(polygon_data$latitude)-0.01, right = max(polygon_data$longitude)+0.01, top = max(polygon_data$latitude)+0.01)

    map <- get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
    # 添加底图
    m1 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = uncert_trans),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradientn(colors = colorRampPalette(brewer.pal(9, "YlOrRd"))(25), limits = trans_obs_err_limit,
    name = expression(paste(epsilon[transport])), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m2 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = uncert_obs),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradientn(colors = colorRampPalette(brewer.pal(9, "YlOrRd"))(25), limits = trans_obs_err_limit,
    name = expression(paste(epsilon[OCO-3])), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m = m1+m2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 2*height, height = height, units = 'mm')

}

plot_mismatch = function(sim, pic_name, zoom, height, mismatch_limit){

    polygon_data <- data.frame(
    id = rep(1:nrow(sim), times = 4),
    longitude = c(sim$lon1, sim$lon2, sim$lon3, sim$lon4),
    latitude = c(sim$lat1, sim$lat2, sim$lat3, sim$lat4),
    mismatch = rep(sim$obs_enhance - sim$ff.xco2, times = 4),
    B_R_ratio = rep(spriorisf^2*(sim$ff.xco2*sim$ff.xco2)/(spriorisf^2*(sim$ff.xco2*sim$ff.xco2)+sim$uncert*sim$uncert+sim$uncert_trans*sim$uncert_trans), times = 4)
    # mismatch_OSSE = rep((sim$obs_enhance - sim$'OSSE.obs')/sim$'OSSE.obs', times = 4)
    )

    map_boundaries <- c(left = min(polygon_data$longitude)-0.01, bottom = min(polygon_data$latitude)-0.01, right = max(polygon_data$longitude)+0.01, top = max(polygon_data$latitude)+0.01)

    map <- get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
    # 添加底图
    m1 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = mismatch),
                alpha = 0.5, color = "gray") +
    # coord_cartesian(xlim = c(min(polygon_data$longitude)-0.01, max(polygon_data$longitude)+0.01), 
    #             ylim = c(min(polygon_data$latitude)-0.01, max(polygon_data$latitude)+0.01))+
    # 添加 colorbar
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = mismatch_limit,
    name = expression(paste("OCO-3 observed ", Delta, XCO[2],-'X-STILT modeled ', XCO[2])), 
                                              guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m2 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = B_R_ratio),
                alpha = 0.5, color = "gray") +
    # coord_cartesian(xlim = c(min(polygon_data$longitude)-0.01, max(polygon_data$longitude)+0.01), 
    #             ylim = c(min(polygon_data$latitude)-0.01, max(polygon_data$latitude)+0.01))+
    # 添加 colorbar
    scale_fill_gradient2(low = "white", high = "red", limits = c(0,1),
    name = expression(paste('(HP'^b,'H'^T, ')(HP'^b,'H'^T,+'R)'^-1)), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 17, angle = 90),
                                              label.theme = element_text(size = 17)))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))
    

    m = m1+m2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 2*height, height = height, units = 'mm')

}    

plot_ver_sim = function(sim, pic_name, zoom, height){

    polygon_data <- data.frame(
    id = rep(1:nrow(sim), times = 4),
    longitude = c(sim$lon1, sim$lon2, sim$lon3, sim$lon4),
    latitude = c(sim$lat1, sim$lat2, sim$lat3, sim$lat4),
    ver_diff1 = rep(sim$ver_0.9 - sim$ver_1.3, times = 4),
    ver_diff2 = rep(sim$ver_0.9 - sim$ver_1, times = 4)
    # mismatch_OSSE = rep((sim$obs_enhance - sim$'OSSE.obs')/sim$'OSSE.obs', times = 4)
    )

    map_boundaries <- c(left = min(polygon_data$longitude)-0.01, bottom = min(polygon_data$latitude)-0.01, right = max(polygon_data$longitude)+0.01, top = max(polygon_data$latitude)+0.01)

    map <- get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
    # 添加底图
    m1 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = ver_diff1),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = c(-0.8, 0.8))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m2 = ggmap(map) +
    # 添加四边形
    geom_polygon(data = polygon_data,
                aes(x = longitude, y = latitude, group = id, fill = ver_diff2),
                alpha = 0.5, color = "gray") +
    # 添加 colorbar
    scale_fill_gradient2(low = "white", high = "red", limits = c(-0.5, 0.5))+
    geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
    theme(legend.text=element_text(size=13),
    legend.title = element_text(size=17),
    # legend.position = c(0.15,0.15),
    axis.title.x=element_text(size=17,color="black",hjust=0.5),
    axis.title.y=element_text(size=17,color="black",hjust=0.5),
    axis.text.x=element_text(size=17,color="black"),
    axis.text.y=element_text(size=17,color="black"))

    m = m1+m2+plot_layout(nrow = 1, ncol = 2)
    ggsave(pic_name, width = 2*height, height = height, units = 'mm')

}    