# Monthly mean temperature loading.

#' Load monthly mean temperatures
#'
#' Reads a CSV of yearly monthly means (columns: year, aug_mean, sept_mean,
#' oct_mean, nov_mean, dec_mean), as used by both pipelines.
#'
#' @param path Path to the monthly-means CSV.
#' @return Tibble of monthly means by year.
#' @export
load_monthly_means <- function(path) {
  readr::read_csv(path, show_col_types = FALSE)
}
