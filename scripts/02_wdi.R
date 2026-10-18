# 02_wdi.R
# Downloads World Bank WDI indicators for the 39 sample countries and merges
# them with the UN E-Government data into the analysis panel.
# Input:  data_clean/egov_europe.csv (from 01_import.R)
# Output: data_raw/wdi_raw.csv, data_clean/panel_final.csv,
#         output/scatter_osi_newbiz.png, output/scatter_osi_newbiz_log.png

library(tidyverse)
library(WDI)

egov_eu <- read_csv("data_clean/egov_europe.csv", show_col_types = FALSE)
europe_iso <- unique(egov_eu$iso3c)

# 1. Download WDI data -------------------------------------------------------
# Requesting only the 39 sample countries avoids server timeouts.
# If the download stops with a timeout, run it again.

wdi_raw <- WDI(country = europe_iso,
               indicator = c(new_biz  = "IC.BUS.NDNS.ZS",
                             gdp_pc   = "NY.GDP.PCAP.PP.KD",
                             internet = "IT.NET.USER.ZS",
                             pop      = "SP.POP.TOTL"),
               start = 2010, end = 2024)

# Check that all four indicators were downloaded
stopifnot(all(c("new_biz", "gdp_pc", "internet", "pop") %in% names(wdi_raw)))

write_csv(wdi_raw, "data_raw/wdi_raw.csv")

# 2. Merge with the UN data --------------------------------------------------
# UN surveys are published every two years, so the inner join keeps only
# the even years 2010-2024.

panel_final <- egov_eu |>
  inner_join(select(wdi_raw, iso3c, year, new_biz, gdp_pc, internet, pop),
             by = c("iso3c", "year"))

stopifnot(nrow(panel_final) == 312)

# Missing new business density by country. Expected: 12 values in total
# (Netherlands 4, Ukraine 4, Austria, Belgium, Greece, Switzerland 1 each).
panel_final |>
  group_by(country) |>
  summarise(n_missing = sum(is.na(new_biz))) |>
  filter(n_missing > 0)

write_csv(panel_final, "data_clean/panel_final.csv")

# 3. Descriptive figures -----------------------------------------------------

ggplot(panel_final, aes(x = osi, y = new_biz)) +
  geom_point(alpha = 0.6) +
  labs(x = "Online Service Index (UN)",
       y = "New businesses per 1,000 people aged 15-64",
       title = "OSI and new business density, Europe 2010-2024") +
  theme_minimal()

ggsave("output/scatter_osi_newbiz.png", width = 7, height = 5)

ggplot(panel_final, aes(x = osi, y = new_biz)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_y_log10() +
  labs(x = "Online Service Index (UN)",
       y = "New businesses per 1,000 (log scale)",
       title = "OSI and new business density (log scale)") +
  theme_minimal()

ggsave("output/scatter_osi_newbiz_log.png", width = 7, height = 5)