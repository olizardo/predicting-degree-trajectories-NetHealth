#!/usr/bin/env Rscript
library(googledrive)
drive_auth(email = "omarlizardo@gmail.com")
doc_id <- "147PaI7iC0LPB12CI_sT6XY_gCg76JKFkPP18maTc9TQ"
live_docx <- "draft_live.docx"
updated_docx <- "draft_updated.docx"
drive_download(as_id(doc_id), path = live_docx, overwrite = TRUE)

exit_code <- system2("python3", args = c("Scripts/update_text.py", live_docx, updated_docx))
if (exit_code == 0) {
  drive_update(as_id(doc_id), media = updated_docx)
  message("Google Doc updated successfully.")
} else {
  message("Error in python script")
}
unlink(live_docx)
unlink(updated_docx)
