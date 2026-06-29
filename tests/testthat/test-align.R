# Tests for name alignment (R/align.R).

test_that("apply_name_alignment substitutes canonical names and keeps unmatched", {
  df <- dplyr::tibble(species = c("x", "y", "z"), value = 1:3)
  alignment <- dplyr::tibble(
    original_name  = c("x", "y"),
    canonical_name = c("X", "Y")
  )

  out <- apply_name_alignment(df, alignment)

  # x/y remapped; z has no entry so coalesce keeps the original.
  expect_equal(out$species, c("X", "Y", "z"))
  # Other columns preserved, helper column dropped.
  expect_equal(out$value, 1:3)
  expect_false("canonical_name" %in% names(out))
})

test_that("align_species_names builds an original->canonical lookup (APC, opt-in)", {
  skip_if_not_installed("APCalign")
  # Hits the network to load taxonomic resources; only run when asked.
  skip_if_not(identical(Sys.getenv("KOSSYPHEN_TEST_APC"), "true"),
              "set KOSSYPHEN_TEST_APC=true to run the APCalign integration test")

  out <- align_species_names(c("Eucalyptus pauciflora", "Banksia marginata"))

  expect_named(out, c("original_name", "canonical_name"))
  expect_equal(nrow(out), 2L)
  expect_false(any(is.na(out$canonical_name)))
})
