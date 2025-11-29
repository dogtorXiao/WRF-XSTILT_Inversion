plot_NO2 = function(YYYYMMDD, site_lonlat, distance, key, zoom, height){

    library(ggplot2)
    library(dplyr)
    library(ggmap)
    library(lubridate)
    library(grDevices) 
    library(RColorBrewer)
    # library(directlabels) 
    library(reshape2)
    library(patchwork)
    library(scales)
    # options(scipen = 100)
    src.path = file.path('DataFigures', YYYYMMDD)
    data <- read.csv(file.path(src.path, 'NO2_data.csv'))
    data$no2 = data$no2 / 4.4615e-4 # turn molec/m2 to DU
    data <- data %>% filter((longitude - site_lonlat[1])^2+(latitude-site_lonlat[2])^2 < (distance/100)^2)
    register_google(key = key)

    # 画图
    plot_map <- function(data, pic_name, zoom, height) {
        polygon_data <- data.frame(
        id = rep(1:nrow(data), times = 4),
        lon = c(data$lon1, data$lon2, data$lon3, data$lon4),
        lat = c(data$lat1, data$lat2, data$lat3, data$lat4),
        NO2 = rep(data$no2, times = 4)
        )

        map_boundaries <- c(left = site_lonlat[1]-1, bottom = site_lonlat[2]-1, right = site_lonlat[1]+1, top = site_lonlat[2]+1)

        # map <- get_map(location = map_boundaries, zoom = zoom, maptype = "roadmap")
        map = get_googlemap(center = site_lonlat, zoom = zoom, maptype = "roadmap")
        # map <- get_map( zoom = 10, maptype = "roadmap")
        # 添加底图
        m1 = ggmap(map) +
        # 添加四边形
        geom_polygon(data = polygon_data,
                    aes(x = lon, y = lat, group = id, fill = NO2),
                    alpha = 0.5, color = "gray") +
        # 添加 colorbar
        scale_fill_gradientn(colors = colorRampPalette(brewer.pal(9, "YlOrRd"))(25),
                            label = label_number(),
                            name = expression(paste('TROPOMI ',NO[2], ' (DU)')), guide = guide_colorbar(direction = "vertical",
                                              title.position = "right",
                                              title.hjust = 1.0,
                                              title.theme = element_text(size = 12, angle = 90),
                                              label.theme = element_text(size = 12)))+
        # geom_point(aes(x=site_lonlat[1], y=site_lonlat[2]), shape = 18, size = 8)+
        theme(axis.title.x=element_text(size=14,color="black",hjust=0.5),
        axis.title.y=element_text(size=14,color="black",hjust=0.5),
        axis.text.x=element_text(size=12,color="black"),
        axis.text.y=element_text(size=12,color="black"))

        m = m1+plot_layout(nrow = 1, ncol = 1)
        ggsave(pic_name, width = height, height = height, units = 'mm')
    }

    pic_name = file.path(src.path, paste0('NO2', YYYYMMDD, '.png'))
    plot_map(data, pic_name, zoom-1, height)

    # 计算平均值和标准差
    mean_no2 <- mean(data$no2, na.rm = TRUE)
    sd_no2 <- sd(data$no2, na.rm = TRUE)

    # 提取高于平均值+标准差的数据
    selected_data <- data %>% filter(no2 > mean_no2 + sd_no2)

    # 再次绘制
    pic_name = file.path(src.path, paste0('NO2_plume', YYYYMMDD, '.png'))
    plot_map(selected_data, pic_name, zoom, height)
    
}