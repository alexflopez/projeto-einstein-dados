/*
================================================================================
SCRIPT COMPLETO - CONSTRUÇÃO DA CAMADA OURO (GOLD)
Banco: opendatasus
Schema: dbo (com prefixo gold_ nas tabelas para governança)
================================================================================
Este script consolida todas as dimensões e a tabela fato final enriquecidas
a partir da camada Prata, aplicando as regras de governança (como a filtragem
de registros excluídos).
================================================================================ */

/*
--------------------------------------------------------------------------------
1. CRIAÇÃO DA TABELA DIMENSÃO MUNICÍPIOS (dbo.gold_dim_municipios)
--------------------------------------------------------------------------------
*/

IF OBJECT_ID('dbo.gold_dim_municipios', 'U') IS NOT NULL
    DROP TABLE dbo.gold_dim_municipios;
GO

SELECT DISTINCT
    codigoMunicipioCompleto AS codigo_municipio_ibge,
    nomeMunicipio AS nome_municipio,
    uf AS sigla_uf,
    nomeUf AS nome_estado,
    regiaoGeograficaIntermediaria AS regiao_intermediaria
INTO dbo.gold_dim_municipios
FROM dbo.dim_municipios
WHERE codigoMunicipioCompleto IS NOT NULL;
GO

/*
--------------------------------------------------------------------------------
2. CRIAÇÃO DA TABELA DIMENSÃO CBO (dbo.gold_dim_cbo)
--------------------------------------------------------------------------------
*/

IF OBJECT_ID('dbo.gold_dim_cbo', 'U') IS NOT NULL
    DROP TABLE dbo.gold_dim_cbo;
GO

SELECT DISTINCT
    COALESCE(cbo, 'ND') AS codigo_cbo,
    CASE 
        WHEN cbo IS NULL OR cbo = 'ND' THEN 'Não Informado'
        ELSE 'Profissão Especificada' 
    END AS descricao_cbo
INTO dbo.gold_dim_cbo
FROM dbo.prata_sindrome_gripal;
GO

/*
--------------------------------------------------------------------------------
3. CRIAÇÃO DA TABELA DIMENSÃO VACINAÇÃO (dbo.gold_dim_vacina)
--------------------------------------------------------------------------------
*/
IF OBJECT_ID('dbo.gold_dim_vacina', 'U') IS NOT NULL
    DROP TABLE dbo.gold_dim_vacina;
GO

-- Trazendo apenas os valores distintos do código de vacina para garantir chave única real
SELECT DISTINCT
    COALESCE(codigoRecebeuVacina, 'ND') AS codigo_recebeu_vacina,
    CASE 
        WHEN codigoRecebeuVacina = '1' THEN 'Sim'
        WHEN codigoRecebeuVacina = '2' THEN 'Não'
        ELSE 'Não Informado'
    END AS descricao_vacina
INTO dbo.gold_dim_vacina
FROM dbo.prata_sindrome_gripal
WHERE codigoRecebeuVacina IS NOT NULL;
GO

/*
--------------------------------------------------------------------------------
4. CRIAÇÃO DA TABELA DIMENSÃO CRITÉRIO EPIDEMIOLÓGICO (dbo.gold_dim_criterio)
--------------------------------------------------------------------------------
*/
USE opendatasus;
GO

IF OBJECT_ID('dbo.gold_dim_criterio', 'U') IS NOT NULL
    DROP TABLE dbo.gold_dim_criterio;
GO

-- Criando uma dimensão com chave única e limpa baseada apenas no código de estratégia covid
SELECT DISTINCT
    COALESCE(codigoEstrategiaCovid, 'ND') AS codigo_estrategia_covid,
    CASE 
        WHEN codigoEstrategiaCovid = 'ND' OR codigoEstrategiaCovid IS NULL THEN 'Não Informado'
        ELSE 'Estratégia ' + codigoEstrategiaCovid
    END AS descricao_estrategia
INTO dbo.gold_dim_criterio
FROM dbo.prata_sindrome_gripal
WHERE codigoEstrategiaCovid IS NOT NULL;
GO


/*
--------------------------------------------------------------------------------
5. CRIAÇÃO DA TABELA FATO SÍNDROME GRIPAL (dbo.gold_fct_sindrome_gripal)
--------------------------------------------------------------------------------
*/
IF OBJECT_ID('dbo.gold_fct_sindrome_gripal', 'U') IS NOT NULL
    DROP TABLE dbo.gold_fct_sindrome_gripal;
GO

SELECT 
    sourceId AS id_notificacao,
    
    -- Chaves Estrangeiras para as Dimensões
    NULLIF(municipioIBGE, 'ND') AS codigo_municipio_ibge,
    COALESCE(cbo, 'ND') AS codigo_cbo,
    COALESCE(codigoRecebeuVacina, 'ND') AS codigo_recebeu_vacina,
    COALESCE(codigoEstrategiaCovid, 'ND') AS codigo_estrategia_covid,
    COALESCE(estado, 'ND') AS sigla_uf,
    
    -- Chave de Data para ligar com a Dimensão Calendário
    CAST(dataNotificacao AS DATE) AS id_data_notificacao,
    
    -- Atributos descritivos restantes
    sexo,
    idade,
    racaCor,
    profissionalSaude,
    profissionalSeguranca,
    evolucaoCaso,
    classificacaoFinal,
    totalTestesRealizados,
    
    -- Métricas / Indicadores
    1 AS total_notificacoes,
    CASE WHEN evolucaoCaso = 'Cura' THEN 1 ELSE 0 END AS qtd_cura,
    CASE WHEN classificacaoFinal LIKE '%Laboratorial%' THEN 1 ELSE 0 END AS qtd_confirmado_lab
INTO dbo.gold_fct_sindrome_gripal
FROM dbo.prata_sindrome_gripal
WHERE isExcluido = 0;
GO
