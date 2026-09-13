USE opendatasus;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'dim_municipios')
BEGIN
    CREATE TABLE dbo.dim_municipios (
        uf VARCHAR(MAX) NULL,
        nomeUf VARCHAR(MAX) NULL,
        regiaoGeograficaIntermediaria VARCHAR(MAX) NULL,
        nomeRegiaoGeograficaIntermediaria VARCHAR(MAX) NULL,
        regiaoGeograficaImediata VARCHAR(MAX) NULL,
        nomeRegiaoGeograficaImediata VARCHAR(MAX) NULL,
        mesorregiaoGeografica VARCHAR(MAX) NULL,
        nomeMesorregiao VARCHAR(MAX) NULL,
        microrregiaoGeografica VARCHAR(MAX) NULL,
        nomeMicrorregiao VARCHAR(MAX) NULL,
        municipio VARCHAR(MAX) NULL,
        codigoMunicipioCompleto VARCHAR(MAX) NULL,
        nomeMunicipio VARCHAR(MAX) NULL
    );
END;
GO