# 03_models.R
# Estimates the main models (pooled, with controls, with country and year
# fixed effects) and the robustness checks. The report (report.Rmd) runs
# the same models; this script lets you check them on their own.
# Input:  data_clean/panel_final.csv (from 02_wdi.R)
# Output: data_raw/wdi_lending_rate.csv, output/regression_table.csv,
#         output/robustness_table.csv

library(tidyverse)
library(fixest)
library(WDI)

panel_final <- read_csv("data_clean/panel_final.csv", show_col_types = FALSE)

# Logs require positive values
stopifnot(min(panel_final$new_biz, na.rm = TRUE) > 0)

panel_final <- panel_final |>
  mutate(log_new_biz = log(new_biz),
         log_gdp_pc  = log(gdp_pc)) |>
  arrange(iso3c, year) |>
  group_by(iso3c) |>
  mutate(osi_lag = dplyr::lag(osi)) |>
  ungroup()

# 1. Main models -------------------------------------------------------------
# Standard errors clustered by country.

m1 <- feols(log_new_biz ~ osi, data = panel_final, cluster = ~iso3c)
m2 <- feols(log_new_biz ~ osi + log_gdp_pc + internet,
            data = panel_final, cluster = ~iso3c)
m3 <- feols(log_new_biz ~ osi + log_gdp_pc + internet | iso3c + year,
            data = panel_final, cluster = ~iso3c)

etable(m1, m2, m3)
write.csv(etable(m1, m2, m3), "output/regression_table.csv")

# Correlation between the explanatory variables (multicollinearity check)
panel_final |>
  select(osi, internet, log_gdp_pc) |>
  cor()

# 2. Robustness checks -------------------------------------------------------

r1 <- feols(log_new_biz ~ egdi + log_gdp_pc + internet | iso3c + year,
            data = panel_final, cluster = ~iso3c)
r2 <- feols(log_new_biz ~ osi + log_gdp_pc + internet | iso3c + year,
            data = filter(panel_final, iso3c != "NLD"), cluster = ~iso3c)
r3 <- feols(log_new_biz ~ osi + log_gdp_pc + internet | iso3c + year,
            data = filter(panel_final, !year %in% c(2020, 2022)),
            cluster = ~iso3c)
r4 <- feols(log_new_biz ~ osi + log_gdp_pc + internet | iso3c + year,
            data = filter(panel_final, !iso3c %in% c("LUX", "EST")),
            cluster = ~iso3c)
r5 <- feols(log_new_biz ~ osi_lag + log_gdp_pc + internet | iso3c + year,
            data = panel_final, cluster = ~iso3c)

# Check the number of observations in each model
stopifnot(nobs(m3) == 300, nobs(r1) == 300, nobs(r2) == 296,
          nobs(r3) == 224, nobs(r4) == 284, nobs(r5) == 263)

etable(m3, r1, r2, r3, r4, r5)
write.csv(etable(m3, r1, r2, r3, r4, r5), "output/robustness_table.csv")

# 3. Lending rate: data availability check ----------------------------------
# A lending rate control was considered but not used: the series covers
# fewer than half of the sample countries and almost no euro area country.

lend_raw <- WDI(country = unique(panel_final$iso3c),
                indicator = c(lend_rate = "FR.INR.LEND"),
                start = 2010, end = 2024)

write_csv(lend_raw, "data_raw/wdi_lending_rate.csv")

lend_raw |>
  filter(year %in% seq(2010, 2024, by = 2)) |>
  group_by(year) |>
  summarise(with_data = sum(!is.na(lend_rate)), total = n())