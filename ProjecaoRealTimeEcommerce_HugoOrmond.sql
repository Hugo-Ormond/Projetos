USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[p_AGG_PROJ_ECOM]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

















CREATE   PROCEDURE [dbo].[p_AGG_PROJ_ECOM] --8460

AS



declare @DATE_START DATETIME = GETDATE()	
declare @DATE_END DATETIME
	declare @ncarga int = ((select max([Nº Carga]) from [RESERVA_DW].[dbo].[LOG_FLOW_BI_ECOM]
				   where cod_proc like '%F%'))

declare @hoje Date			      = CASE WHEN datepart(hour,GETDATE()) between 1 and 6 then '1576-01-02'
                                    else CONVERT(DATE,dateadd(hour,-2,GETDATE())) END
declare @momentovendamax datetime = (select max([Momento Venda]) from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
WHERE Marca in ('reserva','mini','go reserva','go mini','reversa','go')
and Data = @hoje )



IF OBJECT_ID('tempdb..#tabelaprojecoes') IS NOT NULL

DROP TABLE #tabelaprojecoes
create table #tabelaprojecoes (hora int, proj float)


declare @hora int = 0
declare @horamax int = (select datepart(hour,@momentovendamax)-1)



WHILE @hora <= @horamax
	BEGIN

	
IF OBJECT_ID('tempdb..#aux') IS NOT NULL

DROP TABLE #aux

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda])) <= @hora then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda])) <= @hora then [valor colocado] else 0 end)
/sum([valor colocado]) as 'ating'
into #aux
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where data >= dateadd(day,-215, getdate())
and datepart(weekday,data) = datepart(weekday,@hoje)
and Data <> @hoje
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data


IF OBJECT_ID('tempdb..#auxstats') IS NOT NULL

DROP TABLE #auxstats 

select distinct  avg(ating) media
,stdev(ating) desvio into #auxstats 
from #aux


IF OBJECT_ID('tempdb..#auxlimpa') IS NOT NULL

DROP TABLE #auxlimpa 

select data,  venda, media, desvio,
(ating-media)/desvio zscore
, vendaate, ating
into #auxlimpa
from #aux a
left join #auxstats b on 1=1
where  desvio <> 0
and (ating-media)/desvio <= 1.5
and (ating-media)/desvio >= -0.75



IF OBJECT_ID('tempdb..#proj') IS NOT NULL

DROP TABLE #proj 

select  avg(ating) proj
into #proj
from
(
select data,  venda, vendaate, vendaate/venda ating from #auxlimpa
where venda <> 0
) b

insert into #tabelaprojecoes
(hora, proj)
select 
 hora = convert(varchar,@hora)
,proj = (select proj from #proj)


------------------------------

	SET @hora = @hora+1 
	END

	
	
IF OBJECT_ID('tempdb..#aux1') IS NOT NULL

DROP TABLE #aux1

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end)
/sum([valor colocado]) as 'ating'
into #aux1
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where data >= dateadd(day,-215, getdate())
and datepart(weekday,data) = datepart(weekday,@hoje)
and Data <> @hoje
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data



IF OBJECT_ID('tempdb..#auxstats1') IS NOT NULL

DROP TABLE #auxstats1 

select distinct  avg(ating) media
,stdev(ating) desvio into #auxstats1 
from #aux1


IF OBJECT_ID('tempdb..#auxlimpa1') IS NOT NULL

DROP TABLE #auxlimpa1 

select data,  venda, media, desvio,
(ating-media)/desvio zscore
, vendaate, ating
into #auxlimpa1
from #aux1 a
left join #auxstats1 b on 1=1
where  desvio <> 0
and (ating-media)/desvio <= 1.5
and (ating-media)/desvio >= -0.75



IF OBJECT_ID('tempdb..#proj1') IS NOT NULL

DROP TABLE #proj1 

select  avg(ating) proj
into #proj1
from
(
select data,  venda, vendaate, vendaate/venda ating from #auxlimpa1
where venda <> 0
) b


insert into #tabelaprojecoes
(hora, proj)
select 
 hora = convert(varchar,(select datepart(hour,@momentovendamax)))
,proj = (select proj from #proj1)


--------proj natal

IF OBJECT_ID('tempdb..#tabelaprojecoesnatal') IS NOT NULL

DROP TABLE #tabelaprojecoesnatal
create table #tabelaprojecoesnatal (hora int, proj float)


declare @horanatal int = 0
declare @horamaxnatal int = (select datepart(hour,@momentovendamax)-1)



WHILE @horanatal <= @horamaxnatal
	BEGIN

IF OBJECT_ID('tempdb..#auxnatal') IS NOT NULL

DROP TABLE #auxnatal

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda])) <= @horanatal then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda])) <= @horanatal then [valor colocado] else 0 end)
/sum([valor colocado]) as 'ating'
into #auxnatal
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where Data <> @hoje and
(
 Data = dateadd(YEAR,-1,@hoje)
or Data = dateadd(YEAR,-2,@hoje)
or Data = dateadd(YEAR,-3,@hoje)
or Data = dateadd(YEAR,-4,@hoje)
)
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data


IF OBJECT_ID('tempdb..#projnatal') IS NOT NULL

DROP TABLE #projnatal 

select  avg(ating) proj
into #projnatal
from
#auxnatal

insert into #tabelaprojecoesnatal
(hora, proj)
select 
 hora = convert(varchar,@horanatal)
,proj = (select proj from #projnatal)


	SET @horanatal = @horanatal+1 
	END



IF OBJECT_ID('tempdb..#aux1natal') IS NOT NULL

DROP TABLE #aux1natal

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end)
/sum([valor colocado]) as 'ating'
into #aux1natal
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where Data <> @hoje and
(
 Data = dateadd(YEAR,-1,@hoje)
or Data = dateadd(YEAR,-2,@hoje)
or Data = dateadd(YEAR,-3,@hoje)
or Data = dateadd(YEAR,-4,@hoje)
)
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data


IF OBJECT_ID('tempdb..#proj1natal') IS NOT NULL

DROP TABLE #proj1natal 

select  avg(ating) proj
into #proj1natal
from
#aux1natal


insert into #tabelaprojecoesnatal
(hora, proj)
select 
 hora = convert(varchar,(select datepart(hour,@momentovendamax)))
,proj = (select proj from #proj1natal)

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
/*
IF OBJECT_ID('tempdb..#tabelaprojecoesBF') IS NOT NULL

DROP TABLE #tabelaprojecoesBF
create table #tabelaprojecoesBF (hora int, proj float)


declare @horaBF int = 0
declare @horamaxBF int = (select datepart(hour,@momentovendamax)-1)



WHILE @horaBF <= @horamaxBF
	BEGIN

IF OBJECT_ID('tempdb..#auxBF') IS NOT NULL

DROP TABLE #auxBF

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda])) <= @horaBF then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda])) <= @horaBF then [valor colocado] else 0 end)
/sum([valor venda]) as 'ating'
into #auxBF
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where data = dateadd(day,-364, @hoje)
and Data <> @hoje
and datepart(weekday,data) = datepart(weekday,@hoje)
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data


insert into #tabelaprojecoesBF
(hora, proj)
select 
 hora = convert(varchar,@horaBF)
,proj = (select ating from #auxBF)


	SET @horaBF = @horaBF+1 
	END



IF OBJECT_ID('tempdb..#aux1BF') IS NOT NULL

DROP TABLE #aux1BF

 select
 data
,sum([valor colocado]) venda
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end) vendaate
,sum(case when (datepart(hour,[Momento Venda]) = datepart(hour,@momentovendamax)
           and datepart(minute,[Momento Venda]) <= datepart(minute,@momentovendamax))
		   or (datepart(hour,[Momento Venda]) < datepart(hour,@momentovendamax)) then [valor colocado] else 0 end)
/sum([valor venda]) as 'ating'
into #aux1BF
from tbfatoecommercevendaitemtableau a with(nolock)
left join tbdimdata d on d.iddata = a.iddata
left join tbdimmarca m on m.idmarca = a.idmarca
where data = dateadd(day,-364, @hoje)
and Data <> @hoje
and datepart(weekday,data) = datepart(weekday,@hoje)
and Marca in ('reserva','mini','go reserva','go mini','reversa','go')
group by data


insert into #tabelaprojecoesBF
(hora, proj)
select 
 hora = convert(varchar,(select datepart(hour,@momentovendamax)))
,proj = (select ating from #aux1BF)

*/




select * into #tabelaprojecoesfinaln
from
(
select * from #tabelaprojecoes
where not ((datepart(month,@hoje) = 12
and datepart(day,@hoje) in (24,25,31))
or (datepart(month,@hoje) = 1
and datepart(day,@hoje) in (01)))
UNION ALL
select * from #tabelaprojecoesnatal
where ((datepart(month,@hoje) = 12
and datepart(day,@hoje) in (24,25,31))
or (datepart(month,@hoje) = 1
and datepart(day,@hoje) in (01)))
) a



truncate table [dbo].[AGG_PROJ_ECOM]
insert into [dbo].[AGG_PROJ_ECOM]
(idhora, projecao)
select idhora, a.proj--, b.proj
from #tabelaprojecoesfinaln a
--left join #tabelaprojecoesBF b on b.hora = a.hora
left join tbdimhora  h with(nolock) on  h.codhora = a.hora
where h.hora <> '(Não Informado)'


  SET @DATE_END = GETDATE()
INSERT INTO [RESERVA_DW].[dbo].[LOG_FLOW_BI_ECOM]
(
 [COD_PROC]
,[NAME_PROC]
,[DATE_START]
,[DATA_END]
,[Nº Carga]
)
VALUES ('E35G4','[dbo].[p_AGG_PROJ_ECOM]',@DATE_START,@DATE_END,@ncarga)

 
 delete a from 
 [RESERVA_DW].[dbo].[LOG_FLOW_BI_ECOM] a
 where [DATE_START] <= convert(date,dateadd(day,-8,getdate()))



GO
