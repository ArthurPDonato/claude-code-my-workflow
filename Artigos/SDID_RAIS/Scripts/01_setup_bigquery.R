# =============================================================================
# 01_setup_bigquery.R — Valida acesso à Base dos Dados via BigQuery.
#
# Pré-requisitos (feitos manualmente pelo usuário, uma vez, fora do R):
#   1. Criar um projeto no Google Cloud Console (console.cloud.google.com).
#   2. Ativar a API do BigQuery nesse projeto.
#   3. Ativar billing (BigQuery dá 1 TB/mês de processamento gratuito por
#      projeto; para os volumes deste projeto isso deve bastar, mas confirmar
#      na Fase 1 antes de rodar os downloads completos).
#   4. Definir o ID do projeto em BILLING_PROJECT_ID (variável de ambiente
#      abaixo, ou diretamente na chamada de set_billing_id()).
#
# Na primeira execução, basedosdados/bigrquery abre uma janela do navegador
# para autenticar com sua conta Google — rode este script interativamente
# (RStudio ou console R), não via execução não-interativa, na primeira vez.
# =============================================================================

library(basedosdados)

billing_project_id <- Sys.getenv("BILLING_PROJECT_ID", unset = NA)

if (is.na(billing_project_id) || billing_project_id == "") {
  stop(
    "Defina a variável de ambiente BILLING_PROJECT_ID com o ID do seu ",
    "projeto Google Cloud (ex: Sys.setenv(BILLING_PROJECT_ID = 'meu-projeto-123') ",
    "antes de rodar este script, ou crie um .Renviron com essa linha)."
  )
}

set_billing_id(billing_project_id)

message("Testando conexão com a Base dos Dados (query trivial)...")

teste <- read_sql(
  "SELECT id_municipio, nome AS municipio
   FROM `basedosdados.br_bd_diretorios_brasil.municipio`
   WHERE sigla_uf = 'RS'
   LIMIT 5"
)

print(teste)

message(
  "Conexao OK: ", nrow(teste), " linhas retornadas. ",
  "Billing project: ", billing_project_id
)
