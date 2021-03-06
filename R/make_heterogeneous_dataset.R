#' Build a heterogeneou dataset of predefined size
#'
#' This function extracts observations related to heterogeneous organisms from
#' IEDB data and returns a data set that can be used to train machine learning
#' models.
#'
#' The heterogeneous data set is assembled by sampling entries from
#' `epitopes` by organism taxID (after filtering using `removeIDs` and
#' `hostIDs`) until the desired number of positive and negative observations is
#' reached. Random subsampling is performed if required to return the exact
#' number of unique epitope examples.
#'
#' @inheritParams make_OrgSpec_datasets
#' @param taxonomy_list list containing taxonomy information
#'        (generated by [get_taxonomy()])
#' @param nPos number of positive examples to extract. **NOTE**: this refers to
#' the number of unique positive examples extracted from `epitopes`, not to the
#' size of the data frame returned (which is obtained after windowing using
#' [make_window_df()]).
#' @param nNeg number of negative examples to extract
#' @param rnd.seed seed for random number generator
#'
#' @return Data frame containing the resulting dataset.
#'
#' @author Felipe Campelo (\email{f.campelo@@aston.ac.uk})
#'
#' @export
#'
make_heterogeneous_dataset <- function(epitopes, proteins, taxonomy_list,
                                       nPos, nNeg,
                                       removeIDs       = NULL,
                                       hostIDs         = NULL,
                                       min_epit        = 8,
                                       max_epit        = 25,
                                       only_exact      = FALSE,
                                       pos.mismatch.rm = "all",
                                       set.positive    = "mode",
                                       window_size     = 2 * min_epit - 1,
                                       max.N           = 2,
                                       save_folder     = "./",
                                       rnd.seed        = NULL,
                                       ncpus           = 1){

  # ========================================================================== #
  # Sanity checks and initial definitions
  id_classes <- c("NULL", "numeric", "integer", "character")
  assertthat::assert_that(class(hostIDs)   %in% id_classes,
                          class(removeIDs) %in% id_classes,
                          assertthat::is.count(nPos),
                          assertthat::is.count(nNeg),
                          assertthat::is.count(min_epit),
                          assertthat::is.count(max_epit),
                          min_epit <= max_epit,
                          pos.mismatch.rm %in% c("all", "align"),
                          set.positive    %in% c("any", "mode", "all"),
                          is.logical(only_exact) & length(only_exact) == 1,
                          assertthat::is.count(ncpus),
                          is.character(save_folder),
                          length(save_folder) == 1)

  if(!is.null(rnd.seed)) {
    assertthat::assert_that(assertthat::is.count(rnd.seed))
    set.seed(rnd.seed)
  }

  if(!dir.exists(save_folder)) dir.create(save_folder, recursive = TRUE)
  # ========================================================================== #

  # Join and filter epitope/protein data
  jdf <- prepare_join_df(epitopes = epitopes, proteins = proteins,
                         min_epit = min_epit, max_epit = max_epit,
                         only_exact = only_exact,
                         pos.mismatch.rm = pos.mismatch.rm,
                         set.positive = set.positive)

  jdf <- filter_epitopes(jdf,
                         removeIDs = removeIDs,
                         hostIDs   = hostIDs,
                         tax_list  = taxonomy_list)

  # Randomise organism IDs
  set.seed(rnd.seed)
  orgIds <- sample(unique(jdf$sourceOrg_id))

  # Compose heterogeneous dataset
  for (i in seq_along(orgIds)){
    newSet <- jdf[jdf$sourceOrg_id %in% orgIds[1:i], ]
    newSet <- newSet[!which(duplicated(newSet$epitope_id)), ]
    cl     <- as.numeric(table(factor(newSet$Class,
                                      levels = c(-1, 1))))
    if (cl[1] >= nNeg & cl[2] >= nPos) break
  }

  idx <- numeric()
  if (cl[1] > nNeg){
    idx  <- c(idx, sample(which(newSet$Class == -1), size = nNeg,
                          replace = FALSE))
  }

  if (cl[2] > nPos){
    idx  <- c(idx, sample(which(newSet$Class == 1), size = nPos,
                          replace = FALSE))
  }

  newSet <- newSet[idx, ]

  # Prepare windowed representation
  wdf <- make_window_df(df = newSet,
                        window_size = window_size,
                        ncpus = 1)

  # Calculate features
  wdf <- calc_features(wdf, max.N = max.N, ncpus = ncpus)

  saveRDS(wdf, paste0(save_folder, "/df_heterogeneous.rds"))

  return(wdf)
}

