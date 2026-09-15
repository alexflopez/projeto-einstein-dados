/*
================================================================================
SCRIPT DE CARGA INCREMENTAL (UPSERT / MERGE) - CAMADA OURO (GOLD)
Banco: opendatasus
Schema: dbo
================================================================================
*/

-- --------------------------------------------------------------------------------
-- 1. UPSERT DIMENSÃO MUNICÍPIOS
-- --------------------------------------------------------------------------------
MERGE dbo.gold_dim_municipios AS target
USING (
    SELECT DISTINCT
        codigoMunicipioCompleto AS codigo_municipio_ibge,
        nomeMunicipio AS nome_municipio,
        uf AS sigla_uf,
        nomeUf AS nome_estado,
        regiaoGeograficaIntermediaria AS regiao_intermediaria
    FROM dbo.dim_municipios
    WHERE codigoMunicipioCompleto IS NOT NULL
) AS source
ON target.codigo_municipio_ibge = source.codigo_municipio_ibge
WHEN MATCHED THEN
    UPDATE SET 
        target.nome_municipio = source.nome_municipio,
        target.sigla_uf = source.sigla_uf,
        target.nome_estado = source.nome_estado,
        target.regiao_intermediaria = source.regiao_intermediaria
WHEN NOT MATCHED BY TARGET THEN
    INSERT (codigo_municipio_ibge, nome_municipio, sigla_uf, nome_estado, regiao_intermediaria)
    VALUES (source.codigo_municipio_ibge, source.nome_municipio, source.sigla_uf, source.nome_estado, source.regiao_intermediaria);
GO


-- --------------------------------------------------------------------------------
-- 2. UPSERT DIMENSÃO CBO
-- --------------------------------------------------------------------------------
MERGE dbo.gold_dim_cbo AS target
USING (
    SELECT DISTINCT
        COALESCE(cbo, 'ND') AS codigo_cbo,
        CASE 
            WHEN cbo IS NULL OR cbo = 'ND' THEN 'Não Informado'
            ELSE 'Profissão Especificada' 
        END AS descricao_cbo
    FROM dbo.prata_sindrome_gripal
) AS source
ON target.codigo_cbo = source.codigo_cbo
WHEN MATCHED THEN
    UPDATE SET 
        target.descricao_cbo = source.descricao_cbo
WHEN NOT MATCHED BY TARGET THEN
    INSERT (codigo_cbo, descricao_cbo)
    VALUES (source.codigo_cbo, source.descricao_cbo);
GO


-- --------------------------------------------------------------------------------
-- 3. UPSERT DIMENSÃO VACINAÇÃO
-- --------------------------------------------------------------------------------
MERGE dbo.gold_dim_vacina AS target
USING (
    SELECT DISTINCT
        COALESCE(codigoRecebeuVacina, 'ND') AS codigo_recebeu_vacina,
        CASE 
            WHEN codigoRecebeuVacina = '1' THEN 'Sim'
            WHEN codigoRecebeuVacina = '2' THEN 'Não'
            ELSE 'Não Informado'
        END AS descricao_vacina
    FROM dbo.prata_sindrome_gripal
    WHERE codigoRecebeuVacina IS NOT NULL
) AS source
ON target.codigo_recebeu_vacina = source.codigo_recebeu_vacina
WHEN MATCHED THEN
    UPDATE SET 
        target.descricao_vacina = source.descricao_vacina
WHEN NOT MATCHED BY TARGET THEN
    INSERT (codigo_recebeu_vacina, descricao_vacina)
    VALUES (source.codigo_recebeu_vacina, source.descricao_vacina);
GO


-- --------------------------------------------------------------------------------
-- 4. UPSERT DIMENSÃO CRITÉRIO EPIDEMIOLÓGICO
-- --------------------------------------------------------------------------------
MERGE dbo.gold_dim_criterio AS target
USING (
    SELECT DISTINCT
        COALESCE(codigoEstrategiaCovid, 'ND') AS codigo_estrategia_covid,
        CASE 
            WHEN codigoEstrategiaCovid = 'ND' OR codigoEstrategiaCovid IS NULL THEN 'Não Informado'
            ELSE 'Estratégia ' + codigoEstrategiaCovid
        END AS descricao_estrategia
    FROM dbo.prata_sindrome_gripal
    WHERE codigoEstrategiaCovid IS NOT NULL
) AS source
ON target.codigo_estrategia_covid = source.codigo_estrategia_covid
WHEN MATCHED THEN
    UPDATE SET 
        target.descricao_estrategia = source.descricao_estrategia
WHEN NOT MATCHED BY TARGET THEN
    INSERT (codigo_estrategia_covid, descricao_estrategia)
    VALUES (source.codigo_estrategia_covid, source.descricao_estrategia);
GO


-- --------------------------------------------------------------------------------
-- 5. UPSERT FATO SÍNDROME GRIPAL
-- --------------------------------------------------------------------------------
MERGE dbo.gold_fct_sindrome_gripal AS target
USING (
    SELECT 
        sourceId AS id_notificacao,
        NULLIF(municipioIBGE, 'ND') AS codigo_municipio_ibge,
        COALESCE(cbo, 'ND') AS codigo_cbo,
        COALESCE(codigoRecebeuVacina, 'ND') AS codigo_recebeu_vacina,
        COALESCE(codigoEstrategiaCovid, 'ND') AS codigo_estrategia_covid,
        COALESCE(estado, 'ND') AS sigla_uf,
        CAST(dataNotificacao AS DATE) AS id_data_notificacao,
        sexo,
        idade,
        racaCor,
        profissionalSaude,
        profissionalSeguranca,
        evolucaoCaso,
        classificacaoFinal,
        totalTestesRealizados,
        1 AS total_notificacoes,
        CASE WHEN evolucaoCaso = 'Cura' THEN 1 ELSE 0 END AS qtd_cura,
        CASE WHEN classificacaoFinal LIKE '%Laboratorial%' THEN 1 ELSE 0 END AS qtd_confirmado_lab
    FROM dbo.prata_sindrome_gripal
    WHERE isExcluido = 0
) AS source
ON target.id_notificacao = source.id_notificacao
WHEN MATCHED THEN
    UPDATE SET 
        target.codigo_municipio_ibge = source.codigo_municipio_ibge,
        target.codigo_cbo = source.codigo_cbo,
        target.codigo_recebeu_vacina = source.codigo_recebeu_vacina,
        target.codigo_estrategia_covid = source.codigo_estrategia_covid,
        target.sigla_uf = source.sigla_uf,
        target.id_data_notificacao = source.id_data_notificacao,
        target.sexo = source.sexo,
        target.idade = source.idade,
        target.racaCor = source.racaCor,
        target.profissionalSaude = source.profissionalSaude,
        target.profissionalSeguranca = source.profissionalSeguranca,
        target.evolucaoCaso = source.evolucaoCaso,
        target.classificacaoFinal = source.classificacaoFinal,
        target.totalTestesRealizados = source.totalTestesRealizados,
        target.total_notificacoes = source.total_notificacoes,
        target.qtd_cura = source.qtd_cura,
        target.qtd_confirmado_lab = source.qtd_confirmado_lab
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        id_notificacao, codigo_municipio_ibge, codigo_cbo, codigo_recebeu_vacina, 
        codigo_estrategia_covid, sigla_uf, id_data_notificacao, sexo, idade, 
        racaCor, profissionalSaude, profissionalSeguranca, evolucaoCaso, 
        classificacaoFinal, totalTestesRealizados, total_notificacoes, qtd_cura, qtd_confirmado_lab
    )
    VALUES (
        source.id_notificacao, source.codigo_municipio_ibge, source.codigo_cbo, source.codigo_recebeu_vacina, 
        source.codigo_estrategia_covid, source.sigla_uf, source.id_data_notificacao, source.sexo, source.idade, 
        source.racaCor, source.profissionalSaude, source.profissionalSeguranca, source.evolucaoCaso, 
        source.classificacaoFinal, source.totalTestesRealizados, source.total_notificacoes, source.qtd_cura, source.qtd_confirmado_lab
    );
GO
