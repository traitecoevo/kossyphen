# Australian Plant Census name alignment (APCalign).
# Faithful to whats_in_flower/R/align_names.R, generalised.

#' Build a name-alignment lookup via the Australian Plant Census
#'
#' Crosswalks messy recorded flowering names onto canonical names. When
#' `trait_names` is supplied, two names sharing an APC-accepted name are mapped
#' to the trait-table spelling (which matches the phylogeny tips); otherwise the
#' bare accepted name is used.
#'
#' @param flowering_names Character vector of recorded species names.
#' @param trait_names Optional character vector of canonical/trait names.
#' @param resources APCalign taxonomic resources; loaded if NULL.
#' @return Tibble with columns original_name, canonical_name.
#' @export
align_species_names <- function(flowering_names, trait_names = NULL,
                                resources = NULL) {
  if (!requireNamespace("APCalign", quietly = TRUE)) {
    stop("Package 'APCalign' is required for align_species_names().")
  }
  if (is.null(resources)) resources <- APCalign::load_taxonomic_resources()

  fix_spacing <- function(x) stringr::str_squish(gsub("subsp\\.", " subsp. ", x))

  accepted_of <- function(names) {
    lu <- APCalign::create_taxonomic_update_lookup(
      names, resources = resources, taxonomic_splits = "most_likely_species"
    )
    dplyr::transmute(
      lu,
      input = .data$original_name,
      accepted = stringr::str_squish(gsub("\\[.*\\]", "", .data$suggested_name))
    )
  }

  flowering_clean <- unique(fix_spacing(flowering_names))
  acc_flower <- accepted_of(flowering_clean) |>
    dplyr::rename(flowering_name = "input")

  if (!is.null(trait_names)) {
    acc_trait <- accepted_of(unique(trait_names)) |>
      dplyr::rename(trait_name = "input")
    alignment <- acc_flower |>
      dplyr::left_join(acc_trait, by = "accepted") |>
      dplyr::mutate(canonical_name = dplyr::coalesce(.data$trait_name, .data$accepted)) |>
      dplyr::select("accepted", "flowering_name", "canonical_name")
  } else {
    alignment <- acc_flower |>
      dplyr::mutate(canonical_name = .data$accepted) |>
      dplyr::select("accepted", "flowering_name", "canonical_name")
  }

  tibble_names <- data.frame(original_name = unique(flowering_names),
                             stringsAsFactors = FALSE)
  tibble_names$flowering_name <- fix_spacing(tibble_names$original_name)
  tibble_names |>
    dplyr::left_join(alignment, by = "flowering_name") |>
    dplyr::mutate(canonical_name = dplyr::coalesce(.data$canonical_name,
                                                   .data$original_name)) |>
    dplyr::select("original_name", "canonical_name")
}

#' Apply a name-alignment lookup to a flowering-dates table
#'
#' @param df Flowering data with a `species` column.
#' @param alignment Lookup from [align_species_names()].
#' @return `df` with `species` replaced by canonical names.
#' @export
apply_name_alignment <- function(df, alignment) {
  df |>
    dplyr::left_join(alignment, by = c("species" = "original_name")) |>
    dplyr::mutate(species = dplyr::coalesce(.data$canonical_name, .data$species)) |>
    dplyr::select(-"canonical_name")
}
