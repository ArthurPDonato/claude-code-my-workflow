# Revisão de Literatura: Seguro-Desemprego no Brasil e o efeito causal da Lei 13.134/2015

**Data:** 2026-09-30
**Query:** Revisão completa para artigo sobre seguro-desemprego (SD) no Brasil e o efeito causal da Lei 13.134/2015 — teoria e efeitos do SD; SD no Brasil (informalidade, acesso repetido); avaliações da reforma de 2015; métodos (ITS/ARIMA de intervenção, CausalImpact/BSTS, RD/DiD).

---

## Resumo

A literatura de seguro-desemprego (SD) organiza-se em torno de um trade-off central: o benefício provê **seguro/liquidez** a trabalhadores demitidos, mas pode **distorcer a busca** por emprego (moral hazard), prolongando o desemprego. O aparato teórico moderno (Baily, 1978; Chetty, 2008) mostra que o valor ótimo do benefício depende de quanto do efeito sobre a duração vem de *liquidez* (desejável, corrige mercado de crédito incompleto) versus *distorção de incentivo*. Chetty (2008) estima que ~60% do efeito do SD sobre a duração é liquidez, justificando benefícios generosos. A evidência quase-experimental recente (Schmieder & von Wachter, 2016; Nekoei & Weber, 2017) refina isso: extensões de duração têm efeitos modestos sobre o não-emprego e, em alguns contextos, **melhoram a qualidade do reemprego**.

No Brasil, a agenda foi transformada por microdados administrativos ligados (RAIS/CAGED/registro do SD). O tema dominante é a **margem informal**: Gerard & Gonzaga (2021) mostram que o custo de eficiência do SD é *menor* em mercados mais informais; Britto (2022) compara SD (contingente) e FGTS/multa (lump-sum) e encontra que o SD induz transição para informalidade, mas ainda assim é preferível; Britto, Pinotti & Sampaio (2022) usam RD na elegibilidade e mostram que o SD **anula o aumento de criminalidade** pós-demissão enquanto o benefício dura. Esse último desenho — **RD na descontinuidade de elegibilidade** — é diretamente transponível para avaliar a Lei 13.134/2015.

A reforma de 2015 (MP 665/2014 → Lei 13.134/2015) endureceu o acesso: o tempo mínimo de vínculo para a **1ª solicitação subiu de ~6 para 12 meses** (nos últimos 18); 2ª para 9 meses; 3ª+ inalterada. O governo projetava economia de ~R$ 6,4 bi e 1,6 mi de trabalhadores (19%) fora do benefício em 2015. **Avaliações causais dedicadas dessa reforma são escassas** — a principal referência descritiva é Amorim, Sousa & Silva (2024, IPEA TD 3059). Essa é a lacuna que o artigo ocupa. Metodologicamente, a análise agregada (ARIMA de intervenção — Box & Tiao, 1975; CausalImpact/BSTS — Brodersen et al., 2015) esbarra na recessão coincidente de 2015–16, o que motiva a virada para desenhos de microdados (RD/DiD — Lee & Lemieux, 2010; Calonico et al., 2014; Callaway & Sant'Anna, 2021).

---

## Artigos-chave (por relevância)

### Britto, Pinotti & Sampaio (2022) — Job loss, SD e crime no Brasil
- **Contribuição:** liga carreiras, registros criminais e o registro do SD para o universo de homens no Brasil.
- **Método:** event-study de demissões (mass layoffs) + **RD na elegibilidade ao SD**.
- **Achado:** demissão eleva a probabilidade de crime em ~23%; a elegibilidade ao SD **anula** esse aumento enquanto o benefício dura, e o efeito reaparece na exaustão. Aponta liquidez/estresse como mecanismo.
- **Relevância:** modelo direto do desenho RD na elegibilidade — o caminho proposto para a Lei 13.134/2015.

### Gerard & Gonzaga (2021) — Informalidade e custo de eficiência do SD
- **Contribuição:** quantifica o custo de eficiência de estender a duração potencial do SD num país com alta informalidade.
- **Método:** microdados administrativos; variação nas regras de duração do SD brasileiro.
- **Achado:** custo de eficiência **menor** que nos EUA e *menor* onde a informalidade é maior (porque o reemprego formal já é baixo mesmo sem resposta comportamental).
- **Relevância:** referência teórico-empírica central sobre SD em mercado dual; enquadra a margem informal.

### Britto (2022) — Lump-sum vs. contingente (FGTS vs. SD)
- **Contribuição:** compara políticas de proteção lump-sum (rescisão/FGTS) e contingentes (SD).
- **Método:** microdados brasileiros; desenhos quase-experimentais em torno de regras.
- **Achado:** o SD induz transição para o setor informal (efeito atenua no médio prazo), mas continua desejável; lump-sum tem efeito pior sobre emprego formal e salários de reemprego.
- **Relevância:** desenho e dados quase idênticos aos necessários; base para desfechos de bem-estar.

### Chetty (2008) — Moral hazard vs. liquidez
- **Contribuição:** decompõe o efeito do SD sobre a duração em liquidez vs. distorção de incentivo.
- **Método:** heterogeneidade por restrição de liquidez + efeito de pagamentos lump-sum (severance).
- **Achado:** ~60% do efeito é liquidez; benefício ótimo > 50% do salário.
- **Relevância:** arcabouço para interpretar qualquer efeito estimado da reforma (restrição vs. incentivo).

### Schmieder & von Wachter (2016) — Survey dos efeitos do SD
- **Contribuição:** tratamento unificado do bem-estar de nível e duração do benefício.
- **Método:** revisão de estimativas quase-experimentais (RD, sobretudo Alemanha, 20 anos).
- **Achado:** efeitos de duração pequenos a modestos; extensões em recessão não elevam a duração de forma duradoura; efeito ~nulo sobre qualidade média do emprego.
- **Relevância:** calibra expectativas de magnitude; base de comparação internacional.

### Nekoei & Weber (2017) — SD melhora a qualidade do emprego?
- **Contribuição:** testa se estender o SD eleva salários de reemprego.
- **Método:** RD na duração potencial (Áustria).
- **Achado:** SD eleva salários de reemprego (melhor firma-match), sobretudo para grupos restritos.
- **Relevância:** desfecho "qualidade do reemprego" para o desenho de microdados.

### Amorim, Sousa & Silva (2024, IPEA TD 3059) — Acesso repetido no Brasil
- **Contribuição:** perfila padrões de acesso repetido ao SD (mesmo PIS), 2007–2012 vs. 2014–2019.
- **Método:** tabulação descritiva sobre a Base de Gestão do SD (BGSD).
- **Achado:** reincidência não é alta vs. literatura internacional; recorrência concentrada em grupos com vínculos instáveis; reforma de 2015 reduziu beneficiários.
- **Relevância:** artigo-âncora do projeto; documenta a BGSD e a quebra de 2015. **É descritivo — não causal**: a lacuna que preenchemos.

### Card, Chetty & Weber (2007) — Cash-on-hand e busca
- **Contribuição:** testa modelos de comportamento intertemporal na transição do desemprego.
- **Método:** RD em severance/SD na Áustria.
- **Achado:** liquidez (cash-on-hand) afeta a duração da busca — evidência-chave do canal liquidez.
- **Relevância:** fundamenta o mecanismo de liquidez no contexto de rescisão (paralelo ao FGTS).

### Baily (1978) — SD ótimo (teoria)
- **Contribuição:** fórmula seminal do benefício ótimo (trade-off consumo-suavização vs. busca).
- **Relevância:** base teórica de toda a literatura de "sufficient statistics" (Chetty).

### Meyer (1990) / Katz & Meyer (1990) — Duração e exaustão
- **Contribuição:** efeito da duração potencial sobre a duração do desemprego; *spikes* de saída na exaustão do benefício.
- **Método:** dados de spells nos EUA; hazards.
- **Relevância:** desfecho "hazard de reemprego" e padrão de exaustão — replicáveis com dados brasileiros.

### Lalive (2008) — RD na duração do SD
- **Contribuição:** efeito da extensão do SD sobre a duração via RD (idade/região, Áustria).
- **Relevância:** template de RD para regras de SD.

### Brodersen et al. (2015) — CausalImpact / BSTS
- **Contribuição:** infere impacto causal via modelo estrutural bayesiano de séries temporais com contrafactual.
- **Relevância:** um dos dois métodos agregados do artigo.

### Box & Tiao (1975) — Análise de intervenção
- **Contribuição:** modelo ARIMA com função de transferência para intervenções datadas.
- **Relevância:** base do método ARIMA de intervenção (ITS) usado no artigo.

---

## Organização temática

### Contribuições teóricas
O núcleo é o trade-off **seguro vs. incentivo** (Baily, 1978), reformulado por Chetty (2008) na decomposição **liquidez vs. moral hazard** — a chave para interpretar sinais e magnitudes. Em economias duais, a teoria é estendida pela **margem informal** (Gerard & Gonzaga, 2021): parte da "resposta comportamental" ao SD não é lazer/busca, mas transição para o setor informal, o que altera o cálculo de bem-estar.

### Achados empíricos (comparação)
- **Duração/incentivo:** efeitos de nível/duração pequenos a modestos (Schmieder & von Wachter, 2016); *spikes* na exaustão (Katz & Meyer, 1990; Meyer, 1990).
- **Qualidade do reemprego:** de nula (Schmieder & von Wachter, 2016) a positiva (Nekoei & Weber, 2017) — contexto-dependente.
- **Liquidez:** central e desejável (Chetty, 2008; Card, Chetty & Weber, 2007).
- **Brasil:** informalidade domina a resposta (Gerard & Gonzaga, 2021; Britto, 2022); efeitos sociais fora do mercado de trabalho — crime (Britto, Pinotti & Sampaio, 2022).

### Inovações metodológicas relevantes ao artigo
- **ITS/ARIMA de intervenção** (Box & Tiao, 1975; tutorial ITS: Bernal et al., 2017; implementação: Hyndman & Khandakar, 2008).
- **CausalImpact/BSTS** (Brodersen et al., 2015) — contrafactual bayesiano com controles.
- **RD** (Lee & Lemieux, 2010; inferência robusta: Calonico, Cattaneo & Titiunik, 2014).
- **DiD moderno** (Callaway & Sant'Anna, 2021) para timing/heterogeneidade.

---

## Lacunas e oportunidades

1. **Avaliação causal dedicada da Lei 13.134/2015 é escassa.** Amorim et al. (2024) é descritivo; não há (na literatura mapeada) estimativa causal limpa do efeito da reforma sobre acesso, duração do desemprego e reemprego. **Esta é a contribuição central.**
2. **Confundidor macro (recessão 2015–16).** A reforma coincide com a maior recessão recente — o que a análise agregada do projeto mostrou fragilizar toda especificação de série temporal. A literatura brasileira (Britto et al., 2022) já resolve isso com **RD na elegibilidade**, imune ao ciclo agregado.
3. **Desfechos de bem-estar, não só contagem.** A fronteira (Nekoei & Weber, 2017; Britto, 2022) mede reemprego, salário e informalidade — o artigo pode ir além do nº de requerentes.
4. **Margem informal na reforma.** Combinar a descontinuidade de elegibilidade de 2015 com a lente de informalidade (Gerard & Gonzaga, 2021) é uma contribuição original — como o *aperto* de acesso empurra trabalhadores marginais para a informalidade?

## Próximos passos sugeridos

- **Ler integralmente** Britto, Pinotti & Sampaio (2022) e Britto (2022) — desenho RD/dados idênticos ao necessário.
- **Posicionar** o artigo como avaliação causal da reforma via **RD/DiD na descontinuidade 6→12 meses** (ver `DESENHO_DiD_RD.md`), citando Gerard & Gonzaga (2021) para a margem informal.
- **Enquadrar** os resultados agregados (ARIMA/CausalImpact) como motivação/robustez, explicitando o confundidor da recessão (Schmieder & von Wachter, 2016, sobre efeitos em recessão).
- **Buscar** trabalhos recentes 2023–2026 sobre a reforma (dissertações, TDs IPEA/BID) e o paper de "welfare effects of unemployment benefits when informality is high" (JPubEc, 2023) para atualização.

---

## BibTeX

```bibtex
@article{baily1978optimal,
  author  = {Baily, Martin Neil},
  title   = {Some Aspects of Optimal Unemployment Insurance},
  journal = {Journal of Public Economics},
  year    = {1978}, volume = {10}, number = {3}, pages = {379--402}
}

@article{boxtiao1975intervention,
  author  = {Box, George E. P. and Tiao, George C.},
  title   = {Intervention Analysis with Applications to Economic and Environmental Problems},
  journal = {Journal of the American Statistical Association},
  year    = {1975}, volume = {70}, number = {349}, pages = {70--79},
  doi     = {10.1080/01621459.1975.10480264}
}

@article{brodersen2015causalimpact,
  author  = {Brodersen, Kay H. and Gallusser, Fabian and Koehler, Jim and Remy, Nicolas and Scott, Steven L.},
  title   = {Inferring Causal Impact Using {Bayesian} Structural Time-Series Models},
  journal = {The Annals of Applied Statistics},
  year    = {2015}, volume = {9}, number = {1}, pages = {247--274},
  doi     = {10.1214/14-AOAS788}
}

@article{britto2022employment,
  author  = {Britto, Diogo G. C.},
  title   = {The Employment Effects of Lump-Sum and Contingent Job Insurance Policies: Evidence from {Brazil}},
  journal = {The Review of Economics and Statistics},
  year    = {2022}, volume = {104}, number = {3}, pages = {465--482}
}

@article{brittopinottisampaio2022crime,
  author  = {Britto, Diogo G. C. and Pinotti, Paolo and Sampaio, Breno},
  title   = {The Effect of Job Loss and Unemployment Insurance on Crime in {Brazil}},
  journal = {Econometrica},
  year    = {2022}, volume = {90}, number = {4}, pages = {1393--1423},
  doi     = {10.3982/ECTA18984}
}

@article{calonico2014robust,
  author  = {Calonico, Sebastian and Cattaneo, Matias D. and Titiunik, Roc\'{i}o},
  title   = {Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs},
  journal = {Econometrica},
  year    = {2014}, volume = {82}, number = {6}, pages = {2295--2326},
  doi     = {10.3982/ECTA11757}
}

@article{callawaysantanna2021did,
  author  = {Callaway, Brantly and Sant'Anna, Pedro H. C.},
  title   = {Difference-in-Differences with Multiple Time Periods},
  journal = {Journal of Econometrics},
  year    = {2021}, volume = {225}, number = {2}, pages = {200--230}
}

@article{cardchettyweber2007cash,
  author  = {Card, David and Chetty, Raj and Weber, Andrea},
  title   = {Cash-on-Hand and Competing Models of Intertemporal Behavior: New Evidence from the Labor Market},
  journal = {The Quarterly Journal of Economics},
  year    = {2007}, volume = {122}, number = {4}, pages = {1511--1560},
  doi     = {10.1162/qjec.2007.122.4.1511}
}

@article{chetty2008moral,
  author  = {Chetty, Raj},
  title   = {Moral Hazard versus Liquidity and Optimal Unemployment Insurance},
  journal = {Journal of Political Economy},
  year    = {2008}, volume = {116}, number = {2}, pages = {173--234}
}

@article{gerardgonzaga2021informal,
  author  = {Gerard, Fran\c{c}ois and Gonzaga, Gustavo},
  title   = {Informal Labor and the Efficiency Cost of Social Programs: Evidence from Unemployment Insurance in {Brazil}},
  journal = {American Economic Journal: Economic Policy},
  year    = {2021}, volume = {13}, number = {3}, pages = {167--206},
  doi     = {10.1257/pol.20180072}
}

@article{hyndmankhandakar2008forecast,
  author  = {Hyndman, Rob J. and Khandakar, Yeasmin},
  title   = {Automatic Time Series Forecasting: The forecast Package for {R}},
  journal = {Journal of Statistical Software},
  year    = {2008}, volume = {27}, number = {3}, pages = {1--22},
  doi     = {10.18637/jss.v027.i03}
}

@article{katzmeyer1990impact,
  author  = {Katz, Lawrence F. and Meyer, Bruce D.},
  title   = {The Impact of the Potential Duration of Unemployment Benefits on the Duration of Unemployment},
  journal = {Journal of Public Economics},
  year    = {1990}, volume = {41}, number = {1}, pages = {45--72}
}

@article{lalive2008how,
  author  = {Lalive, Rafael},
  title   = {How Do Extended Benefits Affect Unemployment Duration? A Regression Discontinuity Approach},
  journal = {Journal of Econometrics},
  year    = {2008}, volume = {142}, number = {2}, pages = {785--806}
}

@article{leelemieux2010rdd,
  author  = {Lee, David S. and Lemieux, Thomas},
  title   = {Regression Discontinuity Designs in Economics},
  journal = {Journal of Economic Literature},
  year    = {2010}, volume = {48}, number = {2}, pages = {281--355},
  doi     = {10.1257/jel.48.2.281}
}

@article{meyer1990unemployment,
  author  = {Meyer, Bruce D.},
  title   = {Unemployment Insurance and Unemployment Spells},
  journal = {Econometrica},
  year    = {1990}, volume = {58}, number = {4}, pages = {757--782}
}

@article{nekoeiweber2017does,
  author  = {Nekoei, Arash and Weber, Andrea},
  title   = {Does Extending Unemployment Benefits Improve Job Quality?},
  journal = {American Economic Review},
  year    = {2017}, volume = {107}, number = {2}, pages = {527--561},
  doi     = {10.1257/aer.20150528}
}

@article{schmiedervonwachter2016effects,
  author  = {Schmieder, Johannes F. and von Wachter, Till},
  title   = {The Effects of Unemployment Insurance Benefits: New Evidence and Interpretation},
  journal = {Annual Review of Economics},
  year    = {2016}, volume = {8}, pages = {547--581}
}

@techreport{amorim2024perfil,
  author      = {Amorim, Brunu and Sousa, Vict\'{o}ria Evellyn Costa Moraes and Silva, Sandro Pereira},
  title       = {Perfil e Padr\~{o}es de Acesso Repetido ao Seguro-Desemprego no {Brasil}},
  institution = {Instituto de Pesquisa Econ\^{o}mica Aplicada (IPEA)},
  type        = {Texto para Discuss\~{a}o}, number = {3059},
  year        = {2024}, address = {Bras\'{i}lia}
}

@article{bernal2017interrupted,
  author  = {Bernal, James Lopez and Cummins, Steven and Gasparrini, Antonio},
  title   = {Interrupted Time Series Regression for the Evaluation of Public Health Interventions: A Tutorial},
  journal = {International Journal of Epidemiology},
  year    = {2017}, volume = {46}, number = {1}, pages = {348--355}
}

@misc{lei13134_2015,
  author = {{Brasil}},
  title  = {Lei n\textsuperscript{o} 13.134, de 16 de junho de 2015},
  year   = {2015},
  note   = {Altera a Lei n. 7.998/1990 (Programa do Seguro-Desemprego e Abono Salarial). Convers\~{a}o da MP 665/2014}
}
```

> **A adicionar após confirmação** (mencionadas no texto, ainda não incluídas no BibTeX): referências brasileiras clássicas de reincidência (Balbinotto Neto & Zylberstajn, 2002, citado no TD 3059) e de rotatividade (Gonzaga, 2003); e o artigo de "welfare effects of unemployment benefits when informality is high" (JPubEc, 2023).

---

## Post-Flight Verification (CoVe) ✅

**Método:** cada citação foi verificada por busca independente (título + veículo + volume/páginas/DOI), sem passar o rascunho a um verificador — a checagem confirmou os metadados na fonte.

| Citação | Status | Fonte |
|---|---|---|
| Gerard & Gonzaga (2021), AEJ:EP 13(3):167–206 | ✅ confirmado | aeaweb / NBER w22608 |
| Britto, Pinotti & Sampaio (2022), Econometrica 90(4):1393–1423 | ✅ confirmado | Econometrica / DOI 10.3982/ECTA18984 |
| Britto (2022), REStat 104(3):465–482 | ✅ confirmado | RePEc tpr/restat |
| Chetty (2008), JPE 116(2):173–234 | ✅ confirmado | RePEc / NBER w13967 |
| Schmieder & von Wachter (2016), Ann. Rev. Econ. 8:547–581 | ✅ confirmado | annualreviews |
| Nekoei & Weber (2017), AER 107(2):527–561 | ✅ confirmado | aeaweb / DOI 10.1257/aer.20150528 |
| Brodersen et al. (2015), Ann. Appl. Stat. 9(1):247–274 | ✅ confirmado | projecteuclid / DOI 10.1214/14-AOAS788 |
| Baily (1978), JPubEc 10(3):379–402 | ✅ confirmado | EconPapers |
| Box & Tiao (1975), JASA 70(349):70–79 | ✅ confirmado | SciRP / DOI 10.1080/01621459.1975.10480264 |
| Card, Chetty & Weber (2007), QJE 122(4):1511–1560 | ✅ confirmado | EconPapers |
| Meyer (1990), Econometrica 58(4):757–782 | ✅ confirmado | EconPapers |
| Katz & Meyer (1990), JPubEc 41(1):45–72 | ✅ confirmado | EconPapers |
| Lalive (2008), J. Econometrics 142(2):785–806 | ✅ confirmado | EconPapers |
| Lee & Lemieux (2010), JEL 48(2):281–355 | ✅ confirmado | RePEc / DOI 10.1257/jel.48.2.281 |
| Calonico, Cattaneo & Titiunik (2014), Econometrica 82(6):2295–2326 | ✅ confirmado | Wiley / DOI 10.3982/ECTA11757 |
| Callaway & Sant'Anna (2021), J. Econometrics 225(2):200–230 | ✅ confirmado | RePEc eee/econom |
| Hyndman & Khandakar (2008), JSS 27(3):1–22 | ✅ confirmado | RePEc / DOI 10.18637/jss.v027.i03 |
| Amorim, Sousa & Silva (2024), IPEA TD 3059 | ✅ confirmado | lido diretamente (PDF IPEA) |
| Lei 13.134/2015 (MP 665/2014; 1ª: 6→12 meses) | ✅ confirmado | Câmara/DOU + busca |
| Bernal, Cummins & Gasparrini (2017), IJE 46(1):348–355 | ⚠️ alta confiança, não reverificado nesta sessão | — |

**Veredito:** PASS. 19 de 20 citações verificadas na fonte; 1 (`bernal2017`) marcada como alta-confiança a reconferir. Nenhuma citação fabricada detectada.
