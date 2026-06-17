---
journal: Revista Análise Econômica (RAE — UFRGS)
manuscript_id: exxxxx
round: 1
date: 2026-06-17
status: FINAL — Post-Flight Verification PASS (15/15 claims verified)
---

# Resposta aos Árbitros — Primeira Revisão

**Manuscrito:** Avaliação Causal das Enchentes de Maio de 2024 no RS sobre o Emprego Formal
**Periódico:** Revista Análise Econômica (RAE — UFRGS)
**Rodada:** 1 → Revisão e Resubmissão
**Data:** 2026-06-17

---

## Carta de Apresentação

Agradecemos ao Editor e aos dois árbitros pela leitura cuidadosa do manuscrito e pelas críticas construtivas, que nos permitiram aprimorar substancialmente o trabalho. A revisão endereçou todos os problemas estruturais apontados — as Seções 4 (Dados) e 6 (Considerações Finais) foram completamente redigidas, o bloco de Abstract duplicado foi removido, e os comentários internos de rascunho foram eliminados do código LaTeX. Além disso, expandimos a discussão metodológica para distinguir explicitamente a endogeneidade de *localização* (problema transversal, do qual DiD e SDiD estão imunizados) da endogeneidade de *timing* (componente quasi-aleatório que sustenta a identificação causal), adicionamos uma nota explicativa sobre a restrição de *convex hull* do Controle Sintético clássico, e complementamos a revisão de literatura com as referências faltantes apontadas pelos árbitros.

Algumas recomendações — notadamente a análise de sensibilidade do limiar de exclusão do pool doador, o estudo de evento com coeficientes pré-tratamento para o TWFE-DiD, e a quantificação dos efeitos absolutos como proporção das admissões médias anuais pré-desastre — requerem análise adicional nos microdados do CAGED e estão programadas para a próxima rodada de revisão. Respondemos a cada preocupação em detalhe abaixo.

---

## Árbitro 1 — Metodologia / Credibilidade

### Preocupações Maiores

---

**R1.PM1: Contaminação do Pool Doador**

> "Se municípios do pool doador também foram afetados — ainda que abaixo do limiar de corte —, o pressuposto de controles não contaminados está violado."

**Classificação:** Parcialmente endereçado.

Concordamos que este é o principal risco de identificação do estudo, e a revisão incorporou duas respostas ao nível do manuscrito. Primeiro, a Seção 4.3 (Pool Doador) foi redigida e explica explicitamente o *design* de "donut": o limiar de exclusão de ≤0,5% da população atingida cria uma zona de exclusão deliberada entre os tratados (>50%) e os controles (≤0,5%), de modo que municípios com impacto intermediário — entre 0,5% e 50% — são excluídos de ambos os grupos. Essa lacuna de 49,5 pontos percentuais tem como propósito exatamente mitigar a contaminação apontada pelo Árbitro 1 [§4.3, Subseção "Pool Doador e Covariáveis"]. Segundo, a suposição SUTVA é discutida formalmente na Subseção 2.4.3 ("Efeitos de Transbordamento e SUTVA"), que descreve os mecanismos de contaminação possíveis e aponta o design de exclusão como resposta empírica.

Reconhecemos, contudo, que a análise de sensibilidade variando o limiar de exclusão (1%, 5%, 10%) não está no manuscrito revisado — ela requer reestimação do modelo em múltiplas especificações do pool doador e será incluída na próxima rodada. Nos comprometemos a: (a) apresentar os ATTs estimados para os quatro municípios com efeito robusto sob três limiares de exclusão alternativos; (b) incluir um mapa dos municípios excluídos por nível de impacto intermediário. Nossa expectativa, com base na distância do donut (0,5%–50%), é que os resultados sejam estáveis — o que, se confirmado, fornecerá a evidência de robustez que o Árbitro 1 solicita.

---

**R1.PM2: Sem Diagnóstico Formal de Tendências Pré-Tratamento**

> "O RMSPE do SC é um indicador de qualidade do ajuste do sintético, não um teste de paralelas para o TWFE-DiD."

**Classificação:** Parcialmente endereçado.

O Árbitro 1 tem razão em distinguir o RMSPE — que mede a qualidade do ajuste pré-tratamento do Controle Sintético — de um teste formal de tendências paralelas para o TWFE-DiD. A Tabela de Robustez (tab:robustez) reporta o RMSPE para SC e SDiD, que fornece evidência indireta de boa aderência pré-tratamento para os municípios com efeito robusto, mas não é equivalente a um estudo de evento com coeficientes pré-tratamento para o TWFE-DiD.

A inclusão do estudo de evento para o TWFE-DiD requer a geração de um novo gráfico de coeficientes dinâmicos nos scripts R e está programada para a próxima rodada. Nos comprometemos a incluir: (a) o gráfico de coeficientes do TWFE-DiD para períodos de lead/lag em torno de maio/2024; (b) para o SDiD, o gráfico de trajetória observada vs. sintética no período pré-tratamento para ao menos Eldorado do Sul e Muçum, que são os casos mais relevantes. Esses diagnósticos reforçarão a credibilidade da triangulação apresentada na Seção 5.3.

---

**R1.PM3: Múltiplos Testes sem Correção**

> "Com 18 comparações (6 municípios × 3 estimadores), o número esperado de falsos positivos sob H₀ é ≈0,9 ao nível de 5%."

**Classificação:** Parcialmente endereçado.

Reconhecemos a preocupação com inflação de erro Tipo I em comparações múltiplas. Nossa posição é que a triangulação entre estimadores oferece uma forma não convencional mas substantiva de proteção: identificamos como "efeito robusto" apenas os municípios em que *todos os três estimadores* convergem em sinal e magnitude, e os ICs95% de ao menos dois deles excluem o zero. Sob essa regra de decisão conjunta, a probabilidade de falso positivo é muito menor do que no cenário de 18 testes independentes, pois requer que os três estimadores — com hipóteses de identificação distintas — produzam resultados espúrios simultaneamente no mesmo município.

Adicionalmente, nos comprometemos a incluir na próxima rodada uma coluna com os p-valores ajustados por Bonferroni na tabela principal (tab:att_principal) e a discutir explicitamente, em nota de rodapé, por que a triangulação oferece proteção complementar à correção formal de múltiplos testes. Esse esclarecimento fortalece, e não enfraquece, o argumento de robustez do artigo.

---

**R1.PM4: Inferência Mista no Forest Plot**

> "O forest plot mistura IC95% gaussianos (TWFE-DiD) com IC95% por permutação (SC, SDiD). Os dois tipos não são diretamente comparáveis."

**Classificação:** Parcialmente endereçado.

A distinção já existe no manuscrito revisado: a nota de rodapé da Tabela de Triangulação (tab:triangulacao) especifica explicitamente que o TWFE-DiD usa IC95% gaussiano cluster-robust [Bertrand et al. 2004] enquanto SC e SDiD usam IC95% por permutação direta, e adverte que as estimativas são "reportadas para comparabilidade com a literatura prévia." A legenda da Figura fig:forest também enuncia os dois métodos de inferência.

Concordamos, no entanto, que um indicador visual diferenciando os dois tipos de intervalo (por exemplo, forma do ponto ou estilo de linha) tornaria a distinção imediatamente perceptível ao leitor. Incluiremos esse indicador visual na figura na próxima rodada. Avaliaremos também a viabilidade de computar bootstrap de bloco para o TWFE-DiD para homogeneizar os métodos — embora a assimetria de tamanho de amostra entre grupos torne isso metodologicamente não trivial com N=6 tratados.

---

### Preocupações Menores

---

**R1.pm1: Critério de 50% não justificado teoricamente**

**Classificação:** Endereçado.

A Seção 4.2 do manuscrito revisado justifica o limiar de 50% como critério de "alta severidade relativa": municípios abaixo desse patamar podem ter sofrido impactos parciais que não necessariamente se traduzem em deslocamento do mercado de trabalho formal, comprometendo a interpretação causal do estimador. Essa justificativa é apresentada antes da Tabela de municípios tratados [§4.2, Subseção "Municípios Tratados e Critério de Seleção"].

---

**R1.pm2: SUTVA não mencionado explicitamente**

**Classificação:** Endereçado.

O manuscrito revisado menciona SUTVA em dois pontos: (1) na Subseção 3.1, na discussão das premissas do TWFE-DiD — "assume-se ausência de antecipação (*no anticipation*) e consistência dos potenciais resultados (SUTVA)"; (2) na Subseção 2.4.3, dedicada inteiramente a "Efeitos de Transbordamento e SUTVA", onde os mecanismos de violação são descritos e o design de exclusão (donut) é apresentado como resposta empírica [§2.4.3].

---

**R1.pm3: Teixeira (2024) — status editorial não especificado**

**Classificação:** Parcialmente endereçado.

A entrada bibliográfica de Teixeira et al. (2024) está registrada como `@techreport` na base bib, classificando corretamente o documento como relatório técnico da FESPSP (Fundação Escola de Sociologia e Política de São Paulo). O texto do manuscrito, contudo, não explicita essa classificação ao leitor. Adicionaremos na próxima rodada uma indicação explícita no corpo do texto (por exemplo, "Teixeira et al. (2024), em relatório técnico da FESPSP...") para que o leitor identifique imediatamente o status editorial do trabalho.

---

**R1.pm4: Figura fig:perfilz — considerar remover**

**Classificação:** Deferido — decisão dos autores.

Reconhecemos a dificuldade de interpretação da Figura fig:perfilz (perfil Z-padronizado de dano por município). Os autores optaram por mantê-la na revisão atual por oferecer, em conjunto com a Figura fig:canais, uma perspectiva multidimensional do dano: enquanto fig:canais identifica os canais centrais em termos de magnitude absoluta, fig:perfilz permite visualizar a *dispersão relativa* do perfil de dano entre municípios. A manutenção está condicionada ao julgamento do Editor; se o parecerista mantiver a recomendação de remoção na próxima rodada, a figura será suprimida.

---

**R1.pm5: Comentários de rascunho no código LaTeX**

**Classificação:** Endereçado.

Todos os comentários de rascunho foram removidos do arquivo `.tex` (incluindo `% Fonte?`, `% diminuir o tamanho`, `% Não sei se vale a pena...`, e demais anotações internas). O manuscrito submetido não contém comentários LaTeX de natureza editorial.

---

**R1.pm6: IC95% por placebo na curva acumulada sem referência metodológica**

**Classificação:** Deferido.

O procedimento de construção do IC95% para a curva de efeito acumulado por permutação de placebo é descrito na Seção 5.4 com suficiente detalhe para replicação. Adicionaremos uma referência metodológica explícita (Abadie 2021, §4; ou Arkhangelsky et al. 2021, Suplemento) na próxima rodada para ancorar o procedimento na literatura canônica de inferência por placebo.

---

## Árbitro 2 — Domínio Substantivo / Política Pública

### Preocupações Maiores

---

**R2.PM1: Seções 4 e 6 Ausentes — Manuscrito Incompleto**

**Classificação:** Endereçado.

A Seção 4 (Dados) foi completamente redigida e contém três subseções: (4.1) descrição do CAGED e da janela de estimação T=51 meses (jan./2021–mar./2025), com justificativa da data de início; (4.2) critério de definição dos municípios tratados (>50% da população atingida, via MUPRS/SPGG-RS), com tabela descritiva das seis unidades; (4.3) formação do pool doador (≤0,5%, N₀=193), o *design* de exclusão, a lista de covariáveis e o painel balanceado resultante.

A Seção 6 (Considerações Finais) foi também completamente redigida, com: (a) síntese das quatro conclusões principais; (b) implicações de política pública — distinção entre canal de habitação e canal produtivo, com recomendação de pacotes de recuperação que priorizem firmas e infraestrutura viária; (c) três limitações explícitas (mercado informal não capturado, heterogeneidade descritiva com N=6, janela de 11 meses potencialmente incompleta); (d) agenda de pesquisa em quatro dimensões.

---

**R2.PM2: Benchmarking dos Números Absolutos**

**Classificação:** Deferido.

Reconhecemos que contextualizar os 2.390 postos bloqueados como proporção das admissões médias anuais pré-desastre aumentaria o poder comunicativo do resultado central. Esse benchmarking requer extração adicional dos microdados CAGED para o período pré-tratamento de cada município e está programado para a próxima rodada. Nos comprometemos a incluir, na revisão seguinte, (a) o efeito como percentual das admissões médias anuais de 2021–2023 para cada município com efeito robusto; (b) uma comparação breve com os resultados de Deryugina et al. (2018), que já está citado na Seção 2.2 como referência de benchmark para estudos de desastre com metodologia causal.

---

**R2.PM3: Políticas de Recuperação — Avaliação Incompleta**

**Classificação:** Endereçado.

A Seção 6 revisada contém uma discussão de implicações de política pública que: (a) distingue o canal de habitação do canal produtivo à luz dos resultados de heterogeneidade da Seção 5.5; (b) recomenda que pacotes de recuperação priorizem a restauração da capacidade produtiva das firmas e a reconstrução de vias de escoamento; (c) argumenta que o ajuste via margem de entrada implica que instrumentos de estímulo à contratação (crédito a firmas, subsídios temporários) seriam mais eficazes que políticas de proteção ao emprego existente; (d) aponta que a avaliação causal dos próprios programas de recuperação (Volta por Cima, Auxílio Reconstrução, MP 1.230/2024) constitui extensão natural usando a mesma arquitetura de dados [§6, parágrafos 2–3].

---

**R2.PM4: Relação com Teixeira (2024) Subdiscutida**

**Classificação:** Parcialmente endereçado.

O manuscrito revisado descreve explicitamente em §2.1.2 o que Teixeira et al. (2024) estimaram (efeitos médios mensais de ~−166 admissões em Eldorado do Sul e ~−44 em Roca Sales por DiD nos quatro primeiros meses), e a contribuição deste artigo em relação àquele fica implícita na estrutura — SDiD vs. DiD canônico, triangulação com SC, seis municípios vs. amostra mais ampla, janela de 11 meses vs. quatro meses. Reconhecemos, no entanto, que essa diferenciação deveria ser tornada explícita em um parágrafo dedicado na Seção 2.5 (Lacunas da Literatura). Adicionaremos na próxima rodada um parágrafo que posiciona este artigo em relação a Teixeira et al. (2024) em três dimensões: (i) estimador principal (SDiD vs. DiD); (ii) estratégia de robustez (triangulação vs. estimador único); (iii) janela pós-tratamento (11 vs. 4 meses).

---

### Preocupações Menores

---

**R2.pm1: Dois Blocos de Resumo/Abstract**

**Classificação:** Endereçado.

O bloco de Abstract original (versão de dois municípios) foi removido. O manuscrito revisado contém apenas o Abstract da versão atual de seis municípios, em português (Resumo) e inglês (Abstract).

---

**R2.pm2: Autores como A, B, C / Número exxxxx**

**Classificação:** Deferido — item de submissão.

Os campos de autoria e número de manuscrito são preenchidos no momento da submissão ao sistema RAE. Esses campos permanecerão em branco ou com identificadores de submissão cega até a submissão formal.

---

**R2.pm3: Sazonalidade como hipótese alternativa para o segundo pico de jan./2025**

**Classificação:** Deferido.

O Árbitro 2 levanta uma hipótese alternativa válida para o segundo pico de retração em janeiro de 2025 observado em Eldorado do Sul: a sazonalidade na construção civil poderia produzir padrão similar. Embora a hipótese de danos de infraestrutura de transporte (Xiao 2014) seja teoricamente mais direta dado o perfil de dano do município, a hipótese sazonal não pode ser descartada com os dados disponíveis. Adicionaremos uma nota de rodapé na Seção 5.4 reconhecendo essa alternativa e indicando que a desagregação setorial das admissões por CNAE (prevista na agenda de pesquisa) permitirá discriminar entre as duas hipóteses.

---

**R2.pm4: Figura fig:perfilz — considerar remover**

**Classificação:** Deferido — ver R1.pm4 acima.

---

**R2.pm5: Admissões por Mil Habitantes sem Justificativa**

**Classificação:** Endereçado.

A Seção 4.1 do manuscrito revisado inclui um parágrafo dedicado à escolha da normalização: "O uso de uma medida *per capita* é necessário para tornar comparáveis municípios de portes populacionais muito distintos — de Travesseiro (2.152 habitantes) a Eldorado do Sul (39.559 habitantes) — e para remover tendências de crescimento demográfico que poderiam confundir a interpretação dos pesos sintéticos." [§4.1].

---

**R2.pm6: Deryugina et al. (2018) Ausente**

**Classificação:** Endereçado.

Deryugina, Kawano e Levitt (2018), "The Economic Impact of Hurricane Katrina on Its Victims" (*AEJ: Applied Economics*), foi adicionado à Seção 2.2 (Evidências em Mercados de Trabalho), onde os autores são descritos como referência metodológica central para estudos causais de impacto de desastres sobre indivíduos, e como benchmark para o resultado de mobilidade laboral pós-desastre.

---

## Matriz de Classificação das Preocupações

| ID | Árbitro | Gravidade | Preocupação | Classificação | Localização no ms revisado |
|----|---------|-----------|-------------|---------------|---------------------------|
| R1.PM1 | 1 | Crítica | Contaminação do pool doador | **Parcialmente** | §4.3 (donut design); §2.4.3 (SUTVA); análise de sensibilidade: próxima rodada |
| R1.PM2 | 1 | Maior | Sem diagnóstico formal de pre-trends | **Parcialmente** | RMSPE em tab:robustez; event-study: próxima rodada |
| R1.PM3 | 1 | Maior | Múltiplos testes sem correção | **Parcialmente** | §5.3 (triangulação como proteção); Bonferroni: próxima rodada |
| R1.PM4 | 1 | Maior | Inferência mista no forest plot | **Parcialmente** | Notas tab:triangulacao; indicador visual: próxima rodada |
| R1.pm1 | 1 | Menor | Critério 50% não justificado | **Endereçado** | §4.2 |
| R1.pm2 | 1 | Menor | SUTVA não mencionado | **Endereçado** | §3.1; §2.4.3 |
| R1.pm3 | 1 | Menor | Teixeira (2024) status editorial | **Parcialmente** | bib (@techreport); texto: próxima rodada |
| R1.pm4 | 1 | Menor | Figura fig:perfilz | **Deferido** | decisão dos autores (fig mantida) |
| R1.pm5 | 1 | Menor | Comentários de rascunho LaTeX | **Endereçado** | todos removidos |
| R1.pm6 | 1 | Menor | IC95% curva acumulada sem referência | **Deferido** | §5.4 (procedimento descrito); ref: próxima rodada |
| R2.PM1 | 2 | Crítica | Seções 4 e 6 ausentes | **Endereçado** | §4 (3 subseções); §6 (4 parágrafos) |
| R2.PM2 | 2 | Maior | Benchmarking dos absolutos | **Deferido** | §6 (2.390 admissões citadas); % pré-desastre: próxima rodada |
| R2.PM3 | 2 | Maior | Políticas de recuperação não discutidas | **Endereçado** | §6 (canal habitação vs. produtivo; Volta por Cima; crédito a firmas) |
| R2.PM4 | 2 | Maior | Teixeira (2024) subdiscutido | **Parcialmente** | §2.1.2 (descrito); diferenciação explícita: próxima rodada |
| R2.pm1 | 2 | Menor | Dois blocos de Abstract | **Endereçado** | removido |
| R2.pm2 | 2 | Menor | Autores A, B, C | **Deferido** | item de submissão |
| R2.pm3 | 2 | Menor | Sazonalidade jan./2025 | **Deferido** | nota de rodapé: próxima rodada |
| R2.pm4 | 2 | Menor | Figura fig:perfilz | **Deferido** | ver R1.pm4 |
| R2.pm5 | 2 | Menor | Admissões/mil hab. sem justificativa | **Endereçado** | §4.1 |
| R2.pm6 | 2 | Menor | Deryugina et al. ausente | **Endereçado** | §2.2 |

---

## Preocupações Adicionais Tratadas Proativamente

As seguintes questões foram corrigidas na revisão independentemente de solicitação explícita dos árbitros, em resposta à leitura interna do manuscrito:

| Correção | Localização |
|----------|-------------|
| Nota de rodapé sobre restrição de *convex hull* do SC clássico vs. SDiD | §2.1 (SDiD subsection), nota de rodapé |
| Distinção explícita entre endogeneidade de *localização* (cross-sectional) e de *timing* (quasi-aleatório) | §2.4.1 (novos dois parágrafos) |
| Justificativa para uso de dados administrativos MUPRS em vez de SAR/precipitação | §2.4.1 |
| Citações: `leiter2009, bergholt2012` (efeitos de inundações na agricultura/firmas) | §2.3 |
| Citações: `rentschler2022` (famílias com menor capacidade de amortecimento) | §2.3 |
| Citações: `kahn2005death, rentschler2022` (correlação entre localização inundável e renda/institucionalidade) | §2.4.1 |
| Citação `arkhangelsky2021` para SDiD≈TWFE quando pre-trends são paralelas | §5.3 |

---

*Documento gerado por `/respond-to-referees`. Post-Flight Verification: PASS — 15/15 claims verified against `main.tex`. Único item corrigido pós-verificação: comentário residual removido da linha 408 (`%achei meio vago...`).*
*Relatórios dos árbitros: `quality_reports/peer_review_main/02_referee1_*.md` e `03_referee2_*.md`*
