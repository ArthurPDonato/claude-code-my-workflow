# Manuscript Review: Emprego Formal e Desastres Climáticos: Evidências Causais das Enchentes de 2024 no Rio Grande do Sul

**Data:** 2026-06-18
**Revisor:** review-paper skill (single-pass, default mode)
**Arquivo:** `Artigos/SDID/arquivos latex/main.tex`
**Rodada:** 3 (Round 3 — revisão pós-R2)

---

## Status das Preocupações da Rodada 2

| Preocupação | Status |
|---|---|
| MC1: Inconsistência Muçum no benchmarking | ✅ RESOLVIDA — parágrafo reorganizado corretamente |
| MC2: Teste F mina argumento de triangulação | ✅ RESOLVIDA — qualificação explícita adicionada em §5.3 |
| MC3: Sazonalidade de janeiro/2025 | ✅ RESOLVIDA — frase explicativa incluída em §5.4 |
| mc1: Tipografia "phase" → "fase" | ✅ RESOLVIDA |
| mc2: Suposição de não antecipação sem conexão contextual | ✅ RESOLVIDA (§3.1 via referência ao caráter inesperado das chuvas) |
| mc3: Número de clusters TWFE-DiD não explícito | ✅ RESOLVIDA — "$G = 199$" adicionado na nota de rodapé da Tabela 4 |

Todas as preocupações da R2 foram adequadamente tratadas. O manuscrito avançou de forma clara.

---

## Avaliação Geral

**Recomendação:** Revisão Menor — próximo de submissão

O manuscrito está em estado robusto. A triangulação SDiD/SC/TWFE-DiD, a zona de exclusão *donut*, o diagnóstico via teste F e o conjunto de robustez (placebo espacial, temporal, LOO, sensibilidade ao limiar do pool) formam uma estratégia empírica que supera o padrão da literatura de desastres brasileira. As correções da R2 foram bem implementadas — em particular, o benchmarking de Muçum, a qualificação do TWFE-DiD na triangulação e a explicação da sazonalidade de janeiro.

Esta rodada identifica três problemas novos que precisam de atenção antes da submissão, sendo dois deles de natureza identificatória (SUTVA e sensibilidade ao limiar de tratamento) e um de consistência numérica entre tabelas. Os demais itens são menores.

---

## Pontos Fortes

1. **Triangulação completa pós-R2.** A qualificação do TWFE-DiD ("incluído sobretudo para comparabilidade com Teixeira (2024)") resolve a tensão da R2. A frase sobre potência distinta entre procedimentos de inferência (§5.3, linhas 1613–1627) é precisamente o que se precisava.

2. **Sazonalidade de janeiro explicitada.** A frase adicionada em §5.4 — "o controle sintético replica o padrão sazonal histórico de janeiro; o efeito de −10,15 é estimado relativo ao nível sazonal esperado" — é metodologicamente precisa e preventiva ao questionamento arbitral mais óbvio.

3. **Benchmarking revisado.** A separação clara entre os três "efeitos robustos" e Muçum como "provável" é agora consistente entre o parágrafo e a Tabela 2.

4. **Apêndice A (saldo líquido).** A análise de robustez com `saldo_por_mil` como variável dependente é bem motivada, os resultados são adequadamente nuançados (Eldorado do Sul como anomalia explicada pela rigidez trabalhista), e a integração com as Figuras A1 e A2 é direta. A nota sobre o EP uniforme do TWFE-DiD no saldo é um exemplo de transparência que um árbitro apreciará.

5. **Discussão de heterogeneidade com advertência.** A *callout box* em §5.6 mantém-se como um modelo de honestidade metodológica para uma análise com apenas seis unidades.

---

## Preocupações Maiores

### MC1: SUTVA e *spillovers* de equilíbrio geral — não discutidos

- **Dimensão:** Identificação
- **Problema:** O artigo documenta cuidadosamente que a zona de exclusão *donut* (0,5%–50% atingidos) mitiga a contaminação do pool doador por municípios *parcialmente afetados* pela enchente. No entanto, há um canal distinto e não discutido: efeitos de equilíbrio geral via cadeias produtivas entre municípios tratados e municípios de controle. Eldorado do Sul, por exemplo, pertence à Região Metropolitana de Porto Alegre e mantém vínculos de fornecimento e demanda com municípios que não foram atingidos fisicamente. Se a retração em Eldorado reduzir compras de insumos a firmas em municípios de controle, esses controles passam a ser contrafactuais contaminados — violando SUTVA mesmo com proporção de atingidos $\leq 0{,}5\%$. O paper menciona SUTVA em §3.1.1 como premissa, mas não o discute empiricamente nem justifica por que a escala do desastre (municípios de 2–40 mil habitantes) torna o canal de equilíbrio geral negligenciável.
- **Sugestão:** Adicionar em §3.1.1 (ou no início de §5) um parágrafo de 3–4 frases que: (i) reconheça o canal de *spillover* produtivo como ameaça potencial ao SUTVA; (ii) argumente que a escala dos municípios tratados (população total < 60 mil) e a natureza do desastre (ruptura física localizada, não choque macroeconômico) limitam a magnitude esperada desse canal; (iii) note que a sensibilidade a limiares alternativos do pool (Tabela 5) — que não altera as estimativas — constitui evidência indireta de que municípios próximos, potencialmente mais expostos a *spillovers*, não distorcem o contrafactual. Não é necessário conduzir análise adicional; a justificativa textual é suficiente.
- **Localização:** §3.1.1 ou parágrafo de abertura de §5 (linhas 1198–1219).

### MC2: Sensibilidade ao limiar de *tratamento* (50%) não testada

- **Dimensão:** Identificação
- **Problema:** O artigo demonstra robustez à escolha do *limiar do pool doador* (0,5% → 10%, Tabela 5/Figura 8) mas não ao limiar que define quem é *tratado* (50%). A escolha de 50% é justificada como "alta severidade relativa" (§4.2), porém um árbitro pode notar que municípios logo abaixo (ex.: 45% atingidos) são excluídos da análise e do pool, enquanto municípios logo acima (ex.: 51%) são tratados. Essa descontinuidade não é testada. Em particular: (i) os dois municípios "sem efeito" (Igrejinha e Arambaré) estão no limite inferior do grupo tratado (50,9% e 51,9%); e (ii) o resultado substantivo — de que o efeito existe em quatro municípios mas não em dois — depende parcialmente de como o limiar é traçado.
- **Sugestão:** A solução mais simples é acrescentar uma frase em §4.2 reconhecendo que o limiar de 50% não é testado, e justificando sua natureza: *"O limiar de 50\% não constitui um ponto de corte arbitrário, mas um indicador de dominância: municípios acima desse patamar tiveram mais da metade de suas populações residentes deslocadas ou diretamente atingidas, configurando o que a literatura de desastres denomina 'impacto severo de escala municipal' \cite{cavallo2013}. A escolha não é testada por variação de limiar porque não há hipótese *a priori* alternativa a testar — o objetivo é identificar unidades com disrupção total do espaço econômico local, não selecionar municípios com base em um ponto de corte de otimização."* Alternativamente, se houver dados de municípios com 40–49% atingidos, uma análise de descontinuidade ao redor de 50% seria o teste mais robusto.
- **Localização:** §4.2, após o Quadro 2 (linhas 1108–1153).

### MC3: Inconsistência entre os $p$-valores bilaterais da Tabela 2 e os $p$-valores unilaterais da Tabela 3

- **Dimensão:** Econometria / Apresentação
- **Problema:** A Tabela 2 (`tab:att_principal`) reporta p-valores *bilaterais* de 0,041, 0,016, 0,036 e 0,036 para Eldorado, Muçum, Roca Sales e Travesseiro, respectivamente. A Tabela 3 (`tab:robustez`) reporta p-valores *unilaterais* (conforme nota [b]) de 0,021, 0,005, 0,021 e 0,021 para os mesmos municípios. Para Eldorado: 2 × 0,021 = 0,042 ≈ 0,041 (consistente, diferença de arredondamento). Para Roca Sales: 2 × 0,021 = 0,042 ≠ 0,036 (inconsistência de 0,006). Para Travesseiro: idem. Isso pode refletir que os p-valores das duas tabelas foram computados de formas diferentes (por exemplo, bilateral exato vs. 2 × unilateral) — o que seria legítimo mas deve ser explicado. Alternativamente, pode ser um erro de arredondamento ou de execução de script. Um árbitro de métodos vai capturar isso e pode lê-lo como evidência de inconsistência interna na inferência.
- **Sugestão:** Verificar no script `sdid_enchentes_2024_v5.R` se as duas tabelas são produzidas pelo mesmo procedimento (`permutar_matriz`) e, se sim, de onde vem a diferença de 0,006. Se for diferença entre bilateral exato e 2×unilateral, adicionar uma nota de rodapé na Tabela 3 explicando: *"$p$-valor unilateral exato; o bilateral correspondente ($2 \times p_{\text{uni}}$) é uma aproximação — o bilateral exato reportado na Tabela~\ref{tab:att_principal} pode diferir por até 0,01 devido a arredondamento."* Se for erro de script, reexecutar e corrigir.
- **Localização:** Tabelas 2 e 3 (linhas 1234–1260 e 1368–1394).

---

## Preocupações Menores

### mc1: Comparação quantitativa com Teixeira (2024) ausente nos Resultados

- **Problema:** Teixeira et al. (2024) é citado como referência comparativa em múltiplos pontos (§2.5, §5.3, §6), mas o artigo nunca apresenta os números de Teixeira ao lado dos próprios para o leitor comparar. A contribuição metodológica (SDiD vs. TWFE) fica clara; a contribuição substantiva (magnitudes similares? diferentes?) não.
- **Sugestão:** Adicionar uma frase em §5.1 ou em §6 com algo como: *"Para municípios equivalentes, Teixeira et al. (2024) estimaram efeitos nulos sobre desligamentos e reduções de X% nas admissões via TWFE-DiD — resultado consistente com as estimativas SDiD aqui reportadas / que diferem em Y% por razão Z."* (Os valores de X dependem de acesso ao artigo referenciado.)
- **Localização:** §5.1 (após Tabela 2) ou §6 (Considerações Finais, 1ª conclusão).

### mc2: Redundância entre §5.7 e §6

- **Problema:** As quatro conclusões de §5.7 ("Síntese dos Resultados") e as quatro conclusões de §6 ("Considerações Finais") são quase idênticas em conteúdo. O padrão típico em artigos de economia é que a síntese interna (§5.7) seja breve (1–2 parágrafos) e que as considerações finais acrescentem implicações de política e agenda de pesquisa. No estado atual, as "Considerações Finais" essencialmente repetem a síntese antes de acrescentar o novo material.
- **Sugestão:** Reduzir §5.7 a 2–3 frases de transição que remetam ao leitor à seção de conclusões, ou absorver o conteúdo de §5.7 nas considerações finais e eliminar a subseção.
- **Localização:** §5.7, linhas 1884–1921.

### mc3: "Quarta limitação" deveria ser reformulada como nota interpretativa

- **Problema:** A quarta limitação (§6, linhas 1990–1997) — que a significância estatística formal repousa "quase inteiramente na inferência por permutação do SDiD" — não é propriamente uma limitação do estudo, mas uma característica estrutural dos procedimentos de inferência com diferentes potências. Caracterizá-la como "limitação" implica que poderia ser diferente com melhores dados ou design; não pode.
- **Sugestão:** Transformar a quarta limitação em nota interpretativa: *"Por fim, uma nota de interpretação: a significância estatística formal repousa principalmente no SDiD (...). Isso não invalida a triangulação..."*
- **Localização:** §6, linhas 1990–1997.

### mc4: Caption da Figura 7 menciona "área sombreada" não verificável visualmente

- **Problema:** A legenda da Figura 7 menciona: "A área sombreada inferior representa os pesos temporais $\hat{\lambda}_t$". Essa referência a um elemento visual (área sombreada) não pode ser verificada sem abrir os PNGs. Se o script de geração dos gráficos não incluir essa área sombreada, a legenda está enganando o leitor.
- **Sugestão:** Confirmar que os PNGs `municipio_XXXXX_completo_trajetorias.png` incluem de fato a área sombreada representando $\hat{\lambda}_t$. Se não incluírem, remover essa frase da legenda.
- **Localização:** Caption da Figura 7 (`fig:trajetorias_todos`), linhas 1343–1352.

---

## Objeções de Árbitro

### RO1: Contaminação do pool por *spillovers* de equilíbrio geral

**Por que importa:** O argumento central do paper é que o pool doador ($N_0 = 193$, $\leq 0{,}5\%$ atingidos) constitui um contrafactual limpo. Mas mesmo municípios não atingidos por água podem ter seus mercados de trabalho perturbados indiretamente se firmarem nexos de insumos/demanda com os municípios tratados. A zona de exclusão *donut* protege contra contaminação por dano físico; não protege contra contaminação por cadeia produtiva. Um árbitro de métodos identificatórios vai levantar isso como potencial violação de SUTVA.

**Como responder:** A resposta não precisa ser uma análise nova — precisa ser um argumento de escala. Os municípios tratados têm população total de ~93 mil habitantes: dificilmente representam mais de 0,1–0,2% do PIB gaúcho. A disrupção localizada nessa escala raramente gera efeitos detectáveis via cadeia produtiva nos 193 controles, cuja base econômica é heterogênea e geograficamente dispersa. O parágrafo sugerido em MC1 é suficiente.

### RO2: Por que 50%? Mostre que o resultado não é um artefato desse corte

**Por que importa:** Com seis municípios tratados selecionados por um limiar de 50%, e dois deles sem efeito (Igrejinha: 50,9%, Arambaré: 51,9%), um árbitro pode suspeitar que a heterogeneidade no tratamento — e não o estimador — é o que produz a mistura de resultados. Se o limiar fosse 55%, Igrejinha e Arambaré desapareceriam do conjunto tratado e o paper encontraria "efeito uniforme" — o que pareceria muito mais limpo mas seria menos honesto.

**Como responder:** O artigo já está sendo honesto ao incluir os dois casos nulos — isso é um ponto forte. O que falta é uma frase que enquadre essa honestidade: o limiar não é de otimização, é substantivo. Ver MC2.

### RO3: Os $p$-valores das Tabelas 2 e 3 são consistentes entre si?

**Por que importa:** Com acesso ao script, um árbitro replicador vai perceber que Roca Sales e Travesseiro têm $p_{\text{uni}} = 0{,}021$ (Tab 3) mas $p_{\text{bi}} = 0{,}036$ (Tab 2), sendo $0{,}036 \neq 2 \times 0{,}021 = 0{,}042$. A discrepância de 0,006 é pequena mas pode ser lida como erro de tabela ou inconsistência de procedimento. Em um paper que depende da inferência por permutação como evidência central, qualquer sombra sobre os $p$-valores é fatal.

**Como responder:** Verificar o script e, se necessário, corrigir ou adicionar nota explicativa. Ver MC3.

### RO4: Como os seus resultados se comparam, quantitativamente, aos de Teixeira (2024)?

**Por que importa:** O paper posiciona Teixeira (2024) como a referência empírica mais próxima. Um árbitro vai querer saber: as magnitudes são similares? Se Teixeira também encontrou efeitos de ~3–5 admissões/mil com TWFE-DiD, a contribuição metodológica do SDiD é confirmada mas a contribuição substantiva é menor. Se as magnitudes diferem substancialmente, isso precisa ser explicado.

**Como responder:** Uma tabela de comparação ou mesmo uma frase com os números de Teixeira para os municípios sobrepostos é suficiente. Ver mc1.

### RO5: Sensibilidade ao início da janela de estimação (janeiro/2021)

**Por que importa:** A decisão de iniciar em janeiro/2021 é motivada pela normalização pós-pandemia, o que é razoável. Mas isso significa que $T_0 = 40$ e que o SDiD tem acesso a apenas 4 Januários e 3 períodos sazonais completos anteriores ao evento. Com uma janela iniciando em, por exemplo, janeiro/2019, $T_0 = 64$ e o ajuste sintético teria mais informação histórica — possivelmente alterando os pesos $\hat{\lambda}_t$ e as estimativas. O paper não testa esse tradeoff.

**Como responder:** Uma frase em §4.1 reconhecendo que a janela de 2021 foi escolhida por razões de homogeneidade metodológica (Novo CAGED + exclusão da fase aguda da pandemia), e que retroceder para 2019 introduziria heterogeneidade estrutural na série (mudança do sistema de declaração, distorções de pandemia), justifica a escolha sem precisar de análise adicional.

---

## Estatísticas Resumidas

| Dimensão | Avaliação (1–5) |
|---|---|
| Estrutura do Argumento | 4 |
| Estratégia de Identificação | 3,5 |
| Especificação Econométrica | 4 |
| Posicionamento na Literatura | 3,5 |
| Qualidade da Escrita | 4,5 |
| Apresentação | 4 |
| **Geral** | **4** |

---

## Prioridade de Correções

| # | Ação | Urgência | Esforço |
|---|---|---|---|
| 1 | Verificar inconsistência de $p$-valores Tabelas 2 vs 3 (MC3) | Alta | Baixo (verificar script) |
| 2 | Parágrafo de SUTVA/*spillovers* em §3.1.1 (MC1) | Alta | Baixo (texto, ~4 frases) |
| 3 | Justificativa do limiar de 50% (MC2) | Média | Baixo (texto, ~3 frases) |
| 4 | Comparação quantitativa com Teixeira (2024) (mc1) | Média | Baixo (1 frase + número) |
| 5 | Frase sobre sensibilidade da janela de estimação (RO5) | Média | Baixo (texto) |
| 6 | Reduzir redundância §5.7 / §6 (mc2) | Baixa | Médio (reestruturação) |
| 7 | Reformular "quarta limitação" (mc3) | Baixa | Baixo |
| 8 | Verificar área sombreada na Figura 7 (mc4) | Baixa | Baixo (visual) |
