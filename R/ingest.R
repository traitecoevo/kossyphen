# Raw walk-data ingestion for the Gibson & Green KossyFlowers sheets.
# Faithful to whats_in_flower/R/processData.R, generalised to take paths.

#' Process one yearly KossyFlowers sheet into long format
#'
#' @param a Data frame read from a KossyFlowers sheet with `col_names = FALSE`
#'   (columns X1 = species, X5.. = recorded flowering dates).
#' @param year Integer season-start year (e.g. 2006 for the 2006/07 season).
#' @return Long tibble with one row per flowering observation.
#' @export
process_year <- function(a, year) {
  keep_cols <- paste0("X", 5:dim(a)[2])

  df <- a |>
    dplyr::select(dplyr::all_of(c("X1", keep_cols))) |>
    tidyr::gather(key = "column", value = "flower_date", -"X1") |>
    dplyr::filter(!is.na(.data$flower_date))

  df$year <- year
  df$date <- lubridate::dmy(df$flower_date, truncated = 1)

  # Season wraps on month, not on the year dmy() fills in: Jul-Dec belong to the
  # season-start year, Jan-Jun to the following year.
  df$date_fixed <- lubridate::ymd(ifelse(
    lubridate::month(df$date) >= 7,
    format(df$date, paste0(year, "-%m-%d")),
    format(df$date, paste0(year + 1, "-%m-%d"))
  ))
  df$days_after_1july <- df$date_fixed - lubridate::ymd(paste0(year, "-07-01"))
  df
}

# Default mapping of KossyFlowers sheet basenames -> season-start year.
.kossy_sheets <- function() {
  tibble_like <- list(
    KossyFlowers06_07 = 2006, KossyFlowers07_08 = 2007, KossyFlowers08_09 = 2008,
    KossyFlowers09_10 = 2009, KossyFlowers10_11 = 2010, KossyFlowers11_12 = 2011,
    KossyFlowers12_13 = 2012, KossyFlowers13_14 = 2013, KossyFlowers14_15 = 2014,
    KossyFlowers15_16 = 2015, KossyFlowers16_17 = 2016, KossyFlowers18_19 = 2018
  )
  tibble_like
}

#' Load and process all KossyFlowers sheets into tidy flowering dates
#'
#' @param raw_dir Directory holding the KossyFlowers CSVs and the
#'   `WIF_correctnames.csv` name-fix table.
#' @param sheets Named list mapping sheet basename -> season-start year. Defaults
#'   to the twelve surveyed seasons (2017/18 was not surveyed).
#' @param correctnames Basename of the name-fix table in `raw_dir`.
#' @return Tibble with columns species, date_fixed, days_after_1july, year.
#' @export
load_flowering_dates <- function(raw_dir,
                                  sheets = .kossy_sheets(),
                                  correctnames = "WIF_correctnames.csv") {
  rd <- function(f) readr::read_csv(file.path(raw_dir, f), col_names = FALSE,
                                    show_col_types = FALSE)

  df <- do.call(dplyr::bind_rows, Map(function(sheet, yr) process_year(rd(sheet), yr),
                                      names(sheets), unlist(sheets)))

  correct_names <- readr::read_csv(file.path(raw_dir, correctnames),
                                   show_col_types = FALSE)

  df$fixed_name <- ifelse(
    df$X1 %in% correct_names$badName,
    correct_names$goodName[match(df$X1, correct_names$badName)],
    df$X1
  )
  df$fixed_name2 <- gsub(" s.l.", "", df$fixed_name, fixed = TRUE)

  df |>
    dplyr::rename(species = "fixed_name2") |>
    dplyr::select("species", "date_fixed", "days_after_1july", "year")
}
