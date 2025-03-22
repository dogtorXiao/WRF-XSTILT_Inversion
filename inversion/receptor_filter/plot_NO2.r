#' plot the NO2 plumes and whole circle
#' @author DogtorX

plot_NO2 = function(timestr, site_lon_lat, radius, NO2_save_path, key, zoom){

    library(ggplot2)
    library(dplyr)
    library(ggmap)
    library(lubridate)
    library(grDevices) 
    library(RColorBrewer)
    # library(directlabels)
    library(reshape2)
    library(patchwork)

    YYYYMMDD      = substr(timestr,1,8)
    data = read.csv(file.path(NO2_save_path, YYYYMMDD, 'NO2_data.csv'))

    data = data %>% filter((longitude - site_lon_lat[1])^2+(latitude-site_lon_lat[2])^2 < (radius/100)^2)

    register_google(key = key)

    plot_map = function(data, pic_name) {
        polygon_data = data.frame(
        id = rep(1:nrow(data), times = 4),
        lon = c(data$lon1, data$lon2, data$lon3, data$lon4),
        lat = c(data$lat1, data$lat2, data$lat3, data$lat4),
        NO2 = rep(data$no2, times = 4)
        )
        limits = c(min(polygon_data$NO2), max(polygon_data$NO2))

        map_boundaries = c(left = min(polygon_data$lon)-1, bottom = min(polygon_data$lat)-1, right = max(polygon_data$lon)+1, top = max(polygon_data$lat)+1)

        map = get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
        # add the map
        m1 = ggmap(map) +
        geom_polygon(data = polygon_data,
                    aes(x = lon, y = lat, group = id, fill = NO2),
                    alpha = 0.5, color = "gray") +
        # colorbar
        scale_fill_gradientn(colors = colorRampPalette(brewer.pal(9, "YlOrRd"))(25), limits = limits)+
        # geom_point(aes(x=site_lon_lat[1], y=site_lon_lat[2]), shape = 18, size = 8)+
        theme(legend.text=element_text(size=13),
        legend.title = element_text(size=17),
        legend.position = c(0.15,0.15),
        axis.title.x=element_text(size=23,color="black",hjust=0.5),
        axis.title.y=element_text(size=23,color="black",hjust=0.5),
        axis.text.x=element_text(size=17,color="black"),
        axis.text.y=element_text(size=17,color="black"))

        m = m1+plot_layout(nrow = 1, ncol = 1)
        ggsave(pic_name, width = 320, height = 320, units = 'mm')
    }

    pic_name = file.path(NO2_save_path, YYYYMMDD, paste0('NO2_', YYYYMMDD, '.png'))
    plot_map(data, pic_name)

    # mean and sd
    mean_no2 = mean(data$no2, na.rm = TRUE)
    sd_no2 = sd(data$no2, na.rm = TRUE)

    # extract data higher than mean + sd
    selected_data = data %>% filter(no2 > mean_no2 + sd_no2)

    pic_name = file.path(NO2_save_path, YYYYMMDD, paste0('NO2_plume_', YYYYMMDD, '.png'))
    plot_map(selected_data, pic_name)
    return(pic_name)
}