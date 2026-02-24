suppressPackageStartupMessages({
  library(eurostat)
  library(readr)
})

# --------------------------------------------------
# Download full datasets (no filtering)
# --------------------------------------------------

OUTDIR <- "EUROSTAT_RAW_DOWNLOADS"
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)

download_save_full <- function(id) {
  
  cat("Downloading:", id, "\n")
  
  df <- eurostat::get_eurostat(
    id = id,
    time_format = "num",
    cache = TRUE
  )
  
  # Save full dataset
  saveRDS(df, file.path(OUTDIR, paste0(id, ".rds")))
  readr::write_csv(df, file.path(OUTDIR, paste0(id, ".csv")), na = "")
  
  cat("Rows:", nrow(df), "\n\n")
  
  invisible(df)
}

# 1) Final consumption expenditure by COICOP (CP1700)
cp1700 <- download_save_full("naio_10_cp1700")

# 2) National accounts by A*64 industries (employment)
a64e <- download_save_full("nama_10_a64_e")

cat("Files saved in:", normalizePath(OUTDIR), "\n")