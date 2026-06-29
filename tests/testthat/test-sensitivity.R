# Tests for temperature-sensitivity fitting (R/sensitivity.R).
#
# Test data uses residuals orthogonal to the predictor (sum to 0 and
# uncorrelated with x), so the OLS slope stays an exact integer while the fit
# is imperfect -- giving a genuine, positive standard error.

test_that("temp_slope and temp_se_slope recover an OLS slope", {
  x <- c(1, 2, 3, 4)
  y <- 2 * x + 1 + c(1, -1, -1, 1)  # slope exactly 2, non-zero residuals

  expect_equal(temp_slope(y, x), 2)
  expect_gt(temp_se_slope(y, x), 0)
})

test_that("fit_temp_sensitivity returns per-group slope and SE", {
  data <- dplyr::tibble(
    sp       = rep(c("a", "b"), each = 4),
    oct_mean = rep(c(1, 2, 3, 4), times = 2),
    begin    = c(4, 4, 6, 10,    # a: slope +2
                 0, -3, -4, -3)  # b: slope -1
  )

  out <- fit_temp_sensitivity(data, response = "begin", predictor = "oct_mean")

  # Default column names derived from inputs.
  expect_named(out, c("sp", "oct_mean_slope_begin", "oct_mean_slope_begin_se"))
  expect_equal(out$oct_mean_slope_begin[out$sp == "a"], 2)
  expect_equal(out$oct_mean_slope_begin[out$sp == "b"], -1)
  expect_true(all(out$oct_mean_slope_begin_se > 0))
})

test_that("fit_temp_sensitivity honours custom names and grouping column", {
  data <- dplyr::tibble(
    taxon = rep(c("a", "b"), each = 4),
    temp  = rep(c(1, 2, 3, 4), times = 2),
    onset = c(4, 4, 6, 10,     # a: slope +2
              0, -3, -4, -3)   # b: slope -1
  )

  out <- fit_temp_sensitivity(
    data, response = "onset", predictor = "temp", group = "taxon",
    slope_name = "sens", se_name = "sens_se"
  )

  expect_named(out, c("taxon", "sens", "sens_se"))
  expect_equal(out$sens[out$taxon == "a"], 2)
  expect_equal(out$sens[out$taxon == "b"], -1)
})
