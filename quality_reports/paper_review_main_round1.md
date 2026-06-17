---
date: 2026-06-17
skill: review-paper
mode: --peer RAE
round: 1
verdict: REVISE_AND_RESUBMIT
---

# Revisão do Manuscrito — `/review-paper --peer RAE`

**Manuscrito:** Avaliação Causal das Enchentes de Maio de 2024 no RS sobre o Emprego Formal  
**Arquivo:** `Artigos/SDID/arquivos latex/main.tex`  
**Periódico:** Revista Análise Econômica (RAE — UFRGS)  
**Data:** 2026-06-17  
**Árbitro 1:** Methods/CREDIBILITY | **Árbitro 2:** Domain/POLICY

---

## Avaliação Geral

**Decisão editorial simulada:** **Revisão e Resubmissão**

O manuscrito apresenta uma contribuição legítima e oportuna à literatura de avaliação de desastres no Brasil. A triangulação SDiD + TWFE-DiD + Controle Sintético para seis municípios gaúchos afetados pelas enchentes de 2024, com quantificação dos efeitos acumulados em postos de trabalho e análise de heterogeneidade por canais de dano, é metodologicamente competente e substantivamente relevante para leitores da RAE.

**O manuscrito está em estado de rascunho avançado, não de submissão.** Duas seções inteiras estão faltando (Dados e Considerações Finais), dois blocos de resumo coexistem, e comentários de rascunho estão expostos no código LaTeX. Esses problemas precisam ser corrigidos antes da submissão, independentemente de qualquer resposta à revisão substantiva.

As preocupações substantivas endereçáveis mais sérias são: (1) a contaminação potencial do pool doador por municípios afetados abaixo do threshold de tratamento; (2) a ausência de event-study / diagnóstico formal de tendências pré-tratamento; (3) múltiplos testes sem correção. Nenhuma dessas preocupações é fatal — todas têm resposta analítica disponível nos dados.

---

## Problemas Críticos (exigem resolução antes da submissão)

| # | Problema | Seção | Tipo |
|---|----------|-------|------|
| C1 | Seção 4 (Dados) é placeholder | §4 | Estrutural |
| C2 | Seção 6 (Considerações Finais) é placeholder | §6 | Estrutural |
| C3 | Dois blocos de Resumo/Abstract no PDF | linhas ~186–340 | Estrutural |
| C4 | Autores como "A, B, C", número "exxxxx" | Capa | Submissão |
| C5 | Comentários de rascunho no .tex | vários | Submissão |

---

## Preocupações Maiores (identificação e econometria)

### MC1: Contaminação do Pool Doador (CRÍTICA para identificação)

As enchentes de 2024 afetaram centenas de municípios do RS, não apenas os 6 com >50% da população atingida. Municípios com 10–40% de impacto provavelmente também sofreram retração no emprego formal, mas entram no pool doador pelo critério de <1% dos autores. Se os doadores estão contaminados, o contrafatual é viesado e as estimativas do ATT não são interpretáveis como efeito causal puro das enchentes.

**Solução:** Análise de sensibilidade variando o threshold de exclusão (1%, 5%, 10%); mapa dos excluídos; discussão explícita do SUTVA.

### MC2: Sem Diagnóstico Formal de Tendências Pré-Tratamento

O RMSPE do SC é um indicador de qualidade do ajuste do sintético, não um teste de paralelas para o TWFE-DiD. O evento-study com coeficientes pré-tratamento é agora padrão mínimo para qualquer DiD publicado.

**Solução:** Incluir event-study para TWFE-DiD; gráfico de trajetória sintética vs. observada para SDiD (Eldorado do Sul e Muçum, ao menos).

### MC3: Múltiplos Testes — 6 Municípios × 3 Estimadores

18 comparações sem correção: com α = 5%, espera-se ~0.9 falso positivo por azar. Os quatro "resultados robustos" podem incluir um falso positivo.

**Solução:** Aplicar correção Bonferroni à tabela principal (tab:att_principal), ou argumentar explicitamente por que a triangulação protege adequadamente contra múltiplos testes.

### MC4: Inferência Mista no Forest Plot

O forest plot (fig:forest) mistura IC95% gaussianos (TWFE-DiD) com IC95% por permutação (SC, SDiD). Os dois tipos não são diretamente comparáveis — o intervalo cluster-robust é assintótico; o permutação é exato sob permutabilidade.

**Solução:** Nota de rodapé na tabela + indicador visual no gráfico; ou calcular bootstrap de bloco para TWFE-DiD para uniformizar.

---

## Preocupações Maiores (substantivas e literatura)

### MS1: Benchmarking dos Efeitos Absolutos

"~2.390 admissões suprimidas" é difícil de interpretar sem referência. Qual porcentagem das admissões normais anuais nesses municípios isso representa? Como se compara com desastres similares na literatura?

### MS2: Teixeira (2024) Subdiscutido

Citado como resultado de referência para a nulidade dos desligamentos, mas sem: status editorial claro, diferenciação da contribuição deste manuscrito, ou discussão de se usa os mesmos dados/amostra.

### MS3: Políticas de Recuperação Não Discutidas

O paper exclui corretamente as políticas de recuperação da análise de heterogeneidade, mas a Seção 6 (quando completada) deve pelo menos discutir o que os achados implicam para o desenho de políticas futuras de recuperação — em particular a ênfase em firmas/infraestrutura viária sobre habitação.

---

## Preocupações Menores

| # | Problema | Localização |
|---|----------|------------|
| m1 | SUTVA não mencionado explicitamente | §3 |
| m2 | Critério de corte 50% não justificado teoricamente | §4 (quando escrito) |
| m3 | Figura fig:perfilz — dificuldade de interpretação (próprio autor questiona) | §5.5 |
| m4 | Deryugina, Kawano & Levitt (2018) ausente da revisão de literatura | §2 |
| m5 | Status editorial de Teixeira (2024) não especificado | Referências |
| m6 | "IC95% por placebo na curva acumulada" sem referência metodológica | §5.4 |
| m7 | Sazonalidade como hipótese alternativa para o segundo pico em jan./2025 | §5.4 |
| m8 | Variável-resultado (admissões/mil hab.) sem justificativa da normalização | §4 |

---

## Pontos Fortes (a preservar na revisão)

1. **Triangulação metodológica** — o ponto mais forte do trabalho. Convergência entre três estimadores com hipóteses distintas é evidência de identificação robusta que a maioria da literatura não oferece.
2. **Advertência metodológica para heterogeneidade** (§5.5) — a caixa de "Advertência metodológica" com n=6 e "apenas descritivo" é exemplar. Não sobreinterpretar é uma contribuição em si.
3. **Consciência dos limites de Muçum** — o tratamento diferenciado de "inferência parcial" para Muçum (RMSPE alto) é metodologicamente honesto.
4. **Achado de heterogeneidade por canais de dano** — dano viário e dano a firmas discriminam melhor que dano residencial. É o resultado mais novo e acionável do paper para política.
5. **Curva de efeito acumulado** — padrão em "W" para Eldorado do Sul com segundo pico em jan./2025 é resultado substantivo não trivial.
6. **Quantificação em postos de trabalho absolutos** — conversão do ATT em números absolutos (tab:acumulado) é essencial para comunicação com público de política.

---

## Objeções de Árbitro (as mais difíceis)

| # | Objeção | Árbitro | Como responder |
|---|---------|---------|----------------|
| OA1 | "Seus controles foram afetados pelas mesmas enchentes" | 1 | Análise de sensibilidade do threshold do pool doador |
| OA2 | "Seis unidades tratadas não são suficientes para inferência robusta" | 1 | Mostrar distribuição dos pesos; citar Arkhangelsky (2021) §3 |
| OA3 | "Critério de tratamento é endógeno ao resultado" | 1 | Discutir natureza administrativa/geográfica da base MUPRS |
| OA4 | "O paper não tem conclusão" | 2 | Completar Seção 6 |
| OA5 | "Heterogeneidade descritiva com n=6 não é contribuição analítica" | 2 | Fortalecer argumento de geração de hipóteses teoricamente fundamentadas |

---

## Checklist de Revisão para o Autor

### Obrigatório (antes de resubmeter)
- [ ] Completar Seção 4 (Dados)
- [ ] Completar Seção 6 (Considerações Finais)
- [ ] Remover bloco de Resumo/Abstract original (versão 2 municípios)
- [ ] Remover comentários de rascunho do .tex
- [ ] Análise de sensibilidade do pool doador (threshold 1%, 5%, 10%)
- [ ] Incluir event-study para TWFE-DiD (coeficientes pré-tratamento)
- [ ] Incluir gráfico de trajetória sintética vs. observada (SDiD, Eldorado do Sul + Muçum)
- [ ] Aplicar correção de múltiplos testes ou justificar por que não é necessária

### Fortemente recomendado
- [ ] Benchmarking dos efeitos absolutos (como % das admissões normais anuais)
- [ ] Discussão explícita de SUTVA em §3
- [ ] Distinguir inferência TWFE-DiD vs. permutação no forest plot
- [ ] Clarificar status editorial de Teixeira (2024)
- [ ] Adicionar Deryugina et al. (2018) na revisão de literatura
- [ ] Discutir implicações para políticas de recuperação em §6
- [ ] Avaliar remoção ou reformulação de fig:perfilz

---

## Resumo de Dimensões

| Dimensão | Nota (1–5) |
|----------|-----------|
| Questão de pesquisa e motivação | 5 |
| Estratégia de identificação | 3 |
| Econometria e especificação | 3 |
| Resultados e robustez | 4 |
| Posicionamento na literatura | 3 |
| Redação e apresentação | 3 (penalizado por seções faltantes) |
| Relevância para política pública | 4 |
| **Média ponderada (RAE)** | **3.5** |

*Pesos RAE: Política (0.35) × 4 + Credibilidade (0.25) × 3 + Medição (0.20) × 3 + outros = 3.5 aproximado*

---

## Próximos Passos Sugeridos

1. **Agora (rascunho):** Completar Seções 4 e 6 — são a barreira mais simples de remover.
2. **Análise adicional:** Rodar a análise de sensibilidade do pool doador e o event-study para TWFE-DiD nos scripts R.
3. **Revisão de literatura:** Adicionar Deryugina et al. (2018) e fechar a relação com Teixeira (2024).
4. **Limpeza:** Remover rascunhos expostos, resolver os dois abstracts, remover fig:perfilz.
5. **Resubmissão:** Após resolver C1–C5 e MC1–MC4, o paper estará em condições de submissão à RAE.

---

*Relatórios completos: `quality_reports/peer_review_main/01_editor_desk_review.md`, `02_referee1_methods_credibility.md`, `03_referee2_domain_policy.md`, `04_editor_synthesis.md`*
