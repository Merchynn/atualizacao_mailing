/*
BI envia o cnpj , RAZÃO SOCIAL, CPF DO REPRESENTANTE, CREDITO MOTIVO NEGADO,LETRA_TRANSACT ,SCORE_HOI1
*/

/*ETAPA 1 : TRAZER AS INFORMAÇOES DA EMPRESA:
	PORTE,
	SCORE QUOD
	STATUS
	DATA DE FUNDAÇÃO
*/

-- os tempos abaixo referem-se a medição feita em 20/03/2023
-- APAGAR O ÍNDICE 
DROP index cnpj_empresa on TB_CRDT_CLASSLIST_LETRA_R
-- criar índice 
-- tempo 2 minutos




create index cnpj_empresa on TB_CRDT_CLASSLIST_LETRA_R(cnpj)

--- tempo: de 20 minutos passou 
update a
  set 
       
     -- a.[DT_FUNDACAO]= CONVERT(DATE,LEFT(data_fundacao,9),106)
      a.[DT_FUNDACAO] = convert(date,left(DATA_FUNDACAO,9),103)
      ,a.[DE_PORTE]=  case when porte_empresa = 'Microempresa(ME)' THEN 'ME'
					when porte_empresa = 'Microempreendedor Individual(MEI)' THEN 'MEI'
					when porte_empresa = 'Empresa de Pequeno Porte(EPP)' THEN 'EPP'
					when porte_empresa = 'OUTROS' THEN 'OUTROS'
					when porte_empresa = 'Sem informação' THEN 'OUTROS'
					END 
      ,a.SCORE_HOI1=  SCORE_PJ_CUSTOMIZADO
	  ,a.[DE_EMPRESA_ATIVA] =	case WHEN id_situacao_cadastral = 'A' THEN 'ATIVA'
									WHEN id_situacao_cadastral = 'S' THEN 'SUSPENSA'
									WHEN id_situacao_cadastral = 'I' THEN 'INAPTA'
									WHEN id_situacao_cadastral = 'B' THEN 'BAIXADA'
									WHEN id_situacao_cadastral = 'N' THEN 'NULA' END 
	,a.UF = b.UF
	,a.MUNICIPIO = b.MUNICIPIO
      ,a.[DT_INCLUSAO]=getdate()
FROM  TB_CRDT_CLASSLIST_LETRA_R a 

  inner join  [dbo].[TB_CRDT_BASE_QUOD_FULL_PJ] b

  on a.[CNPJ] = b.CNPJ
  where DT_FUNDACAO is null


GO

--- buscar os sócios das empresa pela base de sócios da QUOD
-- tempo : 5 minutos 
update a 
set  CPF_Representante = b.DOCUMENTO
from  TB_CRDT_CLASSLIST_LETRA_R a 
inner join 
	(
		select * from TB_CRDT_QUOD_BASE_QUADRO_SOCIETARIO
		where DATA_SAIDA = '' or DATA_SAIDA is null
		and TIPO_DOCUMENTO = 'CPF' 
	) b on a.CNPJ = b.CNPJ

	WHERE (CPF_Representante = '' or CPF_Representante is null)

GO 

--------

-- tempo: 17:11
-- regra atualizada pois a razão social dos novos MEI está començando com a raiz do CNPJ.
--Dessa forma, se faz necessário validar se o inicio da razão social  é igual aos dois primeiros digitos do CNPJ da emrpresa

update TB_CRDT_CLASSLIST_LETRA_R 
set CPF_Representante=[dbo].[TiraLetras](razao_social)
where (CPF_Representante = '' or CPF_Representante is null) 
	and (left(Razao_Social,2) <> left(cnpj,2) )
	and (CPF_Representante is null or CPF_Representante = '')

GO
--- tempo:  10 minutos 

  update TB_CRDT_CLASSLIST_LETRA_R
  set [CPF_Representante] = right('00000000000000'+[CPF_Representante],14)

  GO
 --tempo : 10 minutos
  update TB_CRDT_CLASSLIST_LETRA_R
  set [CPF_Representante] = null 
  where [CPF_Representante] = '00000000000000'

  GO

----- Faixa tempo de fundação

 -- tempo: 2 minutos
  update a 
  set FAIXA_TEMPO_FUNDACAO = CASE WHEN ([DT_FUNDACAO] IS NULL OR [DT_FUNDACAO] ='') THEN 'NLOC DT FUNDACAO' 
	  WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/1) < 90 then '00- < 3 MESES'
      WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) <=6 then '01- 3 A 6 MESES'
	  WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) > 6 AND ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) <= 12 then '02- > 6 MESES E <= 12 MESES'
	  WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) > 12 AND ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) <= 18 then '03- > 12 MESES <= 18 MESES'
	  WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) > 18 AND ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) <= 24 then '04- > 18 MESES <= 24 MESES'
	  WHEN ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) > 24 then '05- > 24 MESES'
END
,TEMPO_DE_FUNDACAO_MES =  
CASE WHEN ([DT_FUNDACAO] IS NULL OR [DT_FUNDACAO] ='') THEN  NULL
ELSE ceiling(convert(real,datediff (d,convert(date,[DT_FUNDACAO]),convert(date,getdate())))/30) END
, DIAS_FUNDACAO = DATEDIFF(D,DT_FUNDACAO,GETDATE())
  from TB_CRDT_CLASSLIST_LETRA_R a

GO 

-- INFORMA REGIAO GEOGRAFICA DO PAIS
UPDATE A 
SET REGIAO_PAIS =  	CASE WHEN  UF IN ('DF', 'GO','MT','MS') THEN 'CENTRO-OESTE'
	WHEN  UF IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE') THEN 'NORDESTE'
	WHEN  UF IN ('AC','AP','AM','PA','RO','RR','TO') THEN 'NORTE'
	WHEN  UF IN ('ES','MG','RJ','SP') THEN 'SUDESTE'
	WHEN  UF IN ('PR','RS','SC') THEN 'SUL'
	else	'OUTRAS'
	END 
FROM TB_CRDT_CLASSLIST_LETRA_R A 
GO

---
 /* REGIONAL */

 -- tempo :: 2 minutos

  update a 
  set REGIONAL =   [dbo].[RETORNA_REGIONAL_2025](UF) 
  from   TB_CRDT_CLASSLIST_LETRA_R a


go

-- tempo: 2 horas
DECLARE @dig varchar(2);
DECLARE @CONT INT = 0;
DECLARE @DT_INC DATETIME = GETDATE();

SET @CONT = 0;

WHILE @CONT < 100
BEGIN
SET @dig = right('00'+CAST(@CONT AS VARCHAR(3)),2);

update A
 set 
       a.[NM_PESSOA] = b.[NOME]
      ,a.[DE_SITUACAO_CADASTRAL] = b.[SITUACAO_CADASTRAL]
        ,[SCORE_QUOD] = b.[SCORE_2_1]
	
  FROM (SELECT [CPF_Representante],
	[NM_PESSOA],
		[DE_SITUACAO_CADASTRAL] ,
		[SCORE_QUOD]
		FROM TB_CRDT_CLASSLIST_LETRA_R
		WHERE ([CPF_Representante] IS NOT NULL AND [CPF_Representante] <>'') AND [CPF_Representante] LIKE @dig+'%') A
 INNER JOIN
	   (SELECT CPF_14,
	   NOME,
	   case when [OBITO] = 'S' THEN 'CANCELADO' ELSE SITUACAO_CADASTRAL END AS SITUACAO_CADASTRAL,
	  SCORE as  SCORE_2_1
	    FROM  [dbo].TB_CRDT_BASE_QUOD_BASE_PF WHERE cpf_14 LIKE @dig+'%') B
	ON [CPF_Representante] = CPF_14;

	
	select @dig,@DT_INC

    SET @CONT = @CONT + 1;
END;

go
 ----  define a  faixa de score 
 --tempo: 30 minutos
 update a
set 
a.FAIXA_SCORE_QUOD_25 = case when  SCORE_QUOD like 'flag%' then 'Flags de Exceção' else [dbo].[DEFINIR_FAIXA_SCORE_QUERY_PADRAO](25, SCORE_QUOD) end
,a.FAIXA_SCORE_QUOD_50 = case when  SCORE_QUOD like 'flag%' then 'Flags de Exceção' else [dbo].[DEFINIR_FAIXA_SCORE_QUERY_PADRAO](50, SCORE_QUOD) end
,a.FAIXA_SCORE_QUOD_5 = case when  SCORE_QUOD like 'flag%' then 'Flags de Exceção' else [dbo].[DEFINIR_FAIXA_SCORE_QUERY_PADRAO](5, SCORE_QUOD) end

from TB_CRDT_CLASSLIST_LETRA_R a

go 
---- REGRAS DE DÉBITO E  RETIRADAS EM 16/04/2024*/ 
-- para consultar quais eram as regras antigas, abra o aquivo : ALTERACOES_MAILING_R_RECLASSIFICADO_v_072024.sql
--- DEBITO NIO 

update a 

set a.vlr_debito_nio = b.VALOR_FATURADO_EM_ABERTO,
DIAS_ATRASO = NUM_DIAS_DEBITO_MAIS_ANTIGO,
CLI_INAD_NIO = CLIENTE_INADIMPLENTE


FROM TB_CRDT_CLASSLIST_LETRA_R a 

inner join [TB_CRDT_BASE_INADIM_NIO] b on a.cnpj = b.numero_documento

--- 


---  MARCAR DEBITO

update a 

 set a.LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS  =  'D',													
     a.LETRA_PORTAL_REMARCADO_QUOD_VERSAO_UFS  = 'D',
	 A.PRE_APROVADO_QUOD_VERSAO_UFS  = 'N'

	
from TB_CRDT_CLASSLIST_LETRA_R a 
WHERE [DE_PORTE] = 'MEI' AND CLI_INAD_NIO = 'SIM'


-- ALTERACAO DO CORTE DE SCORE PARA 750 PTS
update a 

 set a.LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS  =  CASE WHEN SCORE_QUOD < 750 THEN 'Q'
													when score_quod is null then 'Q'
													ELSE 'R' END,
     a.LETRA_PORTAL_REMARCADO_QUOD_VERSAO_UFS  = CASE WHEN SCORE_QUOD < 750 THEN 'R'
												 when score_quod is null then 'R'
												 ELSE 'RR' END ,
	 A.PRE_APROVADO_QUOD_VERSAO_UFS  = CASE WHEN SCORE_QUOD < 750 THEN 'N'
									   when score_quod is null then 'N'	
									  ELSE 'S' END

	
from TB_CRDT_CLASSLIST_LETRA_R a 
WHERE [DE_PORTE] = 'MEI' AND ( PRE_APROVADO_QUOD_VERSAO_UFS IS NULL OR PRE_APROVADO_QUOD_VERSAO_UFS = '')

GO
/* POR ULTIMO SERA FEITA A MARCAÇÃO DOS CNPJS <> ATIVOS */ 

/* MARCAR CNPJ <> ATIVO */
--tempo : 3 minutos 
update a 

 set a.LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS  =  'L',
     a.LETRA_PORTAL_REMARCADO_QUOD_VERSAO_UFS  = 'L',
	 MEI_COM_CPF_INADIMPLENTE = NULL,
	 A.PRE_APROVADO_QUOD_VERSAO_UFS  = 'N'

	
from TB_CRDT_CLASSLIST_LETRA_R a 
WHERE [DE_EMPRESA_ATIVA] <> 'ATIVA'

--- ==> NOVAS REGRA INCLUSA EM 25/08/2023
-- 1 : CASO O CNPJ TENHA MENOS DE 90 DIAS DE FUNDAÇÃO , INDEPENDENTE DO SCORE E DA REGIÃO

UPDATE A 
 set a.LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS  =  'Q',
     a.LETRA_PORTAL_REMARCADO_QUOD_VERSAO_UFS  = 'Q',
	 MEI_COM_CPF_INADIMPLENTE = NULL,
	 A.PRE_APROVADO_QUOD_VERSAO_UFS  = 'N'
	
from TB_CRDT_CLASSLIST_LETRA_R a 
WHERE DIAS_FUNDACAO < 90  AND [DE_EMPRESA_ATIVA] = 'ATIVA' 

--- 3: INCLUIR OS CNPJS LISTADOS COMO MAILING F

---- regra do mailing K 

update a 

 set a.LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS  = 'K',					
     a.LETRA_PORTAL_REMARCADO_QUOD_VERSAO_UFS  = 'K',
	 A.PRE_APROVADO_QUOD_VERSAO_UFS  = 'S'

	
from TB_CRDT_CLASSLIST_LETRA_R a 
WHERE [DE_PORTE] = 'MEI' AND LETRA_TRANSACT_REMARCADO_QUOD_VERSAO_UFS = 'Q' AND SCORE_QUOD > 320 and DIAS_FUNDACAO >= 90

