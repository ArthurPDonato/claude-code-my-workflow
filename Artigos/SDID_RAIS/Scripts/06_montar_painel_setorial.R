# =============================================================================
# 06_montar_painel_setorial.R — Monta o painel setorial (Seção CNAE) usado
# pelo SDID por setor:
#   (a) painel MENSAL de admissoes por Seção CNAE, id_municipio x ano-mes
#       (equivalente setorial ao "admissoes_por_mil" do CAGED no artigo
#       original), reconstruído a partir de mes_admissao em RAIS Vínculos;
#   (b) painel ANUAL de estoque/composição por Seção CNAE, id_municipio x ano
#       (vínculos ativos, nº estabelecimentos), a partir de RAIS
#       Estabelecimentos.
#
# Usa a base COMPLETA do RS (Raw/) — o pool doador é selecionado aqui via
# proporcao_atingidos (MUPRS), replicando extrair_pool_doador.R do artigo
# original. Os municípios-alvo continuam incluídos no painel (marcados via
# `tratado`); a exclusão do pool doador acontece no script de modelagem
# (07_sdid_por_setor.R), não aqui.
# =============================================================================

library(basedosdados)
library(dplyr)
library(tidyr)
library(lubridate)

billing_project_id <- Sys.getenv("BILLING_PROJECT_ID", unset = NA)
if (is.na(billing_project_id) || billing_project_id == "") {
  stop("Defina BILLING_PROJECT_ID antes de rodar este script.")
}
set_billing_id(billing_project_id)

raw_dir   <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw")
final_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Final")

ids_alvo <- c("4306767", "4312609", "4315800", "4300851", "4321626", "4310108")
LIMIAR_BASELINE <- 0.005

# ---- Diretorio CNAE: subclasse -> Secao -------------------------------------
message("Baixando diretorio CNAE (subclasse -> secao)...")
cnae_dir <- read_sql(
  "SELECT DISTINCT subclasse, secao, descricao_secao
   FROM `basedosdados.br_bd_diretorios_brasil.cnae_2`"
)
saveRDS(cnae_dir, file.path(raw_dir, "cnae_diretorio_secao.rds"))

# ---- Covariaveis (proporcao_atingidos, PopMun) do artigo original ----------
covs <- readxl::read_excel(
  here::here("Artigos", "SDID", "Base de Dados", "Final", "Covariaveis_SDID_Final.xlsx")
) %>%
  transmute(
    id_municipio = as.character(round(id_municipio)),
    proporcao_atingidos,
    PopMun,
    NOME
  )

stopifnot(all(ids_alvo %in% covs$id_municipio))

donor_pool_ids <- covs %>%
  filter(proporcao_atingidos <= LIMIAR_BASELINE, !(id_municipio %in% ids_alvo)) %>%
  pull(id_municipio)

message(sprintf(
  "Pool doador: %d municipios (proporcao_atingidos <= %.3f, excluidos os 6 tratados).",
  length(donor_pool_ids), LIMIAR_BASELINE
))

# ---- Painel mensal de admissoes por Secao CNAE ------------------------------
vinculos_rs <- readRDS(file.path(raw_dir, "rais_vinculos_rs_2021_2025.rds"))

vinculos_rs <- vinculos_rs %>%
  left_join(cnae_dir, by = c("cnae_2_subclasse" = "subclasse")) %>%
  filter(!is.na(mes_admissao), mes_admissao >= 1, mes_admissao <= 12)

municipios_relevantes <- c(ids_alvo, donor_pool_ids)
secoes_validas <- sort(unique(cnae_dir$secao))
meses_painel <- seq(as.Date("2021-01-01"), as.Date("2025-12-01"), by = "month")

painel_admissoes_mensal <- vinculos_rs %>%
  filter(id_municipio %in% municipios_relevantes, !is.na(secao)) %>%
  count(id_municipio, ano, mes_admissao, secao, name = "admissoes") %>%
  rename(mes = mes_admissao) %>%
  mutate(data_ref = lubridate::make_date(ano, mes, 1)) %>%
  select(id_municipio, secao, data_ref, admissoes) %>%
  # painel balanceado: toda combinacao municipio x secao x mes precisa
  # existir, com 0 admissoes onde nao houve nenhuma (nao omitir a linha) —
  # synthdid exige uma matriz N x T completa, sem buracos. (nome da coluna de
  # data NAO pode ser `data`: colide com o parametro `data` do proprio
  # tidyr::complete(), que absorveria o argumento nomeado em vez da coluna.)
  complete(
    id_municipio = municipios_relevantes,
    secao = secoes_validas,
    data_ref = meses_painel,
    fill = list(admissoes = 0)
  ) %>%
  mutate(ano = lubridate::year(data_ref), mes = lubridate::month(data_ref)) %>%
  left_join(covs %>% select(id_municipio, PopMun), by = "id_municipio") %>%
  mutate(
    admissoes_por_mil = admissoes / PopMun * 1000,
    tratado = id_municipio %in% ids_alvo,
    no_pool_doador = id_municipio %in% donor_pool_ids
  ) %>%
  arrange(secao, id_municipio, data_ref)

message(sprintf(
  "Painel mensal de admissoes: %d linhas, %d municipios, %d secoes CNAE, %s a %s.",
  nrow(painel_admissoes_mensal),
  dplyr::n_distinct(painel_admissoes_mensal$id_municipio),
  dplyr::n_distinct(painel_admissoes_mensal$secao, na.rm = TRUE),
  format(min(painel_admissoes_mensal$data_ref)),
  format(max(painel_admissoes_mensal$data_ref))
))

saveRDS(
  painel_admissoes_mensal,
  file.path(final_dir, "painel_admissoes_mensal_secao.rds")
)

# ---- Painel anual de estoque/composicao por Secao CNAE ----------------------
estabelecimentos_rs <- readRDS(
  file.path(raw_dir, "rais_estabelecimentos_rs_2021_2025.rds")
) %>%
  # `ano` chega como bit64::integer64 (tipo INT64 do BigQuery) -- converter
  # para integer aqui evita corrupcao silenciosa a jusante (ex: ggplot2 nao
  # sabe plotar integer64 e produz eixo com valores lixo, sem erro visivel).
  mutate(ano = as.integer(ano)) %>%
  left_join(cnae_dir, by = c("cnae_2_subclasse" = "subclasse"))
  # NAO filtrar por indicador_atividade_ano == 1: o codigo usado para
  # "estabelecimento ativo" NAO e estavel entre anos -- em 2022 a BD/RAIS
  # codificou quase todos os estabelecimentos ativos como "9" em vez de "1"
  # (confirmado via `basedosdados.br_me_rais.microdados_estabelecimentos`:
  # 2022 tem 529611 linhas com indicador=9 e media de vinculos ~5, identico
  # ao padrao de "indicador=1" nos demais anos). Filtrar por == 1 sozinho
  # zerava quase toda a base de 2022. Estabelecimentos genuinamente inativos
  # (indicador=0) ja tem quantidade_vinculos_ativos=0 em todos os anos, entao
  # somar sem filtrar da o mesmo resultado correto sem depender do codigo.

painel_estoque_anual <- estabelecimentos_rs %>%
  filter(id_municipio %in% municipios_relevantes, !is.na(secao)) %>%
  group_by(id_municipio, ano, secao) %>%
  summarise(
    vinculos_ativos = sum(quantidade_vinculos_ativos, na.rm = TRUE),
    n_estabelecimentos = n(),
    .groups = "drop"
  ) %>%
  complete(
    id_municipio = municipios_relevantes,
    secao = secoes_validas,
    ano = 2021:2025,
    fill = list(vinculos_ativos = 0, n_estabelecimentos = 0)
  ) %>%
  left_join(covs %>% select(id_municipio, PopMun), by = "id_municipio") %>%
  mutate(
    vinculos_por_mil = vinculos_ativos / PopMun * 1000,
    tratado = id_municipio %in% ids_alvo,
    no_pool_doador = id_municipio %in% donor_pool_ids
  ) %>%
  arrange(secao, id_municipio, ano)

message(sprintf(
  "Painel anual de estoque: %d linhas, %d municipios, %d secoes CNAE, anos %s.",
  nrow(painel_estoque_anual),
  dplyr::n_distinct(painel_estoque_anual$id_municipio),
  dplyr::n_distinct(painel_estoque_anual$secao, na.rm = TRUE),
  paste(sort(unique(painel_estoque_anual$ano)), collapse = ", ")
))

saveRDS(
  painel_estoque_anual,
  file.path(final_dir, "painel_estoque_anual_secao.rds")
)

# ---- Checagem de sanidade: cobertura das secoes por municipio-alvo ---------
cobertura_alvo <- painel_admissoes_mensal %>%
  filter(tratado) %>%
  group_by(id_municipio, secao) %>%
  summarise(total_admissoes = sum(admissoes), .groups = "drop") %>%
  filter(total_admissoes > 0)

message(sprintf(
  "Secoes com pelo menos 1 admissao em algum municipio-alvo: %d combinacoes municipio x secao.",
  nrow(cobertura_alvo)
))
saveRDS(cobertura_alvo, file.path(final_dir, "cobertura_secoes_alvo.rds"))
