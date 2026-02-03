#' Generate terrain covariates using SAGA GIS (Rsagacmd required)
#'
#' Computes a standardized set of terrain covariates for Digital Soil Mapping
#' using SAGA GIS. The DEM is filled by default using the Wang & Liu algorithm.
#'
#' @param dem A \code{SpatRaster} DEM (projected, planar coordinates).
#' @param saga_path Full path to \code{saga_cmd.exe}.
#' @param tools Character. One or more tool groups to run. Options are
#'   \code{"all"}, \code{"basic"}, \code{"hydrologic"},
#'   \code{"channel_network"}, \code{"terrain_classification"},
#'   \code{"morphometric"}, \code{"mrvbf"}.
#' @param cores Integer. Number of cores for SAGA.
#' @param verbose Logical. Print SAGA messages.
#'
#' @return A \code{SpatRaster} with terrain covariates.
#'
#' @export
ff_get_terrain <- function(
    dem,
    saga_path,
    tools   = "all",
    cores   = 4,
    verbose = TRUE
) {

  # ---- Checks --------------------------------------------------------------
  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a SpatRaster.", call. = FALSE)
  }

  if (is.na(terra::crs(dem))) {
    stop("`dem` must have a valid CRS.", call. = FALSE)
  }

  if (!file.exists(saga_path)) {
    stop("`saga_path` does not exist.", call. = FALSE)
  }

  # ---- SAGA initialization ------------------------------------------------
  saga <- Rsagacmd::saga_gis(
    saga_bin = saga_path,
    cores    = cores,
    verbose  = verbose
  )


  # ---- Fill sinks ----------------------------------------------------------
  if (verbose) message("Filling DEM sinks (Wang & Liu)...")

  dem_filled <- saga$ta_preprocessor$fill_sinks_wang_liu(dem)$filled


  # ---- Tool selection ------------------------------------------------------
  available_tools <- names(.tool_map)

  if ("all" %in% tools) {
    tools <- available_tools
  }

  invalid <- setdiff(tools, available_tools)
  if (length(invalid) > 0) {
    stop("Invalid tools: ", paste(invalid, collapse = ", "), call. = FALSE)
  }

  # ---- Run tools -----------------------------------------------------------
  outputs <- lapply(tools, function(tl) {
    if (verbose) message("Running SAGA tool group: ", tl)
    .tool_map[[tl]](saga, dem_filled)
  })


  # ---- Extract SpatRaster --------------------------------------------------
  rasters <- unlist(outputs, recursive = TRUE)
  rasters <- Filter(function(x) inherits(x, "SpatRaster"), rasters)

  rasters <- terra::rast(rasters[!duplicated(names(rasters))])

  # ---- Stack ---------------------------------------------------------------
  rasters <- c(dem_filled, rasters)
  names(rasters)[1] <- "dem_filled"
  names <- names(rasters)

  covs_terrain <- dem
  covs_terrain <- terra::rast(covs_terrain, nlyr = terra::nlyr(rasters))
  terra::values(covs_terrain) <- terra::values(rasters)
  names(covs_terrain) <- names
  if (verbose) message("Terrain covariates generated successfully.")

  return(covs_terrain)
}
