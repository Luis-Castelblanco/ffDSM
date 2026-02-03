#' Download a base DEM for Digital Soil Mapping
#'
#' Downloads a Digital Elevation Model (DEM) from the ALOS global dataset
#' using the \code{elevatr} package. The AOI is automatically projected to
#' an appropriate UTM coordinate reference system.
#'
#' @param aoi An \code{sf} object of type POLYGON or MULTIPOLYGON.
#' @param clip Character. Clipping method used by
#'   \code{elevatr::get_elev_raster}. One of \code{"tile"},
#'   \code{"bbox"} (default), or \code{"locations"}.
#'
#' @return A DEM raster projected in a UTM coordinate reference system.
#' @details
#' This function requires a valid OpenTopography API key to be set as an
#' environment variable named \code{OPENTOPOGRAPHY_API_KEY}. The key can be
#' obtained for free from https://opentopography.org/blog/introducing-api-keys-access-opentopography-global-datasets.
#'
#' @export
ff_get_dem <- function(aoi, clip = "bbox") {

  # ---- Checks --------------------------------------------------------------
  if (!inherits(aoi, "sf")) {
    stop("`aoi` must be an sf object.", call. = FALSE)
  }

  geom_type <- unique(sf::st_geometry_type(aoi))
  if (!all(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
    stop("`aoi` must be POLYGON or MULTIPOLYGON.", call. = FALSE)
  }

  if (is.na(sf::st_crs(aoi))) {
    stop("`aoi` must have a valid CRS.", call. = FALSE)
  }

  clip_opts <- c("tile", "bbox", "locations")
  if (!clip %in% clip_opts) {
    stop(
      "`clip` must be one of: ",
      paste(clip_opts, collapse = ", "),
      call. = FALSE
    )
  }
  api_key <- Sys.getenv("OPENTOPO_KEY")


  if (api_key == "") {
    stop(
      "The environment variable was not found 'OPENTOPOGRAPHY_API_KEY'.\n",
      "Configure your OpenTopography API key before using  ff_get_dem().\n",
      "Go to: https://opentopography.org/blog/introducing-api-keys-access-opentopography-global-datasets.\n",
      "Then, set the API key in your R environment using:\n",
      "set_opentopo_key(key)"
    )
  }


  # ---- Project AOI to UTM --------------------------------------------------
  utm_epsg <- .get_utm_epsg(aoi)
  aoi_utm  <- sf::st_transform(aoi, utm_epsg)

  # ---- Download DEM --------------------------------------------------------
  dem <- elevatr::get_elev_raster(
    locations = aoi_utm,
    clip      = clip,
    src       = "alos"
  )
  # ---- Transform DEM to Spatraster ------------------------------------------
  dem <- terra::rast(dem)

  return(dem)

}
