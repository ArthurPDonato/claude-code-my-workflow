# ============================================================
#  SWEEP DE LIMIARES DE DANO  (sugestao da banca, item 1)
#  Artigo de targeting (MPU -> RAE). EXERCICIO — nao altera o artigo aceito.
#
#  Pergunta da banca:
#   (1a) Baixando o limiar de "afetados" (50% -> 45/40/35%), ainda encontramos
#        municipios tratados? Quantos, e quais?
#   (1b) Dentro de cada limiar, MUDA a variavel que melhor separa afetados de
#        nao-afetados (doadores donut)?
#   (1c) [gated] Rodar o SDiD nos limiares viaveis (N>=3) — so quando pedido.
#
#  Metodo de separacao: diferenca de media PADRONIZADA (gap_z), identico ao
#  usado em sdid_enchentes_2024_v5.R (secao heterogeneidade). DESCRITIVO.
#
#  AMBIENTE: R 4.4.2 (so precisa de synthdid na parte 1c).
#    "/c/Program Files/R/R-4.4.2/bin/Rscript.exe" Artigos/SDID/Scripts/sdid_sweep_limiares.R
#  Caminhos RELATIVOS a raiz meu-projeto.
# ============================================================

suppressMessages({
  library(tidyverse)
  library(readxl)
})

# ------------------------------------------------------------
# 1. PARAMETROS
# ------------------------------------------------------------
LIMIARES      <- c(0.30, 0.35, 0.40, 0.45, 0.50)   # varredura
METRICAS      <- c(prop_pop = "Pop. afetada",
                   prop_cnpj = "CNPJ afetados",
                   prop_rodovia = "Malha viaria afetada")
METRICA_BASE  <- "prop_pop"        # "afetados" da banca = populacao afetada
LIMIAR_DOADOR <- 0.005             # doador donut (igual aos scripts SDiD)
N_MIN_SDID    <- 3L                # 1c so roda onde N tratados >= isto
RODAR_SDID    <- TRUE              # 1c: multi-ATT + triangulacao + p permutacao, por limiar

dir_base   <- "Artigos/SDID/Resultados"
dir_saida  <- file.path(dir_base, "Relatorio_criterios")
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)

path_main  <- "Artigos/SDID/Base de Dados/Final/BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx"
path_muprs <- "Artigos/SDID/Base de Dados/Primárias/MUPRS_pronto_para_manipular_os_dados (Atingidos Enchente).xlsx"
path_cov   <- "Artigos/SDID/Base de Dados/Final/Covariaveis_SDID_Final.xlsx"

# ------------------------------------------------------------
# 2. LEITURA DAS BASES  (so municipios presentes no painel do artigo)
# ------------------------------------------------------------
num <- function(x) suppressWarnings(as.numeric(str_replace_all(as.character(x), ",", ".")))

df_main <- read_excel(path_main) %>%
  select(data, municipio_nome, id_municipio, admissoes_por_mil)
df_nomes <- df_main %>% select(id_municipio, municipio_nome) %>% distinct()
ids_painel <- df_nomes$id_municipio

muprs <- read_excel(path_muprs) %>%
  transmute(
    cod6         = as.integer(round(num(`Código IBGE`))),
    prop_cnpj    = num(CNPJ_Atingidos) / num(CNPJ_Total),
    prop_rodovia = num(Malha_Rodoviaria_KM_Atingidos) / num(Malha_Rodoviaria_Total),
    prop_pop     = num(Pop_Atingidos) / num(Pop_Total),
    PopMun       = num(Pop_Total))

df_dano <- tibble(id_municipio = ids_painel) %>%
  mutate(cod6 = as.integer(id_municipio %/% 10L)) %>%
  left_join(muprs, by = "cod6") %>%
  mutate(across(c(prop_cnpj, prop_rodovia, prop_pop), ~ coalesce(.x, 0))) %>%
  left_join(df_nomes, by = "id_municipio") %>%
  select(id_municipio, municipio_nome, prop_pop, prop_cnpj, prop_rodovia, PopMun)

# covariaveis estruturais (mesmas da analise de heterogeneidade)
vars_estrut <- c("pib_per_capita_medio", "share_agro_medio", "share_ind_medio",
                 "share_serv_medio", "share_adm_medio", "Idese 2021",
                 "salario_medio_agregado", "operacoes_credito_medio",
                 "total_ativo_medio")
df_cov <- read_excel(path_cov) %>%
  select(id_municipio, any_of(vars_estrut)) %>% distinct() %>%
  mutate(across(any_of(vars_estrut), num))   # Idese/etc. vem como texto (virgula decimal)

cat(sprintf(">> painel do artigo: %d municipios | MUPRS casou dano em %d\n",
            length(ids_painel), sum(df_dano$prop_pop > 0)))

# ============================================================
# 1a. CONTAGEM DE TRATADOS POR METRICA x LIMIAR
# ============================================================
contagem <- expand_grid(metrica = names(METRICAS), limiar = LIMIARES) %>%
  rowwise() %>%
  mutate(
    n_tratados = sum(df_dano[[metrica]] >= limiar, na.rm = TRUE),
    municipios = paste(sort(df_dano$municipio_nome[df_dano[[metrica]] >= limiar]),
                       collapse = "; ")) %>%
  ungroup() %>%
  mutate(rotulo_metrica = METRICAS[metrica]) %>%
  arrange(metrica, limiar)

cat("\n=== 1a. CONTAGEM DE TRATADOS (dano >= limiar) ===\n")
print(as.data.frame(contagem %>% select(rotulo_metrica, limiar, n_tratados)), row.names = FALSE)
write.csv(contagem, file.path(dir_saida, "sweep_limiares_contagem.csv"), row.names = FALSE)

p_cont <- ggplot(contagem, aes(factor(limiar), n_tratados, group = rotulo_metrica,
                               color = rotulo_metrica)) +
  geom_line(linewidth = 0.8) + geom_point(size = 2.4) +
  geom_text(aes(label = n_tratados), vjust = -0.8, size = 3, show.legend = FALSE) +
  labs(title = "Municipios tratados por limiar de dano",
       subtitle = "Quantos municipios tem dano >= limiar, por metrica de triagem",
       x = "Limiar", y = "Nº de municipios tratados", color = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_saida, "sweep_limiares_contagem.png"), p_cont, width = 9, height = 5.5, dpi = 200)

# ============================================================
# 1b. VARIAVEL QUE MELHOR SEPARA TRATADO x DOADOR, POR LIMIAR
#     (metrica base = prop_pop; candidatas = estruturais + as OUTRAS metricas de dano)
# ============================================================
vars_sep <- c(setdiff(names(METRICAS), METRICA_BASE), vars_estrut)  # nao inclui a definidora

base_sep <- df_dano %>% left_join(df_cov, by = "id_municipio")

calc_separacao <- function(limiar) {
  grupo <- base_sep %>%
    mutate(grupo = case_when(
      .data[[METRICA_BASE]] >= limiar         ~ "tratado",
      .data[[METRICA_BASE]] <= LIMIAR_DOADOR  ~ "doador",
      TRUE                                    ~ NA_character_)) %>%
    filter(!is.na(grupo))
  long <- grupo %>%
    pivot_longer(all_of(vars_sep), names_to = "variavel", values_to = "valor") %>%
    group_by(variavel) %>% mutate(z = as.numeric(scale(valor))) %>% ungroup()
  long %>%
    group_by(variavel, grupo) %>%
    summarise(media_z = mean(z, na.rm = TRUE),
              n_valido = sum(!is.na(valor)), .groups = "drop") %>%
    pivot_wider(names_from = grupo, values_from = c(media_z, n_valido)) %>%
    mutate(limiar = limiar,
           n_tratados = sum(grupo$grupo == "tratado"),
           n_doadores = sum(grupo$grupo == "doador"),
           gap_z = media_z_tratado - media_z_doador) %>%
    arrange(desc(abs(gap_z)))
}

separacao <- map_dfr(LIMIARES, calc_separacao)
# leader por limiar
lideres <- separacao %>% group_by(limiar) %>% slice_max(abs(gap_z), n = 1) %>%
  ungroup() %>% select(limiar, n_tratados, n_doadores, variavel_lider = variavel, gap_z_lider = gap_z)

cat("\n=== 1b. VARIAVEL QUE MELHOR SEPARA (base =", METRICA_BASE, ") — lider por limiar ===\n")
print(as.data.frame(lideres), digits = 3, row.names = FALSE)
write.csv(separacao, file.path(dir_saida, "sweep_limiares_separacao.csv"), row.names = FALSE)
write.csv(lideres,   file.path(dir_saida, "sweep_limiares_separacao_lideres.csv"), row.names = FALSE)

p_sep <- ggplot(separacao, aes(reorder(variavel, abs(gap_z)), gap_z, fill = factor(limiar))) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  coord_flip() +
  labs(title = "Poder de separacao tratado x doador por limiar",
       subtitle = sprintf("Diferenca de media padronizada (gap_z); metrica base = %s", METRICA_BASE),
       x = NULL, y = "gap_z (tratado - doador)", fill = "Limiar") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(file.path(dir_saida, "sweep_limiares_separacao.png"), p_sep, width = 10, height = 7, dpi = 200)

# ============================================================
# 1c. SDiD NOS LIMIARES VIAVEIS  (gated: RODAR_SDID)
#     Reusa helpers compactos do motor v5 (synthdid + permutacao donut).
# ============================================================
if (RODAR_SDID) {
  suppressMessages(library(synthdid))
  periodo_intervencao <- 2024L * 12L + 5L

  montar_painel <- function(ids_modelo) {
    dfp <- df_main %>% filter(id_municipio %in% ids_modelo) %>%
      mutate(periodo = as.integer(format(as.Date(data), "%Y")) * 12L +
               as.integer(format(as.Date(data), "%m"))) %>%
      select(id_municipio, periodo, admissoes_por_mil) %>% drop_na()
    pc <- dfp %>% group_by(periodo) %>%
      summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
      filter(n == n_distinct(dfp$id_municipio)) %>% pull(periodo)
    dfp %>% filter(periodo %in% pc)
  }
  att_rapido <- function(dfp, ids_alvo) {
    d <- dfp %>% rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
      mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
    s <- panel.matrices(d, "unit", "time", "outcome", "treated")
    as.numeric(synthdid_estimate(s$Y, s$N0, s$T0))
  }
  # placebo rapido: painel de doadores construido UMA vez; so o rotulo de tratado muda
  att_placebo <- function(dfp_doad, id_alvo) att_rapido(dfp_doad, id_alvo)
  estimar <- function(dfp, ids_alvo) {
    d <- dfp %>% rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
      mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_intervencao)) %>% as.data.frame()
    s <- panel.matrices(d, "unit", "time", "outcome", "treated")
    tau_sdid <- synthdid_estimate(s$Y, s$N0, s$T0)
    se_sdid  <- as.numeric(sqrt(vcov(tau_sdid, method = "placebo")))
    tau_sc   <- sc_estimate(s$Y, s$N0, s$T0)
    tau_did  <- did_estimate(s$Y, s$N0, s$T0)
    list(att = as.numeric(tau_sdid), se = se_sdid, n0 = s$N0,
         att_sc = as.numeric(tau_sc), att_did = as.numeric(tau_did))
  }

  # 1c: por limiar, MULTI-ATT (tratados juntos) + triangulacao SC/DiD +
  #     p-valor por permutacao donut sobre a ESTIMATIVA MULTI (barato: ~N_doad fits).
  res_sdid <- list()
  for (lim in LIMIARES) {
    ids_tr <- df_dano$id_municipio[df_dano[[METRICA_BASE]] >= lim]
    if (length(ids_tr) < N_MIN_SDID) {
      cat(sprintf(">> limiar %.2f: N=%d < %d, pulando SDiD\n", lim, length(ids_tr), N_MIN_SDID)); next
    }
    ids_doad <- setdiff(df_dano$id_municipio[df_dano[[METRICA_BASE]] <= LIMIAR_DOADOR], ids_tr)
    dfp <- montar_painel(c(ids_tr, ids_doad))
    em  <- estimar(dfp, ids_tr)
    # placebo-in-space: painel SO de doadores, construido uma vez; cada doador vira
    # "tratado" (pool = os demais doadores) apenas relabelando (sem re-filtrar o df).
    dfp_doad <- montar_painel(ids_doad)
    taus <- map_dbl(ids_doad, function(j)
      tryCatch(att_placebo(dfp_doad, j), error = function(e) NA_real_))
    taus <- taus[!is.na(taus)]
    p_perm <- mean(abs(taus) >= abs(em$att))
    res_sdid[[as.character(lim)]] <- tibble(
      limiar = lim, metrica = METRICA_BASE, n_tratados = length(ids_tr),
      n_doadores = em$n0, att_multi = em$att, ep_multi = em$se,
      ic_inf = em$att - 1.96*em$se, ic_sup = em$att + 1.96*em$se,
      att_sc = em$att_sc, att_did = em$att_did,
      n_placebos = length(taus), p_permutacao = p_perm)
    cat(sprintf(">> limiar %.2f: N=%d ATT=%.3f IC[%.2f;%.2f] SC=%.2f DiD=%.2f p_perm=%.3f\n",
                lim, length(ids_tr), em$att, em$att-1.96*em$se, em$att+1.96*em$se,
                em$att_sc, em$att_did, p_perm))
  }
  tab_sdid <- bind_rows(res_sdid)
  write.csv(tab_sdid, file.path(dir_saida, "sweep_limiares_sdid.csv"), row.names = FALSE)
  cat("\n=== 1c. SDiD POR LIMIAR (metrica base) ===\n")
  print(as.data.frame(tab_sdid), digits = 3, row.names = FALSE)
}

cat("\nConcluido (1a+1b", if (RODAR_SDID) "+1c" else "", "). Saidas em:\n  ", dir_saida, "\n")
