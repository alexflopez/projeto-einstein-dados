import pandas as pd
import os
from sqlalchemy import create_engine


PATH = (r'D:\Documentos\projeto-einstein-dados\projeto-einstein-dados\files\dados por uf')


def reading_files(path):
    """
    Função responsável pela leitura dos arquivos no formato '.csv'
    """
    lista_dfs = []
    for file in os.listdir(path):
        # Considerando a leitura somente do(s) arquivo(s) .csv do diretório
        if file.lower().endswith('.csv'):
            # print(file)
            caminho_completo = os.path.join(path, file)
            try:
                print(f'Lendo arquivo: {file}')
                df = pd.read_csv(
                    caminho_completo, 
                    sep=";", # Separador nativo do arquivo
                    quotechar='"', # quotechar entre valores, necessário declarar para o pandas reconhecer as colunas
                    encoding='utf-8', # encoding solicitado
                    low_memory=False
                )
                print(f'Total de linhas carregadas: {len(df)}\n')
                lista_dfs.append(df) # Guardando na lista (assumindo a mesma estrutura de colunas)

            except Exception as e:
                print(f'Erro {e} ao ler o arquivo {file}. Por favor, revisar o separador ou encoding.')
            
            # print(df.head(2)) 

    if lista_dfs:
        dfs_consolidados = pd.concat(lista_dfs, ignore_index=True)
        print(f'Todos arquivos foram consolidados com sucesso. Total geral:{len(dfs_consolidados)} linhas')
        return dfs_consolidados
    else:
        print('Nenhum arquivo foi lido.')
        return None


def load_data(df):
    """Função responsável por receber o DataFrame consolidado e subir para o SQL Server."""
    if df is None or df.empty:
        print("Dataframe vazio, nenhuma operação de carga será executada.")
        return

    # Forçando todos os dados para STRING
    df = df.astype(object).where(df.notnull(), None)
    for col in df.columns:
        df[col] = df[col].apply(lambda x: str(x) if x is not None else None)

    # String de conexão (localhost)
    DATABASE_URL = "mssql+pyodbc://@localhost\\SQLEXPRESS/opendatasus?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"

    try:
        print("Conectando ao SQL Server e iniciando a carga na camada Bronze...")
        engine = create_engine(DATABASE_URL)
        
        df.to_sql(
            name='bronze_sindrome_gripal',
            con=engine,
            if_exists='replace',
            index=False,
            chunksize=50000 
        )
        print("Carga finalizada com sucesso! Todos os dados crus foram persistidos na Bronze.")
        
    except Exception as e:
        print(f"Erro ao conectar ou carregar os dados no SQL Server: {e}")


if __name__ == "__main__":
    df = reading_files(PATH)
    # print(df)
    load_data(df)
