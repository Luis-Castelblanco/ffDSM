#' Download climatic covariates (CHELSA)
#'
#' Downloads bioclimatic variables from CHELSA and resamples them
#' to match a DEM template.
#'
#' @param aoi sf POLYGON or MULTIPOLYGON in EPSG:4326
#' @param dem terra::SpatRaster used as spatial template
#' @param source Climate data source. Default "CHELSA"
#' @param variables Climatic variables to download. Default "all" or bio01-bio19, kg5, npp
#' @param resolution Resolution in arc-secondsc("2.5", "5", "10", "0.5"). Default 0.5
#' @param resample_method Resampling method. Default "bicubic"
#'
#' @return terra::SpatRaster
#' @export
ff_get_climate <- function(
    dem,
    aoi,
    variables = "all",
    overwrite = FALSE,
    crop = TRUE
) {

  # =============================
  # 0. Dependencias
  # =============================
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("El paquete 'terra' es requerido.")
  }
  library(terra)

  # =============================
  # 1. Validaciones DEM
  # =============================
  if (!inherits(dem, "SpatRaster")) {
    stop("`dem` debe ser un objeto SpatRaster.")
  }

  if (is.na(crs(dem))) {
    stop("El DEM no tiene CRS definido.")
  }

  if (is.lonlat(dem)) {
    stop(
      "El DEM está en coordenadas geográficas (lon/lat). ",
      "Debe estar en coordenadas planas (ej. UTM)."
    )
  }

  # =============================
  # 2. Validaciones AOI
  # =============================
  if (inherits(aoi, "sf")) {
    aoi.clim <- vect(aoi)
  }

  # if (!inherits(aoi, "SpatVector")) {
  #   stop("`aoi` debe ser un objeto sf o SpatVector.")
  # }

  if (is.na(crs(aoi))) {
    stop("El AOI no tiene CRS definido.")
  }

  # Reproyectar AOI al CRS del DEM
  # if (!same.crs(aoi, dem)) {
  #   aoi <- project(aoi, dem)
  # }

  # =============================
  # 3. URLs CHELSA (v2.1)
  # =============================
  chelsa_urls <- c(
    bio01 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio01/1981-2010/CHELSA_bio01_1981-2010_V.2.1.tif",
    # bio02 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio02/1981-2010/CHELSA_bio02_1981-2010_V.2.1.tif",
    # bio03 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio03/1981-2010/CHELSA_bio03_1981-2010_V.2.1.tif",
    # bio04 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio04/1981-2010/CHELSA_bio04_1981-2010_V.2.1.tif",
    bio05 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio05/1981-2010/CHELSA_bio05_1981-2010_V.2.1.tif",
    bio06 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio06/1981-2010/CHELSA_bio06_1981-2010_V.2.1.tif",
    # bio07 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio07/1981-2010/CHELSA_bio07_1981-2010_V.2.1.tif",
    bio08 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio08/1981-2010/CHELSA_bio08_1981-2010_V.2.1.tif",
    bio09 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio09/1981-2010/CHELSA_bio09_1981-2010_V.2.1.tif",
    bio10 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio10/1981-2010/CHELSA_bio10_1981-2010_V.2.1.tif",
    bio11 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio11/1981-2010/CHELSA_bio11_1981-2010_V.2.1.tif",
    bio12 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio12/1981-2010/CHELSA_bio12_1981-2010_V.2.1.tif",
    bio13 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio13/1981-2010/CHELSA_bio13_1981-2010_V.2.1.tif",
    bio14 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio14/1981-2010/CHELSA_bio14_1981-2010_V.2.1.tif",
    bio15 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio15/1981-2010/CHELSA_bio15_1981-2010_V.2.1.tif",
    bio16 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio16/1981-2010/CHELSA_bio16_1981-2010_V.2.1.tif",
    bio17 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio17/1981-2010/CHELSA_bio17_1981-2010_V.2.1.tif",
    bio18 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio18/1981-2010/CHELSA_bio18_1981-2010_V.2.1.tif",
    bio19 = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/bio19/1981-2010/CHELSA_bio19_1981-2010_V.2.1.tif",
    # kg5   = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/kg5/1981-2010/CHELSA_kg5_1981-2010_V.2.1.tif",
    npp   = "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim/npp/1981-2010/CHELSA_npp_1981-2010_V.2.1.tif"
  )
  # =============================
  # 4. Resolver opción "all"
  # =============================
  if (length(variables) == 1 && variables == "all") {
    variables <- names(chelsa_urls)
  }
  # =============================
  # 5. Validar variables
  # =============================
  if (!is.character(variables)) {
    stop("`variables` debe ser un vector de caracteres o 'all'.")
  }

  missing_vars <- setdiff(variables, names(chelsa_urls))
  if (length(missing_vars) > 0) {
    stop(
      "Variables CHELSA no válidas: ",
      paste(missing_vars, collapse = ", ")
    )
  }
  # =============================
  # 6. Cache
  # =============================
  cache <- TRUE
  cache_dir <- if (cache) {
    tools::R_user_dir("ffDSM", "cache")
  } else {
    tempdir()
  }
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)


  # =============================
  # 7. Descarga + crop
  # =============================
  rasters <- lapply(variables, function(v) {

    url  <- chelsa_urls[[v]]
    dest <- file.path(cache_dir, basename(url))

    if (!file.exists(dest) || overwrite) {
      message("Descargando CHELSA: ", v)
      download.file(url, dest, mode = "wb", quiet = FALSE)
    } else {
      message("Usando CHELSA desde cache: ", v)
    }

    r <- terra::rast(dest)

    if (crop) {
      aoi_clim <- st_transform(aoi, crs = "EPSG:4326")
      r <- terra::crop(r, aoi_clim)
      dem_wgs84 <- terra::project(dem, "EPSG:4326")
      r <- terra::resample(r, dem_wgs84, method = "cubic")
    }

    r
  })

  chelsa <- terra::rast(rasters) %>%
    terra::project(dem, method = "near")
  names(chelsa) <- variables

  return(chelsa)
}
