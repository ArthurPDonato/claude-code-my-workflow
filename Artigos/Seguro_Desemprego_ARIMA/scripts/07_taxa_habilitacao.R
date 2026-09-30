# =============================================================================
# 07_taxa_habilitacao.R — TESTE DECISIVO: efeito da Lei 13.134/2015 sobre a
# TAXA DE HABILITAÇÃO (requerentes/demissões e segurados/demissões).
#
# Lógica: se a Lei restringiu o ACESSO (tenure mín. 6->12 meses p/ 1ª solicitação),
# a razão SD/demissões deve CAIR em 2015-07 — mesmo com demissões constantes.
# Este desfecho já condiciona pelo mercado de trabalho no NUMERADOR/DENOMINADOR,
# resolvendo a ambiguidade "efeito da Lei vs. dinâmica de demissões" do passo 06.
#
# Janela = 2000-01 a 2019-12 (CAGED antigo, sem quebra).
# Dois métodos: ITS-ARIMA (contrafactual) + CausalImpact (sem covariável).
#
# CAVEAT: o denominador é o TOTAL de desligamentos (inclui pedidos de demissão,
# fim de contrato etc.), não só dispensa sem justa causa (que aciona o SD). É um
# proxy de take-up; movimentos de dispensa dominam a variação, mas registrar.
# =============================================================================

suppressMessages({
  library(forecast); library(CausalImpact); library(zoo)
  library(dplyr); library(ggplot2); library(scales); library(tidyr)
})
set.seed(20260930)

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

sb  <- readRDS(here("outputs", "serie_brasil.rds"))$serie_brasil
ctl <- readRDS(here("outputs", "controle_caged.rds"))
lei <- as.Date("2015-07-01")

df <- inner_join(sb %>% select(data, requerentes, segurados), ctl, by = "data") %>%
  filter(data >= as.Date("2000-01-01"), data <= as.Date("2019-12-01")) %>%
  arrange(data) %>%
  mutate(taxa_req = requerentes / desligamentos,
         taxa_seg = segurados   / desligamentos)

# ---- Helpers ----------------------------------------------------------------
dts <- df$data
idx <- function(dt) which(dts == dt)

its_arima <- function(v, rotulo) {
  ip <- 1:idx(as.Date("2015-06-01")); ie <- idx(lei):length(v)
  y_pre <- ts(v[ip], frequency = 12, start = c(2000, 1))
  fit <- auto.arima(y_pre, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
  fc  <- forecast(fit, h = length(ie), level = 95)
  obs <- v[ie]; cf <- as.numeric(fc$mean)
  data.frame(desfecho = rotulo, metodo = "ARIMA-ITS",
             efeito_medio = mean(obs - cf),
             ic_inf = mean(obs - as.numeric(fc$upper)),
             ic_sup = mean(obs - as.numeric(fc$lower)),
             efeito_pct = 100 * mean(obs - cf) / mean(cf),
             p_value = NA_real_)
}

its_ci <- function(v, rotulo) {
  z <- zoo(v, order.by = dts)
  imp <- CausalImpact(z, pre.period = as.Date(c("2000-01-01","2015-06-01")),
                      post.period = as.Date(c("2015-07-01","2019-12-01")),
                      model.args = list(nseasons = 12, season.duration = 1))
  s <- imp$summary
  list(res = data.frame(desfecho = rotulo, metodo = "CausalImpact",
                        efeito_medio = s["Average","AbsEffect"],
                        ic_inf = s["Average","AbsEffect.lower"],
                        ic_sup = s["Average","AbsEffect.upper"],
                        efeito_pct = 100 * s["Average","RelEffect"],
                        p_value = imp$summary$p[1]),
       imp = imp)
}

# ---- Roda os dois desfechos x dois métodos ----------------------------------
a_req <- its_arima(df$taxa_req, "Taxa requerentes/demissões")
a_seg <- its_arima(df$taxa_seg, "Taxa segurados/demissões")
c_req <- its_ci(df$taxa_req, "Taxa requerentes/demissões")
c_seg <- its_ci(df$taxa_seg, "Taxa segurados/demissões")

comp <- bind_rows(a_req, c_req$res, a_seg, c_seg$res) %>% arrange(desfecho, metodo)
write.csv(comp, file.path(tab, "taxa_habilitacao.csv"), row.names = FALSE)

sink(file.path(tab, "taxa_habilitacao.txt"))
cat("=== TESTE DA TAXA DE HABILITAÇÃO — efeito da Lei 13.134/2015 ===\n\n")
cat("Média pré (2000-2015/06):  req/dem =", round(mean(df$taxa_req[dts < lei]),4),
    "| seg/dem =", round(mean(df$taxa_seg[dts < lei]),4), "\n")
cat("Média pós (2015/07-2019):  req/dem =", round(mean(df$taxa_req[dts >= lei]),4),
    "| seg/dem =", round(mean(df$taxa_seg[dts >= lei]),4), "\n\n")
print(comp, row.names = FALSE, digits = 4)
cat("\n\n--- CausalImpact requerentes/demissões ---\n"); print(summary(c_req$imp))
sink()

# ---- Figura: séries das taxas com a Lei -------------------------------------
long <- df %>% select(data, taxa_req, taxa_seg) %>%
  pivot_longer(-data, names_to = "serie", values_to = "taxa") %>%
  mutate(serie = recode(serie, taxa_req = "Requerentes/demissões",
                                taxa_seg = "Segurados/demissões"))
p <- ggplot(long, aes(data, taxa, color = serie)) +
  geom_line(linewidth = 0.4) +
  geom_vline(xintercept = as.numeric(lei), linetype = "dashed", color = "#c00000") +
  annotate("text", x = lei, y = max(long$taxa), label = "Lei 13.134/2015",
           hjust = 1.05, size = 3, color = "#c00000") +
  scale_color_manual(values = c("Requerentes/demissões" = "#1f4e79",
                                "Segurados/demissões" = "#2e8b57")) +
  labs(title = "Taxa de habilitação ao Seguro-Desemprego — Brasil",
       subtitle = "Solicitações/beneficiários por desligamento CAGED",
       x = NULL, y = "Razão", color = NULL,
       caption = "Fonte: BGSD/MTE e CAGED/MTE (IPEADATA).") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(fig, "10_taxa_habilitacao.png"), p, width = 9, height = 4.5, dpi = 150)

png(file.path(fig, "11_causalimpact_taxa_req.png"), width = 900, height = 800, res = 110)
print(plot(c_req$imp)); dev.off()

saveRDS(list(comp = comp, df = df), here("outputs", "taxa_habilitacao_fit.rds"))
cat("07_taxa_habilitacao OK.\n"); print(comp, row.names = FALSE, digits = 4)
