#!/usr/bin/env Rscript
# Scripts/sync_manuscript.R
# Master driver script for strict in-place OpenXML table and figure synchronization.
# Adheres strictly to AGENTS.md Section 8 and Section 10:
# - ZERO Pandoc re-compilation over live Google Docs.
# - The remote document on Google Drive is the canonical source of truth for text, fonts, margins, and styles.
# - Only surgical in-place DOM replacement of <w:tbl> and <w:drawing> nodes is performed.

.libPaths(c("/home/omarlizardo/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))

suppressPackageStartupMessages({
  library(googledrive)
})

main <- function() {
  doc_id <- "147PaI7iC0LPB12CI_sT6XY_gCg76JKFkPP18maTc9TQ"
  live_docx <- "draft_live.docx"
  updated_docx <- "draft_updated.docx"

  on.exit({
    unlink(Sys.glob("draft_*.docx"))
    unlink(Sys.glob("draft_*.txt"))
    unlink(Sys.glob("*.tmp"))
    unlink("replacements.json")
  }, add = TRUE)

  message("[1/4] Ensuring table summaries in cache/ are up to date...")
  if (file.exists("Scripts/generate_md_tables.R")) {
    source("Scripts/generate_md_tables.R")
  }

  message("[2/4] Downloading live formatted manuscript from Google Drive...")
  drive_auth(email = "omarlizardo@gmail.com")
  drive_download(as_id(doc_id), path = live_docx, overwrite = TRUE)

  # Synchronize local markdown mirror from live Google Doc
  system2("pandoc", args = c("-f", "docx", "-t", "gfm", "--wrap=none", live_docx, "-o", "draft_manuscript.md"))

  message("[3/4] Performing surgical in-place OpenXML DOM injection (preserving all remote styles)...")
  exit_code <- system2("python3", args = c("Scripts/sync_manuscript.py", live_docx, updated_docx))
  if (exit_code != 0) {
    stop("Error during in-place OpenXML injection.")
  }

  message("[4/4] Uploading updated manuscript back to Google Drive...")
  drive_update(as_id(doc_id), media = updated_docx)

  message("====================================================================")
  message("Synchronization complete! Remote styles, typography, and text preserved.")
  message(paste0("Document URL: https://docs.google.com/document/d/", doc_id))
  message("====================================================================")
}

main()
