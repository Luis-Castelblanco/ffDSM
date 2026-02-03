#' Generate oblique geographic coordinates (OGC)
#'
#' Computes oblique geographic coordinates based on a DEM following the
#' approach of Møller et al, 2020 (https://doi.org/10.5194/soil-6-269-2020). These covariates capture broad spatial trends
#' and are useful as baseline predictors in Digital Soil Mapping.
#'
#' @param dem A \code{SpatRaster} DEM (projected, planar coordinates).
#' @param n_directions Integer. Number of oblique directions to compute.
#'
#' @return A \code{SpatRaster} with oblique coordinate layers.
#' @details
#' This function depends on the package \code{OGC}, which is not available on
#' CRAN. Users must install it manually using:
#'
#' \preformatted{
#' devtools::install_bitbucket("abmoeller/ogc/rPackage/OGC")
#' }
#'
#' @export
ff_get_ogc <- function(dem, n_directions = 6) {

  # ---- Checks --------------------------------------------------------------
  if (!requireNamespace("OGC", quietly = TRUE)) {
    stop(
      "The 'OGC' package is not installed.\n",
      "Install it manually from Bitbucket with:\n",
      "  devtools::install_bitbucket('abmoeller/ogc/rPackage/OGC')\n"
    )
  }

  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a SpatRaster.", call. = FALSE)
  }

  if (!is.numeric(n_directions) || n_directions < 4) {
    stop("`n_directions` must be an integer >= 4.", call. = FALSE)
  }

  if (!requireNamespace("OGC", quietly = TRUE)) {
    stop("Package 'OGC' is required but not installed.", call. = FALSE)
  }

  # ---- Compute OGC ---------------------------------------------------------
  ogc <- OGC::makeOGC(
    raster::raster(dem),
    n_directions
  )

  # ---- Reproject to DEM grid ----------------------------------------------
  ogc <- terra::project(
    terra::rast(ogc),
    dem,
    method = "near"
  )

  # ---- Naming --------------------------------------------------------------
  names(ogc) <- paste0("ogc_", seq_len(terra::nlyr(ogc)))

  message("Oblique geographic coordinates generated.")

  return(ogc)
}
