# ============================================================
#  DOWNLOAD CAGED NACIONAL + COVARIAVEIS  (item 3 da banca)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Objetivo: montar pool doador NACIONAL (fora do RS) para o SDiD das enchentes,
#  com as covariaveis que a literatura recomenda para o matching (ver
#  quality_reports/item3_covariaveis_literatura.md).
#
#  SAIDAS (Base de Dados/Final/):
#   - caged_nacional_mensal.csv : ano, mes, id_municipio, sigla_uf, admissoes,
#                                 populacao, admissoes_por_mil  (2021-01..2025-03)
#   - covariaveis_nacional.csv  : id_municipio, sigla_uf, populacao, pib_pc,
#                                 share_agro, share_ind, share_serv, idhm
#
#  FONTE: basedosdados (BigQuery). Admissoes = saldo_movimentacao = 1 (Novo CAGED).
#  AUTH: service account (chave FORA do repo). Caminho via env SDID_BQ_KEY ou default.
#  AMBIENTE: R 4.4.2 (bigrquery).
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/caged_nacional_download.R
# ============================================================

suppressMessages({ library(bigrquery); library(dplyr); library(readr) })

# ------------------------------------------------------------
# 1. PARAMETROS + AUTH (service account; chave nunca versionada)
# ------------------------------------------------------------
BILLING  <- "sdid-rais-encchentes"
# Chave da service account: caminho via env SDID_BQ_KEY (NUNCA versionar a chave).
#   export SDID_BQ_KEY="/c/.../sua-chave.json"   (ou setx no Windows)
KEY      <- Sys.getenv("SDID_BQ_KEY", "")
ANO_INI  <- 2021L; MES_INI <- 1L       # janela do artigo (BASE_FINAL: 2021-01..2025-03)
ANO_FIM  <- 2025L; MES_FIM <- 3L
ANO_PIB  <- 2021L                      # PIB baseline pre-enchente
ANO_POP  <- 2022L                      # populacao (censo 2022)
ANO_IDHM <- 2010L                      # Atlas (ultimo censo municipal do ADH)

dir_saida <- "Artigos/SDID/Base de Dados/Final"
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

if (!file.exists(KEY)) stop(sprintf("Chave da service account nao encontrada: %s\n  Defina SDID_BQ_KEY ou ajuste o caminho.", KEY))
bq_auth(path = KEY)
cat(">> BigQuery autenticado (service account) | billing:", BILLING, "\n")

dl <- function(sql) bq_table_download(bq_project_query(BILLING, sql), bigint = "integer64")

# ------------------------------------------------------------
# 2. CAGED NACIONAL — admissoes mensais por municipio
#    saldo_movimentacao = 1 (admissao). Filtro de ano poda particoes (custo baixo).
# ------------------------------------------------------------
sql_caged <- sprintf("
  SELECT ano, mes, sigla_uf, id_municipio, COUNT(*) AS admissoes
  FROM `basedosdados.br_me_caged.microdados_movimentacao`
  WHERE ano BETWEEN %d AND %d
    AND saldo_movimentacao = 1
    AND NOT (ano = %d AND mes < %d)
    AND NOT (ano = %d AND mes > %d)
  GROUP BY ano, mes, sigla_uf, id_municipio
", ANO_INI, ANO_FIM, ANO_INI, MES_INI, ANO_FIM, MES_FIM)

cat(">> baixando CAGED nacional (pode levar alguns minutos)...\n")
caged <- dl(sql_caged) %>%
  mutate(ano = as.integer(ano), mes = as.integer(mes),
         id_municipio = as.integer(id_municipio), admissoes = as.integer(admissoes))
cat(sprintf(">> CAGED: %d linhas | %d municipios | %d UFs\n",
            nrow(caged), n_distinct(caged$id_municipio), n_distinct(caged$sigla_uf)))

# ------------------------------------------------------------
# 3. POPULACAO, PIB, IDHM (baseline por municipio)
# ------------------------------------------------------------
pop <- dl(sprintf("SELECT id_municipio, sigla_uf, populacao
                   FROM `basedosdados.br_ibge_populacao.municipio` WHERE ano = %d", ANO_POP)) %>%
  mutate(id_municipio = as.integer(id_municipio), populacao = as.numeric(populacao))

pib <- dl(sprintf("SELECT id_municipio, pib, va, va_agropecuaria, va_industria, va_servicos
                   FROM `basedosdados.br_ibge_pib.municipio` WHERE ano = %d", ANO_PIB)) %>%
  mutate(id_municipio = as.integer(id_municipio))

idhm <- dl(sprintf("SELECT id_municipio, idhm
                    FROM `basedosdados.mundo_onu_adh.municipio` WHERE ano = %d", ANO_IDHM)) %>%
  mutate(id_municipio = as.integer(id_municipio), idhm = as.numeric(idhm))

cat(sprintf(">> pop: %d | pib: %d | idhm: %d municipios\n",
            nrow(pop), nrow(pib), nrow(idhm)))

# ------------------------------------------------------------
# 4. PAINEL MENSAL (admissoes por mil) + TABELA DE COVARIAVEIS
# ------------------------------------------------------------
caged_pm <- caged %>%
  left_join(pop %>% select(id_municipio, populacao), by = "id_municipio") %>%
  filter(!is.na(populacao) & populacao > 0) %>%
  mutate(admissoes_por_mil = admissoes / populacao * 1000)

cov_nac <- pop %>%
  left_join(pib, by = "id_municipio") %>%
  left_join(idhm, by = "id_municipio") %>%
  mutate(pib_pc     = pib / populacao,
         share_agro = va_agropecuaria / va,
         share_ind  = va_industria / va,
         share_serv = va_servicos / va) %>%
  select(id_municipio, sigla_uf, populacao, pib_pc, share_agro, share_ind, share_serv, idhm)

cat(sprintf(">> painel mensal: %d linhas | covariaveis: %d municipios (completos: %d)\n",
            nrow(caged_pm), nrow(cov_nac),
            sum(complete.cases(cov_nac %>% select(pib_pc, share_agro, share_ind, share_serv, idhm)))))

# ------------------------------------------------------------
# 5. SALVAR
# ------------------------------------------------------------
write_csv(caged_pm, file.path(dir_saida, "caged_nacional_mensal.csv"))
write_csv(cov_nac,  file.path(dir_saida, "covariaveis_nacional.csv"))
cat(">> salvo:\n   caged_nacional_mensal.csv\n   covariaveis_nacional.csv\n")

# sanidade: admissoes/mil dos 6 tratados do RS vs media nacional
trat <- c(4300851, 4306767, 4310108, 4312609, 4315800, 4321626)
cat("\n>> sanidade — admissoes/mil media (pre-enchente, 2021-2023) dos tratados:\n")
caged_pm %>% filter(id_municipio %in% trat, ano <= 2023) %>%
  group_by(id_municipio) %>% summarise(adm_mil_medio = mean(admissoes_por_mil), .groups = "drop") %>%
  as.data.frame() %>% print(row.names = FALSE)
cat("\nConcluido.\n")
