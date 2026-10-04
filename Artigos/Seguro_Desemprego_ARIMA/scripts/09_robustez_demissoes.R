# =============================================================================
# 09_robustez_demissoes.R — Robustez / placebo de mecanismo
#
# Roda os MESMOS modelos do artigo (C-ARIMA + CausalImpact, SEM controle) sobre
# as DEMISSÕES do CAGED, na MESMA janela em que estimamos o efeito sobre os
# requerentes. Pergunta: a própria série de demissões exibe a mesma queda de
# ~-16% em jul/2015? Se sim, o "efeito da Lei" estimado sem controle é, na
# verdade, a dinâmica de demissões da recessão de 2015-16 (não a reforma).
#
# Janela idêntica p/ as duas séries (limitada pelo fim do CAGED antigo):
#   pré  2000-01 .. 2015-06  (186 meses)
#   pós  2015-07 .. 2019-12  ( 54 meses)
# =============================================================================

suppressMessages({ library(CausalArima); library(CausalImpact); library(forecast)
                   library(zoo); library(ggplot2); library(scales) })
set.seed(20260704)

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
d    <- readRDS(here("outputs", "serie_brasil.rds")); sb <- d$serie_brasil
sb$data <- as.Date(sb$data)
ctrl <- readRDS(here("outputs", "controle_caged.rds")); ctrl$data <- as.Date(ctrl$data)
fig  <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

INI <- as.Date("2000-01-01"); FIM <- as.Date("2019-12-01")
INT <- as.Date("2015-07-01"); POS0 <- as.Date("2015-07-01")
NB  <- 1000

# séries alinhadas à janela comum
req <- sb[sb$data >= INI & sb$data <= FIM, c("data", "requerentes")]
dem <- ctrl[ctrl$data >= INI & ctrl$data <= FIM, c("data", "desligamentos")]
stopifnot(nrow(req) == nrow(dem), all(req$data == dem$data))
dts <- req$data

# ---- C-ARIMA (bootstrap direto de boot.distrib; contorna bug do pacote) ------
carima_efeito <- function(y, rotulo) {
  ce <- CausalArima(y = ts(y, frequency = 12), dates = dts, int.date = INT, nboot = NB)
  ord  <- forecast::arimaorder(ce$model)
  post <- ce$dates >= ce$int.date
  y_post <- ce$y[post]; nas <- is.na(y_post); y_post <- y_post[!nas]
  fc  <- ce$forecast[!nas]
  sim <- ce$boot$boot.distrib[!nas, , drop = FALSE]
  eff_draws <- colMeans(apply(sim, 2, function(z) y_post - z))
  est <- mean(y_post) - mean(fc)
  lo  <- unname(quantile(eff_draws, 0.025)); hi <- unname(quantile(eff_draws, 0.975))
  p1  <- min(mean(colSums(sim) >= sum(y_post)), mean(colSums(sim) <= sum(y_post)))
  data.frame(serie = rotulo, metodo = "C-ARIMA",
             modelo = sprintf("ARIMA(%d,%d,%d)(%d,%d,%d)[%d]", ord[1],ord[2],ord[3],ord[4],ord[5],ord[6],ord[7]),
             efeito_medio = est, ic_inf = lo, ic_sup = hi,
             efeito_pct = 100 * est / mean(fc), p_valor = min(1, 2*p1),
             stringsAsFactors = FALSE) -> res
  attr(res, "ce") <- ce; res
}

# ---- CausalImpact (BSTS, sem controle) --------------------------------------
ci_efeito <- function(y, rotulo, arq_fig = NULL) {
  z <- zoo(y, order.by = dts)
  imp <- CausalImpact(z, pre.period = c(INI, as.Date("2015-06-01")),
                      post.period = c(POS0, FIM),
                      model.args = list(nseasons = 12, season.duration = 1))
  if (!is.null(arq_fig)) { png(arq_fig, width = 900, height = 800, res = 110); print(plot(imp)); dev.off() }
  s <- imp$summary
  data.frame(serie = rotulo, metodo = "CausalImpact", modelo = "BSTS (tendência local + sazon. 12)",
             efeito_medio = s["Average","AbsEffect"], ic_inf = s["Average","AbsEffect.lower"],
             ic_sup = s["Average","AbsEffect.upper"], efeito_pct = 100 * s["Average","RelEffect"],
             p_valor = imp$summary$p[1], stringsAsFactors = FALSE) -> res
  attr(res, "imp") <- imp; res
}

# ---- roda as 4 combinações (2 séries x 2 métodos) ---------------------------
cr_req <- carima_efeito(req$requerentes,  "Requerentes")
cr_dem <- carima_efeito(dem$desligamentos, "Demissões")
ci_req <- ci_efeito(req$requerentes,  "Requerentes")
ci_dem <- ci_efeito(dem$desligamentos, "Demissões", file.path(fig, "15_ci_demissoes.png"))
R <- rbind(cr_req[1:8], cr_dem[1:8], ci_req, ci_dem)
R <- R[order(R$serie, R$metodo), ]

write.csv(R, file.path(tab, "robustez_demissoes.csv"), row.names = FALSE)
sink(file.path(tab, "robustez_demissoes.txt"))
cat("=== Robustez: mesmos modelos (sem controle) sobre REQUERENTES vs DEMISSÕES ===\n")
cat("Janela idêntica: pré 2000-01..2015-06 ; pós 2015-07..2019-12 (fim do CAGED antigo).\n")
cat("Hipótese: se as demissões caem ~o mesmo % que os requerentes, o 'efeito da Lei'\n")
cat("sem controle é a dinâmica de demissões (recessão), não a reforma.\n\n")
print(R, row.names = FALSE, digits = 6)
sink()
saveRDS(list(R = R, cr_req = cr_req, cr_dem = cr_dem, ci_req = ci_req, ci_dem = ci_dem),
        here("outputs", "robustez_demissoes_fit.rds"))

# ---- figura: demissões observadas vs contrafactual C-ARIMA ------------------
ce <- attr(cr_dem, "ce"); post <- ce$dates >= ce$int.date
s <- data.frame(data = ce$dates[post], obs = ce$y[post], cf = ce$forecast,
                lo = ce$forecast_lower, hi = ce$forecast_upper)
p <- ggplot(s, aes(data)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#548235", alpha = 0.15) +
  geom_line(aes(y = cf), color = "#548235", linetype = "dashed", linewidth = 0.5) +
  geom_line(aes(y = obs), color = "#1f4e79", linewidth = 0.6) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(title = "Robustez — C-ARIMA sobre as DEMISSÕES (CAGED), Lei 13.134/2015",
       subtitle = "Observado (azul) vs. contrafactual C-ARIMA (verde tracejado, IC 95%)",
       x = NULL, y = "Demissões/mês", caption = "Fonte: CAGED antigo (IPEADATA/MTE).") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig, "14_carima_demissoes.png"), p, width = 9, height = 4.5, dpi = 150)

cat("09_robustez_demissoes OK.\n")
print(R[, c("serie","metodo","efeito_medio","ic_inf","ic_sup","efeito_pct","p_valor")], row.names = FALSE)
