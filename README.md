# Exploratory Analysis of 2026 River Discharge at Selected Bihar Sites

This project analyzes river discharge observations from the Water Resources Department (WRD), Government of Bihar. It uses descriptive analytics to examine daily discharge patterns and identify dates when discharge was relatively high across monitored sites. It is an exploratory monitoring study, not a validated flood prediction system.

## Research question

How did discharge vary at selected WRD dashboard sites from 13 July to 23 September 2026, and on which dates were readings relatively high at multiple monitored sites?

## Data source and scope

The intraday observations were collected from the [Bihar WRD River Discharge Dashboard](https://wrd.bihar.gov.in/rivers/2026/displayDischarge.php), which displays discharge in cusecs for six sites:

- Kosi (Barahkshetra site) — upstream site in Nepal
- Kosi (Birpur Barrage D/S) — Supaul, Bihar
- Gandak (Valmikinagar Barrage D/S) — Pashchim Champaran, Bihar
- Sone (Indrapuri Barrage D/S) — Rohtas, Bihar
- Falgu (Uderasthan Barrage D/S) — Jehanabad, Bihar
- North Koel (Mohammadganj Barrage D/S) — Palamu, Jharkhand

The dataset contains 2,131 intraday records from 13 July through 23 September 2026. This is a selected-site dataset, not a statewide sample. The two Kosi stations are distinct monitoring locations. Site-to-district labels in the derived feature identify monitoring locations; they do not identify all districts that may be affected downstream.

## Analysis workflow

The R script:

1. Reads and checks the intraday observations, including date coverage and missing discharge values.
2. Aggregates readings to one row per observed site and date, calculating daily mean and daily peak discharge.
3. Converts discharge from cusecs to cubic metres per second (m³/s) for an additional unit representation.
4. Produces site-level time-series plots and a heatmap of dates above each site's period-specific 90th-percentile threshold.
5. Creates a four-site Bihar district-date feature file, excluding Barahkshetra (Nepal) and Mohammadganj (Jharkhand).

## Current results

- There are 73 observation dates and 2,131 intraday readings across the six dashboard sites; the source records have no missing discharge values.
- Daily aggregation produces 433 observed site-date records. Five site-dates are absent because the Falgu dashboard site has observations on 68 dates while the other five sites have 73 dates each.
- The four-site Bihar feature contains 287 observed district-date records: three sites have 73 dates each and Falgu has 68.
- Each site's 90th-percentile threshold was calculated separately from this short observation period. All six monitored sites were above their own threshold on 2 and 3 September 2026.
- Sone (Indrapuri Barrage D/S) had the largest observed daily peak in the period: 563,654 cusecs on 2 September 2026.

These are descriptive findings for the sites and dates in this dataset. A period-specific percentile is not an official warning or danger level.

## Files

| File | Description |
|---|---|
| `analyze_bihar_2026_discharge.R` | Main R script; reads the raw data and regenerates the analysis outputs. |
| `bihar_wrd_2026_discharge_jul13_sep23.csv` | Intraday source observations compiled from the WRD dashboard. |
| `bihar_wrd_2026_daily_site_summary.csv` | Daily mean and peak discharge summaries for all six sites. |
| `river_discharge.csv` | Daily discharge feature for the four selected sites located in Bihar. |
| `bihar_2026_site_results.csv` | Site-level p90 thresholds, high-flow-day counts, and observed peaks. |
| `bihar_2026_high_flow_heatmap.png` | Heatmap of site-specific p90 exceedance dates. |
| `bihar_2026_normalized_discharge.png` | Daily peaks shown as a percentage of each site's observed-period maximum. |

## Run the analysis

Open RStudio and run this command in the **Console**:

```r
source("C:/Users/ACER/Documents/Codex/2026-09-23/the/outputs/analyze_bihar_2026_discharge.R")
```

The script expects `bihar_wrd_2026_discharge_jul13_sep23.csv` in the same `outputs` directory. It uses `tidyverse` and `lubridate` and writes the derived CSV files and plots back to that directory.

## Limitations and future work

- The observation period is about ten weeks and covers only six selected sites; results should not be generalized to all of Bihar.
- Four sites are located in Bihar, one is in Nepal, and one is in Jharkhand. River-flow observations at an upstream or barrage site may be relevant to downstream conditions, but this dataset does not directly measure inundation, district-level losses, casualties, or population exposure.
- The p90 thresholds are calculated from the same short observation period. They flag relatively high readings within this dataset, not flood-danger conditions.
- No population dataset, rainfall series matched to these sites, verified station-matched danger-level series, or flood-impact labels are included yet.
- No machine-learning model has been trained or validated. A future AI layer would require a longer record and suitable labels or a clearly defined anomaly-detection objective, plus validation against official warnings and observed impacts.

## Citation

Water Resources Department, Government of Bihar. *River Discharge Dashboard – Major Rivers of Bihar*. Observations for 13 July–23 September 2026, accessed 23 September 2026. https://wrd.bihar.gov.in/rivers/2026/displayDischarge.php
