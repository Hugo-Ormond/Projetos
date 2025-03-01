USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[UpCarga_FatoLTVTableau]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











CREATE PROC [dbo].[UpCarga_FatoLTVTableau] @TIPO varchar(50) = 'INCREMENTAL', @marca varchar(MAX) = 'G1'

AS

BEGIN



---------------------------------tabelas de combinação de Canais---------------------------------
CREATE TABLE #Canais (id int, Canais varchar(50),FilterCanais varchar(100))
INSERT INTO #Canais (id,Canais,FilterCanais) 
VALUES	
(1,'OFFLINE, FRANQUIA E ONLINE','OFFLINE'),(1,'OFFLINE, FRANQUIA E ONLINE','FRANQUIA SELL OUT'),(1,'OFFLINE, FRANQUIA E ONLINE','ONLINE'),
(2,'OFFLINE E ONLINE','OFFLINE'),(2,'OFFLINE E ONLINE','ONLINE'),
(3,'OFFLINE E FRANQUIA','OFFLINE'),(3,'OFFLINE E FRANQUIA','FRANQUIA SELL OUT'),
(4,'OFFLINE','OFFLINE'),
(5,'FRANQUIA','FRANQUIA SELL OUT'),
(6,'ONLINE','ONLINE'),
(7,'APP','APP'),
(8,'SITE','SITE')


---------------------------------tabelas de combinação de Marcas---------------------------------
CREATE TABLE #marcas (id int, Marcas varchar(50),FilterMarcas varchar(100))

declare @teste varchar(MAX) = 
CASE WHEN @marca = 'G1' then '(1,''TODAS EX-BAW'',''RESERVA''),(1,''TODAS EX-BAW'',''MINI''),(1,''TODAS EX-BAW'',''GO''),(1,''TODAS EX-BAW'',''OFICINA''),(1,''TODAS EX-BAW'',''GO RESERVA''),(1,''TODAS EX-BAW'',''GO MINI''),(1,''TODAS EX-BAW'',''INK''),(1,''TODAS EX-BAW'',''SIMPLES''),(1,''TODAS EX-BAW'',''REVERSA''),
(2,''REVERSA E GO'',''REVERSA''),(2,''REVERSA E GO'',''GO''),(2,''REVERSA E GO'',''GO MINI''),(2,''REVERSA E GO'',''GO RESERVA''),(3,''REVERSA E MINI'',''REVERSA''),(3,''REVERSA E MINI'',''MINI''),(4,''REVERSA'',''REVERSA'')'
WHEN @marca = 'G2' then  '(1,''TODAS'',''RESERVA''),(1,''TODAS'',''MINI''),(1,''TODAS'',''GO''),(1,''TODAS'',''OFICINA''),(1,''TODAS'',''GO RESERVA''),(1,''TODAS'',''GO MINI''),(1,''TODAS'',''INK''),(1,''TODAS'',''SIMPLES''),(1,''TODAS'',''BAW''),(1,''TODAS'',''REVERSA''),
(2,''INK'',''INK''), (3,''BAW'',''BAW''),(4,''RESERVA E GO'',''RESERVA''),(4,''RESERVA E GO'',''GO''),(4,''RESERVA E GO'',''GO MINI''),(4,''RESERVA E GO'',''GO RESERVA'')'
WHEN @marca = 'G3' then '(1,''RESERVA E REVERSA'',''RESERVA''),(1,''RESERVA E REVERSA'',''REVERSA''),(2,''OFICINA'',''OFICINA''),
        (3,''RESERVA, REVERSA E GO'',''RESERVA''),(3,''RESERVA, REVERSA E GO'',''REVERSA''),(3,''RESERVA, REVERSA E GO'',''GO''),(3,''RESERVA, REVERSA E GO'',''GO MINI''),(3,''RESERVA, REVERSA E GO'',''GO RESERVA''),
				(4,''RESERVA, REVERSA E MINI'',''RESERVA''),(4,''RESERVA, REVERSA E MINI'',''REVERSA''),(4,''RESERVA, REVERSA E MINI'',''MINI'')'
WHEN @marca = 'G4' then  	'(1,''RESERVA E MINI'',''RESERVA''),(1,''RESERVA E MINI'',''MINI''),(2,''RESERVA, MINI E GO'',''RESERVA''),(2,''RESERVA, MINI E GO'',''MINI''),(2,''RESERVA, MINI E GO'',''GO''),(2,''RESERVA, MINI E GO'',''GO MINI''),(2,''RESERVA, MINI E GO'',''GO RESERVA''),	
        (3,''REVERSA, MINI E GO'',''REVERSA''),(3,''REVERSA, MINI E GO'',''MINI''),(3,''REVERSA, MINI E GO'',''GO''),(3,''REVERSA, MINI E GO'',''GO MINI''),(3,''REVERSA, MINI E GO'',''GO RESERVA''),(4,''GO'',''GO''),(4,''GO'',''GO MINI''),(4,''GO'',''GO RESERVA'')'
WHEN @marca = 'G5' then '(1,''RESERVA, REVERSA, MINI E GO'',''RESERVA''),(1,''RESERVA, REVERSA, MINI E GO'',''REVERSA''),(1,''RESERVA, REVERSA, MINI E GO'',''MINI''),(1,''RESERVA, REVERSA, MINI E GO'',''GO''),(1,''RESERVA, REVERSA, MINI E GO'',''GO MINI''),(1,''RESERVA, REVERSA, MINI E GO'',''GO RESERVA''),
(2,''SIMPLES'',''SIMPLES''), (3,''MINI'',''MINI''), (4,''RESERVA'',''RESERVA'')'
WHEN @marca = 'G6' then '(1,''OFICINA, SIMPLES E INK'',''OFICINA''),(1,''OFICINA, SIMPLES E INK'',''SIMPLES''),(1,''OFICINA, SIMPLES E INK'',''INK''),
(2,''OFICINA E SIMPLES'',''OFICINA''),(2,''OFICINA E SIMPLES'',''SIMPLES'')'
ELSE @marca END

--G1 ('TODAS EX-BAW','REVERSA E GO','REVERSA E MINI','REVERSA')
--G2 ('TODAS','BAW','INK','RESERVA E GO')
--G3 ('RESERVA E REVERSA','OFICINA','RESERVA, REVERSA E GO','RESERVA, REVERSA E MINI')
--G4 ('RESERVA, REVERSA, MINI E GO','RESERVA, MINI E GO','REVERSA, MINI E GO','GO')
--G5 ('RESERVA, REVERSA, MINI E GO','SIMPLES','MINI','RESERVA')


DECLARE @Tabelamarca	VARCHAR(MAX) = '#marcas'
declare @query varchar(max) =
'INSERT INTO '+@Tabelamarca+' (id, Marcas,FilterMarcas)
VALUES '+@teste+'
'

exec(@query)

DECLARE @FirstDay INT = DAY(GETDATE())
-------------------------------------BLOCO DA CONDIÇÃO INCREMENTAL-------------------------------------
DECLARE @BASE_ATIVA DATETIME 
--
IF @TIPO = 'FULL'
BEGIN
SET @BASE_ATIVA = '20210201'
delete a from [dbo].[tbFatoLTVBaseAtiva] a with(nolock)
left join tbdimltv l on l.idltv = a.idltv
where (ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null
delete a from [dbo].[tbFatoLTVClientesNovos] a with(nolock)
left join tbdimltv l on l.idltv = a.idltv
where (ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null
delete a from [dbo].[tbFatoLTVClientesPerdidos] a with(nolock)
left join tbdimltv l on l.idltv = a.idltv
where (ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null
delete a from [dbo].[tbFatoLTVClientesReativados] a with(nolock)
left join tbdimltv l on l.idltv = a.idltv
where (ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null
delete a from [dbo].[tbFatoLTVClientesRetidos] a with(nolock)
left join tbdimltv l on l.idltv = a.idltv
where ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
END

ELSE
BEGIN 
SET @BASE_ATIVA = CASE WHEN @FirstDay = 1 then  dateadd(month,-1,convert(date,dateadd(month,1,dateadd(day, -DATEPART(day,getdate())+1,getdate()))))
else  convert(date,dateadd(month,1,dateadd(day, -DATEPART(day,getdate())+1,getdate()))) end
DELETE tbFatoLTVBaseAtiva FROM [dbo].[tbFatoLTVBaseAtiva]	BA WITH (NOLOCK)
left join tbdimltv l on l.idltv = ba.idltv
JOIN [dbo].[tbDimData]	DAT WITH (NOLOCK) ON DAT.IdData = BA.IdData
WHERE DAT.Data >= (@BASE_ATIVA-1) and ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
DELETE [tbFatoLTVClientesNovos] 
FROM [dbo].[tbFatoLTVClientesNovos]	CR	WITH (NOLOCK)
left join tbdimltv l on l.idltv = cr.idltv
JOIN [dbo].[tbDimData]					DAT WITH (NOLOCK) ON DAT.IdData = CR.IdData
WHERE DAT.Data >= (@BASE_ATIVA-1) and ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
DELETE [tbFatoLTVClientesPerdidos] 
FROM [dbo].[tbFatoLTVClientesPerdidos]	CR	WITH (NOLOCK)
left join tbdimltv l on l.idltv = cr.idltv
JOIN [dbo].[tbDimData]					DAT WITH (NOLOCK) ON DAT.IdData = CR.IdData
WHERE DAT.Data >= (@BASE_ATIVA-1) and ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
DELETE [tbFatoLTVClientesReativados] 
FROM [dbo].[tbFatoLTVClientesReativados]	CR	WITH (NOLOCK)
left join tbdimltv l on l.idltv = cr.idltv
JOIN [dbo].[tbDimData]					DAT WITH (NOLOCK) ON DAT.IdData = CR.IdData
WHERE DAT.Data >= (@BASE_ATIVA-1) and ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
DELETE [tbFatoLTVClientesRetidos] 
FROM [dbo].[tbFatoLTVClientesRetidos]	CR	WITH (NOLOCK)
left join tbdimltv l on l.idltv = cr.idltv
JOIN [dbo].[tbDimData]					DAT WITH (NOLOCK) ON DAT.IdData = CR.IdData
WHERE DAT.Data >= (@BASE_ATIVA-1) and ((ltvmarca in (select distinct marcas from #Marcas) and (LTVCanal in (select distinct canais from #Canais))) 
or ltvmarca is null or ltvcanal is null)
END
-----------------------------------FIM DO BLOCO-----------------------------------
-----------------------------------BLOCO FILIAIS VÁLIDAS-------------------------------------
SELECT DISTINCT CodFilial, Marca
INTO #FILIAL
FROM [RESERVA_DW].[dbo].[tbDimFilial] with(nolock)
--WHERE	Marca <> '(Não Informado)'
--		OR CodFilial IN  ('TSCR06','TSCRCD','TSCRCR','ARCD06')
-----------------------------------FIM DO BLOCO-----------------------------------

-------------------------------------INICIO DO INSERT NO WHILE -------------------------------------

DECLARE @DataBase DATE 

IF @FirstDay = 1
SET @DataBase =  DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0)
ELSE 
SET @DataBase =  DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())+1,0)



---------------------------BLOCO TEMPORÁRIA AUXILIAR DAS VENDAS-----------------------------------

select * INTO #AUX from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)

select * INTO #AUXfrqoff from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and canal in ('franquia sell out','offline')

select * INTO #AUXonoff from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and canal in ('offline','online')

select * INTO #AUXfrq from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and canal in ('franquia sell out')

select * INTO #AUXoff from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and canal in ('offline')

select * INTO #AUXon from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and canal in ('online')

select * INTO #AUXAPP from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and subcanal in ('APP')

select * INTO #AUXSITE from tbfatoltvtableauauxiliar
WHERE	data >= DATEADD(MONTH,-24,@BASE_ATIVA)
and subcanal in ('SITE')


select * into #auxltvstatus from  [dbo].[tbFatoLTVTableauStatus] 
where  datafim >= dateadd(day,-1,@BASE_ATIVA)
and Marca in (select Distinct FilterMarcas from #Marcas)


-----------------------------------INICIO DO LOOPING-----------------------------------
WHILE @BASE_ATIVA <= @DataBase--DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())+1,0) 
	BEGIN
		--DECLARE @cntCanal INT = 1
		--WHILE @cntCanal <= (select max(id) from #Canais)-------CONTADOR DE CANAL
		--	BEGIN
				DECLARE @cntMarca INT = 1
				WHILE @cntMarca <= (select max(id) from #Marcas)-------CONTADOR DE MARCA
					BEGIN

IF OBJECT_ID('tempdb..#auxstatus') IS NOT NULL
DROP TABLE #auxstatus
IF OBJECT_ID('tempdb..#auxstatusfrqoff') IS NOT NULL
DROP TABLE #auxstatusfrqoff
IF OBJECT_ID('tempdb..#auxstatusonoff') IS NOT NULL
DROP TABLE #auxstatusonoff
IF OBJECT_ID('tempdb..#auxstatusfrq') IS NOT NULL
DROP TABLE #auxstatusfrq
IF OBJECT_ID('tempdb..#auxstatusoff') IS NOT NULL
DROP TABLE #auxstatusoff
IF OBJECT_ID('tempdb..#auxstatuson') IS NOT NULL
DROP TABLE #auxstatuson
IF OBJECT_ID('tempdb..#auxstatusapp') IS NOT NULL
DROP TABLE #auxstatusapp
IF OBJECT_ID('tempdb..#auxstatussite') IS NOT NULL
DROP TABLE #auxstatussite
            
			select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatus from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatusfrqoff from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and Canal in ('offline','franquia sell out')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatusonoff from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and Canal in ('offline','online')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatusoff from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and Canal in ('offline')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatusfrq from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and Canal in ('franquia sell out')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatuson from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and Canal in ('online')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatusapp from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from [dbo].[tbFatoLTVTableauStatus] 
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and subcanal in ('APP')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a

						select A.*,   case when [BaseAtiva] = 'SIM' and [Base-1] = 'NAO' and [Base-2] = 'SIM' then  'SIM' else 'NAO' end  [Reativado]
			, case when [BaseAtiva] = 'NAO' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Perdido]
			, case when [BaseAtiva] = 'SIM' and [Base-1] = 'SIM'  then  'SIM' else 'NAO' end  [Retido]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'NAO'  and [BASEAntes13mes] = 'SIM' then  'SIM' else 'NAO' end  [ReativadoMes]
			, case when [BaseAtivaMes] = 'SIM' and [BASEAntes1mes] = 'SIM'   then  'SIM' else 'NAO' end  [RetidosMes]
			into #auxstatussite from 
			(
			select distinct codcliente, MAX(baseativa) baseativa,MAX([BaseAtivaMes])[BaseAtivaMes], MAX([Base-1])  [Base-1], MIN(Novo) Novo, MAX([Base-2])  [Base-2]
			  ,MIN(ClienteNovoMes) NovoMes,MAX([BASEAntes1mes])[BASEAntes1mes],MAX([BASEAntes13mes])[BASEAntes13mes]
			  from  #auxltvstatus
			where Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca) and subcanal in ('SITE')
			and datafim = dateadd(day,-1,@BASE_ATIVA)
			group by codcliente
			) a



IF OBJECT_ID('tempdb..#AUX1') IS NOT NULL
DROP TABLE #AUX1
IF OBJECT_ID('tempdb..#AUXfrqoff1') IS NOT NULL
DROP TABLE #AUXfrqoff1
IF OBJECT_ID('tempdb..#AUXonoff1') IS NOT NULL
DROP TABLE #AUXonoff1
IF OBJECT_ID('tempdb..#AUXfrq1') IS NOT NULL
DROP TABLE #AUXfrq1
IF OBJECT_ID('tempdb..#AUXoff1') IS NOT NULL
DROP TABLE #AUXoff1
IF OBJECT_ID('tempdb..#AUXon1') IS NOT NULL
DROP TABLE #AUXon1
IF OBJECT_ID('tempdb..#AUXapp1') IS NOT NULL
DROP TABLE #AUXapp1
IF OBJECT_ID('tempdb..#AUXsite1') IS NOT NULL
DROP TABLE #AUXsite1


select * INTO #AUX1 from #AUX
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXfrqoff1 from #AUXfrqoff
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXonoff1 from #AUXonoff
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXfrq1 from #AUXfrq
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXoff1 from #AUXoff
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXon1 from #AUXon
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXapp1 from #AUXapp
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

select * INTO #AUXsite1 from #AUXsite
WHERE	Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)





IF OBJECT_ID('tempdb..#auxfinal') IS NOT NULL

DROP TABLE #auxfinal

		select SQ.*, IdData, IdLTV into #auxfinal
FROM	(------------------------OFFLINE, FRANQUIA E ONLINE GERAL
		SELECT	Data							=	dateadd(day,-1,@BASE_ATIVA)
				,Canal							=	baseatual.Canal
				,Marca							=	(select Distinct Marcas from #Marcas where id = @cntMarca)
				,[Base Ativa Anterior]			=	BaseAnterior.Clientes
				,[Ativos Mes Anterior]			=	BaseAnterior.Clientes2
				,[Base Ativa Atual]				=	BaseAtual.Clientes
				,[Ativos Mes Atual]				=	MesAtual.Clientes
				------------------Quantidade de pedidos
				,[Qtde Pedidos Base Anterior]	=	BaseAnterior.QtdePedidos
				,[Qtde Pedidos Mes Anterior]	=	BaseAnterior.QtdePedidos2
				,[Qtde Pedidos Base Atual]		=	BaseAtual.QtdePedidos
				,[Qtde Pedidos Mes Atual]		=	MesAtual.QtdePedidos
				------------------Valores de venda
				,[Valor Base Anterior]			=	BaseAnterior.ValorVenda
				,[Valor Mes Anterior]			=	BaseAnterior.ValorVenda2
				,[Valor Base Atual]				=	BaseAtual.ValorVenda
				,[Valor Mes Atual]				=	MesAtual.ValorVenda
				------------------Frequencia Média
				,[Frequencia Anterior]			=	BaseAnterior.FreqAnterior
				,[Frequencia Mes Anterior]		=	BaseAnterior.FreqMAnterior2
				,[Frequencia Atual]				=	BaseAtual.FreqAtual
				,[Frequencia Mes Atual]			=	MesAtual.FreqMAtual
				------------------Ticket Médio
				,[Ticket Medio Anterior]		=	BaseAnterior.TMAnterior
				,[Ticket Medio Mes Anterior]	=	BaseAnterior.TMMAnterior2
				,[Ticket Medio Atual]			=	BaseAtual.TMAtual
				,[Ticket Medio Mes Atual]		=	MesAtual.TMMAtual
				--------------------------------------------------------------
				,Baseatual.ClientesNovos		
				,Baseatual.QtdePedidosNovos	
				,Baseatual.ValorVendaNovos		
				,Baseatual.FreqAtualNovos		
				,Baseatual.TMAtualNovos		
						        ----
				,Baseatual.ClientesRetidos		
				,Baseatual.QtdePedidosRetidos	
				,Baseatual.ValorVendaRetidos   
				,Baseatual.FreqAtualRetidos	
				,Baseatual.TMAtualRetidos		
						        ----
				,Baseatual.ClientesReativados	
				,Baseatual.QtdePedidosReativados
				,Baseatual.ValorVendaReativados
				,Baseatual.FreqAtualReativados	
				,Baseatual.TMAtualReativados	

				,Mesatual.ClientesNovos		     [ClientesNovosMes]	
				,Mesatual.QtdePedidosNovos		 [QtdePedidosNovosMes]	
				,Mesatual.ValorVendaNovos		 [ValorVendaNovosMes]		
				,Mesatual.FreqAtualNovos		 [FreqAtualNovosMes]		
				,Mesatual.TMAtualNovos			 [TMAtualNovosMes]		
						        ----			  ----
				,Mesatual.ClientesRetidos		 [ClientesRetidosMes]		
				,Mesatual.QtdePedidosRetidos	 [QtdePedidosRetidosMes]	
				,Mesatual.ValorVendaRetidos   	 [ValorVendaRetidosMes]   
				,Mesatual.FreqAtualRetidos		 [FreqAtualRetidosMes]	
				,Mesatual.TMAtualRetidos		 [TMAtualRetidosMes]		
						        ----			  ----
				,Mesatual.ClientesReativados	 [ClientesReativadosMes]	
				,Mesatual.QtdePedidosReativados	 [QtdePedidosReativadosMes]
				,Mesatual.ValorVendaReativados	 [ValorVendaReativadosMes]
				,Mesatual.FreqAtualReativados	 [FreqAtualReativadosMes]	
				,Mesatual.TMAtualReativados		 [TMAtualReativadosMes]

				,ClientesPerdidos	
				,QtdePedidosPerdidos	
				,ValorVendaPerdidos  
				,FreqAtualPerdidos   
				,TMAtualPerdidos	
				
				,ClientesPerdidosMes	    
				,QtdePedidosPerdidosMes	
				,ValorVendaPerdidosMes   
				,FreqAtualPerdidosMes    
				,TMAtualPerdidosMes		
		FROM	 (
				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Offline, Franquia e online'
				FROM #AUX1 a
				JOIN #auxstatus b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)
				
				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Offline e Online'
				FROM #AUXonoff1 a
				JOIN #auxstatusonoff b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Offline e Franquia'
				FROM #auxfrqoff1 a
				JOIN #auxstatusfrqoff b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Offline'
				FROM #AUXoff1 a
				JOIN #auxstatusoff b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Online'
				FROM #AUXon1 a
				JOIN #auxstatuson b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'Franquia'
				FROM #AUXfrq1 a
				JOIN #auxstatusfrq b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'APP'
				FROM #AUXapp1 a
				JOIN #auxstatusapp b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA

				UNION ALL 

				SELECT  Clientes		=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end),													
					    QtdePedidos	=	COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ),
					    ValorVenda		=	ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtual	=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativa = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtual		=	CASE WHEN COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativa = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativa = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when novo = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when novo = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when novo = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Retido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Retido] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Reativado] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Reativado] = 'sim' then a.CodVenda else null end ) END
							 --------------------------------------
							 ,canal = 'SITE'
				FROM #AUXsite1 a
				JOIN #auxstatussite b on b.codcliente = a.codcliente
				WHERE	data >= DATEADD(MONTH,-12,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				--datas da base ativa atual
				)  Baseatual
		LEFT JOIN
				(
				SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal ='Offline, Franquia e online'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'Offline, franquia e online'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

			UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'OFFLINE E FRANQUIA'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'OFFLINE E FRANQUIA'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'OFFLINE E ONLINE'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'OFFLINE E ONLINE'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'OFFLINE'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'OFFLINE'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'ONLINE'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'ONLINE'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'FRANQUIA'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'FRANQUIA'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'APP'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'APP'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				UNION ALL

			SELECT  Clientes		=	[Base Ativa Atual],
						QtdePedidos		=	[Qtde Pedidos Base Atual],
						ValorVenda		=	[Valor Base Atual],
						FreqAnterior	=	[Frequencia Atual],--CASE WHEN COUNT(DISTINCT CodCliente) IS NULL or COUNT(DISTINCT CodCliente) = 0 THEN 0 ELSE COUNT(DISTINCT CodVenda)*1.0/COUNT(DISTINCT CodCliente)*1.0 END,
						TMAnterior		=	[Ticket Medio Atual],-- CASE WHEN COUNT(DISTINCT CodVenda) IS NULL or  COUNT(DISTINCT CodVenda) = 0 THEN 0 ELSE SUM(ValorVenda)/COUNT(DISTINCT CodVenda) END
				        Clientes2		=	[Ativos Mes Atual],
				        QtdePedidos2	=	[Qtde Pedidos Mes Atual],
				        ValorVenda2		=	[Valor Mes Atual],
				        FreqMAnterior2	=	[Frequencia Mes Atual],  
				        TMMAnterior2	=	[Ticket Medio Mes Atual] 
						,canal = 'SITE'
				FROM [dbo].[tbFatoLTVBaseAtiva] a
				left join tbdimltv l on l.idltv = a.idltv
				left join tbDimData d on d.IdData = a.iddata 
				WHERE  Data = dateadd(year,-1,dateadd(day,-1,@BASE_ATIVA))
				AND LTVCanal = 'SITE'
				AND LtvMarca in (select Distinct Marcas from #Marcas where id = @cntMarca)

				) BaseAnterior  on	BaseAnterior.canal = Baseatual.canal
	 left join	(
				SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'Offline, Franquia e online'
			FROM #AUX1 a
				JOIN #auxstatus b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in (select Distinct FilterCanais from #Canais where id = @cntCanal)
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'offline e franquia'
			FROM #AUXfrqoff1 a
				JOIN #auxstatusfrqoff b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in ('offline','franquia sell out')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'offline e online'
			FROM #AUXonoff1 a
				JOIN #auxstatusonoff b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in ('offline','online')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'online'
			FROM #AUXon1 a
				JOIN #auxstatuson b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in ('online')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'franquia'
			FROM #AUXfrq1 a
				JOIN #auxstatusfrq b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in ('franquia sell out')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'offline'
			FROM #AUXoff1 a
				JOIN #auxstatusoff b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA
				--AND Canal in ('offline')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)
								UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'APP'
			FROM #AUXapp1 a
				JOIN #auxstatusapp b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA

												UNION ALL

SELECT  Clientes		    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end),													
					    QtdePedidos   	    =	COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ),
					    ValorVenda		    =	ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0),
					    FreqMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when baseativames = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMMAtual		    =	CASE WHEN COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when baseativames = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when baseativames = 'sim' then a.CodVenda else null end ) END	,	
								        --------------------------------------
					    ClientesNovos		=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end),													
					    QtdePedidosNovos	=	COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ),
					    ValorVendaNovos		=	ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualNovos		=	CASE WHEN COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when NovoMes = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when NovoMes = 'sim' then a.CodVenda else null end ) END	,		
								        --------------------------------------
					    ClientesRetidos		=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosRetidos	=	COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaRetidos   =	ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualRetidos	=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualRetidos		=	CASE WHEN COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [RetidosMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [RetidosMes] = 'sim' then a.CodVenda else null end ) END,
								        --------------------------------------
					    ClientesReativados	    =	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosReativados	=	COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ),
					    ValorVendaReativados    =	ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualReativados	    =	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualReativados		=	CASE WHEN COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [ReativadoMes] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [ReativadoMes] = 'sim' then a.CodVenda else null end ) END			
							 --------------------------------------
						--ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    --QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    --ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    --FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    --TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END
			           , canal = 'SITE'
			FROM #AUXsite1 a
				JOIN #auxstatussite b on b.codcliente = a.codcliente
				WHERE	 data >= DATEADD(MONTH,-1,@BASE_ATIVA ) AND data < @BASE_ATIVA

				--datas da base ativa atual
				) MesAtual on	MesAtual.canal = baseatual.canal
			LEFT JOIN
			( SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'Offline, Franquia e online'
				FROM #AUX1 a
				JOIN #auxstatus b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in (select Distinct FilterCanais from #Canais where id = @cntCanal)
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'offline e online'
				FROM #AUXonoff1 a
				JOIN #auxstatusonoff b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in ('offline','online')
			--	AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'offline e franquia'
				FROM #AUXfrqoff1 a
				JOIN #auxstatusfrqoff b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in ('offline','franquia sell out')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'offline'
				FROM #AUXoff1 a
				JOIN #auxstatusoff b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in ('offline')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'online'
				FROM #AUXon1 a
				JOIN #auxstatuson b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in ('online')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'franquia'
				FROM #AUXfrq1 a
				JOIN #auxstatusfrq b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )
				--AND Canal in ('franquia sell out')
				--AND Marca in (select Distinct FilterMarcas from #Marcas where id = @cntMarca)
				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'APP'
				FROM #AUXapp1 a
				JOIN #auxstatusapp b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )

				UNION ALL

				SELECT
				        ClientesPerdidos	    =	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end),													
					    QtdePedidosPerdidos	=	COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ),
					    ValorVendaPerdidos    =	ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidos    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidos		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' then a.CodVenda else null end ) END,
						ClientesPerdidosMes	    =	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end),													
					    QtdePedidosPerdidosMes	=	COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ),
					    ValorVendaPerdidosMes    =	ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0),
					    FreqAtualPerdidosMes    =	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end) = 0 THEN 0 ELSE COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end )*1.0/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodCliente else null end)*1.0 END,
					    TMAtualPerdidosMes		=	CASE WHEN COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) IS NULL OR COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) = 0 THEN 0 ELSE ISNULL(SUM(case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.ValorVenda else 0 end),0)/COUNT(DISTINCT case when [Perdido] = 'sim' and data >= DATEADD(MONTH,-13,@BASE_ATIVA) then a.CodVenda else null end ) END
			       ,canal = 'SITE'
				FROM #AUXsite1 a
				JOIN #auxstatussite b on b.codcliente = a.codcliente
				WHERE	 data  >= DATEADD(MONTH,-24,@BASE_ATIVA ) AND data < DATEADD(MONTH,-12,@BASE_ATIVA )

				--datas da base ativa atual
				)  Baseanteriorperdido on	Baseanteriorperdido.canal =  baseatual.canal 



		) SQ
LEFT JOIN tbDimLTV LTV WITH (NOLOCK)	ON	LTV.LTVCanal = Canal
										and LTV.LTVMarca = Marca
LEFT JOIN tbDimData DAT WITH (NOLOCK)	ON	DAT.Data = SQ.Data	





						 INSERT INTO [dbo].[tbFatoLTVBaseAtiva] (	[IdData]
											,[IdLTV]
											,[Base Ativa Anterior]		
											,[Ativos Mes Anterior]		
											,[Base Ativa Atual]			
											,[Ativos Mes Atual]			
											------------------Quantidade de pedidos
											,[Qtde Pedidos Base Anterior]
											,[Qtde Pedidos Mes Anterior]
											,[Qtde Pedidos Base Atual]
											,[Qtde Pedidos Mes Atual]
											------------------Valores de venda	
											,[Valor Base Anterior]	
											,[Valor Mes Anterior]	
											,[Valor Base Atual]	
											,[Valor Mes Atual]		
											------------------Frequencia Média
											,[Frequencia Anterior]		
											,[Frequencia Mes Anterior]	
											,[Frequencia Atual]			
											,[Frequencia Mes Atual]		
											------------------Ticket Médio
											,[Ticket Medio Anterior]	
											,[Ticket Medio Mes Anterior]
											,[Ticket Medio Atual]		
											,[Ticket Medio Mes Atual]	
											)
SELECT	  IdData
		,[IdLTV]
		,[Base Ativa Anterior]		
		,[Ativos Mes Anterior]		
		,[Base Ativa Atual]			
		,[Ativos Mes Atual]			
		------------------Quantidade de pedidos
		,[Qtde Pedidos Base Anterior]
		,[Qtde Pedidos Mes Anterior]
		,[Qtde Pedidos Base Atual]
		,[Qtde Pedidos Mes Atual]
		------------------Valores de venda
		,round([Valor Base Anterior],	2)	
		,round([Valor Mes Anterior],	2)	
		,round([Valor Base Atual],	2)	
		,round([Valor Mes Atual],	2)	
		------------------Frequencia Média
		,round([Frequencia Anterior],	2)		
		,round([Frequencia Mes Anterior],	2)	
		,round([Frequencia Atual],	2)			
		,round([Frequencia Mes Atual],	2)		
		------------------Ticket Médio
		,round([Ticket Medio Anterior],	2)	
		,round([Ticket Medio Mes Anterior],	2)
		,round([Ticket Medio Atual],	2)		
		,round([Ticket Medio Mes Atual],	2)
	from #auxfinal


	INSERT INTO [dbo].[tbFatoLTVClientesNovos] (	 
																		[IdData]						
																		,[IdLTV]							
																		,[ClientesNovos]			
																		,[ClientesNovosMes]			
																		,[Qtde Pedidos Novos Base]	
																		,[Qtde Pedidos Novos Mes]	
																		,[Valor Novos Base]			
																		,[Valor Novos Mes]			
																		,[Frequencia Novos Base]	
																		,[Frequencia Novos Mes]		
																		,[Ticket Medio Novos Base]	
																		,[Ticket Medio Novos Mes]	
																		)

						SELECT	  IdData
								,[IdLTV]
								,[ClientesNovos]
								,[ClientesNovosMes]
								, QtdePedidosNovos		 
								,[QtdePedidosNovosMes]	
								,  ValorVendaNovos		 
								,[ValorVendaNovosMes]	
								, FreqAtualNovos		 
								,[FreqAtualNovosMes]	
								,  TMAtualNovos			 
								,[TMAtualNovosMes]		
							FROM #auxfinal

INSERT INTO [dbo].[tbFatoLTVClientesPerdidos] (	 
										[IdData]						
										,[IdLTV]							
										,[ClientesPerdidos]			
										,[ClientesPerdidosMes]			
										,[Qtde Pedidos Perdidos Base]	
										,[Qtde Pedidos Perdidos Mes]	
										,[Valor Perdidos Base]			
										,[Valor Perdidos Mes]			
										,[Frequencia Perdidos Base]	
										,[Frequencia Perdidos Mes]		
										,[Ticket Medio Perdidos Base]	
										,[Ticket Medio Perdidos Mes]	
										)
						SELECT	  IdData
								,[IdLTV]
								,[ClientesPerdidos]
								,[ClientesPerdidosMes]
								, QtdePedidosPerdidos		 
								,[QtdePedidosPerdidosMes]	
								,  ValorVendaPerdidos		 
								,[ValorVendaPerdidosMes]	
								, FreqAtualPerdidos		 
								,[FreqAtualPerdidosMes]	
								,  TMAtualPerdidos			 
								,[TMAtualPerdidosMes]		
							FROM #auxfinal

INSERT INTO [dbo].[tbFatoLTVClientesReativados] (	 
											 [IdData]						
											,[IdLTV]							
											,[ClientesReativados]			
											,[ClientesReativadosMes]			
											,[Qtde Pedidos Reativados Base]	
											,[Qtde Pedidos Reativados Mes]	
											,[Valor Reativados Base]			
											,[Valor Reativados Mes]			
											,[Frequencia Reativados Base]	
											,[Frequencia Reativados Mes]		
											,[Ticket Medio Reativados Base]	
											,[Ticket Medio Reativados Mes]	
											)
						SELECT	  IdData
								,[IdLTV]
								,[ClientesReativados]
								,[ClientesReativadosMes]
								, QtdePedidosReativados		 
								,[QtdePedidosReativadosMes]	
								,  ValorVendaReativados		 
								,[ValorVendaReativadosMes]	
								, FreqAtualReativados	 
								,[FreqAtualReativadosMes]	
								,  TMAtualReativados	 
								,[TMAtualReativadosMes]		
							FROM #auxfinal																			

						INSERT INTO [dbo].[tbFatoLTVClientesRetidos] (	 
												[IdData]			
												,[IdLTV]				
												,[ClientesRetidos]	
												,[ClientesRetidosMes]
												,[Qtde Pedidos Retidos Base]	
												,[Qtde Pedidos Retidos Mes]	
												,[Valor Retidos Base]		
												,[Valor Retidos Mes]			
												,[Frequencia Retidos Base]	
												,[Frequencia Retidos Mes]	
												,[Ticket Medio Retidos Base]	
												,[Ticket Medio Retidos Mes]	
												)
						SELECT	  IdData
								,[IdLTV]
								,[ClientesRetidos]
								,[ClientesRetidosMes]
								, QtdePedidosRetidos		 
								,[QtdePedidosRetidosMes]	
								,  ValorVendaRetidos	 
								,[ValorVendaRetidosMes]	
								, FreqAtualRetidos	 
								,[FreqAtualRetidosMes]	
								,  TMAtualRetidos	 
								,[TMAtualRetidosMes]		
							FROM #auxfinal	

						SET @cntMarca = @cntMarca+1
					END
			--	SET @cntCanal = @cntCanal+1
			--END
		SET @BASE_ATIVA = DATEADD(MONTH, 1,@BASE_ATIVA)--ATUALIZANDO DATA CONDIÇÃO DO WHILE
	END
END
GO
