% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mdm.R
\name{getThreshAdj}
\alias{getThreshAdj}
\title{Get thresholded adjacency network.}
\usage{
getThreshAdj(adj, models, winner)
}
\arguments{
\item{adj}{list with network adjacency from getAdjacency().}

\item{models}{matrix 3D with full model estimates.}

\item{winner}{matrix 2D with winning models.}
}
\value{
thr list with thresholded network adjacency.
}
\description{
Get thresholded adjacency network.
}

