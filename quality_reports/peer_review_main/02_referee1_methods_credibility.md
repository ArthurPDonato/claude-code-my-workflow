---
date: 2026-06-17
agent: methods-referee
disposition: CREDIBILITY
journal: RAE
round: 1
---

# Relatório do Árbitro 1 — Metodologia / Credibilidade

**Manuscrito:** Avaliação Causal das Enchentes de Maio de 2024 no RS sobre o Emprego Formal  
**Disposição:** CREDIBILITY — foco na validade da estratégia de identificação  
**Tipo de paper:** Reduced-form com múltiplos estimadores de diferenças em diferenças  

---

## Avaliação Geral

O manuscrito apresenta uma aplicação competente de Diferença-em-Diferenças Sintética (SDiD) à avaliação do impacto das enchentes de maio de 2024 sobre o emprego formal em seis municípios gaúchos. A triangulação entre TWFE-DiD, Controle Sintético e SDiD é o ponto mais forte do trabalho: nos quatro municípios com efeito robusto, a convergência entre estimadores fornece evidência de identificação que nenhum estimador isolado ofereceria. A aplicação do `synthdid` parece tecnicamente adequada, e os autores demonstram consciência apropriada dos limites do Muçum (RMSPE elevado).

No entanto, a estratégia de identificação apresenta lacunas sérias que precisam ser endereçadas antes de qualquer decisão de publicação. O problema mais grave é a **contaminação potencial do pool doador**: as enchentes de maio de 2024 afetaram centenas de municípios no RS além dos seis definidos como "tratados" pelo critério dos autores (>50% da população atingida). Se municípios do pool doador também foram afetados — ainda que abaixo do limiar de corte —, o pressuposto de controles não contaminados está violado, e o estimador não recupera o ATT do tratamento, mas uma mistura de efeito tratamento e "ruído de enchente" dos controles.

**Recomendação:** Revisão e Resubmissão. Há contribuição real, mas as preocupações de identificação abaixo são endereçáveis.

---

## Pontos Fortes

1. **Triangulação metodológica** (Seção 5.3): reportar três estimadores com diferentes hipóteses de identificação e mostrar convergência é metodologicamente rigoroso e excede a prática padrão da literatura de desastres no Brasil.

2. **Consciência dos limites de Muçum**: o texto reconhece explicitamente o RMSPE pré-tratamento elevado de Muçum e classifica sua inferência como "parcial" — maturidade metodológica que muitos trabalhos empíricos carecem.

3. **Uso de permutação para inferência**: `synthdid_se(method = "placebo")` é a abordagem padrão para inferência quando N tratados é pequeno. Os autores demonstram conhecimento do estado da arte.

4. **Efeitos acumulados mensais** (Seção 5.4): o padrão em "W" para Eldorado do Sul — com segundo pico em janeiro de 2025 — é resultado substantivo relevante que vai além da estimativa pontual do ATT médio.

5. **Heterogeneidade descritiva** (Seção 5.5): a análise por canais de dano (viário, firmas, residencial) com advertência metodológica explícita sobre inferência causal intermunicipal é exemplar. Os autores não sobreinterpretam.

---

## Preocupações Maiores

### PM1: Contaminação do Pool Doador

**Dimensão:** Identificação  
**Gravidade:** CRÍTICA

**Problema:** O pool doador é composto por municípios com menos de 1% da população atingida (N₀ = 193, conforme placeholder da Seção 4). As enchentes de maio de 2024 no RS afetaram muito mais do que 6 municípios — reportagens e dados oficiais indicam danos em dezenas de municípios com 10–49% de impacto. Municípios com, por exemplo, 20% da população atingida provavelmente também sofreram retração no emprego formal, mas ainda assim entram no pool doador pelo critério de <1%.

**Consequência:** O SDID usa o pool doador para construir o contrafatual. Se os doadores também foram negativamente afetados pelas enchentes (ainda que menos intensamente), o contrafatual subestima o emprego que os municípios tratados teriam sem as enchentes, comprimindo a estimativa do ATT em direção ao zero. Isso tornaria as estimativas **conservadoras**, mas o viés é desconhecido sem análise de sensibilidade.

**Como endereçar:**
1. Apresentar o mapa dos municípios excluídos do pool doador por nível de impacto intermediário (entre 1% e 50% da população atingida) — isso dá ao leitor a escala do problema.
2. Análise de sensibilidade: variar o threshold de exclusão de 1% para 5% e 10% da população atingida, e reportar como o ATT muda. Se os resultados forem estáveis, a preocupação é atenuada.
3. Citar a literatura sobre "no interference" (SUTVA) — Imbens & Rubin (2015), Abadie (2021) §4 — e discutir explicitamente por que o critério de 1% é defensável.

**Localização:** Seção 4 (Dados, placeholder) + Seção 3 (Metodologia, §SDiD).

---

### PM2: Ausência de Teste Formal de Tendências Pré-Tratamento

**Dimensão:** Identificação  
**Gravidade:** MAIOR

**Problema:** O RMSPE pré-tratamento é apresentado na Tabela tab:robustez como indicador de ajuste do controle sintético, mas **não é um teste de paralelas para o TWFE-DiD**, nem um diagnóstico do pressuposto de tendências localmente paralelas do SDiD. Para o TWFE-DiD, o pressuposto de identificação é paralelas no sentido de DiD usual; para o SDiD, são os pesos $\hat{\lambda}_t$ que "linearizam" as tendências, mas isso também pressupõe que o padrão de tendências no pré-período seja informativo do contrafatual. Nenhum teste formal é reportado.

**Como endereçar:**
1. Para o TWFE-DiD: incluir o teste de placebo temporal (event-study estático ou dinâmico) mostrando que não há efeitos pré-tratamento significantes. Isso é agora um padrão mínimo para qualquer DiD publicado (Callaway & Sant'Anna 2021; Sun & Abraham 2021).
2. Para o SDiD: o gráfico de "tendências sintéticas" — evolução do sintético vs. tratado no pré-período — é uma boa prática de diagnóstico. O pacote `synthdid` produz esses gráficos. Incluir pelo menos para Eldorado do Sul e Muçum.
3. Citar Arkhangelsky et al. (2021) §5 explicitamente sobre a condição de "locally parallel trends" que o SDiD exige.

**Localização:** Seção 3 (Metodologia), Seção 5 (Resultados — adicionar subseção de diagnóstico).

---

### PM3: Múltiplos Testes sem Correção

**Dimensão:** Econometria  
**Gravidade:** MAIOR

**Problema:** O manuscrito reporta estimativas para 6 municípios × 3 estimadores = 18 comparações. Quando múltiplos testes são realizados sem correção, a probabilidade de ao menos uma rejeição falsa cresce substancialmente (problema de inflação de erro Tipo I). Os quatro "resultados robustos" são identificados pela observação de que os IC95% excluem zero, mas com 18 testes, o número esperado de falsos positivos sob H₀ verdadeira seria ~0.9 ao nível de 5% — ou seja, quase um resultado falso é esperado por azar mesmo se não houvesse efeito em nenhum município.

**Como endereçar:**
1. Aplicar correção de Bonferroni ou Holm ao nível dos 6 municípios (pelo menos para a tabela principal, tabela:att_principal). Com α = 0.05 e 6 testes, o limiar Bonferroni é α* = 0.0083.
2. Alternativamente, adotar a abordagem de Romano & Wolf (2005) de stepdown, que é menos conservadora que Bonferroni. O pacote `fixest` no R oferece `summary(..., se = "twoway")` com opção de ajuste Romano-Wolf.
3. Verificar quais municípios permanecem significantes após a correção e discutir se isso muda as conclusões substantivas.
4. Nota: os autores podem argumentar que a triangulação entre estimadores serve como proteção contra múltiplos testes — argumento parcialmente válido, mas deve ser tornado explícito.

**Localização:** Seção 5.1 (Resultados Principais) e Tabela tab:att_principal.

---

### PM4: Inferência de SC Misturada com Inferência Gaussiana no Forest Plot

**Dimensão:** Econometria  
**Gravidade:** MAIOR

**Problema:** A Tabela tab:triangulacao e a Figura fig:forest apresentam IC95% de três estimadores, mas cada um usa método de inferência diferente: TWFE-DiD usa inferência gaussiana cluster-robust; SC e SDiD usam permutação por placebo. Esses intervalos **não são comparáveis em sentido estrito**: o intervalo cluster-robust é assintótico e assume normalidade; o intervalo por permutação é exato sob a hipótese nula de permutabilidade. Misturar os dois no mesmo gráfico e compará-los visualmente pode enganar o leitor.

**Como endereçar:**
1. Adicionar nota de rodapé na Tabela tab:triangulacao explicitando os métodos de inferência por estimador e alertando sobre a não-comparabilidade direta.
2. Na Figura fig:forest, adicionar indicador visual (forma do ponto ou estilo da barra) distinguindo os dois tipos de intervalo.
3. Considerar computar bootstrap de bloco para o TWFE-DiD para obter todos os IC95% por permutação/bootstrap, permitindo comparação mais homogênea.

**Localização:** Seção 5.3, Tabela tab:triangulacao, Figura fig:forest.

---

## Preocupações Menores

### pm1: Seleção do Critério de Tratamento (50%)

O critério de >50% da população atingida para definir "tratado" não é derivado de um modelo — é uma regra de corte ad hoc. Os autores devem discutir brevemente a sensibilidade dos resultados a cortes alternativos (por exemplo, 40% ou 60%) ou explicitar a teoria que justifica esse limiar específico. Localização: Seção 4 (quando completada).

### pm2: Ausência de Referência ao SUTVA Explicitamente

O artigo não menciona "SUTVA" (Stable Unit Treatment Value Assumption) em nenhum momento, embora seja o pressuposto de identificação central para qualquer DiD com desastres naturais (onde efeitos de transbordamento, migração e efeitos de equilíbrio geral são plausíveis). Um parágrafo curto na Seção 3 discutindo SUTVA e por que é razoável neste contexto (municípios pequenos, emprego formal não altamente móvel no curto prazo) fortaleceria o paper.

### pm3: Teixeira (2024) — Status Editorial

A obra "Teixeira (2024)" é citada diversas vezes como referência para a hipótese de nulidade dos desligamentos. O leitor não consegue determinar se é artigo publicado, preprint, ou trabalho de conferência. Se não é artigo publicado, os autores devem indicar explicitamente e não tratar como resultado estabelecido.

### pm4: Figura dano_perfil_z.png

Há um comentário de rascunho no código LaTeX: `% Não sei se vale a pena manter esse gráfico, ele tem a interpretação tão difícil.` Concordo com a dúvida do autor: um gráfico Z-score de dano padronizado com 6 linhas sobrepostas é de difícil interpretação sem painel ou legenda melhorada. O gráfico da Figura fig:canais (dano_canais_centrais.png) é muito mais direto e suficiente. Recomendo cortar fig:perfilz ou reformulá-la substancialmente.

### pm5: Comentários de Rascunho no Código LaTeX

O manuscrito contém vários comentários de rascunho expostos no código LaTeX (`% Fonte?`, `% diminuir o tamanho dessa imagem`, `% Não sei se vale a pena...`). Esses comentários devem ser removidos antes de qualquer submissão.

### pm6: Cumulative Effect — "placebo na curva acumulada"

A construção do IC95% para a curva acumulada (Tabela tab:acumulado) por "placebo na curva acumulada" é menos padronizada do que a inferência por permutação para o ATT pontual. Os autores devem citar uma referência metodológica que justifique essa abordagem específica, ou descrever o procedimento com precisão suficiente para replicação.

---

## Objeções de Árbitro

### OA1: "Seus controles foram afetados pelas mesmas enchentes"

**Por que é potencialmente fatal:** Se os 193 municípios do pool doador também sofreram impacto econômico das enchentes — mesmo abaixo do limiar de 1% de população atingida —, o contrafatual é contaminado. A identificação falha. Os resultados são interpretáveis como efeito relativo entre os mais atingidos e os menos atingidos, não como o efeito causal das enchentes em si.

**Como responder:** Análise de sensibilidade do pool doador (variar threshold de 1% para 5%/10%), mapa dos excluídos, e argumento explícito sobre por que municípios com <1% de população atingida são candidatos a controles limpos.

---

### OA2: "Seis unidades tratadas não são suficientes para inferência robusta"

**Por que é potencialmente fatal:** Com N = 6 municípios tratados, a permutação de Fisher gera apenas C(199, 6) ≈ 10⁹ permutações — matematicamente suficiente — mas na prática, a estabilidade dos pesos $\hat{w}_i$ com 6 tratados e 193 doadores merece discussão. O pacote `synthdid` foi desenvolvido com exemplos em que N tratados é maior (ou ao menos homogêneo).

**Como responder:** Citar Arkhangelsky et al. (2021) §3 sobre as propriedades do estimador com N pequeno; mostrar que os pesos $\hat{w}_i$ são razoavelmente distribuídos (não concentrados em 1–2 doadores); e incluir o teste de permutação "do it to yourself" (Abadie 2021) se viável.

---

### OA3: "O critério de tratamento é endógeno à variável de resultado"

**Por que é potencialmente fatal:** O critério de >50% de população atingida é definido ex-post com base na magnitude do desastre. Se municípios com maior desemprego pré-crise tendem a reportar maior proporção de atingidos (por exemplo, por diferenças na qualidade da coleta da base MUPRS), há problema de medição endógena do tratamento.

**Como responder:** Discutir a geração dos dados MUPRS — são dados administrativos do governo do estado, não autodeclarados. Verificar se a proporção de atingidos é determinada principalmente pela geografia física (cota das enchentes) e não por características socioeconômicas dos municípios.

---

## Resumo de Dimensões

| Dimensão | Nota (1–5) |
|----------|-----------|
| Identificação | 3 |
| Econometria | 3 |
| Robustez | 3 |
| Replicabilidade | 3 |
| Alinhamento com literatura de métodos | 4 |
| **Média** | **3.2** |

**Recomendação: Revisão e Resubmissão.** As preocupações PM1–PM4 são endereçáveis e, uma vez resolvidas, o trabalho estará em condições de publicação na RAE.
