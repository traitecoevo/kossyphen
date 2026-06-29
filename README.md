# kossyphen

**Shared methods for Kosciuszko alpine flowering phenology.**

`kossyphen` is a small R package that holds the analytical building blocks shared
by two manuscripts working from the same long-term dataset:

- the observational **"What's in Flower"** paper, and
- the experimental/observational **synthesis (honours thesis)** paper.

Both manuscripts analyse the Gibson & Green flowering-walk dataset from Kosciuszko
National Park. Rather than copy-paste the ingestion, name-cleaning, onset, and
temperature-sensitivity code into each pipeline (and watch them silently drift
apart), the shared steps live here once. The two pipelines `import` `kossyphen`
and call the same functions, so the manuscripts **share a method without sharing a
pipeline** — each keeps its own data wrangling, figures, and narrative.

## Why this package exists

When the same method is pasted into two analyses, a fix in one place is a bug in
the other. `kossyphen` is the single source of truth for the steps both papers
agree on:

| Step | Question it answers | Functions |
|------|---------------------|-----------|
| **Ingest** | How do raw yearly walk sheets become tidy flowering observations? | `process_year()`, `load_flowering_dates()` |
| **Align names** | How do messy recorded names map onto canonical Australian Plant Census names? | `align_species_names()`, `apply_name_alignment()` |
| **Climate** | How are monthly mean temperatures loaded? | `load_monthly_means()` |
| **Onset** | When did a species start (and stop) flowering in a season? | `weibull_onset()`, `weibull_offset()`, `weibull_fits()`, `first_flower_onset()` |
| **Sensitivity** | How much does flowering shift per degree of warming? | `temp_slope()`, `temp_se_slope()`, `fit_temp_sensitivity()` |

Where the two pipelines genuinely differ, the package offers both options rather
than forcing a choice. Onset is the clearest example: the observational pipeline
uses the **Weibull limit** (Pearse et al. 2017), which needs ≥ 6 observations per
species-year; the synthesis pipeline uses **first-flower** onset so that sparsely
sampled taxa are still included. Both definitions live here side by side.

## Installation

```r
# install.packages("remotes")
remotes::install_local("path/to/kossyphen")
```

Hard dependencies (`dplyr`, `tidyr`, `readr`, `lubridate`, `stringr`, `rlang`)
install automatically. Three capabilities are optional and only loaded when used:

- **`phest`** — Weibull onset/offset limits (`weibull_onset()`, `weibull_fits()`).
- **`APCalign`** — Australian Plant Census name alignment (`align_species_names()`).
- **`googledrive`** — only if your pipeline pulls the raw sheets from Drive.

Functions that need an optional package check for it and stop with a clear message
if it is missing, so you only need to install what your pipeline actually calls.

## The pipeline at a glance

```
raw KossyFlowers CSVs ──► load_flowering_dates() ──► tidy flowering observations
                                                          │
                          align_species_names() ──────────┤  (canonical names)
                          apply_name_alignment() ◄─────────┘
                                                          │
   ┌──────────────────────────────────────────────────────┤
   ▼                                                        ▼
 weibull_fits()                                      first_flower_onset()
 (Weibull onset/end,                                 (earliest day per
  ≥ 6 obs/species-year)                               species-year)
   │                                                        │
   └─────────────────► onset table per species-year ◄───────┘
                                  │
                  join to load_monthly_means()
                                  │
                                  ▼
                        fit_temp_sensitivity()
              (slope of onset on temperature, per species)
```

## Worked example

```r
library(kossyphen)

# 1. Ingest every yearly walk sheet in `raw_dir` into one tidy table.
#    Expects the KossyFlowers CSVs plus a `WIF_correctnames.csv` name-fix table.
flowering <- load_flowering_dates(raw_dir = "data-raw")
#> # columns: species, date_fixed, days_after_1july, year

# 2. Crosswalk recorded names onto canonical APC names (needs APCalign).
alignment <- align_species_names(unique(flowering$species))
flowering <- apply_name_alignment(flowering, alignment)

# 3a. Observational onset: Weibull limits (needs phest, ≥ 6 obs/species-year).
onset <- weibull_fits(flowering)
#> # columns: yearsp, begin, end, peak, sp, year, duration

# 3b. ...or synthesis onset: first flower, feasible for sparse taxa.
onset <- first_flower_onset(flowering)
#> # columns: sp, year, begin

# 4. Load monthly mean temperatures and join to the onset table.
climate <- load_monthly_means("data-raw/monthly_means.csv")
onset_climate <- dplyr::left_join(onset, climate, by = "year")

# 5. Per-species temperature sensitivity: how much does onset shift
#    per degree of October warming?
sensitivity <- fit_temp_sensitivity(
  onset_climate,
  response  = "begin",
  predictor = "oct_mean",
  group     = "sp"
)
#> # columns: sp, oct_mean_slope_begin, oct_mean_slope_begin_se
```

## Data conventions

A few assumptions are baked into the ingestion so that both pipelines agree:

- **Season-start year.** A season is named by the year it begins (e.g. 2006 for
  2006/07). Observations from **July–December** belong to the season-start year;
  **January–June** observations roll into the following calendar year. This keeps
  a single flowering season contiguous across the New Year.
- **`days_after_1july`.** All onset/offset timing is measured as days since 1 July
  of the season-start year, so seasons are directly comparable.
- **Surveyed seasons.** The default sheet map covers the twelve surveyed seasons
  from 2006/07 to 2018/19; **2017/18 was not surveyed** and is omitted. Pass a
  custom `sheets` list to `load_flowering_dates()` to override.
- **Name fixes.** `load_flowering_dates()` applies a `WIF_correctnames.csv`
  bad-name → good-name table and strips ` s.l.` qualifiers before any APC
  alignment.

## Function reference

Every exported function carries roxygen documentation in its source file. The
short version:

### Ingestion — `R/ingest.R`
- **`process_year(a, year)`** — turn one raw KossyFlowers sheet (read with
  `col_names = FALSE`) into long format, one row per flowering observation.
- **`load_flowering_dates(raw_dir, sheets, correctnames, ext)`** — process and
  bind all yearly sheets, apply name fixes, and return the tidy table.

### Name alignment — `R/align.R`
- **`align_species_names(flowering_names, trait_names, resources)`** — build an
  `original_name → canonical_name` lookup via the Australian Plant Census. Pass
  `trait_names` to map onto trait-table / phylogeny-tip spellings.
- **`apply_name_alignment(df, alignment)`** — replace `species` in a flowering
  table with its canonical name.

### Climate — `R/climate.R`
- **`load_monthly_means(path)`** — read a CSV of yearly monthly means
  (`year`, `aug_mean`, `sept_mean`, `oct_mean`, `nov_mean`, `dec_mean`).

### Onset — `R/onset.R`
- **`weibull_onset(days)` / `weibull_offset(days)`** — Weibull lower/upper flowering
  limits for a vector of day-of-season values (Pearse et al. 2017).
- **`weibull_fits(df, min_obs)`** — per species-year onset, end, peak, and
  duration; keeps only species-years with `> min_obs` observations.
- **`first_flower_onset(df)`** — earliest recorded day-of-season per species-year;
  the sparse-data-friendly onset used by the synthesis pipeline.

### Temperature sensitivity — `R/sensitivity.R`
- **`temp_slope(y, x)` / `temp_se_slope(y, x)`** — slope and standard error of a
  simple OLS fit.
- **`fit_temp_sensitivity(data, response, predictor, group, ...)`** — per-group
  slope + SE of a phenophase regressed on a temperature column (e.g.
  `begin ~ oct_mean` per species).

## Provenance

These functions are faithful generalisations of the original `whats_in_flower`
pipeline code (`processData.R`, `align_names.R`, `phestAnalysis.R`,
`match_climate_data.R`), refactored to take explicit paths/arguments so they can
be shared. Behaviour is intended to match the originals.

## License

MIT © Will Cornwell. See [LICENSE](LICENSE).
