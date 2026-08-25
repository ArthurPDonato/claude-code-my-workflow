# =============================================================================
# 02_verificar_metadados.R — Confirma nomes de tabela, colunas e anos
# disponíveis da RAIS na Base dos Dados, antes de baixar qualquer dado.
#
# Não baixa microdados. Só metadados + uma contagem por ano (barata: usa
# COUNT/GROUP BY, que o BigQuery processa lendo só a coluna `ano`).
# =============================================================================

library(basedosdados)
library(dplyr)

billing_project_id <- Sys.getenv("BILLING_PROJECT_ID", unset = NA)
if (is.na(billing_project_id) || billing_project_id == "") {
  stop("Defina BILLING_PROJECT_ID antes de rodar este script.")
}
set_billing_id(billing_project_id)

out_dir <- here::here("Artigos", "SDID_RAIS", "Resultados")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Tabelas disponíveis no dataset br_me_rais --------------------------
# list_dataset_tables()/get_table_columns() dependem do catálogo de metadados
# da API da BD, que voltou vazio para este dataset — usar INFORMATION_SCHEMA
# do próprio BigQuery em vez disso (fonte mais confiável).
message("Tabelas no dataset br_me_rais (via INFORMATION_SCHEMA):")
tabelas_rais <- read_sql(
  "SELECT table_name
   FROM `basedosdados.br_me_rais.INFORMATION_SCHEMA.TABLES`"
)
print(tabelas_rais)

# ---- 2. Colunas de RAIS Vínculos e Estabelecimentos -------------------------
message("Colunas — microdados_vinculos:")
cols_vinculos <- read_sql(
  "SELECT column_name, data_type
   FROM `basedosdados.br_me_rais.INFORMATION_SCHEMA.COLUMNS`
   WHERE table_name = 'microdados_vinculos'
   ORDER BY ordinal_position"
)
print(cols_vinculos, n = Inf)

message("Colunas — microdados_estabelecimentos:")
cols_estabelecimentos <- read_sql(
  "SELECT column_name, data_type
   FROM `basedosdados.br_me_rais.INFORMATION_SCHEMA.COLUMNS`
   WHERE table_name = 'microdados_estabelecimentos'
   ORDER BY ordinal_position"
)
print(cols_estabelecimentos, n = Inf)

# ---- 3. Anos disponíveis (RS apenas, contagem por ano) ----------------------
message("Anos disponíveis — microdados_vinculos (RS, 2021+):")
anos_vinculos <- read_sql(
  "SELECT ano, COUNT(*) AS n
   FROM `basedosdados.br_me_rais.microdados_vinculos`
   WHERE sigla_uf = 'RS' AND ano >= 2021
   GROUP BY ano
   ORDER BY ano"
)
print(anos_vinculos)

message("Anos disponíveis — microdados_estabelecimentos (RS, 2021+):")
anos_estabelecimentos <- read_sql(
  "SELECT ano, COUNT(*) AS n
   FROM `basedosdados.br_me_rais.microdados_estabelecimentos`
   WHERE sigla_uf = 'RS' AND ano >= 2021
   GROUP BY ano
   ORDER BY ano"
)
print(anos_estabelecimentos)

# ---- 4. Diretório de CNAE (para mapear subclasse -> Seção) ------------------
message("Tabelas de diretório CNAE em br_bd_diretorios_brasil:")
tabelas_diretorio <- read_sql(
  "SELECT table_name
   FROM `basedosdados.br_bd_diretorios_brasil.INFORMATION_SCHEMA.TABLES`
   WHERE LOWER(table_name) LIKE '%cnae%'"
)
print(tabelas_diretorio)

# ---- 5. Estimativa de custo (dry run) das queries de download da Fase 2 ----
# bq_project_query com dry_run=TRUE não executa a query, só retorna os bytes
# que seriam processados — usado para estimar custo antes de baixar de fato.
estimar_bytes <- function(sql) {
  job <- bigrquery::bq_project_query(billing_project_id, sql, dry_run = TRUE)
  attr(job, "bytes")
}

sql_vinculos_download <- "
  SELECT ano, id_municipio, mes_admissao, mes_desligamento, tipo_vinculo,
         vinculo_ativo_3112, cnae_2_subclasse, tipo_admissao
  FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE sigla_uf = 'RS' AND ano >= 2021
"
sql_estabelecimentos_download <- "
  SELECT ano, id_municipio, quantidade_vinculos_ativos, quantidade_vinculos_clt,
         cnae_2_subclasse, tamanho_estabelecimento, indicador_atividade_ano
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos`
  WHERE sigla_uf = 'RS' AND ano >= 2021
"

bytes_vinculos <- estimar_bytes(sql_vinculos_download)
bytes_estabelecimentos <- estimar_bytes(sql_estabelecimentos_download)

gb <- function(b) round(b / 1024^3, 3)

message(sprintf(
  "Estimativa RAIS Vinculos (download completo, colunas selecionadas): %.3f GB",
  gb(bytes_vinculos)
))
message(sprintf(
  "Estimativa RAIS Estabelecimentos (download completo, colunas selecionadas): %.3f GB",
  gb(bytes_estabelecimentos)
))
message(sprintf(
  "Total estimado: %.3f GB (limite gratuito BigQuery: 1024 GB/mes)",
  gb(bytes_vinculos) + gb(bytes_estabelecimentos)
))

# ---- Salva tudo para revisão -------------------------------------------------
saveRDS(
  list(
    tabelas_rais = tabelas_rais,
    cols_vinculos = cols_vinculos,
    cols_estabelecimentos = cols_estabelecimentos,
    anos_vinculos = anos_vinculos,
    anos_estabelecimentos = anos_estabelecimentos,
    tabelas_diretorio_cnae = tabelas_diretorio,
    bytes_estimados_vinculos = bytes_vinculos,
    bytes_estimados_estabelecimentos = bytes_estabelecimentos
  ),
  file.path(out_dir, "metadados_rais.rds")
)

message("Metadados salvos em: ", file.path(out_dir, "metadados_rais.rds"))
