# Tests for monthly-temperature loading (R/climate.R).

test_that("load_monthly_means reads a monthly-means CSV", {
  path <- file.path(tempdir(), "monthly_means.csv")
  on.exit(unlink(path), add = TRUE)

  readr::write_csv(
    dplyr::tibble(
      year = c(2006, 2007),
      aug_mean = c(1.1, 1.2), sept_mean = c(2.1, 2.2),
      oct_mean = c(3.1, 3.2), nov_mean = c(4.1, 4.2),
      dec_mean = c(5.1, 5.2)
    ),
    path
  )

  out <- load_monthly_means(path)

  expect_equal(nrow(out), 2L)
  expect_named(out, c("year", "aug_mean", "sept_mean", "oct_mean",
                      "nov_mean", "dec_mean"))
  expect_equal(out$oct_mean, c(3.1, 3.2))
})
