# ============================================================
#  SDiD — HETEROGENEIDADE POR SETOR (CNAE)   (sugestao da banca, item 5)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Pergunta da banca: QUAIS setores puxaram a queda do emprego formal apos a
#  enchente? Estima o SDiD do criterio populacional (6 tratados vs 278 doadores
#  donut) separadamente para cada SECAO CNAE, usando admissoes da secao por mil
#  habitantes, e ranqueia os setores pelo ATT.
#
#  DADO (em casa, sem download): Base de Dados/Primarias/Base_Mensal_CNAE_RS_Final.csv
#    admissoes mensais por secao CNAE x municipio, 2007-2025, 497 municipios RS.
#
#  DECISOES:
#   - Janela 2020+ (serie "Novo"): evita a quebra CAGED Antigo(ate 2019)/Novo(2020+).
#     Sobram ~52 meses de pre-tratamento ate abril/2024.
#   - Desfecho: admissoes_secao_mes / PopMun * 1000. A base so tem linhas com
#     admissao > 0 => completa-se a grade (muni x mes x secao) com ZERO (ausencia
#     de registro = 0 admissoes naquele setor-mes, que e informativo p/ um fluxo).
#   - Criterio populacional (pop>50%), igual ao artigo; evento maio/2024.
#   - SDiD + triangulacao SC/DiD + permutacao donut (sdid-conventions.md).
#
#  AMBIENTE: R 4.4.2 (tem synthdid).
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/sdid_setorial_cnae.R
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
ANO_MIN             <- 2020L               # serie "Novo" (evita quebra CAGED)
POP_THRESH          <- 0.50
LIMIAR_DOADOR       <- 0.005
periodo_intervencao <- 2024L * 12L + 5L    # maio/2024 (mensal: ano*12+mes)
MIN_ADM_POOL        <- 200L                # secao so entra se o pool tem >= isto de admissoes totais (evita setores raros)

# Rotulos das secoes CNAE 2.0 (A-U)
SECAO_LABEL <- c(
  A="Agropecuaria", B="Ind. extrativa", C="Ind. transformacao", D="Eletricidade/gas",
  E="Agua/esgoto", F="Construcao", G="Comercio", H="Transporte", I="Aloj./alimentacao",
  J="Informacao/comunic.", K="Financeiro", L="Imobiliario", M="Prof./cientifico",
  N="Adm./serv. apoio", O="Adm. publica", P="Educacao", Q="Saude", R="Arte/cultura",
  S="Outros servicos", T="Servicos domesticos", U="Org. internacionais")

dir_base  <- "Artigos/SDID/Resultados"
dir_saida <- file.path(dir_base, "SDID setorial CNAE")
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

path_cnae  <- "Artigos/SDID/Base de Dados/Primárias/Base_Mensal_CNAE_RS_Final.csv"
path_muprs <- "Artigos/SDID/Base de Dados/Primárias/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"

num <- function(x) suppressWarnings(as.numeric(str_replace_all(as.character(x), ",", ".")))

# ------------------------------------------------------------
# 2. LEITURA + CRITERIO POPULACIONAL
# ------------------------------------------------------------
cnae <- read_csv(path_cnae, show_col_types = FALSE) %>%
  filter(ano >= ANO_MIN) %>%
  transmute(id_municipio = as.integer(id_municipio),
            municipio_nome, secao = cnae_2_secao,
            periodo = as.integer(ano) * 12L + as.integer(mes),
            adm = as.numeric(total_admissoes_secao_mes))
df_nomes <- cnae %>% select(id_municipio, municipio_nome) %>% distinct()

muprs <- read_excel(path_muprs) %>%
  transmute(cod6 = as.integer(round(num(`Código IBGE`))),
            prop_pop = num(Pop_Atingidos) / num(Pop_Total),
            PopMun   = num(Pop_Total))
df_dano <- df_nomes %>%
  mutate(cod6 = as.integer(id_municipio %/% 10L)) %>%
  left_join(muprs, by = "cod6") %>%
  mutate(prop_pop = coalesce(prop_pop, 0))

ids_tratados <- df_dano$id_municipio[df_dano$prop_pop >  POP_THRESH]
ids_doadores <- setdiff(df_dano$id_municipio[df_dano$prop_pop <= LIMIAR_DOADOR], ids_tratados)
# doadores/tratados precisam de PopMun (denominador)
ids_pool <- c(ids_tratados, ids_doadores)
ids_pool <- ids_pool[ids_pool %in% (df_dano %>% filter(!is.na(PopMun) & PopMun > 0) %>% pull(id_municipio))]
ids_tratados <- intersect(ids_tratados, ids_pool)
ids_doadores <- intersect(ids_doadores, ids_pool)
pop_lookup <- df_dano %>% filter(id_municipio %in% ids_pool) %>% select(id_municipio, PopMun)

periodos_win <- sort(unique(cnae$periodo))
cat(sprintf(">> janela: %d meses (%d-%02d a %d-%02d) | tratados: %d | doadores: %d\n",
            length(periodos_win), min(periodos_win)%/%12, min(periodos_win)%%12,
            max(periodos_win)%/%12, ((max(periodos_win)-1)%%12)+1,
            length(ids_tratados), length(ids_doadores)))

# secoes elegiveis: admissoes totais no pool >= MIN_ADM_POOL
cob <- cnae %>% filter(id_municipio %in% ids_pool) %>%
  group_by(secao) %>% summarise(adm_pool = sum(adm), .groups = "drop") %>%
  arrange(desc(adm_pool))
secoes_alvo <- cob$secao[cob$adm_pool >= MIN_ADM_POOL]
cat(">> secoes elegiveis (adm pool >=", MIN_ADM_POOL, "):",
    paste(secoes_alvo, collapse = ", "), "\n")

# ------------------------------------------------------------
# 3. FUNCOES SDiD (desfecho = admissoes da secao por mil hab.)
# ------------------------------------------------------------
# grade completa (muni x periodo) para UMA secao, ausencia = 0 admissoes
painel_secao <- function(sec, ids_modelo) {
  grade <- expand_grid(id_municipio = ids_modelo, periodo = periodos_win)
  obs <- cnae %>% filter(secao == sec, id_municipio %in% ids_modelo) %>%
    select(id_municipio, periodo, adm)
  grade %>% left_join(obs, by = c("id_municipio", "periodo")) %>%
    mutate(adm = coalesce(adm, 0)) %>%
    left_join(pop_lookup, by = "id_municipio") %>%
    transmute(id_municipio, periodo, outcome = adm / PopMun * 1000)
}
calcular_rmspe_pre <- function(tau_hat, setup) {
  w <- attr(tau_hat, "weights"); omega <- w$omega; lambda <- w$lambda
  Y <- setup$Y; N0 <- setup$N0; T0 <- setup$T0
  serie_tr <- colMeans(Y[(N0 + 1):nrow(Y), , drop = FALSE])
  serie_sc <- as.numeric(t(omega) %*% Y[1:N0, , drop = FALSE])
  gap <- (serie_tr - serie_sc)[1:T0]; off <- sum(lambda * gap)
  sqrt(mean((gap - off)^2))
}
estimar <- function(dfp, ids_alvo) {
  d <- dfp %>% rename(unit = id_municipio, time = periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
  s <- panel.matrices(d, "unit", "time", "outcome", "treated")
  tau <- synthdid_estimate(s$Y, s$N0, s$T0)
  se  <- as.numeric(sqrt(vcov(tau, method = "placebo")))
  list(att = as.numeric(tau), se = se, n0 = s$N0,
       att_sc = as.numeric(sc_estimate(s$Y, s$N0, s$T0)),
       att_did = as.numeric(did_estimate(s$Y, s$N0, s$T0)),
       rmspe_pre = calcular_rmspe_pre(tau, s))
}
att_rapido <- function(dfp, ids_alvo) {
  d <- dfp %>% rename(unit = id_municipio, time = periodo) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
  s <- panel.matrices(d, "unit", "time", "outcome", "treated")
  as.numeric(synthdid_estimate(s$Y, s$N0, s$T0))
}

# ------------------------------------------------------------
# 4. UMA SECAO: multi-ATT + triangulacao + permutacao donut
# ------------------------------------------------------------
analisar_secao <- function(sec) {
  dfp <- painel_secao(sec, c(ids_tratados, ids_doadores))
  em  <- estimar(dfp, ids_tratados)
  # placebo-in-space: painel so de doadores (uma vez), cada doador vira tratado
  dfp_d <- painel_secao(sec, ids_doadores)
  taus <- vapply(ids_doadores, function(j)
    tryCatch(att_rapido(dfp_d, j), error = function(e) NA_real_), numeric(1))
  taus <- taus[!is.na(taus)]
  tibble(secao = sec, setor = unname(SECAO_LABEL[sec]),
         att = em$att, ep = em$se, ic_inf = em$att - 1.96*em$se, ic_sup = em$att + 1.96*em$se,
         att_sc = em$att_sc, att_did = em$att_did, rmspe_pre = em$rmspe_pre,
         n_placebos = length(taus), p_permutacao = mean(abs(taus) >= abs(em$att)),
         significativo = (em$att - 1.96*em$se) < 0 & (em$att + 1.96*em$se) < 0)
}

cat("\n>> estimando", length(secoes_alvo), "secoes (paralelo)...\n")
res <- future_lapply(secoes_alvo, function(s)
  tryCatch(analisar_secao(s), error = function(e) {
    tibble(secao = s, setor = unname(SECAO_LABEL[s]), att = NA_real_, erro = conditionMessage(e))}),
  future.seed = TRUE,
  future.packages = c("dplyr","tidyr","purrr","tibble","synthdid"))
tab <- bind_rows(res) %>% arrange(att)

cat("\n=== HETEROGENEIDADE SETORIAL (CNAE) — ATT por setor (admissoes/mil) ===\n")
print(as.data.frame(tab %>% select(secao, setor, att, ic_inf, ic_sup, att_sc, att_did,
                                   p_permutacao, significativo)), digits = 3, row.names = FALSE)
write.csv(tab, file.path(dir_saida, "setorial_cnae_att.csv"), row.names = FALSE)

# forest plot por setor
tf <- tab %>% filter(!is.na(att)) %>%
  mutate(rotulo = fct_reorder(sprintf("%s (%s)", setor, secao), att),
         status = ifelse(significativo, "Negativo sig. (IC<0)", "Nao sig."))
p <- ggplot(tf, aes(rotulo, att, color = status)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray50") +
  geom_pointrange(aes(ymin = ic_inf, ymax = ic_sup), linewidth = 0.7, size = 0.5) +
  coord_flip() +
  scale_color_manual(values = c("Negativo sig. (IC<0)" = "#1b7837", "Nao sig." = "gray55")) +
  labs(title = "Efeito da enchente por setor (CNAE) — criterio populacional",
       subtitle = "SDiD multi-ATT; janela 2020+; admissoes da secao por mil hab.",
       x = NULL, y = "ATT (admissoes/mil)", color = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_saida, "setorial_cnae_forest.png"), p, width = 10, height = 7, dpi = 200)

plan(sequential)
cat("\nConcluido. Saidas em:", dir_saida, "\n")
