#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2025}"

# NOAA file naming pattern. The "c{CREATED_DATE}" portion changes when NOAA
# republishes a year. Look at https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/
# This code will select the most recent date for the given year.

BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/"

# Discover available years from NOAA directory listing
YEARS=$(curl -s "${BASE_URL}" \
  | grep 'StormEvents_details-ftp_v1.0_d' \
  | sed -E 's/.*StormEvents_details-ftp_v1.0_d([0-9]{4}).*/\1/' \
  | sort -u)

MIN_YEAR=$(echo "${YEARS}" | head -n1)
MAX_YEAR=$(echo "${YEARS}" | tail -n1)

echo "Valid years are between ${MIN_YEAR} and ${MAX_YEAR} (based on NOAA's files)."

if [ "${YEAR}" -lt "${MIN_YEAR}" ] || [ "${YEAR}" -gt "${MAX_YEAR}" ]; then
  echo "Valid years are between ${MIN_YEAR} and ${MAX_YEAR} (based on NOAA's files)."
  exit 1
fi

get_latest_file_for_year() {
  local year="$1"

  curl -s "${BASE_URL}" \
    | grep "StormEvents_details-ftp_v1.0_d${year}_c" \
    | sed -E 's/.*href="([^"]+)".*/\1/' \
    | grep '\.csv\.gz$' \
    | sort \
    | tail -n 1
}

FILE_NAME="$(get_latest_file_for_year "${YEAR}")"

if [ -z "${FILE_NAME}" ]; then
  echo "ERROR: Could not find StormEvents details file for year ${YEAR} at ${BASE_URL}" >&2
  exit 1
fi

# Extract file creation date (YYYYMMDD) from the NOAA filename
CREATED_DATE=$(
  echo "${FILE_NAME}" \
    | sed -E 's/.*_c([0-9]{8})\.csv\.gz/\1/'
)

echo "Using created date ${CREATED_DATE} from ${FILE_NAME}"

URL="${BASE_URL}/${FILE_NAME}"

RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
RAW_GZ="${RAW_DIR}/${FILE_NAME}"
RAW_CSV="${RAW_DIR}/${FILE_NAME%.gz}"
#OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}_c${CREATED_DATE}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------

echo "[1/4] Setting up directories"
# [TODO] Use mkdir -p to create RAW_DIR and PROCESSED_DIR. Both should be
# safe to call even if the directories already exist.
mkdir -p data/raw data/processed

# -----------------------------------------------------------------------------
# Step 2: Download the raw file
# -----------------------------------------------------------------------------

echo "[2/4] Downloading ${FILE_NAME}"
# [TODO] Use curl to download URL into RAW_GZ. Suggested flags:
#   -L       follow redirects
#   -o       write to a specific output file path
#   --fail   exit non-zero on HTTP errors (4xx/5xx)
#
# Skip the download if the file already exists (idempotency).

if [ -f "${RAW_GZ}" ]; then
  echo "    File already exists at ${RAW_GZ}, skipping download."
else
  curl -L --fail -o "${RAW_GZ}" "${URL}"
fi

# -----------------------------------------------------------------------------
# Step 3: Decompress
# -----------------------------------------------------------------------------

# [TODO] Use gunzip to decompress RAW_GZ into RAW_CSV.
# The -k flag keeps the original .gz so the pipeline can rerun.
# Skip this step if RAW_CSV already exists.

echo "[3/4] Unzipping ${FILE_NAME}"

if [ -f "${RAW_CSV}" ]; then
  echo "    Uncompressed file already exists at ${RAW_CSV}, skipping gunzip."
else
  gunzip -k "${RAW_GZ}"
fi

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"
# [TODO] Use ogr2ogr to convert RAW_CSV into a GeoParquet file at OUT_PARQUET.
#
# The CSV uses BEGIN_LON / BEGIN_LAT for the storm start point. ogr2ogr can
# pick those up if you tell it the column names with -oo:
#
#   -oo X_POSSIBLE_NAMES=BEGIN_LON
#   -oo Y_POSSIBLE_NAMES=BEGIN_LAT
#
# The data is in WGS 84 (EPSG:4326). Set that explicitly with -a_srs.
#
# Use -f Parquet for the output format.
#

echo "[4/4] Converting CSV to GeoParquet"

if [ -f "${OUT_PARQUET}" ]; then
  echo "    GeoParquet already exists at ${OUT_PARQUET}, skipping ogr2ogr."
else
  ogr2ogr \
    -f "Parquet" "${OUT_PARQUET}" "${RAW_CSV}" \
    -oo X_POSSIBLE_NAMES=BEGIN_LON \
    -oo Y_POSSIBLE_NAMES=BEGIN_LAT \
    -a_srs "EPSG:4326"
fi

echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
