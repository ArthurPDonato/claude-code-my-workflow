# =============================================================================
# 02_explore.R — Análise exploratória da série BRASIL de requerentes
#   - Gráfico da série com as duas intervenções marcadas
#   - Decomposição STL (tendência / sazonalidade / resíduo)
#   - ACF/PACF (nível, 1ª diferença, diferença sazonal)
#   - Testes de estacionariedade (ADF, KPSS)
# =============================================================================

suppressMessages({
  library(dplyr); library(ggplot2); library(scales)
  library(forecast); library(tseries)
})

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
d <- readRDS(here("outputs", "serie_brasil.rds"))
sb <- d$serie_brasil; ts_req <- d$ts_req; iv <- d$intervencoes
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

# ---- 1) Série com intervenções ---------------------------------------------
p1 <- ggplot(sb, aes(data, requerentes)) +
  geom_line(color = "#1f4e79", linewidth = 0.5) +
  geom_vline(xintercept = as.numeric(iv$lei_13134),  linetype = "dashed", color = "#c00000") +
  geom_vline(xintercept = as.numeric(iv$covid_2020), linetype = "dashed", color = "#7030a0") +
  annotate("text", x = iv$lei_13134,  y = max(sb$requerentes), label = "Lei 13.134/2015",
           hjust = 1.05, size = 3, color = "#c00000") +
  annotate("text", x = iv$covid_2020, y = max(sb$requerentes), label = "COVID/2020",
           hjust = -0.05, size = 3, color = "#7030a0") +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(title = "Requerentes do Seguro-Desemprego — Brasil (2000–2025)",
       x = NULL, y = "Requerentes/mês", caption = "Fonte: BGSD/MTE") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig, "01_serie_requerentes.png"), p1, width = 9, height = 4.5, dpi = 150)

# ---- 2) Decomposição STL ----------------------------------------------------
stl_fit <- stl(ts_req, s.window = "periodic")
png(file.path(fig, "02_stl_decomposicao.png"), width = 900, height = 700, res = 110)
plot(stl_fit, main = "Decomposição STL — Requerentes (Brasil)")
dev.off()

# ---- 3) ACF / PACF ----------------------------------------------------------
png(file.path(fig, "03_acf_pacf.png"), width = 1000, height = 700, res = 110)
op <- par(mfrow = c(3, 2), mar = c(4, 4, 2, 1))
Acf(ts_req, main = "ACF — nível");                       Pacf(ts_req, main = "PACF — nível")
Acf(diff(ts_req), main = "ACF — 1a dif");                Pacf(diff(ts_req), main = "PACF — 1a dif")
Acf(diff(diff(ts_req), 12), main = "ACF — 1a dif + dif sazonal")
Pacf(diff(diff(ts_req), 12), main = "PACF — 1a dif + dif sazonal")
par(op); dev.off()

# ---- 4) Estacionariedade ----------------------------------------------------
sink(file.path(tab, "estacionariedade.txt"))
cat("=== Testes de estacionariedade — requerentes (Brasil) ===\n\n")
cat(">> ADF (H0: raiz unitária / não estacionária)\n")
print(suppressWarnings(adf.test(ts_req)))
cat("\n>> KPSS (H0: estacionária)\n")
print(suppressWarnings(kpss.test(ts_req)))
cat("\n>> nº de diferenças sugerido (ndiffs):", ndiffs(ts_req), "\n")
cat(">> nº de diferenças sazonais (nsdiffs):", nsdiffs(ts_req), "\n")
sink()

cat("02_explore OK — figuras e testes gravados.\n")
cat("  ndiffs =", ndiffs(ts_req), "| nsdiffs =", nsdiffs(ts_req), "\n")
