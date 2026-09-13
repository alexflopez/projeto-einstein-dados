import pandas as pd
import os
from sqlalchemy import create_engine

# Caminho exato para o arquivo de municípios na pasta files
PATH_MUNICIPIOS = r'D:\Documentos\projeto-einstein-dados\projeto-einstein-dados\files\RELATORIO_DTB_BRASIL_MUNICIPIO.CSV'

def to_camel_case(col_name):
    """Converte uma string para camelCase."""
    # Remove underscores extras e divide a string por partes
    parts = col_name.split('_')
    if not parts:
        return col_name
    # Primeira palavra minúscula, e as demais com a primeira letra maiúscula
    return parts[0].lower() + ''.join(p.capitalize() for p in parts[1:])

def process_and_load_municipios(caminho):
    """
    Função responsável por ler o arquivo de municípios do IBGE, 
    normalizar as colunas para camelCase e carregar no SQL Server.
    """
    try:
        print("Lendo o arquivo de municípios...")
        df = pd.read_csv(
            caminho,
            sep=';',
            encoding='cp1252', # Trata corretamente os caracteres acentuados em português
            low_memory=False
        )
        print(f"Total de municípios carregados: {len(df)}")

        # 1. Limpeza base (remove acentos, espaços e substitui caracteres especiais por underscore)
        temp_cols = (
            df.columns.str.strip()
            .str.lower()
            .str.normalize("NFKD")
            .str.encode("ascii", errors="ignore")
            .str.decode("utf-8")
            .str.replace(r"[^\w\s]", "_", regex=True)
            .str.replace(r"\s+", "_", regex=True)
        )

        # 2. Converte cada coluna para camelCase
        df.columns = [to_camel_case(col) for col in temp_cols]

        # Blindagem de dados: convertendo para string e preservando valores nulos corretamente
        df = df.astype(object).where(df.notnull(), None)
        for col in df.columns:
            df[col] = df[col].apply(lambda x: str(x) if x is not None else None)

        # String de conexão com o banco opendatasus
        DATABASE_URL = "mssql+pyodbc://@localhost\\SQLEXPRESS/opendatasus?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
        
        print("Conectando ao SQL Server e criando a tabela dim_municipios...")
        engine = create_engine(DATABASE_URL)
        
        df.to_sql(
            name='dim_municipios',
            con=engine,
            if_exists='replace',
            index=False,
            chunksize=50000
        )
        print("Tabela dim_municipios carregada com sucesso no padrão camelCase!")

    except Exception as e:
        print(f"Erro ao processar a tabela de municípios: {e}")

if __name__ == "__main__":
    process_and_load_municipios(PATH_MUNICIPIOS)