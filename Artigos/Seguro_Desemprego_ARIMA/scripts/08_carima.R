# =============================================================================
# 08_carima.R — Causal ARIMA (C-ARIMA, Menchetti, Cipollini & Mealli 2023)
#
# Substitui a ITS-contrafactual "manual" do 03 pelo estimador formal C-ARIMA
# (pacote CausalArima): ajusta auto.arima no pré-intervenção, projeta o
# contrafactual e computa o efeito causal (pontual, médio temporal, acumulado)
# com inferência por bootstrap. Triangulado com o CausalImpact (BSTS) do 04/06.
#
# Cenários:
#   1. Lei 13.134/2015, SEM controle  : pré 2000-01..2015-06 ; aval 2015-07..2020-02
#   2. Lei 13.134/2015, COM controle  : idem, xreg=desligamentos ; aval até 2019-12
#                                       (fim do CAGED antigo — evita NA)
#   3. COVID/2020                     : pré 2000-01..2020-02 ; aval 2020-03..2021-02
# =============================================================================

suppressMessages({ library(CausalArima); library(forecast); library(ggplot2); library(scales) })
set.seed(20260704)

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
d    <- readRDS(here("outputs", "serie_brasil.rds"))
sb   <- d$serie_brasil; dts <- as.Date(sb$data); y <- sb$requerentes
ctrl <- readRDS(here("outputs", "controle_caged.rds")); ctrl$data <- as.Date(ctrl$data)
fig  <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")
NB   <- 1000  # réplicas bootstrap

# ---- helper: roda C-ARIMA numa janela e resume o efeito médio temporal -------
run_carima <- function(ini, fim_aval, int.date, rotulo, use_ctrl = FALSE) {
  keep <- dts >= ini & dts <= fim_aval
  yk <- y[keep]; dk <- dts[keep]
  xr <- NULL
  if (use_ctrl) {
    m  <- merge(data.frame(data = dk), ctrl[, c("data","desligamentos")], by = "data", all.x = TRUE)
    xr <- as.matrix(m$desligamentos)
  }
  ce <- CausalArima(y = ts(yk, frequency = 12), dates = dk, int.date = int.date,
                    xreg = xr, nboot = NB)
  ord <- forecast::arimaorder(ce$model)
  # --- inferência bootstrap, computada direto de ce$boot$boot.distrib ---------
  #     (contorna o bug de NSE em CausalArima:::.impact_summary, que lê 'ce'
  #      global em vez de 'x'; aqui replicamos a lógica correta com 'ce').
  post <- ce$dates >= ce$int.date
  y_post <- ce$y[post]; nas <- is.na(y_post)
  y_post <- y_post[!nas]
  fc  <- ce$forecast[!nas]
  sim <- ce$boot$boot.distrib[!nas, , drop = FALSE]   # [n_post x nboot]
  eff_draws <- colMeans(apply(sim, 2, function(z) y_post - z))  # média temporal por réplica
  est <- mean(y_post) - mean(fc)                      # efeito médio temporal
  lo  <- unname(quantile(eff_draws, 0.025))
  hi  <- unname(quantile(eff_draws, 0.975))
  sum_sim <- colSums(sim); sum_y <- sum(y_post)
  p1  <- min(mean(sum_sim >= sum_y), mean(sum_sim <= sum_y))
  pv  <- min(1, 2 * p1)                               # p bidirecional
  cf_mean <- mean(fc)
  res <- data.frame(
    cenario = rotulo,
    modelo  = sprintf("ARIMA(%d,%d,%d)(%d,%d,%d)[%d]", ord[1],ord[2],ord[3],ord[4],ord[5],ord[6],ord[7]),
    controle = ifelse(use_ctrl, "sim (desligamentos)", "nao"),
    efeito_medio = est, ic_inf = lo, ic_sup = hi,
    efeito_pct = 100 * est / cf_mean, p_valor = pv,
    nboot = NB, stringsAsFactors = FALSE
  )
  attr(res, "ce") <- ce
  res
}

# ---- cenários ----------------------------------------------------------------
L_sem  <- run_carima(as.Date("2000-01-01"), as.Date("2020-02-01"), as.Date("2015-07-01"),
                     "Lei 13.134/2015", use_ctrl = FALSE)
L_com  <- run_carima(as.Date("2000-01-01"), as.Date("2019-12-01"), as.Date("2015-07-01"),
                     "Lei 13.134/2015", use_ctrl = TRUE)
Covid  <- run_carima(as.Date("2000-01-01"), as.Date("2021-02-01"), as.Date("2020-03-01"),
                     "COVID/2020", use_ctrl = FALSE)
R <- rbind(L_sem, L_com, Covid)

# ---- saídas texto + csv ------------------------------------------------------
write.csv(R, file.path(tab, "carima_efeitos.csv"), row.names = FALSE)
sink(file.path(tab, "carima.txt"))
cat("=== C-ARIMA (CausalArima) — efeito médio temporal sobre requerentes/mês ===\n")
cat("Inferência:", NB, "réplicas bootstrap; IC 95%.\n\n")
print(R, row.names = FALSE, digits = 6)
cat("\n--- summary completo (sem controle, Lei 2015) ---\n"); print(summary(attr(L_sem,"ce")))
cat("\n--- summary completo (com controle, Lei 2015) ---\n"); print(summary(attr(L_com,"ce")))
sink()
saveRDS(list(L_sem=L_sem, L_com=L_com, Covid=Covid, R=R), here("outputs","carima_fit.rds"))

# ---- figuras: observado vs contrafactual (Lei 2015, sem e com controle) ------
plot_cf <- function(res, titulo, arq, subt) {
  ce <- attr(res, "ce")
  post <- ce$dates >= ce$int.date
  s <- data.frame(data = ce$dates[post],
                  obs = ce$y[post], cf = ce$forecast,
                  lo = ce$forecast_lower, hi = ce$forecast_upper)
  p <- ggplot(s, aes(data)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#c00000", alpha = 0.15) +
    geom_line(aes(y = cf), color = "#c00000", linetype = "dashed", linewidth = 0.5) +
    geom_line(aes(y = obs), color = "#1f4e79", linewidth = 0.6) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    labs(title = titulo, subtitle = subt,
         x = NULL, y = "Requerentes/mês", caption = "Fonte: BGSD/MTE. Contrafactual C-ARIMA (IC 95%).") +
    theme_minimal(base_size = 11)
  ggsave(arq, p, width = 9, height = 4.5, dpi = 150)
}
plot_cf(L_sem, "C-ARIMA — Lei 13.134/2015 (sem controle)",
        file.path(fig, "12_carima_lei2015.png"),
        "Observado (azul) vs. contrafactual C-ARIMA (vermelho tracejado)")
plot_cf(L_com, "C-ARIMA — Lei 13.134/2015 (com controle de demissões)",
        file.path(fig, "13_carima_lei2015_controle.png"),
        "Observado (azul) vs. contrafactual C-ARIMA condicionado nas demissões (CAGED)")

cat("08_carima OK.\n"); print(R[, c("cenario","controle","efeito_medio","ic_inf","ic_sup","efeito_pct","p_valor")], row.names = FALSE)
