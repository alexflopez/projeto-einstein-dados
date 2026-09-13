USE opendatasus;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'bronze_sindrome_gripal')
BEGIN
    CREATE TABLE dbo.bronze_sindrome_gripal (
        sintomas VARCHAR(MAX) NULL,
        profissionalSaude VARCHAR(MAX) NULL,
        racaCor VARCHAR(MAX) NULL,
        outrosSintomas VARCHAR(MAX) NULL,
        outrasCondicoes VARCHAR(MAX) NULL,
        profissionalSeguranca VARCHAR(MAX) NULL,
        cbo VARCHAR(MAX) NULL,
        condicoes VARCHAR(MAX) NULL,
        sexo VARCHAR(MAX) NULL,
        estado VARCHAR(MAX) NULL,
        estadoIBGE VARCHAR(MAX) NULL,
        municipio VARCHAR(MAX) NULL,
        municipioIBGE VARCHAR(MAX) NULL,
        origem VARCHAR(MAX) NULL,
        estadoNotificacao VARCHAR(MAX) NULL,
        municipioNotificacao VARCHAR(MAX) NULL,
        municipioNotificacaoIBGE VARCHAR(MAX) NULL,
        evolucaoCaso VARCHAR(MAX) NULL,
        classificacaoFinal VARCHAR(MAX) NULL,
        codigoEstrategiaCovid VARCHAR(MAX) NULL,
        codigoBuscaAtivaAssintomatico VARCHAR(MAX) NULL,
        outroBuscaAtivaAssintomatico VARCHAR(MAX) NULL,
        codigoTriagemPopulacaoEspecifica VARCHAR(MAX) NULL,
        outroTriagemPopulacaoEspecifica VARCHAR(MAX) NULL,
        codigoLocalRealizacaoTestagem VARCHAR(MAX) NULL,
        outroLocalRealizacaoTestagem VARCHAR(MAX) NULL,
        codigoRecebeuVacina VARCHAR(MAX) NULL,
        codigoLaboratorioPrimeiraDose VARCHAR(MAX) NULL,
        codigoLaboratorioSegundaDose VARCHAR(MAX) NULL,
        lotePrimeiraDose VARCHAR(MAX) NULL,
        loteSegundaDose VARCHAR(MAX) NULL,
        codigoContemComunidadeTradicional VARCHAR(MAX) NULL,
        source_id VARCHAR(MAX) NULL,
        excluido VARCHAR(MAX) NULL,
        validado VARCHAR(MAX) NULL,
        codigoDosesVacina VARCHAR(MAX) NULL,
        estadoNotificacaoIBGE VARCHAR(MAX) NULL,
        totalTestesRealizados VARCHAR(MAX) NULL,
        dataNotificacao VARCHAR(MAX) NULL,
        dataInicioSintomas VARCHAR(MAX) NULL
    );
END;
GO