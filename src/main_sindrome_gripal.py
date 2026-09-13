import pandas as pd
import os
from sqlalchemy import create_engine, text


# Caminho da pasta
PATH = r'D:\Documentos\projeto-einstein-dados\projeto-einstein-dados\data\dados por uf'

# String de conexão (localhost)
DATABASE_URL = "mssql+pyodbc://@localhost\\SQLEXPRESS/opendatasus?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"


def get_processed_files(engine):
    """Retorna uma lista de arquivos já gravados na base de controle."""
    try:
        query = "SELECT fileName FROM control_processed_files"
        df_control = pd.read_sql(query, con=engine)
        return df_control['fileName'].tolist()
    except Exception:
        # Se a tabela ainda não existir no banco, retorna uma lista vazia
        return []


def reading_files(path, processed_files):
    """
    Função responsável pela leitura apenas dos novos arquivos no formato '.csv'
    """
    lista_dfs = []
    arquivos_novos = []

    if not os.path.exists(path):
        print(f"Erro: O diretório {path} não existe.")
        return None, []

    for file in os.listdir(path):
        # Considerando a leitura somente do(s) arquivo(s) .csv do diretório
        if file.lower().endswith('.csv'):
            
            # Validação para pular arquivos que já foram processados anteriormente
            if file in processed_files:
                print(f"Arquivo já processado anteriormente (ignorado): {file}")
                continue

            caminho_completo = os.path.join(path, file)
            try:
                print(f'Lendo NOVO arquivo: {file}')
                df = pd.read_csv(
                    caminho_completo, 
                    sep=";", # Separador nativo do arquivo
                    quotechar='"', # quotechar entre valores
                    encoding='utf-8', # encoding solicitado
                    low_memory=False
                )
                print(f'Total de linhas carregadas: {len(df)}\n')
                lista_dfs.append(df) # Guardando na lista
                arquivos_novos.append(file) # Guardando o nome do arquivo novo

            except Exception as e:
                print(f'Erro {e} ao ler o arquivo {file}. Por favor, revisar o separador ou encoding.')
            
    if lista_dfs:
        dfs_consolidados = pd.concat(lista_dfs, ignore_index=True)
        print(f'Arquivos novos consolidados com sucesso. Total geral:{len(dfs_consolidados)} linhas')
        return dfs_consolidados, arquivos_novos
    else:
        print('Nenhum arquivo novo encontrado.')
        return None, []


def load_data(df, arquivos_novos):
    """Função responsável por receber o DataFrame consolidado, subir via append e registrar os logs."""
    if df is None or df.empty or not arquivos_novos:
        print("Nenhum dado novo para carregar. Processo finalizado.")
        return

    # Forçando todos os dados para STRING
    df = df.astype(object).where(df.notnull(), None)
    for col in df.columns:
        df[col] = df[col].apply(lambda x: str(x) if x is not None else None)

    try:
        print("Conectando ao SQL Server e iniciando a carga incremental na camada Bronze...")
        engine = create_engine(DATABASE_URL)
        
        # Verifica se a tabela bronze já existe para decidir entre append ou replace na primeira vez
        query_check_bronze = "SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'bronze_sindrome_gripal'"
        with engine.connect() as conn:
            bronze_exists = conn.execute(text(query_check_bronze)).fetchone()

        modo_carga = 'append' if bronze_exists else 'replace'

        # 1. Envia os dados novos para a tabela Bronze
        df.to_sql(
            name='bronze_sindrome_gripal',
            con=engine,
            if_exists=modo_carga,
            index=False,
            chunksize=50000 
        )
        print("Dados novos persistidos na Bronze com sucesso.")

        # 2. Cria a tabela de controle (se não existir) e registra os arquivos novos processados
        with engine.begin() as conn:
            conn.execute(text("""
                IF NOT OBJECT_ID('dbo.control_processed_files', 'U') IS NOT NULL
                CREATE TABLE control_processed_files (
                    fileName VARCHAR(255) PRIMARY KEY,
                    processedAt DATETIME DEFAULT GETDATE()
                )
            """))

            for arq in arquivos_novos:
                conn.execute(
                    text("INSERT INTO control_processed_files (fileName) VALUES (:file)"),
                    {"file": arq}
                )

        print(f"Log atualizado! {len(arquivos_novos)} novo(s) arquivo(s) registrado(s) na tabela de controle.")
        
    except Exception as e:
        print(f"Erro ao conectar ou carregar os dados no SQL Server: {e}")


if __name__ == "__main__":
    # Cria uma engine temporária apenas para consultar o histórico antes de ler a pasta
    engine_temp = create_engine(DATABASE_URL)
    arquivos_ja_processados = get_processed_files(engine_temp)
    
    # Lê apenas o que ainda não foi processado
    df_novo, novos_arquivos = reading_files(PATH, arquivos_ja_processados)
    
    # Realiza a carga incremental e registra os arquivos novos
    load_data(df_novo, novos_arquivos)
    