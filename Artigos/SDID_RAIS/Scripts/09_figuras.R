# =============================================================================
# 09_figuras.R — Figuras da analise setorial:
#   (1) Forest plot: ATT por Secao CNAE, uma faceta por municipio-alvo
#   (2) Curva de recuperacao: efeito estimado por periodo pos-tratamento
#       (synthdid_effect_curve), por municipio x setor
#   (3) Composicao setorial (vinculos por mil) ao longo do tempo, 2021-2025
# =============================================================================

library(dplyr)
library(ggplot2)

final_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Final")
resultados_dir <- here::here("Artigos", "SDID_RAIS", "Resultados")
figuras_dir <- file.path(resultados_dir, "figuras")
dir.create(figuras_dir, recursive = TRUE, showWarnings = FALSE)

DATA_TRATAMENTO <- as.Date("2024-05-01")

# Tema simples, sem cinza padrao do ggplot2 (INV-12) -- paleta provisoria,
# harmonizar depois com o padrao visual do artigo original se necessario.
tema_setor <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

cor_negativo <- "#b91c1c"
cor_positivo <- "#15803d"
cor_neutro   <- "#525252"

resultados <- readRDS(file.path(resultados_dir, "sdid_por_setor_resultados_completos.rds"))
tabela_sdid <- readRDS(file.path(resultados_dir, "sdid_por_setor_tabela.rds"))
cnae_dir <- readRDS(here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw", "cnae_diretorio_secao.rds")) %>%
  distinct(secao, descricao_secao)

# ---- (1) Forest plot: ATT por Secao, faceta por municipio ------------------
# Rotulo = so a letra da Secao (descricao completa fica na tabela CSV/tex --
# texto longo nao cabe no eixo com 6 facetas). Ordenacao por ATT DENTRO de
# cada municipio via um id de linha global (reorder() sozinho reordenaria
# globalmente, já que a mesma letra de Secao se repete em varios municipios).
dados_forest <- tabela_sdid %>%
  mutate(
    sinal = case_when(
      ci_perm_high < 0 ~ "negativo",
      ci_perm_low > 0 ~ "positivo",
      TRUE ~ "n.s."
    )
  ) %>%
  arrange(municipio, att) %>%
  mutate(row_id = row_number())

p_forest <- ggplot(dados_forest, aes(x = att, y = factor(row_id))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = cor_neutro) +
  geom_errorbar(aes(xmin = ci_perm_low, xmax = ci_perm_high, color = sinal), width = 0.3) +
  geom_point(aes(color = sinal), size = 2) +
  scale_y_discrete(breaks = dados_forest$row_id, labels = dados_forest$secao) +
  scale_color_manual(values = c(
    "negativo" = cor_negativo, "positivo" = cor_positivo, "n.s." = cor_neutro
  )) +
  facet_wrap(~municipio, scales = "free_y", ncol = 2) +
  labs(
    x = "ATT (admissoes por mil habitantes)", y = "Secao CNAE", color = "IC 95% (perm.)",
    title = "Efeito da enchente de maio/2024 sobre admissoes, por Secao CNAE",
    caption = "Descricao completa de cada Secao: tabela_sdid_por_setor.csv"
  ) +
  tema_setor()

ggsave(
  file.path(figuras_dir, "forest_att_por_setor.png"),
  p_forest, width = 11, height = 12, bg = "transparent", dpi = 150
)

# ---- (2) Curvas de recuperacao (effect curve) por celula -------------------
curvas_df <- bind_rows(lapply(resultados, function(r) {
  curva <- r$curva_efeito
  if (is.null(curva) || length(curva) < 2 || !is.numeric(curva)) return(NULL)
  tibble::tibble(
    id_municipio = r$resumo$id_municipio,
    municipio = r$resumo$municipio,
    secao = r$resumo$secao,
    periodo_pos = seq_along(curva),
    efeito = as.numeric(curva)
  )
}))

if (nrow(curvas_df) > 0) {
  curvas_df <- curvas_df %>% left_join(cnae_dir, by = "secao")

  p_recuperacao <- ggplot(curvas_df, aes(x = periodo_pos, y = efeito, color = secao)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = cor_neutro) +
    geom_line(linewidth = 0.7) +
    geom_point(size = 1.2) +
    facet_wrap(~municipio, scales = "free") +
    labs(
      x = "Meses desde maio/2024 (tratamento)", y = "Efeito estimado (admissoes/mil)",
      color = "Secao CNAE",
      title = "Dinamica de recuperacao por setor apos a enchente"
    ) +
    tema_setor()

  ggsave(
    file.path(figuras_dir, "curva_recuperacao_por_setor.png"),
    p_recuperacao, width = 13, height = 8, bg = "transparent", dpi = 150
  )
}

# ---- (3) Composicao setorial ao longo do tempo (vinculos por mil) ---------
nomes_alvo <- c(
  "4306767" = "Eldorado do Sul", "4312609" = "Mucum", "4315800" = "Roca Sales",
  "4300851" = "Arambare", "4321626" = "Travesseiro", "4310108" = "Igrejinha"
)

estoque <- readRDS(file.path(final_dir, "painel_estoque_anual_secao.rds")) %>%
  filter(tratado) %>%
  left_join(cnae_dir, by = "secao") %>%
  mutate(municipio = nomes_alvo[id_municipio])

p_composicao <- ggplot(estoque, aes(x = ano, y = vinculos_por_mil, fill = secao)) +
  geom_col(position = "stack") +
  geom_vline(xintercept = 2024, linetype = "dashed", color = "white", linewidth = 0.8) +
  facet_wrap(~municipio, scales = "free_y") +
  labs(
    x = "Ano", y = "Vinculos ativos por mil habitantes", fill = "Secao CNAE",
    title = "Composicao setorial do emprego formal, municipios-alvo (2021-2025)"
  ) +
  tema_setor()

ggsave(
  file.path(figuras_dir, "composicao_setorial_2021_2025.png"),
  p_composicao, width = 13, height = 8, bg = "transparent", dpi = 150
)

message("Figuras salvas em: ", figuras_dir)
