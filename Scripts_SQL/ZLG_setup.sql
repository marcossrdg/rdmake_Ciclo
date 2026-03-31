-- ============================================================
-- ZLG_setup.sql
-- Criacao da tabela ZLG010 para Solicitacoes de Logistica
-- Banco: CCC918_161112_PR_PD
-- Executar no SQL Server Management Studio ou via Invoke-Sqlcmd
--
-- ATENCAO: Executar UMA VEZ. Verificar se tabela ja existe antes.
-- ============================================================

USE CCC918_161112_PR_PD;
GO

-- ── PASSO 1: Criar tabela fisica ZLG010 ──────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ZLG010')
BEGIN
    CREATE TABLE ZLG010 (
        R_E_C_N_O_  INT          IDENTITY(1,1) NOT NULL,
        D_E_L_E_T_  CHAR(1)      NOT NULL DEFAULT ' ',

        -- Campos de controle Protheus
        ZLG_FILIAL  CHAR(2)      NOT NULL DEFAULT '  ',

        -- Identificacao da solicitacao
        ZLG_ID      CHAR(10)     NOT NULL DEFAULT '          ',  -- LOG-0001
        ZLG_PRIOR   CHAR(1)      NOT NULL DEFAULT ' ',           -- U=Urgente M=Media B=Baixa
        ZLG_TIPO    CHAR(1)      NOT NULL DEFAULT ' ',           -- E=Eletivo R=Reserva P=Reposicao
        ZLG_STATUS  CHAR(1)      NOT NULL DEFAULT 'P',           -- P=Pendente A=Atendido

        -- Dados do pedido
        ZLG_HOSP    CHAR(80)     NOT NULL DEFAULT '',            -- Hospital
        ZLG_PAC     CHAR(80)     NOT NULL DEFAULT '',            -- Nome do Paciente
        ZLG_DTPROC  CHAR(8)      NOT NULL DEFAULT '        ',    -- Data Procedimento YYYYMMDD
        ZLG_HRPROC  CHAR(5)      NOT NULL DEFAULT '     ',       -- Hora Procedimento HH:MM
        ZLG_CONV    CHAR(80)     NOT NULL DEFAULT '',            -- Convenio
        ZLG_MED     CHAR(80)     NOT NULL DEFAULT '',            -- Medico

        -- Campos texto livre
        ZLG_MAT     CHAR(250)    NOT NULL DEFAULT '',            -- Materiais solicitados e qtde
        ZLG_OBS     CHAR(250)    NOT NULL DEFAULT '',            -- Observacao
        ZLG_ANEXO   CHAR(200)    NOT NULL DEFAULT '',            -- Nome do arquivo anexo

        -- Controle de envio
        ZLG_DTENVI  CHAR(8)      NOT NULL DEFAULT '        ',    -- Data envio YYYYMMDD
        ZLG_HRENVI  CHAR(5)      NOT NULL DEFAULT '     ',       -- Hora envio HH:MM

        CONSTRAINT PK_ZLG010 PRIMARY KEY (R_E_C_N_O_)
    );

    PRINT 'Tabela ZLG010 criada com sucesso.';
END
ELSE
BEGIN
    PRINT 'Tabela ZLG010 ja existe. Nenhuma alteracao realizada.';
END
GO

-- ── PASSO 2: Criar indices ────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ZLG010_ID' AND object_id = OBJECT_ID('ZLG010'))
    CREATE UNIQUE INDEX ZLG010_ID     ON ZLG010 (ZLG_ID) WHERE D_E_L_E_T_ = ' ';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ZLG010_STATUS' AND object_id = OBJECT_ID('ZLG010'))
    CREATE INDEX ZLG010_STATUS ON ZLG010 (ZLG_STATUS, ZLG_DTENVI DESC) WHERE D_E_L_E_T_ = ' ';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ZLG010_TIPO' AND object_id = OBJECT_ID('ZLG010'))
    CREATE INDEX ZLG010_TIPO   ON ZLG010 (ZLG_TIPO, ZLG_STATUS) WHERE D_E_L_E_T_ = ' ';
GO

PRINT 'Indices criados com sucesso.';
GO

-- ── PASSO 3 (OPCIONAL): Inserir entradas no dicionario Protheus SX3 ──
-- Descomente e execute APENAS se quiser que o Protheus gerencie a
-- tabela via SIGACFG (Atualizacao de Dicionarios).
-- Sem isso o servico REST funciona normalmente via SQL direto.

/*
-- Limpa entradas anteriores se houver
DELETE FROM SX3010 WHERE X3_ARQUIVO = 'ZLG' AND D_E_L_E_T_ = ' ';

-- Insere definicao de cada campo no dicionario
INSERT INTO SX3010 (D_E_L_E_T_,X3_CMP,X3_ARQUIVO,X3_ORDEM,X3_CAMPO,X3_TIPO,X3_TAMANHO,X3_DECIMAL,X3_TITULO,X3_DESCRIC,X3_USADO,X3_OBRIGAT,X3_BROWSE,X3_VISUAL,X3_CONTEXT,X3_CBOX,X3_VALID,X3_RELACAO,X3_F3,X3_NIVEL,X3_RESERV,X3_CHECK,X3_TRIGGER,X3_PROPRI,X3_WHEN,X3_INIBRW,X3_GRPSXG,X3_FOLDER,X3_PYME) VALUES
(' ','  ','ZLG','01','ZLG_FILIAL','C',2,0,'Filial','Filial','1','N','N','N','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','02','ZLG_ID    ','C',10,0,'Protocolo','Numero do Protocolo','1','S','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','03','ZLG_PRIOR ','C',1,0,'Prioridade','U=Urgente M=Media B=Baixa','1','S','S','V','R','U=Urgente;M=Media;B=Baixa','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','04','ZLG_TIPO  ','C',1,0,'Tipo','E=Eletivo R=Reserva P=Reposicao','1','S','S','V','R','E=Eletivo;R=Reserva;P=Reposicao','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','05','ZLG_STATUS','C',1,0,'Status','P=Pendente A=Atendido','1','S','S','V','R','P=Pendente;A=Atendido','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','06','ZLG_HOSP  ','C',80,0,'Hospital','Nome do Hospital','1','S','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','07','ZLG_PAC   ','C',80,0,'Paciente','Nome do Paciente','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','08','ZLG_DTPROC','D',8,0,'Dt.Procedimento','Data do Procedimento','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','09','ZLG_HRPROC','C',5,0,'Hr.Procedimento','Hora do Procedimento','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','10','ZLG_CONV  ','C',80,0,'Convenio','Nome do Convenio','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','11','ZLG_MED   ','C',80,0,'Medico','Nome do Medico','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','12','ZLG_MAT   ','C',250,0,'Materiais','Materiais Solicitados e Qtde','1','S','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','13','ZLG_OBS   ','C',250,0,'Observacao','Observacao','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','14','ZLG_ANEXO ','C',200,0,'Anexo','Nome do Arquivo Anexo','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','15','ZLG_DTENVI','D',8,0,'Dt.Envio','Data de Envio','1','N','S','V','R','','','','',1,'','','','U','','','','','N'),
(' ','  ','ZLG','16','ZLG_HRENVI','C',5,0,'Hr.Envio','Hora de Envio','1','N','S','V','R','','','','',1,'','','','U','','','','','N');
*/
GO

-- ── Verificacao final ─────────────────────────────────────────
SELECT
    'ZLG010' AS Tabela,
    COUNT(*) AS TotalRegistros,
    SUM(CASE WHEN ZLG_STATUS='P' THEN 1 ELSE 0 END) AS Pendentes,
    SUM(CASE WHEN ZLG_STATUS='A' THEN 1 ELSE 0 END) AS Atendidos
FROM ZLG010
WHERE D_E_L_E_T_ = ' ';
GO
