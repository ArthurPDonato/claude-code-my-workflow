# Manuscript Review: Emprego Formal e Desastres Climáticos: Evidências Causais das Enchentes de 2024 no Rio Grande do Sul

**Data:** 2026-06-18  
**Revisor:** review-paper skill (single-pass, default mode)  
**Arquivo:** `Artigos/SDID/arquivos latex/main.tex`  
**Rodada:** 2 (R&R — RAE)

---

## Avaliação Geral

**Recomendação:** Aceite com Revisões Menores  

Este artigo é o primeiro a aplicar o estimador SDiD para avaliação de impacto de inundações no Brasil e oferece uma triangulação sistemática com TWFE-DiD e Controle Sintético sobre o mesmo painel, pool doador e janela temporal. A contribuição empírica é genuína — o evento das enchentes de maio de 2024 no RS constitui um caso de enorme relevância pública, e a evidência causal aqui produzida é a mais rigorosa disponível para os municípios mais severamente afetados. A zona de exclusão *donut* (>50% vs ≤0,5%), o diagnóstico via teste F de pré-tendências conjuntas, os placebo no tempo e no espaço, a análise *leave-one-out* e a sensibilidade a limiares alternativos do pool doador formam um conjunto de robustez que supera o padrão da literatura de desastres citada.

O manuscrito está bem redigido em português acadêmico, com estrutura lógica clara e tabelas/figuras de qualidade. Os pontos abaixo são, em sua maioria, ajustes de precisão — um deles uma inconsistência factual que deve ser corrigida antes da submissão.

---

## Pontos Fortes

1. **Triangulação com identificação explícita.** Estimar TWFE-DiD, SC e SDiD sobre exatamente o mesmo painel/pool/janela é raro na literatura de desastres e fornece um tipo de evidência que nenhum estimador isolado oferece. A discussão das propriedades comparativas (Tabela 1) é bem construída.

2. **Zona de exclusão *donut*.** Excluir municípios com 0,5%–50% da população atingida é uma contribuição metodológica relevante contra a contaminação por *spillover*. A sensibilidade a limiares alternativos (Tabela 5, N₀ de 193 a 291) demonstra robustez convincente.

3. **Uso do teste F para motivar o SDiD ex post.** O teste F conjunto de pré-tendências (F=4,14; p<0,001; g.l.=11;198) é corretamente interpretado: rejeição conjunta sem significância individual indica divergência moderada e sistemática que os pesos $\hat{w}_i$ e $\hat{\lambda}_t$ do SDiD neutralizam. Esse é um argumento sólido para a escolha do estimador principal.

4. **Discussão honesta do caso Muçum.** A classificação como "provável (inferência parcial)" com RMSPE=7,07, e a distinção entre significância espacial e insignificância temporal, mostram maturidade metodológica.

5. **Benchmarking em percentual da média pré-evento.** O parágrafo que traduz os ATTs em percentuais do fluxo habitual (~23–24% nos municípios com efeito robusto) melhora substancialmente a interpretabilidade econômica dos resultados.

6. **Indicador visual de tipo de inferência no *forest plot*.** O uso de forma+traço (círculo/sólido = permutação direta; triângulo/tracejado = EP gaussiano) distingue corretamente as comparações válidas das que requerem cautela adicional.

7. **Seção de heterogeneidade com advertência metodológica explícita.** O aviso sobre natureza descritiva/geradora de hipóteses com n=6 é necessário e bem posicionado.

8. **Diferenciação de Teixeira (2024).** O parágrafo final da §2.5 articula três dimensões de contribuição (estimador, triangulação, donut) de forma clara e rastreável.

---

## Preocupações Maiores

### MC1: Inconsistência factual na classificação de Muçum no parágrafo de benchmarking

- **Dimensão:** Argumento / Escrita
- **Problema:** O parágrafo de benchmarking (§5.1, após a Tabela 2) abre com: *"Nos três municípios com 'efeito robusto', as reduções relativas convergem em torno de um quarto do fluxo habitual de contratações: −23,1% em Eldorado do Sul (...), −24,9% em Roca Sales (...) e −24,2% em Muçum (média pré: 21,0)."* Entretanto, a Tabela 2 classifica Muçum como **"Provável†"**, não como "Efeito robusto". Os três municípios com "Efeito robusto" são Eldorado do Sul, Roca Sales e **Travesseiro** — cujo ATT relativo (-44,0%) é mencionado na frase seguinte como se fosse uma observação independente. Há, portanto, uma contradição entre o rótulo "três municípios com efeito robusto" e o conjunto {Eldorado, Roca Sales, Muçum}.
- **Sugestão:** Reorganizar o parágrafo para agrupar os municípios conforme a classificação da Tabela 2. Por exemplo: *"Nos três municípios com 'efeito robusto', as magnitudes relativas divergem: Eldorado do Sul (−23,1%, média pré 16,1), Roca Sales (−24,9%, média pré 15,0) e Travesseiro (−44,0%, média pré 8,5) — sendo este último mais intenso em razão da base formal comparativamente menor. Em Muçum, classificado como 'provável' com inferência parcial, o percentual relativo seria de −24,2% (média pré 21,0), sujeito à ressalva técnica do RMSPE elevado."*
- **Localização:** §5.1, parágrafo de benchmarking (após Tabela 2, aprox. linhas 1274–1285).

### MC2: A rejeição do teste F mina parcialmente o argumento de triangulação com TWFE-DiD

- **Dimensão:** Identificação / Econometria
- **Problema:** O artigo usa a rejeição do teste F (F=4,14) para motivar o SDiD (§5.3, linha ~1625), o que está correto. No entanto, a seção de triangulação (§5.3) argumenta que "a convergência entre TWFE-DiD, SC e SDiD fornece evidência de identificação que nenhum estimador isolado oferece". Se o TWFE-DiD é inconsistente sob pré-tendências sistemáticas (como o F-test sugere), a convergência com o TWFE-DiD não constitui evidência independente — o argumento de robustez por triangulação deveria recair, em primeiro lugar, sobre a convergência entre SC e SDiD, que partilham a permutação direta como inferência. O TWFE-DiD pode ser reportado para comparabilidade com Teixeira (2024), mas sua inclusão no argumento principal de triangulação precisa de qualificação explícita.
- **Sugestão:** Adicionar em §5.3 uma frase como: *"Note-se que a convergência SC-SDiD constitui a evidência de triangulação mais robusta, dado o diagnóstico de pré-tendências divergentes da Subseção \ref{sub:triangulacao}; o TWFE-DiD é reportado para comparabilidade com a literatura prévia, e sua convergência de sinal reforça, mas não substitui, o argumento baseado nos estimadores que acomodam pré-tendências heterogêneas."*
- **Localização:** §5.3, parágrafo de síntese dos três padrões (linhas ~1543–1577).

### MC3: A dinâmica em "W" e o segundo pico em janeiro/2025 — sazonalidade não discutida

- **Dimensão:** Econometria / Argumento
- **Problema:** O texto descreve um segundo pico de retração em janeiro de 2025 (efeito de −10,15 por mil vs. −7,37 em maio/2024) e atribui-o a danos de infraestrutura de transporte (Xiao 2014). Janeiro é tipicamente o mês de menor atividade formal no Brasil (recesso, férias coletivas). O SDiD e o SC, ao usarem dados pré-tratamento de janeiro/2021, janeiro/2022, janeiro/2023 e janeiro/2024 como parte do contrafactual, capturam a sazonalidade de janeiro implicitamente. O texto não deixa isso explícito, e um árbitro poderá questionar se o segundo pico é um efeito genuíno do desastre ou um resíduo de sazonalidade não capturado.
- **Sugestão:** Acrescentar, na descrição do padrão em "W" (§5.4), uma frase que explicite por que o controle sintético já incorpora a sazonalidade de janeiro: *"Como o pool pré-tratamento inclui quatro Januários anteriores ao choque (2021–2024), o controle sintético reproduz o padrão sazonal histórico; o efeito de −10,15 em janeiro/2025 é, portanto, relativo ao nível sazonal esperado e não à sazonalidade bruta."*
- **Localização:** §5.4, parágrafo do padrão em "W" (linhas ~1657–1667).

---

## Preocupações Menores

### mc1: Tipografia — "phase aguda" (um caso de inglês em português)

- **Problema:** Linha ~1090: *"quando o mercado de trabalho formal havia retomado um regime de variação regular após a **phase** aguda de 2020."* "Phase" é inglês; o correto é "fase".
- **Sugestão:** Substituir "phase" por "fase".

### mc2: Suposição de não antecipação — ausente na discussão de identificação do TWFE-DiD

- **Problema:** §3.1.1 lista as premissas do TWFE-DiD (tendências paralelas, SUTVA) mas não menciona a suposição de não antecipação (*no anticipation*), standard na literatura desde Abbring & Heckman (2007). Para inundações, a não antecipação é plausível dado o caráter extremo e inesperado das chuvas de maio/2024 — mas isso deve ser dito. O risco é que alertas meteorológicos de final de abril/2024 tenham levado firmas a postergar contratações, contaminando o período de referência (abril/2024 = k=−1).
- **Sugestão:** Acrescentar um parágrafo de uma frase em §3.1.1: *"Adicionalmente, assume-se ausência de antecipação (*no anticipation*) [já mencionada com SUTVA, mas vale reforçar]: a intensidade e a localização específicas das chuvas de maio/2024 não eram previsíveis com antecedência suficiente para que agentes econômicos ajustassem contratos em antecipação ao evento \cite{elsner2024}."* Na verdade, revisando a Seção 3.1.1, a frase "Adicionalmente, assume-se ausência de antecipação (*no anticipation*) e consistência dos potenciais resultados (SUTVA)" já consta. O que está faltando é uma sentença que conecte isso ao contexto específico das enchentes (discutido apenas em §2.4 para o DiD em geral).
- **Localização:** §5 (Resultados), como parte do preâmbulo metodológico (linhas 1198–1216).

### mc3: Erros-padrão clusterizados com seis clusters no TWFE-DiD de robustez

- **Problema:** A Tabela 4 menciona ICs gaussianos com erros clusterizados no município para o TWFE-DiD. O TWFE-DiD da triangulação é estimado no painel completo (N=199), portanto os 199 clusters são adequados. Mas se em alguma estimação o cluster for apenas nos 6 tratados, os SEs de cluster com G=6 são sabidamente viesados para baixo (Cameron & Miller 2015). O texto não especifica com nitidez quantos clusters são usados na estimação do TWFE-DiD de triangulação.
- **Sugestão:** Confirmar/especificar na nota de rodapé (a) da Tabela 4 que o cluster é sobre os 199 municípios (G=199), não apenas os 6 tratados.

### mc4: Adoção simultânea vs. escalonada — argumento de motivação do SDiD

- **Problema:** A introdução menciona que o SDiD "acomoda naturalmente configurações com múltiplas unidades tratadas e adoção escalonada" (§1, linha ~326). Entretanto, todos os seis municípios são tratados em maio/2024 simultaneamente. A motivação por adoção escalonada (Clarke 2023) é menos relevante do que a motivação por divergência de pré-tendências.
- **Sugestão:** Rever a frase na Introdução para não apoiar o SDiD primariamente no argumento de adoção escalonada, mas sim na robustez à divergência de pré-tendências e na dupla robustez. O argumento de adoção escalonada é válido como generalização futura (ex.: se o timing do pico de inundação variou entre municípios), mas secundário no contexto específico deste estudo.

---

## Objeções de Árbitro

Estas são as perguntas difíceis que um árbitro de topo provavelmente colocaria:

### RO1: Se o teste F rejeita tendências paralelas, por que incluir o TWFE-DiD como braço principal de triangulação?

**Por que isso importa:** Um árbitro metodológico argumentará que a "triangulação" com TWFE-DiD não produz evidência independente quando o estimador é inconsistente sob pré-tendências divergentes. Isso não é fatal — o TWFE-DiD pode ser mantido para comparabilidade —, mas o argumento de robustez precisa centrar-se explicitamente na convergência SC-SDiD.  
**Como responder:** Adicionar uma frase em §5.3 qualificando o TWFE-DiD como "comparabilidade com literatura prévia", e reformular o argumento de triangulação para destacar SC e SDiD como o par identificatoriamente mais robusto.

### RO2: O segundo pico de −10,15 em janeiro/2025 é maior que o choque inicial. Isso é real ou artefato de sazonalidade?

**Por que isso importa:** O padrão em "W" é economicamente incomum — o segundo choque maior que o primeiro — e pode sugerir um problema com o contrafactual sintético no período de final de série. Se o SDiD sub-estima o contrafactual de janeiro/2025 (porque os doadores também tiveram quedas em janeiro/2025 por razões não relacionadas ao desastre), o efeito estimado ficaria inflado.  
**Como responder:** (a) Adicionar, para Eldorado do Sul, o gráfico de trajetória mostrando explicitamente que o controle sintético também exibe a dip de janeiro mas não a magnitude observada na unidade tratada. O script 09_trajetorias_cores.R já produz isso. (b) Ou discutir brevemente que o SDiD pondera os períodos pré-tratamento mais próximos (incluindo Jan/2021–Jan/2024), capturando assim a sazonalidade implicitamente.

### RO3: A variável de severidade (% população atingida, do MUPRS) é endógena à capacidade administrativa e econômica municipal. Como isso afeta a seleção dos tratados?

**Por que isso importa:** Municípios com maior capacidade administrativa podem registrar proporções de atingidos mais precisas (ou maiores, por terem melhor mapeamento). Se Arambaré e Igrejinha têm registros menos precisos, a "ausência de efeito" pode parcialmente refletir missclassification de severidade, não resiliência genuína.  
**Como responder:** Acknowledger em §2.4 (já discute endogeneidade da variável de tratamento) que os dados do MUPRS/SPGG-RS são baseados em fontes físicas e administrativas combinadas, e que a endogeneidade à capacidade municipal é mitigada pelo fato de que o critério (>50%) é de alta severidade e pouco sensível a pequenas diferenças de registro.

### RO4: Com apenas 11 meses pós-tratamento e uma segunda retração em janeiro/2025, como afirmar que as estimativas representam um limite inferior do impacto de longo prazo?

**Por que isso importa:** A seção de limitações diz que o déficit acumulado deve ser entendido como "estimativa parcial do impacto de longo prazo" (§6). Mas para que isso seja um limite inferior, precisaria ser demonstrado que o processo de recuperação não gerou efeitos positivos suficientes para compensar — o que a dinâmica em "W" sugere, mas não demonstra formalmente.  
**Como responder:** Qualificar: *"se o processo de recuperação é monótono ou com a direção dominada pelo componente de retração, as estimativas representam um limite inferior; a presença de uma segunda retração em janeiro/2025 é consistente com esse cenário, mas não o estabelece formalmente."*

### RO5: Por que Igrejinha — com danos viário e a firmas comparáveis aos municípios com efeito robusto — não apresenta resposta significante?

**Por que isso importa:** A heterogeneidade de Igrejinha é o caso mais desafiador para a hipótese dos canais produtivos. A explicação por "diversificação econômica" (Xiao 2014) é plausível mas ad hoc com n=6. Um árbitro pedirá evidência mais concreta.  
**Como responder:** Acrescentar indicadores econômicos de Igrejinha (ex.: número de CNAEs, distribuição setorial do emprego, tamanho médio de firma) para documentar a diversificação. Esses dados estão disponíveis no CAGED e no Cadastro Central de Empresas do IBGE.

---

## Comentários Específicos

| Localização | Observação |
|---|---|
| Linha ~1090 | "phase aguda" → "fase aguda" |
| §5.1, benchmarking | "Nos três municípios com 'efeito robusto'... Muçum" → inconsistente com classificação da Tabela 2 (ver MC1) |
| §5.3, linha ~1507 | "Trata-se, ao nosso conhecimento, da primeira aplicação de uma triangulação dessa natureza ao caso brasileiro" — moderar levemente: primeiro para as enchentes de 2024; Chuvas 2011 (Serra Fluminense) podem ter estudos com dois estimadores |
| §6 (Limitações) | Poderia mencionarr que o emprego informal e o trabalho por conta própria são tipicamente canais de absorção de choque em desastres (Burke et al. 2015 no contexto de países em desenvolvimento), ampliando a visibilidade da limitação do CAGED |
| Abstract/Resumo | Adicionar os percentuais de benchmarking (~24% do fluxo habitual) melhoraria a interpretabilidade para leitores não economistas |
| Referência Elsner (2024) | Verificar disponibilidade pública/DOI da referência — pode ser paper de conferência ainda não publicado como artigo (dependendo da base) |

---

## Estatísticas de Avaliação

| Dimensão | Nota (1–5) |
|----------|-----------|
| Estrutura do argumento | 4 |
| Estratégia de identificação | 4 |
| Especificação econométrica | 4 |
| Posicionamento na literatura | 4 |
| Qualidade da escrita | 4 |
| Apresentação (tabelas/figuras) | 5 |
| **Geral** | **4,2** |

---

## Síntese para o Autor

O artigo está essencialmente pronto para submissão. Há **uma correção factual obrigatória** (MC1: classificação de Muçum no parágrafo de benchmarking) e **duas qualificações conceituais importantes** (MC2: TWFE na triangulação; MC3: sazonalidade de janeiro). As preocupações menores são de precisão e podem ser tratadas com ajustes de uma frase. As objeções de árbitro RO1 e RO2 são as mais prováveis de aparecer em revisão e valem preparação proativa na resposta.

A contribuição do SDiD como estimador principal + donut zone + triangulação sistemática é genuína e está bem documentada. O artigo merece publicação.
