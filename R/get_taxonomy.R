#' Retrieve taxonomic classification tables from NCBI.
#'
#' This function retrieves the taxonomic information of a vector of organism
#' IDs, from the NCBI Taxonomy data base.
#'
#' @param uids vector of organism IDs to retrieve taxonomical information, or a
#'        *data.table* object of class *LBCE_dt*, generated by [get_LBCE()].
#' @param save_folder path to folder for saving the results.
#'
#' @return A list containing the information for each element of uids
#'
#' @author Felipe Campelo (\email{f.campelo@@aston.ac.uk})
#'
#' @export
#'
#'
#' @examples
#' uids <- c("6282", # O. volvulus,
#'           "9606") # H. sapiens
#' tax <- get_taxonomy(uids)
#'

get_taxonomy <- function(uids, save_folder = NULL){

  # ========================================================================== #
  # Sanity checks and initial definitions
  t0 <- Sys.time()
  ok_classes <- c("NULL", "numeric", "integer", "character")
  assertthat::assert_that(is.null(save_folder) | (is.character(save_folder)),
                          is.null(save_folder) | length(save_folder) == 1)

  if(is.vector(uids)){
    assertthat::assert_that(any(class(uids) %in% ok_classes),
                            length(uids) >= 1)
    uids <- as.character(uids)
  } else {
    assertthat::assert_that("LBCE_dt" %in% class(uids))
    uids <- unique(uids$sourceOrg_id)
  }

  # Check save folder and create file names
  if(!is.null(save_folder)) {
    if(!dir.exists(save_folder)) dir.create(save_folder)
    ymd <- gsub("-", "", Sys.Date())
    df_file <- paste0(normalizePath(save_folder), "/00_taxonomy_", ymd, ".rds")
    errfile <- paste0(normalizePath(save_folder),
                      "/00_taxonomy_not_retrieved_", ymd, ".rds")
    tmpf    <- tempfile(fileext = ".rds", tmpdir = save_folder)
  }

  errlist <- seq_along(uids)
  reslist <- vector("list", length = length(uids))
  nerr    <- Inf

  while(length(errlist) < nerr && length(errlist) > 0){
    nerr <- length(errlist)
    cat("\nTrying to retrieve", length(errlist), "entries from NCBI (db = taxonomy)")
    cc <- 0
    for (idx in errlist){
      errk <- FALSE
      suppressMessages(
        tryCatch({
          tt  <- reutils::efetch(as.numeric(uids[idx]),
                                 db      = "taxonomy",
                                 retmode = "xml")
          if(is.null(tt$errors$errmsg)){
            ttp <- XML::xmlTreeParse(tt$content, useInternalNodes = TRUE)
            reslist[[idx]]$Taxonomy <- data.frame(
              ScientificName = XML::xpathSApply(ttp,
                                                "//TaxaSet/Taxon/LineageEx/Taxon/ScientificName",
                                                XML::xmlValue),
              Rank = XML::xpathSApply(ttp, "//TaxaSet/Taxon/LineageEx/Taxon/Rank",
                                      XML::xmlValue),
              UID  = XML::xpathSApply(ttp, "//TaxaSet/Taxon/LineageEx/Taxon/TaxId",
                                      XML::xmlValue),
              stringsAsFactors = FALSE)
          }
        },
        warning = function(c) {errk <<- TRUE},
        error   = function(c) {errk <<- TRUE},
        finally = NULL))

      if(!errk){
        reslist[[idx]]$UID <- uids[idx]
      }

      # Print progress bar
      mypb(i = cc, max_i = length(errlist), t0 = t0, npos = 30)
      cc <- cc + 1

      # save tmp results (if needed)
      if(!is.null(save_folder) && !(cc %% 10)){
        saveRDS(object = list(reslist = reslist, errlist = errlist,
                              idx = idx, uids = uids),
                file = tmpf)
      }

      # NCBI limits requests to three per second
      Sys.sleep(0.3)
    }
    errlist <- which(sapply(reslist, function(x) {is.null(x$UID)}))
  }

  if(length(errlist) > 0) reslist <- reslist[-errlist]
  errlist <- uids[errlist]

  class(reslist) <- c(class(reslist), "taxonomy_list")

  # Save results to file
  if(!is.null(save_folder)){
    saveRDS(object = reslist, file = df_file)
    saveRDS(object = errlist, file = errfile)
    if(file.exists(tmpf)) file.remove(tmpf)
  }

  cat("\nDone!\n", length(reslist), "taxonomies retrieved.\n",
      length(errlist), "retrieval errors.")

  return(reslist)
}
