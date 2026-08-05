# ==============================================================================
# Publication figures v2: retrofit-need correlations and decile transitions
#
# Inputs (expected in the same project directory as this script):
#   - rtft_indx_imd_corr_df.csv
#   - rtrft_lsoa11_lad_v4.csv (or its updated v4a replacement)
#
# Outputs:
#   - publication_plots_v2/*.png (600 dpi)
#   - publication_plots_v2/*.pdf (vector)
#   - publication_plots_v2/retrofit_decile_change_breakdown_by_region_v2.csv
#
# If needed, install the required packages with:
# install.packages(c(
#   "tidyverse", "paletteer", "ggsankeyfier", "patchwork", "scales", "ragg"
# ))
# ==============================================================================

required_packages <- c(
  "tidyverse",
  "paletteer",
  "ggsankeyfier",
  "patchwork",
  "scales",
  "ragg"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0L) {
  stop(
    "Install the following packages before running this script: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(paletteer)
  library(ggsankeyfier)
  library(patchwork)
})

# Locate the project directory whether the script is run with Rscript or sourced
# interactively from RStudio.
command_args <- commandArgs(trailingOnly = FALSE)
run_args <- commandArgs(trailingOnly = TRUE)
national_heatmaps_only <- "--national-heatmaps-only" %in% run_args
combined_figures_only <- "--combined-figures-only" %in% run_args
breakdown_table_only <- "--breakdown-table-only" %in% run_args
file_arg <- grep("^--file=", command_args, value = TRUE)
script_dir <- if (length(file_arg) == 1L) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else {
  getwd()
}

correlation_filename <- "rtft_indx_imd_corr_df.csv"
retrofit_filenames <- c(
  "rtrft_lsoa11_lad_v4.csv",
  "rtrft_lsoa11_lad_v4a.csv"
)

# input/output directory
candidate_dirs <- file.path(getwd(), outputs_dir)

# candidate_dirs <- unique(c(getwd(), script_dir, dirname(script_dir)))
project_dir <- candidate_dirs[
  vapply(
    candidate_dirs,
    \(path) {
      file.exists(file.path(path, correlation_filename)) &&
        any(file.exists(file.path(path, retrofit_filenames)))
    },
    logical(1)
  )
][1]

if (is.na(project_dir)) {
  stop(
    "Could not find the correlation CSV and either retrofit v4 or v4a CSV. ",
    "Run this script from the project directory or keep it beside the inputs.",
    call. = FALSE
  )
}

# create output directory
# outputs_dir <- file.path(getwd(), "outputs") #omit since created on main rmd file

# if it doesn't already exist
if(!dir.exists(outputs_dir)){
  dir.create(outputs_dir)
}

correlation_path <- file.path(project_dir, correlation_filename)
retrofit_candidates <- file.path(project_dir, retrofit_filenames)
retrofit_path <- retrofit_candidates[file.exists(retrofit_candidates)][1]

assert_columns <- function(data, required, data_name) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      data_name,
      " is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

save_publication_plot <- function(
    plot,
    stem,
    width,
    height,
    output_directory = outputs_dir) {
  png_path <- file.path(output_directory, paste0(stem, ".png"))
  pdf_path <- file.path(output_directory, paste0(stem, ".pdf"))

  ggsave(
    filename = png_path,
    plot = plot,
    device = ragg::agg_png,
    width = width,
    height = height,
    units = "in",
    dpi = 600,
    bg = "white"
  )

  ggsave(
    filename = pdf_path,
    plot = plot,
    device = grDevices::pdf,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )

  invisible(c(png_path, pdf_path))
}

theme_manuscript <- function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = element_text(
        face = "bold",
        size = rel(1.35),
        colour = "#161616",
        margin = margin(b = 6)
      ),
      plot.subtitle = element_text(
        colour = "#4A4A4A",
        lineheight = 1.08,
        margin = margin(b = 12)
      ),
      plot.caption = element_text(
        colour = "#5F5F5F",
        size = rel(0.78),
        hjust = 0,
        margin = margin(t = 10)
      ),
      axis.title = element_text(face = "bold", colour = "#292929"),
      axis.text = element_text(colour = "#292929"),
      legend.title = element_text(face = "bold"),
      legend.position = "bottom",
      legend.justification = "left",
      plot.margin = margin(12, 18, 12, 12)
    )
}

# ------------------------------------------------------------------------------
# 1. Correlation plot
# ------------------------------------------------------------------------------

correlation_raw <- readr::read_csv(
  correlation_path,
  show_col_types = FALSE,
  progress = FALSE
)

assert_columns(
  correlation_raw,
  c("variables", "corr", "pvalue"),
  "rtft_indx_imd_corr_df.csv"
)

if (
  anyNA(correlation_raw$corr) ||
    any(!is.finite(correlation_raw$corr)) ||
    any(abs(correlation_raw$corr) > 1)
) {
  stop(
    "Column 'corr' must contain complete correlation coefficients from -1 to 1.",
    call. = FALSE
  )
}

# Explicit labels improve readability; the fallback below also ensures that any
# future variables have underscores removed.
correlation_label_lookup <- c(
  index_of_multiple_deprivation_imd_score =
    "Index of Multiple Deprivation (IMD) score",
  income_score_rate =
    "Income score rate",
  employment_score_rate =
    "Employment score rate",
  health_deprivation_and_disability_score =
    "Health deprivation and disability score",
  adult_skills_sub_domain_score =
    "Adult skills sub-domain score",
  education_skills_and_training_score =
    "Education, skills and training score",
  crime_score =
    "Crime score",
  geographical_barriers_sub_domain_score =
    "Geographical barriers sub-domain score",
  wider_barriers_sub_domain_score =
    "Wider barriers sub-domain score",
  living_environment_score =
    "Living environment score",
  indoors_sub_domain_score =
    "Indoors sub-domain score",
  epc_lss_eql_d_prcnt =
    "Properties rated EPC D or below (%)",
  outdoors_sub_domain_score =
    "Outdoors sub-domain score",
  barriers_to_housing_and_services_score =
    "Barriers to housing and services score"
)

tidy_variable_labels <- function(variable) {
  fallback <- variable |>
    str_replace_all("_", " ") |>
    str_squish() |>
    str_to_sentence()

  matched <- unname(correlation_label_lookup[variable])
  if_else(is.na(matched), fallback, matched)
}

correlation_data <- correlation_raw |>
  transmute(
    variable = variables,
    variable_label = tidy_variable_labels(variables),
    correlation = as.numeric(corr),
    absolute_correlation = abs(correlation)
  ) |>
  arrange(desc(absolute_correlation), desc(correlation)) |>
  mutate(
    variable_label = factor(
      variable_label,
      levels = rev(unique(variable_label))
    ),
    value_label = scales::number(
      correlation,
      accuracy = 0.01,
      trim = TRUE
    )
  )

# "vik" is a perceptually uniform, colour-vision-conscious diverging palette.
# Reversing it assigns red to negative values and blue to positive values.
correlation_colours <- rev(
  as.character(paletteer::paletteer_c("scico::vik", n = 256))
)

correlation_plot <- ggplot(
  correlation_data,
  aes(
    x = variable_label,
    y = absolute_correlation,
    fill = correlation
  )
) +
  geom_hline(
    yintercept = 0,
    colour = "#4B4B4B",
    linewidth = 0.45
  ) +
  geom_col(width = 0.72) +
  geom_text(
    aes(label = value_label),
    hjust = -0.12,
    size = 3.2,
    colour = "#111111"
  ) +
  coord_flip(clip = "off") +
  scale_y_continuous(
    limits = c(0, 0.90),
    breaks = seq(0, 0.8, by = 0.2),
    labels = scales::label_number(accuracy = 0.1),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_fill_gradientn(
    colours = correlation_colours,
    limits = c(-1, 1),
    values = scales::rescale(c(-1, 0, 1)),
    oob = scales::squish,
    breaks = c(-1, -0.5, 0, 0.5, 1),
    labels = scales::label_number(accuracy = 0.1),
    name = "Pearson correlation (r)"
  ) +
  guides(
    fill = guide_colourbar(
      title.position = "top",
      title.hjust = 0,
      barwidth = grid::unit(9, "cm"),
      barheight = grid::unit(0.42, "cm"),
      ticks.colour = "#3A3A3A",
      frame.colour = "#7A7A7A"
    )
  ) +
  labs(
    title = "Correlations with the housing retrofit need index",
    subtitle = paste(
      "Bar lengths show absolute Pearson correlation coefficients.",
      "Colours and labels retain the direction of each correlation."
    ),
    x = NULL,
    y = "Absolute Pearson correlation coefficient (|r|)",
    caption = paste(
      "Positive correlations are shown in blue and negative correlations in red;",
      "colour intensity is scaled to the full theoretical range (−1 to +1)."
    )
  ) +
  theme_manuscript(base_size = 11) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(
      colour = "#D9D9D9",
      linewidth = 0.35
    ),
    axis.text.y = element_text(size = 10),
    axis.ticks.x = element_line(colour = "#5A5A5A"),
    legend.margin = margin(t = 2)
  )

# ------------------------------------------------------------------------------
# 2–3. Sankey plots: local authorities and LSOAs
# ------------------------------------------------------------------------------

retrofit_raw <- readr::read_csv(
  retrofit_path,
  show_col_types = FALSE,
  progress = FALSE
)

required_retrofit_columns <- c(
  "LAD20CD",
  "LAD20NM",
  "LSOA11CD",
  "cvnl_lad_indx_dcl",
  "fll_lad_indx_dcl",
  "mini_lsoa_indx_dcl",
  "fll_lsoa_indx_dcl",
  "RGN11NM"
)

assert_columns(
  retrofit_raw,
  required_retrofit_columns,
  basename(retrofit_path)
)

decile_columns <- c(
  "cvnl_lad_indx_dcl",
  "fll_lad_indx_dcl",
  "mini_lsoa_indx_dcl",
  "fll_lsoa_indx_dcl"
)

invalid_decile <- retrofit_raw |>
  select(all_of(decile_columns)) |>
  summarise(
    across(
      everything(),
      \(x) any(is.na(x) | !x %in% 1:10)
    )
  ) |>
  unlist(use.names = FALSE) |>
  any()

if (invalid_decile) {
  stop(
    "All four decile columns must be complete integers from 1 to 10.",
    call. = FALSE
  )
}

# Every row for a given authority should carry the same authority-level pair.
lad_consistency <- retrofit_raw |>
  group_by(LAD20CD) |>
  summarise(
    n_names = n_distinct(LAD20NM),
    n_regions = n_distinct(RGN11NM),
    n_conventional_deciles = n_distinct(cvnl_lad_indx_dcl),
    n_enhanced_deciles = n_distinct(fll_lad_indx_dcl),
    .groups = "drop"
  )

if (
  any(lad_consistency$n_names != 1L) ||
    any(lad_consistency$n_regions != 1L) ||
    any(lad_consistency$n_conventional_deciles != 1L) ||
    any(lad_consistency$n_enhanced_deciles != 1L)
) {
  stop(
    paste(
      "Authority names, regions, or authority-level deciles are",
      "inconsistent within LAD20CD."
    ),
    call. = FALSE
  )
}

# Count each local authority once, not once for every LSOA within it.
lad_units <- retrofit_raw |>
  distinct(
    LAD20CD,
    LAD20NM,
    RGN11NM,
    cvnl_lad_indx_dcl,
    fll_lad_indx_dcl
  ) |>
  transmute(
    unit_id = LAD20CD,
    region = RGN11NM,
    conventional_decile = as.integer(cvnl_lad_indx_dcl),
    enhanced_decile = as.integer(fll_lad_indx_dcl)
  )

# The source has one record per LSOA; this check prevents accidental double
# counting if the source structure changes later.
lsoa_units <- retrofit_raw |>
  distinct(
    LSOA11CD,
    RGN11NM,
    mini_lsoa_indx_dcl,
    fll_lsoa_indx_dcl
  ) |>
  transmute(
    unit_id = LSOA11CD,
    region = RGN11NM,
    conventional_decile = as.integer(mini_lsoa_indx_dcl),
    enhanced_decile = as.integer(fll_lsoa_indx_dcl)
  )

if (nrow(lsoa_units) != n_distinct(lsoa_units$unit_id)) {
  stop(
    paste(
      "At least one LSOA11CD has more than one",
      "Conventional/Enhanced Index decile pairing."
    ),
    call. = FALSE
  )
}

region_levels <- c(
  "North East",
  "North West",
  "Yorkshire and The Humber",
  "East Midlands",
  "West Midlands",
  "East of England",
  "London",
  "South East",
  "South West"
)

observed_regions <- sort(unique(retrofit_raw$RGN11NM))
if (!setequal(observed_regions, region_levels)) {
  stop(
    paste0(
      "RGN11NM must contain the expected nine English regions. Found: ",
      paste(observed_regions, collapse = ", ")
    ),
    call. = FALSE
  )
}

lad_units <- lad_units |>
  mutate(region = factor(region, levels = region_levels))

lsoa_units <- lsoa_units |>
  mutate(region = factor(region, levels = region_levels))

# ------------------------------------------------------------------------------
# National and regional decile-change breakdown table
# ------------------------------------------------------------------------------

summarise_decile_changes <- function(unit_data) {
  national_summary <- unit_data |>
    summarise(
      Region = "England",
      changed_n = sum(conventional_decile != enhanced_decile),
      total_n = n(),
      newly_prioritised_n = sum(
        enhanced_decile == 1 & conventional_decile != 1
      ),
      enhanced_highest_need_n = sum(enhanced_decile == 1)
    )

  regional_summary <- unit_data |>
    group_by(region) |>
    summarise(
      changed_n = sum(conventional_decile != enhanced_decile),
      total_n = n(),
      newly_prioritised_n = sum(
        enhanced_decile == 1 & conventional_decile != 1
      ),
      enhanced_highest_need_n = sum(enhanced_decile == 1),
      .groups = "drop"
    ) |>
    transmute(
      Region = as.character(region),
      changed_n,
      total_n,
      newly_prioritised_n,
      enhanced_highest_need_n
    )

  bind_rows(national_summary, regional_summary) |>
    mutate(Region = factor(Region, levels = c("England", region_levels))) |>
    arrange(Region) |>
    mutate(Region = as.character(Region))
}

format_breakdown_metric <- function(numerator, denominator) {
  if_else(
    denominator > 0,
    paste0(
      scales::percent(numerator / denominator, accuracy = 0.1),
      " (",
      scales::comma(numerator, accuracy = 1),
      "/",
      scales::comma(denominator, accuracy = 1),
      ")"
    ),
    "Not applicable"
  )
}

lsoa_breakdown <- summarise_decile_changes(lsoa_units)
lad_breakdown <- summarise_decile_changes(lad_units)

decile_change_breakdown_table <- lsoa_breakdown |>
  left_join(
    lad_breakdown,
    by = "Region",
    suffix = c("_lsoa", "_lad")
  ) |>
  transmute(
    Region,
    `Neighbourhoods changing decile` = format_breakdown_metric(
      changed_n_lsoa,
      total_n_lsoa
    ),
    `Enhanced highest-need neighbourhoods newly prioritised` =
      format_breakdown_metric(
        newly_prioritised_n_lsoa,
        enhanced_highest_need_n_lsoa
      ),
    `Local authorities changing decile` = format_breakdown_metric(
      changed_n_lad,
      total_n_lad
    ),
    `Enhanced highest-need local authorities newly prioritised` =
      format_breakdown_metric(
        newly_prioritised_n_lad,
        enhanced_highest_need_n_lad
      )
  )

breakdown_table_path <- file.path(
  outputs_dir,
  "retrofit_decile_change_breakdown_by_region_v2.csv"
)

export_breakdown_table <- function() {
  readr::write_csv(decile_change_breakdown_table, breakdown_table_path)
  breakdown_table_path
}

decile_labels <- paste("Decile", 1:10)
decile_colours <- as.character(
  paletteer::paletteer_c("scico::batlow", n = 256)
)

make_sankey_data <- function(unit_data, facet_by_region = FALSE) {
  if (facet_by_region) {
    flows <- unit_data |>
      count(
        region,
        conventional_decile,
        enhanced_decile,
        name = "number"
      )

    node_totals <- bind_rows(
      unit_data |>
        count(region, conventional_decile, name = "node_total") |>
        transmute(
          region,
          stage_key = "conventional_stage",
          node_key = paste("Decile", conventional_decile),
          node_total
        ),
      unit_data |>
        count(region, enhanced_decile, name = "node_total") |>
        transmute(
          region,
          stage_key = "enhanced_stage",
          node_key = paste("Decile", enhanced_decile),
          node_total
        )
    )

    additional_aesthetics <- c("destination_decile", "region")
    join_keys <- c("region", "stage_key", "node_key")
  } else {
    flows <- unit_data |>
      count(conventional_decile, enhanced_decile, name = "number")

    node_totals <- bind_rows(
      unit_data |>
        count(conventional_decile, name = "node_total") |>
        transmute(
          stage_key = "conventional_stage",
          node_key = paste("Decile", conventional_decile),
          node_total
        ),
      unit_data |>
        count(enhanced_decile, name = "node_total") |>
        transmute(
          stage_key = "enhanced_stage",
          node_key = paste("Decile", enhanced_decile),
          node_total
        )
    )

    additional_aesthetics <- "destination_decile"
    join_keys <- c("stage_key", "node_key")
  }

  flows <- flows |>
    arrange(conventional_decile, enhanced_decile) |>
    mutate(
      destination_decile = enhanced_decile,
      conventional_stage = factor(
        paste("Decile", conventional_decile),
        levels = decile_labels
      ),
      enhanced_stage = factor(
        paste("Decile", enhanced_decile),
        levels = decile_labels
      )
    )

  # Node heights are proportional to the number of geographic units in each
  # stage/decile. These totals are also added to the node labels so that small
  # differences in height remain transparent to readers.
  sankey_long <- ggsankeyfier::pivot_stages_longer(
    data = flows,
    stages_from = c("conventional_stage", "enhanced_stage"),
    values_from = "number",
    additional_aes_from = additional_aesthetics,
    invert_nodes = TRUE
  ) |>
    mutate(
      stage_key = as.character(stage),
      node_key = as.character(node)
    ) |>
    left_join(node_totals, by = join_keys) |>
    mutate(
      stage = factor(
        stage_key,
        levels = c("conventional_stage", "enhanced_stage"),
        labels = c("Conventional Index", "Enhanced Index")
      ),
      node_label = paste0(
        node_key,
        "\n(n = ",
        scales::comma(node_total),
        ")"
      ),
      node_label_short = str_replace(node_key, "^Decile\\s+", "D")
    )

  if (anyNA(sankey_long$node_total)) {
    stop("Unable to match one or more Sankey nodes to their totals.", call. = FALSE)
  }

  sankey_long
}

make_sankey_plot <- function(
    unit_data,
    title,
    unit_label,
    unit_label_singular,
    facet_by_region = FALSE) {
  sankey_data <- make_sankey_data(
    unit_data,
    facet_by_region = facet_by_region
  ) |>
    mutate(
      plot_node_label = if (facet_by_region) {
        node_label_short
      } else {
        node_label
      }
    )

  total_n <- nrow(unit_data)
  changed_n <- sum(
    unit_data$conventional_decile != unit_data$enhanced_decile
  )
  changed_pct <- changed_n / total_n

  sankey_position <- ggsankeyfier::position_sankey(
    v_space = "auto",
    order = "as_is",
    align = "justify"
  )

  node_text_size <- if (facet_by_region) 1.9 else 2.75
  caption_width <- if (facet_by_region) 190 else 115

  caption_text <- paste(
    "Flows run from the Conventional Index to the Enhanced Index.",
    "Node height and edge width represent the number of geographic units.",
    "Edge colour denotes the destination Enhanced Index decile;",
    "Decile 1 represents the greatest retrofit need."
  )

  if (facet_by_region) {
    caption_text <- paste(
      caption_text,
      paste(
        "Each regional panel is independently scaled for legibility;",
        "node heights and edge widths are comparable within, but not between,",
        "regions."
      )
    )
  }

  sankey_plot <- ggplot(
    sankey_data,
    aes(
      x = stage,
      y = number,
      group = node,
      connector = connector,
      edge_id = edge_id
    )
  ) +
    ggsankeyfier::geom_sankeyedge(
      aes(fill = destination_decile),
      position = sankey_position,
      slope = 0.62,
      colour = NA,
      alpha = 0.82
    ) +
    ggsankeyfier::geom_sankeynode(
      position = sankey_position,
      fill = "#FFFFFF",
      colour = "#343434",
      linewidth = 0.4
    ) +
    geom_text(
      aes(label = plot_node_label),
      stat = "sankeynode",
      position = sankey_position,
      family = "sans",
      fontface = "bold",
      lineheight = 0.95,
      size = node_text_size,
      colour = "#151515"
    ) +
    scale_fill_gradientn(
      colours = decile_colours,
      limits = c(1, 10),
      breaks = 1:10,
      labels = 1:10,
      name = paste(
        "Destination Enhanced Index decile",
        "(1 = greatest retrofit need)",
        sep = "\n"
      )
    ) +
    scale_x_discrete(
      expand = expansion(add = c(0.08, 0.08))
    ) +
    guides(
      fill = guide_colourbar(
        title.position = "top",
        title.hjust = 0,
        barwidth = grid::unit(10, "cm"),
        barheight = grid::unit(0.46, "cm"),
        ticks.colour = "#353535",
        frame.colour = "#7A7A7A"
      )
    ) +
    labs(
      title = title,
      subtitle = sprintf(
        paste0(
          "%s %s; %s %s changed decile (%s). ",
          "Edge width represents the number of %s."
        ),
        scales::comma(total_n),
        unit_label,
        scales::comma(changed_n),
        if_else(changed_n == 1L, unit_label_singular, unit_label),
        scales::percent(changed_pct, accuracy = 0.1),
        unit_label
      ),
      x = NULL,
      y = NULL,
      caption = str_wrap(
        caption_text,
        width = caption_width
      )
    ) +
    theme_manuscript(base_size = 11) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(
        face = "bold",
        size = 11,
        colour = "#202020",
        margin = margin(t = 8)
      ),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      legend.margin = margin(t = 4)
    )

  if (facet_by_region) {
    sankey_plot <- sankey_plot +
      facet_wrap(
        vars(region),
        ncol = 3,
        scales = "free_y",
        axes = "all_x",
        axis.labels = "all_x"
      ) +
      theme(
        strip.background = element_rect(
          fill = "#EEF1F3",
          colour = "#B7BEC3",
          linewidth = 0.4
        ),
        strip.text = element_text(
          face = "bold",
          size = 9.5,
          colour = "#202020",
          margin = margin(5, 5, 5, 5)
        ),
        panel.border = element_rect(
          fill = NA,
          colour = "#CDD1D4",
          linewidth = 0.35
        ),
        panel.spacing.x = grid::unit(2.2, "lines"),
        panel.spacing.y = grid::unit(1.3, "lines"),
        axis.text.x = element_text(size = 8)
      )
  }

  sankey_plot
}

lad_sankey_plot <- make_sankey_plot(
  unit_data = lad_units,
  title = "Change in local-authority retrofit-need deciles",
  unit_label = "local authorities",
  unit_label_singular = "local authority"
)

lsoa_sankey_plot <- make_sankey_plot(
  unit_data = lsoa_units,
  title = "Change in LSOA retrofit-need deciles",
  unit_label = "LSOAs",
  unit_label_singular = "LSOA"
)

lad_sankey_plot_by_region <- make_sankey_plot(
  unit_data = lad_units,
  title = "Regional change in local-authority retrofit-need deciles",
  unit_label = "local authorities",
  unit_label_singular = "local authority",
  facet_by_region = TRUE
)

lsoa_sankey_plot_by_region <- make_sankey_plot(
  unit_data = lsoa_units,
  title = "Regional change in LSOA retrofit-need deciles",
  unit_label = "LSOAs",
  unit_label_singular = "LSOA",
  facet_by_region = TRUE
)

# ------------------------------------------------------------------------------
# 6–9. Heat maps: composition of Enhanced Index deciles
# ------------------------------------------------------------------------------

# "vik" is a perceptually uniform diverging palette. Negative changes are blue,
# zero is the light midpoint, and positive changes are red.
heatmap_colours <- as.character(
  paletteer::paletteer_c("scico::vik", n = 256)
)

make_heatmap_data <- function(unit_data, facet_by_region = FALSE) {
  if (facet_by_region) {
    heatmap_data <- unit_data |>
      count(
        region,
        conventional_decile,
        enhanced_decile,
        name = "number"
      ) |>
      complete(
        region,
        conventional_decile = 1:10,
        enhanced_decile = 1:10,
        fill = list(number = 0L)
      )

    percentage_groups <- c("region", "enhanced_decile")
  } else {
    heatmap_data <- unit_data |>
      count(
        conventional_decile,
        enhanced_decile,
        name = "number"
      ) |>
      complete(
        conventional_decile = 1:10,
        enhanced_decile = 1:10,
        fill = list(number = 0L)
      )

    percentage_groups <- "enhanced_decile"
  }

  heatmap_data |>
    group_by(across(all_of(percentage_groups))) |>
    mutate(
      enhanced_total = sum(number),
      percentage = if_else(
        enhanced_total > 0,
        100 * number / enhanced_total,
        NA_real_
      )
    ) |>
    ungroup() |>
    mutate(
      conventional_decile_plot = factor(
        conventional_decile,
        levels = 1:10
      ),
      # Reverse factor levels so Enhanced Index Decile 1 appears at the top.
      enhanced_decile_plot = factor(
        enhanced_decile,
        levels = 10:1
      ),
      decile_change = conventional_decile - enhanced_decile,
      decile_change_fill = if_else(
        number > 0,
        as.numeric(decile_change),
        NA_real_
      ),
      percentage_label = if_else(
        number > 0,
        sprintf("%.1f", percentage),
        ""
      ),
      label_colour = if_else(
        number > 0 & abs(decile_change) >= 6,
        "#FFFFFF",
        "#161616"
      )
    )
}

make_heatmap_plot <- function(
    unit_data,
    title,
    unit_label,
    facet_by_region = FALSE) {
  heatmap_data <- make_heatmap_data(
    unit_data,
    facet_by_region = facet_by_region
  )

  total_n <- nrow(unit_data)
  # Increase national cell labels by 1.5; retain regional label sizing.
  label_size <- if (facet_by_region) 3.6 else 3.1 * 1.5

  subtitle_text <- paste0(
    scales::comma(total_n),
    " ",
    unit_label,
    ". Cells show the percentage composition of each Enhanced Index decile\n",
    "by Conventional Index decile."
  )

  subtitle_label <- if (facet_by_region) {
    str_wrap(str_replace_all(subtitle_text, "\n", " "), width = 125)
  } else {
    subtitle_text
  }

  caption_text <- paste(
    paste(
      "Cell labels are percentages calculated within each Enhanced Index",
      "decile and rounded to one decimal place;"
    ),
    "rows sum to 100% subject to rounding.",
    paste(
      "Colour shows Conventional Index decile minus Enhanced Index decile:",
      "positive values indicate increased retrofit need, negative values",
      "indicate decreased retrofit need, and zero indicates no change."
    ),
    "Blank cells represent zero transitions.",
    "Outlined cells represent a change in decile."
  )

  if (facet_by_region) {
    caption_text <- paste(
      caption_text,
      "Percentages are calculated independently within each region."
    )
  }

  heatmap_plot <- ggplot(
    heatmap_data,
    aes(
      x = conventional_decile_plot,
      y = enhanced_decile_plot,
      fill = decile_change_fill
    )
  ) +
    geom_tile(
      colour = "#FFFFFF",
      linewidth = 0.35
    ) +
    geom_tile(
      data = \(data) filter(
        data,
        number > 0,
        conventional_decile != enhanced_decile
      ),
      fill = NA,
      colour = "#303030",
      linewidth = 0.65
    ) +
    geom_text(
      aes(
        label = percentage_label,
        colour = label_colour
      ),
      family = "sans",
      fontface = "plain",
      size = label_size
    ) +
    scale_colour_identity() +
    scale_fill_gradientn(
      colours = heatmap_colours,
      limits = c(-9, 9),
      values = scales::rescale(c(-9, 0, 9)),
      breaks = seq(-9, 9, by = 3),
      labels = scales::label_number(accuracy = 1),
      oob = scales::squish,
      na.value = "#F7F7F7",
      name = paste(
        "Decile change (Conventional − Enhanced)",
        "Positive = increased retrofit need",
        sep = "\n"
      )
    ) +
    guides(
      fill = guide_colourbar(
        title.position = "top",
        title.hjust = 0,
        barwidth = grid::unit(10, "cm"),
        barheight = grid::unit(0.46, "cm"),
        ticks.colour = "#353535",
        frame.colour = "#7A7A7A"
      )
    ) +
    coord_fixed(clip = "off") +
    labs(
      title = title,
      subtitle = subtitle_label,
      x = "Conventional Index decile",
      y = "Enhanced Index decile",
      caption = str_wrap(
        caption_text,
        width = if (facet_by_region) 190 else 115
      )
    ) +
    theme_manuscript(base_size = 11) +
    theme(
      panel.grid = element_blank(),
      axis.title = element_text(face = "bold"),
      axis.text = element_text(size = 9),
      axis.ticks = element_blank(),
      legend.margin = margin(t = 4)
    )

  if (facet_by_region) {
    heatmap_plot <- heatmap_plot +
      facet_wrap(
        vars(region),
        ncol = 3,
        scales = "fixed",
        axes = "all",
        axis.labels = "all"
      ) +
      theme(
        strip.background = element_rect(
          fill = "#EEF1F3",
          colour = "#B7BEC3",
          linewidth = 0.4
        ),
        strip.text = element_text(
          face = "bold",
          size = 11.5,
          colour = "#202020",
          margin = margin(5, 5, 5, 5)
        ),
        panel.border = element_rect(
          fill = NA,
          colour = "#CDD1D4",
          linewidth = 0.35
        ),
        panel.spacing.x = grid::unit(2.2, "lines"),
        panel.spacing.y = grid::unit(1.5, "lines"),
        axis.title = element_text(size = 16.5),
        axis.text = element_text(size = 12.75),
        plot.subtitle = element_text(size = 12.5),
        plot.caption = element_text(size = 10.5)
      )
  }

  heatmap_plot
}

lad_heatmap_plot <- make_heatmap_plot(
  unit_data = lad_units,
  title = "Composition of Enhanced Index LA deciles",
  unit_label = "local authorities"
)

lsoa_heatmap_plot <- make_heatmap_plot(
  unit_data = lsoa_units,
  title = "Composition of Enhanced Index LSOA deciles",
  unit_label = "LSOAs"
)

lad_heatmap_plot_by_region <- make_heatmap_plot(
  unit_data = lad_units,
  title = "Regional composition of Enhanced Index LA deciles",
  unit_label = "local authorities",
  facet_by_region = TRUE
)

lsoa_heatmap_plot_by_region <- make_heatmap_plot(
  unit_data = lsoa_units,
  title = "Regional composition of Enhanced Index LSOA deciles",
  unit_label = "LSOAs",
  facet_by_region = TRUE
)

# ------------------------------------------------------------------------------
# 10. Combined national heat maps (one row, two columns)
# ------------------------------------------------------------------------------

national_shared_caption <- ggplot2::get_labs(lsoa_heatmap_plot)$caption |>
  str_squish() |>
  str_wrap(width = 190)

national_heatmap_comparison_plot <- (
  patchwork::wrap_plots(
    lsoa_heatmap_plot +
      labs(caption = NULL) +
      theme(plot.margin = margin(12, 4, 12, 4)),
    lad_heatmap_plot +
      labs(caption = NULL) +
      theme(plot.margin = margin(12, 4, 12, 4)),
    nrow = 1,
    ncol = 2,
    guides = "collect"
  ) +
    patchwork::plot_annotation(
      caption = national_shared_caption,
      theme = theme(
        plot.caption.position = "plot",
        plot.caption = element_text(
          colour = "#5F5F5F",
          size = 8.6,
          hjust = 0,
          margin = margin(t = 10)
        )
      )
    )
) &
  theme(legend.position = "bottom")

# ------------------------------------------------------------------------------
# 11. Combined national Sankey plots (one row, two columns)
# ------------------------------------------------------------------------------

national_sankey_shared_caption <- ggplot2::get_labs(lsoa_sankey_plot)$caption |>
  str_squish() |>
  str_wrap(width = 230)

national_sankey_comparison_plot <- (
  patchwork::wrap_plots(
    lsoa_sankey_plot + labs(caption = NULL),
    lad_sankey_plot + labs(caption = NULL),
    nrow = 1,
    ncol = 2,
    guides = "collect"
  ) +
    patchwork::plot_annotation(
      caption = national_sankey_shared_caption,
      theme = theme(
        plot.caption.position = "plot",
        plot.caption = element_text(
          colour = "#5F5F5F",
          size = 8.6,
          hjust = 0,
          margin = margin(t = 10)
        )
      )
    )
) &
  theme(legend.position = "bottom")

# ------------------------------------------------------------------------------
# Export figures
# ------------------------------------------------------------------------------

export_combined_heatmap <- function() {
  save_publication_plot(
    national_heatmap_comparison_plot,
    stem = "enhanced_decile_composition_heatmaps_national_combined_v2",
    width = 14,
    height = 9.5
  )
}

export_combined_sankey <- function() {
  save_publication_plot(
    national_sankey_comparison_plot,
    stem = "retrofit_decile_transitions_national_combined_v2",
    width = 23,
    height = 12.3
  )
}

export_combined_figures <- function() {
  c(
    export_combined_heatmap(),
    export_combined_sankey()
  )
}

export_national_heatmaps <- function() {
  c(
    save_publication_plot(
      lad_heatmap_plot,
      stem = "enhanced_decile_composition_heatmap_local_authorities_v2",
      width = 10,
      height = 9
    ),
    save_publication_plot(
      lsoa_heatmap_plot,
      stem = "enhanced_decile_composition_heatmap_lsoas_v2",
      width = 10,
      height = 9
    ),
    export_combined_heatmap()
  )
}

if (breakdown_table_only) {
  plot_files <- character()
} else if (combined_figures_only) {
  plot_files <- export_combined_figures()
} else if (national_heatmaps_only) {
  plot_files <- export_national_heatmaps()
} else {
  plot_files <- c(
    save_publication_plot(
      correlation_plot,
      stem = "retrofit_index_correlations_v2",
      width = 12.5,
      height = 8.4
    ),
    save_publication_plot(
      lad_sankey_plot,
      stem = "retrofit_decile_transitions_local_authorities_v2",
      width = 12,
      height = 12.3
    ),
    save_publication_plot(
      lsoa_sankey_plot,
      stem = "retrofit_decile_transitions_lsoas_v2",
      width = 12,
      height = 12.3
    ),
    save_publication_plot(
      lad_sankey_plot_by_region,
      stem = "retrofit_decile_transitions_local_authorities_by_region_v2",
      width = 18,
      height = 21
    ),
    save_publication_plot(
      lsoa_sankey_plot_by_region,
      stem = "retrofit_decile_transitions_lsoas_by_region_v2",
      width = 18,
      height = 21
    ),
    export_national_heatmaps(),
    save_publication_plot(
      lad_heatmap_plot_by_region,
      stem = "enhanced_decile_composition_heatmap_local_authorities_by_region_v2",
      width = 18,
      height = 19
    ),
    save_publication_plot(
      lsoa_heatmap_plot_by_region,
      stem = "enhanced_decile_composition_heatmap_lsoas_by_region_v2",
      width = 18,
      height = 19
    ),
    export_combined_sankey()
  )
}

standard_run <- !any(c(
  breakdown_table_only,
  combined_figures_only,
  national_heatmaps_only
))

table_files <- if (breakdown_table_only || standard_run) {
  export_breakdown_table()
} else {
  character()
}

output_files <- c(plot_files, table_files)
figure_count <- length(plot_files) / 2
output_summary <- c(
  if (figure_count > 0) {
    paste0(figure_count, " figure designs as PNG and PDF")
  },
  if (length(table_files) > 0) {
    paste0(length(table_files), " CSV table")
  }
)

message(
  "Created ",
  length(output_files),
  " publication files (",
  paste(output_summary, collapse = "; "),
  ") in:\n  ",
  normalizePath(outputs_dir, winslash = "/"),
  "\n\n",
  paste0("  - ", basename(output_files), collapse = "\n")
)
