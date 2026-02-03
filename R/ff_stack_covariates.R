#' Stack and align covariates for Digital Soil Mapping
#'
#' Builds a harmonized stack of environmental covariates for Digital Soil
#' Mapping (DSM). All covariates are reprojected, resampled, and optionally
#' cropped using a DEM as the spatial template. The function is intended as a
#' fast and standardized baseline for DSM workflows, prioritizing robustness
#' and reproducibility over optimal tuning.
#'
#' @param dem SpatRaster. Digital Elevation Model used as spatial template.
#'   The DEM must be in projected (planar) coordinates and have a valid CRS.
#'
#' @param ... One or more objects of class SpatRaster, or lists of SpatRaster,
#'   representing environmental covariates (e.g. terrain derivatives, remote
#'   sensing indices, climatic variables, oblique coordinates).
#'
#' @param resample_method Character. Resampling method passed to
#'   \code{terra::resample()}. Typical options are \code{"bilinear"},
#'   \code{"near"}, or \code{"bicubic"}. Default is \code{"near"}.
#'
#' @param crop Logical. If \code{TRUE} (default), covariates are cropped to the
#'   spatial extent of the DEM before stacking.
#'
#' @param remove_constant Logical. If \code{TRUE} (default), covariates with
#'   zero spatial variance (constant layers) are removed from the final stack.
#'
#' @param verbose Logical. If \code{TRUE} (default), informative messages about
#'   alignment, cleaning, and final stack size are printed to the console.
#'
#' @return A SpatRaster containing a harmonized stack of covariates aligned to
#'   the DEM grid, ready for extraction and model fitting.
#'
#' @details
#' The DEM is treated as the authoritative spatial reference. All input
#' covariates are forced to match its coordinate reference system, resolution,
#' and extent. This function does not download or compute covariates; it only
#' harmonizes existing raster layers.
#'
#' @seealso \code{\link{ff_get_dem}}, \code{\link{ff_get_terrain}},
#'   \code{\link{ff_get_rs_indices}}, \code{\link{ff_get_chelsa}}
#'
#' @export
ff_stack_covariates <- function(
    dem,
    ...,
    resample_method = "near",
    crop = TRUE,
    remove_constant = TRUE,
    verbose = TRUE
) {

  # =============================
  # 0. Dependencias
  # =============================
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("El paquete 'terra' es requerido.")
  }
  library(terra)

  # =============================
  # 1. Validar DEM
  # =============================
  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` debe ser un SpatRaster.")
  }

  if (is.na(crs(dem))) {
    stop("El DEM no tiene CRS definido.")
  }

  if (is.lonlat(dem)) {
    stop("El DEM debe estar en coordenadas planas.")
  }

  # =============================
  # 2. Recoger covariables
  # =============================
  covs <- list(...)

  if (length(covs) == 0) {
    stop("Debe proveer al menos un conjunto de covariables.")
  }

  # Aplanar listas internas
  covs <- unlist(covs, recursive = TRUE)

  # Mantener solo SpatRaster
  covs <- Filter(function(x) inherits(x, "SpatRaster"), covs)

  if (length(covs) == 0) {
    stop("No se encontraron objetos SpatRaster válidos.")
  }

  # =============================
  # 3. Alinear cada covariable
  # =============================
  aligned <- lapply(covs, function(r) {

    if (is.na(crs(r))) {
      stop("Una covariable no tiene CRS definido.")
    }

    if (!same.crs(r, dem)) {
      r <- project(r, dem, method = resample_method)
    }

    if (crop) {
      r <- crop(r, dem)
    }

    r <- resample(r, dem, method = resample_method)

    r
  })

  # =============================
  # 4. Stack
  # =============================
  cov_stack <- rast(aligned)

  # =============================
  # 5. Limpiar capas problemáticas
  # =============================
  if (remove_constant) {

    v <- terra::global(cov_stack, "sd", na.rm = TRUE)
    sd_vals <- v[, 1]

    keep_idx <- which(sd_vals > 0 & !is.na(sd_vals))
    drop_idx <- which(sd_vals == 0 | is.na(sd_vals))

    if (verbose) {
      if (length(drop_idx) > 0) {
        message(
          "Se removieron ", length(drop_idx),
          " covariables constantes o sin varianza:"
        )
        message("  - ", paste(names(cov_stack)[drop_idx], collapse = ", "))
      } else {
        message("No se encontraron covariables constantes.")
      }
    }

    cov_stack <- cov_stack[[keep_idx]]
  }


  # =============================
  # 6. Nombres únicos
  # =============================
  names(cov_stack) <- make.unique(names(cov_stack))

  if (verbose) {
    message("Stack final con ", nlyr(cov_stack), " covariables.")
  }

  return(cov_stack)
}
