# =============================================================================
# TAREFA 9 – VAR ou VEC? Especificação, Estimação e Análise Dinâmica
# Cadeia do Diesel — PPGE/FURG | Econometria
# Discente: Arthur Pereira Donato | Matrícula: 184210
# =============================================================================
# Pacotes exigidos: vars, urca, lmtest, ggplot2
# Todos os gráficos são salvos como PNG na pasta outputs/
# Todas as tabelas são salvas como CSV para uso no LaTeX
# =============================================================================

library(vars)     # VAR(), VARselect(), irf(), fevd(), causality(), serial.test()
library(urca)     # ur.df(), ca.jo(), cajorls(), vec2var()
library(lmtest)   # coeftest() — inferência robusta
library(ggplot2)  # gráficos (usado para eventuais extensões)

set.seed(2026)    # semente exigida pelo enunciado

# ── Diretório de saída ───────────────────────────────────────────────────────
out_dir <- "C:/Users/TutuSurfer/meu-projeto/Artigos/Tarefa Econometria/Tarefa 9/outputs"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# =============================================================================
# PARTE 1 – PREPARAÇÃO E ANÁLISE EXPLORATÓRIA
# =============================================================================

# Item 1 ─────────────────────────────────────────────────────────────────────
# Carregamento e truncamento
# O enunciado especifica corte em 26/01/2026, resultando em exatamente 161 obs.
dados <- read.csv(
  "C:/Users/TutuSurfer/meu-projeto/Artigos/Tarefa Econometria/Tarefa 9/dados_diesel.csv",
  stringsAsFactors = FALSE, sep = ","
)
dados$data_inicio <- as.Date(dados$data_inicio)
dados <- dados[dados$data_inicio <= as.Date("2026-01-26"), ]
cat("Observações após truncamento:", nrow(dados), "\n")  # deve ser 161

# Transformação logarítmica
# ln(preço) → coeficientes interpretados diretamente como elasticidades
dados$l_brent <- log(dados$brent_brl_media)
dados$l_dA    <- log(dados$dieselA_S10_pi)
dados$l_dB    <- log(dados$dieselB_S10_dist)

# Estatísticas descritivas das três séries em log
descr <- function(x) {
  c(N = sum(!is.na(x)), Media = round(mean(x, na.rm=TRUE), 4),
    DP = round(sd(x, na.rm=TRUE), 4), Min = round(min(x, na.rm=TRUE), 4),
    Q1 = round(quantile(x, .25, na.rm=TRUE), 4),
    Mediana = round(median(x, na.rm=TRUE), 4),
    Q3 = round(quantile(x, .75, na.rm=TRUE), 4),
    Max = round(max(x, na.rm=TRUE), 4))
}

tab_desc <- rbind(l_brent = descr(dados$l_brent),
                  l_dA    = descr(dados$l_dA),
                  l_dB    = descr(dados$l_dB))
print(tab_desc)
write.csv(tab_desc, file.path(out_dir, "tab01_descritivas.csv"), quote=FALSE)

# Item 2 ─────────────────────────────────────────────────────────────────────
# Painel 3×1: séries em log ao longo do tempo com linha da média
# O co-movimento visual entre as três séries é o primeiro indício de cointegração.
# Séries sem tendência determinística clara, mas com deriva estocástica comum.
png(file.path(out_dir, "fig01_series_log.png"), width=900, height=720)
par(mfrow=c(3,1), mar=c(3, 4, 2.5, 1))

plot(dados$data_inicio, dados$l_brent, type="l", col="steelblue", lwd=1.5,
     xlab="Data", ylab="log(R$/barril)",
     main="l_brent — Brent em R$/barril (logaritmo natural)")
abline(h=mean(dados$l_brent), lty=2, col="gray40")
legend("topright", legend=c("Série", "Média"), lty=c(1,2),
       col=c("steelblue","gray40"), lwd=c(1.5,1), bty="n", cex=0.85)

plot(dados$data_inicio, dados$l_dA, type="l", col="darkorange", lwd=1.5,
     xlab="Data", ylab="log(R$/litro)",
     main="l_dA — Diesel A S10, Produtor (logaritmo natural)")
abline(h=mean(dados$l_dA), lty=2, col="gray40")
legend("topright", legend=c("Série", "Média"), lty=c(1,2),
       col=c("darkorange","gray40"), lwd=c(1.5,1), bty="n", cex=0.85)

plot(dados$data_inicio, dados$l_dB, type="l", col="darkgreen", lwd=1.5,
     xlab="Data", ylab="log(R$/litro)",
     main="l_dB — Diesel B S10, Distribuidor (logaritmo natural)")
abline(h=mean(dados$l_dB), lty=2, col="gray40")
legend("topright", legend=c("Série", "Média"), lty=c(1,2),
       col=c("darkgreen","gray40"), lwd=c(1.5,1), bty="n", cex=0.85)

dev.off()
cat("fig01 salva.\n")

# Item 3 ─────────────────────────────────────────────────────────────────────
# ACF em nível e em 1ª diferença (lag 0–20)
# Séries I(1): ACF em nível decai lentamente (autocorrelações próximas de 1).
# Após diferenciação: ACF cai abruptamente ao intervalo de confiança (ruído branco).
png(file.path(out_dir, "fig02_acf_nivel.png"), width=900, height=720)
par(mfrow=c(3,1), mar=c(3, 4, 2.5, 1))
acf(dados$l_brent, lag.max=20, main="ACF — l_brent (nível)")
acf(dados$l_dA,    lag.max=20, main="ACF — l_dA (nível)")
acf(dados$l_dB,    lag.max=20, main="ACF — l_dB (nível)")
dev.off()

png(file.path(out_dir, "fig03_acf_diff.png"), width=900, height=720)
par(mfrow=c(3,1), mar=c(3, 4, 2.5, 1))
acf(diff(dados$l_brent), lag.max=20, main="ACF — Δl_brent (1ª diferença)")
acf(diff(dados$l_dA),    lag.max=20, main="ACF — Δl_dA (1ª diferença)")
acf(diff(dados$l_dB),    lag.max=20, main="ACF — Δl_dB (1ª diferença)")
dev.off()
cat("figs ACF salvas.\n")

# =============================================================================
# PARTE 2 – TESTES DE RAIZ UNITÁRIA (ADF)
# =============================================================================
# Item 4 ─────────────────────────────────────────────────────────────────────
# ADF com type="none" (sem constante, tau_nc), lags=6, selectlags="AIC"
# H0: raiz unitária. Rejeita se tau < -1,95 (CV 5%, T≈160, tau_nc).
# A especificação sem constante é consistente com o Johansen ecdet="none".

resultados_adf <- list()

adf_teste <- function(serie, nome) {
  res  <- ur.df(serie, type="none", lags=6, selectlags="AIC")
  tau  <- res@teststat[1]
  dec  <- ifelse(tau < -1.95, "Estacionária", "Raiz unitária")
  cat(sprintf("  %-22s | tau = %7.3f | %s\n", nome, tau, dec))
  c(tau=round(tau,3), CV5pct=-1.95, Decisao=dec)
}

cat("\n--- ADF em Nível ---\n")
r1 <- adf_teste(dados$l_brent, "l_brent (nível)")
r2 <- adf_teste(dados$l_dA,    "l_dA (nível)")
r3 <- adf_teste(dados$l_dB,    "l_dB (nível)")

cat("\n--- ADF em 1ª Diferença ---\n")
r4 <- adf_teste(diff(dados$l_brent), "Dl_brent (1a dif)")
r5 <- adf_teste(diff(dados$l_dA),    "Dl_dA (1a dif)")
r6 <- adf_teste(diff(dados$l_dB),    "Dl_dB (1a dif)")

tab_adf <- data.frame(
  Variavel   = c("l_brent (nível)","l_dA (nível)","l_dB (nível)",
                 "Dl_brent (1ª dif.)","Dl_dA (1ª dif.)","Dl_dB (1ª dif.)"),
  tau        = as.numeric(c(r1["tau"],r2["tau"],r3["tau"],r4["tau"],r5["tau"],r6["tau"])),
  CV_5pct    = -1.95,
  Decisao    = c(r1["Decisao"],r2["Decisao"],r3["Decisao"],
                 r4["Decisao"],r5["Decisao"],r6["Decisao"]),
  stringsAsFactors = FALSE
)
print(tab_adf)
write.csv(tab_adf, file.path(out_dir, "tab02_adf.csv"), row.names=FALSE, quote=FALSE)

# Item 5: todas as séries são I(1) → condição necessária para VEC é satisfeita.
# O VEC exige (1) todas as séries I(1) e (2) pelo menos 1 relação de cointegração.

# =============================================================================
# PARTE 3 – SELEÇÃO DA ORDEM DO MODELO
# =============================================================================
# Item 6 ─────────────────────────────────────────────────────────────────────
# VARselect em nível (para determinar p do VAR subjacente ao VECM)
# type="none": sem constante, consistente com a especificação ADF e Johansen

Y <- cbind(l_brent = dados$l_brent,
           l_dA    = dados$l_dA,
           l_dB    = dados$l_dB)

sel <- VARselect(Y, lag.max=8, type="none")
cat("\n--- VARselect (p = 1 a 8) ---\n")
print(round(sel$criteria, 4))

tab_varsel        <- as.data.frame(t(round(sel$criteria, 4)))
tab_varsel$p      <- 1:8
tab_varsel        <- tab_varsel[, c("p", "AIC(n)", "HQ(n)", "SC(n)", "FPE(n)")]
write.csv(tab_varsel, file.path(out_dir, "tab03_varselect.csv"),
          row.names=FALSE, quote=FALSE)

cat(sprintf("\nOrdem selecionada — AIC: %d | HQ: %d | SC: %d | FPE: %d\n",
            sel$selection["AIC(n)"], sel$selection["HQ(n)"],
            sel$selection["SC(n)"],  sel$selection["FPE(n)"]))

# Item 7: todos os critérios selecionam p=2.
# Com T=161 e k=3: cada lag adicional consome 9 parâmetros (3 equações × 3 variáveis).
# p=2 preserva graus de liberdade e captura dinâmica de curto prazo.
# No VECM a ordem de lags nas diferenças será p-1 = 1.
p_uso <- as.integer(sel$selection["SC(n)"])
cat(sprintf("Ordem usada: p = %d\n", p_uso))

# =============================================================================
# PARTE 4 – TESTE DE COINTEGRAÇÃO DE JOHANSEN
# =============================================================================
# Item 8 ─────────────────────────────────────────────────────────────────────
# ca.jo() com ecdet="none", K=p_uso=2, spec="longrun"
# Aplica os dois testes: estatística do traço e do máximo autovalor

jo_trace <- ca.jo(Y, type="trace", ecdet="none", K=p_uso, spec="longrun")
jo_eigen <- ca.jo(Y, type="eigen", ecdet="none", K=p_uso, spec="longrun")

cat("\n--- Johansen: Estatística do Traço ---\n")
print(summary(jo_trace))

cat("\n--- Johansen: Máximo Autovalor ---\n")
print(summary(jo_eigen))

# Extrai estatísticas e valores críticos; urca ordena de r=k-1 a r=0 → reverter
estat_t  <- rev(jo_trace@teststat)
cval_t   <- jo_trace@cval[nrow(jo_trace@cval):1, ]
estat_e  <- rev(jo_eigen@teststat)
cval_e   <- jo_eigen@cval[nrow(jo_eigen@cval):1, ]

tab_jo <- data.frame(
  Hipotese   = c("H0: r=0", "H0: r<=1", "H0: r<=2"),
  Traco_stat = round(estat_t, 3),
  T_CV10     = round(cval_t[,1], 3), T_CV5 = round(cval_t[,2], 3),
  T_CV1      = round(cval_t[,3], 3),
  Eigen_stat = round(estat_e, 3),
  E_CV10     = round(cval_e[,1], 3), E_CV5 = round(cval_e[,2], 3),
  E_CV1      = round(cval_e[,3], 3),
  stringsAsFactors = FALSE
)
print(tab_jo)
write.csv(tab_jo, file.path(out_dir, "tab04_johansen.csv"),
          row.names=FALSE, quote=FALSE)

# Item 9 ─────────────────────────────────────────────────────────────────────
# Decisão sobre r
# Traço: H0 r=0 → stat=30.94 | CV5%=31.52 → NÃO rejeita a 5% (margem: 0.58)
#                             | CV10%=28.71 → REJEITA a 10%
# Eigen: H0 r=0 → stat=18.27 | CV5%=21.07 → NÃO rejeita | CV10%=18.90 → NÃO rejeita
#
# ESCOLHA METODOLÓGICA: adoto r=1 com base em:
#   (a) O teste do traço rejeita H0:r=0 ao nível de 10% (stat 30.94 > CV 28.71)
#   (b) Raciocínio econômico: três preços da mesma cadeia produtiva têm forte
#       prior de cointegração (lei do preço único setorial)
#   (c) A diferença de 0.58 entre a estatística e o CV de 5% é muito pequena
#       para ser tomada como evidência definitiva de ausência de cointegração
#   (d) VAR em diferenças, se houver cointegração, é misspecificado (omite o ECT)
#
# Se r=0 fosse adotado: o VEC seria inviável, pois não haveria relação
# de equilíbrio de longo prazo para corrigir. O VAR em diferenças seria
# correto mas perderia informação de longo prazo.

r <- 1   # número de vetores de cointegração adotado
cat(sprintf("\nVetores de cointegração adotados: r = %d (traço a 10%% + prior econômico)\n", r))

# =============================================================================
# PARTE 5 – ESTIMAÇÃO DO MODELO VEC
# =============================================================================
# Item 10 ────────────────────────────────────────────────────────────────────
# Estimação do VECM por OLS dado r=1
# cajorls() retorna: $beta (k×r — vetores de cointegração)
#                    $rlm  (mlm — equações do VECM em forma de mlm)

vec_fit <- cajorls(jo_trace, r=r)

cat("\n--- Vetor de Cointegração Normalizado beta (normalização: l_brent = 1) ---\n")
beta_norm <- vec_fit$beta
print(round(beta_norm, 4))
write.csv(round(as.data.frame(beta_norm), 4),
          file.path(out_dir, "tab05_beta.csv"), quote=FALSE)

# Item 11 ────────────────────────────────────────────────────────────────────
# Coeficientes de ajustamento alpha e p-valores por equação
# cajorls retorna $rlm (mlm): cada equação tem nome "Response l_brent.d" etc.
# Extraímos coeficientes e p-valores diretamente do objeto summary(mlm).

resumo_vec <- summary(vec_fit$rlm)

# Salva resumo completo em texto
sink(file.path(out_dir, "vec_resumo.txt"))
print(resumo_vec)
sink()

# Nomes das respostas no objeto mlm (formato "Response <var>.d")
nomes_resp <- names(resumo_vec)
cat("\nNomes das equações no objeto mlm:", paste(nomes_resp, collapse=" | "), "\n")

# Função para extrair alpha e p-valor de cada equação
extr_ect <- function(resp_nome) {
  s <- resumo_vec[[resp_nome]]
  if (!is.null(s) && "ect1" %in% rownames(s$coefficients)) {
    c(alpha  = s$coefficients["ect1", "Estimate"],
      se     = s$coefficients["ect1", "Std. Error"],
      tstat  = s$coefficients["ect1", "t value"],
      pvalor = s$coefficients["ect1", "Pr(>|t|)"])
  } else c(alpha=NA, se=NA, tstat=NA, pvalor=NA)
}

# Identifica o nome correto de cada equação (pode variar por versão do urca)
find_eq <- function(padrao) {
  nomes_resp[grep(padrao, nomes_resp, value=FALSE)]
}
eq_brent <- find_eq("brent")
eq_dA    <- find_eq("dA")
eq_dB    <- find_eq("dB")

cat(sprintf("Equações encontradas: %s | %s | %s\n",
            eq_brent[1], eq_dA[1], eq_dB[1]))

e_brent <- extr_ect(eq_brent[1])
e_dA    <- extr_ect(eq_dA[1])
e_dB    <- extr_ect(eq_dB[1])

alpha_brent <- e_brent["alpha"]
alpha_dA    <- e_dA["alpha"]
alpha_dB    <- e_dB["alpha"]
p_brent     <- e_brent["pvalor"]
p_dA        <- e_dA["pvalor"]
p_dB        <- e_dB["pvalor"]

cat(sprintf("\nalpha (ect1): l_brent = %.4f (p=%.4f) | l_dA = %.4f (p=%.4f) | l_dB = %.4f (p=%.4f)\n",
            alpha_brent, p_brent, alpha_dA, p_dA, alpha_dB, p_dB))

# Meia-vida: -ln(2)/ln(1+alpha), válida apenas para alpha < 0
# Para alpha > 0 a variável se "afasta" do ECT diretamente (mas pode corrigir
# indiretamente via relação de equilíbrio — veja interpretação no LaTeX).
meia_vida <- function(a) {
  if (!is.na(a) && a < 0 && a > -2) round(-log(2)/log(1+a), 1) else NA
}
mv_brent <- meia_vida(alpha_brent)
mv_dA    <- meia_vida(alpha_dA)
mv_dB    <- meia_vida(alpha_dB)

cat(sprintf("Meia-vida (semanas): l_brent = %s | l_dA = %s | l_dB = %s\n",
            mv_brent, mv_dA, mv_dB))

tab_alpha <- data.frame(
  Equacao   = c("l_brent","l_dA","l_dB"),
  alpha     = round(c(alpha_brent, alpha_dA, alpha_dB), 4),
  EP        = round(c(e_brent["se"],  e_dA["se"],  e_dB["se"]),  4),
  t_stat    = round(c(e_brent["tstat"],e_dA["tstat"],e_dB["tstat"]),3),
  p_valor   = round(c(p_brent, p_dA, p_dB), 4),
  Meia_vida = c(mv_brent, mv_dA, mv_dB),
  stringsAsFactors = FALSE
)
print(tab_alpha)
write.csv(tab_alpha, file.path(out_dir, "tab07_alpha.csv"),
          row.names=FALSE, quote=FALSE)

# Item 12 ────────────────────────────────────────────────────────────────────
# Dinâmica de curto prazo (Gamma_1): coeficientes das diferenças defasadas
coef_mat <- coef(vec_fit$rlm)
cat("\n--- Matriz de Coeficientes do VECM ---\n")
print(round(coef_mat, 4))
write.csv(round(as.data.frame(coef_mat), 4),
          file.path(out_dir, "tab06_coeficientes_vec.csv"), quote=FALSE)

cat("\n--- Curto Prazo (Gamma_1): coeficientes e p-valores por equação ---\n")
for (eq in nomes_resp) {
  cat("\n  Equação:", eq, "\n")
  print(round(resumo_vec[[eq]]$coefficients, 4))
}

# =============================================================================
# PARTE 6 – DIAGNÓSTICOS
# =============================================================================
# Reconverte o VEC para VAR em níveis para usar as funções do pacote vars
var_fit <- vec2var(jo_trace, r=r)

# Identifica variáveis no objeto vec2var (nomes vêm de @x do ca.jo)
var_names_fit <- colnames(var_fit$y)
cat("\nVEC convertido para VAR em níveis.\n")
cat("Variáveis (via var_fit$y):", paste(var_names_fit, collapse=", "), "\n")

# Para funções que exigem "varest" (causality, stability), estimo um
# VAR em NÍVEIS auxiliar com os mesmos dados. No contexto VEC, isso implementa
# o teste de Toda-Yamamoto (VAR em níveis com inferência Wald) que é válido
# para séries cointegradas. Para serial, arch, normality e irf uso var_fit (vec2var).
var_niveis <- VAR(as.data.frame(Y), p=p_uso, type="const")

# Item 13 ────────────────────────────────────────────────────────────────────
# Autocorrelação serial multivariada (lags=12)
# H0: resíduos sem autocorrelação serial
# PT.asymptotic: Portmanteau assintótico (mais conservador)
# BG: Breusch-Godfrey (mais poderoso para autocorrelação em lags específicos)
cat("\n--- Autocorrelação Serial (PT.asymptotic, 12 lags) ---\n")
pt_test <- serial.test(var_fit, lags.pt=12, type="PT.asymptotic")
print(pt_test)

cat("\n--- Autocorrelação Serial (BG, 12 lags) ---\n")
bg_test <- serial.test(var_fit, lags.pt=12, type="BG")
print(bg_test)

sink(file.path(out_dir, "diag01_serial.txt"))
cat("=== PT.asymptotic ===\n"); print(pt_test)
cat("\n=== BG ===\n");           print(bg_test)
sink()

# Item 14 ────────────────────────────────────────────────────────────────────
# Heterocedasticidade condicional (ARCH multivariado, lags=5)
# H0: sem efeitos ARCH. Preços de commodities frequentemente exibem clusters de
# volatilidade. ARCH nos resíduos NÃO invalida o VECM mas afeta a eficiência
# dos IC bootstrap das IRF — por isso uso bootstrap em vez de IC analíticos.
cat("\n--- ARCH Multivariado (lags=5) ---\n")
arch_test <- arch.test(var_fit, lags.multi=5)
print(arch_test)

sink(file.path(out_dir, "diag02_arch.txt"))
print(arch_test)
sink()

# Item 15 ────────────────────────────────────────────────────────────────────
# Normalidade multivariada (Jarque-Bera)
# H0: resíduos normalmente distribuídos
# Não-normalidade NÃO invalida o VECM: com T=161, o TCL garante assintótica
# normal para os estimadores ML independentemente da distribuição dos erros.
cat("\n--- Normalidade (Jarque-Bera por equação e multivariado) ---\n")
norm_test <- normality.test(var_fit, multivariate.only=FALSE)
print(norm_test)

sink(file.path(out_dir, "diag03_normalidade.txt"))
print(norm_test)
sink()

# Salva JB por equação para tabela LaTeX
# Os nomes em jb.uni dependem do objeto (podem ser "resids of l_brent" no vec2var)
jb_uni_stats  <- sapply(norm_test$jb.uni,  function(x) x$statistic[[1]])
jb_uni_pvals  <- sapply(norm_test$jb.uni,  function(x) x$p.value[[1]])
jb_mult_stat  <- norm_test$jb.mul$JB$statistic[[1]]
jb_mult_pval  <- norm_test$jb.mul$JB$p.value[[1]]

cat("Equações JB uni:", paste(names(jb_uni_stats), collapse=" | "), "\n")
cat("Stats:", round(jb_uni_stats, 2), "\n")

tab_norm <- data.frame(
  Equacao = c(paste0("Eq.", 1:length(jb_uni_stats)), "Multivariado"),
  JB_stat = round(c(jb_uni_stats, jb_mult_stat), 2),
  p_valor = format(round(c(jb_uni_pvals, jb_mult_pval), 4), scientific=FALSE),
  stringsAsFactors = FALSE
)
print(tab_norm)
write.csv(tab_norm, file.path(out_dir, "tab08_normalidade.csv"),
          row.names=FALSE, quote=FALSE)

# Item 16 ────────────────────────────────────────────────────────────────────
# Estabilidade estrutural (OLS-CUSUM)
# stability() da classe varest não aceita vec2var diretamente.
# Aplico sobre o VAR nas diferenças (p=1), que corresponde às equações de
# curto prazo do VECM. Isso avalia estabilidade da dinâmica de curto prazo.
cat("\n--- Estabilidade OLS-CUSUM (VAR em níveis auxiliar) ---\n")
# stability() requer classe "varest"; uso var_niveis
stab <- stability(var_niveis, type="OLS-CUSUM")

png(file.path(out_dir, "fig04_cusum.png"), width=900, height=720)
plot(stab)
dev.off()
cat("fig04 (CUSUM) salva.\n")

# =============================================================================
# PARTE 7 – CAUSALIDADE DE GRANGER
# =============================================================================
# Item 17 ────────────────────────────────────────────────────────────────────
# Tabela 3×3 de Granger-causalidade par-a-par.
# Para cada par (causa → efeito), testo H0: os p=2 lags da variável "causa"
# na equação do "efeito" são conjuntamente iguais a zero (F-test por OLS).
# Abordagem de Toda-Yamamoto: VAR em níveis com inferência Wald, válida para
# séries I(1) com cointegração (evita o viés do VAR em diferenças).

cat("\n--- Causalidade de Granger par-a-par (tabela 3x3) ---\n")
cat("Variáveis:", paste(names(var_niveis$varresult), collapse=", "), "\n")

# F-test par-a-par em base R (sem dependências externas)
granger_par <- function(causa, efeito, var_obj) {
  eq_lm    <- var_obj$varresult[[efeito]]
  # reconstrói y e X a partir do objeto lm
  y_full   <- fitted(eq_lm) + residuals(eq_lm)
  X        <- model.matrix(eq_lm)
  lag_cols <- grep(paste0("^", causa, "\\.l"), colnames(X))
  if (length(lag_cols) == 0) return(c(F_stat=NA, p_valor=NA, df1=NA, df2=NA))
  q        <- length(lag_cols)
  k_full   <- ncol(X)
  rss_full <- sum(residuals(eq_lm)^2)
  X_r      <- X[, -lag_cols, drop=FALSE]
  rss_r    <- sum(lm.fit(X_r, y_full)$residuals^2)
  df_res   <- length(y_full) - k_full
  F_val    <- ((rss_r - rss_full) / q) / (rss_full / df_res)
  p_val    <- pf(F_val, q, df_res, lower.tail=FALSE)
  c(F_stat=round(F_val,3), p_valor=round(p_val,4), df1=q, df2=df_res)
}

vars_nms <- names(var_niveis$varresult)
tab_granger_par <- data.frame(Causa=character(), Efeito=character(),
                               F_stat=numeric(), p_valor=numeric(),
                               df1=integer(), df2=integer(),
                               stringsAsFactors=FALSE)
for (ca in vars_nms) {
  for (ef in vars_nms) {
    if (ca == ef) next
    res <- granger_par(ca, ef, var_niveis)
    cat(sprintf("  %s -> %s: F(%g,%g) = %.3f, p = %.4f\n",
                ca, ef, res["df1"], res["df2"], res["F_stat"], res["p_valor"]))
    tab_granger_par <- rbind(tab_granger_par, data.frame(
      Causa=ca, Efeito=ef, F_stat=res["F_stat"], p_valor=res["p_valor"],
      df1=res["df1"], df2=res["df2"], stringsAsFactors=FALSE
    ))
  }
}
write.csv(tab_granger_par, file.path(out_dir, "tab09_granger_par.csv"),
          row.names=FALSE, quote=FALSE)
print(tab_granger_par)

# Testes conjuntos (causa -> todas as outras) — mantidos para Item 18
cat("\n--- Causalidade conjunta ---\n")
g_brent <- causality(var_niveis, cause="l_brent")
g_dA    <- causality(var_niveis, cause="l_dA")
g_dB    <- causality(var_niveis, cause="l_dB")
cat("l_brent (conjunto):\n"); print(g_brent$Granger)
cat("l_dA (conjunto):\n");    print(g_dA$Granger)
cat("l_dB (conjunto):\n");    print(g_dB$Granger)

extr_g <- function(g) c(
  F_stat  = round(g$Granger$statistic[[1]], 3),
  p_valor = round(g$Granger$p.value, 4)
)

# Item 18 ────────────────────────────────────────────────────────────────────
# Classificação: combina alpha (longo prazo) e Granger (curto prazo)
cat("\n--- Classificação Endogeneidade / Exogeneidade ---\n")

classif <- function(nome, alpha, p_alpha, p_granger) {
  sig_alpha   <- !is.na(p_alpha)   && p_alpha   < 0.05
  sig_granger <- !is.na(p_granger) && p_granger < 0.05
  tipo <- if (sig_alpha  && sig_granger)  "Endógena CP e LP"  else
          if (sig_alpha  && !sig_granger) "Endógena só LP"    else
          if (!sig_alpha)                 "Fracamente exógena" else
                                          "Indeterminada"
  cat(sprintf("  %s: alpha=%.4f (p=%.4f) | Granger p=%.4f | %s\n",
              nome, alpha, p_alpha, p_granger, tipo))
}

# Nota: p_granger do teste "variável i causa as demais"
classif("l_brent", alpha_brent, p_brent, extr_g(g_brent)["p_valor"])
classif("l_dA",    alpha_dA,    p_dA,    extr_g(g_dA)["p_valor"])
classif("l_dB",    alpha_dB,    p_dB,    extr_g(g_dB)["p_valor"])

# =============================================================================
# PARTE 8 – FUNÇÕES IMPULSO-RESPOSTA (IRF)
# =============================================================================
# Item 19 ────────────────────────────────────────────────────────────────────
# Ordenamento de Cholesky: l_brent → l_dA → l_dB
# Justificativa: Brent determina o custo da matéria-prima; o produtor (Diesel A)
# repassa para o distribuidor (Diesel B). Cholesky assume que o mais exógeno
# (Brent) não responde a choques contemporâneos dos demais.
# No VEC, choques têm efeitos permanentes → IRF não converge a zero (séries I(1))

cat("\n--- Estimando IRF (20 semanas, bootstrap 99 rep., IC 95%) ---\n")
irf_fit <- irf(var_fit, n.ahead=20, boot=TRUE, ci=0.95, runs=99)

png(file.path(out_dir, "fig05_irf_full.png"), width=1100, height=960)
par(oma=c(0, 0, 3, 0))   # margem externa superior para título global
plot(irf_fit)
mtext("IRF VECM Cadeia do Diesel | Cholesky: l_brent -> l_dA -> l_dB | IC bootstrap 95% (99 rep.)",
      outer=TRUE, cex=0.9, font=2, line=1)
dev.off()
cat("fig05 (IRF completa) salva.\n")

# Item 20 ────────────────────────────────────────────────────────────────────
# IRF específicas: l_dB ~ l_brent, l_dA ~ l_brent, l_dB ~ l_dA
irf_dB_brent <- irf(var_fit, impulse="l_brent", response="l_dB",
                     n.ahead=20, boot=TRUE, ci=0.95, runs=99)
irf_dA_brent <- irf(var_fit, impulse="l_brent", response="l_dA",
                     n.ahead=20, boot=TRUE, ci=0.95, runs=99)
irf_dB_dA    <- irf(var_fit, impulse="l_dA",    response="l_dB",
                     n.ahead=20, boot=TRUE, ci=0.95, runs=99)

# Extrai valores para comentar no LaTeX
h <- 0:20
cat("\n--- IRF: resposta de l_dB a choque em l_brent (h=0..5 e h=20) ---\n")
resp_dB_brent <- irf_dB_brent$irf$l_brent
cat(round(resp_dB_brent[1:6], 5), "...", round(resp_dB_brent[21], 5), "\n")

cat("--- IRF: resposta de l_dA a choque em l_brent ---\n")
resp_dA_brent <- irf_dA_brent$irf$l_brent
cat(round(resp_dA_brent[1:6], 5), "...", round(resp_dA_brent[21], 5), "\n")

# Salva IRF numericamente
irf_vals <- data.frame(
  h              = h,
  ldB_lbrent_irf = irf_dB_brent$irf$l_brent,
  ldB_lbrent_lo  = irf_dB_brent$Lower$l_brent,
  ldB_lbrent_hi  = irf_dB_brent$Upper$l_brent,
  ldA_lbrent_irf = irf_dA_brent$irf$l_brent,
  ldA_lbrent_lo  = irf_dA_brent$Lower$l_brent,
  ldA_lbrent_hi  = irf_dA_brent$Upper$l_brent,
  ldB_ldA_irf    = irf_dB_dA$irf$l_dA,
  ldB_ldA_lo     = irf_dB_dA$Lower$l_dA,
  ldB_ldA_hi     = irf_dB_dA$Upper$l_dA
)
write.csv(round(irf_vals, 5), file.path(out_dir, "tab10_irf_valores.csv"),
          row.names=FALSE, quote=FALSE)

# Gráfico IRF específicas
png(file.path(out_dir, "fig06_irf_especificas.png"), width=900, height=900)
par(mfrow=c(3,1), mar=c(3,4,2.5,1))

plot(h, irf_dB_brent$irf$l_brent, type="l", col="steelblue", lwd=2,
     ylim=range(c(irf_dB_brent$Lower$l_brent, irf_dB_brent$Upper$l_brent)),
     xlab="Horizonte (semanas)", ylab="Resposta",
     main="Resposta de l_dB a choque unitário em l_brent")
lines(h, irf_dB_brent$Upper$l_brent, lty=2, col="gray50")
lines(h, irf_dB_brent$Lower$l_brent, lty=2, col="gray50")
abline(h=0)

plot(h, irf_dA_brent$irf$l_brent, type="l", col="darkorange", lwd=2,
     ylim=range(c(irf_dA_brent$Lower$l_brent, irf_dA_brent$Upper$l_brent)),
     xlab="Horizonte (semanas)", ylab="Resposta",
     main="Resposta de l_dA a choque unitário em l_brent")
lines(h, irf_dA_brent$Upper$l_brent, lty=2, col="gray50")
lines(h, irf_dA_brent$Lower$l_brent, lty=2, col="gray50")
abline(h=0)

plot(h, irf_dB_dA$irf$l_dA, type="l", col="darkgreen", lwd=2,
     ylim=range(c(irf_dB_dA$Lower$l_dA, irf_dB_dA$Upper$l_dA)),
     xlab="Horizonte (semanas)", ylab="Resposta",
     main="Resposta de l_dB a choque unitário em l_dA")
lines(h, irf_dB_dA$Upper$l_dA, lty=2, col="gray50")
lines(h, irf_dB_dA$Lower$l_dA, lty=2, col="gray50")
abline(h=0)

dev.off()
cat("fig06 (IRF específicas) salva.\n")

# =============================================================================
# PARTE 9 – DECOMPOSIÇÃO DA VARIÂNCIA (FEVD)
# =============================================================================
# Item 22 ────────────────────────────────────────────────────────────────────
cat("\n--- FEVD (horizonte 20) ---\n")
fevd_fit <- fevd(var_fit, n.ahead=20)

png(file.path(out_dir, "fig07_fevd.png"), width=900, height=720)
plot(fevd_fit)
dev.off()
cat("fig07 (FEVD) salva.\n")

# Tabelas FEVD para horizontes selecionados
horizontes <- c(1, 4, 8, 12, 20)

tabela_fevd <- function(var_nome) {
  m     <- fevd_fit[[var_nome]]
  m_sel <- round(m[horizontes, ] * 100, 2)
  df    <- as.data.frame(m_sel)
  df$Horizonte <- horizontes
  df$Total     <- rowSums(df[, 1:3])
  df[, c("Horizonte", colnames(m)[1:3], "Total")]
}

tab_fevd_brent <- tabela_fevd("l_brent")
tab_fevd_dA    <- tabela_fevd("l_dA")
tab_fevd_dB    <- tabela_fevd("l_dB")

cat("\nFEVD — l_brent:\n"); print(tab_fevd_brent)
cat("\nFEVD — l_dA:\n");    print(tab_fevd_dA)
cat("\nFEVD — l_dB:\n");    print(tab_fevd_dB)

write.csv(tab_fevd_brent, file.path(out_dir, "tab11a_fevd_brent.csv"), row.names=FALSE)
write.csv(tab_fevd_dA,    file.path(out_dir, "tab11b_fevd_dA.csv"),    row.names=FALSE)
write.csv(tab_fevd_dB,    file.path(out_dir, "tab11c_fevd_dB.csv"),    row.names=FALSE)

# =============================================================================
# FINALIZAÇÃO
# =============================================================================
cat("\n=== Script concluído. Outputs em:", out_dir, "===\n")
cat(paste(sort(list.files(out_dir)), collapse="\n"), "\n")
