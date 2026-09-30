# =============================================================================
# 06_causalimpact_controle.R — CausalImpact da Lei 13.134/2015 COM controle CAGED
#
# Preditores: admissões e demissões nacionais (CAGED antigo, MTE), exógenos à
# regra de elegibilidade do SD. Janela toda pré-2020 (sem quebra metodológica).
#   pre  = 2000-01 .. 2015-06
#   post = 2015-07 .. 2019-12   (fim do CAGED antigo)
#
# Compara com o modelo SEM covariáveis (04) para mostrar o ganho de precisão.
# =============================================================================

suppressMessages({ library(CausalImpact); library(zoo); library(dplyr) })
set.seed(20260930)

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

sb  <- readRDS(here("outputs", "serie_brasil.rds"))$serie_brasil
ctl <- readRDS(here("outputs", "controle_caged.rds"))

# ---- Merge e janela comum ---------------------------------------------------
df <- inner_join(sb %>% select(data, requerentes), ctl, by = "data") %>%
  filter(data >= as.Date("2000-01-01"), data <= as.Date("2019-12-01")) %>%
  arrange(data)

# Qualidade do controle: correlação no pré-intervenção
pre_mask <- df$data <= as.Date("2015-06-01")
cor_des <- cor(df$requerentes[pre_mask], df$desligamentos[pre_mask])
cor_adm <- cor(df$requerentes[pre_mask], df$admissoes[pre_mask])

# ---- CausalImpact com covariáveis (resposta = coluna 1) ---------------------
z <- zoo(cbind(requerentes = df$requerentes,
               desligamentos = df$desligamentos,
               admissoes = df$admissoes), order.by = df$data)
pre  <- as.Date(c("2000-01-01", "2015-06-01"))
post <- as.Date(c("2015-07-01", "2019-12-01"))
imp <- CausalImpact(z, pre.period = pre, post.period = post,
                    model.args = list(nseasons = 12, season.duration = 1))

png(file.path(fig, "09_causalimpact_lei2015_controle.png"), width = 900, height = 800, res = 110)
print(plot(imp)); dev.off()

s <- imp$summary
res_ctl <- data.frame(
  modelo = "CausalImpact + controle CAGED",
  efeito_medio        = s["Average", "AbsEffect"],
  efeito_medio_ic_inf = s["Average", "AbsEffect.lower"],
  efeito_medio_ic_sup = s["Average", "AbsEffect.upper"],
  efeito_pct          = 100 * s["Average", "RelEffect"],
  p_value             = imp$summary$p[1],
  largura_ic          = s["Average", "AbsEffect.upper"] - s["Average", "AbsEffect.lower"]
)

# ---- Baseline sem covariável (do 04), p/ comparar largura do IC -------------
base <- readRDS(here("outputs", "causalimpact_fit.rds"))$ci_lei
res_base <- data.frame(
  modelo = "CausalImpact sem controle",
  efeito_medio = base$efeito_medio,
  efeito_medio_ic_inf = base$efeito_medio_ic_inf,
  efeito_medio_ic_sup = base$efeito_medio_ic_sup,
  efeito_pct = base$efeito_pct, p_value = base$p_value,
  largura_ic = base$efeito_medio_ic_sup - base$efeito_medio_ic_inf
)
comp <- bind_rows(res_base, res_ctl)

sink(file.path(tab, "causalimpact_controle.txt"))
cat("=== CausalImpact — Lei 13.134/2015 COM controle CAGED ===\n\n")
cat(sprintf("Correlação pré-intervenção requerentes~desligamentos: %.3f\n", cor_des))
cat(sprintf("Correlação pré-intervenção requerentes~admissões:     %.3f\n\n", cor_adm))
print(summary(imp))
cat("\n\n--- Comparação (efeito médio, req/mês) ---\n")
print(comp, row.names = FALSE, digits = 5)
sink()

write.csv(comp, file.path(tab, "comparacao_controle.csv"), row.names = FALSE)
saveRDS(list(imp = imp, comp = comp, cor_des = cor_des, cor_adm = cor_adm),
        here("outputs", "causalimpact_controle_fit.rds"))

cat("06_causalimpact_controle OK.\n")
cat(sprintf("cor(requerentes, desligamentos) pré = %.3f\n", cor_des))
print(comp[, c("modelo","efeito_medio","efeito_medio_ic_inf",
               "efeito_medio_ic_sup","efeito_pct","p_value","largura_ic")],
      row.names = FALSE, digits = 5)
