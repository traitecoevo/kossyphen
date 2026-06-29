# Tests for onset estimators (R/onset.R).

test_that("first_flower_onset returns the earliest day per species-year", {
  df <- dplyr::tibble(
    species          = c("a", "a", "a", "b", "b"),
    year             = c(2006, 2006, 2007, 2006, 2006),
    days_after_1july = c(40, 20, 55, 80, NA)
  )

  out <- first_flower_onset(df)

  expect_named(out, c("sp", "year", "begin"))
  # a/2006 -> min(40,20) = 20; a/2007 -> 55; b/2006 -> 80 (NA ignored).
  expect_equal(out$begin[out$sp == "a" & out$year == 2006], 20)
  expect_equal(out$begin[out$sp == "a" & out$year == 2007], 55)
  expect_equal(out$begin[out$sp == "b" & out$year == 2006], 80)
})

test_that("weibull_onset/offset return finite limits with onset before offset", {
  skip_if_not_installed("phest")
  set.seed(42)
  days <- sort(round(runif(12, 10, 200)))

  onset  <- weibull_onset(days)
  offset <- weibull_offset(days)

  expect_true(is.finite(onset))
  expect_true(is.finite(offset))
  expect_lt(onset, offset)
})

test_that("weibull_fits keeps only species-years above min_obs", {
  skip_if_not_installed("phest")
  set.seed(7)
  df <- dplyr::bind_rows(
    # Well-sampled: 8 observations -> kept.
    dplyr::tibble(species = "a", year = 2006,
                  days_after_1july = sort(round(runif(8, 30, 150)))),
    # Sparse: 3 observations -> dropped (need > 5).
    dplyr::tibble(species = "b", year = 2006,
                  days_after_1july = c(40, 60, 90))
  )

  out <- weibull_fits(df)

  expect_equal(nrow(out), 1L)
  expect_equal(out$sp, "a")
  expect_named(out, c("yearsp", "begin", "end", "peak", "sp", "year", "duration"))
  expect_equal(out$peak, (out$begin + out$end) / 2)
  expect_equal(out$duration, out$end - out$begin)
})
