# =============================================================================
# 05_triangulacao.R — Consolida ARIMA-ITS vs. CausalImpact
#   - Tabela comparativa (CSV)
#   - Figura tipo forest plot dos efeitos médios com IC 95%
# =============================================================================

suppressMessages({ library(dplyr); library(ggplot2); library(scales) })

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
fig <- here("outputs", "figuras"); tab <- here("outputs", "tabelas")

A  <- readRDS(here("outputs", "arima_fit.rds"))$A
CI <- readRDS(here("outputs", "causalimpact_fit.rds"))$CI

comp <- bind_rows(
  A  %>% transmute(intervencao, metodo = "ARIMA-ITS (contrafactual)",
                   efeito_medio, ic_inf = efeito_medio_ic_inf,
                   ic_sup = efeito_medio_ic_sup, efeito_pct),
  CI %>% transmute(intervencao, metodo = "CausalImpact (BSTS)",
                   efeito_medio, ic_inf = efeito_medio_ic_inf,
                   ic_sup = efeito_medio_ic_sup, efeito_pct)
) %>% arrange(intervencao, metodo)

write.csv(comp, file.path(tab, "triangulacao_efeitos.csv"), row.names = FALSE)

p <- ggplot(comp, aes(x = efeito_medio, y = metodo, color = metodo)) +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey40") +
  geom_errorbarh(aes(xmin = ic_inf, xmax = ic_sup), height = 0.2, linewidth = 0.6) +
  geom_point(size = 2.6) +
  facet_wrap(~ intervencao, ncol = 1, scales = "free_x") +
  scale_x_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(values = c("ARIMA-ITS (contrafactual)" = "#c00000",
                                "CausalImpact (BSTS)" = "#1f4e79")) +
  labs(title = "Triangulação — efeito médio sobre requerentes/mês (IC 95%)",
       x = "Efeito médio (requerentes/mês)", y = NULL, color = NULL,
       caption = "Fonte: BGSD/MTE. Elaboração própria.") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(fig, "08_triangulacao_forest.png"), p, width = 9, height = 5, dpi = 150)

cat("05_triangulacao OK.\n"); print(comp, row.names = FALSE, digits = 5)
