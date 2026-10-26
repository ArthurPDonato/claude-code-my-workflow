# ============================================================
#  SDiD COM CONTROLES DE FORA DO RS (matching Mahalanobis)  (item 3 da banca)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Pergunta da banca: usar municipios de FORA do RS como controle, selecionados
#  por caracteristicas (propensity/Mahalanobis), em vez do donut RS.
#
#  Desenho:
#   - Tratados: 6 municipios RS do criterio populacional (prop_pop>0.5, MUPRS).
#   - Candidatos: municipios NAO-RS com covariaveis completas e painel balanceado.
#   - Matching: distancia de MAHALANOBIS ao CENTROIDE dos tratados, nas covariaveis
#     fundamentadas na literatura (quality_reports/item3_covariaveis_literatura.md):
#       resumo do pre de admissoes/mil (media + tendencia)  [Abadie: preditor nº1]
#       shares setoriais (agro/ind/serv), log-pop, PIB pc, IDHM.
#     -> seleciona os N_DOADORES mais proximos.
#   - SDiD (tratados + doadores pareados) + triangulacao SC/DiD + permutacao.
#   - Compara com o baseline do artigo (donut RS, ATT ~ -2.4 a -3.5).
#
#  ENTRADA: Final/caged_nacional_mensal.csv + Final/covariaveis_nacional.csv
#           (de caged_nacional_download.R) + MUPRS (tratados).
#  AMBIENTE: R 4.4.2 (synthdid). Deterministico; set.seed por seguranca.
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/sdid_fora_rs_psm.R
# ============================================================

suppressMessages({
  library(tidyverse); library(readxl); library(synthdid); library(future.apply)
})
set.seed(20240501)
N_WORKERS <- max(1L, parallel::detectCores())
plan(multisession, workers = N_WORKERS)

# ------------------------------------------------------------
# 1. PARAMETROS
# ------------------------------------------------------------
N_DOADORES          <- 40L
POP_THRESH          <- 0.50
periodo_intervencao <- 2024L * 12L + 5L     # maio/2024
# covariaveis de matching (resumo do pre e adicionado adiante)
VARS_COV <- c("share_agro","share_ind","share_serv","log_pop","pib_pc","idhm")

dir_base  <- "Artigos/SDID/Resultados"
dir_saida <- file.path(dir_base, "SDID fora do RS PSM")
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

path_panel <- "Artigos/SDID/Base de Dados/Final/caged_nacional_mensal.csv"
path_cov   <- "Artigos/SDID/Base de Dados/Final/covariaveis_nacional.csv"
path_muprs <- "Artigos/SDID/Base de Dados/Primárias/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"
num <- function(x) suppressWarnings(as.numeric(str_replace_all(as.character(x), ",", ".")))

# ------------------------------------------------------------
# 2. LEITURA + PAINEL BALANCEADO (grade completa, ausencia = 0 admissoes)
# ------------------------------------------------------------
pan0 <- read_csv(path_panel, show_col_types = FALSE) %>%
  mutate(periodo = as.integer(ano) * 12L + as.integer(mes))
periodos_win <- sort(unique(pan0$periodo))
cov_nac <- read_csv(path_cov, show_col_types = FALSE) %>%
  mutate(log_pop = log(populacao))

# tratados (MUPRS pop>50%)
muprs <- read_excel(path_muprs) %>%
  transmute(cod6 = as.integer(round(num(`Código IBGE`))),
            prop_pop = num(Pop_Atingidos) / num(Pop_Total))
ids_tratados <- pan0 %>% distinct(id_municipio) %>%
  mutate(cod6 = as.integer(id_municipio %/% 10L)) %>%
  left_join(muprs, by = "cod6") %>% filter(prop_pop > POP_THRESH) %>% pull(id_municipio)
cat(sprintf(">> tratados (pop>%.0f%%): %d | janela: %d meses | municipios no painel: %d\n",
            100*POP_THRESH, length(ids_tratados), length(periodos_win), n_distinct(pan0$id_municipio)))

# grade completa p/ um conjunto de ids (ausencia = 0 adm; usa pop p/ por mil)
completar <- function(ids) {
  expand_grid(id_municipio = ids, periodo = periodos_win) %>%
    left_join(pan0 %>% select(id_municipio, periodo, admissoes_por_mil),
              by = c("id_municipio","periodo")) %>%
    mutate(admissoes_por_mil = coalesce(admissoes_por_mil, 0))
}

# ------------------------------------------------------------
# 3. RESUMO DO PRE (media + tendencia) — preditor nº1 (Abadie)
# ------------------------------------------------------------
pre <- periodos_win[periodos_win < periodo_intervencao]
resumo_pre <- completar(unique(pan0$id_municipio)) %>%
  filter(periodo %in% pre) %>%
  group_by(id_municipio) %>%
  summarise(mean_pre = mean(admissoes_por_mil),
            trend_pre = coef(lm(admissoes_por_mil ~ I(periodo - min(pre))))[2],
            .groups = "drop")

# ------------------------------------------------------------
# 4. MATCHING MAHALANOBIS ao centroide dos tratados
# ------------------------------------------------------------
sig_uf <- cov_nac %>% select(id_municipio, sigla_uf)
base_match <- cov_nac %>%
  left_join(resumo_pre, by = "id_municipio") %>%
  mutate(across(all_of(c(VARS_COV,"mean_pre","trend_pre")), as.numeric))

# covariaveis completas p/ TODOS os tratados -> conjunto usado
vars_all <- c("mean_pre","trend_pre", VARS_COV)
na_trat <- base_match %>% filter(id_municipio %in% ids_tratados) %>%
  summarise(across(all_of(vars_all), ~ sum(is.na(.x))))
vars_use <- vars_all[as.numeric(na_trat[1,]) == 0]
cat(">> covariaveis de matching usadas:", paste(vars_use, collapse=", "), "\n")

# candidatos: NAO-RS, covariaveis completas, presentes no painel
ids_balanceados <- pan0 %>% count(id_municipio) %>% pull(id_municipio)  # tem alguma obs
cand <- base_match %>%
  filter(sigla_uf != "RS", id_municipio %in% ids_balanceados) %>%
  filter(if_all(all_of(vars_use), ~ !is.na(.x)))
cat(sprintf(">> candidatos nao-RS com covariaveis completas: %d\n", nrow(cand)))

# padronizar (z) usando candidatos + tratados; Mahalanobis via cov dessa base
trat_cov <- base_match %>% filter(id_municipio %in% ids_tratados)
M <- as.matrix(bind_rows(cand, trat_cov) %>% select(all_of(vars_use)))
mu <- colMeans(M); sdv <- apply(M, 2, sd)
Z  <- scale(M, center = mu, scale = sdv)
S  <- cov(Z); Sinv <- MASS::ginv(S)
z_cand <- Z[seq_len(nrow(cand)), , drop = FALSE]
z_trat <- Z[(nrow(cand)+1):nrow(Z), , drop = FALSE]
centro <- colMeans(z_trat)
d_maha <- apply(z_cand, 1, function(x) sqrt(t(x - centro) %*% Sinv %*% (x - centro)))
cand$dist <- as.numeric(d_maha)
doadores <- cand %>% arrange(dist) %>% slice_head(n = N_DOADORES)
ids_doadores <- doadores$id_municipio
cat(sprintf(">> %d doadores pareados selecionados (UFs: %s)\n",
            length(ids_doadores), paste(sort(unique(doadores$sigla_uf)), collapse=", ")))
write_csv(doadores %>% select(id_municipio, sigla_uf, dist, all_of(vars_use)),
          file.path(dir_saida, "doadores_pareados.csv"))

# ------------------------------------------------------------
# 5. SDiD (tratados + doadores pareados)
# ------------------------------------------------------------
montar_painel <- function(ids) {
  dfp <- completar(ids) %>% rename(outcome = admissoes_por_mil)
  pc <- dfp %>% group_by(periodo) %>% summarise(n = n_distinct(id_municipio), .groups="drop") %>%
    filter(n == n_distinct(dfp$id_municipio)) %>% pull(periodo)
  dfp %>% filter(periodo %in% pc)
}
calcular_rmspe_pre <- function(tau, s) {
  w <- attr(tau,"weights"); om <- w$omega; la <- w$lambda; Y<-s$Y; N0<-s$N0; T0<-s$T0
  st <- colMeans(Y[(N0+1):nrow(Y),,drop=FALSE]); ss <- as.numeric(t(om)%*%Y[1:N0,,drop=FALSE])
  g <- (st-ss)[1:T0]; sqrt(mean((g - sum(la*g))^2))
}
estimar <- function(dfp, ids_alvo) {
  d <- dfp %>% rename(unit=id_municipio, time=periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
  s <- panel.matrices(d, "unit","time","outcome","treated")
  tau <- synthdid_estimate(s$Y, s$N0, s$T0); se <- as.numeric(sqrt(vcov(tau, method="placebo")))
  list(att=as.numeric(tau), se=se, n0=s$N0, t0=s$T0, t1=ncol(s$Y)-s$T0,
       att_sc=as.numeric(sc_estimate(s$Y,s$N0,s$T0)), att_did=as.numeric(did_estimate(s$Y,s$N0,s$T0)),
       rmspe_pre=calcular_rmspe_pre(tau,s))
}
att_rapido <- function(dfp, ids_alvo) {
  d <- dfp %>% rename(unit=id_municipio, time=periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
  s <- panel.matrices(d,"unit","time","outcome","treated"); as.numeric(synthdid_estimate(s$Y,s$N0,s$T0))
}

dfp_all <- montar_painel(c(ids_tratados, ids_doadores))
em <- estimar(dfp_all, ids_tratados)

# por municipio tratado (permutacao donut sobre os doadores pareados)
dfp_doad <- montar_painel(ids_doadores)
ind <- future_lapply(ids_tratados, function(idt) {
  dpi <- montar_painel(c(idt, ids_doadores))
  att0 <- att_rapido(dpi, idt)
  taus <- vapply(ids_doadores, function(j) tryCatch(att_rapido(dfp_doad, j), error=function(e) NA_real_), numeric(1))
  taus <- taus[!is.na(taus)]
  tibble(id_municipio=idt, att=att0, p_bilateral=mean(abs(taus)>=abs(att0)),
         ic_inf=att0+quantile(taus-median(taus),.025,names=FALSE),
         ic_sup=att0+quantile(taus-median(taus),.975,names=FALSE))
}, future.seed=TRUE, future.packages=c("dplyr","tidyr","purrr","tibble","synthdid"))
tab_ind <- bind_rows(ind) %>%
  left_join(sig_uf, by="id_municipio") %>%
  mutate(significativo = ic_inf<0 & ic_sup<0) %>% arrange(att)

cat(sprintf("\n=== SDiD FORA DO RS (matching) ===\n>> MULTI ATT=%.3f IC[%.2f;%.2f] SC=%.2f DiD=%.2f RMSPE=%.2f | doad=%d acerto=%d/%d\n",
            em$att, em$att-1.96*em$se, em$att+1.96*em$se, em$att_sc, em$att_did, em$rmspe_pre,
            em$n0, sum(tab_ind$significativo), nrow(tab_ind)))
print(as.data.frame(tab_ind %>% select(id_municipio, att, ic_inf, ic_sup, p_bilateral, significativo)),
      digits=3, row.names=FALSE)

multi <- tibble(escopo="MULTI", att=em$att, ep=em$se, ic_inf=em$att-1.96*em$se, ic_sup=em$att+1.96*em$se,
                att_sc=em$att_sc, att_did=em$att_did, rmspe_pre=em$rmspe_pre, n_doadores=em$n0)
write_csv(tab_ind, file.path(dir_saida, "fora_rs_individual.csv"))
write_csv(multi,   file.path(dir_saida, "fora_rs_multi.csv"))

# forest plot
tf <- bind_rows(
  tab_ind %>% transmute(rotulo=as.character(id_municipio), att, ic_inf, ic_sup, sig=significativo, tipo="Individual"),
  multi %>% transmute(rotulo="MULTI", att, ic_inf, ic_sup, sig=ic_sup<0, tipo="Multi")) %>%
  mutate(rotulo=fct_reorder(rotulo, att),
         status=case_when(tipo=="Multi"~"Multi", sig~"Negativo sig.", TRUE~"Nao sig."))
p <- ggplot(tf, aes(rotulo, att, color=status)) +
  geom_hline(yintercept=0, linetype=2, color="gray50") +
  geom_pointrange(aes(ymin=ic_inf, ymax=ic_sup), linewidth=.7, size=.5) + coord_flip() +
  scale_color_manual(values=c("Negativo sig."="#1b7837","Nao sig."="gray55","Multi"="#D95F0E")) +
  labs(title="SDiD com controles de fora do RS (matching Mahalanobis)",
       subtitle=sprintf("%d doadores nao-RS pareados; admissoes/mil mensais", length(ids_doadores)),
       x=NULL, y="ATT (admissoes/mil)", color=NULL) +
  theme_minimal() + theme(legend.position="bottom")
ggsave(file.path(dir_saida, "fora_rs_forest.png"), p, width=10, height=6, dpi=200)

plan(sequential)
cat("\nConcluido. Saidas em:", dir_saida, "\n")
