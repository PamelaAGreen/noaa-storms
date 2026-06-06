# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data, converts it to GeoParquet, and lands it ready for analysis in DuckDB, GeoPandas, or QGIS.

## What it does

`pipeline.sh` takes a year (default: 2025), pulls the most recent raw `details` file from NOAA's public archive, decompresses it, and converts it to a single GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet connection.

## The data

- **Source:** [NOAA Storm Events Database](https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/)
- **License:** Public domain (US federal data)
- **What's in it:** every recorded storm event in the United States for the given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

```bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
```

To run for a specific year:

```bash
./pipeline.sh 2023
```

## What I learned

 * Designed an idempotent, reproducible shell pipeline for NOAA Storm Events data, including robust directory setup, download, decompression, and CSV→GeoParquet conversion that can be safely rerun without clobbering existing outputs.

 * Implemented defensive data access for evolving filenames, automatically discovering the correct StormEvents file for a given year by parsing NOAA’s directory index, instead of hard‑coding created dates.

 * Learned to use Git effectively inside VS Code, including staging individual files vs. “stage all,” understanding commits vs. published branches, and configuring .gitignore to keep large raw data (data/, .DS_Store) out of version control.

 * Set up and managed a project‑specific geospatial toolchain with mamba (GDAL + GeoParquet plugin), and wired it cleanly into the shell pipeline via environment activation rather than ad‑hoc system installs.

 * Practiced defensive scripting patterns (set -euo pipefail, existence checks for files and outputs, clear logging of each pipeline step), making the workflow clearer, safer, and easier for others to audit or extend.

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet
