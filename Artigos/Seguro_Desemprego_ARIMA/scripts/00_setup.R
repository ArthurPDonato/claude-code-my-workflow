# =============================================================================
# 00_setup.R — Verifica e instala pacotes necessários para o projeto
# Seguro-Desemprego: ARIMA de intervenção + CausalImpact (triangulação)
# =============================================================================

req <- c(
  "readxl",       # leitura do .xlsx do MTE
  "dplyr", "tidyr", "readr", "stringr",  # manipulação
  "lubridate", "zoo",                    # datas / séries
  "ggplot2", "scales",                   # gráficos
  "forecast", "tseries",                 # SARIMA, ADF/KPSS
  "TSA",                                 # arimax (Box-Tiao transfer function)
  "CausalImpact"                         # BSTS bayesiano
)

inst <- rownames(installed.packages())
faltando <- setdiff(req, inst)

cat("Pacotes instalados:\n")
for (p in req) cat(sprintf("  %-14s %s\n", p, ifelse(p %in% inst, "OK", "FALTA")))

if (length(faltando) > 0) {
  cat("\nInstalando:", paste(faltando, collapse = ", "), "\n")
  install.packages(faltando, repos = "https://cloud.r-project.org")
} else {
  cat("\nTodos os pacotes disponíveis.\n")
}
