# =============================================================================
# 07_sdid_por_setor.R — Roda Synthetic DiD (pacote `synthdid`) por Seção CNAE,
# para cada município-alvo, no painel mensal de admissões (proxy setorial do
# "admissoes_por_mil" do artigo original, agora quebrado por setor).
#
# Nota de proveniência: a lógica de donor pool (proporcao_atingidos <= 0.005,
# mesmos ids_alvo, mesma data de tratamento) replica exatamente
# Artigos/SDID/Scripts/extrair_pool_doador.R e o `main.tex` do artigo
# original. A camada de INFERÊNCIA (permutação, vcov placebo, leave-one-out)
# foi reimplementada aqui em cima das primitivas do próprio pacote `synthdid`
# — não é uma cópia linha-a-linha de sdid_enchentes_2024_v5.R (que só foi
# lido via resumo, não código-fonte completo). Reconciliar com os números
# publicados no artigo é um objetivo de robustez, não uma garantia de match
# exato (fonte de dado também é diferente: RAIS vs CAGED).
#
# Filtro de N mínimo (decisão do usuário): só roda SDID em combinações
# município-alvo x Seção com >= N_MIN admissões totais 2021-2025. Abaixo
# disso, a célula é reportada só descritivamente (ver 08_tabelas.R).
#
# Nota de performance: os dados sao pre-filtrados por Secao UMA VEZ por
# celula (nao a cada iteracao de permutacao/LOO) e a coluna de tratamento e
# atribuida vetorialmente em data.frame base — filtrar os ~250 mil registros
# do painel completo a cada uma das ~386 reestimacoes por celula (~57
# celulas) tornava o script impraticavel (>> 1h). Ver
# quality_reports/session_logs/ para o registro dessa correcao.
# =============================================================================

library(dplyr)
library(synthdid)

final_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Final")
resultados_dir <- here::here("Artigos", "SDID_RAIS", "Resultados")
dir.create(resultados_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20260824L)

N_MIN <- 50L
DATA_TRATAMENTO <- as.Date("2024-05-01")

ids_alvo <- c("4306767", "4312609", "4315800", "4300851", "4321626", "4310108")
nomes_alvo <- c(
  "4306767" = "Eldorado do Sul", "4312609" = "Mucum", "4315800" = "Roca Sales",
  "4300851" = "Arambare", "4321626" = "Travesseiro", "4310108" = "Igrejinha"
)

painel <- readRDS(file.path(final_dir, "painel_admissoes_mensal_secao.rds"))
donor_pool_ids <- painel %>% filter(no_pool_doador) %>% pull(id_municipio) %>% unique()

cnae_dir <- readRDS(here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw", "cnae_diretorio_secao.rds")) %>%
  distinct(secao, descricao_secao)

painel_df <- as.data.frame(painel[, c("id_municipio", "secao", "data_ref", "admissoes_por_mil")])

# ---- Celulas elegiveis (>= N_MIN admissoes totais no periodo) --------------
cobertura <- painel %>%
  filter(tratado) %>%
  group_by(id_municipio, secao) %>%
  summarise(total_admissoes = sum(admissoes), .groups = "drop") %>%
  filter(total_admissoes >= N_MIN)

message(sprintf(
  "%d combinacoes municipio-alvo x secao elegiveis (>= %d admissoes totais).",
  nrow(cobertura), N_MIN
))

# Pre-divide o painel por secao uma unica vez (evita refiltrar 250k linhas
# a cada celula/permutacao).
painel_por_secao <- split(painel_df, painel_df$secao)

estimar <- function(df) {
  setup <- panel.matrices(
    df, unit = "id_municipio", time = "data_ref",
    outcome = "admissoes_por_mil", treatment = "tratamento"
  )
  list(
    tau = tryCatch(synthdid_estimate(setup$Y, setup$N0, setup$T0), error = function(e) NULL),
    setup = setup
  )
}

# ---- Funcao: roda SDID para uma celula (municipio-alvo, secao) -------------
rodar_sdid_celula <- function(municipio_id, secao_id) {
  df_secao <- painel_por_secao[[secao_id]]

  # ---- Estimacao real: municipio-alvo + pool doador completo ----------------
  df_real <- df_secao[df_secao$id_municipio %in% c(municipio_id, donor_pool_ids), ]
  df_real$tratamento <- as.integer(
    df_real$id_municipio == municipio_id & df_real$data_ref >= DATA_TRATAMENTO
  )

  fit_real <- estimar(df_real)
  if (is.null(fit_real$tau)) stop("Falha na estimacao real (synthdid_estimate).")
  tau_hat <- fit_real$tau
  att <- as.numeric(tau_hat)

  curva <- tryCatch(synthdid_effect_curve(tau_hat), error = function(e) NA)

  # ---- Permutacao direta: cada doador j vira "tratado" ----------------------
  # NAO usamos vcov(tau_hat, method="placebo") do pacote: internamente ele
  # roda sua propria reamostragem sobre o pool de doadores (~197s medidos em
  # teste, contra ~1.7s por reestimacao manual) e e redundante com a
  # permutacao direta feita abaixo, que ja fornece p-valor exato e um IC por
  # quantil recentrado (mesma logica de inferencia do artigo original).
  # Base fixa = so os doadores (mesma para todo j); so a coluna `tratamento`
  # muda a cada iteracao — sem refiltrar o data.frame.
  df_doadores <- df_secao[df_secao$id_municipio %in% donor_pool_ids, ]

  tau_placebo <- vapply(donor_pool_ids, function(j) {
    df_j <- df_doadores
    df_j$tratamento <- as.integer(df_j$id_municipio == j & df_j$data_ref >= DATA_TRATAMENTO)
    fit <- tryCatch(estimar(df_j), error = function(e) list(tau = NULL))
    if (is.null(fit$tau)) NA_real_ else as.numeric(fit$tau)
  }, numeric(1))

  tau_placebo <- tau_placebo[!is.na(tau_placebo)]
  p_permutacao <- if (length(tau_placebo) > 0) mean(abs(tau_placebo) >= abs(att)) else NA_real_

  # IC por quantil recentrado na distribuicao de permutacao (mesma logica do
  # artigo original): desloca os quantis da distribuicao placebo (centrada em
  # sua propria mediana) para em torno do ATT observado.
  ic_perm <- if (length(tau_placebo) >= 10) {
    desvio <- quantile(tau_placebo - stats::median(tau_placebo), c(0.025, 0.975))
    att + desvio
  } else {
    c(NA_real_, NA_real_)
  }
  se_perm <- if (length(tau_placebo) > 0) stats::sd(tau_placebo) else NA_real_

  # ---- Leave-one-out: remove um doador por vez da estimacao real ------------
  loo_ests <- vapply(donor_pool_ids, function(j) {
    df_loo <- df_real[df_real$id_municipio != j, ]
    fit <- tryCatch(estimar(df_loo), error = function(e) list(tau = NULL))
    if (is.null(fit$tau)) NA_real_ else as.numeric(fit$tau)
  }, numeric(1))
  loo_ests <- loo_ests[!is.na(loo_ests)]

  list(
    resumo = tibble(
      id_municipio = municipio_id,
      municipio = nomes_alvo[[municipio_id]],
      secao = secao_id,
      att = att,
      se_permutacao = se_perm,
      ci_perm_low = unname(ic_perm[1]),
      ci_perm_high = unname(ic_perm[2]),
      n_permutacoes = length(tau_placebo),
      p_permutacao = p_permutacao,
      n_donors = fit_real$setup$N0,
      n_pre = fit_real$setup$T0,
      n_post = ncol(fit_real$setup$Y) - fit_real$setup$T0,
      loo_min = if (length(loo_ests) > 0) min(loo_ests) else NA_real_,
      loo_max = if (length(loo_ests) > 0) max(loo_ests) else NA_real_
    ),
    tau_hat = tau_hat,
    curva_efeito = curva,
    tau_placebo = tau_placebo,
    loo_ests = loo_ests
  )
}

# ---- Roda para todas as celulas elegiveis (paralelo entre celulas) --------
# Cada celula = ~1 + 193 (permutacao) + 193 (LOO) reestimacoes synthdid,
# ~1.7s cada (medido) => ~11 min/celula em serie. Com 57 celulas isso e
# ~10h em serie — paralelizamos entre celulas (cada uma independente) num
# cluster PSOCK (funciona em Windows, ao contrario de mclapply).
n_cores <- max(1L, parallel::detectCores() - 1L)
message(sprintf("Rodando %d celulas em paralelo (%d cores)...", nrow(cobertura), n_cores))

cl <- parallel::makeCluster(n_cores)
on.exit(parallel::stopCluster(cl), add = TRUE)

parallel::clusterEvalQ(cl, { library(synthdid); library(tibble) })
parallel::clusterExport(cl, c(
  "painel_por_secao", "donor_pool_ids", "nomes_alvo", "DATA_TRATAMENTO",
  "estimar", "rodar_sdid_celula"
))

t0_total <- Sys.time()
resultados <- parallel::clusterMap(
  cl,
  function(mun, sec) {
    tryCatch(
      rodar_sdid_celula(mun, sec),
      error = function(e) {
        list(erro = sprintf("[%s x %s]: %s", mun, sec, conditionMessage(e)))
      }
    )
  },
  cobertura$id_municipio, cobertura$secao,
  SIMPLIFY = FALSE
)
message(sprintf(
  "Tempo total: %.1f min", as.numeric(Sys.time() - t0_total, units = "mins")
))

erros <- Filter(function(x) !is.null(x$erro), resultados)
if (length(erros) > 0) {
  message(sprintf("%d celulas com erro:", length(erros)))
  for (e in erros) message("  ", e$erro)
}

resultados <- Filter(function(x) is.null(x$erro), resultados)

tabela_resultados <- bind_rows(lapply(resultados, `[[`, "resumo")) %>%
  left_join(cnae_dir, by = "secao") %>%
  relocate(descricao_secao, .after = secao) %>%
  arrange(municipio, desc(abs(att)))

print(tabela_resultados, n = Inf)

saveRDS(resultados, file.path(resultados_dir, "sdid_por_setor_resultados_completos.rds"))
saveRDS(tabela_resultados, file.path(resultados_dir, "sdid_por_setor_tabela.rds"))

message("Resultados salvos em: ", resultados_dir)
