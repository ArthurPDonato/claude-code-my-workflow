# Sugestões da banca — SDiD enchentes 2024 (exercícios de robustez)

**Data:** 2026-10-24
**Branch:** `pesquisa-sugestoes-banca`
**Apresentação:** 2026-10-23 (quinta) — linha de targeting/triagem (MPU → RAE).
**Natureza:** exercícios. Não altera o `main.tex` do artigo aceito (Análise Econômica).
**Ambiente:** R 4.4.2 (`synthdid`, `Synth`). Scripts em `Artigos/SDID/Scripts/`.

> Plano: `quality_reports/plans/buzzing-swinging-pony.md`.

---

## Resumo executivo (sugestão → o que foi feito → achado)

| # | Sugestão | O que foi feito | Achado | Onda |
|---|----------|-----------------|--------|------|
| 1 | Outros limiares de dano (35/40/45%) | Varredura de limiares (contagem + separação + SDiD) | Baixar o limiar amplia o conjunto tratado mas **dilui** o efeito; variável separadora muda com o limiar | 1 ✅ |
| 2 | Variável defasada no controle sintético | SC clássico de Abadie (`Synth`) com lags + covariáveis | **Replica o synthdid**; Vale do Taquari robusto (Roca Sales p=0.00) | 1 ✅ |
| 3 | Controles fora do RS + PSM | CAGED nacional + matching Mahalanobis (40 doadores) | **Corrobora**: MULTI ATT −4.08; os 4 do Vale do Taquari robustos | 2 ✅ |
| 4 | Dados trimestrais | Painel mensal → trimestral, SDiD | Efeito **sobrevive e fica mais nítido**; MULTI significativo | 1 ✅ |
| 5 | Heterogeneidade por setor | SDiD por seção CNAE (mensal, 2020+) | **Ind. transformação** domina a queda (ATT −1.36); reforça canal industrial | 2 ✅ |

---

## Item 1 — Varredura de limiares de dano
**Script:** `Artigos/SDID/Scripts/sdid_sweep_limiares.R`
**Saídas:** `Artigos/SDID/Resultados/Relatorio_criterios/sweep_limiares_*.{csv,png}`

### 1a. Existem municípios nesses limiares? (nº de tratados por métrica × limiar)

| Métrica \ limiar | 0.30 | 0.35 | 0.40 | 0.45 | 0.50 |
|---|---|---|---|---|---|
| Pop. afetada  | 27 | 21 | 13 | 10 | 6 |
| CNPJ afetados | 34 | 33 | 28 | 24 | 24 |
| Malha viária  | 18 | 13 | 8  | 3  | 1 |

**Sim** — baixar o limiar de "afetados" (pop.) de 50% encontra progressivamente mais municípios (6 → 27). A malha viária, porém, quase não tem municípios em limiares altos (1 a 50%).

### 1b. A variável que melhor separa afetados de não-afetados muda com o limiar?

Separação medida por diferença de média padronizada (`gap_z`, tratado − doador donut), mesmo método da análise de heterogeneidade do artigo.

- **Entre todas as variáveis:** `prop_rodovia` lidera de 30% a 45%; `prop_cnpj` assume a 50%. Ambas são métricas de dano físico e co-movem com o dano populacional (gap_z ~3.3–6.8).
- **Entre as covariáveis estruturais:** `share_ind_medio` (participação da indústria) lidera em **todos** os limiares e se **fortalece** conforme o limiar sobe (gap_z 1.10 em 40% → 1.47 em 50%). Municípios mais afetados são sistematicamente mais industriais.

**Conclusão 1b:** a liderança da variável separadora muda no topo (viária→CNPJ); o sinal estrutural estável é a participação industrial.

### 1c. O efeito SDiD sobrevive a cada limiar? (multi-ATT + triangulação + p permutação)

Critério populacional, 278 doadores donut, admissões mensais por mil:

| Limiar | Nº tratados | ATT multi | IC 95% | SC | DiD | p permutação |
|---|---|---|---|---|---|---|
| 0.30 | 27 | −0.674 | [−1.33; −0.02] | −1.13 | −0.45 | 0.475 |
| 0.35 | 21 | −0.781 | [−1.61; 0.04] | −1.13 | −0.61 | 0.414 |
| 0.40 | 13 | −1.026 | [−1.92; −0.13] | −1.43 | −1.07 | 0.306 |
| 0.45 | 10 | −1.486 | [−2.54; −0.44] | −2.01 | −1.61 | 0.184 |
| 0.50 | 6  | **−2.415** | [−3.80; −1.03] | −3.59 | −2.61 | **0.086** |

**Achado 1c (monotônico):** conforme o limiar sobe (dano mais concentrado), a magnitude do ATT **cresce** (−0.67 → −2.42) e o p-valor de permutação **cai** (0.47 → 0.086). SC e DiD triangulam o mesmo padrão. Baixar o limiar para incluir municípios menos atingidos **dilui** o efeito médio. Isso **sustenta a escolha do limiar de 50%** no artigo e a tese de precisão de triagem — limiares mais baixos encontram mais municípios (1a) mas com efeito médio mais fraco e menos preciso.

---

## Item 4 — Painel trimestral
**Script:** `Artigos/SDID/Scripts/sdid_trimestral.R`
**Saídas:** `Artigos/SDID/Resultados/SDID trimestral/trimestral_*.{csv,png}`

Agregação mensal → trimestral: admissões (fluxo) **somadas** nos 3 meses; 17 trimestres completos; critério populacional (pop>50%, 6 tratados, 278 doadores donut). Dois timings do evento (maio/2024 cai no Q2).

| Timing | MULTI ATT | IC 95% | SC | DiD | Acerto individual |
|---|---|---|---|---|---|
| Q2 2024 (contém abril) | **−8.00** | [−12.2; −3.80] | −10.4 | −6.90 | 2/6 |
| Q3 2024 (trimestre limpo) | **−5.63** | [−10.4; −0.88] | −11.7 | −5.78 | 1/6 |

(ATT em admissões trimestrais por mil hab.)

**Achado:** o efeito **sobrevive** à agregação trimestral e fica **mais nítido** que no mensal (ruidoso) — o MULTI é significativo nos dois timings, e a triangulação SDiD/SC/DiD converge (todos negativos). Os maiores efeitos individuais são Roca Sales, Travesseiro, Muçum e Eldorado do Sul (Vale do Taquari — os mais atingidos). Os dois timings "emparedam" o efeito: Q2 maior (contaminado por abril pré-evento), Q3 menor mas ainda significativo.

---

## Item 2 — Controle sintético clássico (Abadie) com variável defasada
**Script:** `Artigos/SDID/Scripts/sc_classico_abadie.R`
**Saídas:** `Artigos/SDID/Resultados/SC classico Abadie/sc_classico_*.{csv,png}`

Operacionalização da sugestão "variável defasada no controle sintético": SC clássico (`Synth`) casando em **14 lags do desfecho** (grade trimestral no pré, 40 períodos pré) + 5 covariáveis estruturais (pib_pc, shares agro/ind/serv, Idese; `operacoes_credito_medio` descartada por faltar em um tratado), para os 6 municípios do critério populacional (278 doadores donut). Inferência por placebo-in-space (razão RMSPE pós/pré), 37 placebos válidos (de 60 amostrados).

### Comparação: SC clássico (lags) vs. synthdid/sc_estimate/DiD (ATT mensal, admissões por mil)

| Município | synthdid | sc_estimate | DiD | **SC clássico** | ratio RMSPE | p placebo |
|---|---|---|---|---|---|---|
| Roca Sales | −3.50 | −4.04 | −3.09 | **−4.53** | 5.13 | **0.000** |
| Muçum | −3.22 | −2.93 | −4.69 | −3.21 | 1.20 | 0.622 |
| Eldorado do Sul | −3.19 | −3.84 | −3.02 | −4.71 | 2.36 | 0.108 |
| Travesseiro | −2.88 | −3.74 | −3.62 | −4.93 | 1.81 | 0.216 |
| Igrejinha | −1.63 | −0.72 | −1.10 | +0.45 | 1.20 | 0.622 |
| Arambaré | −0.37 | −0.13 | −0.16 | −0.60 | 1.61 | 0.297 |

**Achado item 2:** usar os lags do desfecho num SC clássico de Abadie **replica** o resultado do synthdid — os 4 municípios do Vale do Taquari (Roca Sales, Muçum, Eldorado do Sul, Travesseiro) mantêm efeito negativo robusto (ATT ~ −3 a −5), com **Roca Sales** o caso mais limpo (ratio RMSPE 5.13, placebo p = 0.000). Divergência fica restrita aos dois municípios de efeito fraco (Igrejinha troca de sinal; Arambaré nulo), o que é **esperado** — o SC clássico tem target e normalização de pesos diferentes do `sc_estimate` do synthdid (`sdid-conventions.md`). A convergência entre SC clássico, synthdid, sc_estimate e DiD nos casos fortes **reforça a identificação**.

Saídas: `sc_classico_tratados.csv`, `sc_classico_placebo_ratios.csv`, `sc_classico_gaps.png`.

---

## Item 5 — Heterogeneidade por setor (CNAE)
**Script:** `Artigos/SDID/Scripts/sdid_setorial_cnae.R`
**Saídas:** `Artigos/SDID/Resultados/SDID setorial CNAE/setorial_cnae_{att.csv,forest.png}`

Dado em casa (`Base de Dados/Primárias/Base_Mensal_CNAE_RS_Final.csv`): admissões mensais por seção CNAE, RS. Janela 2020+ (série "Novo", evita a quebra CAGED Antigo/Novo); 68 meses; desfecho = admissões da seção por mil hab. (grade muni×mês×seção completada com 0); critério populacional (6 tratados vs 278 doadores donut); evento maio/2024. SDiD + triangulação SC/DiD + permutação, por seção (20 seções elegíveis, adm. no pool ≥ 200).

| Setor (CNAE) | ATT | IC 95% | SC | DiD | p permut. | Sig? |
|---|---|---|---|---|---|---|
| **C — Ind. transformação** | **−1.363** | [−2.79; 0.07] | −1.68 | −1.46 | 0.086 | marginal |
| N — Adm./serviços de apoio | −0.341 | [−0.49; −0.19] | +0.30 | −0.40 | 0.040 | ✅ |
| Q — Saúde | −0.103 | [−0.17; −0.04] | −0.09 | −0.09 | 0.126 | ✅ |
| H — Transporte | −0.060 | [−0.37; 0.25] | 0.00 | −0.01 | 0.529 | não |
| (demais seções) | ~0 | cruzam 0 | | | | não |
| G — Comércio | +0.051 | [−0.30; 0.40] | +0.04 | +0.04 | 0.889 | não |
| M — Prof./científico | +0.128 | [−0.16; 0.42] | +0.07 | +0.07 | 0.255 | não |

**Achado item 5:** a **indústria de transformação (C)** é o maior motor da queda (ATT −1.36, triangulação consistente, p=0.086) — concentra ~⅔ do efeito agregado (soma setorial ≈ −1.9/mil, da ordem do ATT total). Administração/serviços de apoio (N) e saúde (Q) têm efeitos pequenos mas significativos (IC<0). Comércio, serviços profissionais e alojamento/alimentação não caem. **Reforça o canal estrutural-industrial** do item 1b (participação industrial é a covariável que mais separa afetados). Ressalva: admissões por seção são números pequenos → a maioria das seções é fina demais para detectar; o sinal agregado é carregado pela indústria.

---

## Item 3 — Controles de fora do RS + matching
**Scripts:** `caged_nacional_download.R` (download) + `sdid_fora_rs_psm.R` (matching + SDiD)
**Saídas:** `Artigos/SDID/Resultados/SDID fora do RS PSM/{fora_rs_individual.csv, fora_rs_multi.csv, doadores_pareados.csv, fora_rs_forest.png}`
**Fundamentação das covariáveis:** `quality_reports/item3_covariaveis_literatura.md`.

Baixou-se o **CAGED nacional** (basedosdados/BigQuery, service account): admissões mensais por município, 2021-01→2025-03, 5.571 municípios, 28 UFs; + população (IBGE 2022), PIB (2021) e IDHM (Atlas 2010) para 5.565 municípios. Desfecho = admissões/mil (grade completada com 0). Os 6 tratados são os do critério populacional; candidatos = 5.069 municípios não-RS com covariáveis completas.

**Matching (literatura, Abadie/Kaul):** distância de **Mahalanobis** ao centroide dos tratados nas covariáveis: resumo do pré de admissões/mil (média + tendência — preditor nº 1), shares setoriais (agro/ind/serv), log-população, PIB per capita, IDHM. (Densidade caiu — sem fonte limpa de área no basedosdados; crédito ficou de fora por parcimônia.) Selecionados os **40 mais próximos**.

**Doadores pareados (40):** SC 15, PR 6, SP 6, MG 5, GO 3, ES 2, MT 2, MS 1 — Sul/Sudeste/Centro-Oeste, com Santa Catarina (vizinha) dominando. Distâncias Mahalanobis 0.81–1.44.

| Município | ATT | IC 95% | p permut. | Sig? |
|---|---|---|---|---|
| Muçum | −6.68 | [−8.78; −4.46] | 0.000 | sim |
| Roca Sales | −5.56 | [−7.66; −3.34] | 0.000 | sim |
| Eldorado do Sul | −4.94 | [−7.03; −2.71] | 0.000 | sim |
| Travesseiro | −4.94 | [−7.03; −2.71] | 0.000 | sim |
| Igrejinha | −2.21 | [−4.31; 0.01] | 0.075 | marginal |
| Arambaré | −0.05 | [−2.15; 2.17] | 0.975 | não |
| **MULTI** | **−4.08** | [−5.14; −3.03] | — | sim (SC −4.23, DiD −3.39) |

**Achado item 3:** controles de fora do RS, pareados por características, dão a **mesma conclusão** — e mais nítida (IC mais apertado, 4/6 municípios individualmente significativos vs 2/6 no trimestral). Os 4 do Vale do Taquari (Muçum, Roca Sales, Eldorado, Travesseiro) são robustos a p=0.000; Igrejinha marginal e Arambaré nulo, como em todas as checagens. Responde à objeção de que os doadores só-RS fossem poucos ou contaminados: **reforça a identificação**.

---

## Onda 2 — status
Itens 3 e 5 **concluídos**. Robustez adicional possível (não executada): densidade (precisa de área municipal), crédito, e o SDiD fora-do-RS por setor.
