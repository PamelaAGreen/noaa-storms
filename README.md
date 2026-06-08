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

 * Designed an idempotent, reproducible shell pipeline for NOAA Storm Events data, including directory setup, download, decompression, and CSV→GeoParquet conversion that can be safely rerun without deleting existing outputs.

 * Automatically discovers the most recent StormEvents file for the specified year by parsing NOAA’s directory index, so the pipeline keeps working even if exact filenames or created dates change.

 * Implemented a guard that discovers the available years from NOAA’s directory listing and validates user input against that range, so the script fails fast with a clear message when the year is invalid.

 * Learned to use Git effectively inside VS Code, including options for staging files, understanding commit alternatives, and configuring .gitignore to keep large raw data (data/, .DS_Store) out of version control.

 * Set up a dedicated geospatial environment using mamba (including GDAL and the GeoParquet plugin) to run the shell script.

 * Practiced safe scripting habits (set -euo pipefail, existence checks for files and outputs, clear logging of each pipeline step), making the workflow clearer, safer, and easier for others to review and modify.

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet
