USE opendatasus;
GO

--------------------------------------------------------------------------------
-- 3.b.i: Consulta por UF permitindo o filtro em uma lista, 
-- ligando a tabela geral com a tabela específica de São Paulo
--------------------------------------------------------------------------------
SELECT 
    t1.estado,
    t1.municipio,
    COUNT(t1.sourceId) AS total_geral,
    COUNT(t2.sourceId) AS total_sp_correspondente
FROM dbo.prata_sindrome_gripal t1
LEFT JOIN dbo.tb_sindrome_gripal_sp t2 
    ON t1.sourceId = t2.sourceId
WHERE t1.estado IN ('São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Paraná')
GROUP BY t1.estado, t1.municipio
ORDER BY total_geral DESC;
GO


--------------------------------------------------------------------------------
-- 3.b.ii: Consulta por cidade cuja contagem seja acima de 10,
-- utilizando a dimensão de municípios e cruzando com as duas fontes de dados
--------------------------------------------------------------------------------
SELECT 
    m.nomeUf AS estado,
    m.nomeMunicipio AS municipio,
    m.codigoMunicipioCompleto AS ibge,
    COUNT(s1.sourceId) AS total_geral,
    COUNT(s2.sourceId) AS total_sp
FROM dbo.dim_municipios m 
LEFT JOIN dbo.prata_sindrome_gripal s1 
    ON s1.municipio = m.nomeMunicipio AND s1.estado = m.nomeUf
LEFT JOIN dbo.tb_sindrome_gripal_sp s2 
    ON s2.sourceId = s1.sourceId
GROUP BY m.nomeUf, m.nomeMunicipio, m.codigoMunicipioCompleto
HAVING COUNT(s1.sourceId) > 10
ORDER BY total_geral DESC;
GO


--------------------------------------------------------------------------------
-- 3.c.i: Criação da nova tabela contendo apenas os dados do estado de São Paulo
-- (Ajustado para puxar da tabela física correta: dbo.prata_sindrome_gripal)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.tb_sindrome_gripal_sp', 'U') IS NOT NULL
    DROP TABLE dbo.tb_sindrome_gripal_sp;
GO

SELECT *
INTO dbo.tb_sindrome_gripal_sp
FROM dbo.prata_sindrome_gripal
WHERE estado = 'São Paulo';
GO

-- Validação rápida para conferir a nova tabela de SP
SELECT TOP 10 estado, municipio, COUNT(*) AS total
FROM dbo.tb_sindrome_gripal_sp
GROUP BY estado, municipio;
GO


--------------------------------------------------------------------------------
-- Diagnóstico: Visualizar valores de estado IBGE e notificação
--------------------------------------------------------------------------------
SELECT DISTINCT
    estadoIBGE,
	estadoNotificacaoIBGE 
FROM dbo.prata_sindrome_gripal;
GO


--------------------------------------------------------------------------------
-- 3.c.ii: Implementa um comando que modifique a UF que está indefinida, vazia ou nula para 'ND'
--------------------------------------------------------------------------------
UPDATE dbo.prata_sindrome_gripal
SET estado = 'ND'
WHERE estado IS NULL 
   OR LTRIM(RTRIM(estado)) = '' 
   OR UPPER(LTRIM(RTRIM(estado))) IN ('NULL', 'UNDEFINED', 'INDEFINIDO', 'NÃO DEFINIDO', 'NAO DEFINIDO');
GO


--------------------------------------------------------------------------------
-- 3.c.iii: Implementa um comando que apague 10 registros da UF 'ND'
-- (Utilizamos TOP (10) no SQL Server para garantir que apague exatamente 10 linhas com segurança)
--------------------------------------------------------------------------------
DELETE TOP (10) 
FROM dbo.prata_sindrome_gripal
WHERE estado = 'ND';
GO