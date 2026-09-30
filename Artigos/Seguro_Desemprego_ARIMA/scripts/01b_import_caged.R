# =============================================================================
# 01b_import_caged.R — Série de controle nacional: CAGED antigo (MTE)
#
# Fonte: IPEADATA / MTE-Caged (séries INATIVAS, metodologia antiga)
#   CAGED12_ADMIS  = admissões  (mensal, 1999-05 a 2019-12)
#   CAGED12_DESLIG = demissões  (mensal, 1999-05 a 2019-12)
#
# Uso: preditor no CausalImpact para a Lei 13.134/2015 (janela toda pré-2020,
# 100% CAGED antigo -> sem quebra metodológica). NÃO usar p/ COVID.
#
# Saída: outputs/controle_caged.csv  (data, admissoes, desligamentos)
# =============================================================================

suppressMessages({ library(jsonlite); library(dplyr); library(zoo) })

here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
ler_serie <- function(arq, nome) {
  j <- fromJSON(here("dados", "caged", arq))$value
  data.frame(data = as.Date(substr(j$VALDATA, 1, 10)),
             valor = as.numeric(j$VALVALOR)) %>%
    filter(!is.na(valor)) %>% rename(!!nome := valor)
}

adm <- ler_serie("CAGED12_ADMIS.json",  "admissoes")
des <- ler_serie("CAGED12_DESLIG.json", "desligamentos")

controle <- full_join(adm, des, by = "data") %>%
  arrange(data) %>%
  # 1º dia do mês para casar com a série do SD
  mutate(data = as.Date(format(data, "%Y-%m-01")))

# Interpola NA interior (2000-02 em desligamentos) por aproximação linear
n_na <- sum(is.na(controle$admissoes)) + sum(is.na(controle$desligamentos))
if (n_na > 0) {
  controle$admissoes     <- na.approx(controle$admissoes,     na.rm = FALSE)
  controle$desligamentos <- na.approx(controle$desligamentos, na.rm = FALSE)
  cat(sprintf("Interpolados %d valores NA (aproximação linear).\n", n_na))
}

esperado <- length(seq(min(controle$data), max(controle$data), by = "month"))
cat(sprintf("Controle CAGED: %d meses (%s a %s) | esperado %d | gaps %d\n",
            nrow(controle), min(controle$data), max(controle$data),
            esperado, esperado - nrow(controle)))
cat(sprintf("NAs admissoes: %d | NAs desligamentos: %d\n",
            sum(is.na(controle$admissoes)), sum(is.na(controle$desligamentos))))
stopifnot(esperado - nrow(controle) == 0)

write.csv(controle, here("outputs", "controle_caged.csv"), row.names = FALSE)
saveRDS(controle, here("outputs", "controle_caged.rds"))
cat("01b_import_caged OK.\n"); print(utils::tail(controle, 3), row.names = FALSE)
