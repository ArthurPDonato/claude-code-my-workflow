# =============================================================================
# 03_arima_intervencao.R — ARIMA de intervenção sobre os requerentes (Brasil)
#
# DUAS abordagens complementares:
#  (A) ITS por CONTRAFACTUAL (principal): ajusta SARIMA só no pré-intervenção,
#      projeta o contrafactual e mede o efeito = observado − previsto.
#      Estimando idêntico ao do CausalImpact -> triangulação apples-to-apples.
#  (B) Box-Tiao com dummies (robustez): SARIMA com regressores de intervenção.
#      Ressalva: sob série d=1 o DEGRAU de nível é mal identificado; por isso
#      é secundária. O PULSO da COVID, esse sim, é bem estimado por (B).
#
# Intervenções:
#   Lei 13.134/2015 -> 2015-07 ; janela de avaliação encerra ANTES da COVID.
#   COVID/2020      -> 2020-03 ; janela aguda de 12 meses.
# =============================================================================

suppressMessages({ library(forecast); library(dplyr); library(ggplot2); library(scales) })

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
d  <- readRDS(here("outputs", "serie_brasil.rds"))
sb <- d$serie_brasil; y <- d$ts_req; iv <- d$intervencoes
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")
dts <- sb$data

idx <- function(dt) which(dts == dt)                     # posição do mês
win <- function(a, b) idx(a):idx(b)

# ---- (A) ITS por contrafactual ---------------------------------------------
its_contrafactual <- function(pre_ini, pre_fim, ev_ini, ev_fim, rotulo) {
  ip <- win(pre_ini, pre_fim); ie <- win(ev_ini, ev_fim)
  y_pre <- ts(sb$requerentes[ip], frequency = 12,
              start = c(as.integer(format(pre_ini, "%Y")), as.integer(format(pre_ini, "%m"))))
  fit <- auto.arima(y_pre, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
  fc  <- forecast(fit, h = length(ie), level = 95)
  obs <- sb$requerentes[ie]
  cf  <- as.numeric(fc$mean); lo <- as.numeric(fc$lower); hi <- as.numeric(fc$upper)
  efeito_t <- obs - cf
  data.frame(
    intervencao = rotulo,
    modelo      = as.character(fit),
    n_pre = length(ip), n_ev = length(ie),
    efeito_medio = mean(efeito_t),
    efeito_medio_ic_inf = mean(obs - hi),   # obs − limite sup do contrafactual
    efeito_medio_ic_sup = mean(obs - lo),
    efeito_pct   = 100 * mean(efeito_t) / mean(cf),
    efeito_acum  = sum(efeito_t),
    stringsAsFactors = FALSE
  ) -> res
  attr(res, "serie") <- data.frame(data = dts[ie], obs = obs, cf = cf, lo = lo, hi = hi)
  attr(res, "fit") <- fit
  res
}

A_lei   <- its_contrafactual(as.Date("2000-01-01"), as.Date("2015-06-01"),
                             as.Date("2015-07-01"), as.Date("2020-02-01"), "Lei 13.134/2015")
A_covid <- its_contrafactual(as.Date("2000-01-01"), as.Date("2020-02-01"),
                             as.Date("2020-03-01"), as.Date("2021-02-01"), "COVID/2020")
A <- bind_rows(A_lei, A_covid)

# ---- (B) Box-Tiao com dummies (robustez) -----------------------------------
step2015    <- as.numeric(dts >= iv$lei_13134)
covid_spike <- as.numeric(dts >= as.Date("2020-04-01") & dts <= as.Date("2020-06-01"))
covid_step  <- as.numeric(dts >= iv$covid_2020)
xreg <- cbind(step2015 = step2015, covid_spike = covid_spike, covid_step = covid_step)
fitB <- auto.arima(y, xreg = xreg, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
coB <- coef(fitB); seB <- sqrt(diag(fitB$var.coef))
B <- data.frame(termo = colnames(xreg),
                coef = coB[colnames(xreg)], se = seB[colnames(xreg)],
                ic_inf = coB[colnames(xreg)] - 1.96 * seB[colnames(xreg)],
                ic_sup = coB[colnames(xreg)] + 1.96 * seB[colnames(xreg)])

# ---- Saída de texto ---------------------------------------------------------
sink(file.path(tab, "arima_intervencao.txt"))
cat("=== (A) ITS por CONTRAFACTUAL — efeito = observado − contrafactual ===\n\n")
print(A[, c("intervencao","modelo","n_pre","n_ev","efeito_medio",
            "efeito_medio_ic_inf","efeito_medio_ic_sup","efeito_pct","efeito_acum")],
      row.names = FALSE, digits = 5)
cat("\n\n=== (B) Box-Tiao com dummies (robustez) ===\n")
cat("Modelo:", as.character(fitB), "\n")
cat("Ressalva: sob d=1 o DEGRAU (step2015/covid_step) é mal identificado;\n",
    "o PULSO (covid_spike) é confiável.\n\n")
print(B, row.names = FALSE, digits = 5)
cat("\nLjung-Box (B):\n"); print(checkresiduals(fitB, plot = FALSE))
sink()

saveRDS(list(A = A, A_lei = A_lei, A_covid = A_covid, B = B, fitB = fitB),
        here("outputs", "arima_fit.rds"))

# ---- Gráfico do contrafactual (Lei 2015) -----------------------------------
plot_cf <- function(res, titulo, arq) {
  s <- attr(res, "serie")
  p <- ggplot(s, aes(data)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#c00000", alpha = 0.15) +
    geom_line(aes(y = cf), color = "#c00000", linetype = "dashed", linewidth = 0.5) +
    geom_line(aes(y = obs), color = "#1f4e79", linewidth = 0.5) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    labs(title = titulo,
         subtitle = "Observado (azul) vs. contrafactual ARIMA (vermelho tracejado, IC 95%)",
         x = NULL, y = "Requerentes/mês", caption = "Fonte: BGSD/MTE") +
    theme_minimal(base_size = 11)
  ggsave(arq, p, width = 9, height = 4.5, dpi = 150)
}
plot_cf(A_lei,   "ITS contrafactual — Lei 13.134/2015", file.path(fig, "04_its_lei2015.png"))
plot_cf(A_covid, "ITS contrafactual — COVID/2020",      file.path(fig, "05_its_covid.png"))

cat("03_arima OK.\n"); print(A[, c("intervencao","efeito_medio","efeito_medio_ic_inf",
                                    "efeito_medio_ic_sup","efeito_pct")], row.names = FALSE)
