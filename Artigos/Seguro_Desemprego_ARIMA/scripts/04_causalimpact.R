# =============================================================================
# 04_causalimpact.R — CausalImpact (BSTS bayesiano) sobre os requerentes (Brasil)
#
# Modelo estrutural com tendência local + sazonalidade mensal (nseasons = 12),
# SEM covariáveis (contrafactual a partir da própria dinâmica pré-intervenção).
# Janelas idênticas às do 03 -> triangulação direta com a ITS-ARIMA.
#
# Extensão futura: adicionar série de controle nacional (ex.: admissões CAGED)
# como preditor para estreitar o intervalo posterior.
# =============================================================================

suppressMessages({ library(CausalImpact); library(zoo); library(dplyr) })
set.seed(20260930)

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
d  <- readRDS(here("outputs", "serie_brasil.rds"))
sb <- d$serie_brasil
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

z <- zoo(sb$requerentes, order.by = sb$data)

rodar_ci <- function(pre_ini, pre_fim, pos_ini, pos_fim, rotulo, arq_fig) {
  pre <- as.Date(c(pre_ini, pre_fim)); pos <- as.Date(c(pos_ini, pos_fim))
  imp <- CausalImpact(z, pre.period = pre, post.period = pos,
                      model.args = list(nseasons = 12, season.duration = 1))
  png(arq_fig, width = 900, height = 800, res = 110)
  print(plot(imp)); dev.off()
  s <- imp$summary
  data.frame(intervencao = rotulo,
             efeito_medio        = s["Average", "AbsEffect"],
             efeito_medio_ic_inf = s["Average", "AbsEffect.lower"],
             efeito_medio_ic_sup = s["Average", "AbsEffect.upper"],
             efeito_pct          = 100 * s["Average", "RelEffect"],
             p_value             = imp$summary$p[1],
             stringsAsFactors = FALSE) -> res
  attr(res, "imp") <- imp
  res
}

ci_lei   <- rodar_ci("2000-01-01", "2015-06-01", "2015-07-01", "2020-02-01",
                     "Lei 13.134/2015", file.path(fig, "06_causalimpact_lei2015.png"))
ci_covid <- rodar_ci("2000-01-01", "2020-02-01", "2020-03-01", "2021-02-01",
                     "COVID/2020", file.path(fig, "07_causalimpact_covid.png"))
CI <- bind_rows(ci_lei, ci_covid)

sink(file.path(tab, "causalimpact.txt"))
cat("=== CausalImpact — requerentes (Brasil) ===\n\n")
cat(">>> Lei 13.134/2015\n");  print(summary(attr(ci_lei, "imp")))
cat("\n\n>>> COVID/2020\n");   print(summary(attr(ci_covid, "imp")))
sink()

saveRDS(list(CI = CI, ci_lei = ci_lei, ci_covid = ci_covid), here("outputs", "causalimpact_fit.rds"))

cat("04_causalimpact OK.\n")
print(CI[, c("intervencao","efeito_medio","efeito_medio_ic_inf",
             "efeito_medio_ic_sup","efeito_pct","p_value")], row.names = FALSE)
