library(readxl)
library(dplyr)

path_cov  <- "C:/Users/TutuSurfer/meu-projeto/Artigos/SDID/Base de Dados/Final/Covariaveis_SDID_Final.xlsx"
path_main <- "C:/Users/TutuSurfer/meu-projeto/Artigos/SDID/Base de Dados/Final/BASE_FINAL_SEM_NAS_ULTIMA_VERSAO_POWER_PLUS_ULTRA.xlsx"

LIMIAR_BASELINE <- 0.005
ids_tratados <- c(4306767L, 4312609L, 4315800L, 4300851L, 4321626L, 4310108L)

df_cov  <- read_excel(path_cov)
df_main <- read_excel(path_main) %>%
  select(id_municipio, municipio_nome) %>%
  distinct()

ids_pool <- df_cov %>%
  select(id_municipio, proporcao_atingidos) %>%
  distinct() %>%
  filter(proporcao_atingidos <= LIMIAR_BASELINE,
         !(id_municipio %in% ids_tratados)) %>%
  pull(id_municipio) %>%
  intersect(unique(df_main$id_municipio))

pool_nomes <- df_main %>%
  filter(id_municipio %in% ids_pool) %>%
  select(municipio_nome) %>%
  distinct() %>%
  arrange(municipio_nome) %>%
  pull(municipio_nome)

cat("N doadores:", length(pool_nomes), "\n")

# Gera código LaTeX: tabela 3 colunas
n   <- length(pool_nomes)
pad <- (3 - n %% 3) %% 3
nomes_pad <- c(pool_nomes, rep("", pad))
mat <- matrix(nomes_pad, ncol = 3, byrow = TRUE)

linhas <- apply(mat, 1, function(r) paste(r, collapse = " & "))
linhas_tex <- paste0(linhas, " \\\\")

latex_out <- c(
  "% Pool doador — gerado automaticamente por extrair_pool_doador.R",
  paste0("% N = ", n, " municípios"),
  "\\begin{longtable}{lll}",
  "\\caption{Municípios do pool doador ($N_0 = 193$)}",
  "\\label{tab:pool_doador}\\\\",
  "\\toprule",
  "\\multicolumn{3}{l}{\\textit{Municípios gaúchos com proporção de atingidos} $\\leq 0{,}5\\%$} \\\\",
  "\\midrule",
  "\\endfirsthead",
  "\\toprule",
  "\\multicolumn{3}{l}{\\textit{(continuação)}} \\\\",
  "\\midrule",
  "\\endhead",
  "\\midrule",
  "\\multicolumn{3}{r}{\\footnotesize\\textit{continua na próxima página}} \\\\",
  "\\endfoot",
  "\\bottomrule",
  "\\multicolumn{3}{l}{\\footnotesize Fonte: MUPRS/SPGG-RS. Ordenação alfabética.} \\\\",
  "\\endlastfoot",
  linhas_tex,
  "\\end{longtable}"
)

out_path <- "C:/Users/TutuSurfer/meu-projeto/Artigos/SDID/arquivos latex/pool_doador_table.tex"
writeLines(latex_out, out_path, useBytes = FALSE)
cat("LaTeX salvo em:", out_path, "\n")
