# Seguro-Desemprego — Avaliação Causal por ARIMA de Intervenção

Avaliação do efeito de choques institucionais sobre o **número de requerentes do
Seguro-Desemprego** (trabalhador formal, Brasil), por **triangulação** de dois
métodos de série temporal interrompida (ITS):

1. **ARIMA de intervenção (contrafactual)** — SARIMA ajustado no pré-intervenção,
   contrafactual projetado, efeito = observado − previsto.
2. **CausalImpact (BSTS)** — modelo estrutural bayesiano com tendência local +
   sazonalidade mensal.

## Intervenções avaliadas

| Intervenção | Data | Forma esperada |
|---|---|---|
| **Lei nº 13.134/2015** (aperto de elegibilidade) | jul/2015 | degrau permanente ↓ |
| **Choque pandêmico** (COVID / medidas emergenciais) | mar/2020 | pulso agudo + vale |

## Dados

- **Fonte:** Base de Gestão do Seguro-Desemprego (BGSD) — MTE/SPPE,
  *Série Histórica do Seguro-Desemprego 2000–2025* (`.xlsx`).
- **Cobertura:** mensal, **2000/01 a 2025/04** (304 meses), por UF de demissão + Brasil.
- **Integridade:** série contínua, **0 lacunas, 0 NAs** (verificado em `01_import.R`).
- **Alvo primário:** Tabela 1 — Requerentes. **Secundário:** Tabela 2 — Segurados.
- **Controle nacional (CausalImpact):** admissões e demissões mensais do
  **CAGED antigo** (IPEADATA/MTE, séries `CAGED12_ADMIS`/`CAGED12_DESLIG`,
  1999-05 a 2019-12). Só se aplica à **Lei 2015** (janela toda pré-2020, sem a
  quebra do Novo CAGED). Correlação pré-intervenção com requerentes: **0,93**.

> Nota: o TD IPEA nº 3059 (2024), que motivou o projeto, usa apenas o agregado
> **anual** até 2019 — insuficiente para modelagem de série temporal. Este projeto
> usa a série **mensal** completa até 2025 (a "necessidade de completar a série").

## Pipeline (`scripts/`)

Rodar **da raiz do repositório**:

```bash
Rscript Artigos/Seguro_Desemprego_ARIMA/scripts/00_run_all.R
```

| Script | Função |
|---|---|
| `00_setup.R` | Verifica/instala pacotes |
| `00_run_all.R` | Orquestrador + verificação de outputs |
| `01_import.R` | Lê o `.xlsx`, reshape, série BRASIL + painel UF, checagem de integridade |
| `01b_import_caged.R` | Controle CAGED antigo (admissões/demissões) do IPEADATA |
| `02_explore.R` | STL, ACF/PACF, ADF/KPSS, gráfico com intervenções |
| `03_arima_intervencao.R` | ITS contrafactual (principal) + Box-Tiao com dummies (robustez) |
| `04_causalimpact.R` | BSTS bayesiano SEM covariáveis, janelas idênticas ao 03 |
| `05_triangulacao.R` | Tabela comparativa + forest plot |
| `06_causalimpact_controle.R` | CausalImpact da Lei 2015 COM controle CAGED |
| `07_taxa_habilitacao.R` | Teste da taxa requerentes/demissões e segurados/demissões |

## Resultados (efeito médio sobre requerentes/mês)

| Método | Lei 13.134/2015 | COVID (1º ano) |
|---|---|---|
| ARIMA-ITS | −113 mil (−16,2%) | ~nulo (pico e vale se cancelam) |
| CausalImpact | −115 mil (−16,4%), p≈0,001 | ~nulo (p≈0,24) |

**Efeito bruto (associacional):** os dois métodos **convergem** em ~**−16%** de
requerentes/mês após a Lei 13.134/2015.

**Efeito condicional (isolando o mercado de trabalho) — achado central:** ao
incluir **demissões do CAGED** como controle no CausalImpact, o efeito
**desaparece** (+2,6%, p≈0,15; IC atravessa zero) e o intervalo **encolhe pela
metade**. Ou seja: a queda de −16% nas solicitações após 2015 parece **atribuível
sobretudo à dinâmica de demissões** (recessão de 2015–16 e recuperação lenta),
**não** ao aperto de elegibilidade da Lei em si.

> ⚠️ **Ressalva (a resolver antes de publicar):** o achado depende de as demissões
> serem um controle *válido* (não um "bad control"). Argumento a favor: a Lei mudou
> a elegibilidade do *trabalhador*, não o comportamento de demissão do *empregador*.
> Teste-chave pendente: modelar a **taxa de habilitação** (requerentes/demissões) em
> torno de 2015 — se a Lei operou, essa razão deve cair.

**Teste da taxa de habilitação (`07`) — as estimativas agregadas divergem:**

| Abordagem | Efeito estimado da Lei 2015 |
|---|---|
| Requerentes (nível), sem controle | **−16%** |
| Requerentes \| demissões (controle CAGED) | **~0** (n.s.) |
| Taxa requerentes/demissões (vs. contrafactual) | **+10%** (p<0,01) |
| Taxa requerentes/demissões (médias simples pré→pós) | **−2%** |

**Conclusão metodológica (central):** o efeito da Lei **não é robustamente
identificável com dados agregados nacionais**, porque a Lei (jul/2015) coincidiu com
a **recessão de 2015–16**, que moveu simultaneamente o volume de demissões, a
*composição* das separações (mais dispensas involuntárias, elegíveis ao SD) e o
take-up. Cada especificação agregada carrega esse confundidor de forma diferente.
Ver `figuras/10_taxa_habilitacao.png`: a razão repica na recessão e depois reverte —
padrão cíclico, não degrau de política.

> **Caveat do denominador:** usamos o TOTAL de desligamentos; o correto seria só
> **dispensa sem justa causa** (categoria que aciona o SD). A recessão eleva a fração
> involuntária, inflando a taxa — parte do "+10%" é composição, não a Lei.

**Desenho recomendado para identificar a Lei:** explorar a **descontinuidade de
elegibilidade** (tempo de vínculo 6→12 meses para a 1ª solicitação) em **microdados**
(RAIS/CAGED + registro do SD) via **DiD/RD** comparando trabalhadores logo abaixo vs.
acima do novo limiar — o grupo de controle absorve a recessão macro.

O efeito líquido do 1º ano de pandemia é ≈ zero em ambos os métodos porque o surto
de demissões (abr–jun/2020) é compensado pela supressão posterior de desligamentos
(MP 936 / BEm) — o pulso agudo é bem estimado pelo modelo com dummies.

## Extensões planejadas

- [x] **Controle nacional CAGED** no CausalImpact (feito — `01b`/`06`).
- [x] **Taxa de habilitação** (requerentes/demissões) — feito (`07`); revelou que o
  sinal agregado é fragilizado pela recessão coincidente.
- [~] **Denominador correto:** dispensa sem justa causa. **Confirmado** que o CAGED
  antigo registra o código `31 - Dispensa sem justa causa` (layout, Registro C) para
  todo 2000–2019 → o dado EXISTE. Importador drop-in pronto (`01c`, filtro código 31)
  e o `07` já o usa quando `outputs/desligamentos_sjc.csv` existir. **Falta 1 passo
  manual (só o usuário):** acesso a microdados — `pip install basedosdados` +
  `gcloud auth application-default login` + `GCP_BILLING_PROJECT` (ou baixar do PDET).
- [ ] **Desenho de microdados (DiD/RD)** na descontinuidade de elegibilidade 6→12
  meses — caminho para identificar a Lei separando-a da recessão.
- [ ] Repetir para **Segurados** (Tab. 2) e **valores pagos deflacionados** (Tab. 4).
- [ ] Análise **por UF/região** a partir do `painel_uf.csv`.
