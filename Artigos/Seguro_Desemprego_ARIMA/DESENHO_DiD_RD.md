# Desenho de identificação em microdados — Lei 13.134/2015 (Seguro-Desemprego)

**Status:** esboço (spec) · **Data:** 2026-09-30
**Motivação:** a análise agregada (`scripts/` 03–07) mostrou que o efeito da Lei
**não é identificável com séries nacionais**, porque a reforma (jun–jul/2015)
coincidiu com a recessão de 2015–16. A solução é explorar a **descontinuidade de
elegibilidade** que a Lei criou, com um grupo de controle que enfrenta a mesma
macroeconomia — differencing-out da recessão.

---

## 1. A política e a descontinuidade

A Lei 13.134/2015 tornou o requisito de tempo de vínculo **específico por ordem de
solicitação** (antes: ~6 meses nos últimos 36, para qualquer solicitação):

| Solicitação | Regra ANTES | Regra DEPOIS (Lei 13.134) | Salto |
|---|---|---|---|
| **1ª** | ≥ 6 meses | **≥ 12 meses nos últimos 18** | **6 → 12** |
| 2ª | ≥ 6 meses | ≥ 9 meses nos últimos 12 | 6 → 9 |
| 3ª+ | ≥ 6 meses | ≥ 6 meses | inalterado |

> A **1ª solicitação** é a margem mais afetada e mais limpa (o limiar dobra). O grupo
> de 3ª+ solicitação é um **placebo natural** (regra inalterada).

**Datas:** MP 665 (30/12/2014, com regras iniciais mais duras) → conversão na Lei
13.134 (16/06/2015). A vigência efetiva e a possível **antecipação** desde dez/2014
precisam ser tratadas (ver §7).

---

## 2. Estratégia de identificação (dois desenhos complementares)

### Desenho A — Regression Discontinuity (RD) no tempo de vínculo
- **Variável de corte (running variable):** meses de vínculo qualificável na janela
  de referência, na data da dispensa; centrada no limiar `c = 12` (1ª solicitação).
- **Tratamento:** `Elig = 1{tenure ≥ 12}` para dispensas **após** a reforma.
- **Estimando:** efeito **local** da elegibilidade ao SD na margem (LATE no corte).
- **Sharp na elegibilidade / fuzzy no recebimento:** ser elegível é determinístico em
  `tenure`; receber o benefício não (nem todo elegível solicita). Para desfechos
  comportamentais, usar **fuzzy RD** com `Elig` instrumentando "recebeu SD".
- Estimação com `rdrobust` (kernel triangular, banda MSE-ótima, IC bias-corrected);
  densidade de manipulação com `rddensity` (McCrary).

### Desenho B — Diff-in-Discontinuities / DiD na reforma (identificação principal)
Resolve o confundidor da recessão comparando quem **perdeu** elegibilidade com quem a
manteve, na mesma conjuntura:

- **Grupo tratado:** dispensados de 1ª solicitação com vínculo na **faixa [6, 12)**
  meses — elegíveis **antes**, inelegíveis **depois**.
- **Grupo controle:** vínculo **≥ 12 meses** (elegíveis antes e depois). Placebo
  adicional: vínculo **< 6 meses** (inelegíveis sempre) e **3ª+ solicitação**.
- **DiD:** variação de desfecho da faixa [6,12) através da reforma vs. o grupo
  sempre-elegível. A recessão afeta ambos → sai na diferença.
- **Diff-in-disc:** compara o *tamanho da descontinuidade* no corte antes vs. depois
  — a especificação mais robusta (combina A e B).

---

## 3. Desfechos (Y)

**Mecânicos / primeira etapa**
- P(solicita SD | dispensa); P(recebe SD); nº de parcelas; valor recebido.

**Comportamentais / bem-estar (o interesse do artigo)**
- **Tempo até reemprego formal** (duração; modelo de risco/hazard).
- P(reemprego formal em 3/6/12 meses).
- **Salário no reemprego** (qualidade do match — moral hazard vs. liquidez).
- Transição para **informalidade** (proxy: ausência do RAIS/CAGED por N meses;
  idealmente cruzar com PNAD Contínua para robustez).
- Rotatividade / churning subsequente.

---

## 4. Dados e ligação (por PIS)

| Base | Papel | Acesso |
|---|---|---|
| **RAIS** (anual, identificada) | vínculos, tenure, salário, datas, reemprego | restrito (MTE) |
| **CAGED** (mensal, identificado) | data de dispensa, **motivo (dispensa s/ justa causa)** | restrito (MTE) |
| **BGSD** (registro do SD) | solicitação/recebimento efetivo do benefício, ordem da solicitação | restrito (MTE) — usado no TD 3059 |

**Ligação:** por **PIS**, construindo o histórico de vínculos (tenure e ordem de
solicitação) e o painel de reemprego pós-dispensa. Fonte-espelho pública para
prototipagem da estrutura (sem identificação): RAIS/CAGED no **Base dos Dados**
(BigQuery) — serve para desenvolver o código antes do acesso identificado.

> **Risco prático nº 1 = acesso.** RAIS/CAGED/BGSD identificados exigem convênio/lab
> (MTE, ou ambiente seguro). Definir a via de acesso é pré-requisito. Enquanto isso,
> desenvolver todo o pipeline sobre a estrutura pública (não-identificada).

---

## 5. Construção da amostra e da running variable

- **Universo:** dispensas **sem justa causa** de trabalhadores formais (CAGED motivo),
  **1ª solicitação**, em janela de **±18 meses** em torno da vigência.
- **Running variable:** meses com vínculo/salário na janela de referência (18 meses
  antes da dispensa), conforme a contagem legal. Definição deve **espelhar a lei**;
  documentar a regra de contagem e testar sensibilidade a ela.
- **Restrições:** excluir modalidades especiais (pescador, doméstico, resgatado);
  um registro por evento de dispensa; tratar múltiplas dispensas do mesmo PIS.

---

## 6. Equações

**RD (sharp na elegibilidade), banda `|tenure−c|<h`:**
```
Y_i = α + τ·Elig_i + f(tenure_i − c) + Elig_i·g(tenure_i − c) + ε_i
```
`τ` = efeito da elegibilidade no corte (linear local, kernel triangular).

**DiD (faixa que perde elegibilidade vs. sempre-elegível):**
```
Y_ist = α + β·(Excluido_i × Pos_t) + γ·Excluido_i + δ_t + X_i'θ + ε_ist
Excluido_i = 1{tenure ∈ [6,12)} ;  Pos_t = 1{dispensa após a reforma}
```
`β` = efeito de **perder** a elegibilidade ao SD. Versão **event-study** com leads/lags
(checagem de tendências paralelas e de antecipação).

**Fuzzy RD (2SLS) para desfechos comportamentais:** `Elig` instrumenta `RecebeSD`.

---

## 7. Ameaças à identificação e diagnósticos

| Ameaça | Diagnóstico / mitigação |
|---|---|
| **Manipulação do corte** (firma adia dispensa p/ tornar elegível, ou antecipa) | `rddensity`/McCrary no tenure em 12 meses; **donut RD** removendo bins colados ao corte |
| **Antecipação** (MP 665 desde dez/2014) | usar datas alternativas (MP vs Lei); janela-donut na data; event-study |
| **Composição das dispensas** muda com a recessão | é exatamente o que o **grupo controle** do DiD absorve; testar pré-tendências |
| **Tratamento composto** (a Lei mudou também abono, seguro-defeso) | restringir à modalidade formal; abono atinge outra população; controlar |
| **Regras por ordem de solicitação** (2ª/3ª mudaram diferente) | restringir à **1ª solicitação**; usar 3ª+ como **placebo** (regra inalterada) |
| **Balanceamento de covariáveis** no corte | testar continuidade de X (idade, sexo, salário, setor) em `c` |

---

## 8. Plano de execução (pipeline `scripts/micro/`)

1. `10_build_spells.R` — reconstruir vínculos/tenure e ordem de solicitação por PIS.
2. `11_sample.R` — universo de dispensas s/ justa causa, 1ª solicitação, janela ±18m.
3. `12_running_var.R` — running variable + `Elig`/`Excluido` + covariáveis.
4. `13_rd.R` — `rdrobust` + `rddensity` + gráficos RD (sharp e fuzzy).
5. `14_did.R` — DiD/event-study (`fixest::feols`), pré-tendências, placebos.
6. `15_diagnostics.R` — balanceamento, donut, sensibilidade de banda/kernel.
7. Pacotes: `rdrobust`, `rddensity`, `fixest`, `data.table`, `did` (se staggered).

**Prototipagem sem dados identificados:** rodar 10–15 sobre RAIS/CAGED do Base dos
Dados para validar a lógica e a construção da running variable antes do acesso.

---

## 9. O que este desenho entrega que o agregado não deu

- **Identificação limpa** do efeito da Lei, imune à recessão de 2015–16 (grupo de
  controle na mesma conjuntura).
- Efeitos de **bem-estar** (reemprego, salário, informalidade), não só a contagem de
  solicitações — a pergunta economicamente interessante (liquidez vs. moral hazard).
- Conexão direta com a literatura de UI design (efeito da generosidade/elegibilidade
  do seguro-desemprego sobre duração do desemprego e qualidade do reemprego).
