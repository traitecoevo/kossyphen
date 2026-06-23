# Per-species temperature-sensitivity slopes.
# Faithful to whats_in_flower/R/match_climate_data.R temp_slope/temp_se_slope.

#' Slope of an OLS fit of `y` on a single predictor
#' @param y Response vector.
#' @param x Predictor vector.
#' @return The slope coefficient.
#' @export
temp_slope <- function(y, x) {
  unname(stats::coef(stats::lm(y ~ x))[2])
}

#' Standard error of the slope of an OLS fit of `y` on a single predictor
#' @inheritParams temp_slope
#' @return The slope standard error.
#' @export
temp_se_slope <- function(y, x) {
  s <- summary(stats::lm(y ~ x))
  s$coefficients[2, 2]
}

#' Per-group temperature sensitivity (slope + SE)
#'
#' For each level of `group`, regresses `response` on `predictor` and returns
#' the slope and its standard error. This is the engine behind both pipelines'
#' per-species sensitivities (e.g. begin ~ oct_mean).
#'
#' @param data Data frame with one row per group-year.
#' @param response Name of the phenophase column (e.g. "begin").
#' @param predictor Name of the temperature column (e.g. "oct_mean").
#' @param group Grouping column (default "sp").
#' @param slope_name,se_name Output column names; default derived from inputs.
#' @return Tibble: <group>, <slope_name>, <se_name>.
#' @export
fit_temp_sensitivity <- function(data, response, predictor, group = "sp",
                                 slope_name = NULL, se_name = NULL) {
  if (is.null(slope_name)) slope_name <- paste0(predictor, "_slope_", response)
  if (is.null(se_name))    se_name    <- paste0(slope_name, "_se")

  data |>
    dplyr::group_by(.data[[group]]) |>
    dplyr::summarize(
      "{slope_name}" := temp_slope(.data[[response]], .data[[predictor]]),
      "{se_name}"    := temp_se_slope(.data[[response]], .data[[predictor]]),
      .groups = "drop"
    )
}
