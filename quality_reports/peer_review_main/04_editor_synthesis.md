---
date: 2026-06-17
agent: editor
journal: RAE (Revista Análise Econômica — UFRGS)
round: 1
decision: REVISE_AND_RESUBMIT
---

# Carta de Decisão Editorial — RAE

**Manuscrito:** Avaliação Causal das Enchentes de Maio de 2024 no RS sobre o Emprego Formal  
**Decisão:** Revisão e Resubmissão (com prazo sugerido de 60 dias)  
**Data:** 2026-06-17

---

## Ao(s) Autor(es),

Submetemos seu manuscrito à avaliação de dois árbitros especializados — um com foco em metodologia de identificação causal (Árbitro 1) e outro com foco em contribuição substantiva e relevância de política pública (Árbitro 2). Ambos recomendam **Revisão e Resubmissão**.

O trabalho apresenta uma contribuição genuína e oportuna: a avaliação causal do impacto das enchentes de maio de 2024 no RS sobre admissões em emprego formal, usando Diferença-em-Diferenças Sintética com triangulação por TWFE-DiD e Controle Sintético. Os resultados são substantivos — especialmente a convergência dos estimadores para os quatro municípios com efeito robusto, a dinâmica acumulada para Eldorado do Sul, e a análise de heterogeneidade por canais de dano produtivo. O periódico tem interesse em publicar este trabalho após as revisões necessárias.

---

## Exigências para Resubmissão

As seguintes revisões são **obrigatórias** (sem elas, o manuscrito será devolvido sem revisão adicional):

### R1: Completar Seção 4 (Dados)

A seção atual é um placeholder com pontos enumerados. É necessário um texto completo descrevendo: (a) a janela de estimação (T₀ = 40 meses) e sua justificativa; (b) os dados CAGED e o procedimento de extração da variável-resultado; (c) o critério de definição de municípios tratados (>50% da população atingida, via base MUPRS) e sua justificativa; (d) a formação do pool doador (critério de <1% e o resultado de N₀ = 193 municípios); (e) estatísticas descritivas básicas do painel.

*Comentário do editor:* Sem a Seção 4, não é possível avaliar se o design de pesquisa é defensável. Esta é a seção mais crítica para credibilidade da identificação.

### R2: Completar Seção 6 (Considerações Finais)

A seção é um placeholder. Deve conter: (a) síntese dos principais achados; (b) implicações para políticas de recuperação (à luz dos achados de heterogeneidade por canal de dano produtivo vs. residencial); (c) limitações do estudo (N pequeno de tratados, placeholders de seção, limite da análise à margem de admissões); (d) agenda de pesquisa.

*Comentário do editor:* Para um periódico de política aplicada como a RAE, as implicações de política não são acessório — são parte central da contribuição.

### R3: Endereçar a Contaminação Potencial do Pool Doador

O Árbitro 1 levanta a preocupação mais séria do paper: se municípios com 10–40% da população atingida também sofreram impacto econômico das enchentes, mas entram no pool doador pelo critério de <1%, o contrafatual pode estar contaminado. Os autores devem: (a) apresentar análise de sensibilidade variando o threshold de exclusão (1%, 5%, 10%); (b) incluir mapa dos municípios excluídos do pool por nível de impacto intermediário; (c) discutir explicitamente o pressuposto SUTVA e por que o critério de 1% é defensável.

*Comentário do editor:* Este é o principal risco de identificação do paper. Uma análise de sensibilidade convincente pode neutralizá-lo.

### R4: Incluir Diagnóstico Formal de Tendências Pré-Tratamento

Para o componente TWFE-DiD da triangulação, incluir um event-study com coeficientes pré-tratamento que demonstre ausência de tendências diferenciais antes de maio de 2024. Para o SDiD, incluir o gráfico de trajetória sintética vs. observada no pré-período ao menos para Eldorado do Sul e Muçum.

### R5: Resolver as Redundâncias Estruturais

(a) Remover o bloco de Resumo/Abstract original (versão de 2 municípios) — apenas a versão revisada de 6 municípios deve permanecer. (b) Remover todos os comentários de rascunho expostos no código LaTeX (`% Fonte?`, `% diminuir o tamanho`, `% Não sei se vale a pena...`). (c) Atualizar autores e número do artigo.

---

## Revisões Recomendadas (não obrigatórias, mas fortemente sugeridas)

### S1: Múltiplos Testes

O Árbitro 1 aponta que 18 comparações (6 municípios × 3 estimadores) sem correção de múltiplos testes inflam a taxa de falsos positivos. Recomendamos ao menos uma discussão deste ponto — seja aplicando correção Bonferroni à tabela principal (tab:att_principal), seja argumentando explicitamente por que a triangulação entre estimadores já provê proteção suficiente.

### S2: Benchmarking dos Efeitos Absolutos

Os números absolutos (1.619 admissões em Eldorado do Sul, ~2.390 no total) ganhariam em poder comunicativo se contextualizados — como porcentagem das admissões médias anuais pré-enchentes, ou em comparação com estimativas similares da literatura de desastres.

### S3: Distinguir Métodos de Inferência no Forest Plot

A Figura fig:forest mistura IC95% de dois tipos (gaussiano cluster-robust para TWFE-DiD; permutação para SC e SDiD). Uma nota de rodapé ou indicador visual distinguindo os dois tipos protege o leitor de comparações indevidas.

### S4: Completar Discussão sobre Teixeira (2024)

Explicitar o status editorial de Teixeira (2024) e diferenciar a contribuição deste manuscrito em relação a esse trabalho paralelo.

### S5: Figura fig:perfilz

Avaliar remoção desta figura ou reformulação substancial. O próprio autor questiona sua utilidade (como indica comentário interno). A Figura fig:canais transmite a mensagem com mais clareza.

### S6: Citar Deryugina et al. (2018)

Incluir "The Economic Impact of Hurricane Katrina on Its Victims" (AEJ: Applied Economics, 2018) na revisão de literatura, como o paper de referência mais próximo metodologicamente.

---

## Síntese das Preocupações por Árbitro

| Preocupação | Árbitro | Gravidade | Mapeada em |
|-------------|---------|-----------|-----------|
| Seção 4 ausente (Dados) | 2 (PM1) | Crítica | R1 |
| Seção 6 ausente (Conclusões) | 2 (PM1) | Crítica | R2 |
| Contaminação do pool doador | 1 (PM1) | Crítica | R3 |
| Sem teste de paralelas formal | 1 (PM2) | Maior | R4 |
| Redundâncias estruturais / rascunho | 2 (pm1,pm2,pm5) | Maior | R5 |
| Múltiplos testes | 1 (PM3) | Maior | S1 |
| Benchmarking de absolutos | 2 (PM2) | Maior | S2 |
| Inferência mista no forest plot | 1 (PM4) | Maior | S3 |
| Teixeira (2024) subdiscutido | 2 (PM4) | Maior | S4 |
| Figura fig:perfilz | 1 (pm4), 2 (pm4) | Menor | S5 |
| Deryugina et al. ausente | 2 (pm6) | Menor | S6 |

---

## Avaliação de Mérito Científico

O trabalho é metodologicamente competente e substantivamente relevante. Os achados de triangulação e heterogeneidade são contribuições genuínas para a literatura de avaliação de desastres no Brasil. A qualidade da argumentação nas Seções 1–5 (as que existem) é adequada para a RAE.

O manuscrito está em estado de "rascunho avançado" — não em estado de submissão. As revisões obrigatórias (R1–R5) são substanciais mas não requerem nova coleta de dados ou reestimação do modelo principal. A expectativa do editor é que um pesquisador dedicado possa completar as revisões em 45–60 dias.

Aguardamos a resubmissão.

---

## Arquivo de Decisão (SCORECARD)

```
FINDING:BLOCK — Seção 4 ausente (identificação não pode ser avaliada)
FINDING:BLOCK — Seção 6 ausente (contribuição incompleta)
FINDING:CRITICAL — Contaminação pool doador (ameaça à validade interna)
FINDING:MAJOR — Sem evento-study / diagnóstico pré-tratamento formal
FINDING:MAJOR — Múltiplos testes sem correção (18 comparações)
FINDING:MAJOR — Inferência mista no forest plot
FINDING:MAJOR — Teixeira (2024) subdiscutido
FINDING:MAJOR — Benchmarking dos absolutos ausente
FINDING:MINOR — Figura fig:perfilz (valor questionável)
FINDING:MINOR — Deryugina et al. ausente
FINDING:MINOR — Rascunho exposto (comentários LaTeX, dois abstracts)

VERDICT: REVISE_AND_RESUBMIT
GATE: BLOCK (3 BLOCKs resolvíveis, 1 CRITICAL resolvível com análise adicional)
```

---
*Relatórios completos dos árbitros: `02_referee1_methods_credibility.md` e `03_referee2_domain_policy.md`*
