---
paths:
  - "**/*sdid*.R"
  - "**/*synthdid*.R"
  - "**/*synthetic*.R"
  - "**/*sc_estimate*.R"
  - "scripts/R/**/*.R"
---

# SDiD / Synthetic DiD Conventions (synthdid standard)

Methodological standards for Synthetic Difference-in-Differences via the `synthdid` R package (Arkhangelsky, Athey, Hirshberg, Imbens & Wager, 2021, *JASA*). This rule governs every `.R` file that estimates SDiD, SC, or DiD via `synthdid` in this project.

**The governing principle:** SDiD is a variance-weighted combination of SC and DiD. Report all three estimators (`synthdid`, `sc_estimate`, `did_estimate`) as a triangulation — convergence strengthens identification; divergence demands explanation.

---

## Data Format — HARD

- `synthdid` requires a **wide-format outcome matrix** (N units × T periods) + a scalar treatment indicator, NOT long format.
- Conversion pipeline: long panel → `panel.matrices()` from the `synthdid` package.
  ```r
  setup <- panel.matrices(data, unit = "id_municipio", time = "periodo",
                          outcome = "admissoes", treatment = "tratado")
  # setup$Y  : N×T outcome matrix
  # setup$W  : N×T treatment matrix (0/1, absorbing)
  ```
- Treatment must be **absorbing** (once treated = always treated). Verify: `all(apply(setup$W, 1, function(w) all(diff(w[w > 0]) >= 0)))`.
- Panel must be **balanced** before calling `panel.matrices()`. Drop or impute missing unit-periods first and document the choice.
- `periodo` must be **numeric** (year-month as integer: e.g., 202401). Never string or Date.

---

## Estimators and Their Uses — HARD

```r
# Main estimator (SDiD)
tau_sdid <- synthdid_estimate(setup$Y, setup$W)

# Robustness 1 — Synthetic Control
tau_sc   <- sc_estimate(setup$Y, setup$W)

# Robustness 2 — DiD
tau_did  <- did_estimate(setup$Y, setup$W)
```

- **SDiD** = headline estimator. Report as primary result.
- **SC** = robustness check. Sensitivity to unit weights.
- **DiD** = robustness check. Baseline no-weighting counterfactual.
- Never present SC or DiD as the primary result in this paper.

---

## Inference — HARD

```r
set.seed(PROJECT_SEED)  # sempre antes de qualquer estimação bootstrap/placebo

# Placebo SE (padrão de publicação para SDiD)
se_sdid <- synthdid_se(tau_sdid, method = "placebo")

# Bootstrap SE (cross-check, não headline)
se_boot <- synthdid_se(tau_sdid, method = "bootstrap", nboot = 500L)
```

- `method = "placebo"` é o padrão de publicação para SDiD — reportar sempre.
- `method = "bootstrap"` é cross-check obrigatório — relatar se divergir de "placebo" em mais de 20%.
- `method = "jackknife"` é alternativa aceitável quando N_tratados < 5.
- Nunca reportar apenas SE analítico sem validação por placebo.
- `nboot` ≥ 500L para relatórios; ≥ 1000L para submissão.

---

## Testes Placebo e Permutação — HARD (todos obrigatórios)

```r
# Placebo in-space: permutar unidades de controle como se fossem tratadas
placebo_estimates <- synthdid_placebo(tau_sdid, nplacebo = 100L)

# P-valor por permutação (proporção de placebo |τ| ≥ |τ_estimado|)
pval_permutation <- mean(abs(placebo_estimates) >= abs(tau_sdid))
```

- Reportar distribuição dos placebos como histograma com linha vertical em `τ_SDiD`.
- Reportar `pval_permutation` na tabela de resultados.
- Se N_controles < 20: avisar sobre poder reduzido do teste de permutação.

---

## Visualização — HARD (todos obrigatórios)

```r
# Trajetória sintética vs tratada
synthdid_plot(tau_sdid)

# Pesos das unidades de controle (obrigatório reportar)
synthdid_units_plot(tau_sdid)

# Comparação dos três estimadores (forest plot)
# → Usar ggplot2 com theme_custom(); ver scripts/R/05_figures.R
```

- `synthdid_plot()`: mostrar período pré-tratamento + trajetória pós; linha vertical no evento (maio/2024).
- `synthdid_units_plot()`: identificar se alguma unidade de controle domina os pesos (peso > 0.3 em uma única unidade = vulnerabilidade a identificar e discutir).
- **Forest plot de triangulação** (`τ_SDiD`, `τ_SC`, `τ_DiD` com IC): mostrar em figura separada. Convergência = evidência adicional de robustez; divergência = discutir no manuscrito.
- Todos os plots: `ggsave(..., bg = "transparent")` e `theme_custom()` para consistência visual.

---

## Estrutura de Saída (Scripts) — HARD

```r
# Salvar estimativas como lista nomeada
results_sdid <- list(
  tau      = as.numeric(tau_sdid),
  se_placebo = se_sdid,
  se_boot  = se_boot,
  pval_perm = pval_permutation,
  weights  = attr(tau_sdid, "unit.weights"),
  estimator = "SDiD"
)
saveRDS(results_sdid, here::here("scripts/R/_outputs/results_sdid.rds"))
```

- Um `.rds` por estimador (`results_sdid.rds`, `results_sc.rds`, `results_did.rds`).
- Tabela consolidada como `results_table.csv` com colunas: `estimador, tau, se, ci_lo, ci_hi, pval_perm`.
- Figures salvas em `scripts/R/_outputs/figures/` como PDF e PNG.

---

## Triangulação (Protocolo de Robustez) — HARD

Reportar SDiD, SC e DiD juntos em um **forest plot de triangulação** com:
- Ponto: estimativa pontual
- Barras: IC 95% (via SE placebo para SDiD; bootstrap para SC e DiD)
- Linha vertical em 0
- Tabela complementar com N, SE, p-valor para cada estimador

Convergência dos três = robustez metodológica forte. Divergência SDiD↔SC = discutir pesos unit-level. Divergência SDiD↔DiD = discutir parallel trends assumption.

---

## Pitfalls — NÃO FAZER

- ❌ Não usar `synthdid` com **tratamento contínuo** (para isso: ver `did-conventions.md` → `contdid`).
- ❌ Não confundir `sc_estimate()` (do `synthdid`) com o SC clássico de Abadie (diferem no target e na normalização dos pesos).
- ❌ Não omitir pesos das unidades de controle — peso concentrado em uma única unidade é vulnerabilidade metodológica.
- ❌ Não reportar apenas SDiD sem a triangulação SC/DiD como robustez.
- ❌ Não rodar inferência sem `set.seed()` — resultados não-reproduzíveis bloqueiam `/commit`.
- ❌ Não usar dados em formato long diretamente — converter via `panel.matrices()` primeiro.
- ❌ Não omitir teste de balanceamento do painel antes de estimar.

---

## Cross-references

- [`.claude/rules/did-conventions.md`](did-conventions.md) — padrões para Callaway–Sant'Anna DiD (estimador complementar neste projeto).
- [`.claude/rules/r-code-conventions.md`](r-code-conventions.md) — convenções gerais de código R.
- [`.claude/rules/replication-protocol.md`](replication-protocol.md) — replicar resultados antes de estender.
- [`.claude/rules/inference-robustness.md`](inference-robustness.md) — testes placebo, permutação, múltipla hipótese.
- [`.claude/skills/did-event-study/SKILL.md`](../skills/did-event-study/SKILL.md) — pipeline DiD (para o TWFE-DiD de robustez).
