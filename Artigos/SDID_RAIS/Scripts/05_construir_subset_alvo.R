# =============================================================================
# 05_construir_subset_alvo.R — A partir das bases completas do RS (Raw/),
# extrai o subset dos 6 municípios-alvo (mesmos do artigo SDID original) e
# salva separadamente em Final/. As bases completas do RS continuam
# disponíveis em Raw/ para servir de pool doador nos scripts seguintes.
#
# id_municipio (IBGE) dos 6 municípios-alvo — mesmos do artigo original
# (Artigos/SDID/Scripts/extrair_pool_doador.R):
#   Eldorado do Sul  4306767
#   Muçum            4312609
#   Roca Sales       4315800
#   Arambaré         4300851
#   Travesseiro      4321626
#   Igrejinha        4310108
# =============================================================================

library(dplyr)

raw_dir   <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw")
final_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Final")
dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)

ids_alvo <- c(
  "4306767", # Eldorado do Sul
  "4312609", # Mucum
  "4315800", # Roca Sales
  "4300851", # Arambare
  "4321626", # Travesseiro
  "4310108"  # Igrejinha
)

# ---- Estabelecimentos --------------------------------------------------------
estabelecimentos_rs <- readRDS(
  file.path(raw_dir, "rais_estabelecimentos_rs_2021_2025.rds")
)

estabelecimentos_alvo <- estabelecimentos_rs %>%
  filter(id_municipio %in% ids_alvo)

message(sprintf(
  "Estabelecimentos-alvo: %d linhas, %d dos %d municipios-alvo presentes.",
  nrow(estabelecimentos_alvo),
  dplyr::n_distinct(estabelecimentos_alvo$id_municipio),
  length(ids_alvo)
))

saveRDS(
  estabelecimentos_alvo,
  file.path(final_dir, "rais_estabelecimentos_alvo_2021_2025.rds")
)

# ---- Vinculos -----------------------------------------------------------------
vinculos_rs <- readRDS(file.path(raw_dir, "rais_vinculos_rs_2021_2025.rds"))

vinculos_alvo <- vinculos_rs %>%
  filter(id_municipio %in% ids_alvo)

message(sprintf(
  "Vinculos-alvo: %d linhas, %d dos %d municipios-alvo presentes.",
  nrow(vinculos_alvo),
  dplyr::n_distinct(vinculos_alvo$id_municipio),
  length(ids_alvo)
))

saveRDS(
  vinculos_alvo,
  file.path(final_dir, "rais_vinculos_alvo_2021_2025.rds")
)

# ---- Checagem de sanidade ----------------------------------------------------
faltantes <- setdiff(ids_alvo, unique(estabelecimentos_rs$id_municipio))
if (length(faltantes) > 0) {
  warning(
    "id_municipio ausentes na base de Estabelecimentos do RS: ",
    paste(faltantes, collapse = ", ")
  )
} else {
  message("OK: todos os 6 municipios-alvo presentes na base completa do RS.")
}
