% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mdm.R
\name{getWinner}
\alias{getWinner}
\title{Get winner network by maximazing log predictive likelihood (LPL)
from a set of models.}
\usage{
getWinner(models, nodes)
}
\arguments{
\item{models}{2D matrix, or 3D models x node.}

\item{nodes}{number of nodes.}
}
\value{
winner array with highest scored model(s).
}
\description{
Get winner network by maximazing log predictive likelihood (LPL)
from a set of models.
}

