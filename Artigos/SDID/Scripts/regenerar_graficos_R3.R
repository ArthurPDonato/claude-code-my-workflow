# ============================================================
#  regenerar_graficos_R3.R
#  Regenera os gráficos das Figs 3, 5, 8 e 9 sem título,
#  subtítulo, nota de rodapé ou legenda desnecessária,
#  conforme revisão R3 (junho/2026).
#
#  Figs afetadas:
#   Fig 3  — sensibilidade_forest.png  (sem título/subtítulo/nota)
#   Fig 5  — event_study_twfe_todos.png (sem título/subtítulo/legenda/nota)
#   Fig 8  — triangulacao_saldo_forest.png (sem título; remove legenda
#             de cor; mantém legenda de forma/inferência)
#   Fig 9  — municipio_*_adm_vs_saldo.png individuais (sem título/legenda)
#             [REQUER base de saldo — ver seção 4 abaixo]
# ============================================================

library(tidyverse)
library(readxl)
library(synthdid)

# ── Caminhos base ────────────────────────────────────────────────────────────
dir_local  <- "C:/Users/TutuSurfer/meu-projeto"
dir_res    <- file.path(dir_local, "Artigos/SDID/Resultados")
dir_final  <- file.path(dir_local, "Artigos/SDID/Base de Dados/Final")

path_main <- file.path(dir_final, "BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx")
path_cov  <- file.path(dir_final, "Covariaveis_SDID_Final.xlsx")

dir_sens   <- file.path(dir_res, "SDID sensibilidade pool")
dir_evt    <- file.path(dir_res, "SDID event study twfe")
dir_saldo  <- file.path(dir_res, "SDID robustez saldo")

for (d in c(dir_sens, dir_evt, dir_saldo))
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# ── Parâmetros ───────────────────────────────────────────────────────────────
periodo_intervencao <- 2024L * 12L + 5L   # mai/2024
LIMIAR_BASELINE     <- 0.005
ids_tratados <- c(4306767L, 4312609L, 4315800L, 4300851L, 4321626L, 4310108L)
ids_sens     <- c(4306767L, 4312609L, 4315800L, 4321626L)   # ES, Muçum, RS, Travesseiro
LIMIARES_SENSIB <- c(0.005, 0.01, 0.05, 0.10)               # 0.5%, 1%, 5%, 10%

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

# ── Leitura dos dados ────────────────────────────────────────────────────────
df_cov  <- read_excel(path_cov)
df_main <- read_excel(path_main) %>%
  select(data, municipio_nome, id_municipio, admissoes_por_mil) %>%
  mutate(periodo = as.integer(format(as.Date(data), "%Y")) * 12L +
           as.integer(format(as.Date(data), "%m")))

df_nomes <- df_main %>% select(id_municipio, municipio_nome) %>% distinct()
df_cov_pool <- df_cov %>%
  filter(proporcao_atingidos <= LIMIAR_BASELINE,
         !(id_municipio %in% ids_tratados)) %>%
  pull(id_municipio) %>%
  intersect(unique(df_main$id_municipio))

# Funções auxiliares
montar_painel <- function(df_fonte, ids_modelo) {
  dfp <- df_fonte %>%
    filter(id_municipio %in% ids_modelo) %>%
    select(id_municipio, periodo, admissoes_por_mil) %>% drop_na()
  periodos_comuns <- dfp %>% group_by(periodo) %>%
    summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
    filter(n == n_distinct(dfp$id_municipio)) %>% pull(periodo)
  dfp %>% filter(periodo %in% periodos_comuns)
}

att_sdid_rapido <- function(df_panel, ids_alvo, periodo_int) {
  df <- df_panel %>%
    rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
    mutate(treated = as.integer(unit %in% ids_alvo & time >= periodo_int)) %>%
    as.data.frame()
  s <- panel.matrices(df, "unit", "time", "outcome", "treated")
  as.numeric(synthdid_estimate(s$Y, s$N0, s$T0))
}

pool_por_limiar <- function(limiar) {
  df_cov %>%
    filter(proporcao_atingidos <= limiar, !(id_municipio %in% ids_tratados)) %>%
    pull(id_municipio) %>%
    intersect(unique(df_main$id_municipio))
}

# ============================================================
# 1. FIG 3 — Sensibilidade do ATT (sem título/subtítulo/nota de rodapé)
# ============================================================
cat("\n=== FIG 3: Sensibilidade ===\n")

labels_limiar <- c(
  "0.005" = "0,5% (baseline)",
  "0.01"  = "1%",
  "0.05"  = "5%",
  "0.1"   = "10%"
)
cores_limiar <- c(
  "0,5% (baseline)" = "#1b9e77",
  "1%"              = "#d95f02",
  "5%"              = "#7570b3",
  "10%"             = "#e7298a"
)

lista_sens <- list()
for (limiar in LIMIARES_SENSIB) {
  pool <- pool_por_limiar(limiar)
  cat(sprintf("  limiar=%.1f%%  pool=%d\n", limiar * 100, length(pool)))
  for (id_trat in ids_sens) {
    nome <- (df_nomes %>% filter(id_municipio == id_trat) %>% pull(municipio_nome))[1]
    ids_c <- intersect(pool, unique(df_main$id_municipio))
    df_p  <- montar_painel(df_main, c(id_trat, ids_c))
    df_setup <- df_p %>%
      rename(unit = id_municipio, time = periodo, outcome = admissoes_por_mil) %>%
      mutate(treated = as.integer(unit == id_trat & time >= periodo_intervencao)) %>%
      as.data.frame()
    s <- tryCatch(panel.matrices(df_setup, "unit", "time", "outcome", "treated"),
                  error = function(e) NULL)
    if (is.null(s)) next
    tau <- tryCatch(synthdid_estimate(s$Y, s$N0, s$T0), error = function(e) NULL)
    if (is.null(tau)) next
    att_val <- as.numeric(tau)
    perm_taus <- map_dbl(seq_len(s$N0), function(j) {
      Y_perm <- s$Y[c(setdiff(seq_len(s$N0), j), nrow(s$Y), j), ]
      tryCatch(as.numeric(synthdid_estimate(Y_perm, s$N0, s$T0)), error = function(e) NA_real_)
    })
    perm_taus <- perm_taus[!is.na(perm_taus)]
    med <- median(perm_taus)
    q   <- quantile(perm_taus - med, c(0.025, 0.975))
    ic_inf <- att_val + q[1]; ic_sup <- att_val + q[2]
    lista_sens[[length(lista_sens) + 1]] <- tibble(
      municipio_nome = nome,
      limiar_txt     = labels_limiar[as.character(limiar)],
      n_pool         = length(ids_c),
      att            = att_val,
      ic_inf         = ic_inf,
      ic_sup         = ic_sup,
      ic_exclui_zero = (ic_inf < 0 & ic_sup < 0)
    )
  }
}

df_sens <- bind_rows(lista_sens) %>%
  mutate(
    municipio_nome = factor(municipio_nome, levels = c("Eldorado do Sul","Muçum","Roca Sales","Travesseiro")),
    limiar_txt     = factor(limiar_txt, levels = c("0,5% (baseline)","1%","5%","10%")),
    rotulo         = sprintf("%s\n(%s)", municipio_nome, limiar_txt)
  )

p_sens <- ggplot(df_sens, aes(att, limiar_txt, color = limiar_txt)) +
  facet_wrap(~ municipio_nome, scales = "free_x", ncol = 2) +
  geom_vline(xintercept = 0, linetype = 2, color = "gray55") +
  geom_errorbar(aes(xmin = ic_inf, xmax = ic_sup), width = 0.3, linewidth = 0.9, orientation = "y") +
  geom_point(aes(shape = ic_exclui_zero), size = 3.5) +
  scale_color_manual(values = cores_limiar, name = "Limiar pool doador") +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1),
                     labels = c(`TRUE` = "IC exclui zero", `FALSE` = "IC inclui zero"),
                     name = NULL) +
  labs(title = NULL, subtitle = NULL,
       x = "ATT (admissões por mil hab./mês)", y = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom",
        strip.text      = element_text(face = "bold"),
        legend.box      = "vertical")

ggsave(file.path(dir_sens, "sensibilidade_forest.png"), p_sens,
       width = 10, height = 8, dpi = 300)
cat("  → sensibilidade_forest.png salvo.\n")

# ============================================================
# 2. FIG 5 — Estudo de Evento TWFE-DiD (sem título/subtítulo/legenda/nota)
# ============================================================
cat("\n=== FIG 5: Estudo de Evento TWFE-DiD ===\n")

if (!requireNamespace("fixest", quietly = TRUE)) install.packages("fixest")
library(fixest)

df_twfe <- df_main %>%
  mutate(
    tratado    = as.integer(id_municipio %in% ids_tratados),
    rel_time   = periodo - periodo_intervencao,
    rel_time_f = factor(rel_time)
  ) %>%
  filter(rel_time >= -12L, rel_time <= 11L)

df_twfe$rel_time_f <- relevel(df_twfe$rel_time_f, ref = "-1")

mod_evt <- feols(admissoes_por_mil ~ i(rel_time_f, tratado, ref = "-1") |
                   id_municipio + periodo,
                 data    = df_twfe,
                 cluster = ~id_municipio)

coefs <- coeftable(mod_evt) %>%
  as_tibble(rownames = "term") %>%
  filter(str_detect(term, "rel_time_f")) %>%
  mutate(
    k         = as.integer(str_extract(term, "-?\\d+")),
    periodo   = ifelse(k >= 0, "pós-tratamento", "pré-tratamento"),
    ic_inf    = Estimate - 1.96 * `Std. Error`,
    ic_sup    = Estimate + 1.96 * `Std. Error`,
    sig       = ic_inf > 0 | ic_sup < 0
  ) %>%
  bind_rows(tibble(term = "ref", k = -1L, Estimate = 0, `Std. Error` = 0,
                   periodo = "pré-tratamento", ic_inf = 0, ic_sup = 0, sig = FALSE))

cores_evt <- c("pós-tratamento" = "#C0392B", "pré-tratamento" = "gray55")

p_evt <- ggplot(coefs, aes(k, Estimate, color = periodo, fill = periodo)) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray40") +
  geom_vline(xintercept = -0.5, color = "steelblue", linewidth = 0.7) +
  geom_ribbon(aes(ymin = ic_inf, ymax = ic_sup), alpha = 0.18, color = NA) +
  geom_line(linewidth = 0.9) +
  geom_point(aes(shape = sig), size = 2.8) +
  scale_color_manual(values = cores_evt, guide = "none") +
  scale_fill_manual(values  = cores_evt, guide = "none") +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1), guide = "none") +
  scale_x_continuous(breaks = seq(-12, 11, 2),
                     labels = function(x) ifelse(x == 0, "mai/2024",
                                                 num_para_data_texto(periodo_intervencao + x))) +
  labs(title = NULL, subtitle = NULL,
       x = "Mês relativo ao tratamento (0 = maio/2024)",
       y = "Efeito estimado (admissões por mil hab./mês)") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x     = element_text(angle = 30, hjust = 1))

ggsave(file.path(dir_evt, "event_study_twfe_todos.png"), p_evt,
       width = 11, height = 6, dpi = 300)
cat("  → event_study_twfe_todos.png salvo.\n")

# ============================================================
# 3. FIG 8 — Triangulação saldo (sem título; sem legenda de cor; mantém forma)
# ============================================================
cat("\n=== FIG 8: Triangulação Saldo ===\n")

csv_saldo <- file.path(dir_saldo, "triangulacao_saldo.csv")
if (!file.exists(csv_saldo)) stop("triangulacao_saldo.csv não encontrado em ", dir_saldo)

tri_saldo <- read.csv(csv_saldo)

ordem_muns <- c("Eldorado do Sul","Muçum","Roca Sales","Arambaré","Travesseiro","Igrejinha")

tri_long <- bind_rows(
  tri_saldo %>% transmute(
    municipio_nome, modelo = "SDiD",
    att = att_sdid, ic_inf = ic_sdid_inf, ic_sup = ic_sdid_sup,
    sig = sig_sdid, inferencia = "Permutação\ndireta"
  ),
  tri_saldo %>% transmute(
    municipio_nome, modelo = "SC",
    att = att_sc, ic_inf = ic_sc_inf, ic_sup = ic_sc_sup,
    sig = sig_sc, inferencia = "Permutação\ndireta"
  ),
  tri_saldo %>% transmute(
    municipio_nome, modelo = "TWFE-DiD",
    att = att_did, ic_inf = ic_did_inf, ic_sup = ic_did_sup,
    sig = sig_did, inferencia = "Gaussiano\n(EP cluster)"
  )
) %>%
  mutate(
    modelo         = factor(modelo, levels = c("TWFE-DiD","SC","SDiD")),
    municipio_nome = factor(municipio_nome, levels = ordem_muns)
  )

p_saldo_forest <- ggplot(tri_long, aes(att, modelo, color = sig, shape = inferencia)) +
  facet_wrap(~ municipio_nome, scales = "free_x", ncol = 3) +
  geom_vline(xintercept = 0, linetype = 2, color = "gray55") +
  geom_errorbar(aes(xmin = ic_inf, xmax = ic_sup), width = 0.25,
                linewidth = 0.9, orientation = "y") +
  geom_point(size = 3.2) +
  scale_color_manual(
    values = c(`TRUE` = "#C0392B", `FALSE` = "#7F8C8D"),
    guide  = "none"
  ) +
  scale_shape_manual(
    values = c("Permutação\ndireta" = 16, "Gaussiano\n(EP cluster)" = 17),
    name   = "Inferência"
  ) +
  labs(title = NULL, subtitle = NULL,
       x = "Efeito estimado (saldo por mil hab. por mês)", y = NULL) +
  theme_minimal() +
  theme(legend.position  = "bottom",
        strip.text       = element_text(face = "bold"))

ggsave(file.path(dir_saldo, "triangulacao_saldo_forest.png"), p_saldo_forest,
       width = 12, height = 8, dpi = 300)
cat("  → triangulacao_saldo_forest.png salvo.\n")

# ============================================================
# 4. FIG 9 — Painel adm_vs_saldo individuais (sem título/legenda)
#    REQUER: variável de saldo na base de dados.
#    O arquivo BASE_FINAL não contém saldo_por_mil.
#    Forneça o caminho para a base com saldo e descomente o código abaixo.
# ============================================================
cat("\n=== FIG 9: Painel adm_vs_saldo (stub — requer base de saldo) ===\n")

# path_saldo_base <- "G:/Meu Drive/.../BASE_COM_SALDO.xlsx"
# df_saldo_raw <- read_excel(path_saldo_base) %>%
#   select(data, municipio_nome, id_municipio, admissoes_por_mil, saldo_por_mil) %>%
#   mutate(periodo = as.integer(format(as.Date(data), "%Y")) * 12L +
#            as.integer(format(as.Date(data), "%m")))
#
# gerar_adm_vs_saldo_png <- function(id_trat, df_saldo_raw, ids_pool, dir_out) {
#   nome_trat <- (df_nomes %>% filter(id_municipio == id_trat) %>% pull(municipio_nome))[1]
#   ids_c <- ids_pool
#   df_p <- df_saldo_raw %>%
#     filter(id_municipio %in% c(id_trat, ids_c)) %>%
#     select(id_municipio, periodo, admissoes_por_mil, saldo_por_mil) %>% drop_na()
#   periodos_ok <- df_p %>% group_by(periodo) %>%
#     summarise(n = n_distinct(id_municipio), .groups = "drop") %>%
#     filter(n == n_distinct(df_p$id_municipio)) %>% pull(periodo)
#   df_p <- df_p %>% filter(periodo %in% periodos_ok)
#
#   fazer_traj <- function(var_col, cor_obs, titulo_y) {
#     df_setup <- df_p %>%
#       transmute(unit = id_municipio, time = periodo,
#                 outcome = .data[[var_col]],
#                 treated = as.integer(unit == id_trat & time >= periodo_intervencao)) %>%
#       as.data.frame()
#     s   <- panel.matrices(df_setup, "unit","time","outcome","treated")
#     tau <- synthdid_estimate(s$Y, s$N0, s$T0)
#     att_val <- as.numeric(tau)
#     w_omega <- attr(tau,"weights")$omega
#     sc_traj <- as.numeric(t(w_omega) %*% s$Y[seq_len(s$N0),])
#     obs_traj <- s$Y[nrow(s$Y),]
#     periodos_num <- as.integer(colnames(s$Y))
#     df_traj <- tibble(periodo = periodos_num,
#                       observado = as.numeric(obs_traj),
#                       sintetico = as.numeric(sc_traj))
#     ggplot(df_traj, aes(periodo)) +
#       geom_vline(xintercept = periodo_intervencao - 0.5, linetype = 2, color = "gray40") +
#       geom_line(aes(y = sintetico), color = "gray50", linetype = "dashed", linewidth = 0.9) +
#       geom_line(aes(y = observado), color = cor_obs, linewidth = 1) +
#       annotate("text", x = max(periodos_num) - 2, y = max(obs_traj) * 0.97,
#                label = sprintf("ATT = %.2f", att_val), size = 3, hjust = 1) +
#       scale_x_continuous(labels = num_para_data_texto) +
#       labs(title = NULL, subtitle = NULL, x = NULL, y = titulo_y) +
#       theme_minimal() + theme(legend.position = "none")
#   }
#   p_adm  <- fazer_traj("admissoes_por_mil", "#1f78b4", "Admissões formais por mil hab./mês")
#   p_sald <- fazer_traj("saldo_por_mil",     "#e31a1c", "Saldo líquido por mil hab./mês")
#   p_comb <- p_adm + p_sald + patchwork::plot_layout(ncol = 2)
#   out <- file.path(dir_out, sprintf("municipio_%d_adm_vs_saldo.png", id_trat))
#   ggsave(out, p_comb, width = 14, height = 5, dpi = 300)
#   cat("  →", basename(out), "salvo.\n")
# }
#
# ids_pool_completo <- df_cov %>%
#   filter(proporcao_atingidos <= LIMIAR_BASELINE, !(id_municipio %in% ids_tratados)) %>%
#   pull(id_municipio) %>% intersect(unique(df_saldo_raw$id_municipio))
#
# if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
# for (id_trat in ids_tratados)
#   gerar_adm_vs_saldo_png(id_trat, df_saldo_raw, ids_pool_completo, dir_saldo)

cat("  Fig 9: forneça path_saldo_base e descomente o código para regenerar.\n")
cat("\nConcluído.\n")
