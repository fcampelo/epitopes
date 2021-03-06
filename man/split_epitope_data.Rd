% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/split_epitope_data.R
\name{split_epitope_data}
\alias{split_epitope_data}
\title{Split epitope data based on epitope, protein or organism IDs.}
\usage{
split_epitope_data(
  wdf,
  split_level = "prot",
  split_perc = c(70, 30),
  split_names = NULL,
  save_folder = NULL,
  blast_file = NULL,
  coverage_threshold = 80,
  identity_threshold = 80
)
}
\arguments{
\item{wdf}{data table of class \emph{windowed_epit_dt} (returned by
\code{\link[=make_window_df]{make_window_df()}})}

\item{split_level}{which level should be used for splitting? Use "org" for
splitting by source organism ID, "prot" by protein ID or "epit" by
epitope ID. When "prot" is used the routine attempts to identify
different protein versions and treat them as a single unit for
splitting purposes.}

\item{split_perc}{numeric vector of desired splitting percentages. See
Details.}

\item{split_names}{optional character vector with short names for each split.}

\item{save_folder}{path to folder for saving the results.}

\item{blast_file}{path to file containing all-vs-all BLASTp alignment results
for all proteins in \strong{wdf}. See Details.}

\item{coverage_threshold}{coverage threshold for grouping proteins by
similarity, see Details.}

\item{identity_threshold}{identity threshold for grouping proteins by
similarity, see Details.}
}
\value{
A list object containing the split data tables.
}
\description{
Takes a data.table of data of class \emph{windowed_epit_dt} (returned by
\code{\link[=make_window_df]{make_window_df()}}) and split it into mutually exclusive sets of
observations, based on columns \emph{Info_sourceOrg_id}, \emph{Info_protein_id} or
\emph{Info_epitope_id}.
}
\details{
If the sum of \strong{split_perc} is less than 100 an extra split is generated
with the remaining observations - e.g., \code{split_perc = c(50, 30)} results in
three sets with an approximately 50/30/20\% split \emph{of the total observations.}
If the sum is greater than 100 the splits are linearly scaled down so that
the sum becomes 100. Note that the split percents correspond to the number of
observations, not the number of unique IDs.

This function will attempt to approximate the desired split levels, but
depending on the size of \strong{wdf} set and the desired \strong{split_level} it may
not be possible (e.g., if \code{split_level = "org"} and a single organism
corresponds to 90\% of the data, one of the splits will necessarily correspond
to at least 90\% of the data, regardless of the values informed in
\code{split_perc}.

If a BLASTp file is provided the routine will keep any pairs of proteins
having (coverage >= \strong{coverage_threshold} AND
identity >=  \strong{identity_threshold}) under the same split. This is useful to
prevent accidental data leakage due to quasi-identical proteins with
different UIDs. \strong{NOTE}: this only works if \verb{split_level == "prot}.
}
\author{
Felipe Campelo (\email{f.campelo@aston.ac.uk})
}
