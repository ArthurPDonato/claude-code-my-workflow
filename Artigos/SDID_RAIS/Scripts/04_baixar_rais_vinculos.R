# =============================================================================
# 04_baixar_rais_vinculos.R — Baixa RAIS Vínculos, todos os municípios do RS,
# 2021+. Colunas mínimas para reconstruir fluxo mensal de admissões/
# desligamentos por Seção CNAE (equivalente setorial ao CAGED do artigo
# original). Sem colunas de característica de trabalhador — essa parte fica
# para quando a base RAIS identificada (fora da Base dos Dados) for integrada.
# =============================================================================

library(basedosdados)

billing_project_id <- Sys.getenv("BILLING_PROJECT_ID", unset = NA)
if (is.na(billing_project_id) || billing_project_id == "") {
  stop("Defina BILLING_PROJECT_ID antes de rodar este script.")
}
set_billing_id(billing_project_id)

raw_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

message("Baixando RAIS Vinculos (RS, 2021+) — pode levar alguns minutos (~24M linhas)...")

vinculos_rs <- read_sql(
  "SELECT ano, id_municipio, mes_admissao, mes_desligamento, tipo_vinculo,
          vinculo_ativo_3112, cnae_2_subclasse, tipo_admissao
   FROM `basedosdados.br_me_rais.microdados_vinculos`
   WHERE sigla_uf = 'RS' AND ano >= 2021"
)

message(sprintf(
  "Baixadas %d linhas, %d municipios distintos, anos %s.",
  nrow(vinculos_rs),
  dplyr::n_distinct(vinculos_rs$id_municipio),
  paste(sort(unique(vinculos_rs$ano)), collapse = ", ")
))

saveRDS(
  vinculos_rs,
  file.path(raw_dir, "rais_vinculos_rs_2021_2025.rds")
)

message("Salvo em: ", file.path(raw_dir, "rais_vinculos_rs_2021_2025.rds"))
