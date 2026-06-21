# ============================================================
#  SYNTHETIC DIFFERENCE-IN-DIFFERENCES
#  Impacto das Enchentes de 2024 (RS) sobre ADMISSÕES EM
#  EMPREGOS FORMAIS
#  Tratados (6): Eldorado do Sul, Muçum, Roca Sales,
#                Arambaré, Travesseiro, Igrejinha
#
#  VERSÃO 5 — mudanças sobre a v4:
#   (1) DOIS MODOS DE POOL coexistindo no mesmo script:
#         - "pareado"  : nossa filtragem (N_DOADORES por matching mahalanobis)
#         - "completo" : pool cheio (todos os controles limpos), como no PDF
#       Basta MODOS_DOADORES <- c("pareado","completo") (rode um ou ambos).
#   (2) PERMUTAÇÃO DIRETA (Abadie/Arkhangelsky) como inferência principal:
#       p bilateral e unilateral EXATOS + IC95% por quantis empíricos
#       recentrados. Reportada LADO A LADO com o EP placebo gaussiano (v4).
#       No modo "completo" a permutação usa o universo de doadores e
#       coincide com o placebo espacial do PDF; no "pareado" ela permuta
#       entre os doadores pareados (null mais estreito → p mais granular),
#       e o placebo espacial de universo amplo (re-pareado) é mantido.
#   (3) Comparação automática PAREADO × COMPLETO × PDF para Eldorado do Sul
#       e Roca Sales (tabela + forest), reproduzindo o cara a cara discutido.
#   (4) Mantém: efeito absoluto por conversão, tabela consolidada, forest
#       por severidade, flag de RMSPE alto, robustez por tratado.
#   (5) TRIANGULAÇÃO INTEGRADA: DiD e SC estimados DENTRO do loop, SÓ no
#       modo "completo", reaproveitando a matriz Y já montada pelo SDID
#       (est$setup$Y) — nenhum SDID é reestimado. Flags RODAR_TRIANGULACAO
#       e RODAR_PERM_SC (permutação direta também para o SC). Gera tabela,
#       convergência e forest de DiD/SC/SDID na pasta do modo completo.
#   (6) HETEROGENEIDADE INTEGRADA (seções 9 e 10): seção 9 = covariáveis
#       estruturais (com guarda de cobertura); seção 10 = dano físico MUPRS
#       (CNPJ, malha viária, índice produtivo). Ambas DESCRITIVAS (n=6, sem
#       inferência) e reaproveitando os resultados já em memória.
#
#  NOTA DE RUNTIME: modo "completo" roda a permutação direta e o LOO sobre
#  ~193 doadores por tratado; é mais pesado. Use RODAR_ROBUSTEZ_PESADA para
#  desligar LOO/placebo-temporal se quiser só os pontos + permutação.
# ============================================================

# ------------------------------------------------------------
# 0. PACOTES
# ------------------------------------------------------------
library(tidyverse)
library(readxl)
library(synthdid)
library(MatchIt)
library(cobalt)
if (!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")
library(writexl)

# ------------------------------------------------------------
# 1. PARÂMETROS GERAIS
# ------------------------------------------------------------
MODOS_DOADORES      <- c("pareado", "completo")   # rode um ou ambos
RODAR_ROBUSTEZ_PESADA <- TRUE                      # LOO + placebo temporal por tratado
RODAR_PLACEBO_ESPACO_UNIVERSO <- TRUE             # placebo espacial re-pareado (universo amplo)
RODAR_TRIANGULACAO  <- TRUE                        # DiD + SC (SÓ no modo "completo"), reusando o Y do SDID
RODAR_PERM_SC       <- TRUE                        # permutação direta também p/ o SC (mais rigoroso; +~193 fits/trat.)

N_DOADORES          <- 20L
LIMIAR_BASELINE     <- 0.005
LIMIARES_SENSIB     <- c(0.001, 0.005, 0.01)
periodo_intervencao <- 2024L * 12L + 5L           # maio/2024
LIMPAR_PASTA        <- TRUE

NOMES_TRATADOS <- c("Eldorado do Sul", "Muçum", "Roca Sales",
                    "Arambaré", "Travesseiro", "Igrejinha")

DATAS_PLACEBO_TEMPO <- (2022L*12L + 1L):(2023L*12L + 12L)  # jan/2022..dez/2023
MIN_PRE_PLACEBO     <- 6L
MIN_POS_PLACEBO     <- 3L
N_PLACEBO_ESPACO    <- 100L

# Valores de referência do PDF (Relatório Técnico) p/ comparação automática.
# Pool cheio (N0=193), permutação direta. PopMun do PDF difere da nossa base
# (ES 42.490 vs 40.954; RS 11.556 vs 10.644) — ver nota de reconciliação no fim.
ref_pdf <- tribble(
  ~id_municipio, ~municipio_nome,   ~att_pdf, ~ep_pdf, ~ic_inf_pdf, ~ic_sup_pdf, ~p_bi_pdf, ~p_uni_pdf, ~pop_pdf,
  4306767,       "Eldorado do Sul", -3.720,   1.825,   -7.30,       -0.14,       0.042,     0.021,      42490,
  4315800,       "Roca Sales",      -3.724,   1.763,   -7.18,       -0.27,       0.036,     0.021,      11556
)

dir_base <- "G:/Meu Drive/Arthur Facul/Avaliação dos Impactos dos Eventos Climáticos Extremos no RS Sobre Variáveis Socioeconômicas/Resultados/SDID"

# ------------------------------------------------------------
# 2. LEITURA DAS BASES
# ------------------------------------------------------------
path_cov  <- "G:/Meu Drive/Arthur Facul/Avaliação dos Impactos dos Eventos Climáticos Extremos no RS Sobre Variáveis Socioeconômicas/Base de dados/Controles SDID/Utilizados SDID/Covariaveis_SDID_Final.xlsx"
path_main <- "G:/Meu Drive/Arthur Facul/Avaliação dos Impactos dos Eventos Climáticos Extremos no RS Sobre Variáveis Socioeconômicas/Base de dados/Controles SDID/Utilizados SDID/BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx"
# Base MUPRS de atingidos (usada na seção 10 — heterogeneidade de dano físico)
path_muprs <- "G:/Meu Drive/Arthur Facul/Avaliação dos Impactos dos Eventos Climáticos Extremos no RS Sobre Variáveis Socioeconômicas/Base de dados/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"

df_cov  <- read_excel(path_cov)
df_main <- read_excel(path_main) %>%
  select(data, municipio_nome, id_municipio, admissoes_por_mil)

# ------------------------------------------------------------
# 3. TRATADOS E TABELAS AUXILIARES
# ------------------------------------------------------------
resolver_id <- function(nome) {
  df_main %>%
    filter(str_detect(municipio_nome, regex(nome, ignore_case = TRUE))) %>%
    pull(id_municipio) %>% unique()
}
ids_por_nome <- set_names(map(NOMES_TRATADOS, resolver_id), NOMES_TRATADOS)
walk2(names(ids_por_nome), ids_por_nome, function(nm, ids) {
  if (length(ids) == 0)      warning(sprintf(">> ATENCAO: nenhum municipio para '%s'.", nm))
  else if (length(ids) > 1)  warning(sprintf(">> ATENCAO: '%s' casou com %d municipios (%s).", nm, length(ids), paste(ids, collapse=", ")))
})
ids_tratados <- ids_por_nome %>% unlist(use.names = FALSE) %>% unique()
cat(">> Tratados resolvidos:", length(ids_tratados), "| ids:", paste(ids_tratados, collapse = ", "), "\n")

df_pop   <- df_cov  %>% select(id_municipio, PopMun) %>% distinct()
df_nomes <- df_main %>% select(id_municipio, municipio_nome) %>% distinct()
df_sev   <- df_cov  %>% select(id_municipio, proporcao_atingidos) %>% distinct()

# CORREÇÃO: as proporções de atingidos de Arambaré e Travesseiro não foram
# incluídas na base final (quando os alvos primários eram só ES e RS). Fonte:
# planilha MUPRS (Pop_Atingidos / Pop_Total). Os 6 alvos têm >50% atingidos.
# Não afeta estimação (alvos são excluídos do pool por id), só severidade.
proporcoes_corrigidas <- tribble(
  ~id_municipio, ~prop_corr,
  4306767, 0.8218,   # Eldorado do Sul
  4312609, 0.7907,   # Muçum
  4315800, 0.5452,   # Roca Sales
  4300851, 0.5190,   # Arambaré (estava NA)
  4321626, 0.5102,   # Travesseiro (estava NA)
  4310108, 0.5085    # Igrejinha
)
df_sev <- df_sev %>%
  left_join(proporcoes_corrigidas, by = "id_municipio") %>%
  mutate(proporcao_atingidos = coalesce(prop_corr, proporcao_atingidos)) %>%
  select(id_municipio, proporcao_atingidos)

# ------------------------------------------------------------
# 4. COVARIÁVEIS (NÍVEL) — usadas SÓ no pareamento (são estáticas)
#    PopMun NÃO entra: o desfecho já é per capita (admissoes_por_mil).
#    (No modo "completo" as covariáveis não são usadas: o pool é todo o
#     conjunto de controles limpos, como no PDF.)
# ------------------------------------------------------------
cov_vars_nivel <- c(
  "pib_per_capita_medio", "share_agro_medio", "share_ind_medio",
  "share_serv_medio", "share_adm_medio", "Idese 2021", #"PopMun",
  "salario_medio_agregado", "operacoes_credito_medio", "total_ativo_medio"
)
df_cov <- df_cov %>%
  mutate(across(all_of(cov_vars_nivel), ~ as.numeric(str_replace_all(as.character(.), ",", "."))))

# ============================================================
# 5. FUNÇÕES AUXILIARES
# ============================================================
num_para_data_texto <- function(valores_numericos) {
  rotulos <- rep(NA_character_, length(valores_numericos))
  validos <- which(!is.na(valores_numericos))
  if (length(validos) > 0) {
    val_int <- floor(as.numeric(valores_numericos[validos]))
    anos  <- floor((val_int - 1) / 12); meses <- ((val_int - 1) %% 12) + 1
    datas <- suppressWarnings(as.Date(paste(anos, sprintf("%02d", meses), "01", sep = "-")))
    rotulos[validos] <- format(datas, "%b/%Y")
  }
  ifelse(is.na(rotulos), "", rotulos)
}

limpar_pasta <- function(dir, executar = FALSE) {
  if (!executar) return(invisible())
  arquivos <- list.files(dir, pattern = "\\.(png|csv|xlsx)$", full.names = TRUE)
  if (length(arquivos)) file.remove(arquivos)
  cat(">> Pasta limpa:", length(arquivos), "arquivo(s).\n")
}

# --- Seleção de doadores: PAREADO (matching) ---------------------------------
selecionar_controles <- function(df_cov, vars, ids_alvo, ids_tratados_todos, limiar,
                                 n_doadores, verbose = FALSE) {
  df_cand <- df_cov %>%
    filter((proporcao_atingidos <= limiar & !(id_municipio %in% ids_tratados_todos)) |
             id_municipio %in% ids_alvo) %>%
    select(id_municipio, all_of(vars)) %>%
    mutate(tratado = as.integer(id_municipio %in% ids_alvo))
  linhas_tratados <- df_cand %>% filter(tratado == 1L)
  if (nrow(linhas_tratados) == 0)
    stop(sprintf("Tratado(s) [%s] ausente(s) nas covariáveis.", paste(ids_alvo, collapse = ", ")))
  vars_uso <- vars[map_lgl(vars, ~ all(!is.na(linhas_tratados[[.x]])))]
  if (length(vars_uso) == 0) stop("Nenhuma covariável disponível para o(s) tratado(s).")
  if (verbose && length(setdiff(vars, vars_uso)) > 0)
    cat(sprintf("   [pareamento] %d covariável(is) descartada(s) por NA: %s\n",
                length(setdiff(vars, vars_uso)), paste(setdiff(vars, vars_uso), collapse = ", ")))
  df_match <- df_cand %>% select(id_municipio, tratado, all_of(vars_uso)) %>% drop_na()
  n_disp <- sum(df_match$tratado == 0); n_alvo <- max(1L, length(ids_alvo))
  ratio_efetivo <- min(n_doadores, n_disp %/% n_alvo)
  if (ratio_efetivo < 1) stop("Sem controles suficientes.")
  if (ratio_efetivo < n_doadores)
    warning(sprintf("Limiar %.3f: %d controles p/ %d tratado(s). ratio = %d.", limiar, n_disp, n_alvo, ratio_efetivo))
  formula_match <- as.formula(paste("tratado ~", paste(sprintf("`%s`", vars_uso), collapse = " + ")))
  set.seed(42)
  match_out <- matchit(formula_match, data = df_match, method = "nearest",
                       distance = "mahalanobis", ratio = ratio_efetivo, replace = FALSE)
  setdiff(match.data(match_out) %>% pull(id_municipio) %>% unique(), ids_alvo)
}

# --- Seleção de doadores: COMPLETO (pool cheio, como no PDF) ------------------
selecionar_controles_completo <- function(df_cov, ids_alvo, ids_tratados_todos, limiar) {
  ids <- df_cov %>%
    filter(proporcao_atingidos <= limiar & !(id_municipio %in% ids_tratados_todos)) %>%
    pull(id_municipio) %>% unique()
  intersect(ids, unique(df_main$id_municipio))
}

# --- Dispatcher por modo -----------------------------------------------------
obter_doadores <- function(modo, ids_alvo, verbose = FALSE) {
  if (modo == "pareado")
    selecionar_controles(df_cov, cov_vars_nivel, ids_alvo, ids_tratados, LIMIAR_BASELINE, N_DOADORES, verbose = verbose)
  else if (modo == "completo")
    selecionar_controles_completo(df_cov, ids_alvo, ids_tratados, LIMIAR_BASELINE)
  else stop("modo deve ser 'pareado' ou 'completo'.")
}

montar_painel <- function(df_fonte, ids_modelo) {
  dfp <- df_fonte %>%
    filter(id_municipio %in% ids_modelo) %>%
    mutate(periodo = as.integer(format(as.Date(data), "%Y")) * 12L +
             as.integer(format(as.Date(data), "%m"))) %>%
    select(id_municipio, periodo, admissoes_por_mil) %>% drop_na()
  periodos_comuns <- dfp %>% group_by(periodo) %>%
    summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
    filter(n == n_distinct(dfp$id_municipio)) %>% pull(periodo)
  dfp %>% filter(periodo %in% periodos_comuns)
}

calcular_rmspe_pre <- function(tau_hat, setup) {
  w <- attr(tau_hat, "weights"); omega <- w$omega; lambda <- w$lambda
  N0 <- setup$N0; T0 <- setup$T0; Y <- setup$Y
  serie_tr <- colMeans(Y[(N0 + 1):nrow(Y), , drop = FALSE])
  serie_sc <- as.numeric(t(omega) %*% Y[1:N0, , drop = FALSE])
  gap_pre  <- (serie_tr - serie_sc)[1:T0]; offset <- sum(lambda * gap_pre)
  list(rmspe_pre = sqrt(mean((gap_pre - offset)^2)), gap_nivel_pre = mean(gap_pre))
}

estimar_sdid <- function(df_panel, ids_alvo, periodo_intervencao) {
  df_setup <- df_panel %>%
    rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>%
    as.data.frame()
  setup   <- panel.matrices(df_setup, "unit", "time", "outcome", "treated")
  tau_hat <- synthdid_estimate(setup$Y, setup$N0, setup$T0)
  att <- as.numeric(tau_hat); se <- as.numeric(sqrt(vcov(tau_hat, method = "placebo")))
  fit <- calcular_rmspe_pre(tau_hat, setup)
  list(tau_hat = tau_hat, setup = setup, att = att, se = se,
       ic_inf = att - 1.96*se, ic_sup = att + 1.96*se,
       rmspe_pre = fit$rmspe_pre, gap_nivel_pre = fit$gap_nivel_pre,
       n0 = setup$N0, t0 = setup$T0, t1 = ncol(setup$Y) - setup$T0)
}

att_sdid_rapido <- function(df_panel, ids_alvo, periodo_intervencao, data_corte = periodo_intervencao) {
  df <- df_panel %>%
    rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= data_corte)) %>% as.data.frame()
  s <- panel.matrices(df, "unit", "time", "outcome", "treated")
  as.numeric(synthdid_estimate(s$Y, s$N0, s$T0))
}

# --- PERMUTAÇÃO DIRETA (inferência principal, à la PDF) -----------------------
# Para cada doador j do painel: j vira "tratado placebo", o tratado real é
# deslocado para o pool de controles, e o SDID é reestimado por completo
# (reotimizando ω e λ). Gera p exato e IC por quantis empíricos recentrados.
permutacao_direta <- function(df_panel, id_trat, periodo_intervencao, ids_doadores) {
  att_real <- att_sdid_rapido(df_panel, id_trat, periodo_intervencao)
  taus <- map_dbl(ids_doadores, function(j)
    tryCatch(att_sdid_rapido(df_panel, j, periodo_intervencao), error = function(e) NA_real_))
  taus <- taus[!is.na(taus)]
  med  <- median(taus)
  q    <- as.numeric(quantile(taus - med, c(0.025, 0.975), names = FALSE))
  list(
    att = att_real, taus = taus, n_placebos = length(taus),
    sd_emp = sd(taus), mediana = med,
    p_bilateral  = mean(abs(taus) >= abs(att_real)),   # = (1/N0) Σ 1[|τj|≥|τreal|]
    p_unilateral = mean(taus <= att_real),             # H1: τ < 0
    ic_inf = att_real + q[1], ic_sup = att_real + q[2],
    z = att_real / sd(taus))
}

# --- PERMUTAÇÃO DIRETA SOBRE A MATRIZ Y (reordenação matricial) ---------------
# Usada na triangulação (SC/SDID) reaproveitando o Y já montado pelo SDID, sem
# remontar painel. Cada controle j vira "tratado"; o tratado real (última linha)
# vira doador. 'estimador' é did_estimate / sc_estimate / synthdid_estimate.
permutar_matriz <- function(Y, N0, T0, estimador) {
  tau_real <- as.numeric(estimador(Y, N0, T0))
  n_total  <- nrow(Y)
  taus <- map_dbl(seq_len(N0), function(j) {
    Y_perm <- Y[c(setdiff(seq_len(N0), j), n_total, j), ]
    tryCatch(as.numeric(estimador(Y_perm, N0, T0)), error = function(e) NA_real_)
  })
  taus <- taus[!is.na(taus)]
  med  <- median(taus)
  q    <- as.numeric(quantile(taus - med, c(0.025, 0.975), names = FALSE))
  list(att = tau_real, n = length(taus), sd_emp = sd(taus),
       p_bilateral = mean(abs(taus) >= abs(tau_real)),
       p_unilateral = mean(taus <= tau_real),
       ic_inf = tau_real + q[1], ic_sup = tau_real + q[2])
}

banda_acum_placebo <- function(df_panel, idc, periodo_intervencao, n_pos) {
  curvas <- map(idc, function(i) {
    df_i <- df_panel %>% filter(id_municipio %in% idc) %>%
      rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
      mutate(treated = as.integer(unit == i & time >= periodo_intervencao)) %>% as.data.frame()
    s <- tryCatch(panel.matrices(df_i, "unit", "time", "outcome", "treated"), error = function(e) NULL)
    if (is.null(s)) return(NULL)
    tryCatch(cumsum(as.numeric(synthdid_effect_curve(synthdid_estimate(s$Y, s$N0, s$T0)))),
             error = function(e) NULL)
  })
  curvas <- curvas[!map_lgl(curvas, is.null)]
  if (length(curvas) < 2) return(rep(NA_real_, n_pos))
  L <- min(n_pos, min(map_int(curvas, length)))
  M <- do.call(rbind, lapply(curvas, function(v) v[1:L]))
  c(apply(M, 2, sd), rep(NA_real_, n_pos - L))
}

# ============================================================
# 5b. PLACEBO ESPACIAL DE UNIVERSO AMPLO (re-pareado) — calculado UMA vez.
#     Independe do modo, pois cada pseudo-tratado é re-pareado. Serve de
#     null espacial robusto sobretudo para o modo "pareado".
# ============================================================
placebos_espaco_uni <- numeric(0)
if (RODAR_PLACEBO_ESPACO_UNIVERSO) {
  cat("\n=== PLACEBO ESPACIAL (universo amplo, re-pareado) — cálculo único ===\n")
  universo_limpos <- df_cov %>%
    filter(proporcao_atingidos <= LIMIAR_BASELINE & !(id_municipio %in% ids_tratados)) %>%
    pull(id_municipio) %>% unique()
  universo_limpos <- intersect(universo_limpos, unique(df_main$id_municipio))
  set.seed(123)
  amostra_espaco <- if (length(universo_limpos) > N_PLACEBO_ESPACO) sample(universo_limpos, N_PLACEBO_ESPACO) else universo_limpos
  cat("  Universo limpo:", length(universo_limpos), "| pseudo-tratados:", length(amostra_espaco), "\n")
  placebos_espaco_uni <- map_dbl(amostra_espaco, function(j) {
    ids_c_j <- tryCatch(suppressWarnings(selecionar_controles(df_cov, cov_vars_nivel, j, ids_tratados, LIMIAR_BASELINE, N_DOADORES)), error = function(e) NULL)
    if (is.null(ids_c_j) || length(ids_c_j) < 2) return(NA_real_)
    tryCatch(att_sdid_rapido(montar_painel(df_main, c(j, ids_c_j)), j, periodo_intervencao), error = function(e) NA_real_)
  })
  placebos_espaco_uni <- placebos_espaco_uni[!is.na(placebos_espaco_uni)]
}

# ============================================================
# 6. FUNÇÃO PRINCIPAL: ANÁLISE COMPLETA PARA UM MODO DE POOL
# ============================================================
analisar_modo <- function(modo) {
  cat("\n\n##############################################################\n")
  cat("#  MODO DE POOL:", toupper(modo), "\n")
  cat("##############################################################\n")
  dir_saida <- file.path(dir_base, paste0("SDID ", modo,
                                          if (modo == "pareado") paste0(" ", N_DOADORES, " doadores covariaveis") else " pool completo",
                                          " 6 municipios"))
  if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)
  limpar_pasta(dir_saida, executar = LIMPAR_PASTA)
  
  modelos <- list(); lista_resumo <- list(); lista_tempo <- list(); lista_robustez <- list()
  
  for (id_trat in ids_tratados) {
    nome_tratado <- (df_nomes %>% filter(id_municipio == id_trat) %>% pull(municipio_nome) %>% unique())[1]
    if (is.na(nome_tratado)) nome_tratado <- as.character(id_trat)
    pop_tratado <- (df_pop %>% filter(id_municipio == id_trat) %>% pull(PopMun) %>% unique())[1]
    cat("\n=== [", modo, "] ", nome_tratado, "(", id_trat, ") ===\n")
    
    ids_controle <- obter_doadores(modo, ids_alvo = id_trat, verbose = TRUE)
    df_panel <- montar_painel(df_main, c(id_trat, ids_controle))
    est <- estimar_sdid(df_panel, ids_alvo = id_trat, periodo_intervencao)
    
    # --- PERMUTAÇÃO DIRETA (p exato + IC empírico) ---
    perm <- permutacao_direta(df_panel, id_trat, periodo_intervencao, ids_controle)
    cat(sprintf("  ATT=%.3f | EP_gauss=%.3f IC_g[%.2f;%.2f] | EP_emp=%.3f IC_perm[%.2f;%.2f] | p_bi=%.3f p_uni=%.3f | z=%.2f | RMSPE=%.2f | doad=%d\n",
                est$att, est$se, est$ic_inf, est$ic_sup, perm$sd_emp, perm$ic_inf, perm$ic_sup,
                perm$p_bilateral, perm$p_unilateral, perm$z, est$rmspe_pre, est$n0))
    
    # --- TRIANGULAÇÃO: DiD + SC (SÓ no modo completo) ---------------------
    # Reaproveita a matriz Y já montada pelo SDID (est$setup$Y): nenhum SDID é
    # reestimado. DiD com EP placebo gaussiano (referência); SC com permutação
    # direta se RODAR_PERM_SC, senão EP placebo gaussiano.
    tri <- list(att_did = NA_real_, ep_did = NA_real_, ic_inf_did = NA_real_, ic_sup_did = NA_real_,
                att_sc = NA_real_, ep_sc = NA_real_, ic_inf_sc = NA_real_, ic_sup_sc = NA_real_,
                p_bi_sc = NA_real_, p_uni_sc = NA_real_, inferencia_sc = NA_character_)
    if (modo == "completo" && RODAR_TRIANGULACAO) {
      Yt <- est$setup$Y; N0t <- est$setup$N0; T0t <- est$setup$T0
      tau_did <- did_estimate(Yt, N0t, T0t); se_did <- as.numeric(sqrt(vcov(tau_did, method = "placebo")))
      tau_sc  <- sc_estimate(Yt, N0t, T0t)
      tri$att_did <- as.numeric(tau_did); tri$ep_did <- se_did
      tri$ic_inf_did <- tri$att_did - 1.96*se_did; tri$ic_sup_did <- tri$att_did + 1.96*se_did
      if (RODAR_PERM_SC) {
        psc <- permutar_matriz(Yt, N0t, T0t, sc_estimate)
        tri$att_sc <- psc$att; tri$ep_sc <- psc$sd_emp
        tri$ic_inf_sc <- psc$ic_inf; tri$ic_sup_sc <- psc$ic_sup
        tri$p_bi_sc <- psc$p_bilateral; tri$p_uni_sc <- psc$p_unilateral
        tri$inferencia_sc <- "permutação direta"
      } else {
        se_sc <- as.numeric(sqrt(vcov(tau_sc, method = "placebo")))
        tri$att_sc <- as.numeric(tau_sc); tri$ep_sc <- se_sc
        tri$ic_inf_sc <- tri$att_sc - 1.96*se_sc; tri$ic_sup_sc <- tri$att_sc + 1.96*se_sc
        tri$inferencia_sc <- "EP placebo (gauss)"
      }
      cat(sprintf("    [tri] DiD=%.3f (EP %.2f) | SC=%.3f%s | SDID=%.3f\n",
                  tri$att_did, tri$ep_did, tri$att_sc,
                  if (RODAR_PERM_SC) sprintf(" (p_bi=%.3f)", tri$p_bi_sc) else "", est$att))
    }
    
    # --- Curva de efeito e acumulado (banda por placebo na curva) ---
    periodos_pos <- as.integer(colnames(est$setup$Y))[(est$t0 + 1):ncol(est$setup$Y)]
    n_pos <- length(periodos_pos); curva <- as.numeric(synthdid_effect_curve(est$tau_hat))
    n_curve <- min(length(curva), n_pos)
    sd_cum_permil <- banda_acum_placebo(df_panel, ids_controle, periodo_intervencao, n_pos)
    df_tempo <- tibble(
      modo = modo, id_municipio = id_trat, municipio_nome = nome_tratado, PopMun = pop_tratado,
      periodo = periodos_pos[1:n_curve], efeito_por_mil = curva[1:n_curve],
      efeito_total = efeito_por_mil * pop_tratado / 1000) %>%
      mutate(efeito_total_acumulado = cumsum(efeito_total),
             sd_acum_total = sd_cum_permil[1:n_curve] * pop_tratado / 1000,
             ic_inf_acum = efeito_total_acumulado - 1.96 * sd_acum_total,
             ic_sup_acum = efeito_total_acumulado + 1.96 * sd_acum_total)
    
    # --- Gráficos ---
    base <- paste0("municipio_", id_trat, "_", modo)
    p_traj <- plot(est$tau_hat, se.method = "placebo") +
      labs(title = NULL, subtitle = NULL, x = NULL, y = NULL) +
      scale_x_continuous(labels = num_para_data_texto) +
      theme_minimal() +
      theme(legend.position = "none")
    ggsave(file.path(dir_saida, paste0(base, "_trajetorias.png")), p_traj, width = 9, height = 6, dpi = 300)
    
    p_acum <- ggplot(df_tempo, aes(periodo, efeito_total_acumulado)) +
      geom_ribbon(aes(ymin = ic_inf_acum, ymax = ic_sup_acum), fill = "#D95F0E", alpha = 0.15) +
      geom_line(color = "#D95F0E", linewidth = 1) + geom_point(color = "#D95F0E", size = 2) +
      geom_hline(yintercept = 0, linetype = 2, color = "gray40") +
      labs(title = NULL, subtitle = NULL, x = NULL, y = NULL) +
      scale_x_continuous(labels = num_para_data_texto) + theme_minimal()
    ggsave(file.path(dir_saida, paste0(base, "_efeito_acumulado.png")), p_acum, width = 9, height = 6, dpi = 300)
    
    # Histograma da permutação direta (placebo espacial à la PDF)
    p_perm <- ggplot(tibble(val = perm$taus), aes(val)) +
      geom_histogram(fill = "gray80", bins = max(12, round(sqrt(perm$n_placebos)))) +
      geom_vline(xintercept = 0, color = "gray40", linetype = 3) +
      geom_vline(xintercept = est$att, color = "red", linetype = "dashed", linewidth = 1) +
      labs(title = NULL, subtitle = NULL, x = NULL, y = NULL) + theme_minimal()
    ggsave(file.path(dir_saida, paste0(base, "_permutacao_direta.png")), p_perm, width = 8, height = 6, dpi = 300)
    
    # --- Robustez pesada (opcional): placebo temporal + LOO ---
    p_tempo_val <- NA_real_; pt_media <- NA_real_; pt_dp <- NA_real_
    loo_min <- NA_real_; loo_max <- NA_real_
    p_espaco_uni <- NA_real_; n_ext_uni <- NA_integer_
    if (RODAR_ROBUSTEZ_PESADA) {
      periodos_disp <- sort(unique(df_panel$periodo))
      datas_validas <- DATAS_PLACEBO_TEMPO[
        map_lgl(DATAS_PLACEBO_TEMPO, function(d)
          sum(periodos_disp < d & periodos_disp < periodo_intervencao) >= MIN_PRE_PLACEBO &
            sum(periodos_disp >= d & periodos_disp < periodo_intervencao) >= MIN_POS_PLACEBO)]
      placebo_tempo <- map_dbl(datas_validas, function(d) {
        dft <- df_panel %>% filter(periodo < periodo_intervencao)
        tryCatch(att_sdid_rapido(dft, id_trat, periodo_intervencao, data_corte = d), error = function(e) NA_real_)
      })
      placebo_tempo <- placebo_tempo[!is.na(placebo_tempo)]
      pt_media <- mean(placebo_tempo); pt_dp <- sd(placebo_tempo)
      p_tempo_val <- (1 + sum(abs(placebo_tempo) >= abs(est$att))) / (1 + length(placebo_tempo))
      p_pt <- ggplot(tibble(val = placebo_tempo), aes(val)) +
        geom_histogram(fill = "gray80", bins = 12) +
        geom_vline(xintercept = 0, color = "gray40", linetype = 3) +
        geom_vline(xintercept = est$att, color = "red", linetype = "dashed", linewidth = 1) +
        labs(title = NULL, subtitle = NULL, x = NULL, y = NULL) + theme_minimal()
      ggsave(file.path(dir_saida, paste0(base, "_placebo_tempo.png")), p_pt, width = 8, height = 6, dpi = 300)
      
      loo <- map_dbl(ids_controle, function(drop_id)
        tryCatch(att_sdid_rapido(df_panel %>% filter(id_municipio %in% c(id_trat, setdiff(ids_controle, drop_id))),
                                 id_trat, periodo_intervencao), error = function(e) NA_real_))
      loo_min <- min(loo, na.rm = TRUE); loo_max <- max(loo, na.rm = TRUE)
    }
    # Placebo espacial universo amplo (independe do modo)
    if (RODAR_PLACEBO_ESPACO_UNIVERSO && length(placebos_espaco_uni) > 0) {
      n_ext_uni <- sum(abs(placebos_espaco_uni) >= abs(est$att))
      p_espaco_uni <- (1 + n_ext_uni) / (1 + length(placebos_espaco_uni))
    }
    
    lista_resumo[[as.character(id_trat)]] <- tibble(
      modo = modo, id_municipio = id_trat, municipio_nome = nome_tratado, PopMun = pop_tratado,
      n_doadores = est$n0, n_periodos_pre = est$t0, n_periodos_pos = n_pos,
      att = est$att,
      # inferência gaussiana (placebo vcov)
      ep_gauss = est$se, ic_inf_gauss = est$ic_inf, ic_sup_gauss = est$ic_sup,
      # inferência por permutação direta (principal)
      ep_emp = perm$sd_emp, ic_inf_perm = perm$ic_inf, ic_sup_perm = perm$ic_sup,
      p_bilateral = perm$p_bilateral, p_unilateral = perm$p_unilateral, z = perm$z,
      n_placebos_perm = perm$n_placebos,
      # triangulação (DiD/SC; preenchido só no modo completo)
      att_did = tri$att_did, ep_did = tri$ep_did, ic_inf_did = tri$ic_inf_did, ic_sup_did = tri$ic_sup_did,
      att_sc = tri$att_sc, ep_sc = tri$ep_sc, ic_inf_sc = tri$ic_inf_sc, ic_sup_sc = tri$ic_sup_sc,
      p_bi_sc = tri$p_bi_sc, p_uni_sc = tri$p_uni_sc, inferencia_sc = tri$inferencia_sc,
      rmspe_pre = est$rmspe_pre, gap_nivel_pre = est$gap_nivel_pre,
      # robustez
      p_tempo = p_tempo_val, placebo_tempo_media = pt_media, loo_min = loo_min, loo_max = loo_max,
      p_espaco_uni = p_espaco_uni, n_ext_espaco_uni = n_ext_uni,
      # efeito absoluto por conversão
      efeito_mensal_abs = est$att * pop_tratado / 1000,
      ic_inf_mensal_abs = perm$ic_inf * pop_tratado / 1000,
      ic_sup_mensal_abs = perm$ic_sup * pop_tratado / 1000,
      efeito_acum_abs = tail(df_tempo$efeito_total_acumulado, 1),
      ic_inf_acum_abs = tail(df_tempo$ic_inf_acum, 1), ic_sup_acum_abs = tail(df_tempo$ic_sup_acum, 1))
    lista_tempo[[as.character(id_trat)]] <- df_tempo
    modelos[[as.character(id_trat)]] <- list(tau_hat = est$tau_hat, att = est$att, se = est$se,
                                             nome = nome_tratado, pop = pop_tratado, df_panel = df_panel,
                                             ids_controle = ids_controle, perm = perm)
  }
  
  tabela <- bind_rows(lista_resumo) %>% left_join(df_sev, by = "id_municipio")
  
  # --- Flag de RMSPE alto + classificação (inclui a checagem de ajuste pré) ---
  med_rmspe <- median(tabela$rmspe_pre, na.rm = TRUE)
  tabela <- tabela %>%
    mutate(
      rmspe_alto = rmspe_pre > 1.5 * med_rmspe,
      significativo_perm = ic_inf_perm < 0 & ic_sup_perm < 0,
      classificacao = case_when(
        significativo_perm & p_bilateral <= 0.05 & (is.na(p_tempo) | p_tempo <= 0.10) & !rmspe_alto ~ "Efeito robusto",
        (significativo_perm | p_bilateral <= 0.10)                                                  ~ "Efeito provável (inferência parcial)",
        TRUE                                                                                        ~ "Sem efeito detectável"))
  
  tabela_consolidada <- tabela %>%
    arrange(desc(proporcao_atingidos)) %>%
    select(municipio_nome, PopMun, proporcao_atingidos, n_doadores,
           att, ep_gauss, ic_inf_gauss, ic_sup_gauss,
           ep_emp, ic_inf_perm, ic_sup_perm, p_bilateral, p_unilateral, z,
           rmspe_pre, rmspe_alto, p_tempo, p_espaco_uni, loo_min, loo_max,
           efeito_mensal_abs, ic_inf_mensal_abs, ic_sup_mensal_abs,
           efeito_acum_abs, ic_inf_acum_abs, ic_sup_acum_abs,
           significativo_perm, classificacao)
  cat("\n--- CONSOLIDADA [", modo, "] ---\n"); print(as.data.frame(tabela_consolidada), digits = 3)
  write.csv(tabela_consolidada, file.path(dir_saida, paste0("tabela_CONSOLIDADA_", modo, ".csv")), row.names = FALSE)
  write_xlsx(bind_rows(lista_tempo), file.path(dir_saida, paste0("efeitos_tempo_", modo, ".xlsx")))
  
  # --- Multi-tratado (mantém EP gaussiano; permutação com N1>1 não é trivial) ---
  ids_controle_multi <- obter_doadores(modo, ids_alvo = ids_tratados, verbose = TRUE)
  df_panel_multi <- montar_painel(df_main, c(ids_tratados, ids_controle_multi))
  est_multi <- estimar_sdid(df_panel_multi, ids_alvo = ids_tratados, periodo_intervencao)
  cat(sprintf("\n--- MULTI [%s] ATT=%.3f EP=%.3f IC[%.2f;%.2f] RMSPE=%.2f doad=%d ---\n",
              modo, est_multi$att, est_multi$se, est_multi$ic_inf, est_multi$ic_sup, est_multi$rmspe_pre, est_multi$n0))
  
  # --- Forest plot por severidade (IC de permutação como principal) ---
  df_forest <- bind_rows(
    tabela %>% transmute(municipio_nome, att, ic_inf = ic_inf_perm, ic_sup = ic_sup_perm,
                         proporcao_atingidos, sig = significativo_perm, tipo = "Individual"),
    tibble(municipio_nome = "Multi-tratado (média)", att = est_multi$att,
           ic_inf = est_multi$ic_inf, ic_sup = est_multi$ic_sup,
           proporcao_atingidos = NA_real_, sig = est_multi$ic_sup < 0, tipo = "Multi")) %>%
    mutate(ord = ifelse(is.na(proporcao_atingidos), -Inf, proporcao_atingidos),
           rotulo = ifelse(is.na(proporcao_atingidos), municipio_nome,
                           sprintf("%s (%.2f%%)", municipio_nome, 100 * proporcao_atingidos)),
           rotulo = fct_reorder(rotulo, ord),
           status = case_when(tipo == "Multi" ~ "Multi-tratado (média)",
                              sig             ~ "Negativo significativo (IC<0)",
                              TRUE            ~ "Não significativo (IC cruza 0)"))
  p_forest <- ggplot(df_forest, aes(rotulo, att, color = status)) +
    geom_hline(yintercept = 0, linetype = 2, color = "gray50") +
    geom_pointrange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 0.8, size = 0.7) +
    coord_flip() +
    scale_color_manual(values = c("Negativo significativo (IC<0)" = "#1b7837",
                                  "Não significativo (IC cruza 0)" = "gray55",
                                  "Multi-tratado (média)" = "#D95F0E")) +
    labs(title = NULL, subtitle = NULL,
         x = NULL, y = "ATT (admissões por mil hab.)", color = NULL) +
    theme_minimal() + theme(legend.position = "bottom")
  ggsave(file.path(dir_saida, paste0("forest_plot_", modo, ".png")), p_forest, width = 10, height = 6, dpi = 300)
  
  # --- TRIANGULAÇÃO: tabela + convergência + forest (só no modo completo) ---
  if (modo == "completo" && RODAR_TRIANGULACAO) {
    cols_tri <- c("id_municipio", "municipio_nome", "PopMun", "n_periodos_pos")
    tri_did  <- tabela %>% transmute(across(all_of(cols_tri)), modelo = "DiD clássico",
                                     att = att_did, ic_inf = ic_inf_did, ic_sup = ic_sup_did, p_bilateral = NA_real_)
    tri_sc   <- tabela %>% transmute(across(all_of(cols_tri)), modelo = "Controle Sintético (SC)",
                                     att = att_sc, ic_inf = ic_inf_sc, ic_sup = ic_sup_sc, p_bilateral = p_bi_sc)
    tri_sdid <- tabela %>% transmute(across(all_of(cols_tri)), modelo = "SDID (perm. direta)",
                                     att = att, ic_inf = ic_inf_perm, ic_sup = ic_sup_perm, p_bilateral = p_bilateral)
    tri_tab <- bind_rows(tri_did, tri_sc, tri_sdid) %>%
      mutate(modelo = factor(modelo, levels = c("DiD clássico", "Controle Sintético (SC)", "SDID (perm. direta)")),
             significativo = ic_inf < 0 & ic_sup < 0,
             vagas = (att / 1000) * PopMun * n_periodos_pos)   # método τ × pop × meses (coautor)
    cat("\n--- TRIANGULAÇÃO [completo] ---\n")
    print(as.data.frame(tri_tab %>% select(municipio_nome, modelo, att, ic_inf, ic_sup,
                                           p_bilateral, vagas, significativo)), digits = 3)
    write.csv(tri_tab, file.path(dir_saida, "triangulacao_did_sc_sdid.csv"), row.names = FALSE)
    
    convergencia <- tri_tab %>%
      group_by(municipio_nome) %>%
      summarise(att_did = att[modelo == "DiD clássico"],
                att_sc  = att[modelo == "Controle Sintético (SC)"],
                att_sdid = att[modelo == "SDID (perm. direta)"],
                amplitude = max(att) - min(att),
                mesmo_sinal = n_distinct(sign(att)) == 1, .groups = "drop") %>%
      arrange(att_sdid)
    cat("\n--- CONVERGÊNCIA ENTRE ESTIMADORES ---\n"); print(as.data.frame(convergencia), digits = 3)
    write.csv(convergencia, file.path(dir_saida, "triangulacao_convergencia.csv"), row.names = FALSE)
    
    p_tri <- ggplot(tri_tab, aes(att, modelo, color = significativo)) +
      facet_wrap(~ municipio_nome, scales = "free_x") +
      geom_vline(xintercept = 0, linetype = 2, color = "gray55") +
      geom_errorbar(aes(xmin = ic_inf, xmax = ic_sup), width = 0.25, linewidth = 0.9, orientation = "y") +
      geom_point(size = 3) +
      scale_color_manual(values = c(`TRUE` = "#C0392B", `FALSE` = "#7F8C8D"),
                         labels = c(`TRUE` = "IC exclui zero", `FALSE` = "IC cruza zero"), name = NULL) +
      labs(title = NULL, subtitle = NULL,
           x = "Efeito (admissões por mil hab. por mês)", y = NULL) +
      theme_minimal() + theme(legend.position = "none", strip.text = element_text(face = "bold"))
    ggsave(file.path(dir_saida, "triangulacao_forest.png"), p_tri, width = 12, height = 8, dpi = 300)
  }
  
  list(modo = modo, dir = dir_saida, tabela = tabela, multi = est_multi)
}

# ============================================================
# 7. RODAR TODOS OS MODOS
# ============================================================
resultados_modos <- map(MODOS_DOADORES, analisar_modo) %>% set_names(MODOS_DOADORES)
tabela_todos_modos <- map_dfr(resultados_modos, "tabela")
write.csv(tabela_todos_modos, file.path(dir_base, "SDID_tabela_TODOS_MODOS.csv"), row.names = FALSE)

# ============================================================
# 8. COMPARAÇÃO PAREADO × COMPLETO × PDF (Eldorado do Sul e Roca Sales)
# ============================================================
cat("\n\n=== COMPARAÇÃO COM O PDF (Eldorado do Sul e Roca Sales) ===\n")
ids_pdf <- ref_pdf$id_municipio

# Nossas estimativas (cada modo disponível) para os 2 municípios do PDF
nosso_comp <- tabela_todos_modos %>%
  filter(id_municipio %in% ids_pdf) %>%
  transmute(id_municipio, municipio_nome,
            fonte = paste0("Nosso (", modo, ")"),
            att, ep = ep_emp, ic_inf = ic_inf_perm, ic_sup = ic_sup_perm,
            p_bi = p_bilateral, p_uni = p_unilateral, n_doadores, z)

pdf_comp <- ref_pdf %>%
  transmute(id_municipio, municipio_nome, fonte = "PDF (pool 193, perm.)",
            att = att_pdf, ep = ep_pdf, ic_inf = ic_inf_pdf, ic_sup = ic_sup_pdf,
            p_bi = p_bi_pdf, p_uni = p_uni_pdf, n_doadores = 193L, z = att_pdf / ep_pdf)

tabela_comparacao <- bind_rows(nosso_comp, pdf_comp) %>%
  arrange(municipio_nome, fonte)
cat("\n--- TABELA COMPARATIVA ---\n"); print(as.data.frame(tabela_comparacao), digits = 3)
write.csv(tabela_comparacao, file.path(dir_base, "SDID_comparacao_pareado_completo_PDF.csv"), row.names = FALSE)

# Forest comparativo (ES e RS): nosso(s) modo(s) vs PDF
p_comp <- tabela_comparacao %>%
  mutate(rotulo = paste0(municipio_nome, "\n", fonte),
         destaque = ic_inf < 0 & ic_sup < 0) %>%
  ggplot(aes(reorder(rotulo, att), att, color = destaque)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray50") +
  geom_pointrange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 0.8, size = 0.6) +
  coord_flip() + facet_wrap(~ municipio_nome, scales = "free_y", ncol = 1) +
  scale_color_manual(values = c(`TRUE` = "#1b7837", `FALSE` = "gray55"),
                     labels = c(`TRUE` = "IC exclui zero", `FALSE` = "IC cruza zero"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = NULL, y = "ATT (admissões por mil hab.)") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_base, "SDID_forest_comparacao_PDF.png"), p_comp, width = 9, height = 7, dpi = 300)

# ============================================================
# 9. HETEROGENEIDADE DO EFEITO — ANÁLISE EXPLORATÓRIA
#  AVISO METODOLÓGICO: n = 6 tratados. Isto é DESCRITIVO e gerador de
#  hipóteses, NÃO inferência. Nenhuma regressão ou p-valor é reportado:
#  com 6 pontos e 9 covariáveis, qualquer ajuste é espúrio. O objetivo é
#  ver QUAL dimensão estrutural acompanha a divisão entre municípios com
#  efeito (IC<0) e sem efeito. Toda leitura é associativa, não causal.
#  Como a severidade (proporcao_atingidos) é quase idêntica nos 4 menos
#  atingidos (~51-54%) e os efeitos divergem, ela NÃO explica a divisão —
#  a hipótese é que a estrutura econômica explique.
# ============================================================
modo_het <- if ("completo" %in% names(resultados_modos)) "completo" else names(resultados_modos)[1]
cat("\n\n=== HETEROGENEIDADE (modo:", modo_het, ") ===\n")
dir_het <- file.path(dir_base, "SDID heterogeneidade")
if (!dir.exists(dir_het)) dir.create(dir_het, recursive = TRUE)

vars_estrut <- c("pib_per_capita_medio", "share_agro_medio", "share_ind_medio",
                 "share_serv_medio", "share_adm_medio", "Idese 2021",
                 "salario_medio_agregado", "operacoes_credito_medio",
                 "total_ativo_medio", "PopMun")

base_het <- resultados_modos[[modo_het]]$tabela %>%
  select(id_municipio, municipio_nome, att, p_bilateral, rmspe_pre, rmspe_alto,
         significativo_perm, classificacao, proporcao_atingidos) %>%
  left_join(df_cov %>% select(id_municipio, all_of(vars_estrut)) %>% distinct(),
            by = "id_municipio") %>%
  mutate(grupo_efeito = ifelse(significativo_perm, "com", "sem"))

cat("\n--- Municípios por grupo de efeito ---\n")
print(base_het %>% select(municipio_nome, att, classificacao, proporcao_atingidos) %>%
        arrange(att) %>% as.data.frame(), digits = 3)
write.csv(base_het, file.path(dir_het, "heterogeneidade_base.csv"), row.names = FALSE)

# Formato longo + z-score de cada covariável entre os 6
het_long <- base_het %>%
  pivot_longer(all_of(vars_estrut), names_to = "covariavel", values_to = "valor") %>%
  group_by(covariavel) %>% mutate(z = as.numeric(scale(valor))) %>% ungroup()

# --- COBERTURA por covariável e por grupo ---
# Exigência: ao menos MIN_COBERTURA_GRUPO municípios válidos em CADA grupo.
# Sem isso, o "gap" compara médias de 1 ponto e produz campeões espúrios
# (foi o caso de total_ativo_medio e operacoes_credito_medio, com 1 só "sem efeito").
MIN_COBERTURA_GRUPO <- 2L
cobertura <- het_long %>%
  group_by(covariavel) %>%
  summarise(n_validos = sum(!is.na(valor)),
            n_com_valido = sum(!is.na(valor) & grupo_efeito == "com"),
            n_sem_valido = sum(!is.na(valor) & grupo_efeito == "sem"),
            .groups = "drop") %>%
  mutate(cobertura_ok = n_com_valido >= MIN_COBERTURA_GRUPO & n_sem_valido >= MIN_COBERTURA_GRUPO)

vars_cobertura_ok <- cobertura %>% filter(cobertura_ok) %>% pull(covariavel)
vars_excluidas    <- cobertura %>% filter(!cobertura_ok) %>% pull(covariavel)
if (length(vars_excluidas) > 0)
  cat(sprintf("\n[heterogeneidade] %d covariável(is) EXCLUÍDA(S) do ranking/gráficos por cobertura < %d em algum grupo:\n   %s\n",
              length(vars_excluidas), MIN_COBERTURA_GRUPO, paste(vars_excluidas, collapse = ", ")))

# Ranking: qual covariável mais separa "com efeito" de "sem efeito"
# (diferença de média padronizada). DESCRITIVO — não é teste. Variáveis com
# cobertura insuficiente são sinalizadas e empurradas para o fim (não lideram).
ranking_sep <- het_long %>%
  group_by(covariavel, grupo_efeito) %>%
  summarise(media_z = mean(z, na.rm = TRUE), media_bruta = mean(valor, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = grupo_efeito, values_from = c(media_z, media_bruta)) %>%
  mutate(gap_z_padronizado = media_z_com - media_z_sem) %>%
  left_join(cobertura, by = "covariavel") %>%
  arrange(desc(cobertura_ok), desc(abs(gap_z_padronizado))) %>%
  select(covariavel, cobertura_ok, n_com_valido, n_sem_valido,
         gap_z_padronizado, media_z_com, media_z_sem, media_bruta_com, media_bruta_sem)
cat("\n--- Ranking de separação (apenas covariáveis com cobertura OK lideram) ---\n")
print(as.data.frame(ranking_sep), digits = 3)
write.csv(ranking_sep, file.path(dir_het, "heterogeneidade_ranking_separacao.csv"), row.names = FALSE)

# Subconjunto válido para os GRÁFICOS (evita painéis enganosos com 1 ponto/grupo)
het_long_ok <- het_long %>% filter(covariavel %in% vars_cobertura_ok)

# Dispersão: ATT vs cada covariável (só cobertura OK), rotulado por município
usar_repel <- requireNamespace("ggrepel", quietly = TRUE)
p_scatter <- ggplot(het_long_ok, aes(valor, att, color = grupo_efeito)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray60") +
  geom_point(size = 2.6) +
  {if (usar_repel) ggrepel::geom_text_repel(aes(label = municipio_nome), size = 2.3, max.overlaps = Inf)
    else geom_text(aes(label = municipio_nome), size = 2.3, vjust = -0.8)} +
  facet_wrap(~ covariavel, scales = "free_x") +
  scale_color_manual(values = c(com = "#1b7837", sem = "gray55"),
                     labels = c(com = "Com efeito (IC<0)", sem = "Sem efeito"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = "Valor da covariável", y = "ATT (admissões por mil hab.)") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_het, "heterogeneidade_dispersao.png"), p_scatter, width = 11, height = 8, dpi = 300)

# Perfil z: "impressão digital" estrutural de cada município (só cobertura OK)
p_perfil <- ggplot(het_long_ok, aes(reorder(covariavel, z), z, group = municipio_nome, color = grupo_efeito)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray60") +
  geom_line(alpha = 0.5) + geom_point(size = 2) +
  geom_text(data = het_long_ok %>% group_by(municipio_nome) %>% slice_max(z, n = 1) %>% ungroup(),
            aes(label = municipio_nome), size = 2.2, vjust = -0.7, show.legend = FALSE) +
  coord_flip() +
  scale_color_manual(values = c(com = "#1b7837", sem = "gray55"),
                     labels = c(com = "Com efeito (IC<0)", sem = "Sem efeito"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = NULL, y = "z-score da covariável (entre os 6)") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_het, "heterogeneidade_perfil_z.png"), p_perfil, width = 10, height = 7, dpi = 300)

write.csv(cobertura, file.path(dir_het, "heterogeneidade_cobertura.csv"), row.names = FALSE)
cat("\nHeterogeneidade: saídas em\n", dir_het, "\n")

# ============================================================
# 10. HETEROGENEIDADE II — DANO FÍSICO DO DESASTRE (MUPRS) vs EFEITO SDID
#  Integrada ao pipeline: NÃO reestima nenhum SDID; usa os resultados já em
#  memória (resultados_modos[[modo_het]]$tabela, modo "completo") + a base
#  MUPRS de atingidos. Roda em segundos.
#
#  OBJETIVO: testar (DESCRITIVAMENTE, n=6) se variáveis de dano à base
#  PRODUTIVA e à INFRAESTRUTURA acompanham a heterogeneidade do efeito
#  melhor que o dano residencial (proporcao_atingidos), que já sabemos não
#  separar os grupos.
#
#  CANAIS TEÓRICOS (economia de desastres):
#   - Capital/firma:    % de CNPJs atingidos (destruição de estabelecimentos).
#   - Conectividade:    % de malha rodoviária atingida (custos/escoamento).
#   - Serviços públicos:% de equipamentos públicos atingidos (canal mais fraco).
#   - Geografia do dano:índice = %CNPJ − %domicílios (firmas vs. casas).
#   - Dano residencial: % domicílios/famílias (CONTRASTE — esperado NÃO separar).
#
#  EXCLUÍDAS POR DESIGN: auxílios (pós-tratamento/endógenos) e "Situação do
#  Município" (categórica colinear com severidade).
#
#  AVISO: n=6. DESCRITIVO e gerador de hipóteses. Sem regressão, sem p-valor.
#  Leitura associativa, jamais causal entre municípios.
# ============================================================
cat("\n\n=== HETEROGENEIDADE II — DANO FÍSICO (MUPRS) (modo:", modo_het, ") ===\n")
dir_het_dano <- file.path(dir_base, "SDID heterogeneidade dano")
if (!dir.exists(dir_het_dano)) dir.create(dir_het_dano, recursive = TRUE)

# 10.1 Resultados SDID já calculados (em memória) — grupos com/sem efeito
res_dano <- resultados_modos[[modo_het]]$tabela %>%
  select(id_municipio, municipio_nome, att, p_bilateral,
         ic_inf_perm, ic_sup_perm, rmspe_pre, rmspe_alto,
         significativo_perm, classificacao) %>%
  mutate(grupo_efeito = ifelse(significativo_perm, "com", "sem"))

# 10.2 Base MUPRS -> variáveis de dano (proporções).
#   Código IBGE no MUPRS é de 6 dígitos (sem verificador); nossos ids têm 7.
#   Casamento por cod6 = id7 %/% 10 (ambos forçados a inteiro).
muprs <- read_excel(path_muprs) %>%
  rename(cod6 = `Código IBGE`) %>%
  mutate(cod6 = as.integer(round(as.numeric(cod6))))
mapa_dano <- tibble(id_municipio = ids_tratados, cod6 = as.integer(ids_tratados %/% 10L))

dano <- muprs %>%
  inner_join(mapa_dano, by = "cod6") %>%
  transmute(
    id_municipio = id_municipio,
    prop_cnpj       = CNPJ_Atingidos / CNPJ_Total,                                  # firma/capital
    prop_rodovia    = Malha_Rodoviaria_KM_Atingidos / Malha_Rodoviaria_Total,       # conectividade
    prop_eq_publico = Equipamentos_Publicos_Atingidos / Equipamentos_Publicos_Total,# serviços públicos
    prop_domicilios = Domicilios_Particulares_Atingidos / Domicilios_Particulares_Total,
    prop_familias   = Familias_Atingidas / Familias_Total,
    idx_produtivo_relativo = prop_cnpj - prop_domicilios,                           # produtivo vs. residencial
    cnpj_atingidos  = CNPJ_Atingidos, cnpj_total = CNPJ_Total)

vars_dano <- c("prop_cnpj", "prop_rodovia", "prop_eq_publico",
               "prop_domicilios", "prop_familias", "idx_produtivo_relativo")

# 10.3 Junta efeito + dano
base_dano <- res_dano %>% left_join(dano, by = "id_municipio") %>% arrange(att)
cat("\n--- Efeito x dano (ordenado por ATT) ---\n")
print(base_dano %>%
        select(municipio_nome, grupo_efeito, att, classificacao,
               prop_cnpj, prop_rodovia, prop_domicilios, idx_produtivo_relativo) %>%
        as.data.frame(), digits = 3)
write.csv(base_dano, file.path(dir_het_dano, "dano_base.csv"), row.names = FALSE)

# 10.4 Ranking de separação com guarda de cobertura (reusa MIN_COBERTURA_GRUPO da seção 9)
het_dano_long <- base_dano %>%
  pivot_longer(all_of(vars_dano), names_to = "variavel", values_to = "valor") %>%
  group_by(variavel) %>% mutate(z = as.numeric(scale(valor))) %>% ungroup()

cobertura_dano <- het_dano_long %>%
  group_by(variavel) %>%
  summarise(n_com_valido = sum(!is.na(valor) & grupo_efeito == "com"),
            n_sem_valido = sum(!is.na(valor) & grupo_efeito == "sem"), .groups = "drop") %>%
  mutate(cobertura_ok = n_com_valido >= MIN_COBERTURA_GRUPO & n_sem_valido >= MIN_COBERTURA_GRUPO)

ranking_dano <- het_dano_long %>%
  group_by(variavel, grupo_efeito) %>%
  summarise(media_z = mean(z, na.rm = TRUE), media_bruta = mean(valor, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = grupo_efeito, values_from = c(media_z, media_bruta)) %>%
  mutate(gap_z_padronizado = media_z_com - media_z_sem) %>%
  left_join(cobertura_dano, by = "variavel") %>%
  arrange(desc(cobertura_ok), desc(abs(gap_z_padronizado))) %>%
  select(variavel, cobertura_ok, n_com_valido, n_sem_valido,
         gap_z_padronizado, media_bruta_com, media_bruta_sem)
cat("\n--- Ranking de separação (dano) ---\n"); print(as.data.frame(ranking_dano), digits = 3)
write.csv(ranking_dano, file.path(dir_het_dano, "dano_ranking_separacao.csv"), row.names = FALSE)

# 10.5 Gráficos
usar_repel <- requireNamespace("ggrepel", quietly = TRUE)
rotular_dano <- function(p) {
  if (usar_repel) p + ggrepel::geom_text_repel(aes(label = municipio_nome), size = 2.4, max.overlaps = Inf)
  else            p + geom_text(aes(label = municipio_nome), size = 2.4, vjust = -0.8)
}

# (a) Dispersão ATT vs cada variável de dano
p_disp_dano <- rotular_dano(
  ggplot(het_dano_long, aes(valor, att, color = grupo_efeito)) +
    geom_hline(yintercept = 0, linetype = 2, color = "gray60") + geom_point(size = 2.8)) +
  facet_wrap(~ variavel, scales = "free_x") +
  scale_color_manual(values = c(com = "#1b7837", sem = "gray55"),
                     labels = c(com = "Com efeito (IC<0)", sem = "Sem efeito"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = "Valor da variável de dano", y = "ATT (admissões por mil hab.)") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_het_dano, "dano_dispersao.png"), p_disp_dano, width = 11, height = 7, dpi = 300)

# (b) Foco: canais centrais (dano viário, CNPJ, índice produtivo)
foco_dano <- base_dano %>%
  select(municipio_nome, grupo_efeito, prop_rodovia, prop_cnpj, idx_produtivo_relativo) %>%
  pivot_longer(c(prop_rodovia, prop_cnpj, idx_produtivo_relativo),
               names_to = "variavel", values_to = "valor")
p_foco_dano <- ggplot(foco_dano, aes(reorder(municipio_nome, valor), valor, fill = grupo_efeito)) +
  geom_col() + coord_flip() + facet_wrap(~ variavel, scales = "free_x") +
  scale_fill_manual(values = c(com = "#1b7837", sem = "gray55"),
                    labels = c(com = "Com efeito (IC<0)", sem = "Sem efeito"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = NULL, y = "Proporção atingida / índice") +
  theme_minimal() + theme(legend.position = "none")
ggsave(file.path(dir_het_dano, "dano_canais_centrais.png"), p_foco_dano, width = 11, height = 6, dpi = 300)

# (c) Perfil z por município (impressão digital do dano)
p_perfil_dano <- ggplot(het_dano_long, aes(reorder(variavel, z), z, group = municipio_nome, color = grupo_efeito)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray60") +
  geom_line(alpha = 0.5) + geom_point(size = 2) +
  geom_text(data = het_dano_long %>% group_by(municipio_nome) %>% slice_max(z, n = 1) %>% ungroup(),
            aes(label = municipio_nome), size = 2.2, vjust = -0.7, show.legend = FALSE) +
  coord_flip() +
  scale_color_manual(values = c(com = "#1b7837", sem = "gray55"),
                     labels = c(com = "Com efeito (IC<0)", sem = "Sem efeito"), name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = NULL, y = "z-score da variável de dano") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_het_dano, "dano_perfil_z.png"), p_perfil_dano, width = 10, height = 6, dpi = 300)

write.csv(cobertura_dano, file.path(dir_het_dano, "dano_cobertura.csv"), row.names = FALSE)
cat("\nHeterogeneidade de dano: saídas em\n", dir_het_dano, "\n")
cat("\nLeitura esperada: dano VIÁRIO e dano a CNPJs separam melhor que o dano\n",
    "residencial; Arambaré aparece como tecido produtivo poupado (idx negativo);\n",
    "Igrejinha resiste à geografia do dano (escala/diversificação — interpretar à parte).\n")

cat("\nConcluído. Modos rodados:", paste(MODOS_DOADORES, collapse = ", "), "\n")
cat("Saídas por modo em subpastas de:\n", dir_base, "\n")

# ============================================================
# NOTA DE RECONCILIAÇÃO (para o texto / banca):
#  (a) População difere entre a nossa base e o PDF (ES 40.954 vs 42.490;
#      RS 10.644 vs 11.556). Isso altera o cálculo de vagas. Fixar UMA
#      fonte censitária (ano de referência) antes de reportar absolutos.
#  (b) O PDF acumula vagas como τ_médio × pop × 11; a nossa v5 soma a curva
#      de efeito mês a mês (efeito_total_acumulado). Os dois divergem um
#      pouco — padronizar o método de acumulação no texto.
#  (c) Conferir se a janela pré coincide (PDF: T0=40, jan/2021→abr/2024).
#      Se a nossa começar depois, os pesos λ e o RMSPE não são comparáveis.
#  (d) Multi-tratado usa EP gaussiano (permutação com N1>1 exige desenho
#      de re-randomização específico, não implementado aqui).
# ============================================================