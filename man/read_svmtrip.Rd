% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_svmtrip.R
\name{read_svmtrip}
\alias{read_svmtrip}
\title{Read saved output from SVMtrip}
\usage{
read_svmtrip(res.file, protID, proteins, ...)
}
\arguments{
\item{res.file}{path to the results file. Must be an HTML file containing the
SVMtrip output.}

\item{protID}{ID of the protein represented in \code{res.file}}

\item{proteins}{data frame containing protein data related to the predictions
in \code{res.file}. Each position in a protein must be represented by a row in
this data frame. Must have at least the columns \emph{Info_UID} (with protein
IDs) and \emph{Info_center_pos} (with position on the protein).}

\item{...}{Currently unused.}
}
\description{
This function is used to read the saved HTML output from SVMtrip
}
\author{
Felipe Campelo (\email{f.campelo@aston.ac.uk})
}
