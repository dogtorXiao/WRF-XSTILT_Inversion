library(ggplot2)
df = read.csv("chart_convert.csv")

p <- ggplot(df, aes(x = date), size = 8) +
  geom_line(aes(y = ODIAC, color = "ODIAC"), group = 1, linewidth = 1) +
  geom_line(aes(y = estimate, color = "standard estimation"), group = 1, linewidth = 1) + 
  geom_line(aes(y = expected, color = "ENTSO-E derived"), group = 1, linewidth = 1) + 
  geom_line(aes(y = mean_bg_test, color = "background test"), group = 1, linewidth = 1) +
  # geom_line(aes(y = ODIAC, color = "ODIAC"), group = 1, linewidth = 1) +
  geom_line(aes(y = downwind_domain_test, color = "downwind domain test"), group = 1, linewidth = 1) +

  geom_point(aes(y = ODIAC, color = "ODIAC"), size = 3) +
  geom_point(aes(y = estimate, color = "standard estimation"), size = 3) + 
  geom_point(aes(y = expected, color = "ENTSO-E derived"), size = 3) + 
  geom_point(aes(y = mean_bg_test, color = "background test"), size = 3) +
  # geom_point(aes(y = ODIAC, color = "ODIAC"), size = 3) +
  geom_point(aes(y = downwind_domain_test, color = "downwind domain test"), size = 3) +

  geom_errorbar(aes(y = estimate, ymin = estimate - uncertainty, ymax = estimate + uncertainty, color = "standard estimation"), width=0.3) +
  geom_errorbar(aes(y = expected, ymin = expected - 0.1 * expected, ymax = expected + 0.1 * expected, color = "ENTSO-E derived"), width=0.3) +
  geom_errorbar(aes(y = mean_bg_test, ymin = mean_bg_test - bg_sd, ymax = mean_bg_test + bg_sd, color = "background test"), width=0.3) +
  geom_errorbar(aes(y = downwind_domain_test, ymin = downwind_domain_test - downwind_domain_test_sd, ymax = downwind_domain_test + downwind_domain_test_sd, color = "downwind domain test"), width=0.3) +
  scale_color_manual(
    values = c(
      "ODIAC" = 'black', 
      "standard estimation" = "#377EB8", 
      "ENTSO-E derived" = "#E41A1C", 
      "background test" = "#4DAF4A", 
      # "ODIAC" = 'black', 
      "downwind domain test" = '#dba507'
    ),
    labels = c(
      "ODIAC" = "ODIAC",
      "standard estimation" = expression(E[NO2_BG]),
      "ENTSO-E derived" = "ENTSO-E based",
      "background test" = expression(E[Mean_BG]),
      # "ODIAC" = "ODIAC",
      "downwind domain test" = expression(E-DW[Mean_BG])
    ),
    breaks = c("ODIAC", "ENTSO-E derived", "standard estimation", "background test", "downwind domain test")  # 显式指定顺序
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.key.size = unit(1.0, "lines")) + 
  labs(color = "emissions", y = 'ktCO2/day', size = 8)

p = p + theme(legend.text.align = 0)

ggsave('chart_all_converted.png', width = 300, height = 200, units = 'mm')