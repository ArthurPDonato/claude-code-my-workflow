# =============================================================================
# 08_tabelas.R — Tabelas da analise setorial:
#   (1) Resultados SDID por Secao CNAE (celulas com N >= N_MIN, causal)
#   (2) Celulas abaixo do limiar (so descritivo, sem estimativa causal)
#   (3) Composicao setorial pre vs pos-enchente (vinculos ativos por Secao)
# =============================================================================

library(dplyr)
library(tidyr)

final_dir <- here::here("Artigos", "SDID_RAIS", "Base de Dados", "Final")
resultados_dir <- here::here("Artigos", "SDID_RAIS", "Resultados")

N_MIN <- 50L
nomes_alvo <- c(
  "4306767" = "Eldorado do Sul", "4312609" = "Mucum", "4315800" = "Roca Sales",
  "4300851" = "Arambare", "4321626" = "Travesseiro", "4310108" = "Igrejinha"
)

cnae_dir <- readRDS(here::here("Artigos", "SDID_RAIS", "Base de Dados", "Raw", "cnae_diretorio_secao.rds")) %>%
  distinct(secao, descricao_secao)

# ---- (1) Resultados SDID (causal) ------------------------------------------
tabela_sdid <- readRDS(file.path(resultados_dir, "sdid_por_setor_tabela.rds")) %>%
  mutate(
    sig = case_when(
      p_permutacao < 0.01 ~ "***",
      p_permutacao < 0.05 ~ "**",
      p_permutacao < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

readr::write_csv(tabela_sdid, file.path(resultados_dir, "tabela_sdid_por_setor.csv"))

linhas_sdid <- tabela_sdid %>%
  mutate(linha = sprintf(
    "%s & %s & %.3f%s & [%.3f, %.3f] & %.3f & %d \\\\\\\\",
    municipio, descricao_secao, att, sig, ci_perm_low, ci_perm_high,
    p_permutacao, n_donors
  )) %>%
  pull(linha)

writeLines(
  c(
    "% Gerado por 08_tabelas.R -- resultados SDID por Secao CNAE",
    "\\begin{tabular}{llrrrr}",
    "\\hline",
    "Munic\\'{i}pio & Se\\c{c}\\~{a}o & ATT & IC 95\\% (perm.) & p (perm.) & N doadores \\\\",
    "\\hline",
    linhas_sdid,
    "\\hline",
    "\\end{tabular}"
  ),
  file.path(resultados_dir, "tabela_sdid_por_setor.tex")
)

# ---- (2) Celulas abaixo do limiar (descritivo, sem SDID) -------------------
cobertura_alvo <- readRDS(file.path(final_dir, "cobertura_secoes_alvo.rds"))

celulas_modeladas <- tabela_sdid %>% distinct(id_municipio, secao)

tabela_descritiva_abaixo_limiar <- cobertura_alvo %>%
  anti_join(celulas_modeladas, by = c("id_municipio", "secao")) %>%
  left_join(cnae_dir, by = "secao") %>%
  mutate(municipio = nomes_alvo[id_municipio]) %>%
  select(municipio, secao, descricao_secao, total_admissoes) %>%
  arrange(municipio, desc(total_admissoes))

message(sprintf(
  "%d combinacoes municipio x secao abaixo do limiar N_MIN=%d (so descritivo).",
  nrow(tabela_descritiva_abaixo_limiar), N_MIN
))

readr::write_csv(
  tabela_descritiva_abaixo_limiar,
  file.path(resultados_dir, "tabela_descritiva_abaixo_limiar.csv")
)

# ---- (3) Composicao setorial: pre (2023, ultimo ano cheio pre-enchente) ----
# vs pos (2025, ano mais recente disponivel) -- vinculos ativos por Secao,
# como % do total do municipio-alvo naquele ano.
estoque <- readRDS(file.path(final_dir, "painel_estoque_anual_secao.rds"))

composicao <- estoque %>%
  filter(tratado, ano %in% c(2023, 2025)) %>%
  group_by(id_municipio, ano) %>%
  mutate(share_vinculos = vinculos_ativos / sum(vinculos_ativos)) %>%
  ungroup() %>%
  left_join(cnae_dir, by = "secao") %>%
  mutate(municipio = nomes_alvo[id_municipio]) %>%
  select(municipio, secao, descricao_secao, ano, vinculos_ativos, share_vinculos) %>%
  pivot_wider(
    names_from = ano, values_from = c(vinculos_ativos, share_vinculos),
    names_sep = "_"
  ) %>%
  mutate(
    variacao_share_pp = (share_vinculos_2025 - share_vinculos_2023) * 100
  ) %>%
  arrange(municipio, desc(abs(variacao_share_pp)))

readr::write_csv(
  composicao,
  file.path(resultados_dir, "tabela_composicao_setorial_2023_2025.csv")
)

message("Tabelas salvas em: ", resultados_dir)
