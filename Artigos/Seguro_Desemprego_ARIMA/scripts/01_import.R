# =============================================================================
# 01_import.R — Importa a série histórica do Seguro-Desemprego (MTE)
#
# Fonte: 3-serie-historica-do-seguro-desemprego-2000-a-2025 (MTE/SPPE)
#   Tabela 1 (aba 6) = Qtd. de REQUERENTES (trab. formal) por UF x mês
#   Tabela 2 (aba 8) = Qtd. de SEGURADOS (habilitados)    por UF x mês
#
# Saída:
#   outputs/serie_brasil.csv  — BRASIL mensal (requerentes, segurados)
#   outputs/painel_uf.csv     — painel UF x mês (long)
#   outputs/serie_brasil.rds  — lista com objetos ts() prontos p/ modelagem
# =============================================================================

suppressMessages({
  library(readxl); library(dplyr); library(tidyr); library(stringr); library(readr)
})

# ---- Caminhos (relativos à raiz do subprojeto) ------------------------------
here <- function(...) file.path("Artigos/Seguro_Desemprego_ARIMA", ...)
xlsx <- here("dados", "serie_seguro_desemprego_2000_2025.xlsx")
dir_out <- here("outputs")
stopifnot(file.exists(xlsx))

# ---- Parser de uma aba (formato: meses nas colunas, UF nas linhas) ----------
parse_aba <- function(path, sheet, valor_nome) {
  raw <- suppressMessages(read_excel(path, sheet = sheet, col_names = FALSE))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)

  # 1) linha de cabeçalho = a que contém rótulos "AAAA/MM"
  is_ym <- function(x) grepl("^\\d{4}/\\d{2}$", trimws(as.character(x)))
  hdr_row <- which(vapply(seq_len(nrow(raw)),
                          function(i) sum(is_ym(unlist(raw[i, ])), na.rm = TRUE) > 12,
                          logical(1)))[1]
  stopifnot(!is.na(hdr_row))

  labels <- as.character(unlist(raw[hdr_row, ]))
  mcols  <- which(is_ym(labels))              # colunas que são meses
  ym     <- labels[mcols]

  # 2) coluna de geografia = a que contém "BRASIL"
  geo_col <- which(vapply(seq_len(ncol(raw)),
                          function(j) any(toupper(trimws(as.character(raw[[j]]))) == "BRASIL"),
                          logical(1)))[1]
  stopifnot(!is.na(geo_col))

  # 3) linhas de dados = da linha do BRASIL até a última UF não-vazia
  brasil_row <- which(toupper(trimws(as.character(raw[[geo_col]]))) == "BRASIL")[1]
  geo_vals   <- toupper(trimws(as.character(raw[[geo_col]])))
  data_rows  <- brasil_row:nrow(raw)
  data_rows  <- data_rows[!is.na(geo_vals[data_rows]) & geo_vals[data_rows] != ""]
  # Descarta linhas de rodapé/fonte (começam com "*" ou "Fonte:")
  data_rows  <- data_rows[!grepl("^\\*|^FONTE", geo_vals[data_rows])]

  out <- lapply(data_rows, function(i) {
    v <- suppressWarnings(as.numeric(unlist(raw[i, mcols])))
    data.frame(geografia = trimws(as.character(raw[[geo_col]][i])),
               ym = ym, valor = v, stringsAsFactors = FALSE)
  })
  out <- bind_rows(out)
  out$data <- as.Date(paste0(gsub("/", "-", out$ym), "-01"))
  out <- out[, c("geografia", "data", "valor")]
  names(out)[3] <- valor_nome
  out
}

message("Lendo Tabela 1 (requerentes)...")
req <- parse_aba(xlsx, sheet = 6, valor_nome = "requerentes")
message("Lendo Tabela 2 (segurados)...")
seg <- parse_aba(xlsx, sheet = 8, valor_nome = "segurados")

# ---- Painel UF x mês (long, exclui BRASIL) ----------------------------------
painel <- full_join(req, seg, by = c("geografia", "data")) %>%
  arrange(geografia, data)
painel_uf <- painel %>% filter(toupper(geografia) != "BRASIL")

# ---- Série BRASIL -----------------------------------------------------------
serie_brasil <- painel %>%
  filter(toupper(geografia) == "BRASIL") %>%
  select(data, requerentes, segurados) %>%
  arrange(data)

# ---- Objetos ts() para modelagem (freq mensal) ------------------------------
y0 <- as.integer(format(min(serie_brasil$data), "%Y"))
m0 <- as.integer(format(min(serie_brasil$data), "%m"))
ts_req <- ts(serie_brasil$requerentes, start = c(y0, m0), frequency = 12)
ts_seg <- ts(serie_brasil$segurados,   start = c(y0, m0), frequency = 12)

# ---- Datas das intervenções (referência única do projeto) -------------------
intervencoes <- list(
  lei_13134  = as.Date("2015-07-01"),  # Lei nº 13.134/2015 (aperto de elegibilidade)
  covid_2020 = as.Date("2020-03-01")   # choque pandêmico / medidas emergenciais
)

# ---- Verificação de integridade ---------------------------------------------
n  <- nrow(serie_brasil)
esperado <- length(seq(min(serie_brasil$data), max(serie_brasil$data), by = "month"))
gaps <- esperado - n
cat(sprintf("\nSérie BRASIL: %d meses (%s a %s) | esperado %d | gaps %d\n",
            n, min(serie_brasil$data), max(serie_brasil$data), esperado, gaps))
cat(sprintf("NAs requerentes: %d | NAs segurados: %d\n",
            sum(is.na(serie_brasil$requerentes)), sum(is.na(serie_brasil$segurados))))
cat(sprintf("UFs no painel: %d\n", dplyr::n_distinct(painel_uf$geografia)))
stopifnot(gaps == 0, sum(is.na(serie_brasil$requerentes)) == 0)

# ---- Grava saídas -----------------------------------------------------------
write_csv(serie_brasil, file.path(dir_out, "serie_brasil.csv"))
write_csv(painel_uf,    file.path(dir_out, "painel_uf.csv"))
saveRDS(list(serie_brasil = serie_brasil, ts_req = ts_req, ts_seg = ts_seg,
             intervencoes = intervencoes),
        file.path(dir_out, "serie_brasil.rds"))

cat("\nOK — outputs gravados em", dir_out, "\n")
print(utils::head(serie_brasil, 3)); print(utils::tail(serie_brasil, 3))
