# =============================================================================
# 00_run_all.R — Orquestrador do pipeline Seguro-Desemprego (ARIMA causal)
# Rodar da RAIZ do repositório:
#   Rscript Artigos/Seguro_Desemprego_ARIMA/scripts/00_run_all.R
# =============================================================================

sc <- function(f) file.path("Artigos/Seguro_Desemprego_ARIMA/scripts", f)
passos <- c("01_import.R", "01b_import_caged.R", "02_explore.R",
            "03_arima_intervencao.R", "04_causalimpact.R", "05_triangulacao.R",
            "06_causalimpact_controle.R", "07_taxa_habilitacao.R")

t0 <- Sys.time()
for (p in passos) {
  cat("\n==========================================================\n")
  cat(">> ", p, "\n")
  cat("==========================================================\n")
  source(sc(p), echo = FALSE)
}

# ---- Verificação de outputs -------------------------------------------------
out <- "Artigos/Seguro_Desemprego_ARIMA/outputs"
esperados <- c(
  file.path(out, "serie_brasil.csv"),
  file.path(out, "painel_uf.csv"),
  file.path(out, "controle_caged.csv"),
  file.path(out, "tabelas/triangulacao_efeitos.csv"),
  file.path(out, "tabelas/comparacao_controle.csv"),
  file.path(out, "tabelas/taxa_habilitacao.csv"),
  file.path(out, "figuras/10_taxa_habilitacao.png"),
  file.path(out, "figuras/01_serie_requerentes.png"),
  file.path(out, "figuras/06_causalimpact_lei2015.png"),
  file.path(out, "figuras/08_triangulacao_forest.png"),
  file.path(out, "figuras/09_causalimpact_lei2015_controle.png")
)
faltando <- esperados[!file.exists(esperados)]
cat("\n\n===== VERIFICAÇÃO =====\n")
if (length(faltando) == 0) {
  cat("OK — todos os outputs esperados foram gerados.\n")
} else {
  cat("FALTANDO:\n"); cat(paste0("  - ", faltando, collapse = "\n"), "\n")
}
cat(sprintf("Tempo total: %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
