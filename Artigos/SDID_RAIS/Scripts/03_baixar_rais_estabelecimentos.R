# =============================================================================
# 03_baixar_rais_estabelecimentos.R — Baixa RAIS Estabelecimentos, todos os
# municípios do RS, 2021+. Colunas mínimas necessárias para a análise setorial
# (composição/estoque por Seção CNAE, ano a ano).
# =============================================================================

library(basedosdados)

billing_project_id <- Sys.getenv("BILLING_PROJECT_ID", unset = NA)
if (is.na(billing_project_id) || billing_project_id == "") {
  stop("Defina BILLING_PROJECT_ID antes de rodar este script.")
}
set_billing_id(billing_project_id)

raw_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

message("Baixando RAIS Estabelecimentos (RS, 2021+)...")

estabelecimentos_rs <- read_sql(
  "SELECT ano, id_municipio, quantidade_vinculos_ativos, quantidade_vinculos_clt,
          cnae_2_subclasse, tamanho_estabelecimento, indicador_atividade_ano
   FROM `basedosdados.br_me_rais.microdados_estabelecimentos`
   WHERE sigla_uf = 'RS' AND ano >= 2021"
)

message(sprintf(
  "Baixadas %d linhas, %d municipios distintos, anos %s.",
  nrow(estabelecimentos_rs),
  dplyr::n_distinct(estabelecimentos_rs$id_municipio),
  paste(sort(unique(estabelecimentos_rs$ano)), collapse = ", ")
))

saveRDS(
  estabelecimentos_rs,
  file.path(raw_dir, "rais_estabelecimentos_rs_2021_2025.rds")
)

message("Salvo em: ", file.path(raw_dir, "rais_estabelecimentos_rs_2021_2025.rds"))
