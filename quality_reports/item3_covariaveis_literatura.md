# Item 3 — Escolha de covariáveis para o matching (fundamentação na literatura)

**Data:** 2026-10-25 · **Contexto:** seleção de controles de fora do RS por PSM/Mahalanobis para o SDiD das enchentes.

## Pergunta
Quais covariáveis usar para parear municípios não-RS aos 6 tratados (critério populacional) antes do SDiD?

## O que a literatura diz

### Preditores em controle sintético / matching
- **Abadie (2021, *JEL* 59(2):391–425)** — "Using Synthetic Controls". A trajetória pré-tratamento do desfecho é o preditor central; covariáveis devem ter poder preditivo sobre o desfecho; evitar cherry-picking de preditores.
- **Kaul, Klößner, Pfeifer & Schieler (2022, *JBES* 40(3))** — usar *todos* os lags do desfecho como preditores torna as demais covariáveis irrelevantes; portanto usar **alguns resumos do pré** + covariáveis estruturais, não muitas.
- **Abadie & L'Hour (2021, *JASA*)** — SC penalizado favorece doadores com valores de covariáveis **próximos** ao tratado → fundamenta o matching por distância (Mahalanobis).
- **Lição:** parcimônia; priorizar covariáveis preditivas do emprego; o resumo do pré do desfecho é o mais importante.

### Desastres e mercado de trabalho local (quais características municipais importam)
- **Composição setorial** (agro/indústria/construção/serviços): realocação setorial é central (estudo de realocação pós-terremoto; no Brasil enchentes afetam agro e serviços — Nordeste/UEA). Itens 1b e 5 deste projeto confirmam o canal industrial.
- **Tamanho (população), PIB/renda per capita**: controles padrão (FRBSF 2020; Xiao 2011 *JRS*; Kirchberger/IZA).
- **Desenvolvimento humano (IDH)**: capacidade de recuperação/resiliência.
- **Densidade/urbanização**: exposição e estrutura do mercado de trabalho.
- **Firm entry / flood risk** (NBER w30250): estrutura econômica prediz resposta do emprego.
- **Crédito**: aparece como *canal de recuperação*, não como covariável de matching padrão; nível municipal nacional é problemático (cobertura/qualidade). Anti-parcimônia.

## Decisão (conjunto de matching)

**Principal (entra na distância de Mahalanobis):**
1. Resumo do pré de admissões/mil (média pré + inclinação da tendência) — *preditor nº 1 (Abadie)*
2. Shares setoriais (agro / indústria / serviços)
3. População (log)
4. PIB per capita
5. IDHM (análogo nacional do Idese, que só existe no RS)
6. Densidade demográfica (pop / área)

**Robustez apenas (fora do matching principal):** crédito — reportar como checagem, não como variável de pareamento.

## Fontes
- Abadie (2021): <https://conference.nber.org/confer/2021/SI2021/Abadie_2021.pdf>
- Kaul et al. (2022): <https://www.tandfonline.com/doi/abs/10.1080/07350015.2021.1930012>
- Vives-i-Bastida, Predictor Selection for SC: <https://arxiv.org/pdf/2203.11576>
- FRBSF (2020) Local Economic Impact of Natural Disasters: <https://www.frbsf.org/wp-content/uploads/wp2020-34.pdf>
- Kirchberger (IZA): <https://conference.iza.org/conference_files/worldb2011/kirchberger_m6807.pdf>
- NBER w30250 "Expecting Floods": <https://www.nber.org/system/files/working_papers/w30250/w30250.pdf>
- Natural Disasters and Economic Growth in Northeast Brazil (UEA): <https://ueaeprints.uea.ac.uk/id/eprint/83160/1/Accepted_manuscript.pdf>
