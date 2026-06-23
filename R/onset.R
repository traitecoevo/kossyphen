# Onset estimators: Weibull limits (Pearse et al. 2017) and first-flower.

#' Weibull onset (lower limit) for a vector of day-of-season values
#' @param days Numeric vector of days (e.g. days after 1 July).
#' @return Estimated onset day.
#' @export
weibull_onset <- function(days) {
  if (!requireNamespace("phest", quietly = TRUE)) {
    stop("Package 'phest' is required for Weibull onset.")
  }
  as.numeric(phest::weib.limit(sort(as.numeric(days)))[1])
}

#' Weibull offset (upper limit) for a vector of day-of-season values
#' @inheritParams weibull_onset
#' @return Estimated end (offset) day.
#' @export
weibull_offset <- function(days) {
  if (!requireNamespace("phest", quietly = TRUE)) {
    stop("Package 'phest' is required for Weibull offset.")
  }
  as.numeric(phest::weib.limit(sort(as.numeric(days)), upper = TRUE)[1])
}

#' Weibull onset/end/peak/duration per species-year
#'
#' Mirrors whats_in_flower/R/phestAnalysis.R: keeps only species-years with
#' more than `min_obs` observations (the Weibull limit needs >= 6), then fits
#' lower/upper limits.
#'
#' @param df Flowering data with columns species, year, days_after_1july.
#' @param min_obs Minimum observations per species-year (default 5, i.e. > 5).
#' @return Tibble: yearsp, begin, end, peak, sp, year, duration.
#' @export
weibull_fits <- function(df, min_obs = 5) {
  df <- dplyr::filter(df, !is.na(.data$days_after_1july))
  df$yearsp <- paste0(df$species, df$year)

  counts <- df |>
    dplyr::group_by(.data$yearsp) |>
    dplyr::summarize(n = dplyr::n(), .groups = "drop")
  good <- counts$yearsp[counts$n > min_obs]
  df <- dplyr::filter(df, .data$yearsp %in% good)

  df |>
    dplyr::group_by(.data$species, .data$year) |>
    dplyr::summarize(
      begin = weibull_onset(.data$days_after_1july),
      end   = weibull_offset(.data$days_after_1july),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      peak     = (.data$begin + .data$end) / 2,
      duration = .data$end - .data$begin,
      yearsp   = paste0(.data$species, .data$year),
      sp       = .data$species
    ) |>
    dplyr::select("yearsp", "begin", "end", "peak", "sp", "year", "duration")
}

#' First-flower onset per species-year
#'
#' The earliest recorded day-of-season per species-year. Feasible for sparsely
#' sampled taxa where the Weibull limit cannot be fit; used by the synthesis
#' pipeline so all taxa share one onset definition.
#'
#' @param df Flowering data with columns species, year, days_after_1july.
#' @return Tibble: sp, year, begin (first-flower onset).
#' @export
first_flower_onset <- function(df) {
  df |>
    dplyr::filter(!is.na(.data$days_after_1july)) |>
    dplyr::group_by(.data$species, .data$year) |>
    dplyr::summarize(begin = min(as.numeric(.data$days_after_1july)),
                     .groups = "drop") |>
    dplyr::rename(sp = "species")
}
