.get_utm_epsg <- function(sf_obj) {

  centroid <- sf::st_centroid(sf::st_union(sf_obj))
  coords <- sf::st_coordinates(centroid)

  lon <- coords[1]
  lat <- coords[2]

  zone <- floor((lon + 180) / 6) + 1

  if (lat >= 0) {
    epsg <- 32600 + zone  # Northern hemisphere
  } else {
    epsg <- 32700 + zone  # Southern hemisphere
  }

  return(epsg)
}
.tool_map <- list(
  basic = function(saga, dem_filled) {
    saga$ta_compound$compound_basic_terrain_analysis(dem_filled)
  },

  hydrologic = function(saga, dem) {
    saga$ta_compound$compound_hydrologic_terrain_analysis(dem_filled)
  },

  channel_network = function(saga, dem) {
    saga$ta_compound$compound_channel_network_analysis(dem_filled)
  },

  terrain_classification = function(saga, dem) {
    saga$ta_compound$compound_terrain_classification(dem_filled)
  },

  morphometric = function(saga, dem) {
    saga$ta_compound$compound_morphometric_terrain_analysis(dem_filled)
  },

  mrvbf = function(saga, dem) {
    saga$ta_morphometry$multiresolution_index_of_valley_bottom_flatness_mrvbf(dem_filled)
  }
)
