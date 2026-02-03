#' Download Sentinel imagery and compute spectral indices
#'
#' Downloads Sentinel-1 and/or Sentinel-2 imagery using the \code{rsi} package
#' and computes a standardized set of spectral indices for Digital Soil Mapping.
#'
#' @param aoi An \code{sf} POLYGON or MULTIPOLYGON.
#' @param dem A \code{SpatRaster} used as spatial reference.
#' @param sensor Character vector. One or both of \code{"S2"}, \code{"S1"}.
#' @param dates_S1, dates_S2 Character. Start and end dates range (c(YYYY-MM-DD,YYYY-MM-DD)).
#' @param s2_composite Character. Composite function for Sentinel-2.
#' @param mask_s2 Logical. Apply SCL mask for Sentinel-2.
#' @param exclude_domains Character. Index domains to exclude.
#' @param verbose Logical.
#'
#' @return A named list of \code{SpatRaster} objects with spectral indices.
#'
#' @export
ff_get_rs_indices <- function(
    aoi,
    dem,
    sensor = c("S2", "S1"),
    dates_S1,
    dates_S2,
    s2_composite = "median",
    mask_s2 = TRUE,
    exclude_domains = c("urban", "snow"),
    verbose = TRUE
) {

  # ---- Checks --------------------------------------------------------------
  if (!inherits(aoi, "sf")) {
    stop("`aoi` must be an sf object.", call. = FALSE)
  }

  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` must be a SpatRaster.", call. = FALSE)
  }

  sensor <- match.arg(sensor, choices = c("S2", "S1"), several.ok = TRUE)
  # ---- Project AOI to UTM --------------------------------------------------
  utm_epsg <- .get_utm_epsg(aoi)
  aoi_utm  <- sf::st_transform(aoi, utm_epsg)

  # ---- Output container ----------------------------------------------------
  out <- list()

  # ====================== Sentinel-1 =======================================
  if ("S1" %in% sensor) {

    if (verbose) message("Downloading Sentinel-1 imagery...")

    s1 <- rsi::get_sentinel1_imagery(
      aoi = aoi_utm,
      start_date = dates_S1[1],
      end_date   = dates_S1[2],
      collection = "sentinel-1-grd",
      output_filename = tempfile(fileext = ".tif")
    )

    s1 <- terra::project(terra::rast(s1), dem, method = "near")

    idx1 <- rsi::filter_bands(bands = names(s1))

    if (verbose) message("Computing Sentinel-1 indices...")

    ind1 <- rsi::calculate_indices(
      raster::stack(s1),
      idx1,
      overwrite = TRUE,
      output_filename = tempfile(fileext = ".tif")
    )

    ind1 <- terra::project(terra::rast(ind1), dem, method = "near")
    names(ind1) <- paste0("S1_", names(ind1))

    out$S1 <- c(s1,ind1)
  }

  # ====================== Sentinel-2 =======================================
  if ("S2" %in% sensor) {

    if (verbose) message("Downloading Sentinel-2 imagery...")

    s2 <- rsi::get_sentinel2_imagery(
      aoi = aoi_utm,
      start_date = dates_S2[1],
      end_date   = dates_S2[2],
      composite_function = s2_composite,
      mask_band = if (mask_s2) "SCL" else NULL,
      mask_function = if (mask_s2) rsi::sentinel2_mask_function else NULL,
      output_filename = tempfile(fileext = ".tif")
    )

    s2 <- terra::project(terra::rast(s2), dem, method = "near")
    # Plot the Sentinel 2 data in real color
    terra::plotRGB(s2, r = 4, g = 3, b = 2, stretch = "lin", main = "Sentinel 2 - Real Color")


    idx2 <- rsi::filter_bands(bands = names(s2)[-10]) |>
      dplyr::filter(!application_domain %in% exclude_domains)

    if (verbose) message("Computing Sentinel-2 indices...")

    ind2 <- rsi::calculate_indices(
      raster::stack(s2),
      idx2,
      overwrite = TRUE,
      output_filename = tempfile(fileext = ".tif")
    )

    ind2 <- terra::project(terra::rast(ind2), dem, method = "near")
    names(ind2) <- paste0("S2_", names(ind2))

    out$S2 <- c(s2, ind2)
  }

  if (verbose) message("Spectral indices generated successfully.")

  return(out)
}
