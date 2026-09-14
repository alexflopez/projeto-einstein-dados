CREATE OR ALTER VIEW dbo.vw_prata_sindrome_gripal AS
SELECT 
    -- Chave Única e Origem
    NULLIF(TRIM(source_id), 'NULL') AS sourceId, 
    NULLIF(TRIM(origem), 'NULL') AS origem, 

    -- Localização e Geografia
    CASE 
        WHEN estado IS NULL OR TRIM(estado) IN ('', 'NULL', 'undefined', 'null', 'INDEFINIDO') THEN 'ND'
        ELSE TRIM(estado) 
    END AS estado, 
	NULLIF(TRIM(estadoIBGE), 'NULL') AS estadoIBGE,
    NULLIF(TRIM(municipio), 'NULL') AS municipio, 
    NULLIF(TRIM(municipioIBGE), 'NULL') AS municipioIBGE,
    NULLIF(TRIM(estadoNotificacao), 'NULL') AS estadoNotificacao,
    NULLIF(TRIM(estadoNotificacaoIBGE), 'NULL') AS estadoNotificacaoIBGE,
    NULLIF(TRIM(municipioNotificacao), 'NULL') AS municipioNotificacao,

    -- Corta tudo o que vem antes do ponto decimal
	CASE 
		WHEN CHARINDEX('.', TRIM(municipioNotificacaoIBGE)) > 0 
		THEN SUBSTRING(TRIM(municipioNotificacaoIBGE), 1, CHARINDEX('.', TRIM(municipioNotificacaoIBGE)) - 1)
		ELSE TRIM(municipioNotificacaoIBGE)
	END AS municipioNotificacaoIBGE,

    -- Dados Demográficos e Profissionais
    NULLIF(TRIM(sexo), 'NULL') AS sexo,
    TRY_CAST(TRY_CAST(NULLIF(TRIM(idade), 'NULL') AS FLOAT) AS INT) AS idade,
    NULLIF(TRIM(racaCor), 'NULL') AS racaCor,
    NULLIF(TRIM(profissionalSaude), 'NULL') AS profissionalSaude,
    NULLIF(TRIM(profissionalSeguranca), 'NULL') AS profissionalSeguranca,
    NULLIF(TRIM(cbo), 'NULL') AS cbo,

    -- Quadro Clínico e Diagnóstico
    NULLIF(TRIM(sintomas), 'NULL') AS sintomas,
    CASE 
		WHEN NULLIF(TRIM(outrosSintomas), 'NULL') IS NULL THEN NULL
		ELSE UPPER(LEFT(TRIM(outrosSintomas), 1)) + LOWER(SUBSTRING(TRIM(outrosSintomas), 2, LEN(TRIM(outrosSintomas))))
	END AS outrosSintomas, --normalizando os dados para primeira maiúscula
	
	NULLIF(TRIM(condicoes), 'NULL') AS condicoes, 

	CASE 
        WHEN NULLIF(TRIM(outrasCondicoes), 'NULL') IS NULL OR TRIM(outrasCondicoes) = '' THEN NULL
        ELSE UPPER(LEFT(TRIM(outrasCondicoes), 1)) + LOWER(SUBSTRING(TRIM(outrasCondicoes), 2, LEN(TRIM(outrasCondicoes))))
    END AS outrasCondicoes, 
    NULLIF(TRIM(evolucaoCaso), 'NULL') AS evolucaoCaso, 
    NULLIF(TRIM(classificacaoFinal), 'NULL') AS classificacaoFinal, 

    -- Datas (Conversão de VARCHAR para DATE)
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataNotificacao), 'NULL') AS DATE), 103) AS dataNotificacao, -- tratamento do formato ano/mes/dia para dia/mes/ano
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataInicioSintomas), 'NULL') AS DATE), 103) AS dataInicioSintomas, -- tratamento do formato ano/mes/dia para dia/mes/ano
	CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataEncerramento), 'NULL') AS DATE), 103) AS dataEncerramento, -- tratamento do formato ano/mes/dia para dia/mes/ano
	CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataPrimeiraDose), 'NULL') AS DATE), 103) AS dataPrimeiraDose, -- tratamento do formato ano/mes/dia para dia/mes/ano
	CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataSegundaDose), 'NULL') AS DATE), 103) AS dataSegundaDose, -- tratamento do formato ano/mes/dia para dia/mes/ano

    -- Vacinação e Estratégia
    TRY_CAST(TRY_CAST(NULLIF(TRIM(totalTestesRealizados), 'NULL') AS FLOAT) AS INT) AS totalTestesRealizados, 
	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoEstrategiaCovid), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoEstrategiaCovid,
    CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoRecebeuVacina), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoRecebeuVacina,    
    NULLIF(TRIM(codigoDosesVacina), 'NULL') AS codigoDosesVacina,-- ok

    -- Padronização dos códigos dos laboráórios
	CASE 
		WHEN NULLIF(TRIM(codigoLaboratorioPrimeiraDose), 'NULL') IS NULL OR TRIM(codigoLaboratorioPrimeiraDose) = '' THEN NULL
		WHEN TRIM(codigoLaboratorioPrimeiraDose) LIKE '%Pendente Identifica%' THEN 'Pendente Identificação'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%FUNDACAO OSWALDO CRUZ%' THEN 'Fundação Oswaldo Cruz'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%PFIZER%PEDI%MENOR%' THEN 'Pfizer - Pediátrica Menor de 5 Anos'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%PFIZER%PEDI%' THEN 'Pfizer - Pediátrica'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%PFIZER%BIONTECH%' THEN 'Pfizer/BioNTech'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) = 'PFIZER' THEN 'Pfizer'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%ASTRAZENECA%OXFORD%' THEN 'AstraZeneca/Oxford'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%ASTRAZENECA%FIOCRUZ%' THEN 'AstraZeneca/Fiocruz'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) = 'ASTRAZENECA' THEN 'AstraZeneca'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%SINOVAC%BUTANTAN%' THEN 'Sinovac/Butantan'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) = 'SINOVAC' THEN 'Sinovac'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) = 'JANSSEN' THEN 'Janssen'
		WHEN UPPER(TRIM(codigoLaboratorioPrimeiraDose)) LIKE '%MINISTERIO DA SAUDE%' THEN 'Ministério da Saúde'
		ELSE UPPER(LEFT(REPLACE(TRIM(codigoLaboratorioPrimeiraDose), '??', 'çã'), 1)) 
			 + LOWER(SUBSTRING(REPLACE(TRIM(codigoLaboratorioPrimeiraDose), '??', 'çã'), 2, 255))
	END AS codigoLaboratorioPrimeiraDose, 

	CASE 
        WHEN NULLIF(TRIM(codigoLaboratorioSegundaDose), 'NULL') IS NULL OR TRIM(codigoLaboratorioSegundaDose) = '' THEN NULL
        
        -- Correção de encoding / ruídos
        WHEN TRIM(codigoLaboratorioSegundaDose) LIKE '%Pendente Identifica%' THEN 'Pendente Identificação'
        
        -- Padronização com Capital Case e Acentuação Oficial
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%FUNDACAO OSWALDO CRUZ%' THEN 'Fundação Oswaldo Cruz'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%FUNDACAO BUTANTAN%' THEN 'Fundação Butantan'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%PFIZER%PEDI%MENOR%' THEN 'Pfizer - Pediátrica Menor de 5 Anos'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%PFIZER%PEDI%' THEN 'Pfizer - Pediátrica'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%PFIZER%BIONTECH%' THEN 'Pfizer/BioNTech'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) = 'PFIZER' THEN 'Pfizer'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%ASTRAZENECA%OXFORD%' THEN 'AstraZeneca/Oxford'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%ASTRAZENECA%FIOCRUZ%' THEN 'AstraZeneca/Fiocruz'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) = 'ASTRAZENECA' THEN 'AstraZeneca'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%SINOVAC%BUTANTAN%' THEN 'Sinovac/Butantan'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) = 'SINOVAC' THEN 'Sinovac'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) = 'JANSSEN' THEN 'Janssen'
        WHEN UPPER(TRIM(codigoLaboratorioSegundaDose)) LIKE '%MINISTERIO DA SAUDE%' THEN 'Ministério da Saúde'
        
        -- Fallback: Primeira letra maiúscula
        ELSE UPPER(LEFT(REPLACE(TRIM(codigoLaboratorioSegundaDose), '??', 'çã'), 1)) 
             + LOWER(SUBSTRING(REPLACE(TRIM(codigoLaboratorioSegundaDose), '??', 'çã'), 2, 255))
    END AS codigoLaboratorioSegundaDose, -- OK
    NULLIF(TRIM(lotePrimeiraDose), 'NULL') AS lotePrimeiraDose,
    NULLIF(TRIM(loteSegundaDose), 'NULL') AS loteSegundaDose, 
	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoContemComunidadeTradicional), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoContemComunidadeTradicional, 
    

    -- Busca Ativa e Triagem
	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoBuscaAtivaAssintomatico), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoBuscaAtivaAssintomatico, 
    
	CASE 
		WHEN NULLIF(TRIM(outroBuscaAtivaAssintomatico), 'NULL') IS NULL OR TRIM(outroBuscaAtivaAssintomatico) = '' THEN NULL
		ELSE UPPER(LEFT(TRIM(outroBuscaAtivaAssintomatico), 1)) + LOWER(SUBSTRING(TRIM(outroBuscaAtivaAssintomatico), 2, LEN(TRIM(outroBuscaAtivaAssintomatico))))
	END AS outroBuscaAtivaAssintomatico, 
	
	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoTriagemPopulacaoEspecifica), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoTriagemPopulacaoEspecifica,
    
	CASE 
		WHEN NULLIF(TRIM(outroTriagemPopulacaoEspecifica), 'NULL') IS NULL OR TRIM(outroTriagemPopulacaoEspecifica) = '' THEN NULL
		ELSE UPPER(LEFT(TRIM(outroTriagemPopulacaoEspecifica), 1)) + LOWER(SUBSTRING(TRIM(outroTriagemPopulacaoEspecifica), 2, LEN(TRIM(outroTriagemPopulacaoEspecifica))))
	END AS outroTriagemPopulacaoEspecifica,

	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoLocalRealizacaoTestagem), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoLocalRealizacaoTestagem,

    CASE 
		WHEN NULLIF(TRIM(outroLocalRealizacaoTestagem), 'NULL') IS NULL OR TRIM(outroLocalRealizacaoTestagem) = '' THEN NULL
		ELSE UPPER(LEFT(TRIM(outroLocalRealizacaoTestagem), 1)) + LOWER(SUBSTRING(TRIM(outroLocalRealizacaoTestagem), 2, LEN(TRIM(outroLocalRealizacaoTestagem))))
	END AS outroLocalRealizacaoTestagem,

    -- Teste 1
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoEstadoTeste1), 'NULL') AS FLOAT) AS INT) AS codigoEstadoTeste1,
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoTipoTeste1), 'NULL') AS FLOAT) AS INT) AS codigoTipoTeste1, 
    CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoFabricanteTeste1), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoFabricanteTeste1, 

    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoResultadoTeste1), 'NULL') AS FLOAT) AS INT) AS codigoResultadoTeste1, 
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataColetaTeste1), 'NULL') AS DATE), 103) AS dataColetaTeste1,  -- tratamento do formato ano/mes/dia para dia/mes/ano

    -- Teste 2
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoEstadoTeste2), 'NULL') AS FLOAT) AS INT) AS codigoEstadoTeste2,
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoTipoTeste2), 'NULL') AS FLOAT) AS INT) AS codigoTipoTeste2,
	CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoFabricanteTeste2), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoFabricanteTeste2, 

    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoResultadoTeste2), 'NULL') AS FLOAT) AS INT) AS codigoResultadoTeste2, 
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataColetaTeste2), 'NULL') AS DATE), 103) AS dataColetaTeste2,

    -- Teste 3
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoEstadoTeste3), 'NULL') AS FLOAT) AS INT) AS codigoEstadoTeste3, 
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoTipoTeste3), 'NULL') AS FLOAT) AS INT) AS codigoTipoTeste3, 
    CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoFabricanteTeste3), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoFabricanteTeste3,
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoResultadoTeste3), 'NULL') AS FLOAT) AS INT) AS codigoResultadoTeste3, 
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataColetaTeste3), 'NULL') AS DATE), 103) AS dataColetaTeste3, 

    -- Teste 4
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoEstadoTeste4), 'NULL') AS FLOAT) AS INT) AS codigoEstadoTeste4, 
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoTipoTeste4), 'NULL') AS FLOAT) AS INT) AS codigoTipoTeste4, 
    CAST(CAST(TRY_CAST(NULLIF(TRIM(codigoFabricanteTeste4), 'NULL') AS FLOAT) AS INT) AS VARCHAR(50)) AS codigoFabricanteTeste4,
    TRY_CAST(TRY_CAST(NULLIF(TRIM(codigoResultadoTeste4), 'NULL') AS FLOAT) AS INT) AS codigoResultadoTeste4, 
    CONVERT(VARCHAR(10), TRY_CAST(NULLIF(TRIM(dataColetaTeste4), 'NULL') AS DATE), 103) AS dataColetaTeste4,

    -- Flags de Controle
    CASE WHEN LOWER(TRIM(excluido)) = 'true' THEN 1 ELSE 0 END AS isExcluido,
    CASE WHEN LOWER(TRIM(validado)) = 'true' THEN 1 ELSE 0 END AS isValidado
FROM dbo.bronze_sindrome_gripal;