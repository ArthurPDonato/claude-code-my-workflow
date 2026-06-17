---
date: 2026-06-17
agent: domain-referee
disposition: POLICY
journal: RAE
round: 1
---

# Relatório do Árbitro 2 — Domínio Substantivo / Política Pública

**Manuscrito:** Avaliação Causal das Enchentes de Maio de 2024 no RS sobre o Emprego Formal  
**Disposição:** POLICY — foco em contribuição substantiva, relevância de política pública, posicionamento na literatura  

---

## Avaliação Geral

O manuscrito aborda uma questão empiricamente urgente e politicamente relevante: qual foi o impacto causal das enchentes de 2024 no RS sobre o mercado de trabalho formal? A resposta tem implicações diretas para o desenho de políticas de recuperação — especialmente para a alocação entre auxílio às famílias, recuperação de firmas e reconstrução de infraestrutura viária.

O trabalho entrega contribuições substantivas genuínas: (i) quantifica o efeito sobre admissões formais para os seis municípios mais atingidos, separando os que têm efeito robusto dos que não têm; (ii) constrói a curva de efeito acumulado ao longo de onze meses, revelando dinâmica não-linear (padrão em "W"); (iii) oferece uma análise descritiva de heterogeneidade por canais de dano que gera hipóteses para pesquisa futura. O uso de dados administrativos CAGED é uma escolha metodológica sólida para o contexto brasileiro.

A principal limitação do manuscript *como submetido* é o estado incompleto: a Seção 6 (Considerações Finais) é um placeholder e a Seção 4 (Dados) está esquematizada mas não escrita. Isso impede a avaliação completa das implicações de política que são, da perspectiva desta resenha, a contribuição mais valiosa potencial do trabalho.

**Recomendação: Revisão e Resubmissão** — com exigência de completar as seções faltantes e endereçar as preocupações substantivas abaixo.

---

## Pontos Fortes

1. **Relevância e oportunidade:** As enchentes de 2024 foram o maior desastre climático da história do RS. Há demanda real — tanto acadêmica quanto de política — por evidência causal sobre os efeitos econômicos. O trabalho está na fronteira temporal dos eventos, o que é uma vantagem competitiva.

2. **Quantificação em postos de trabalho absolutos** (Tabela tab:acumulado): a conversão do ATT em números absolutos (1.619 admissões suprimidas em Eldorado do Sul, ~2.390 no total) é a contribuição mais direta para o debate de política. Essa é a linguagem que formuladores de política entendem e usam.

3. **Achado de heterogeneidade por canais de dano** (Seção 5.5): a descoberta de que o dano viário e o dano a firmas discriminam melhor os municípios com/sem efeito do que o dano residencial é uma informação de política com implicações claras — políticas de recuperação que privilegiam habitação em vez de infraestrutura produtiva podem ser subótimas. Esse achado é o mais novo e mais acionável do paper.

4. **Discussão de Igrejinha como exceção informativa:** O fato de Igrejinha — com danos comparáveis a municípios que sofreram efeito — não exibir resposta significante, e a hipótese de diversificação econômica como mecanismo de resiliência, é relevante para políticas de desenvolvimento regional que priorizem diversificação produtiva preventiva.

5. **Distinção entre margem de entrada e margem de saída do emprego:** A Seção 5.4 esclarece que o ajuste do emprego formal se deu pela margem de entrada (admissões), não desligamentos — informação diretamente relevante para a escolha de instrumentos de política (subsídios à contratação vs. proteção ao emprego existente).

---

## Preocupações Maiores

### PM1: Seções 4 e 6 Ausentes — Manuscrito Incompleto

**Dimensão:** Argumento / Apresentação  
**Gravidade:** CRÍTICA para submissão, ENDEREÇÁVEL

**Problema:** O manuscrito está incompleto. A Seção 4 (Dados) é central para que o leitor avalie a construção da amostra e a qualidade dos dados; sem ela, afirmações sobre T₀ = 40, critério de tratamento, e pool doador não podem ser avaliadas. A Seção 6 (Considerações Finais) é onde deveriam estar: síntese da contribuição, implicações de política, limitações e agenda de pesquisa.

**Como endereçar:**
- Completar a Seção 4 com: (a) janela de estimação e justificativa; (b) fonte CAGED e procedimento de extração; (c) critério de tratamento e fontes MUPRS; (d) estatísticas descritivas do painel (N municípios, T períodos, distribuição da variável resultado).
- Completar a Seção 6 com pelo menos: (a) síntese de 3–4 achados principais; (b) implicações para política de recuperação (qual combinação de políticas é sugerida pela heterogeneidade de canais de dano?); (c) limitações principais; (d) agenda de pesquisa (extensões naturais: setores de atividade, dados de demissões, tempo até recuperação completa).

**Localização:** Seções 4 e 6.

---

### PM2: Benchmarking dos Números Absolutos

**Dimensão:** Argumento / Relevância  
**Gravidade:** MAIOR

**Problema:** Os efeitos acumulados em postos de trabalho (tab:acumulado) são apresentados sem benchmarking. "2.390 admissões suprimidas em 4 municípios" — mas em relação a quê? O leitor não tem referência para avaliar a magnitude econômica desse número.

**Como endereçar:**
1. Reportar o número de admissões totais anuais nesses municípios antes das enchentes (média pré-tratamento CAGED por município), de modo que o efeito possa ser expresso como uma porcentagem da atividade normal.
2. Comparar com benchmarks da literatura: por exemplo, quanto desastres similares suprimiram em outros contextos (Deryugina et al. 2018 para furacões nos EUA, ou estudos brasileiros).
3. Opcional: calcular o "tempo de recuperação implícito" — se o déficit médio mensal é X por mil habitantes, quantos meses de atividade normal seriam necessários para recuperar o estoque perdido?

**Localização:** Seção 5.4 (Efeito acumulado) e Seção 6 (quando completada).

---

### PM3: Políticas de Recuperação — Avaliação Incompleta

**Dimensão:** Política pública  
**Gravidade:** MAIOR

**Problema:** O manuscrito menciona que os auxílios emergenciais (Volta por Cima, SOS-RS) foram excluídos da análise de heterogeneidade por serem "bad controls" — decisão metodologicamente correta. Mas o leitor natural da RAE (economista regional ou formulador de política) quer saber: essas políticas funcionaram? O paper está em posição única para ao menos discutir essa questão, mesmo que não possa respondê-la causalmente.

**Como endereçar:**
1. Na Seção 6, incluir uma subseção de "Implicações de Política" que: (a) descreva brevemente o mix de políticas implementado (Volta por Cima, SOS-RS, FGTS emergencial); (b) aponte que a avaliação causal dessas políticas está além do escopo deste paper; (c) sugira que a arquitetura de dados (CAGED + MUPRS + registros de beneficiários) seria adequada para uma avaliação futura.
2. Discutir se os resultados — efeito via margem de entrada, canais de dano produtivo — sugerem que políticas de crédito a firmas afetadas e de recuperação viária seriam mais eficazes do que transferências a famílias para restaurar o emprego formal.

**Localização:** Seção 6 (quando completada).

---

### PM4: Relação com Teixeira (2024) Subdiscutida

**Dimensão:** Posicionamento na literatura  
**Gravidade:** MAIOR

**Problema:** Teixeira (2024) aparece várias vezes como resultado de referência (nulidade dos desligamentos). Mas o leitor não consegue entender: esse trabalho usa os mesmos dados? O mesmo evento? A mesma amostra de municípios? É um working paper, artigo publicado, ou apresentação de congresso? E qual é a contribuição deste manuscrito em relação a Teixeira (2024)?

**Como endereçar:**
1. Adicionar um parágrafo na Seção 2 (Revisão de Literatura) distinguindo explicitamente a contribuição deste trabalho em relação a Teixeira (2024): método diferente? Amostra diferente? Foco em admissões vs. emprego estoque? A triangulação como contribuição?
2. Identificar claramente o status editorial de Teixeira (2024) (publicado / preprint / mimeo).

**Localização:** Seção 2 (Revisão de Literatura), Seção 3 ou 6.

---

## Preocupações Menores

### pm1: Dois Blocos de Resumo/Abstract

O manuscrito contém dois blocos de Resumo/Abstract: o original (versão com 2 municípios, linhas ~186–227) e o revisado (versão com 6 municípios, linhas ~294–341). O bloco original deve ser removido — ele expõe o histórico de desenvolvimento do paper ao árbitro.

### pm2: Autores como A, B, C

Inconsistente: o manuscrito é submetido com autores como "A", "B", "C" e número de artigo "exxxxx". Se o periódico usa blind review, esses são placeholders corretos, mas devem ser confirmados com as instruções da RAE.

### pm3: Interpretação de Eldorado do Sul

O segundo pico em janeiro de 2025 (efeito de –10,15 por mil em Eldorado do Sul) é o maior estimado na série. Os autores o atribuem a danos de infraestrutura de transporte (hipótese Xiao 2014). Mas há uma hipótese alternativa: efeitos sazonais (janeiro é período de menor atividade no setor de construção, que pode ter sido especialmente afetado). Mencioná-la e descartá-la (ou não) seria prudente.

### pm4: Figura fig:perfilz — considerar remover

O próprio autor questiona (em comentário de rascunho) se o gráfico de perfil Z padronizado vale a pena manter. Concordo: o gráfico fig:canais (canais centrais de dano) transmite a mensagem com muito mais clareza. A Figura fig:perfilz adiciona complexidade visual sem adição proporcional de insight. Recomendo cortar.

### pm5: Interpretação de "Admissões por Mil Habitantes"

A variável-resultado (admissões formais por mil habitantes) é clara para um público de métodos, mas pode ser desorientadora para leitores de política. Um parágrafo breve na Seção 4 explicando a escolha desta normalização (em vez de, por exemplo, admissões por trabalhador formal) seria útil.

### pm6: Missing: Deryugina et al. (2018)

O artigo "The Economic Impact of Hurricane Katrina on Its Victims" (Deryugina, Kawano & Levitt 2018, *AEJ: Applied Economics*) é o paper de referência mais próximo à identificação causal de efeitos de desastre sobre mercado de trabalho. Não é citado. Para um árbitro POLICY, essa ausência sinaliza que a revisão de literatura pode ter lacunas.

---

## Objeções de Árbitro

### OA4: "O paper não tem conclusão — como posso avaliar a contribuição?"

**Por que é potencialmente fatal (para submissão):** Na forma atual, o paper termina abruptamente após a síntese dos resultados (Seção 5.6). Sem a Seção 6, não há: síntese da contribuição, articulação das implicações de política, nem agenda de pesquisa. Para uma revista de política econômica como a RAE, a Seção 6 não é acessório — é onde o valor do trabalho se cristaliza.

**Como responder:** Completar a Seção 6.

---

### OA5: "Os achados de heterogeneidade não têm poder causal — por que são centrais?"

**Por que é saudável levantar:** A Seção 5.5 é explicitamente descritiva (n=6, sem inferência formal). Um árbitro policy pode questionar: se os achados de heterogeneidade são apenas descritivos e associativos, qual é a contribuição analítica além da triangulação?

**Como responder:** Os autores devem fortalecer o argumento de que a heterogeneidade descritiva — quando baseada em mecanismos teoricamente fundamentados (canal de capital vs. canal de conectividade) e com uma advertência metodológica explícita — é uma contribuição legítima para a geração de hipóteses. A literatura de desastres opera frequentemente com amostras pequenas; a honestidade sobre os limites inferenciais é, ela própria, uma contribuição metodológica.

---

## Resumo de Dimensões

| Dimensão | Nota (1–5) |
|----------|-----------|
| Contribuição original | 4 |
| Relevância para política pública | 4 |
| Posicionamento na literatura | 3 |
| Validade externa | 3 |
| Clareza e argumentação | 3 (penalizado pelos placeholders) |
| **Média** | **3.4** |

**Recomendação: Revisão e Resubmissão.** O trabalho tem mérito real e relevância clara para a RAE. As seções faltantes são a barreira principal.
