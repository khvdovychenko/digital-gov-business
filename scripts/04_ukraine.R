# 04_ukraine.R
# Builds a series of new limited liability companies (LLCs) in Ukraine,
# 2005-2025, from the Unified State Register and validates it against the
# World Bank indicator IC.BUS.NDNS.ZS.
# Input:  data_raw/edr/uo.zip (download manually, see README)
# Output: data_clean/edr_uo_extract.rds, data_clean/ukraine_new_llc.csv,
#         output/ukraine_new_llc.png

library(tidyverse)
library(WDI)

zip_path <- "data_raw/edr/uo.zip"

# 1. Extract five fields from each record ----------------------------------
# The XML file (3.2 GB, windows-1251) is streamed through the system unzip
# command in chunks of 50,000 lines. Some records span several lines, so the
# lines are joined and split at the closing </SUBJECT> tag.

extract_fields <- function(records) {
  tibble(
    edrpou    = str_match(records, "<EDRPOU>(.*?)</EDRPOU>")[, 2],
    opf       = str_match(records, "<OPF>(.*?)</OPF>")[, 2],
    stan      = str_match(records, "<STAN>(.*?)</STAN>")[, 2],
    reg_date  = str_match(records, "<REGISTRATION>(\\d{2}\\.\\d{2}\\.\\d{4})")[, 2],
    term_date = str_match(records, "<TERMINATED_INFO>(\\d{2}\\.\\d{2}\\.\\d{4})")[, 2]
  )
}

con <- pipe(paste("unzip -p", shQuote(zip_path), "UO.xml"), open = "r")
leftover <- ""
results <- list()
i <- 0

repeat {
  lines <- readLines(con, n = 50000, warn = FALSE)
  if (length(lines) == 0) break
  
  lines <- iconv(lines, from = "windows-1251", to = "UTF-8", sub = "?")
  text  <- paste(c(leftover, lines), collapse = " ")
  parts <- str_split(text, fixed("</SUBJECT>"))[[1]]
  
  leftover <- parts[length(parts)]
  records  <- parts[-length(parts)]
  records  <- records[str_detect(records, fixed("<SUBJECT>"))]
  
  i <- i + 1
  results[[i]] <- extract_fields(records)
  message("Chunk ", i, ": ", length(records), " records")
}
close(con)

uo <- bind_rows(results)
rm(results, lines, text, parts, records)
write_rds(uo, "data_clean/edr_uo_extract.rds", compress = "gz")

# 2. Count new LLCs by registration year -----------------------------------
# The register covers entities registered since July 2004, plus older ones
# that are still active, so the series starts in 2005. 2026 is incomplete.

uo <- uo |>
  mutate(reg_date = dmy(reg_date),
         reg_year = year(reg_date))

message("Records without a valid registration date: ", sum(is.na(uo$reg_year)))

llc_year <- uo |>
  filter(opf == "ТОВАРИСТВО З ОБМЕЖЕНОЮ ВІДПОВІДАЛЬНІСТЮ",
         reg_year >= 2005, reg_year <= 2025) |>
  count(reg_year, name = "new_llc")

# 3. Validate against the World Bank series ---------------------------------

ukr_pop <- WDI(country = "UA",
               indicator = c(pop1564 = "SP.POP.1564.TO"),
               start = 2005, end = 2025)

wdi_raw <- read_csv("data_raw/wdi_raw.csv", show_col_types = FALSE)
ukr_wdi <- wdi_raw |>
  filter(iso3c == "UKR") |>
  select(year, new_biz_wdi = new_biz)

ukr_check <- llc_year |>
  rename(year = reg_year) |>
  left_join(select(ukr_pop, year, pop1564), by = "year") |>
  left_join(ukr_wdi, by = "year") |>
  mutate(new_llc_density = new_llc / pop1564 * 1000)

write_csv(ukr_check, "data_clean/ukraine_new_llc.csv")

# 4. Figure -----------------------------------------------------------------
# Annual values are plotted at mid-year so they line up with dated events.

milestones <- tibble(
  date = c(2020.75, 2022.15, 2022.65),
  num  = c("1", "2", "3")
)

ggplot(ukr_check, aes(x = year + 0.5)) +
  geom_vline(data = milestones, aes(xintercept = date),
             linetype = "dashed", colour = "grey60") +
  geom_text(data = milestones, aes(x = date, y = 2.1, label = num),
            size = 3.5, colour = "grey30") +
  geom_line(aes(y = new_llc_density,
                colour = "Unified State Register (own calculation)")) +
  geom_point(aes(y = new_biz_wdi, colour = "World Bank WDI")) +
  labs(x = NULL,
       y = "New LLCs per 1,000 people aged 15-64",
       colour = NULL,
       title = "New limited liability companies in Ukraine, 2005-2025",
       caption = paste("1 = LLC registration on Diia portal (Oct 2020)",
                       "2 = full-scale invasion (Feb 2022)",
                       "3 = automatic LLC registration on Diia (Aug 2022)",
                       sep = "\n")) +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.caption = element_text(hjust = 0))

ggsave("output/ukraine_new_llc.png", width = 8, height = 5)