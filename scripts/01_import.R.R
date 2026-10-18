# 01_import.R
# Reads the UN E-Government Survey files (2010-2024), keeps the indices used
# in the analysis, adds ISO3 country codes and selects 39 European countries.
# Input:  data_raw/EGOV_DATA_<year>.csv (UN E-Government Knowledgebase)
# Output: data_clean/egov_europe.csv

library(tidyverse)
library(countrycode)

# 1. Read and stack all survey waves ----------------------------------------

egov <- list.files("data_raw", pattern = "EGOV_DATA_.*\\.csv$",
                   full.names = TRUE) |>
  map(read_csv, show_col_types = FALSE) |>
  list_rbind()

# 2. Keep and rename the variables ------------------------------------------

egov_clean <- egov |>
  select(year      = `Survey Year`,
         country   = `Country Name`,
         egdi      = `E-Government Index`,
         osi       = `Online Service Index`,
         epi       = `E-Participation Index`,
         hci       = `Human Capital Index`,
         tii       = `Telecommunication Infrastructure Index`) |>
  mutate(iso3c     = countrycode(country, "country.name", "iso3c"),
         continent = countrycode(country, "country.name", "continent"))

# 3. Select the sample -------------------------------------------------------
# EU-27, Norway, Iceland, Switzerland, United Kingdom, Ukraine, Moldova,
# Turkey and five Western Balkan countries. Russia, Belarus and microstates
# are excluded (see README). Cyprus and Turkey are selected by ISO code
# because countrycode assigns them to Asia.

europe_iso <- c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN",
                "FRA", "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX",
                "MLT", "NLD", "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE",
                "NOR", "ISL", "CHE", "GBR",
                "UKR", "MDA", "SRB", "ALB", "MKD", "MNE", "BIH", "TUR")

egov_eu <- egov_clean |> filter(iso3c %in% europe_iso)

# Check: 39 countries x 8 survey waves = 312 rows
stopifnot(n_distinct(egov_eu$iso3c) == 39,
          nrow(egov_eu) == 312)

# 4. Save --------------------------------------------------------------------

write_csv(egov_eu, "data_clean/egov_europe.csv")