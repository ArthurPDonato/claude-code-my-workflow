# ============================================================
#  SDiD EM FREQUENCIA TRIMESTRAL  (sugestao da banca, item 4)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Pergunta da banca: o efeito sobrevive quando agregamos o CAGED mensal
#  (ruidoso) em trimestres? A agregacao reduz a variancia de alta frequencia.
#
#  Agregacao (CUIDADO — fluxo soma, nivel faz media):
#    admissoes_por_mil (fluxo) -> SOMA dos 3 meses do trimestre
#    saldo_por_mil     (fluxo) -> SOMA
#    salario_medio     (nivel) -> MEDIA ponderada por admissoes
#  periodo_tri = ano*4 + trimestre ; trimestre = ceiling(mes/3)
#
#  Timing do evento (maio/2024 cai no Q2 2024):
#    EVENTO_Q2 (default) -> 1o pos = Q2 2024 (contem abril pre; "parcial")
#    robustez           -> 1o pos = Q3 2024 (trimestre limpo)  [TIMINGS]
#
#  Criterio: populacional base (prop_pop > POP_THRESH), igual ao artigo.
#  SDiD + permutacao donut + triangulacao SC/DiD (sdid-conventions.md).
#
#  AMBIENTE: R 4.4.2 (tem synthdid).
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/sdid_trimestral.R
# ============================================================

suppressMessages({
  library(tidyverse); library(readxl); library(synthdid); library(future.apply)
})
set.seed(20240501)
N_WORKERS <- max(1L, parallel::detectCores())
plan(multisession, workers = N_WORKERS)
cat(sprintf(">> paralelismo: %d workers\n", N_WORKERS))

# ------------------------------------------------------------
# 1. PARAMETROS
# ------------------------------------------------------------
POP_THRESH    <- 0.50
LIMIAR_DOADOR <- 0.005
# timings a rodar: nome -> primeiro trimestre tratado (ano*4 + trimestre)
TIMINGS <- c(Q2_2024 = 2024L*4L + 2L,   # contem maio (e abril, pre)
             Q3_2024 = 2024L*4L + 3L)   # robustez: trimestre limpo
OUTCOME_COL   <- "adm_tri_por_mil"      # desfecho principal (admissoes trimestrais por mil)

dir_base  <- "Artigos/SDID/Resultados"
dir_saida <- file.path(dir_base, "SDID trimestral")
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

path_main  <- "Artigos/SDID/Base de Dados/Final/BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx"
path_muprs <- "Artigos/SDID/Base de Dados/Primárias/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"

num <- function(x) suppressWarnings(as.numeric(str_replace_all(as.character(x), ",", ".")))

# ------------------------------------------------------------
# 2. PAINEL MENSAL -> TRIMESTRAL
# ------------------------------------------------------------
mensal <- read_excel(path_main) %>%
  select(data, municipio_nome, id_municipio, admissoes_por_mil) %>%
  mutate(ano = as.integer(format(as.Date(data), "%Y")),
         mes = as.integer(format(as.Date(data), "%m")),
         tri = ((mes - 1L) %/% 3L) + 1L,
         periodo = ano * 4L + tri)

# fluxo -> SOMA dentro do trimestre; exige os 3 meses presentes p/ trimestre completo
tri_df <- mensal %>%
  group_by(id_municipio, municipio_nome, ano, tri, periodo) %>%
  summarise(n_meses = n_distinct(mes),
            adm_tri_por_mil = sum(admissoes_por_mil, na.rm = TRUE),
            .groups = "drop") %>%
  filter(n_meses == 3L) %>%                 # so trimestres completos
  select(id_municipio, municipio_nome, periodo, adm_tri_por_mil)

df_nomes <- tri_df %>% select(id_municipio, municipio_nome) %>% distinct()
cat(sprintf(">> trimestres completos: %d periodos | %d municipios\n",
            n_distinct(tri_df$periodo), n_distinct(tri_df$id_municipio)))

# ------------------------------------------------------------
# 3. CRITERIO POPULACIONAL (tratado / doador donut)
# ------------------------------------------------------------
muprs <- read_excel(path_muprs) %>%
  transmute(cod6 = as.integer(round(num(`Código IBGE`))),
            prop_pop = num(Pop_Atingidos) / num(Pop_Total),
            Pop_Total = num(Pop_Total))
df_dano <- df_nomes %>%
  mutate(cod6 = as.integer(id_municipio %/% 10L)) %>%
  left_join(muprs, by = "cod6") %>%
  mutate(prop_pop = coalesce(prop_pop, 0)) %>%
  select(id_municipio, prop_pop, PopMun = Pop_Total)

ids_tratados <- df_dano$id_municipio[df_dano$prop_pop >  POP_THRESH]
ids_doadores <- setdiff(df_dano$id_municipio[df_dano$prop_pop <= LIMIAR_DOADOR], ids_tratados)
cat(sprintf(">> criterio pop>%.0f%%: %d tratados | %d doadores donut\n",
            100*POP_THRESH, length(ids_tratados), length(ids_doadores)))

# ------------------------------------------------------------
# 4. FUNCOES SDiD (desfecho = OUTCOME_COL; periodo_intervencao parametrizado)
# ------------------------------------------------------------
num_para_tri_texto <- function(v) {
  out <- rep("", length(v)); ok <- which(!is.na(v))
  if (length(ok)) { vi <- floor(v[ok]); a <- vi %/% 4L; q <- vi %% 4L
    q <- ifelse(q == 0L, 4L, q); a <- ifelse(vi %% 4L == 0L, a - 1L, a)
    out[ok] <- sprintf("%dQ%d", a, q) }
  out
}
montar_painel <- function(ids_modelo) {
  dfp <- tri_df %>% filter(id_municipio %in% ids_modelo) %>%
    transmute(id_municipio, periodo, outcome = .data[[OUTCOME_COL]]) %>% drop_na()
  pc <- dfp %>% group_by(periodo) %>%
    summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
    filter(n == n_distinct(dfp$id_municipio)) %>% pull(periodo)
  dfp %>% filter(periodo %in% pc)
}
calcular_rmspe_pre <- function(tau_hat, setup) {
  w <- attr(tau_hat, "weights"); omega <- w$omega; lambda <- w$lambda
  Y <- setup$Y; N0 <- setup$N0; T0 <- setup$T0
  serie_tr <- colMeans(Y[(N0 + 1):nrow(Y), , drop = FALSE])
  serie_sc <- as.numeric(t(omega) %*% Y[1:N0, , drop = FALSE])
  gap <- (serie_tr - serie_sc)[1:T0]; off <- sum(lambda * gap)
  sqrt(mean((gap - off)^2))
}
estimar_sdid <- function(dfp, ids_alvo, pint) {
  d <- dfp %>% rename(unit = id_municipio, time = periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= pint)) %>% as.data.frame()
  s <- panel.matrices(d, "unit", "time", "outcome", "treated")
  tau <- synthdid_estimate(s$Y, s$N0, s$T0)
  se  <- as.numeric(sqrt(vcov(tau, method = "placebo")))
  list(tau = tau, setup = s, att = as.numeric(tau), se = se,
       ic_inf = as.numeric(tau) - 1.96*se, ic_sup = as.numeric(tau) + 1.96*se,
       att_sc = as.numeric(sc_estimate(s$Y, s$N0, s$T0)),
       att_did = as.numeric(did_estimate(s$Y, s$N0, s$T0)),
       rmspe_pre = calcular_rmspe_pre(tau, s), n0 = s$N0, t0 = s$T0, t1 = ncol(s$Y) - s$T0)
}
att_rapido <- function(dfp, ids_alvo, pint) {
  d <- dfp %>% rename(unit = id_municipio, time = periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= pint)) %>% as.data.frame()
  s <- panel.matrices(d, "unit", "time", "outcome", "treated")
  as.numeric(synthdid_estimate(s$Y, s$N0, s$T0))
}
permutacao <- function(dfp, id_trat, ids_doad, pint) {
  att0 <- att_rapido(dfp, id_trat, pint)
  taus <- map_dbl(ids_doad, ~ tryCatch(att_rapido(dfp, .x, pint), error = function(e) NA_real_))
  taus <- taus[!is.na(taus)]; med <- median(taus)
  q <- as.numeric(quantile(taus - med, c(0.025, 0.975), names = FALSE))
  list(att = att0, n = length(taus), sd_emp = sd(taus),
       ic_inf = att0 + q[1], ic_sup = att0 + q[2],
       p_bilateral = mean(abs(taus) >= abs(att0)))
}

# ------------------------------------------------------------
# 5. RODAR CADA TIMING: multi-ATT + por-municipio (permutacao) + triangulacao
# ------------------------------------------------------------
processar_timing <- function(nome_timing, pint) {
  cat(sprintf("\n#### TIMING %s (1o pos = periodo %d) ####\n", nome_timing, pint))

  # por municipio tratado (paralelo)
  lst <- future_lapply(ids_tratados, function(idt) {
    dfp <- montar_painel(c(idt, ids_doadores))
    est <- estimar_sdid(dfp, idt, pint)
    prm <- permutacao(dfp, idt, ids_doadores, pint)
    nome <- (df_nomes %>% filter(id_municipio == idt) %>% pull(municipio_nome))[1]
    popm <- (df_dano  %>% filter(id_municipio == idt) %>% pull(PopMun))[1]
    tibble(timing = nome_timing, id_municipio = idt, municipio_nome = nome, PopMun = popm,
           att = est$att, ep_gauss = est$se, att_sc = est$att_sc, att_did = est$att_did,
           ic_inf_perm = prm$ic_inf, ic_sup_perm = prm$ic_sup, p_bilateral = prm$p_bilateral,
           rmspe_pre = est$rmspe_pre, n_doadores = est$n0, n_pre = est$t0, n_pos = est$t1,
           significativo = prm$ic_inf < 0 & prm$ic_sup < 0)
  }, future.seed = TRUE,
     future.packages = c("dplyr","tidyr","purrr","tibble","synthdid"))
  tab <- bind_rows(lst) %>% arrange(att)

  # multi-ATT
  dfp_multi <- montar_painel(c(ids_tratados, ids_doadores))
  em <- estimar_sdid(dfp_multi, ids_tratados, pint)
  multi <- tibble(timing = nome_timing, escopo = "MULTI", att = em$att, ep_gauss = em$se,
                  ic_inf = em$ic_inf, ic_sup = em$ic_sup, att_sc = em$att_sc, att_did = em$att_did,
                  rmspe_pre = em$rmspe_pre, n_doadores = em$n0, n_pre = em$t0, n_pos = em$t1)

  cat(sprintf(">> MULTI [%s] ATT=%.3f IC[%.2f;%.2f] SC=%.2f DiD=%.2f | acerto=%d/%d\n",
              nome_timing, em$att, em$ic_inf, em$ic_sup, em$att_sc, em$att_did,
              sum(tab$significativo), nrow(tab)))
  print(as.data.frame(tab %>% select(municipio_nome, att, ic_inf_perm, ic_sup_perm,
                                      p_bilateral, significativo)), digits = 3, row.names = FALSE)
  list(tab = tab, multi = multi)
}

resultados <- imap(TIMINGS, ~ processar_timing(.y, .x))
tab_ind   <- map_dfr(resultados, "tab")
tab_multi <- map_dfr(resultados, "multi")
write.csv(tab_ind,   file.path(dir_saida, "trimestral_individual.csv"), row.names = FALSE)
write.csv(tab_multi, file.path(dir_saida, "trimestral_multi.csv"),      row.names = FALSE)

# forest plot (timing Q2, individual + multi)
tf <- resultados$Q2_2024$tab
df_forest <- bind_rows(
  tf %>% transmute(municipio_nome, att, ic_inf = ic_inf_perm, ic_sup = ic_sup_perm,
                   sig = significativo, tipo = "Individual"),
  resultados$Q2_2024$multi %>% transmute(municipio_nome = "MULTI (media)", att,
                   ic_inf, ic_sup, sig = ic_sup < 0, tipo = "Multi")) %>%
  mutate(rotulo = fct_reorder(municipio_nome, att),
         status = case_when(tipo == "Multi" ~ "Multi (media)",
                            sig ~ "Negativo sig. (IC<0)", TRUE ~ "Nao sig."))
p_forest <- ggplot(df_forest, aes(rotulo, att, color = status)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray50") +
  geom_pointrange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 0.7, size = 0.5) +
  coord_flip() +
  scale_color_manual(values = c("Negativo sig. (IC<0)" = "#1b7837",
                                "Nao sig." = "gray55", "Multi (media)" = "#D95F0E")) +
  labs(title = "SDiD trimestral — criterio populacional (evento Q2 2024)",
       x = NULL, y = "ATT (admissoes trimestrais por mil hab.)", color = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_saida, "trimestral_forest_Q2.png"), p_forest, width = 10, height = 6, dpi = 200)

plan(sequential)
cat("\n=== MULTI-ATT POR TIMING ===\n")
print(as.data.frame(tab_multi), digits = 3, row.names = FALSE)
cat("\nConcluido. Saidas em:", dir_saida, "\n")
