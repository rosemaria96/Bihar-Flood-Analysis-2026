# Descriptive analysis of 2026 Bihar WRD river discharge observations
# Source: Bihar Water Resources Department, River Discharge Dashboard
# Observation dates available: 2026-07-13 through 2026-09-23
# Scope: six dashboard sites; river_discharge.csv keeps the four sites located in Bihar.

library(tidyverse)
library(lubridate)

data_dir <- "C:/Users/ACER/Documents/Codex/2026-09-23/the/outputs"

observations <- read_csv(
  file.path(data_dir, "bihar_wrd_2026_discharge_jul13_sep23.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    date = as.Date(date),
    discharge_cusecs = as.numeric(discharge_cusecs)
  )

# Check collection coverage and possible missing values.
observations %>%
  summarise(
    rows = n(),
    stations = n_distinct(station),
    dates = n_distinct(date),
    first_date = min(date, na.rm = TRUE),
    last_date = max(date, na.rm = TRUE),
    missing_discharge = sum(is.na(discharge_cusecs))
  ) %>%
  print()

# Collapse the dashboard's intraday observations to one daily summary per site.
# Daily peak is useful for examining peak flow; daily mean is also retained.
daily_site <- observations %>%
  filter(!is.na(discharge_cusecs)) %>%
  group_by(date, station) %>%
  summarise(
    readings = n(),
    daily_mean_cusecs = mean(discharge_cusecs),
    daily_peak_cusecs = max(discharge_cusecs),
    .groups = "drop"
  )

# Highest observed date in this downloaded period for each dashboard site.
site_peaks <- daily_site %>%
  group_by(station) %>%
  slice_max(daily_peak_cusecs, n = 1, with_ties = TRUE) %>%
  ungroup() %>%
  arrange(desc(daily_peak_cusecs))

print(site_peaks, n = Inf)

# Plot daily peak discharge. Free y-scales are used because site flows differ.
ggplot(daily_site, aes(x = date, y = daily_peak_cusecs)) +
  geom_line(colour = "steelblue", linewidth = 0.6) +
  geom_point(colour = "steelblue", alpha = 0.55, size = 0.9) +
  facet_wrap(~ station, scales = "free_y") +
  labs(
    title = "Observed 2026 discharge at selected Bihar river sites",
    subtitle = "Daily peak of dashboard readings, 13 July–23 September 2026",
    x = "Date",
    y = "Daily peak discharge (cusecs)"
  ) +
  theme_minimal()

# Optional: convert cusecs to cubic metres per second (m³/s).
daily_site <- daily_site %>%
  mutate(
    daily_mean_m3s = daily_mean_cusecs * 0.0283168466,
    daily_peak_m3s = daily_peak_cusecs * 0.0283168466
  )

# Export the daily summaries for tables or further analysis.
write_csv(daily_site, file.path(data_dir, "bihar_wrd_2026_daily_site_summary.csv"))

# Create a district-date discharge feature for the four dashboard sites located
# in Bihar. The Barahkshetra site is in Nepal and Mohammadganj is in Jharkhand,
# so they are not included in this Bihar-district feature.
bihar_site_lookup <- tribble(
  ~station,                                      ~district,             ~river,
  "Sone (Indrapuri Barrage D/S)",               "Rohtas",              "Sone",
  "Gandak (Valmikinagar Barrage D/S)",           "Pashchim Champaran",  "Gandak",
  "Kosi (Birpur Barrage D/S)",                  "Supaul",              "Kosi",
  "Falgu (Uderasthan Barrage D/S)",             "Jehanabad",           "Falgu"
)

river_discharge <- daily_site %>%
  inner_join(bihar_site_lookup, by = "station") %>%
  transmute(
    date,
    district,
    river,
    station,
    readings,
    river_discharge_cusecs = daily_peak_cusecs,
    daily_mean_cusecs,
    river_discharge_m3s = daily_peak_m3s,
    source = "Bihar WRD River Discharge Dashboard"
  ) %>%
  arrange(date, district)

write_csv(river_discharge, file.path(data_dir, "river_discharge.csv"))

river_discharge %>%
  summarise(
    rows = n(),
    districts = n_distinct(district),
    first_date = min(date),
    last_date = max(date),
    missing_discharge = sum(is.na(river_discharge_cusecs))
  ) %>%
  print()

# Compare each site's daily peak with its own observed-period maximum.
daily_normalized <- daily_site %>%
  group_by(station) %>%
  mutate(
    percent_of_site_peak =
      100 * daily_peak_cusecs / max(daily_peak_cusecs, na.rm = TRUE)
  ) %>%
  arrange(date, .by_group = TRUE) %>%
  mutate(
    segment = cumsum(is.na(lag(date)) | (date - lag(date)) > 1)
  ) %>%
  ungroup()

normalized_plot <- ggplot(
  daily_normalized,
  aes(x = date, y = percent_of_site_peak,
      group = interaction(station, segment))
) +
  geom_line(colour = "steelblue") +
  geom_point(colour = "steelblue", size = 0.8) +
  facet_wrap(~ station) +
  labs(
    title = "Timing of discharge peaks at selected monitoring sites",
    subtitle = "Each site's daily peak as a percentage of its observed-period peak",
    x = "Date",
    y = "Percent of site's observed-period peak"
  ) +
  theme_minimal()

print(normalized_plot)
ggsave(
  file.path(data_dir, "bihar_2026_normalized_discharge.png"),
  plot = normalized_plot,
  width = 11,
  height = 7,
  dpi = 300
)

# Exploratory high-flow flags: each station's own 90th percentile.
site_p90 <- daily_site %>%
  group_by(station) %>%
  summarise(
    p90_cusecs = quantile(daily_peak_cusecs, 0.90, na.rm = TRUE),
    .groups = "drop"
  )

high_flow_by_site <- daily_site %>%
  left_join(site_p90, by = "station") %>%
  mutate(above_p90 = daily_peak_cusecs > p90_cusecs)

high_flow_summary <- high_flow_by_site %>%
  group_by(station) %>%
  summarise(
    observed_days = n(),
    high_flow_days = sum(above_p90),
    highest_peak_cusecs = max(daily_peak_cusecs, na.rm = TRUE),
    highest_peak_date = date[which.max(daily_peak_cusecs)],
    .groups = "drop"
  ) %>%
  arrange(desc(high_flow_days))

print(high_flow_summary, n = Inf)

# Count how many sites exceeded their own p90 on each date.
bihar_daily_indicator <- high_flow_by_site %>%
  group_by(date) %>%
  summarise(
    sites_reporting = n_distinct(station),
    sites_above_p90 = sum(above_p90),
    .groups = "drop"
  ) %>%
  arrange(desc(sites_above_p90), date)

print(bihar_daily_indicator, n = 20)

# Heatmap of relative high-flow dates across the six dashboard sites.
p <- ggplot(high_flow_by_site, aes(x = date, y = station, fill = above_p90)) +
  geom_tile() +
  scale_fill_manual(
    values = c("FALSE" = "grey90", "TRUE" = "firebrick"),
    labels = c("FALSE" = "At or below p90", "TRUE" = "Above p90")
  ) +
  labs(
    title = "Relatively high discharge at six monitored sites",
    subtitle = "Red marks daily peaks above each site's period p90",
    x = "Date",
    y = "Dashboard site",
    fill = "Daily peak"
  ) +
  theme_minimal() +
  theme(
    plot.title.position = "plot",
    axis.text.y = element_text(size = 9)
  )

print(p)
ggsave(
  file.path(data_dir, "bihar_2026_high_flow_heatmap.png"),
  plot = p,
  width = 11,
  height = 6,
  dpi = 300
)

# Final six-site results table.
final_site_results <- high_flow_by_site %>%
  group_by(station) %>%
  summarise(
    observed_days = n(),
    p90_cusecs = first(p90_cusecs),
    days_above_p90 = sum(above_p90),
    highest_peak_cusecs = max(daily_peak_cusecs, na.rm = TRUE),
    highest_peak_date = date[which.max(daily_peak_cusecs)],
    .groups = "drop"
  ) %>%
  arrange(desc(highest_peak_cusecs))

print(final_site_results, n = Inf)
write_csv(
  final_site_results,
  file.path(data_dir, "bihar_2026_site_results.csv")
)
