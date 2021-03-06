% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mdm.R
\name{plotMat}
\alias{plotMat}
\title{Plots network as adjacency matrix.}
\usage{
plotMat(adj, col = heat.colors(12), lab = NULL, lim = c(0, 1),
  diag = FALSE)
}
\arguments{
\item{adj}{2D adjacency matrix.}

\item{col}{color palette.}

\item{lab}{labels as character array.}

\item{lim}{vector with two min and max values for color scaling.}

\item{diag}{true or false, if true showing values on the diagnoal line.}
}
\description{
Plots network as adjacency matrix.
}

