# Tests for raw walk-data ingestion (R/ingest.R).

test_that("process_year reshapes to long and computes day-of-season", {
  a <- dplyr::tibble(
    X1 = c("Species a", "Species b"),
    X2 = NA, X3 = NA, X4 = NA,
    X5 = c("15-08", "20-01")  # Aug = season-start year, Jan = following year
  )

  out <- process_year(a, 2006)

  expect_equal(nrow(out), 2L)
  expect_setequal(out$X1, c("Species a", "Species b"))
  expect_equal(out$year, c(2006, 2006))
  # Season wrap: Aug stays in 2006, Jan rolls into 2007.
  expect_equal(as.character(out$date_fixed), c("2006-08-15", "2007-01-20"))
  # Days after 1 July: 15 Aug -> 45, 20 Jan -> 203.
  expect_equal(as.numeric(out$days_after_1july), c(45, 203))
})

test_that("process_year drops blank flowering cells", {
  a <- dplyr::tibble(
    X1 = c("Species a", "Species b"),
    X2 = NA, X3 = NA, X4 = NA,
    X5 = c("15-08", NA)
  )
  out <- process_year(a, 2006)
  expect_equal(nrow(out), 1L)
  expect_equal(out$X1, "Species a")
})

test_that("load_flowering_dates binds sheets, appends .csv, fixes names", {
  raw_dir <- file.path(tempdir(), "kossy_ingest")
  dir.create(raw_dir, showWarnings = FALSE)
  on.exit(unlink(raw_dir, recursive = TRUE), add = TRUE)

  # A no-header sheet: species in col 1, dates from col 5 on.
  writeLines(
    c('"Bad sp",,,,15-08', '"Foo s.l.",,,,20-01'),
    file.path(raw_dir, "KossyFlowers06_07.csv")
  )
  # Name-fix table: bad -> good.
  readr::write_csv(
    dplyr::tibble(badName = "Bad sp", goodName = "Good sp"),
    file.path(raw_dir, "WIF_correctnames.csv")
  )

  out <- load_flowering_dates(
    raw_dir,
    sheets = list(KossyFlowers06_07 = 2006)  # basename without extension
  )

  expect_named(out, c("species", "date_fixed", "days_after_1july", "year"))
  # "Bad sp" -> "Good sp" via the fix table; " s.l." stripped from "Foo s.l.".
  expect_setequal(out$species, c("Good sp", "Foo"))
  expect_equal(sort(as.numeric(out$days_after_1july)), c(45, 203))
})
