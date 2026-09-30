# =============================================================================
# 01c_import_desligamentos_sjc.py — Denominador CORRETO: desligamentos por
# DISPENSA SEM JUSTA CAUSA (CAGED, código de movimentação 31), mensal nacional.
#
# POR QUÊ: o passo 07 usa hoje o TOTAL de desligamentos como denominador da taxa
# de habilitação. Isso é confundido pela composição cíclica das separações (na
# recessão sobe a fração involuntária). O denominador correto é só a categoria
# que ACIONA o seguro-desemprego: dispensa sem justa causa (código 31).
#
# CONFIRMADO no layout do CAGED antigo (Registro C, TIPO DE MOVIMENTO):
#   DESLIGAMENTO -> 31 Dispensa sem justa causa | 32 c/ justa causa | 40 a pedido
#                   43/45 término | 50 aposentado | 60 morte | 80 transf. | 90 acordo
# Logo o dado EXISTE para 2000-2019; o que falta é ACESSO aos microdados.
#
# ------------------------------------------------------------------------------
# PRÉ-REQUISITO (passo manual, só você pode fazer — precisa de conta GCP):
#   1) pip install basedosdados
#   2) autenticar: `gcloud auth application-default login`  (via `! gcloud ...`)
#   3) definir um projeto de faturamento GCP (a consulta é grátis nos dados,
#      mas o BigQuery cobra o processamento na SUA conta): billing_project_id
# Alternativa sem GCP: baixar microdados do PDET (ftp/https) e filtrar código 31.
# ------------------------------------------------------------------------------
#
# Saída: outputs/desligamentos_sjc.csv  (data, desligamentos_sjc)  [nacional/BR]
# =============================================================================

import os, sys

OUT = os.path.join("Artigos", "Seguro_Desemprego_ARIMA", "outputs",
                   "desligamentos_sjc.csv")
BILLING = os.environ.get("GCP_BILLING_PROJECT")  # export antes de rodar

# NB: confirme nomes de tabela/coluna no dicionário da Base dos Dados
#     (https://basedosdados.org/dataset/br-me-caged). O CAGED antigo costuma
#     expor 'tipo_movimentacao' com os códigos 10..90 e 'saldo_movimentacao'.
QUERY = """
SELECT ano, mes, SUM(1) AS desligamentos_sjc
FROM `basedosdados.br_me_caged.microdados_antigos`
WHERE tipo_movimentacao = 31          -- dispensa sem justa causa
  AND ano BETWEEN 2000 AND 2019
GROUP BY ano, mes
ORDER BY ano, mes
"""

def main():
    try:
        import basedosdados as bd
    except ImportError:
        sys.stderr.write(
            "\n[01c] basedosdados não instalado. Rode:  pip install basedosdados\n"
            "      e depois `gcloud auth application-default login`.\n"
            "      (passo 07 seguirá com o denominador TOTAL como fallback.)\n")
        return 0
    if not BILLING:
        sys.stderr.write(
            "\n[01c] Defina GCP_BILLING_PROJECT (projeto de faturamento GCP) e\n"
            "      autentique com gcloud antes de rodar. Fallback ativo no 07.\n")
        return 0

    df = bd.read_sql(QUERY, billing_project_id=BILLING)
    df["data"] = (df["ano"].astype(int).astype(str) + "-"
                  + df["mes"].astype(int).astype(str).str.zfill(2) + "-01")
    df = df[["data", "desligamentos_sjc"]].sort_values("data")
    df.to_csv(OUT, index=False)
    print(f"[01c] OK — {len(df)} meses gravados em {OUT}")
    print(df.tail(3).to_string(index=False))
    return 0

if __name__ == "__main__":
    sys.exit(main())
