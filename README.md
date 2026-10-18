# Digital Public Services and New Business Creation in Europe

Portfolio project in R by Khrystyna Vdovychenko, October 2026.

## Research question

Is the level of digital public services associated with new business creation in European countries, 2010-2024?

## Main findings

- Across countries, a higher UN Online Service Index (OSI) goes together with more new limited liability companies per 1,000 people aged 15-64.
- The association disappears with controls for internet use and income and with country and year fixed effects. Within countries over time, changes in the OSI are not linked to changes in new business density.
- The result holds when using the E-Government Development Index instead of the OSI, without the Netherlands, without the 2020 and 2022 waves, without Luxembourg and Estonia, and with the OSI from the previous wave.
- For Ukraine, I rebuilt new LLC registrations for 2005-2025 from the Unified State Register. For 2014-2017 the series matches the World Bank indicator within 1 percent.

The design shows associations, not causal effects. See section 8 of the report for limitations.

## Data

| Variable | Source | Indicator or file | Downloaded |
|---|---|---|---|
| osi, egdi, epi, hci, tii | UN E-Government Survey, 2010-2024 | `EGOV_DATA_<year>.csv` | 11 Oct 2026 |
| new_biz | World Bank WDI | `IC.BUS.NDNS.ZS` | 11 Oct 2026 |
| gdp_pc | World Bank WDI | `NY.GDP.PCAP.PP.KD` | 11 Oct 2026 |
| internet | World Bank WDI | `IT.NET.USER.ZS` | 11 Oct 2026 |
| pop | World Bank WDI | `SP.POP.TOTL` | 11 Oct 2026 |
| pop1564 (Ukraine) | World Bank WDI | `SP.POP.1564.TO` | 12 Oct 2026 |
| Lending rate (checked, not used) | World Bank WDI | `FR.INR.LEND` | 12 Oct 2026 |
| New LLCs in Ukraine | Unified State Register, Ministry of Justice of Ukraine (CC BY) | `UO.zip`, version of 6 Oct 2026 | 12 Oct 2026 |

Sources:

- UN E-Government Knowledgebase: https://publicadministration.un.org/egovkb/en-us/Data-Center
- World Bank WDI, downloaded with the R package `WDI`
- Unified State Register on data.gov.ua: https://data.gov.ua/dataset/a1799820-195b-4982-8141-6e84f58103e7

## Sample

- 39 countries: EU-27, Norway, Iceland, Switzerland, United Kingdom, Ukraine, Moldova, Serbia, Albania, North Macedonia, Montenegro, Bosnia and Herzegovina, Turkey.
- Excluded: Russia and Belarus (different political context), and microstates without World Bank data (Andorra, Liechtenstein, Monaco, San Marino).
- Cyprus and Turkey were added by ISO code, because the `countrycode` package assigns them to Asia.
- Final panel: 312 country-years (39 countries x 8 survey waves), 300 with data on new business density.
- The Netherlands is kept although 4 of 8 waves are missing. A robustness check drops it.
- In the World Bank data, Ukraine has new business density only for 2010-2017. The panel therefore includes Ukraine only for the 2010, 2012, 2014 and 2016 waves.

## Repository structure

```
data_raw/      original downloads, never edited
data_clean/    processed data
scripts/       01_import.R, 02_wdi.R, 03_models.R, 04_ukraine.R
output/        figures and tables
report.Rmd     report with all results (knit to HTML or PDF)
```

## How to reproduce

1. Install R (version 4.6.1 used) and the packages `tidyverse`, `WDI`, `countrycode`, `fixest`, `modelsummary` and `ggrepel`.
2. Download the UN E-Government data for 2010-2024 into `data_raw/`.
3. Run the scripts in order from `01_import.R` to `04_ukraine.R`. The script `02_wdi.R` downloads the World Bank data through its API, so the values can change slightly if the World Bank revises them.
4. For `04_ukraine.R`, download `UO.zip` from the data.gov.ua page above into `data_raw/edr/`. It is not included in this repository because of its size (328 MB compressed, 3.2 GB of XML). The script reads it in chunks without unzipping it to disk, takes about 3 minutes, and uses the `unzip` command available on macOS and Linux.
5. Knit `report.Rmd`.