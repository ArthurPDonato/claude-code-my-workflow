# ============================================================
#  CONTROLE SINTETICO CLASSICO (Abadie) — VARIAVEL DEFASADA  (banca, item 2)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Pergunta da banca: usar a VARIAVEL DEFASADA no controle sintetico.
#  Operacionalizacao: SC CLASSICO (pacote Synth) casando em LAGS do desfecho
#  (special.predictors) + covariaveis estruturais, para cada municipio tratado
#  pelo criterio populacional. Compara com o synthdid/sc_estimate ja reportados.
#
#  NOTA (sdid-conventions.md): o SC classico difere do sc_estimate do synthdid
#  no target e na normalizacao dos pesos. Divergencia e ESPERADA — documentar,
#  nao "corrigir". synthdid ja casa na trajetoria pre inteira; aqui testamos o
#  SC classico com lags explicitos como preditores.
#
#  Inferencia: placebo-in-space (cada doador como tratado), razao RMSPE pos/pre;
#  p-valor = posicao do tratado na distribuicao dos placebos. Pool de placebo
#  limitado a N_PLACEBO doadores (amostra seeded) por custo — documentado.
#
#  AMBIENTE: R 4.4.2 (tem Synth e synthdid).
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/sc_classico_abadie.R
# ============================================================

suppressMessages({
  library(tidyverse); library(readxl); library(Synth); library(future.apply)
})
set.seed(20240501)
N_WORKERS <- max(1L, parallel::detectCores())
plan(multisession, workers = N_WORKERS)
cat(sprintf(">> paralelismo: %d workers\n", N_WORKERS))

# ------------------------------------------------------------
# 1. PARAMETROS
# ------------------------------------------------------------
POP_THRESH          <- 0.50
LIMIAR_DOADOR       <- 0.005
periodo_intervencao <- 2024L * 12L + 5L     # maio/2024 (mensal: ano*12+mes)
N_PLACEBO           <- 60L                  # teto de doadores no placebo (custo)
vars_estrut <- c("pib_per_capita_medio", "share_agro_medio", "share_ind_medio",
                 "share_serv_medio", "Idese 2021", "operacoes_credito_medio")

dir_base  <- "Artigos/SDID/Resultados"
dir_saida <- file.path(dir_base, "SC classico Abadie")
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

path_main  <- "Artigos/SDID/Base de Dados/Final/BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx"
path_muprs <- "Artigos/SDID/Base de Dados/Primárias/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"
path_cov   <- "Artigos/SDID/Base de Dados/Final/Covariaveis_SDID_Final.xlsx"

num <- function(x) suppressWarnings(as.numeric(str_replace_all(as.character(x), ",", ".")))

# ------------------------------------------------------------
# 2. PAINEL MENSAL + COVARIAVEIS (balanceado p/ Synth)
# ------------------------------------------------------------
df_main <- read_excel(path_main) %>%
  select(data, municipio_nome, id_municipio, admissoes_por_mil) %>%
  mutate(periodo = as.integer(format(as.Date(data), "%Y")) * 12L +
                   as.integer(format(as.Date(data), "%m")))
df_nomes <- df_main %>% select(id_municipio, municipio_nome) %>% distinct()

cov <- read_excel(path_cov) %>%
  select(id_municipio, any_of(vars_estrut)) %>% distinct() %>%
  mutate(across(any_of(vars_estrut), num))
vars_presentes <- intersect(vars_estrut, names(cov))
# cov_ok definido ADIANTE (secao 3), apos conhecer os tratados: so covariaveis
# nao-faltantes p/ TODOS os tratados entram como preditores (Synth nao aceita NA).

# painel balanceado: so periodos presentes em TODOS os municipios
pc <- df_main %>% group_by(periodo) %>%
  summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
  filter(n == max(n)) %>% pull(periodo)
pan <- df_main %>% filter(periodo %in% pc) %>%
  left_join(cov, by = "id_municipio") %>%
  arrange(id_municipio, periodo) %>%
  as.data.frame()
periodos_pre <- sort(unique(pan$periodo[pan$periodo < periodo_intervencao]))
periodos_pos <- sort(unique(pan$periodo[pan$periodo >= periodo_intervencao]))
# lags do desfecho usados como special.predictors (grade trimestral no pre)
lags_pre <- periodos_pre[seq(1, length(periodos_pre), by = 3)]
cat(sprintf(">> painel: %d periodos (%d pre / %d pos) | lags preditores: %d\n",
            length(pc), length(periodos_pre), length(periodos_pos), length(lags_pre)))

# ------------------------------------------------------------
# 3. CRITERIO POPULACIONAL
# ------------------------------------------------------------
muprs <- read_excel(path_muprs) %>%
  transmute(cod6 = as.integer(round(num(`Código IBGE`))),
            prop_pop = num(Pop_Atingidos) / num(Pop_Total))
df_dano <- df_nomes %>%
  mutate(cod6 = as.integer(id_municipio %/% 10L)) %>%
  left_join(muprs, by = "cod6") %>%
  mutate(prop_pop = coalesce(prop_pop, 0))
ids_tratados <- df_dano$id_municipio[df_dano$prop_pop >  POP_THRESH]
ids_doadores <- setdiff(df_dano$id_municipio[df_dano$prop_pop <= LIMIAR_DOADOR], ids_tratados)

# cov_ok = covariaveis NAO-faltantes para TODOS os tratados (Synth nao aceita NA
# nos preditores). As que faltam em algum tratado sao descartadas com aviso;
# os lags do desfecho (special.predictors) seguem sendo os preditores centrais.
na_trat <- cov %>% filter(id_municipio %in% ids_tratados) %>%
  summarise(across(all_of(vars_presentes), ~ sum(is.na(.x))))
cov_ok   <- vars_presentes[as.numeric(na_trat[1, ]) == 0]
cov_fora <- setdiff(vars_presentes, cov_ok)
if (length(cov_fora))
  cat(sprintf(">> covariaveis DESCARTADAS (faltam em algum tratado): %s\n",
              paste(cov_fora, collapse = ", ")))
if (length(cov_ok) == 0)
  cat(">> AVISO: nenhuma covariavel completa p/ todos tratados; usando so lags do desfecho\n")

# doadores precisam ter cov_ok completas
if (length(cov_ok))
  ids_doadores <- ids_doadores[ids_doadores %in%
    (pan %>% filter(if_all(all_of(cov_ok), ~ !is.na(.x))) %>% pull(id_municipio) %>% unique())]
cat(sprintf(">> tratados: %d | doadores (cov completa): %d | preditores cov: %s\n",
            length(ids_tratados), length(ids_doadores),
            if (length(cov_ok)) paste(cov_ok, collapse = ",") else "(nenhuma)"))

# ------------------------------------------------------------
# 4. UM AJUSTE SC CLASSICO (retorna gaps + RMSPE)
# ------------------------------------------------------------
rodar_sc <- function(id_trat, ids_ctrl) {
  special <- lapply(lags_pre, function(p) list("admissoes_por_mil", p, "mean"))
  dp <- dataprep(
    foo = pan, dependent = "admissoes_por_mil",
    unit.variable = "id_municipio", time.variable = "periodo",
    predictors = if (length(cov_ok)) cov_ok else NULL, predictors.op = "mean",
    time.predictors.prior = periodos_pre,
    special.predictors = special,
    treatment.identifier = id_trat, controls.identifier = ids_ctrl,
    time.optimize.ssr = periodos_pre, time.plot = c(periodos_pre, periodos_pos))
  so <- synth(dp, verbose = FALSE)
  y_tr <- as.numeric(dp$Y1plot)
  y_sc <- as.numeric(dp$Y0plot %*% so$solution.w)
  gap  <- y_tr - y_sc
  idx_pre <- seq_along(periodos_pre); idx_pos <- length(periodos_pre) + seq_along(periodos_pos)
  rmspe_pre <- sqrt(mean(gap[idx_pre]^2)); rmspe_pos <- sqrt(mean(gap[idx_pos]^2))
  list(gap = gap, y_tr = y_tr, y_sc = y_sc, w = so$solution.w,
       att = mean(gap[idx_pos]), rmspe_pre = rmspe_pre, rmspe_pos = rmspe_pos,
       ratio = rmspe_pos / rmspe_pre)
}

# ------------------------------------------------------------
# 5. TRATADOS + PLACEBO-IN-SPACE
# ------------------------------------------------------------
tempos <- c(periodos_pre, periodos_pos)
rotular_tri <- function(v) { a <- v %/% 12L; m <- v %% 12L; m <- ifelse(m==0,12,m); a <- ifelse(v%%12==0,a-1,a)
  sprintf("%d-%02d", a, m) }

res_trat <- list(); gaps_plot <- list()
for (idt in ids_tratados) {
  nome <- (df_nomes %>% filter(id_municipio == idt) %>% pull(municipio_nome))[1]
  fit  <- tryCatch(rodar_sc(idt, ids_doadores), error = function(e) {cat("  ERRO", nome, conditionMessage(e), "\n"); NULL})
  if (is.null(fit)) next
  res_trat[[as.character(idt)]] <- tibble(
    id_municipio = idt, municipio_nome = nome,
    att_sc_classico = fit$att, rmspe_pre = fit$rmspe_pre,
    rmspe_pos = fit$rmspe_pos, ratio_rmspe = fit$ratio)
  gaps_plot[[nome]] <- tibble(periodo = tempos, gap = fit$gap, municipio = nome)
  cat(sprintf("  [trat] %-18s ATT=%7.3f RMSPE pre=%.3f pos=%.3f ratio=%.2f\n",
              nome, fit$att, fit$rmspe_pre, fit$rmspe_pos, fit$ratio))
}
tab_trat <- bind_rows(res_trat)

# placebo: amostra de doadores como "tratados" (pool = demais doadores)
set.seed(20240501)
doad_placebo <- if (length(ids_doadores) > N_PLACEBO) sample(ids_doadores, N_PLACEBO) else ids_doadores
cat(sprintf("\n>> placebo-in-space em %d doadores...\n", length(doad_placebo)))
ratios_placebo <- future_lapply(doad_placebo, function(j) {
  f <- tryCatch(rodar_sc(j, setdiff(ids_doadores, j)), error = function(e) NULL)
  if (is.null(f)) return(NA_real_); f$ratio
}, future.seed = TRUE, future.packages = c("Synth"))
ratios_placebo <- unlist(ratios_placebo); ratios_placebo <- ratios_placebo[!is.na(ratios_placebo)]

# p-valor por municipio tratado = proporcao de placebos com ratio >= ratio do tratado
tab_trat <- tab_trat %>%
  rowwise() %>%
  mutate(p_placebo = mean(ratios_placebo >= ratio_rmspe),
         n_placebos = length(ratios_placebo)) %>% ungroup()

cat("\n=== SC CLASSICO — TRATADOS (criterio populacional) ===\n")
print(as.data.frame(tab_trat), digits = 3, row.names = FALSE)
write.csv(tab_trat, file.path(dir_saida, "sc_classico_tratados.csv"), row.names = FALSE)
write.csv(tibble(ratio = ratios_placebo),
          file.path(dir_saida, "sc_classico_placebo_ratios.csv"), row.names = FALSE)

# ------------------------------------------------------------
# 6. PLOT DE GAPS (tratados) + COMPARACAO COM synthdid/sc_estimate
# ------------------------------------------------------------
gaps_df <- bind_rows(gaps_plot)
p_gaps <- ggplot(gaps_df, aes(periodo, gap)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray60") +
  geom_vline(xintercept = periodo_intervencao, linetype = 3, color = "red") +
  geom_line(color = "#1b7837") + facet_wrap(~ municipio, scales = "free_y") +
  scale_x_continuous(labels = rotular_tri) +
  labs(title = "SC classico (Abadie) — gap tratado vs sintetico",
       subtitle = "Preditores: lags do desfecho + covariaveis estruturais; linha vermelha = maio/2024",
       x = NULL, y = "gap (admissoes por mil)") +
  theme_minimal()
ggsave(file.path(dir_saida, "sc_classico_gaps.png"), p_gaps, width = 11, height = 7, dpi = 200)

# comparacao com synthdid/sc_estimate (le tabela do criterio populacional se existir)
path_pop <- file.path(dir_base, "SDID criterio pop_cnpj", "tabela_consolidada_pop_cnpj.csv")
cat("\n>> para comparar com synthdid/sc_estimate, cruzar com as tabelas de\n   Resultados/SDID criterio*/ (coluna att, att_sc).\n")

plan(sequential)
cat("\nConcluido. Saidas em:", dir_saida, "\n")
