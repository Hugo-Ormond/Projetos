USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[UpCarga_AGG_VD_CN_FL_VDD_MC_DIA]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO































CREATE  PROCEDURE [dbo].[UpCarga_AGG_VD_CN_FL_VDD_MC_DIA]
AS
BEGIN



declare @data            Date			      = convert(date,dateadd(day,-1,getdate()))
declare @IniMes           Date		      = CONVERT(DATE,DATEADD(DAY,-1*(DATEPART(DAY,@data)-1),@data))
declare @FimMes           Date		      = DATEADD(DAY,-1,DATEADD(MONTH,1,@IniMes))
declare @IniMesPassado Date		  = DATEADD(month,-1,@inimes)
declare @IniMesPassado2 Date	  = DATEADD(month,-2,@inimes)
declare @FimMesPassado Date		  = DATEADD(DAY,-1,@inimes)
declare @FimMesPassado2 Date      = DATEADD(DAY,-1,@IniMesPassado)
-------------------------------------------------------------
declare @inimespassadogreg date   =  dateadd(year, -1, @IniMesPassado)
declare @inimespassado364 date    =  dateadd(day, -364, @IniMesPassado)
declare @fimmesgreg date          =  dateadd(year, -1, @fimmes)
declare @fimmes364 date           = dateadd(day, -364, @fimmes)
----------------------------------------------------------------------------------------------
declare @dataexclusao date = (CASE WHEN datepart(day,getdate()) <=  1 then @IniMes else @IniMes end)
declare @dataexclusaofim date = (CASE WHEN datepart(day,getdate()) <=  1 then @data else @data end)
declare @difdias int = datediff(day,@dataexclusao,@dataexclusaofim)+1 



select  distinct f.IdFilial idantigo, max(f2.idfilial) idnovo into #auxmudarfilial 
from  [reserva_ods].[dbo].[tbOdsLinxDeParaFiliais] a
left join tbdimfilial f with(nolock) on f.codfilial = a.codfilialantigo
left join tbdimfilial f2 with(nolock) on f2.codfilial = a.codfilialnovo
where f2.[Flag Atividade] = 'Ativa'
group by f.IdFilial





----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
select distinct idvendedor, [Válido p/ Top 20] = 'Sim' into #top20
from 
(
select distinct idvendedor, count(distinct(data)) dias, @difdias*0.7 corte
from
(select distinct idvendedor,  data,
sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end) valor_salao
   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal -- alteração hugo
left join tbdimfilial f on f.idfilial = a.idfilial
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
where data between @dataexclusao  and @dataexclusaofim
group by idvendedor, data) b
where valor_salao <> 0 and idvendedor <> 0
group by idvendedor
) c
where dias >= dias
----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
select distinct codfilial, [CPF], MAX(idvendedor) idvendedor into #dimvendedor from tbDimVendedor 
group by codfilial, [CPF]
----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select 
  Data                     = ISNULL(A.Data,ISNULL(B.Data,C.DATA))
 ,Codfilial                = ISNULL(A.Codfilial,ISNULL(B.Codfilial,C.Codfilial))
 ,CPFVendedor              = ISNULL(A.CPFVendedor,ISNULL(B.CPFVendedor,C.CPFVendedor))
 ,[MalasEnviadas]          = SUM(ISNULL(A.qtdetotal,0))
 ,[MalasConvertidas]	   = SUM(ISNULL(A.QtdeConvertida,0))
 ,[RONEnviados]	           = SUM(ISNULL(B.Qtde,0))
 ,[RONComVenda]	           = SUM(ISNULL(C.Qtde,0))
 ,[RONValor]	           = SUM(ISNULL(C.Valor,0))
into #dadosnow
from 
(
select distinct data, codfilial, cpfvendedor,
count(distinct(ticket)) QtdeTotal,
count(distinct(case when qtde > 0 and valor > 0 then ticket else null end)) QtdeConvertida
from
[RESERVA_ODS].[dbo].[tbOdsNowMalasEnviadas]
where  Data between @IniMesPassado and @FimMes
group by data, codfilial, cpfvendedor
) A
FULL OUTER JOIN
(
select distinct data, codfilial, cpfvendedor, sum(qtde) qtde from
[RESERVA_ODS].[dbo].[tbOdsNowRONEnviados]
where  Data between @IniMesPassado and @FimMes
group by data, codfilial, cpfvendedor
) B ON B.data = A.data 
   AND B.codfilial = a.codfilial
   AND B.CPFVendedor = a.cpfvendedor
FULL OUTER JOIN
(
select distinct convert(date,datacontato) Data, codfilial, cpfvendedor, count(distinct(ticket)) Qtde, sum(valor) Valor from 
[RESERVA_ODS].[dbo].[tbOdsNowGerouClientesOCC] a
left join tbDimAgendasNow ag on ag.TituloAgenda = a.TipoAgendaNow
where  Data between @IniMesPassado and @FimMes
and flagron = 'sim'
group by  convert(date,datacontato), codfilial, cpfvendedor
) C ON C.data = A.data 
   AND C.codfilial = a.codfilial
   AND C.CPFVendedor = a.cpfvendedor

 GROUP BY 
  ISNULL(A.Data,ISNULL(B.Data,C.DATA))
 ,ISNULL(A.Codfilial,ISNULL(B.Codfilial,C.Codfilial))
 ,ISNULL(A.CPFVendedor,ISNULL(B.CPFVendedor,C.CPFVendedor))


------------------------------------Novo Malas na Rua-----------------------------------------

select 
	Codfilial 	,
	[MalasRua]	   = ISNULL(count(numero_nf),0),
	Data = dateadd(d,-1,getdate())
into #malasrua
from  [RESERVA_ODS].[dbo].[tbOdsReservadoRua] a
left join reserva_dw..tbDimFilial f on f.FilialOriginal = a.FILIAL
where Previsao_retorno >= DATEADD(d,-1, getdate())
and tipo_reserva = 'RESERVADO MALA'
group by Codfilial

----------------------------------------------------------------------------------------------



 ----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select a.* into #pistolada from [reserva_ods].[dbo].[tbOdsLinxPistoladas] a
left join tbdimfilial f on f.CodFilial = a.codfilial
where Data between @IniMesPassado and @FimMes
and f.marca in ('RESERVA','RESERVA MINI','OFICINA RESERVA','REVERSA','GO')

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

declare @datacorner date = case when datepart(day,@data) < 2 then @IniMesPassado else @IniMes end



select distinct codfilial, [Possui Corner GO] = 'Sim' into #filialcornerGO from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'GO' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'GO'
group by a.codfilial
UNION ALL 
SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'GO' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilialPlanilha] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,'NF') <> 'GO'
group by a.codfilial
) a where meta > 0   

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--declare @datacorner date = case when datepart(day,@data) < 2 then @IniMesPassado else @IniMes end


select distinct codfilial, [Possui Corner] = 'Sim' into #filialcorner from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'RESERVA MINI' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'RESERVA MINI'
group by a.codfilial
UNION ALL
SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'RESERVA MINI' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilialPlanilha] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,'NF') <> 'RESERVA MINI'
group by a.codfilial
) a where meta > 0   

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--declare @datacorner date = case when datepart(day,@data) < 2 then @IniMesPassado else @IniMes end


select distinct codfilial, [Possui Corner Oficina] = 'Sim' into #filialcorneroficina from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'OFICINA RESERVA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'OFICINA RESERVA'
group by a.codfilial
UNION ALL
SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'OFICINA RESERVA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilialPlanilha] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,'NF') <> 'OFICINA RESERVA'
group by a.codfilial
) a where meta > 0   

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select distinct codfilial, [Possui Corner Reversa] = 'Sim' into #filialcornerreversa from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'REVERSA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'REVERSA'
group by a.codfilial
UNION ALL
SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'REVERSA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilialPlanilha] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,'NF') <> 'REVERSA'
group by a.codfilial
) a where meta > 0   

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select distinct codfilial, [Possui Corner Baw] = 'Sim' into #filialcornerbaw from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'BAW' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'BAW'
group by a.codfilial
) a where meta > 0   
----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select distinct codfilial, [Possui Corner Simples] = 'Sim' into #filialcornersimples from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'SIMPLES' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'SIMPLES'
group by a.codfilial
) a where meta > 0   

----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--INCLUSÃO DO BLOCO DE Corner Reserva -15-08-2023
select distinct codfilial, [Possui Corner Reserva] = 'Sim' into #filialcornerreserva 
from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'RESERVA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @datacorner and @FimMes and isnull(b.marca,a.letreiro) <> 'RESERVA'
group by a.codfilial
) a where meta > 0   

-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#tbmetas') IS NOT NULL

DROP TABLE #tbmetas
SELECT
 [Data] = ISNULL(metaatual.data, isnull(DATEADD(year,1,metagreg1.data), DATEADD(DAY,364,Meta364.Data)))
,[Idfilial] = ISNULL(metaatual.Idfilial, isnull(metagreg1.Idfilial, meta364.Idfilial))
,[Meta Atual] = CASE WHEN 
(CASE WHEN datepart(month,ISNULL(metaatual.data, isnull(DATEADD(year,1,metagreg1.data), DATEADD(DAY,364,Meta364.Data)))) = 1
and datepart(day,ISNULL(metaatual.data, isnull(DATEADD(year,1,metagreg1.data), DATEADD(DAY,364,Meta364.Data)))) = 1 then 0 else
ISNULL(Metaatual.[Meta Atual] , 0 ) END) <= 1 then 0
ELSE
(CASE WHEN datepart(month,ISNULL(metaatual.data, isnull(DATEADD(year,1,metagreg1.data), DATEADD(DAY,364,Meta364.Data)))) = 1
and datepart(day,ISNULL(metaatual.data, isnull(DATEADD(year,1,metagreg1.data), DATEADD(DAY,364,Meta364.Data)))) = 1 then 0 else
ISNULL(Metaatual.[Meta Atual] , 0 ) END)
END
,[Meta Greg (n-1)] = CASE WHEN ISNULL(metagreg1.[Meta Atual] , 0 ) <=1 then 0 else ISNULL(metagreg1.[Meta Atual] , 0 ) END
,[Meta 364 (n-1)] = CASE WHEN ISNULL(meta364.[Meta Atual]   , 0 ) <=1 then 0 else ISNULL(meta364.[Meta Atual]   , 0 ) END
INTO	#tbmetas
FROM
(
SELECT Data
      ,[IdFilial] 
      ,[Meta Atual]
  FROM [RESERVA_DW].[dbo].[tbFatoMetaFilialTableau] a WITH(NOLOCK)
  LEFT JOIN [RESERVA_DW].[dbo].[tbDimData] b WITH(NOLOCK) on b.iddata = a.iddata

  WHERE [Data] >= @IniMesPassado and [Data] <= @FimMes ) MetaAtual
FULL OUTER JOIN
(
SELECT Data
      ,[IdFilial] 
      ,[Meta Atual]
  FROM [RESERVA_DW].[dbo].[tbFatoMetaFilialTableau] a WITH(NOLOCK)

  LEFT JOIN [RESERVA_DW].[dbo].[tbDimData] b WITH(NOLOCK) on b.iddata = a.iddata
  WHERE [Data] >= @inimespassadogreg and [Data] <= @fimmesgreg ) MetaGreg1 on MetaGreg1.idfilial = MetaAtual.idfilial
                                                                     and DATEADD(year,1,metagreg1.data) = metaatual.data
FULL OUTER JOIN
(
SELECT Data
      ,[IdFilial] 
      ,[Meta Atual]
  FROM [RESERVA_DW].[dbo].[tbFatoMetaFilialTableau] a WITH(NOLOCK)

  LEFT JOIN [RESERVA_DW].[dbo].[tbDimData] b WITH(NOLOCK) on b.iddata = a.iddata
  WHERE [Data] >= @inimespassado364 and [Data] <= @fimmes364 ) Meta364 on Meta364.idfilial = MetaAtual.idfilial
                                                                     and DATEADD(DAY,364,Meta364.Data) = metaatual.data



----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#atividadefilial') IS NOT NULL

DROP TABLE #atividadefilial

select distinct  idfilial, Atividade = 'Ativa'--, datainifilial = MIN(data), datafimfilial = MAX(data)
into #atividadefilial 
from #tbmetas
where [Meta Atual] <> 0 
and Data between @dataexclusao and @dataexclusaofim
group by idfilial
UNION
select distinct idfilial, Atividade = 'Ativa' from tbDimFilial
where SupervisorAtual <> '(Não Informado)' and [Flag Atividade] = 'Ativa'



----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

select data, idcanal, IdCanalNegocio, idfilial, idvendedor, Supervisor, [Flag Atividade],[Franqueado], [Cancelado último dia Plano B], [Cancelado último dia STV]
into #auxcancelados
from (
select convert(date,@fimmespassado) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial] 
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,Supervisor = [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a 
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado) and IdTabela = '1'
and d1.Data between @IniMesPassado and @FimMesPassado
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]  
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	   --,ma.[IdMarca]


UNION ALL 


select convert(date,@fimmespassado2) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial]  
	   ,Supervisor = [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado2) and IdTabela = '1'
and d1.Data between @IniMesPassado2 and @FimMesPassado2
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	   --,ma.[IdMarca]


UNION ALL 


select convert(date,@fimmes) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial]  
	   ,Supervisor = [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @FimMes) and IdTabela = '1'
and d1.Data between @IniMes and @fimmes
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	   --,ma.[IdMarca]

UNION ALL 

select  dateadd(day,1,convert(date,@fimmespassado)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial]  
	   ,Supervisor = [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = -1*sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = -1*sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	   --,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado) and IdTabela = '1'
and d1.Data between @IniMesPassado and @FimMesPassado
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
      -- ,[IdMarcaComercial] 
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	  -- ,ma.[IdMarca]

UNION ALL 

select  dateadd(day,1,convert(date,@fimmespassado2)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,Supervisor =        [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = -1*sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = -1*sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	   --,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado2) and IdTabela = '1'
and d1.Data between @IniMesPassado2 and @FimMesPassado2
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       , a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial]   
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	   --,ma.[IdMarca]
	   
UNION ALL 

select  dateadd(day,1,convert(date,@fimmes)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial] 
	   ,Supervisor =        [SupervisorAtual]
	   ,[Flag Atividade] = [Atividade]
	   ,[Franqueado]
	   ,[Cancelado último dia Plano B]             = -1*sum(Case when MeioVenda = 'plano b' then [Valor Cancelado] else 0 end)
	   ,[Cancelado último dia STV]                 = -1*sum(Case when promotorvenda = 'stv' then [Valor Cancelado] else 0 end)
	   --,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbdimfilial f on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmes) and IdTabela = '1'
and d1.Data between @inimes and @fimmes
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       , a.[IdFilial]   
       ,[IdVendedor] 
       --,[IdMarcaComercial]   
	   ,[SupervisorAtual], [Atividade],[Franqueado]
	   --,ma.[IdMarca]

	   ) c
--left join tbdimdata d1 on d1.data = c.Data
where [Cancelado último dia Plano B] <> 0 or [Cancelado último dia STV] <> 0

---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#auxsss') IS NOT NULL
drop table #auxsss

select a.*, status = 'Inválida' into #auxsss from (
select distinct datepart(month,data) mes, idfilial, count(distinct(data)) dias from #tbmetas
where  [meta atual] <> 0 and (CASE WHEN [meta 364 (n-1)] = 0 then [meta greg (n-1)] ELSE [meta 364 (n-1)] END) <> 0
group by datepart(month,data), idfilial) a
where dias < 20

---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


select idticket, troca = 'Sim', sum([valor venda]) valor,
[Troca com Dif] = case when sum([valor venda]) <> 0 then 'Sim' else 'Não' end
into #ticketstroca 
from tbfatovendaitemtableau a
where idticket in 
(
select distinct idticket
from tbfatovendaitemtableau a
left join tbdimcanalnegocio c on c.idcanalnegocio = a.idcanalnegocio
left join tbdimdata d on d.iddata = a.iddata
where data >= @dataexclusao  
and [Quantidade Troca] <> 0
and canalnegocio in ('offline','franquia sell out')
and IdTicket <> 0
) 
group by idticket

---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------

select distinct idcliente, novoprime = 'Não' into #clantigosprime
from tbFatoVendaItemTableau a with(nolock)
left join tbDimData d with(nolock) on d.IdData = a.iddata
left join tbDimProdutos p with(nolock) on p.IdProdutos = a.IdProdutos
left join tbDimAssinatura ass with(nolock) on ass.IdAssinatura = a.IdAssinatura
where [Data] < @dataexclusao and 
(assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%' or
Produto like '%OFICINA PRIME%' or
Produto like '%RESERVA PRIME%' )


----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

DELETE a from  [dbo].[AGG_VD_CN_FL_VDD_MC_DIA]  a 
left join tbdimdata d on d.iddata = a.IdData
where Data >= @dataexclusao



INSERT INTO [dbo].[AGG_VD_CN_FL_VDD_MC_DIA]  (         [IdData] 
	                                                  ,[IdCanal] 
	                                                  ,[IdCanalNegocio] 
	                                                  ,[IdFilial] 
	                                                  ,[IdVendedor] 
	                                                  --,[IdMarca] 
													  --,[idmarca2]
	                                                  ,[Venda Atual - Plano B] 				
	                                                  ,[Venda Atual - Salão] 					
	                                                  ,[Venda Atual - STV] 					
	                                                  ,[Venda Atual - Mala] 					
	                                                  ,[Venda Atual Greg SSS - Total] 			
	                                                  ,[Venda Atual 364 SSS - Total]		    
	                                                  ,[Venda 364 SSS - Total]				    
	                                                  ,[Venda Greg SSS - Total]	
					                                  ,[Venda 364 - Total]				    
	                                                  ,[Venda Greg - Total]	
	                                                  ,[Cancelado Delivery] 					
	                                                  ,[Cancelado último dia Plano B]			
	                                                  ,[Cancelado último dia STV]			    
	                                                  ,[Número de Peças] 						
	                                                  ,[Número de Tickets] 	
													  ,[Número de Tickets - Reserva]
													  ,[Número de Tickets - Reversa] 
													  ,[Número de Tickets - Baw]
													  ,[Número de Tickets - Mini]
													  ,[Número de Tickets - Oficina]
													  ,[Número de Tickets - Simples]
													  ,[Número de Tickets - Go]
													  ,[Meta Filial]
													  ,[Meta Vendedor]
													  ,[Venda Atual - Corner]          
													  ,[Venda Atual Greg SSS - Corner] 
													  ,[Venda Atual 364 SSS - Corner]	
													  ,[Venda 364 SSS - Corner]		
													  ,[Venda Greg SSS - Corner]		
													  ,[Venda 364 - Corner]			
													  ,[Venda Greg - Corner]	
													  ,[Número de Peças - Corner]  
													  ,[Número de Tickets - Corner]
													  ,[Possui Corner]
													 -- ,[Número de Peças - Digital] 
                                                     -- ,[Número de Peças - Loja]
                                                     -- ,[Número de Tickets - Digital] 
                                                     -- ,[Número de Tickets - Loja]    
													 ,[Número de Peças 364]       
													 ,[Número de Tickets 364]
													 ,[Número de Tickets 364 - Reserva]
													 ,[Número de Tickets 364 - Reversa]
													 ,[Número de Tickets 364 - Baw]
													 ,[Número de Tickets 364 - Mini]
													 ,[Número de Tickets 364 - Oficina]
													 ,[Número de Tickets 364 - Simples]
													 ,[Número de Tickets 364 - Go]
													 ,[Número de Peças Greg]      
													 ,[Número de Tickets Greg]
													 ,[Número de Tickets Greg - Reserva]
													 ,[Número de Tickets Greg - Reversa]
													 ,[Número de Tickets Greg - Baw]
													 ,[Número de Tickets Greg - Mini]
													 ,[Número de Tickets Greg - Oficina]
													 ,[Número de Tickets Greg - Simples]
													 ,[Número de Tickets Greg - Go]
													 ,[Número de Peças 364 SSS]   
													 ,[Número de Tickets 364 SSS]
													 ,[Número de Tickets 364 SSS - Reserva]
													 ,[Número de Tickets 364 SSS - Reversa]
													 ,[Número de Tickets 364 SSS - Baw]
													 ,[Número de Tickets 364 SSS - Mini]
													 ,[Número de Tickets 364 SSS - Oficina]
													 ,[Número de Tickets 364 SSS - Simples]
													 ,[Número de Tickets 364 SSS - Go]
													 ,[Número de Peças Greg SSS]  
													 ,[Número de Tickets Greg SSS]
													 ,[Número de Tickets Greg SSS - Reserva]
													 ,[Número de Tickets Greg SSS - Reversa]
													 ,[Número de Tickets Greg SSS - Baw]
													 ,[Número de Tickets Greg SSS - Mini]
													 ,[Número de Tickets Greg SSS - Oficina]
													 ,[Número de Tickets Greg SSS - Simples]
													 ,[Número de Tickets Greg SSS - Go]
													 ,[Número de Peças Atual 364 SSS]    
													 ,[Número de Tickets Atual 364 SSS]  
													 ,[Número de Tickets Atual 364 SSS - Reserva]
													 ,[Número de Tickets Atual 364 SSS - Reversa]
													 ,[Número de Tickets Atual 364 SSS - Baw]
													 ,[Número de Tickets Atual 364 SSS - Mini]
													 ,[Número de Tickets Atual 364 SSS - Oficina]
													 ,[Número de Tickets Atual 364 SSS - Simples]
													 ,[Número de Tickets Atual 364 SSS - Go]
													 ,[Número de Peças Atual Greg SSS]   
													 ,[Número de Tickets Atual Greg SSS] 
													 ,[Número de Tickets Atual Greg SSS - Reserva]
													 ,[Número de Tickets Atual Greg SSS - Reversa]
													 ,[Número de Tickets Atual Greg SSS - Baw]
													 ,[Número de Tickets Atual Greg SSS - Mini]
													 ,[Número de Tickets Atual Greg SSS - Oficina]
													 ,[Número de Tickets Atual Greg SSS - Simples]
													 ,[Número de Tickets Atual Greg SSS - Go]
													 ,[SEM TROCA E CS - Número de Peças] 
													 ,[SEM TROCA E CS - Número de Tickets]
													 ,[SEM TROCA E CS - Número de Peças 364]       
													 ,[SEM TROCA E CS - Número de Tickets 364]     
													 ,[SEM TROCA E CS - Número de Peças Greg]      
													 ,[SEM TROCA E CS - Número de Tickets Greg]    
													 ,[SEM TROCA E CS - Número de Peças 364 SSS]   
													 ,[SEM TROCA E CS - Número de Tickets 364 SSS] 
													 ,[SEM TROCA E CS - Número de Peças Greg SSS]  
													 ,[SEM TROCA E CS - Número de Tickets Greg SSS]
													 ,[SEM TROCA E CS - Número de Peças Atual 364 SSS]    
													 ,[SEM TROCA E CS - Número de Tickets Atual 364 SSS]  
													 ,[SEM TROCA E CS - Número de Peças Atual Greg SSS]   
													 ,[SEM TROCA E CS - Número de Tickets Atual Greg SSS] 
													 ,[20 dias ou mais de SSSG]
													 ,[Supervisor]    
													 ,[Flag Atividade]
													 ,[Venda Atual - Delivery]         
													 ,[Venda Atual Greg SSS - Delivery]
													 ,[Venda Atual 364 SSS - Delivery] 
													 ,[Venda Atual Greg SSS - Salão]   
													 ,[Venda Atual 364 SSS - Salão]    
													 ,[Venda Atual Greg SSS - Plano B] 
													 ,[Venda Atual 364 SSS - Plano B]  
													 ,[Venda Atual Greg SSS - STV]     
													 ,[Venda Atual 364 SSS - STV]      
													 ,[Venda Atual Greg SSS - Mala]    
													 ,[Venda Atual 364 SSS - Mala]     
													 ,[Venda Greg SSS - Delivery]      
													 ,[Venda 364 SSS - Delivery]       
													 ,[Venda Greg SSS - Salão]         
													 ,[Venda 364 SSS - Salão]          
													 ,[Venda Greg SSS - Plano B]       
													 ,[Venda 364 SSS - Plano B]        
													 ,[Venda Greg SSS - STV]           
													 ,[Venda 364 SSS - STV]            
													 ,[Venda Greg SSS - Mala]          
													 ,[Venda 364 SSS - Mala]           
													 ,[Número de Peças - Delivery]     
													 ,[Número de Tickets - Delivery]   
													 ,[Número de Peças - Salão]        
													 ,[Número de Tickets - Salão]      
													 ,[Número de Peças - Plano B]      
													 ,[Número de Tickets - Plano B]    
													 ,[Número de Peças - STV]          
													 ,[Número de Tickets - STV]        
													 ,[Número de Peças - Mala]         
													 ,[Número de Tickets - Mala]   
													 ,[Venda Greg - Delivery]
													 ,[Venda 364 - Delivery] 
													 ,[Venda Greg - Salão]   
													 ,[Venda 364 - Salão]    
													 ,[Venda Greg - Plano B] 
													 ,[Venda 364 - Plano B]  
													 ,[Venda Greg - STV]     
													 ,[Venda 364 - STV]      
													 ,[Venda Greg - Mala]    
													 ,[Venda 364 - Mala]     
													 ,[Número de Peças - Cuecas]        
													 ,[Número de Peças - Assinaturas]
													 ,[Número de Tickets - Cross Sell]  
													 ,[Número de Tickets - Cuecas]
													 ,[Número de Tickets - Assinaturas]
													 ,[Venda Atual - Cross Sell]  
													 ,[Venda Atual - Corner Reversa]
													 ,[Venda Atual Greg SSS - Corner Reversa] 
													 ,[Venda Atual 364 SSS - Corner Reversa]
													 ,[Venda 364 SSS - Corner Reversa]
													 ,[Venda Greg SSS - Corner Reversa]
													 ,[Venda 364 - Corner Reversa]
													 ,[Venda Greg - Corner Reversa] 
													 ,[Número de Peças - Corner Reversa]
													 ,[Número de Tickets - Corner Reversa] 
													 ,[Possui Corner Reversa]
													 ,[Válido p/ Top 20]
													 ,[Venda Atual - Mala Corner Reversa]
													 ,[Venda Atual - Mala Corner Mini]
													 ,[Possui Corner Baw]
													 ,[Possui Corner Reserva]
													 ,[Possui Corner Simples]
													 ,[Venda Atual - Corner Baw]             
													 ,[Venda Atual Greg SSS - Corner Baw]    
													 ,[Venda Atual 364 SSS - Corner Baw]	    
													 ,[Venda 364 SSS - Corner Baw]		    
													 ,[Venda Greg SSS - Corner Baw]		    
													 ,[Venda 364 - Corner Baw]			    
													 ,[Venda Greg - Corner Baw] 			    
													 ,[Número de Peças - Corner Baw]		    
													 ,[Número de Tickets - Corner Baw] 	
													 ,[Venda Atual - Corner Reserva]             
													 ,[Venda Atual Greg SSS - Corner Reserva]    
													 ,[Venda Atual 364 SSS - Corner Reserva]	    
													 ,[Venda 364 SSS - Corner Reserva]		    
													 ,[Venda Greg SSS - Corner Reserva]		    
													 ,[Venda 364 - Corner Reserva]			    
													 ,[Venda Greg - Corner Reserva] 			    
													 ,[Número de Peças - Corner Reserva]		    
													 ,[Número de Tickets - Corner Reserva] 	  
													 ,[Venda Atual - Corner Simples]         
													 ,[Venda Atual Greg SSS - Corner Simples]
													 ,[Venda Atual 364 SSS - Corner Simples]	
													 ,[Venda 364 SSS - Corner Simples]		
													 ,[Venda Greg SSS - Corner Simples]		
													 ,[Venda 364 - Corner Simples]			
													 ,[Venda Greg - Corner Simples] 			
													 ,[Número de Peças - Corner Simples]		
													 ,[Número de Tickets - Corner Simples] 	
													 ,[Venda Atual - Mala Corner Baw]   
													  ,[Venda Atual - Mala Corner Reserva]   
					                                 ,[Venda Atual - Mala Corner Simples]
													 ,[Número de Tickets Troca]  
													 ,[Valor Troca Atual]		
													 ,[Número de Tickets Troca com Dif] 
													 ,[Valor Troca Atual com Dif]	
													 ,[Malas Enviadas]   
													 ,[Malas Convertidas]
													 ,[RON Enviados]   
													 ,[RON com Venda]
													 ,[RON Valor]
													 ,[Número de Tickets - Pistoladas]
													 ,[Venda Atual Greg SSS- Cross Sell] 
													 ,[Venda Atual 364 SSS- Cross Sell] 
													 ,[Venda Greg SSS - Cross Sell]
													 ,[Venda 364 SSS - Cross Sell]
													 ,[Venda Greg - Cross Sell]
													 ,[Venda 364 - Cross Sell] 
													 ,[Número de Peças Atual Greg SSS- Cuecas] 
													 ,[Número de Peças Atual 364 SSS- Cuecas] 
													 ,[Número de Peças Greg SSS - Cuecas] 
													 ,[Número de Peças 364 SSS - Cuecas] 
													 ,[Número de Peças Greg - Cuecas] 
													 ,[Número de Peças 364 - Cuecas] 
													 ,[Número de Peças Atual Greg SSS- Assinaturas]
													 ,[Número de Peças Atual 364 SSS- Assinaturas] 
													 ,[Número de Peças Greg SSS - Assinaturas] 
													 ,[Número de Peças 364 SSS - Assinaturas] 
													 ,[Número de Peças Greg - Assinaturas]
													 ,[Número de Peças 364 - Assinaturas] 
													 ,[Número de Tickets Offline Sem Troca] 
													 ,[Número de Peças - Oculos]
													 ,[Flag Atividade Vendedor]
													 ,[Franqueado]
													 ,[Possui Corner GO]
													 ,[Número de Peças - Meia]   
													 ,[Venda Atual - Corner Go]          
													 ,[Venda Atual Greg SSS - Corner Go] 
													 ,[Venda Atual 364 SSS - Corner Go]	
													 ,[Venda 364 SSS - Corner Go]		
													 ,[Venda Greg SSS - Corner Go]		
													 ,[Venda 364 - Corner Go]			
													 ,[Venda Greg - Corner Go] 			
													 ,[Número de Peças - Corner Go]		
													 ,[Número de Tickets - Corner Go] 	
													 ,[Venda Atual - Mala Corner Go]   
													 ,[Venda Atual - Plano B Corner Reversa]	
													  ,[Venda Atual - Plano B Corner Baw]
													  ,[Venda Atual - Plano B Corner Reserva]
													  ,[Venda Atual - Plano B Corner Go]		
													  ,[Venda Atual - Plano B Corner Simples]	
													  ,[Venda Atual - Plano B Corner Mini]	
													  ,[Venda Atual - Salão Corner Reversa]	
													  ,[Venda Atual - Salão Corner Baw]	
													   ,[Venda Atual - Salão Corner Reserva]	
													  ,[Venda Atual - Salão Corner Go]		
													  ,[Venda Atual - Salão Corner Simples]	
													  ,[Venda Atual - Salão Corner Mini]		
													  ,[Venda Atual - STV Corner Reversa]		
													  ,[Venda Atual - STV Corner Baw]	
													  ,[Venda Atual - STV Corner Reserva]
													  ,[Venda Atual - STV Corner Go]			
													  ,[Venda Atual - STV Corner Simples]		
													  ,[Venda Atual - STV Corner Mini]		
													  ,[Venda Atual - Delivery Corner Reversa]
													  ,[Venda Atual - Delivery Corner Baw]	
													  ,[Venda Atual - Delivery Corner Reserva]	
													  ,[Venda Atual - Delivery Corner Go]		
													  ,[Venda Atual - Delivery Corner Simples]
													  ,[Venda Atual - Delivery Corner Mini]
													  ,[Venda Atual - Delivery Corner Oficina]
													  ,[Venda Atual - STV Corner Oficina]
                                                      ,[Venda Atual - Salão Corner Oficina]
                                                      ,[Venda Atual - Plano B Corner Oficina] 
													  ,[Venda Atual - Mala Corner Oficina] 
													  ,[Possui Corner Oficina]
													  ,[Venda Atual - Corner Oficina]          
													  ,[Venda Atual Greg SSS - Corner Oficina] 
													  ,[Venda Atual 364 SSS - Corner Oficina]	
													  ,[Venda 364 SSS - Corner Oficina]		
													  ,[Venda Greg SSS - Corner Oficina]		
													  ,[Venda 364 - Corner Oficina]			
													  ,[Venda Greg - Corner Oficina] 			
													  ,[Número de Peças - Corner Oficina]		
													  ,[Número de Tickets - Corner Oficina] 	
													  ,[Número de Tickets - Meia]
													  ,[Número de Peças Atual Greg SSS- Meia]
													  ,[Número de Peças Atual 364 SSS- Meia] 
													  ,[Número de Peças Greg SSS - Meia] 
													  ,[Número de Peças 364 SSS - Meia] 
													  ,[Número de Peças Greg - Meia] 
													  ,[Número de Peças 364 - Meia] 
													  ,[Número de Tickets - Novas Assinaturas]
													  -- Inclusão de novos campos para as métricas dos óculos
													  ,[Número de Tickets - Oculos]           
													  ,[Número de Peças Atual Greg SSS- Oculos]         
													  ,[Número de Peças Atual 364 SSS- Oculos]  			 
													  ,[Número de Peças Greg SSS - Oculos] 				 
													  ,[Número de Peças 364 SSS - Oculos] 			
													  ,[Número de Peças Greg - Oculos] 		
													  ,[Número de Peças 364 - Oculos] 
													  ,[Gerente Comercial]
													  ,[Pedidos BOPIS/Ship To (Entregue)]
													  ,[MalasRua]



											)



Select  
                        ISNULL([IdData]          , 0)
	                   ,ISNULL([IdCanal] 		 , 0)
	                   ,ISNULL([IdCanalNegocio]  , 0)
	                   ,ISNULL(B.[IdFilial] 		 , 0)
	                   ,ISNULL(B.[IdVendedor] 	 , 0)
	                   --,ISNULL([IdMarca] 		 , 0)
					  -- ,ISNULL([IdMarca2] 		 , 0)
					   ,[Venda Atual - Plano B] 				
	                   ,[Venda Atual - Salão] 					
	                   ,[Venda Atual - STV] 					
	                   ,[Venda Atual - Mala] 					
	                   ,[Venda Atual Greg SSS - Total] 			
	                   ,[Venda Atual 364 SSS - Total]		    
	                   ,[Venda 364 SSS - Total]				    
	                   ,[Venda Greg SSS - Total]	
					   ,[Venda 364 - Total]				    
	                   ,[Venda Greg - Total]	
	                   ,[Cancelado Delivery] 					
	                   ,[Cancelado último dia Plano B]			
	                   ,[Cancelado último dia STV]			    
	                   ,[Número de Peças] 						
	                   ,[Número de Tickets] 
					   ,[Número de Tickets - Reserva]
					   ,[Número de Tickets - Reversa]
					   ,[Número de Tickets - Baw]
					   ,[Número de Tickets - Mini]
					   ,[Número de Tickets - Oficina]
					   ,[Número de Tickets - Simples]
					   ,[Número de Tickets - Go]
					   ,[Meta Filial]
					   ,[Meta Vendedor]
					   ,[Venda Atual - Corner]          
					   ,[Venda Atual Greg SSS - Corner] 
					   ,[Venda Atual 364 SSS - Corner]	
					   ,[Venda 364 SSS - Corner]		
					   ,[Venda Greg SSS - Corner]		
					   ,[Venda 364 - Corner]			
					   ,[Venda Greg - Corner]	
					   ,[Número de Peças - Corner]  
					   ,[Número de Tickets - Corner]
					   ,isnull([Possui Corner], 'Não')
					  -- ,[Número de Peças - Digital] 
                      -- ,[Número de Peças - Loja]
                      -- ,[Número de Tickets - Digital] 
                      -- ,[Número de Tickets - Loja] 
					      
					  ,[Número de Peças 364]       
					  ,[Número de Tickets 364]     
					  ,[Número de Tickets 364 - Reserva]
					  ,[Número de Tickets 364 - Reversa]
					  ,[Número de Tickets 364 - Baw]
					  ,[Número de Tickets 364 - Mini]
					  ,[Número de Tickets 364 - Oficina]
					  ,[Número de Tickets 364 - Simples]
					  ,[Número de Tickets 364 - Go]
					  ,[Número de Peças Greg]      
					  ,[Número de Tickets Greg]
					  ,[Número de Tickets Greg - Reserva]
					  ,[Número de Tickets Greg - Reversa]
					  ,[Número de Tickets Greg - Baw]
					  ,[Número de Tickets Greg - Mini]
					  ,[Número de Tickets Greg - Oficina]
					  ,[Número de Tickets Greg - Simples]
					  ,[Número de Tickets Greg - Go]
					  ,[Número de Peças 364 SSS]   
					  ,[Número de Tickets 364 SSS]
					  ,[Número de Tickets 364 SSS - Reserva]
					  ,[Número de Tickets 364 SSS - Reversa]
					  ,[Número de Tickets 364 SSS - Baw]
					  ,[Número de Tickets 364 SSS - Mini]
					  ,[Número de Tickets 364 SSS - Oficina]
					  ,[Número de Tickets 364 SSS - Simples]
					  ,[Número de Tickets 364 SSS - Go]
					  ,[Número de Peças Greg SSS]  
					  ,[Número de Tickets Greg SSS]
					  ,[Número de Tickets Greg SSS - Reserva]
					  ,[Número de Tickets Greg SSS - Reversa]
					  ,[Número de Tickets Greg SSS - Baw]
					  ,[Número de Tickets Greg SSS - Mini]
					  ,[Número de Tickets Greg SSS - Oficina]
					  ,[Número de Tickets Greg SSS - Simples]
					  ,[Número de Tickets Greg SSS - Go]

					  ,[Número de Peças Atual 364 SSS]    
					  ,[Número de Tickets Atual 364 SSS]
					  ,[Número de Tickets Atual 364 SSS - Reserva]
					  ,[Número de Tickets Atual 364 SSS - Reversa]
					  ,[Número de Tickets Atual 364 SSS - Baw]
					  ,[Número de Tickets Atual 364 SSS - Mini]
					  ,[Número de Tickets Atual 364 SSS - Oficina]
					  ,[Número de Tickets Atual 364 SSS - Simples]
					  ,[Número de Tickets Atual 364 SSS - Go]
					  ,[Número de Peças Atual Greg SSS]   
					  ,[Número de Tickets Atual Greg SSS] 
					  ,[Número de Tickets Atual Greg SSS - Reserva]
					  ,[Número de Tickets Atual Greg SSS - Reversa]
					  ,[Número de Tickets Atual Greg SSS - Baw] 
					  ,[Número de Tickets Atual Greg SSS - Mini]
					  ,[Número de Tickets Atual Greg SSS - Oficina]
					  ,[Número de Tickets Atual Greg SSS - Simples]
					  ,[Número de Tickets Atual Greg SSS - Go]

					  ,[SEM TROCA E CS - Número de Peças] 
					  ,[SEM TROCA E CS - Número de Tickets]
					  ,[SEM TROCA E CS - Número de Peças 364]       
					  ,[SEM TROCA E CS - Número de Tickets 364]     
					  ,[SEM TROCA E CS - Número de Peças Greg]      
					  ,[SEM TROCA E CS - Número de Tickets Greg]    
					  ,[SEM TROCA E CS - Número de Peças 364 SSS]   
					  ,[SEM TROCA E CS - Número de Tickets 364 SSS] 
					  ,[SEM TROCA E CS - Número de Peças Greg SSS]  
					  ,[SEM TROCA E CS - Número de Tickets Greg SSS]
					  ,[SEM TROCA E CS - Número de Peças Atual 364 SSS]    
					  ,[SEM TROCA E CS - Número de Tickets Atual 364 SSS]  
					  ,[SEM TROCA E CS - Número de Peças Atual Greg SSS]   
					  ,[SEM TROCA E CS - Número de Tickets Atual Greg SSS] 
					  ,[20 dias ou mais de SSSG] = CASE WHEN ASSS.[status] = 'Inválida' then 'Não' ELse 'Sim' END
					  ,b.[Supervisor]    
					  ,[Flag Atividade] = ISNULL(b.[Flag Atividade],'Inativa')
					  ,[Venda Atual - Delivery]         
			          ,[Venda Atual Greg SSS - Delivery]
			          ,[Venda Atual 364 SSS - Delivery] 
			          ,[Venda Atual Greg SSS - Salão]   
			          ,[Venda Atual 364 SSS - Salão]    
			          ,[Venda Atual Greg SSS - Plano B] 
			          ,[Venda Atual 364 SSS - Plano B]  
			          ,[Venda Atual Greg SSS - STV]     
			          ,[Venda Atual 364 SSS - STV]      
			          ,[Venda Atual Greg SSS - Mala]    
			          ,[Venda Atual 364 SSS - Mala]     
			          ,[Venda Greg SSS - Delivery]      
			          ,[Venda 364 SSS - Delivery]       
			          ,[Venda Greg SSS - Salão]         
			          ,[Venda 364 SSS - Salão]          
			          ,[Venda Greg SSS - Plano B]       
			          ,[Venda 364 SSS - Plano B]        
			          ,[Venda Greg SSS - STV]           
			          ,[Venda 364 SSS - STV]            
			          ,[Venda Greg SSS - Mala]          
			          ,[Venda 364 SSS - Mala]           
			          ,[Número de Peças - Delivery]     
			          ,[Número de Tickets - Delivery]   
			          ,[Número de Peças - Salão]        
			          ,[Número de Tickets - Salão]      
			          ,[Número de Peças - Plano B]      
			          ,[Número de Tickets - Plano B]    
			          ,[Número de Peças - STV]          
			          ,[Número de Tickets - STV]        
			          ,[Número de Peças - Mala]         
			          ,[Número de Tickets - Mala]   
					  ,[Venda Greg - Delivery]
					  ,[Venda 364 - Delivery] 
					  ,[Venda Greg - Salão]   
					  ,[Venda 364 - Salão]    
					  ,[Venda Greg - Plano B] 
					  ,[Venda 364 - Plano B]  
					  ,[Venda Greg - STV]     
					  ,[Venda 364 - STV]      
					  ,[Venda Greg - Mala]    
					  ,[Venda 364 - Mala]     
					  ,[Número de Peças - Cuecas]        
				      ,[Número de Peças - Assinaturas]
				      ,[Número de Tickets - Cross Sell]  
					  ,[Número de Tickets - Cuecas]
					  ,[Número de Tickets - Assinaturas]
					  ,[Venda Atual - Cross Sell]  
					  ,[Venda Atual - Corner Reversa]
					  ,[Venda Atual Greg SSS - Corner Reversa] 
					  ,[Venda Atual 364 SSS - Corner Reversa]
					  ,[Venda 364 SSS - Corner Reversa]
					  ,[Venda Greg SSS - Corner Reversa]
					  ,[Venda 364 - Corner Reversa]
					  ,[Venda Greg - Corner Reversa] 
					  ,[Número de Peças - Corner Reversa]
					  ,[Número de Tickets - Corner Reversa] 
					  ,[Possui Corner Reversa]
					  ,[Válido p/ Top 20] = CASE WHEN tp.[Válido p/ Top 20] = 'Sim' then 'Sim' ELse 'Não' END
					  ,[Venda Atual - Mala Corner Reversa]
					  ,[Venda Atual - Mala Corner Mini]
					  ,[Possui Corner Baw]   
					  ,[Possui Corner Reserva]
					  ,[Possui Corner Simples]
					  ,[Venda Atual - Corner Baw]             
					  ,[Venda Atual Greg SSS - Corner Baw]    
					  ,[Venda Atual 364 SSS - Corner Baw]	  
					  ,[Venda 364 SSS - Corner Baw]		    
					  ,[Venda Greg SSS - Corner Baw]		    
					  ,[Venda 364 - Corner Baw]			    
					  ,[Venda Greg - Corner Baw] 			  
					  ,[Número de Peças - Corner Baw]		  
					  ,[Número de Tickets - Corner Baw] 	
					  ,[Venda Atual - Corner Reserva]             
					  ,[Venda Atual Greg SSS - Corner Reserva]    
					  ,[Venda Atual 364 SSS - Corner Reserva]	  
					  ,[Venda 364 SSS - Corner Reserva]		    
					  ,[Venda Greg SSS - Corner Reserva]		    
					  ,[Venda 364 - Corner Reserva]			    
					  ,[Venda Greg - Corner Reserva] 			  
					  ,[Número de Peças - Corner Reserva]		  
					  ,[Número de Tickets - Corner Reserva] 	
					  ,[Venda Atual - Corner Simples]         
					  ,[Venda Atual Greg SSS - Corner Simples]
					  ,[Venda Atual 364 SSS - Corner Simples]	
					  ,[Venda 364 SSS - Corner Simples]		
					  ,[Venda Greg SSS - Corner Simples]		
					  ,[Venda 364 - Corner Simples]			
					  ,[Venda Greg - Corner Simples] 			
					  ,[Número de Peças - Corner Simples]		
					  ,[Número de Tickets - Corner Simples] 	
					  ,[Venda Atual - Mala Corner Baw]    
					  ,[Venda Atual - Mala Corner Reserva]   
					  ,[Venda Atual - Mala Corner Simples]
					  ,[Número de Tickets Troca] 
					  ,[Valor Troca Atual]		
					  ,[Número de Tickets Troca com Dif] 
					  ,[Valor Troca Atual com Dif]		
					  ,[Malas Enviadas]   
					  ,[Malas Convertidas]
					  ,[RON Enviados]    
					  ,[RON com Venda]
					  ,[RON Valor]
					  ,[Número de Tickets - Pistoladas]
					  ,[Venda Atual Greg SSS- Cross Sell] 
					  ,[Venda Atual 364 SSS- Cross Sell] 
					  ,[Venda Greg SSS - Cross Sell]
					  ,[Venda 364 SSS - Cross Sell]
					  ,[Venda Greg - Cross Sell]
					  ,[Venda 364 - Cross Sell] 
					  ,[Número de Peças Atual Greg SSS- Cuecas] 
					  ,[Número de Peças Atual 364 SSS- Cuecas] 
					  ,[Número de Peças Greg SSS - Cuecas] 
					  ,[Número de Peças 364 SSS - Cuecas] 
					  ,[Número de Peças Greg - Cuecas] 
					  ,[Número de Peças 364 - Cuecas] 
					  ,[Número de Peças Atual Greg SSS- Assinaturas]
					  ,[Número de Peças Atual 364 SSS- Assinaturas] 
					  ,[Número de Peças Greg SSS - Assinaturas] 
					  ,[Número de Peças 364 SSS - Assinaturas] 
					  ,[Número de Peças Greg - Assinaturas]
					  ,[Número de Peças 364 - Assinaturas] 
					  ,[Número de Tickets Offline Sem Troca] 
					  ,[Número de Peças - Oculos]
					  ,[Flag Atividade Vendedor] = CASE WHEN DataDesativacao is null then 'Ativo' else 'Inativo' END
					  ,b.[Franqueado]
					  ,[Possui Corner GO]
					  ,[Número de Peças - Meia]   
					  ,[Venda Atual - Corner Go]         
					  ,[Venda Atual Greg SSS - Corner Go]
					  ,[Venda Atual 364 SSS - Corner Go]	
					  ,[Venda 364 SSS - Corner Go]		
					  ,[Venda Greg SSS - Corner Go]		
					  ,[Venda 364 - Corner Go]			
					  ,[Venda Greg - Corner Go] 			
					  ,[Número de Peças - Corner Go]		
					  ,[Número de Tickets - Corner Go] 	
					  ,[Venda Atual - Mala Corner Go] 
					  ,[Venda Atual - Plano B Corner Reversa]	
					  ,[Venda Atual - Plano B Corner Baw]
					  ,[Venda Atual - Plano B Corner Reserva]
					  ,[Venda Atual - Plano B Corner Go]		
					  ,[Venda Atual - Plano B Corner Simples]	
					  ,[Venda Atual - Plano B Corner Mini]	
					  ,[Venda Atual - Salão Corner Reversa]	
					  ,[Venda Atual - Salão Corner Baw]		
					  ,[Venda Atual - Salão Corner Reserva]	
					  ,[Venda Atual - Salão Corner Go]		
					  ,[Venda Atual - Salão Corner Simples]	
					  ,[Venda Atual - Salão Corner Mini]		
					  ,[Venda Atual - STV Corner Reversa]		
					  ,[Venda Atual - STV Corner Baw]	
					  ,[Venda Atual - STV Corner Reserva]
					  ,[Venda Atual - STV Corner Go]			
					  ,[Venda Atual - STV Corner Simples]		
					  ,[Venda Atual - STV Corner Mini]		
					  ,[Venda Atual - Delivery Corner Reversa]
					  ,[Venda Atual - Delivery Corner Baw]	
					  ,[Venda Atual - Delivery Corner Reserva]
					  ,[Venda Atual - Delivery Corner Go]		
					  ,[Venda Atual - Delivery Corner Simples]
					  ,[Venda Atual - Delivery Corner Mini]
					  ,[Venda Atual - Delivery Corner Oficina]
					  ,[Venda Atual - STV Corner Oficina]
                      ,[Venda Atual - Salão Corner Oficina]
                      ,[Venda Atual - Plano B Corner Oficina] 
					  ,[Venda Atual - Mala Corner Oficina] 
					  ,[Possui Corner Oficina]
					  ,[Venda Atual - Corner Oficina]          
					  ,[Venda Atual Greg SSS - Corner Oficina] 
					  ,[Venda Atual 364 SSS - Corner Oficina]	
					  ,[Venda 364 SSS - Corner Oficina]		
					  ,[Venda Greg SSS - Corner Oficina]		
					  ,[Venda 364 - Corner Oficina]			
					  ,[Venda Greg - Corner Oficina] 			
					  ,[Número de Peças - Corner Oficina]		
					  ,[Número de Tickets - Corner Oficina] 	
					  ,[Número de Tickets - Meia]
					  ,[Número de Peças Atual Greg SSS- Meia]
					  ,[Número de Peças Atual 364 SSS- Meia] 
					  ,[Número de Peças Greg SSS - Meia] 
					  ,[Número de Peças 364 SSS - Meia] 
					  ,[Número de Peças Greg - Meia] 
					  ,[Número de Peças 364 - Meia] 
					  ,[Número de Tickets - Novas Assinaturas]
					  -- Inclusão dos campos novos para óculos
					  ,[Número de Tickets - Oculos]           
					  ,[Número de Peças Atual Greg SSS- Oculos]         
					  ,[Número de Peças Atual 364 SSS- Oculos]  			 
					  ,[Número de Peças Greg SSS - Oculos] 				 
					  ,[Número de Peças 364 SSS - Oculos] 			
					  ,[Número de Peças Greg - Oculos] 		
					  ,[Número de Peças 364 - Oculos] 	
					  ,f.[Gerente Comercial]   
					  ,[Pedidos BOPIS/Ship To (Entregue)]
					  ,[MalasRua]

				

from (


SELECT	[Data]                                  =   ISNULL(a.data,isnull(vdgreg.data,isnull(vd364.data, isnull(atualgregsss.data, isnull(atual364sss.data, isnull(vdgregsss.data, isnull(vd364sss.data, isnull(metafl.data, isnull(metavd.data, isnull(b.data,isnull(dn.data,isnull(pt.data,isnull(vdsintese.data,dmr.data)))))))))))))
	   ,[IdCanal] 								=   ISNULL(a.idcanal,isnull(vdgreg.idcanal,isnull(vd364.idcanal,  isnull(atualgregsss.idcanal, isnull(atual364sss.idcanal, isnull(vdgregsss.idcanal, isnull(vd364sss.idcanal, isnull(metafl.idcanal, isnull(metavd.idcanal, isnull(b.idcanal,isnull(dn.idcanal,isnull(pt.idcanal,isnull(vdsintese.idcanal,dmr.idcanal)))))))))))))
	   ,[IdCanalNegocio] 						=   ISNULL(a.idcanalnegocio,isnull(vdgreg.idcanalnegocio,isnull(vd364.idcanalnegocio,  isnull(atualgregsss.idcanalnegocio, isnull(atual364sss.idcanalnegocio, isnull(vdgregsss.idcanalnegocio, isnull(vd364sss.idcanalnegocio, isnull(metafl.idcanalnegocio, isnull(metavd.idcanalnegocio, isnull(b.idcanalnegocio,isnull(dn.idcanalnegocio,isnull(pt.idcanalnegocio,isnull(vdsintese.idcanalnegocio,dmr.idcanalnegocio)))))))))))))
	   ,[IdFilial] 								=   ISNULL(a.idfilial,isnull(vdgreg.idfilial,isnull(vd364.idfilial,  isnull(atualgregsss.idfilial, isnull(atual364sss.idfilial, isnull(vdgregsss.idfilial, isnull(vd364sss.idfilial, isnull(metafl.idfilial, isnull(metavd.idfilial, isnull(b.idfilial,isnull(dn.idfilial,isnull(pt.idfilial,isnull(vdsintese.idfilial,dmr.idfilial)))))))))))))
	   ,[IdVendedor] 							=   ISNULL(a.idvendedor,isnull(vdgreg.idvendedor,isnull(vd364.idvendedor,  isnull(atualgregsss.idvendedor, isnull(atual364sss.idvendedor, isnull(vdgregsss.idvendedor, isnull(vd364sss.idvendedor, isnull(metafl.idvendedor, isnull(metavd.idvendedor, isnull(b.idvendedor,isnull(dn.idvendedor,isnull(pt.idvendedor,isnull(vdsintese.idvendedor,dmr.idvendedor)))))))))))))
	  -- ,[IdMarca] 								=   ISNULL(a.idmarca,isnull(vdgreg.idmarca,isnull(vd364.idmarca,  isnull(atualgregsss.idmarca, isnull(atual364sss.idmarca, isnull(vdgregsss.idmarca, isnull(vd364sss.idmarca, isnull(metafl.idmarca, isnull(metavd.idmarca, b.idmarca)))))))))
	 --  ,[IdMarca2] 								=   ISNULL(a.idmarca2,isnull(vdgreg.idmarca2,isnull(vd364.idmarca2,  isnull(atualgregsss.idmarca2, isnull(atual364sss.idmarca2, isnull(vdgregsss.idmarca2, isnull(vd364sss.idmarca2, isnull(metafl.idmarca2, isnull(metavd.idmarca2, b.idmarca2)))))))))
	   ,[Venda Atual - Plano B] 				=   SUM(ISNULL(a.[Plano B] 		                ,0    ))						
	   ,[Venda Atual - Salão] 					=   SUM(ISNULL(a.[Salão] 					    ,0    ))		
	   ,[Venda Atual - STV] 					=   SUM(ISNULL(a.[STV] 							,0    ))		
	   ,[Venda Atual - Mala] 					=   SUM(ISNULL(a.[Mala] 						,0    ))	
	   ,[Venda Atual Greg SSS - Total] 		    =   SUM(ISNULL(atualgregsss.[total]             ,0    ))	
	   ,[Venda Atual 364 SSS - Total]		    =   SUM(ISNULL(atual364sss.[total]              ,0    )) 
	   ,[Venda 364 SSS - Total]				    =   SUM(ISNULL(vd364sss.[total]                 ,0    )) 
	   ,[Venda Greg SSS - Total]			    =   SUM(ISNULL(vdgregsss.[total]                ,0    ))
	   ,[Venda 364 - Total]				        =   SUM(ISNULL(vd364.[total]                    ,0    ))
	   ,[Venda Greg - Total]				    =   SUM(ISNULL(vdgreg.[total]                   ,0    ))
	   ,[Cancelado Delivery] 					=   SUM(ISNULL([Cancelado Delivery] 			,0    ))		
	   ,[Cancelado último dia Plano B]			=   SUM(ISNULL([Cancelado último dia Plano B]	,0    ))
	   ,[Cancelado último dia STV]			    =   SUM(ISNULL([Cancelado último dia STV]	    ,0    ))
	   ,[Número de Peças] 						=   SUM(ISNULL(a.[Número de Peças] 				,0    ))		
	   ,[Número de Tickets] 					=   SUM(ISNULL(a.[Número de Tickets] 			    ,0    ))
	   ,[Número de Tickets - Reserva] 			=   SUM(ISNULL(a.[Número de Tickets - Reserva] 		,0    ))
	   ,[Número de Tickets - Reversa] 			=   SUM(ISNULL(a.[Número de Tickets - Reversa] 		,0    ))
	   ,[Número de Tickets - Baw] 			    =   SUM(ISNULL(a.[Número de Tickets - Baw] 		,0    ))
	   ,[Número de Tickets - Mini] 			    =   SUM(ISNULL(a.[Número de Tickets - Mini] 		,0    ))
	   ,[Número de Tickets - Oficina] 			=   SUM(ISNULL(a.[Número de Tickets - Oficina] 		,0    ))
	   ,[Número de Tickets - Simples] 			=   SUM(ISNULL(a.[Número de Tickets - Simples] 		,0    ))
	   ,[Número de Tickets - Go] 			    =   SUM(ISNULL(a.[Número de Tickets - Go] 		,0    ))
	   ,[Meta Filial]                           =   SUM(ISNULL(metafl.[Meta] 			        ,0    ))	
	   ,[Meta Vendedor]                         =   SUM(ISNULL(metavd.[Meta] 			        ,0    ))	
	   ,[Venda Atual - Corner]                  =   SUM(ISNULL(a.[Corner] 						,0    ))
	   ,[Venda Atual Greg SSS - Corner] 		=	SUM(ISNULL(atualgregsss.Corner              ,0    ))
	   ,[Venda Atual 364 SSS - Corner]			=	SUM(ISNULL(atual364sss.Corner               ,0    ))
	   ,[Venda 364 SSS - Corner]				=	SUM(ISNULL(vd364sss.Corner                  ,0    ))
	   ,[Venda Greg SSS - Corner]				=	SUM(ISNULL(vdgregsss.Corner                 ,0    ))
	   ,[Venda 364 - Corner]					=	SUM(ISNULL(vd364.Corner                     ,0    ))
	   ,[Venda Greg - Corner]					=	SUM(ISNULL(vdgreg.Corner                    ,0    ))
	   ,[Número de Peças - Corner]              =	SUM(ISNULL(a.[Corner - Número de Peças]     ,0    ))
	   ,[Número de Tickets - Corner]		    =	SUM(ISNULL(a.[Corenr - Número de Tickets]   ,0    ))
	  -- ,[Número de Peças - Digital]             =	SUM(ISNULL([Número de Peças - Digital]      ,0    ))
      -- ,[Número de Peças - Loja]                =	SUM(ISNULL([Número de Peças - Loja]         ,0    ))
      -- ,[Número de Tickets - Digital]           =	SUM(ISNULL([Número de Tickets - Digital]    ,0    ))
      -- ,[Número de Tickets - Loja]              =	SUM(ISNULL([Número de Tickets - Loja]       ,0    ))
	   ,[Número de Peças 364]                   =	SUM(ISNULL(vd364.[Número de Peças]          ,0    ))
	   ,[Número de Tickets 364]     			=	SUM(ISNULL(vd364.[Número de Tickets]        ,0    ))
	   ,[Número de Tickets 364 - Reserva]     	=	SUM(ISNULL(vd364.[Número de Tickets - Reserva]    ,0    ))
	   ,[Número de Tickets 364 - Reversa]     	=	SUM(ISNULL(vd364.[Número de Tickets - Reversa]    ,0    ))
	   ,[Número de Tickets 364 - Baw]     	    =	SUM(ISNULL(vd364.[Número de Tickets - Baw]    ,0    ))
	   ,[Número de Tickets 364 - Mini]     	    =	SUM(ISNULL(vd364.[Número de Tickets - Mini]    ,0    ))
	   ,[Número de Tickets 364 - Oficina]     	=	SUM(ISNULL(vd364.[Número de Tickets - Oficina]    ,0    ))
	   ,[Número de Tickets 364 - Simples]     	=	SUM(ISNULL(vd364.[Número de Tickets - Simples]    ,0    ))
	   ,[Número de Tickets 364 - Go]     	    =	SUM(ISNULL(vd364.[Número de Tickets - Go]    ,0    ))
	   ,[Número de Peças Greg]                  =	SUM(ISNULL(vdgreg.[Número de Peças]         ,0    ))
	   ,[Número de Tickets Greg]    		    =	SUM(ISNULL(vdgreg.[Número de Tickets]       ,0    ))
	   ,[Número de Tickets Greg - Reserva]    	=	SUM(ISNULL(vdgreg.[Número de Tickets - Reserva]  ,0    ))
	   ,[Número de Tickets Greg - Reversa]    	=	SUM(ISNULL(vdgreg.[Número de Tickets - Reversa]  ,0    ))
	   ,[Número de Tickets Greg - Baw]    	    =	SUM(ISNULL(vdgreg.[Número de Tickets - Baw]  ,0    ))
	   ,[Número de Tickets Greg - Mini]    	    =	SUM(ISNULL(vdgreg.[Número de Tickets - Mini]  ,0    ))
	   ,[Número de Tickets Greg - Oficina]    	=	SUM(ISNULL(vdgreg.[Número de Tickets - Oficina]  ,0    ))
	   ,[Número de Tickets Greg - Simples]    	=	SUM(ISNULL(vdgreg.[Número de Tickets - Simples]  ,0    ))
	   ,[Número de Tickets Greg - Go]    	    =	SUM(ISNULL(vdgreg.[Número de Tickets - Go]  ,0    ))
	   ,[Número de Peças 364 SSS]               =	SUM(ISNULL(vd364sss.[Número de Peças]       ,0    ))
	   ,[Número de Tickets 364 SSS] 			=	SUM(ISNULL(vd364sss.[Número de Tickets]     ,0    ))
	   ,[Número de Tickets 364 SSS - Reserva] 	=	SUM(ISNULL(vd364sss.[Número de Tickets - Reserva] ,0    ))
	   ,[Número de Tickets 364 SSS - Reversa] 	=	SUM(ISNULL(vd364sss.[Número de Tickets - Reversa] ,0    ))
	   ,[Número de Tickets 364 SSS - Baw] 	    =	SUM(ISNULL(vd364sss.[Número de Tickets - Baw] ,0    ))
	   ,[Número de Tickets 364 SSS - Mini] 	    =	SUM(ISNULL(vd364sss.[Número de Tickets - Mini] ,0    ))
	   ,[Número de Tickets 364 SSS - Oficina]   =	SUM(ISNULL(vd364sss.[Número de Tickets - Oficina] ,0    ))
	   ,[Número de Tickets 364 SSS - Simples]   =	SUM(ISNULL(vd364sss.[Número de Tickets - Simples] ,0    ))
	   ,[Número de Tickets 364 SSS - Go]        =	SUM(ISNULL(vd364sss.[Número de Tickets - Go] ,0    ))
	   ,[Número de Peças Greg SSS]              =	SUM(ISNULL(vdgregsss.[Número de Peças]      ,0    ))
	   ,[Número de Tickets Greg SSS]		    =	SUM(ISNULL(vdgregsss.[Número de Tickets]    ,0    ))
	   ,[Número de Tickets Greg SSS - Reserva]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Reserva]  ,0    ))
	   ,[Número de Tickets Greg SSS - Reversa]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Reversa]  ,0    ))
	   ,[Número de Tickets Greg SSS - Baw]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Baw]  ,0    ))
	   ,[Número de Tickets Greg SSS - Mini]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Mini]  ,0    ))
	   ,[Número de Tickets Greg SSS - Oficina]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Oficina]  ,0    ))
	   ,[Número de Tickets Greg SSS - Simples]	=	SUM(ISNULL(vdgregsss.[Número de Tickets - Simples]  ,0    ))
	   ,[Número de Tickets Greg SSS - Go]	    =	SUM(ISNULL(vdgregsss.[Número de Tickets - Go]  ,0    ))
	   ,[Número de Peças Atual 364 SSS]         =	SUM(ISNULL(atual364sss.[Número de Peças]    ,0    ))
	   ,[Número de Tickets Atual 364 SSS]   	=	SUM(ISNULL(atual364sss.[Número de Tickets]  ,0    ))
	   ,[Número de Tickets Atual 364 SSS - Reserva]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Reserva]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Reversa]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Reversa]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Baw]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Baw]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Mini]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Mini]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Oficina]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Oficina]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Simples]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Simples]  ,0))
	   ,[Número de Tickets Atual 364 SSS - Go]  =	SUM(ISNULL(atual364sss.[Número de Tickets - Go]  ,0))
	   ,[Número de Peças Atual Greg SSS]        =	SUM(ISNULL(atualgregsss.[Número de Peças]   ,0    ))
	   ,[Número de Tickets Atual Greg SSS] 		=	SUM(ISNULL(atualgregsss.[Número de Tickets] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Reserva] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Reserva] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Reversa] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Reversa] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Baw] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Baw] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Mini] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Mini] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Oficina] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Oficina] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Simples] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Simples] ,0    ))
	   ,[Número de Tickets Atual Greg SSS - Go] =	SUM(ISNULL(atualgregsss.[Número de Tickets - Go] ,0    ))
	   ,[SEM TROCA E CS - Número de Peças]                    = SUM(ISNULL(a.[Número de Peças2] 				,0    ))	
       ,[SEM TROCA E CS - Número de Tickets]				  = SUM(ISNULL(a.[Número de Tickets2] 			    ,0    ))
       ,[SEM TROCA E CS - Número de Peças 364]                =	SUM(ISNULL(vd364.[Número de Peças2]          ,0    ))
       ,[SEM TROCA E CS - Número de Tickets 364]     		  =	SUM(ISNULL(vd364.[Número de Tickets2]        ,0    ))
       ,[SEM TROCA E CS - Número de Peças Greg]      		  =	SUM(ISNULL(vdgreg.[Número de Peças2]         ,0    ))
       ,[SEM TROCA E CS - Número de Tickets Greg]    		  =	SUM(ISNULL(vdgreg.[Número de Tickets2]       ,0    ))
       ,[SEM TROCA E CS - Número de Peças 364 SSS]   		  =	SUM(ISNULL(vd364sss.[Número de Peças2]       ,0    ))
       ,[SEM TROCA E CS - Número de Tickets 364 SSS] 		  =	SUM(ISNULL(vd364sss.[Número de Tickets2]     ,0    ))
       ,[SEM TROCA E CS - Número de Peças Greg SSS]  		  =	SUM(ISNULL(vdgregsss.[Número de Peças2]      ,0    ))
       ,[SEM TROCA E CS - Número de Tickets Greg SSS]		  =	SUM(ISNULL(vdgregsss.[Número de Tickets2]    ,0    ))
       ,[SEM TROCA E CS - Número de Peças Atual 364 SSS]      =	SUM(ISNULL(atual364sss.[Número de Peças2]    ,0    ))
       ,[SEM TROCA E CS - Número de Tickets Atual 364 SSS]    =	SUM(ISNULL(atual364sss.[Número de Tickets2]  ,0    ))
       ,[SEM TROCA E CS - Número de Peças Atual Greg SSS]     =	SUM(ISNULL(atualgregsss.[Número de Peças2]   ,0    ))
       ,[SEM TROCA E CS - Número de Tickets Atual Greg SSS]   =	SUM(ISNULL(atualgregsss.[Número de Tickets2] ,0    ))
	   ,[Supervisor]     =   ISNULL(a.[Supervisor],isnull(vdgreg.[Supervisor],isnull(vd364.[Supervisor], isnull(atualgregsss.[Supervisor], isnull(atual364sss.[Supervisor], isnull(vdgregsss.[Supervisor], isnull(vd364sss.[Supervisor], isnull(metafl.[Supervisor], isnull(metavd.[Supervisor], isnull(b.[Supervisor],isnull(dn.SupervisorAtual,isnull(pt.SupervisorAtual,isnull(vdsintese.Supervisor,dmr.SupervisorAtual)))))))))))))
	   ,[Flag Atividade] =   ISNULL(a.[Flag Atividade],isnull(vdgreg.[Flag Atividade],isnull(vd364.[Flag Atividade], isnull(atualgregsss.[Flag Atividade], isnull(atual364sss.[Flag Atividade], isnull(vdgregsss.[Flag Atividade], isnull(vd364sss.[Flag Atividade], isnull(metafl.[Flag Atividade], isnull(metavd.[Flag Atividade], isnull(b.[Flag Atividade],isnull(dn.[Flag Atividade],isnull(pt.[Flag Atividade],isnull(vdsintese.[Flag Atividade],dmr.[Flag Atividade])))))))))))))
	   ,[Venda Atual - Delivery]           = SUM(ISNULL([Delivery]                          ,0))
       ,[Venda Atual Greg SSS - Delivery]  = SUM(ISNULL([Venda Atual Greg SSS - Delivery]	,0))
       ,[Venda Atual 364 SSS - Delivery]   = SUM(ISNULL([Venda Atual 364 SSS - Delivery] 	,0))
       ,[Venda Atual Greg SSS - Salão]     = SUM(ISNULL([Venda Atual Greg SSS - Salão]   	,0))
       ,[Venda Atual 364 SSS - Salão]      = SUM(ISNULL([Venda Atual 364 SSS - Salão]    	,0))
       ,[Venda Atual Greg SSS - Plano B]   = SUM(ISNULL([Venda Atual Greg SSS - Plano B] 	,0))
       ,[Venda Atual 364 SSS - Plano B]    = SUM(ISNULL([Venda Atual 364 SSS - Plano B]  	,0))
       ,[Venda Atual Greg SSS - STV]       = SUM(ISNULL([Venda Atual Greg SSS - STV]     	,0))
       ,[Venda Atual 364 SSS - STV]        = SUM(ISNULL([Venda Atual 364 SSS - STV]      	,0))
       ,[Venda Atual Greg SSS - Mala]      = SUM(ISNULL([Venda Atual Greg SSS - Mala]    	,0))
       ,[Venda Atual 364 SSS - Mala]       = SUM(ISNULL([Venda Atual 364 SSS - Mala]     	,0))
       ,[Venda Greg SSS - Delivery]        = SUM(ISNULL([Venda Greg SSS - Delivery]      	,0))
       ,[Venda 364 SSS - Delivery]         = SUM(ISNULL([Venda 364 SSS - Delivery]       	,0))
       ,[Venda Greg SSS - Salão]           = SUM(ISNULL([Venda Greg SSS - Salão]         	,0))
       ,[Venda 364 SSS - Salão]            = SUM(ISNULL([Venda 364 SSS - Salão]          	,0))
       ,[Venda Greg SSS - Plano B]         = SUM(ISNULL([Venda Greg SSS - Plano B]       	,0))
       ,[Venda 364 SSS - Plano B]          = SUM(ISNULL([Venda 364 SSS - Plano B]        	,0))
       ,[Venda Greg SSS - STV]             = SUM(ISNULL([Venda Greg SSS - STV]           	,0))
       ,[Venda 364 SSS - STV]              = SUM(ISNULL([Venda 364 SSS - STV]            	,0))
       ,[Venda Greg SSS - Mala]            = SUM(ISNULL([Venda Greg SSS - Mala]          	,0))
       ,[Venda 364 SSS - Mala]             = SUM(ISNULL([Venda 364 SSS - Mala]           	,0))
       ,[Número de Peças - Delivery]       = SUM(ISNULL([Número de Peças - Delivery]     	,0))
       ,[Número de Tickets - Delivery]     = SUM(ISNULL([Número de Tickets - Delivery]   	,0))
       ,[Número de Peças - Salão]          = SUM(ISNULL([Número de Peças - Salão]        	,0))
       ,[Número de Tickets - Salão]        = SUM(ISNULL([Número de Tickets - Salão]      	,0))
       ,[Número de Peças - Plano B]        = SUM(ISNULL([Número de Peças - Plano B]      	,0))
       ,[Número de Tickets - Plano B]      = SUM(ISNULL([Número de Tickets - Plano B]    	,0))
       ,[Número de Peças - STV]            = SUM(ISNULL([Número de Peças - STV]          	,0))
       ,[Número de Tickets - STV]          = SUM(ISNULL([Número de Tickets - STV]        	,0))
       ,[Número de Peças - Mala]           = SUM(ISNULL([Número de Peças - Mala]         	,0))
       ,[Número de Tickets - Mala]   	   = SUM(ISNULL([Número de Tickets - Mala]   		,0))
	   ,[Venda Greg - Delivery]            = SUM(ISNULL([Venda Greg - Delivery]             ,0))
	   ,[Venda 364 - Delivery] 			   = SUM(ISNULL([Venda 364 - Delivery] 				,0))
	   ,[Venda Greg - Salão]   			   = SUM(ISNULL([Venda Greg - Salão]   				,0))
	   ,[Venda 364 - Salão]    			   = SUM(ISNULL([Venda 364 - Salão]    				,0))
	   ,[Venda Greg - Plano B] 			   = SUM(ISNULL([Venda Greg - Plano B] 				,0))
	   ,[Venda 364 - Plano B]  			   = SUM(ISNULL([Venda 364 - Plano B]  				,0))
	   ,[Venda Greg - STV]     			   = SUM(ISNULL([Venda Greg - STV]     				,0))
	   ,[Venda 364 - STV]      			   = SUM(ISNULL([Venda 364 - STV]      				,0))
	   ,[Venda Greg - Mala]    			   = SUM(ISNULL([Venda Greg - Mala]    				,0))
	   ,[Venda 364 - Mala]     			   = SUM(ISNULL([Venda 364 - Mala]     				,0))
	   ,[Número de Peças - Cuecas]         = SUM(ISNULL([Número de Peças - Cuecas]          ,0)) 
	   ,[Número de Peças - Assinaturas] = SUM(ISNULL([Número de Peças - Assinaturas]   ,0))
	   ,[Número de Tickets - Cross Sell]   = SUM(ISNULL([Número de Tickets - Cross Sell]    ,0))
	   ,[Número de Tickets - Cuecas]       = SUM(ISNULL([Número de Tickets - Cuecas]     	,0))
	   ,[Número de Tickets - Assinaturas]  = SUM(ISNULL([Número de Tickets - Assinaturas]     	,0))
	   ,[Venda Atual - Cross Sell]  	   = SUM(ISNULL([Venda Atual - Cross Sell]  	     ,0)) 
	   ,[Venda Atual - Corner Reversa]             =    SUM(ISNULL(a.[Corner Reversa] 						,0    ))
	   ,[Venda Atual Greg SSS - Corner Reversa]    =	SUM(ISNULL(atualgregsss.[Corner Reversa] 	        ,0    ))
	   ,[Venda Atual 364 SSS - Corner Reversa]     =	SUM(ISNULL(atual364sss.[Corner Reversa] 	        ,0    ))
	   ,[Venda 364 SSS - Corner Reversa]           =	SUM(ISNULL(vd364sss.[Corner Reversa] 	            ,0    ))
	   ,[Venda Greg SSS - Corner Reversa]          =	SUM(ISNULL(vdgregsss.[Corner Reversa] 	            ,0    ))
	   ,[Venda 364 - Corner Reversa]               =	SUM(ISNULL(vd364.[Corner Reversa] 	                ,0    ))
	   ,[Venda Greg - Corner Reversa]              =	SUM(ISNULL(vdgreg.[Corner Reversa] 	                ,0    ))
	   ,[Número de Peças - Corner Reversa]         =	SUM(ISNULL(a.[Corner Reversa - Número de Peças]     ,0    ))
	   ,[Número de Tickets - Corner Reversa]       =	SUM(ISNULL(a.[Corenr Reversa - Número de Tickets]   ,0    ))
	   ,[Venda Atual - Mala Corner Reversa]        =    SUM(ISNULL([Venda Atual - Mala Corner Reversa]      ,0    ))
	   ,[Venda Atual - Mala Corner Mini]		   =    SUM(ISNULL([Venda Atual - Mala Corner Mini]		    ,0    ))
	   ,[Venda Atual - Corner Baw]                 = SUM(ISNULL(a.[Corner Baw]           ,0))
	   ,[Venda Atual Greg SSS - Corner Baw]    	   = SUM(ISNULL(atualgregsss.[Corner Baw]             	,0))
	   ,[Venda Atual 364 SSS - Corner Baw]	  	   = SUM(ISNULL(atual364sss.[Corner Baw]              	,0))
	   ,[Venda 364 SSS - Corner Baw]		       = SUM(ISNULL(vd364sss.[Corner Baw] 	               ,0))
	   ,[Venda Greg SSS - Corner Baw]		       = SUM(ISNULL(vdgregsss.[Corner Baw] 	                ,0))
	   ,[Venda 364 - Corner Baw]			       = SUM(ISNULL(vd364.[Corner Baw] 	                ,0))
	   ,[Venda Greg - Corner Baw] 			  	   = SUM(ISNULL(vdgreg.[Corner Baw] 	                	,0))
	   ,[Número de Peças - Corner Baw]		  	   = SUM(ISNULL(a.[Corner Baw - Número de Peças]     	,0))
	   ,[Número de Tickets - Corner Baw] 	       = SUM(ISNULL(a.[Corenr Baw - Número de Tickets]  	    ,0))

	   ,[Venda Atual - Corner Reserva]                 = SUM(ISNULL(a.[Corner Reserva]           ,0))
	   ,[Venda Atual Greg SSS - Corner Reserva]    	   = SUM(ISNULL(atualgregsss.[Corner Reserva]             	,0))
	   ,[Venda Atual 364 SSS - Corner Reserva]	  	   = SUM(ISNULL(atual364sss.[Corner Reserva]              	,0))
	   ,[Venda 364 SSS - Corner Reserva]		       = SUM(ISNULL(vd364sss.[Corner Reserva] 	               ,0))
	   ,[Venda Greg SSS - Corner Reserva]		       = SUM(ISNULL(vdgregsss.[Corner Reserva] 	                ,0))
	   ,[Venda 364 - Corner Reserva]			       = SUM(ISNULL(vd364.[Corner Reserva] 	                ,0))
	   ,[Venda Greg - Corner Reserva] 			  	   = SUM(ISNULL(vdgreg.[Corner Reserva] 	                	,0))
	   ,[Número de Peças - Corner Reserva]		  	   = SUM(ISNULL(a.[Corner Reserva - Número de Peças]     	,0))
	   ,[Número de Tickets - Corner Reserva] 	       = SUM(ISNULL(a.[Corner Reserva - Número de Tickets]  	    ,0))

	   ,[Venda Atual - Corner Simples]         	   = SUM(ISNULL(a.[Corner Simples]     	,0))
	   ,[Venda Atual Greg SSS - Corner Simples]	   = SUM(ISNULL(atualgregsss.[Corner Simples]     ,0))
	   ,[Venda Atual 364 SSS - Corner Simples]	   = SUM(ISNULL(atual364sss.[Corner Simples] 	  ,0))
	   ,[Venda 364 SSS - Corner Simples]		   = SUM(ISNULL(vd364sss.[Corner Simples] 		  ,0))
	   ,[Venda Greg SSS - Corner Simples]		   = SUM(ISNULL(vdgregsss.[Corner Simples] 		  ,0))
	   ,[Venda 364 - Corner Simples]			   = SUM(ISNULL(vd364.[Corner Simples] 	    	  ,0))
	   ,[Venda Greg - Corner Simples] 			   = SUM(ISNULL(vdgreg.[Corner Simples] 	      ,0))
	   ,[Número de Peças - Corner Simples]		   = SUM(ISNULL(a.[Corner Simples - Número de Peças]      ,0    ))
	   ,[Número de Tickets - Corner Simples] 	   = SUM(ISNULL(a.[Corenr Simples - Número de Tickets]    ,0    ))
	   ,[Venda Atual - Mala Corner Baw]            = SUM(ISNULL([Venda Atual - Mala Corner Baw]           ,0    ))
	   ,[Venda Atual - Mala Corner Reserva]            = SUM(ISNULL([Venda Atual - Mala Corner Reserva]           ,0    ))
	   ,[Venda Atual - Mala Corner Simples]        = SUM(ISNULL([Venda Atual - Mala Corner Simples]       ,0    ))
	   ,[Número de Tickets Troca]                  = SUM(ISNULL(a.[Número de Tickets Troca]               ,0    ))
	   ,[Valor Troca Atual]		 				   = SUM(ISNULL(a.[Valor Troca Atual]                     ,0    ))
	   ,[Número de Tickets Troca com Dif]          = SUM(ISNULL(a.[Número de Tickets Troca com Dif]       ,0    ))
	   ,[Valor Troca Atual com Dif]				   = SUM(ISNULL(a.[Valor Troca Atual com Dif]             ,0    ))
	   ,[Malas Enviadas]                           = SUM(ISNULL(dn.MalasEnviadas,0))
	   ,[Malas Convertidas]                        = SUM(ISNULL(dn.MalasConvertidas,0))
	   ,[RON Enviados]                             = SUM(ISNULL(dn.RONEnviados,0))
	   ,[RON com Venda]                            = SUM(ISNULL(dn.RONComVenda,0))
	   ,[RON Valor]                                = SUM(ISNULL(dn.RONValor,0))
	   ,[Número de Tickets - Pistoladas]           = SUM(ISNULL(pt.pistoladas,0))
	   ,[Venda Atual Greg SSS- Cross Sell]               = SUM(ISNULL(atualgregsss.[Cross Sell]             	,0))
	   ,[Venda Atual 364 SSS- Cross Sell] 				 = SUM(ISNULL(atual364sss.[Cross Sell]               	,0))
	   ,[Venda Greg SSS - Cross Sell]                    = SUM(ISNULL(vdgregsss.[Cross Sell]  	               ,0))
	   ,[Venda 364 SSS - Cross Sell]					 = SUM(ISNULL(vd364sss.[Cross Sell]  	                ,0))
	   ,[Venda Greg - Cross Sell]						 = SUM(ISNULL(vdgreg.[Cross Sell]  	                ,0))
	   ,[Venda 364 - Cross Sell] 						 = SUM(ISNULL(vd364.[Cross Sell]  	                	,0))
	   ,[Número de Peças Atual Greg SSS- Cuecas]         = SUM(ISNULL(atualgregsss.[Cuecas]             	,0))
	   ,[Número de Peças Atual 364 SSS- Cuecas] 		 = SUM(ISNULL(atual364sss.[Cuecas]              	,0))
	   ,[Número de Peças Greg SSS - Cuecas]              = SUM(ISNULL(vdgregsss.[Cuecas] 	               ,0))
	   ,[Número de Peças 364 SSS - Cuecas] 				 = SUM(ISNULL(vd364sss.[Cuecas] 	                ,0))
	   ,[Número de Peças Greg - Cuecas] 				 = SUM(ISNULL(vdgreg.[Cuecas] 	                ,0))
	   ,[Número de Peças 364 - Cuecas] 					 = SUM(ISNULL(vd364.[Cuecas] 	                	,0))
	   ,[Número de Peças Atual Greg SSS- Assinaturas]    = SUM(ISNULL(atualgregsss.[Assinaturas]             	,0))
	   ,[Número de Peças Atual 364 SSS- Assinaturas] 	 = SUM(ISNULL(atual364sss.[Assinaturas]              	,0))
	   ,[Número de Peças Greg SSS - Assinaturas]         = SUM(ISNULL(vdgregsss.[Assinaturas] 	               ,0))
	   ,[Número de Peças 364 SSS - Assinaturas] 		 = SUM(ISNULL(vd364sss.[Assinaturas] 	                ,0))
	   ,[Número de Peças Greg - Assinaturas]			 = SUM(ISNULL(vdgreg.[Assinaturas] 	                ,0))
	   ,[Número de Peças 364 - Assinaturas] 			 = SUM(ISNULL(vd364.[Assinaturas] 	                	,0))
	   ,[Número de Tickets Offline Sem Troca]            =SUM(ISNULL([Número de Tickets Offline Sem Troca],0))
	   ,[Número de Peças - Oculos]                       = SUM(ISNULL([Número de Peças - Oculos]          ,0)) 
	   ,[Franqueado]                                     = ISNULL(a.[Franqueado],isnull(vdgreg.[Franqueado],isnull(vd364.[Franqueado], isnull(atualgregsss.[Franqueado], isnull(atual364sss.[Franqueado], isnull(vdgregsss.[Franqueado], isnull(vd364sss.[Franqueado], isnull(metafl.[Franqueado], isnull(metavd.[Franqueado], isnull(b.[Franqueado],isnull(dn.[Franqueado],isnull(pt.[Franqueado],isnull(vdsintese.[Franqueado],dmr.[Franqueado])))))))))))))
	   ,[Número de Peças - Meia]						 = SUM(ISNULL([Número de Peças - Meia]          ,0))
	   ,[Venda Atual - Corner Go]                        = SUM(ISNULL(a.[Corner Go]           ,0))
	   ,[Venda Atual Greg SSS - Corner Go]				 = SUM(ISNULL(atualgregsss.[Corner Go]             	,0))
	   ,[Venda Atual 364 SSS - Corner Go]				 = SUM(ISNULL(atual364sss.[Corner Go]              	,0))
	   ,[Venda 364 SSS - Corner Go]						 = SUM(ISNULL(vd364sss.[Corner Go] 	               ,0))
	   ,[Venda Greg SSS - Corner Go]					 = SUM(ISNULL(vdgregsss.[Corner Go] 	                ,0))
	   ,[Venda 364 - Corner Go]							 = SUM(ISNULL(vd364.[Corner Go] 	                ,0))
	   ,[Venda Greg - Corner Go] 						 = SUM(ISNULL(vdgreg.[Corner Go] 	                	,0))
	   ,[Número de Peças - Corner Go]					 = SUM(ISNULL(a.[Corner Go - Número de Peças]     	,0))
	   ,[Número de Tickets - Corner Go] 				 = SUM(ISNULL(a.[Corner Go - Número de Tickets]  	    ,0))
	   ,[Venda Atual - Mala Corner Go]                   = SUM(ISNULL([Venda Atual - Mala Corner Go]           ,0    ))
	   ,[Venda Atual - Plano B Corner Reversa]			 = SUM(ISNULL([Venda Atual - Plano B Corner Reversa]           ,0    ))
	   ,[Venda Atual - Plano B Corner Baw]				 = SUM(ISNULL([Venda Atual - Plano B Corner Baw]	           ,0    ))	
	   ,[Venda Atual - Plano B Corner Reserva]			 = SUM(ISNULL([Venda Atual - Plano B Corner Reserva]	           ,0    ))	
	   ,[Venda Atual - Plano B Corner Go]				 = SUM(ISNULL([Venda Atual - Plano B Corner Go]           ,0    ))
	   ,[Venda Atual - Plano B Corner Simples]			 = SUM(ISNULL([Venda Atual - Plano B Corner Simples]           ,0    ))
	   ,[Venda Atual - Plano B Corner Mini]				 = SUM(ISNULL([Venda Atual - Plano B Corner Mini]           ,0    ))
	   ,[Venda Atual - Salão Corner Reversa]			 = SUM(ISNULL([Venda Atual - Salão Corner Reversa]           ,0    ))	         
	   ,[Venda Atual - Salão Corner Baw]				 = SUM(ISNULL([Venda Atual - Salão Corner Baw]           ,0    ))	
	   ,[Venda Atual - Salão Corner Reserva]				 = SUM(ISNULL([Venda Atual - Salão Corner Reserva]           ,0    ))	
	   ,[Venda Atual - Salão Corner Go]					 = SUM(ISNULL([Venda Atual - Salão Corner Go]           ,0    ))	
	   ,[Venda Atual - Salão Corner Simples]			 = SUM(ISNULL([Venda Atual - Salão Corner Simples]          ,0    ))
	   ,[Venda Atual - Salão Corner Mini]		         = SUM(ISNULL([Venda Atual - Salão Corner Mini]          ,0    ))
	   ,[Venda Atual - STV Corner Reversa]		         = SUM(ISNULL([Venda Atual - STV Corner Reversa]           ,0    ))	 
	   ,[Venda Atual - STV Corner Baw]			         = SUM(ISNULL([Venda Atual - STV Corner Baw]	,0    ))
	   ,[Venda Atual - STV Corner Reserva]			         = SUM(ISNULL([Venda Atual - STV Corner Reserva]	,0    ))
	   ,[Venda Atual - STV Corner Go]			         = SUM(ISNULL([Venda Atual - STV Corner Go]           ,0    ))	
	   ,[Venda Atual - STV Corner Simples]				 = SUM(ISNULL([Venda Atual - STV Corner Simples]	          ,0    ))
	   ,[Venda Atual - STV Corner Mini]		             = SUM(ISNULL([Venda Atual - STV Corner Mini]        ,0    ))
	   ,[Venda Atual - Delivery Corner Reversa]          = SUM(ISNULL([Venda Atual - Delivery Corner Reversa]          ,0    ))
	   ,[Venda Atual - Delivery Corner Baw]	             = SUM(ISNULL([Venda Atual - Delivery Corner Baw]	,0    ))	
	   ,[Venda Atual - Delivery Corner Reserva]	             = SUM(ISNULL([Venda Atual - Delivery Corner Reserva]	,0    ))
	   ,[Venda Atual - Delivery Corner Go]		         = SUM(ISNULL([Venda Atual - Delivery Corner Go]          ,0    ))	
	   ,[Venda Atual - Delivery Corner Simples]          = SUM(ISNULL([Venda Atual - Delivery Corner Simples]	,0    ))	
	   ,[Venda Atual - Delivery Corner Mini]             = SUM(ISNULL([Venda Atual - Delivery Corner Mini]          ,0    ))	
	   ,[Venda Atual - Delivery Corner OFICINA]			 = SUM(ISNULL([Venda Atual - Delivery Corner OFICINA]	          ,0    ))	
	   ,[Venda Atual - STV Corner OFICINA]				 = SUM(ISNULL([Venda Atual - STV Corner OFICINA]          ,0    ))	
	   ,[Venda Atual - Salão Corner OFICINA]			 = SUM(ISNULL([Venda Atual - Salão Corner OFICINA]         ,0    ))	
       ,[Venda Atual - Plano B Corner OFICINA] 			 = SUM(ISNULL([Venda Atual - Plano B Corner OFICINA]          ,0    ))	
	   ,[Venda Atual - Mala Corner OFICINA] 			 = SUM(ISNULL([Venda Atual - Mala Corner OFICINA]          ,0    ))	
	   ,[Venda Atual - Corner Oficina]                        = SUM(ISNULL(a.[Corner Oficina]           ,0))
	   ,[Venda Atual Greg SSS - Corner Oficina]				 = SUM(ISNULL(atualgregsss.[Corner Oficina]             	,0))
	   ,[Venda Atual 364 SSS - Corner Oficina]				 = SUM(ISNULL(atual364sss.[Corner Oficina]              	,0))
	   ,[Venda 364 SSS - Corner Oficina]						 = SUM(ISNULL(vd364sss.[Corner Oficina] 	               ,0))
	   ,[Venda Greg SSS - Corner Oficina]					 = SUM(ISNULL(vdgregsss.[Corner Oficina] 	                ,0))
	   ,[Venda 364 - Corner Oficina]							 = SUM(ISNULL(vd364.[Corner Oficina] 	                ,0))
	   ,[Venda Greg - Corner Oficina] 						 = SUM(ISNULL(vdgreg.[Corner Oficina] 	                	,0))
	   ,[Número de Peças - Corner Oficina]					 = SUM(ISNULL(a.[Corner Oficina - Número de Peças]     	,0))
	   ,[Número de Tickets - Corner Oficina] 				 = SUM(ISNULL(a.[Corner Oficina - Número de Tickets]  	    ,0))
	   ,[Número de Tickets - Meia]                           = SUM(ISNULL([Número de Tickets - Meia]     	,0))
	   ,[Número de Peças Atual Greg SSS- Meia]               = SUM(ISNULL(atualgregsss.[Meia]             	,0))
	   ,[Número de Peças Atual 364 SSS- Meia]  				 = SUM(ISNULL(atual364sss.[Meia]              	,0))
	   ,[Número de Peças Greg SSS - Meia] 					 = SUM(ISNULL(vdgregsss.[Meia] 	               ,0))
	   ,[Número de Peças 364 SSS - Meia] 					 = SUM(ISNULL(vd364sss.[Meia] 	                ,0))
	   ,[Número de Peças Greg - Meia] 						 = SUM(ISNULL(vdgreg.[Meia] 	                ,0))
	   ,[Número de Peças 364 - Meia] 						 = SUM(ISNULL(vd364.[Meia] 	                	,0))
	   ,[Número de Tickets - Novas Assinaturas]              = SUM(ISNULL([Número de Tickets - Novas Assinaturas] 	                	,0))
	   -- Inclusão das metricas para oculos 20/07/2023
	   ,[Número de Tickets - Oculos]                         = SUM(ISNULL([Número de Tickets - Oculos]     	,0))
	   ,[Número de Peças Atual Greg SSS- Oculos]             = SUM(ISNULL(atualgregsss.[Oculos]             ,0))
	   ,[Número de Peças Atual 364 SSS- Oculos]  			 = SUM(ISNULL(atual364sss.[Oculos]              ,0))
	   ,[Número de Peças Greg SSS - Oculos] 				 = SUM(ISNULL(vdgregsss.[Oculos] 	            ,0))
	   ,[Número de Peças 364 SSS - Oculos] 					 = SUM(ISNULL(vd364sss.[Oculos] 	            ,0))
	   ,[Número de Peças Greg - Oculos] 					 = SUM(ISNULL(vdgreg.[Oculos] 	                ,0))
	   ,[Número de Peças 364 - Oculos] 						 = SUM(ISNULL(vd364.[Oculos] 	                ,0))
	   ,[Pedidos BOPIS/Ship To (Entregue)]                   = SUM(ISNULL(vdsintese.[ShipTo/BOPIS] 	                ,0))
	   ,[MalasRua]  = SUM(ISNULL(dmr.[MalasRua]	                ,0))


FROM
(
 (select
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio] 
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Mala]                = sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then

(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Tickets - Reserva] =  count(distinct(
										case when ma.marca = 'RESERVA' 
											then(
												case when canalnegocio = 'online'  
													 then pedidooriginal 
													else convert(varchar,a.[idticket]) end
											 ) else null end))
								  
,[Número de Tickets - Reversa]   =  count(distinct(
											case when ma.marca = 'REVERSA' 
												 then(
													  case when canalnegocio = 'online'  
													  then pedidooriginal 
													  else convert(varchar,a.[idticket]) end
													  ) else null end))
													  
,[Número de Tickets - Baw]   =  count(distinct(
											case when ma.marca = 'BAW' 
												then(
													  case when canalnegocio = 'online'  
													  then pedidooriginal 
													  else convert(varchar,a.[idticket]) end
													 ) else null end))
								  
,[Número de Tickets - Mini]   = count(distinct(
										case when ma.marca = 'MINI' 
											 then(
												  case when canalnegocio = 'online'  
												       then pedidooriginal 
													   else convert(varchar,a.[idticket]) end
												  ) else null end))
												  
,[Número de Tickets - Oficina]   = count(distinct(
												case when ma.marca = ' OFICINA' 
													 then(
														  case when canalnegocio = 'online'  
														        then pedidooriginal 
																else convert(varchar,a.[idticket]) end
														  ) else null end))
														  
,[Número de Tickets - Simples]   = count(distinct(
												case when ma.marca = 'SIMPLES' 
													 then(
														  case when canalnegocio = 'online' 
														  then pedidooriginal else 
														  convert(varchar,a.[idticket]) end
														  ) else null end))
														  
,[Número de Tickets - Go]   = count(distinct(
												case when ma.marca = 'GO' 
													 then(
														  case when canalnegocio = 'online'  
														       then pedidooriginal 
															   else convert(varchar,a.[idticket]) end
														  ) else null end))
														  

,[Número de Tickets Offline Sem Troca]   =count(distinct(case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' and MeioVenda not like '%STV%'
and [Quantidade Troca] = 0 and OperacaoVenda <> 'ESTOQUE OMNI'
 then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end )
else null end))
,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corner]              = sum(Case when  ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when  ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when  ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]          = sum(Case when  ma.marca in ('RESERVA', 'GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when  ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Corner - Número de Peças]     = sum(case when  ma.marca in ('MINI','GO MINI')  then [Quantidade Venda] else 0 end)
,[Corner Reversa - Número de Peças]     = sum(case when  ma.marca in  ('REVERSA')  then [Quantidade Venda] else 0 end)
,[Corner Baw - Número de Peças]     = sum(case when  ma.marca in  ('BAW')  then [Quantidade Venda] else 0 end)
,[Corner Reserva - Número de Peças]     = sum(case when  ma.marca in  ('RESERVA','GO')  then [Quantidade Venda] else 0 end)

,[Corner Go - Número de Peças]     = sum(case when  ma.[Marca Produto] in  ('GO')  then [Quantidade Venda] else 0 end)
,[Corner Oficina - Número de Peças]     = sum(case when  ma.marca in ('OFICINA')  then [Quantidade Venda] else 0 end)
,[Corner Simples - Número de Peças]     = sum(case when  ma.marca in  ('SIMPLES')  then [Quantidade Venda] else 0 end)
,[Corenr - Número de Tickets]   = count(distinct(case when ma.marca in ('MINI','GO MINI') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corenr Reversa - Número de Tickets]   = count(distinct(case when ma.marca in ('REVERSA') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corenr Baw - Número de Tickets]   = count(distinct(case when ma.marca in ('BAW') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corner Go - Número de Tickets]   = count(distinct(case when ma.[Marca Produto] in ('GO') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corner Oficina - Número de Tickets]   = count(distinct(case when ma.[Marca] in ('OFICINA') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corenr Simples - Número de Tickets]   = count(distinct(case when ma.marca in ('SIMPLES') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Corner Reserva - Número de Tickets]   = count(distinct(case when ma.marca in ('RESERVA', 'GO') then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Peças - Digital]    = sum(case when promotorvenda = 'stv' or MeioVenda = 'plano b'   then [Quantidade Venda] else 0 end)
,[Número de Peças - Loja]       = sum(case when (TipoAtendimento = 'reservado' or  MeioVenda in ('local','delivery')) and MeioVenda not like '%STV%'  then [Quantidade Venda] else 0 end)
,[Número de Tickets - Digital]  = count(distinct(case when promotorvenda = 'stv' or MeioVenda = 'plano b'  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Tickets - Loja]     = count(distinct(case when (TipoAtendimento = 'reservado' or  MeioVenda in ('local','delivery')) and MeioVenda not like '%STV%' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Supervisor]     = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Delivery]  = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Número de Peças - Delivery]     = sum(case when TipoAtendimento <> 'reservado' and  MeioVenda in ('delivery')   then [Quantidade Venda] else 0 end)
,[Número de Tickets - Delivery]  = count(distinct(case when TipoAtendimento <> 'reservado' and  MeioVenda in ('delivery')  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Peças - Salão]       = sum(case when TipoAtendimento <> 'reservado' and  MeioVenda in ('local','delivery')   then [Quantidade Venda] else 0 end)
,[Número de Tickets - Salão]     = count(distinct(case when TipoAtendimento <> 'reservado' and  MeioVenda in ('local','delivery')  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Peças - Plano B]      = sum(case when MeioVenda = 'plano b'   then [Quantidade Venda] else 0 end)
,[Número de Tickets - Plano B]    = count(distinct(case when  MeioVenda = 'plano b'  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Peças - STV]          = sum(case when promotorvenda = 'stv'   then [Quantidade Venda] else 0 end)
,[Número de Tickets - STV]        = count(distinct(case when promotorvenda = 'stv'  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Peças - Mala]         = sum(case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Quantidade Venda] else 0 end)
,[Número de Tickets - Mala]   	= count(distinct(case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
--,ma.[IdMarca] as IdMarca2 
,[Número de Peças - Cuecas]         = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Número de Peças - Oculos]  = SUM(CASE WHEN linha = 'ÓCULOS DE SOL'  then [Quantidade Venda] else 0 end)
,[Número de Peças - Assinaturas]	= SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Número de Tickets - Cross Sell] 	= count(distinct(case when  OPERACAOVENDA  like '%CROSS SELL%'  then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Tickets - Cuecas]    = count(distinct(case when  SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Tickets - Meia]    = count(distinct(case when   SubGrupo = 'meia'  then
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Número de Tickets - Oculos]    = count(distinct(case when   SubGrupo = 'ÓCULOS'  then
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))

,[Número de Tickets - Assinaturas]  = count(distinct(CASE WHEN  ((assinatura = 'VERDADEIRO' and Produto not like 'RESERVA PRIME%') or  Produto like '%OFICINA PRIME%'  or  Produto like '%RESERVA PRIME%')
and [Quantidade Venda] > 0 then
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
,[Venda Atual - Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Reversa]  = sum(Case when  ma.marca in ('REVERSA') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Baw]  = sum(Case when  ma.marca in ('BAW') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Reserva]  = sum(Case when  ma.marca in ('RESERVA','GO') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Go]  = sum(Case when  ma.[Marca Produto] in ('GO') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Simples]  = sum(Case when  ma.marca in ('SIMPLES') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Mini]     = sum(Case when  ma.marca in ('MINI','GO MINI') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Venda Atual - Mala Corner Oficina]     = sum(Case when  ma.marca in ('OFICINA') and TipoAtendimento = 'reservado' and MeioVenda not like '%STV%'  then [Valor Venda] else 0 end)
,[Número de Tickets Troca]            = COUNT(DISTINCT(CASE WHEN troca = 'sim' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))

/*********************************************PLANO B **************************************************************/

,[Venda Atual - Plano B Corner Reversa]  = sum(Case when  ma.marca in ('REVERSA') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner Baw]  = sum(Case when  ma.marca in ('BAW') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner Reserva]  = sum(Case when  ma.marca in ('RESERVA', 'GO') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner Go]  = sum(Case when  ma.[Marca Produto] in ('GO') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner Simples]  = sum(Case when  ma.marca in ('SIMPLES') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner Mini]     = sum(Case when  ma.marca in ('MINI','GO MINI') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)
,[Venda Atual - Plano B Corner OFICINA]     = sum(Case when  ma.marca in ('OFICINA') and MeioVenda = 'plano b'  then [Valor Venda] else 0 end)

/*********************************************SALÃO **************************************************************/

,[Venda Atual - Salão Corner Reversa]  = sum(Case when  ma.marca in ('REVERSA') and MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado'  then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner Baw]  = sum(Case when  ma.marca in ('BAW') and MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner Reserva]  = sum(Case when  ma.marca in ('RESERVA', 'GO') and MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner Go]  = sum(Case when  ma.[Marca Produto] in ('GO') and MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado'  then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner Simples]  = sum(Case when  ma.marca in ('SIMPLES') and MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner Mini]     = sum(Case when  ma.marca in ('MINI','GO MINI') and MeioVenda in ('local','delivery')and TipoAtendimento <> 'reservado'  then [Valor Venda] else 0 end)
,[Venda Atual - Salão Corner OFICINA]     = sum(Case when  ma.marca in ('OFICINA') and MeioVenda in ('local','delivery')and TipoAtendimento <> 'reservado'  then [Valor Venda] else 0 end)


/*********************************************STV **************************************************************/

,[Venda Atual - STV Corner Reversa]  = sum(Case when  ma.marca in ('REVERSA') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner Baw]  = sum(Case when  ma.marca in ('BAW') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner Reserva]  = sum(Case when  ma.marca in ('RESERVA', 'GO') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner Go]  = sum(Case when  ma.[Marca Produto] in ('GO') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner Simples]  = sum(Case when  ma.marca in ('SIMPLES') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner Mini]     = sum(Case when  ma.marca in ('MINI','GO MINI') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)
,[Venda Atual - STV Corner OFICINA]     = sum(Case when  ma.marca in ('OFICINA') and promotorvenda = 'stv'  then [Valor Venda] else 0 end)

/*********************************************DELIVERY **************************************************************/

,[Venda Atual - Delivery Corner Reversa]  = sum(Case when  ma.marca in ('REVERSA') and MeioVenda = 'delivery'  then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner Baw]  = sum(Case when  ma.marca in ('BAW') and MeioVenda  = 'delivery' then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner Reserva]  = sum(Case when  ma.marca in ('RESERVA', 'GO') and MeioVenda  = 'delivery' then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner Go]  = sum(Case when  ma.[Marca Produto] in ('GO') and MeioVenda  = 'delivery'   then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner Simples]  = sum(Case when  ma.marca in ('SIMPLES') and MeioVenda = 'delivery' then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner Mini]     = sum(Case when  ma.marca in ('MINI','GO MINI') and MeioVenda  = 'delivery'   then [Valor Venda] else 0 end)
,[Venda Atual - Delivery Corner OFICINA]     = sum(Case when  ma.marca in ('OFICINA') and MeioVenda  = 'delivery'   then [Valor Venda] else 0 end)

/*
,[Venda Atual - Delivery Corner OFICINA]
,[Venda Atual - STV Corner OFICINA]
,[Venda Atual - Salão Corner OFICINA]
,[Venda Atual - Plano B Corner OFICINA] 
*/


,[Valor Troca Atual]      			  = SUM(CASE WHEN troca = 'sim' then [Valor Venda] else 0 end)
,[Número de Tickets Troca com Dif]    =  COUNT(DISTINCT(CASE WHEN troca = 'sim' and [Troca com Dif] = 'Sim' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end)) 
,[Valor Troca Atual com Dif]	=	SUM(CASE WHEN troca = 'sim' and [Troca com Dif] = 'Sim' then [Valor Venda] else 0 end)
,[Franqueado]
,[Número de Peças - Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Número de Tickets - Novas Assinaturas]  = count(distinct(CASE WHEN  ((assinatura = 'VERDADEIRO' and Produto not like 'RESERVA PRIME%') or  Produto like '%OFICINA PRIME%'  or  Produto like '%RESERVA PRIME%')
and novoprime is null and [Quantidade Venda] > 0  then
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,a.[idticket]) end
) else null end))
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.idassinatura = a.idassinatura
left join #ticketstroca tc on tc.IdTicket = a.IdTicket
left join #atividadefilial af on af.idfilial = a.idfilial
left join #clantigosprime clp on clp.IdCliente = a.IdCliente


WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @IniMesPassado and @FimMes and IdTabela = '1'
GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
) a




FULL OUTER JOIN 

 (select
 [Data]                 = dateadd(year,1,data)
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                 = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA','GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then (
																			case when canalnegocio = 'online'  
																			      then pedidooriginal else 
																			convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca ='REVERSA' then (
															case when canalnegocio = 'online' 
																 then pedidooriginal 
																else convert(varchar,[idticket]) end
															) else null end))
,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then (
																	case when canalnegocio = 'online' 
																		 then pedidooriginal 
																		 else convert(varchar,[idticket]) end
																	) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then (
																		case when canalnegocio = 'online' 
																			 then pedidooriginal 
																			 else convert(varchar,[idticket]) end
																		) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then (
																			case when canalnegocio = 'online' 
																			then pedidooriginal 
																			else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then (
																				case when canalnegocio = 'online' 
																					then pedidooriginal 
																					else convert(varchar,[idticket]) end
																				) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then (
																				case when canalnegocio = 'online' 
																					then pedidooriginal 
																					else convert(varchar,[idticket]) end
																				) else null end))


,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda Greg - Delivery]    = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Greg - Salão]    	= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Greg - Plano B] 	= sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda Greg - STV]      	= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda Greg - Mala]     	= sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]       = SUM(CASE WHEN SubGrupo = 'ÓCULOS' then [Quantidade Venda] else 0 end)
,[Cuecas]    = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]

FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @inimespassadogreg and dateadd(month,1,@fimmesgreg) and IdTabela = '1'

GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
)   vdgreg 
 on vdgreg.idcanal = a.idcanal
and vdgreg.idcanalnegocio = a.IdCanalNegocio
and vdgreg.idfilial = a.idfilial
and vdgreg.idvendedor = a.idvendedor
--and vdgreg.idmarca = a.idmarca
and vdgreg.Data = a.Data
and vdgreg.Supervisor = a.Supervisor
and vdgreg.[Flag Atividade] = a.[Flag Atividade]
and vdgreg.franqueado = a.Franqueado
--and vdgreg.Idmarca2 = a.IdMarca2



FULL OUTER JOIN 

 (select
 [Data]                 = dateadd(day,364,data)
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                 = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA', 'GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then (
																				case when canalnegocio = 'online'  
																				     then pedidooriginal 
																					 else convert(varchar,[idticket]) end
																				) else null end))
,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca = 'REVERSA' then (
																	case when canalnegocio = 'online'  
																		then pedidooriginal 
																		else convert(varchar,[idticket]) end
																	) else null end))
,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then(
																	case when canalnegocio = 'online'  
																		 then pedidooriginal 
																		 else convert(varchar,[idticket]) end
																	) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then (
																	case when canalnegocio = 'online'  
																		 then pedidooriginal 
																		 else convert(varchar,[idticket]) end
																	) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then (
																			case when canalnegocio = 'online'  
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then (
																			case when canalnegocio = 'online'  
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then (
																	case when canalnegocio = 'online'  
																		 then pedidooriginal 
																		 else convert(varchar,[idticket]) end
																	) else null end))


,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda 364 - Delivery]     = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda 364 - Salão]    	= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda 364 - Plano B] 	    = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda 364 - STV]      	= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda 364 - Mala]     	= sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]       = SUM(CASE WHEN SubGrupo = 'ÓCULOS'   then [Quantidade Venda] else 0 end)
,[Cuecas]   = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @inimespassado364 and dateadd(month,1,@fimmes364) and IdTabela = '1'

GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
)   vd364 
 on vd364.idcanal = a.idcanal
and vd364.idcanalnegocio = a.IdCanalNegocio
and vd364.idfilial = a.idfilial
and vd364.idvendedor = a.idvendedor
--and vd364.idmarca = a.idmarca
and vd364.Data = a.Data
and vd364.Supervisor = a.Supervisor
and vd364.[Flag Atividade] = a.[Flag Atividade]
and vd364.franqueado = a.Franqueado
--and vd364.Idmarca2 = a.IdMarca2


FULL OUTER JOIN 

 (select
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                    = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA', 'GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then (
																			case when canalnegocio = 'online'  
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca = 'REVERSA' then (
																				case when canalnegocio = 'online'  
																					 then pedidooriginal 
																					 else convert(varchar,[idticket]) end
																				) else null end))
,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then (
																			case when canalnegocio = 'online' 
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then (
																			case when canalnegocio = 'online' 
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then (
																			case when canalnegocio = 'online'  
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then (
																			case when canalnegocio = 'online'  
																				 then pedidooriginal 
																				 else convert(varchar,[idticket]) end
																			) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then (
																			case when canalnegocio = 'online'  
																			then pedidooriginal 
																			else convert(varchar,[idticket]) end
																			) else null end))


,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda Atual Greg SSS - Delivery]      = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual Greg SSS - Salão]   		= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual Greg SSS - Plano B] 		= sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda Atual Greg SSS - STV]     		= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda Atual Greg SSS - Mala]          = sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]         = SUM(CASE WHEN SubGrupo = 'ÓCULOS'   then [Quantidade Venda] else 0 end)
,[Cuecas]    = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @IniMesPassado and @FimMes and
CONCAT(d.data, a.[IdFilial]) in (SELECT DISTINCT CONCAT(#tbmetas.data, #tbmetas.idfilial) FROM #tbmetas
			                           WHERE [Data] >= @IniMesPassado and [Data] <= @FimMes
									   AND [Meta Atual] <> 0 AND [Meta Greg (n-1)] <> 0) and IdTabela = '1'
GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
) atualgregsss 
 on atualgregsss.idcanal = a.idcanal
and atualgregsss.idcanalnegocio = a.IdCanalNegocio
and atualgregsss.idfilial = a.idfilial
and atualgregsss.idvendedor = a.idvendedor
--and atualgregsss.idmarca = a.idmarca
and atualgregsss.Data = a.Data
and atualgregsss.Supervisor = a.Supervisor
and atualgregsss.[Flag Atividade] = a.[Flag Atividade]
and atualgregsss.franqueado = a.Franqueado
--and atualgregsss.Idmarca2 = a.IdMarca2

FULL OUTER JOIN 

 (select
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                  = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA','GO') then [Valor Venda] else 0 end)

,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca = 'REVERSA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))


,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda Atual 364 SSS - Delivery]       = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual 364 SSS - Salão]   		= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Atual 364 SSS - Plano B] 		= sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda Atual 364 SSS - STV]     		= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda Atual 364 SSS - Mala]           = sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]         = SUM(CASE WHEN SubGrupo = 'ÓCULOS'   then [Quantidade Venda] else 0 end)
,[Cuecas]    = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE  (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @IniMesPassado and @FimMes and
CONCAT(d.data, a.[IdFilial]) in (SELECT DISTINCT CONCAT(#tbmetas.data, #tbmetas.idfilial) FROM #tbmetas
			                           WHERE [Data] >= @IniMesPassado and [Data] <= @FimMes
									   AND [Meta Atual] <> 0 AND [Meta 364 (n-1)] <> 0) and IdTabela = '1'
GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
) atual364sss 
 on atual364sss.idcanal = a.idcanal
and atual364sss.idcanalnegocio = a.IdCanalNegocio
and atual364sss.idfilial = a.idfilial
and atual364sss.idvendedor = a.idvendedor
--and atual364sss.idmarca = a.idmarca
and atual364sss.Data = a.Data
and atual364sss.Supervisor = a.Supervisor
and atual364sss.[Flag Atividade] = a.[Flag Atividade]
and atual364sss.franqueado = a.Franqueado
--and atual364sss.Idmarca2 = a.IdMarca2


FULL OUTER JOIN 

 (select
 [Data] = dateadd(year, 1, data)
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                 = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA', 'GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))

,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca = 'REVERSA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))

,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))

,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda Greg SSS - Delivery]      = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Greg SSS - Salão]   		= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda Greg SSS - Plano B] 		= sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda Greg SSS - STV]     		= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda Greg SSS - Mala]          = sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]       = SUM(CASE WHEN SubGrupo = 'ÓCULOS'   then [Quantidade Venda] else 0 end)
,[Cuecas]   = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE  (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and  Data between @inimespassadogreg and @fimmesgreg and
CONCAT(dateadd(year, 1, data), a.[IdFilial]) in (SELECT DISTINCT CONCAT(#tbmetas.data, #tbmetas.idfilial) FROM #tbmetas
			                           WHERE [Data] >= @IniMesPassado and [Data] <= @FimMes
									   AND [Meta Atual] <> 0 AND [Meta greg (n-1)] <> 0) and IdTabela = '1'
GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
) vdgregsss
 on vdgregsss.idcanal = a.idcanal
and vdgregsss.idcanalnegocio = a.IdCanalNegocio
and vdgregsss.idfilial = a.idfilial
and vdgregsss.idvendedor = a.idvendedor
--and vdgregsss.idmarca = a.idmarca
and vdgregsss.Data = a.Data
and vdgregsss.Supervisor = a.Supervisor
and vdgregsss.[Flag Atividade] = a.[Flag Atividade]
and vdgregsss.franqueado = a.Franqueado
--and vdgregsss.Idmarca2 = a.IdMarca2



FULL OUTER JOIN 

 (select
 [Data] = dateadd(day, 364, data)
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] as IdMarca
,[Total]                 = sum([Valor Venda])
,[Corner]                = sum(Case when ma.marca in ('MINI','GO MINI') then [Valor Venda] else 0 end)
,[Corner Reversa]              = sum(Case when ma.marca in ('REVERSA') then [Valor Venda] else 0 end)
,[Corner Baw]              = sum(Case when ma.marca in ('BAW') then [Valor Venda] else 0 end)
,[Corner Reserva]              = sum(Case when ma.marca in ('RESERVA', 'GO') then [Valor Venda] else 0 end)
,[Corner Go]              = sum(Case when  ma.[Marca Produto] in  ('GO') then [Valor Venda] else 0 end)
,[Corner Oficina]              = sum(Case when  ma.marca in ('OFICINA') then [Valor Venda] else 0 end)
,[Corner Simples]              = sum(Case when ma.marca in ('SIMPLES') then [Valor Venda] else 0 end)
,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reserva]   = count(distinct(case when ma.marca = 'RESERVA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Reversa]   = count(distinct(case when ma.marca = 'REVERSA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Baw]   = count(distinct(case when ma.marca = 'BAW' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Mini]   = count(distinct(case when ma.marca = 'MINI' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Oficina]   = count(distinct(case when ma.marca = 'OFICINA' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Simples]   = count(distinct(case when ma.marca = 'SIMPLES' then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
,[Número de Tickets - Go]   = count(distinct(case when ma.marca = 'GO' then 
(
case when canalnegocio = 'online'  then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))


,[Número de Peças2]     = sum(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado')
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%' then [Quantidade Venda] else 0 end)
,[Número de Tickets2]   = count(distinct(case when (MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado') 
                                         and [Quantidade Troca] = 0 and OPERACAOVENDA not like '%CROSS SELL%'then 
(
case when canalnegocio = 'online' then pedidooriginal else 
convert(varchar,[idticket]) end
) else null end))
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,ma.[IdMarca] as IdMarca2
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade]
,[Venda 364 SSS - Delivery]      = sum(Case when MeioVenda in ('delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda 364 SSS - Salão]   		= sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
,[Venda 364 SSS - Plano B] 		= sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
,[Venda 364 SSS - STV]     		= sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
,[Venda 364 SSS - Mala]          = sum(Case when TipoAtendimento = 'reservado' and MeioVenda not like '%STV%' then [Valor Venda] else 0 end)
,[Meia]         = SUM(CASE WHEN SubGrupo = 'meia'   then [Quantidade Venda] else 0 end)
,[Oculos]       = SUM(CASE WHEN SubGrupo = 'ÓCULOS'  then [Quantidade Venda] else 0 end)
,[Cuecas]   = SUM(CASE WHEN SubGrupo like '%cueca%' or SubGrupo like '%boxer%'
  or   (produto like '%cueca%' and subgrupo = 'PIJAMA')
  or ([Grupo]= 'INTIMO' and (Produto like '%calcinha%' or Produto like '%top%' )) then [Quantidade Venda] else 0 end)
,[Assinaturas]  = SUM(CASE WHEN  assinatura = 'VERDADEIRO' and Produto not like '%RESERVA PRIME%'  then [Quantidade Venda]
                                               WHEN  Produto like '%OFICINA PRIME%' then [Quantidade Venda]*3
											   WHEN  Produto like '%RESERVA PRIME%' then [Quantidade Venda]*3 else 0 end)
,[Cross Sell]  	 = SUM(CASE WHEN OPERACAOVENDA  like '%CROSS SELL%'  then  [Valor Venda] else 0 end)
,[Franqueado]
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe
left join tbDimOperacaoVenda op on op.IdOperacaoVenda = a.IdOperacaoVenda
left join tbDimCanalNegocio cn on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbDimFilial f on f.idfilial = a.idfilial
left join tbDimAssinatura ass on ass.IdAssinatura = a.IdAssinatura
left join #atividadefilial af on af.idfilial = a.idfilial

WHERE  (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and Data between @inimespassado364 and @fimmes364 and
CONCAT(dateadd(day, 364, data), a.[IdFilial]) in (SELECT DISTINCT CONCAT(#tbmetas.data, #tbmetas.idfilial) FROM #tbmetas
			                           WHERE [Data] >= @IniMesPassado and [Data] <= @FimMes
									   AND [Meta Atual] <> 0 AND [Meta 364 (n-1)] <> 0) and IdTabela = '1'
GROUP BY 
 [Data] 
,[IdCanal] 
,a.[IdCanalNegocio]  
,a.[IdFilial] 
,[IdVendedor] 
--,[IdMarcaComercial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
--,ma.[IdMarca]
) vd364sss
 on vd364sss.idcanal = a.idcanal
and vd364sss.idcanalnegocio = a.IdCanalNegocio
and vd364sss.idfilial = a.idfilial
and vd364sss.idvendedor = a.idvendedor
--and vd364sss.idmarca = a.idmarca
and vd364sss.Data = a.Data
and vd364sss.Supervisor = a.Supervisor
and vd364sss.[Flag Atividade] = a.[Flag Atividade]
and vd364sss.franqueado = a.Franqueado
--and vd364sss.Idmarca2 = a.IdMarca2

FULL OUTER JOIN 

 (select
 [Data]
,[IdCanal]        = 0
,[IdCanalNegocio] = 0
,a.[IdFilial]  
,[IdVendedor]     = 0
--,[IdMarca]        = 0
,[Meta]                 = sum([Meta Atual])
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,IdMarca2        = 0
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade] 
,[Franqueado]
FROM [reserva_dw].[dbo].[tbFatoMetaFilialTableau] a
left join tbdimfilial f  with(nolock) on f.idfilial = a.idfilial
left join #atividadefilial af on af.Idfilial = a.idfilial
left join tbdimdata d on d.iddata = a.iddata
where Data >= @inimespassado 
GROUP BY 
 [Data] 
,a.[IdFilial] 
,SupervisorAtual
,[Atividade]
,[Franqueado]
) metafl
 on metafl.idcanal = a.idcanal
and metafl.idcanalnegocio = a.IdCanalNegocio
and metafl.idfilial = a.idfilial
and metafl.idvendedor = a.idvendedor
--and metafl.idmarca = a.idmarca
and metafl.Data = a.Data
and metafl.supervisor = a.supervisor
and metafl.[Flag Atividade] = a.[Flag Atividade]
and metafl.franqueado = a.Franqueado
--and metafl.Idmarca2 = a.IdMarca2

FULL OUTER JOIN 

 (select
 [Data]
,[IdCanal]        = 0
,[IdCanalNegocio] = 0
,a.[IdFilial]     
,[IdVendedor]     
--,[IdMarca]        = 0
,[Meta]                 = sum([Meta])
--,[Plano B]             = sum(Case when MeioVenda = 'plano b' then [Valor Venda] else 0 end)
--,[Salão]               = sum(Case when MeioVenda in ('local','delivery') and TipoAtendimento <> 'reservado' then [Valor Venda] else 0 end)
--,[STV]                 = sum(Case when promotorvenda = 'stv' then [Valor Venda] else 0 end)
--,[Mala]                = sum(Case when TipoAtendimento = 'reservado' then [Valor Venda] else 0 end)
--,[Cancelado Delivery]  = sum(case when MeioVenda = 'delivery' then [Valor Cancelado] else 0 end)
--,[Número de Peças]     = sum(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [Quantidade Venda] else 0 end)
--,[Número de Tickets]   = count(distinct(case when MeioVenda in ('plano b', 'local', 'delivery') or PromotorVenda = 'stv' or TipoAtendimento = 'reservado' then [idticket] else null end))
--,IdMarca2        = 0
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] = [Atividade] 
,[Franqueado]
FROM [dbo].[tbFatoMetaVendedorTableau] a
left join tbdimfilial f  with(nolock) on f.idfilial = a.idfilial
left join #atividadefilial af on af.idfilial = a.idfilial
left join tbdimdata d on d.iddata = a.iddata
where Data between @inimespassado and @fimmes 
GROUP BY 
 [Data] 
,a.[IdFilial] 
,[IdVendedor]
,SupervisorAtual
,[Atividade]
,[Franqueado]
) metavd
 on metavd.idcanal = a.idcanal
and metavd.idcanalnegocio = a.IdCanalNegocio
and metavd.idfilial = a.idfilial
and metavd.idvendedor = a.idvendedor
--and metavd.idmarca = a.idmarca
and metavd.Data = a.Data
and metavd.supervisor = a.supervisor
and metavd.[Flag Atividade] = a.[Flag Atividade]
and metavd.franqueado = a.Franqueado
--and metavd.Idmarca2 = a.IdMarca2


FULL OUTER JOIN 

(select * from #auxcancelados)
b   on b.idcanal = a.idcanal
   and b.idcanalnegocio = a.IdCanalNegocio
   and b.idfilial = a.idfilial
   and b.idvendedor = a.idvendedor
  -- and b.idmarca = a.idmarca
   and b.Data = a.Data
   and b.Supervisor = a.Supervisor
   and b.[Flag Atividade] = a.[Flag Atividade]
   and b.franqueado = a.Franqueado
 --  and b.Idmarca2 = a.IdMarca2

 FULL OUTER JOIN 
 (select a.*, f.idfilial, idvendedor, SupervisorAtual, [Flag Atividade] = Atividade ,[Franqueado]
 , idcanal = 0, idcanalnegocio = 0 from #dadosnow a
left join tbdimdata d on d.data = a.data
left join tbDimFilial f on f.codfilial = a.codfilial
left join #atividadefilial af on af.idfilial = f.idfilial
left join #dimvendedor v on v.cpf = a.CPFVendedor
                         and v.codfilial = a.codfilial
where [Atividade] = 'Ativa'
 )
 dn on dn.idcanal = a.idcanal
   and dn.idcanalnegocio = a.IdCanalNegocio
   and dn.idfilial = a.idfilial
   and dn.idvendedor = a.idvendedor
  -- and b.idmarca = a.idmarca
   and dn.Data = a.Data
   and dn.SupervisorAtual = a.Supervisor
   and dn.[Flag Atividade] = a.[Flag Atividade]
   and dn.franqueado = a.Franqueado

--------------------------------------FULL OUTER JOIN MALAS RUA -------------------------------------------
 FULL OUTER JOIN 
 (select a.*, f.idfilial, SupervisorAtual, [Flag Atividade] = Atividade ,[Franqueado]
 ,idvendedor = 0, idcanal = 0, idcanalnegocio = 0 from #malasrua a
left join tbDimFilial f on f.codfilial = a.codfilial
left join #atividadefilial af on af.idfilial = f.idfilial
where [Atividade] = 'Ativa'
 )
 dmr on dmr.idcanal = a.idcanal
   and dmr.idcanalnegocio = a.IdCanalNegocio
   and dmr.idfilial = a.idfilial
   and dmr.idvendedor = a.idvendedor
  -- and b.idmarca = a.idmarca
   and dmr.Data = a.Data
   and dmr.SupervisorAtual = a.Supervisor
   and dmr.[Flag Atividade] = a.[Flag Atividade]
   and dmr.franqueado = a.Franqueado

-----------------------------------------------------------------------------------------------------------


    FULL OUTER JOIN 
 (select a.*, f.idfilial, idvendedor, SupervisorAtual, [Flag Atividade] = Atividade ,[Franqueado]
 , idcanal = 0, idcanalnegocio = 0  from #pistolada a
left join tbdimdata d on d.data = a.data
left join tbDimFilial f on f.codfilial = a.codfilial
left join #atividadefilial af on af.idfilial = f.idfilial
left join #dimvendedor v on v.cpf = a.CPFVendedor
                         and v.codfilial = a.codfilial
where [Atividade] = 'Ativa'
 )
 pt on pt.idcanal = a.idcanal
   and pt.idcanalnegocio = a.IdCanalNegocio
   and pt.idfilial = a.idfilial
   and pt.idvendedor = a.idvendedor
  -- and b.idmarca = a.idmarca
   and pt.Data = a.Data
   and pt.SupervisorAtual = a.Supervisor
   and pt.[Flag Atividade] = a.[Flag Atividade]
   and pt.franqueado = a.Franqueado


FULL OUTER JOIN 



(
select 
 [Data]           
,[IdCanal]       
,[IdCanalNegocio]
,[IdFilial]      
,[IdVendedor]    
,[Supervisor]    
,[Flag Atividade]
,[Franqueado]
,[ShipTo/BOPIS] = sum([ShipTo/BOPIS])
from 
(
 select
 [Data]                 = convert(date, A.[Data_Cadastramento])
,[IdCanal]              = 0
,[IdCanalNegocio]  	    = 0
,[IdFilial]             = idfilial
,[IdVendedor]           = 0
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] --= [Atividade]
,[Franqueado]
,[ShipTo/BOPIS] = count(distinct a.pedido)
FROM [reserva_ods].[dbo].[tbOdsLinxControleAtendimento3652] A with (nolock)
left join [10.1.1.2].[reserva].[dbo].RSV_ATG_ECOMMERCE_SHIPPING_GROUP_INFO B ON REPLACE(replace(A.pedido, 'E0',''),'E','') = B.order_id
left join (SELECT distinct
       [FilialAntiga]
      ,max([FilialNova])[FilialNova]
  FROM [RESERVA_ODS].[dbo].[tbOdsLinxDeParaFiliais]
  group by [FilialAntiga]) ajfi on ajfi.FilialAntiga = b.ADDRESS3 
left join (select distinct idfilial, [filial comercial],FilialOriginal, tipofilial,marca,franqueado,cnpj,[flag atividade], max(supervisoratual) supervisoratual from tbdimfilial with(nolock)
where  supervisoratual <> '(Não Informado)' and supervisoratual is not null
group by idfilial,[Filial comercial],FilialOriginal, TipoFilial,marca,franqueado,cnpj,[flag atividade]) f on f.FilialOriginal = isnull(ajfi.filialnova,b.ADDRESS3 )
where  convert(date, A.[Data_Cadastramento]) between @IniMesPassado and @FimMes and idfilial is not null
and status_pedido = 'Finished' 
group by convert(date, A.[Data_Cadastramento]), idfilial,  [Flag Atividade], SupervisorAtual,  [Franqueado]

UNION ALL

SELECT
[Data]                 = CONVERT(date, a.data)	
,[IdCanal]              = 0
,[IdCanalNegocio]  	    = 0
,[IdFilial]             = idfilial
,[IdVendedor]           = 0
,[Supervisor]    = SupervisorAtual
,[Flag Atividade] --= [Atividade]
,[Franqueado]
,[ShipTo/BOPIS] = count(distinct a.pedido)
FROM 
	[10.1.1.2].[reserva].[dbo].RSV_SINOMS_PEDIDOS a WITH(NOLOCK) 
LEFT JOIN [10.1.1.2].[reserva].[dbo].RSV_RELATORIO_SINOMS e with(nolock) on E.pedido = A.pedido  and E.conta = A.conta
left join (SELECT distinct
       [FilialAntiga]
      ,max([FilialNova])[FilialNova]
  FROM [RESERVA_ODS].[dbo].[tbOdsLinxDeParaFiliais]
  group by [FilialAntiga]) ajfi on ajfi.FilialAntiga = a.filial 
left join (select distinct idfilial,[filial comercial],[Flag Atividade],FilialOriginal, tipofilial,marca,franqueado,cnpj, max(supervisoratual) supervisoratual from tbdimfilial with(nolock)
where supervisoratual <> '(Não Informado)' and supervisoratual is not null
group by idfilial,[Filial comercial],FilialOriginal,[Flag Atividade], TipoFilial,marca,franqueado,cnpj) f on f.FilialOriginal = isnull(ajfi.FilialNova ,a.filial )
where  CONVERT(date, a.data)	between @IniMesPassado and @FimMes and idfilial is not null
and a.[Forma Envio] = 'Retirada Loja'
and [Entrega] = 'Pickup Store'
and a.[Status] = 'Entregue'
group by CONVERT(date, a.data), idfilial,  [Flag Atividade], SupervisorAtual,  [Franqueado]

) a
group by 
[Data]           
,[IdCanal]       
,[IdCanalNegocio]
,[IdFilial]      
,[IdVendedor]    
,[Supervisor]    
,[Flag Atividade]
,[Franqueado]
)   vdsintese 
 on vdsintese.idcanal = a.idcanal
and vdsintese.idcanalnegocio = a.IdCanalNegocio
and vdsintese.idfilial = a.idfilial
and vdsintese.idvendedor = a.idvendedor
--and vdgreg.idmarca = a.idmarca
and vdsintese.Data = a.Data
and vdsintese.Supervisor = a.Supervisor
and vdsintese.[Flag Atividade] = a.[Flag Atividade]
and vdsintese.franqueado = a.Franqueado
--and vdgreg.Idmarca2 = a.IdMarca2







   ) 
GROUP BY
------- ISNULL(a.data,isnull(vdgreg.data,isnull(vd364.data, isnull(atualgregsss.data, isnull(atual364sss.data, isnull(vdgregsss.data, isnull(vd364sss.data, isnull(metafl.data, isnull(metavd.data, isnull(b.data,isnull(dn.data,isnull(pt.data,vdsintese.data))))))))))))
-------,ISNULL(a.idcanal,isnull(vdgreg.idcanal,isnull(vd364.idcanal,  isnull(atualgregsss.idcanal, isnull(atual364sss.idcanal, isnull(vdgregsss.idcanal, isnull(vd364sss.idcanal, isnull(metafl.idcanal, isnull(metavd.idcanal, isnull(b.idcanal,isnull(dn.idcanal,isnull(pt.idcanal,vdsintese.idcanal))))))))))))
-------,ISNULL(a.idcanalnegocio,isnull(vdgreg.idcanalnegocio,isnull(vd364.idcanalnegocio,  isnull(atualgregsss.idcanalnegocio, isnull(atual364sss.idcanalnegocio, isnull(vdgregsss.idcanalnegocio, isnull(vd364sss.idcanalnegocio, isnull(metafl.idcanalnegocio, isnull(metavd.idcanalnegocio, isnull(b.idcanalnegocio,isnull(dn.idcanalnegocio,isnull(pt.idcanalnegocio,vdsintese.idcanalnegocio))))))))))))
-------,ISNULL(a.idfilial,isnull(vdgreg.idfilial,isnull(vd364.idfilial,  isnull(atualgregsss.idfilial, isnull(atual364sss.idfilial, isnull(vdgregsss.idfilial, isnull(vd364sss.idfilial, isnull(metafl.idfilial, isnull(metavd.idfilial, isnull(b.idfilial,isnull(dn.idfilial,isnull(pt.idfilial,vdsintese.idfilial))))))))))))
-------,ISNULL(a.idvendedor,isnull(vdgreg.idvendedor,isnull(vd364.idvendedor,  isnull(atualgregsss.idvendedor, isnull(atual364sss.idvendedor, isnull(vdgregsss.idvendedor, isnull(vd364sss.idvendedor, isnull(metafl.idvendedor, isnull(metavd.idvendedor, isnull(b.idvendedor,isnull(dn.idvendedor,isnull(pt.idvendedor,vdsintese.idvendedor))))))))))))
---------,ISNULL(a.idmarca,isnull(vdgreg.idmarca,isnull(vd364.idmarca,  isnull(atualgregsss.idmarca, isnull(atual364sss.idmarca, isnull(vdgregsss.idmarca, isnull(vd364sss.idmarca, isnull(metafl.idmarca, isnull(metavd.idmarca, b.idmarca)))))))))
---------,ISNULL(a.idmarca2,isnull(vdgreg.idmarca2,isnull(vd364.idmarca2,  isnull(atualgregsss.idmarca2, isnull(atual364sss.idmarca2, isnull(vdgregsss.idmarca2, isnull(vd364sss.idmarca2, isnull(metafl.idmarca2, isnull(metavd.idmarca2, b.idmarca2)))))))))
-------,ISNULL(a.[Supervisor],isnull(vdgreg.[Supervisor],isnull(vd364.[Supervisor], isnull(atualgregsss.[Supervisor], isnull(atual364sss.[Supervisor], isnull(vdgregsss.[Supervisor], isnull(vd364sss.[Supervisor], isnull(metafl.[Supervisor], isnull(metavd.[Supervisor], isnull(b.[Supervisor],isnull(dn.SupervisorAtual,isnull(pt.SupervisorAtual,vdsintese.Supervisor))))))))))))
-------,ISNULL(a.[Flag Atividade],isnull(vdgreg.[Flag Atividade],isnull(vd364.[Flag Atividade], isnull(atualgregsss.[Flag Atividade], isnull(atual364sss.[Flag Atividade], isnull(vdgregsss.[Flag Atividade], isnull(vd364sss.[Flag Atividade], isnull(metafl.[Flag Atividade], isnull(metavd.[Flag Atividade], isnull(b.[Flag Atividade],isnull(dn.[Flag Atividade],isnull(pt.[Flag Atividade],vdsintese.[Flag Atividade]))))))))))))
-------,ISNULL(a.[Franqueado],isnull(vdgreg.[Franqueado],isnull(vd364.[Franqueado], isnull(atualgregsss.[Franqueado], isnull(atual364sss.[Franqueado], isnull(vdgregsss.[Franqueado], isnull(vd364sss.[Franqueado], isnull(metafl.[Franqueado], isnull(metavd.[Franqueado], isnull(b.[Franqueado],isnull(dn.[Franqueado],isnull(pt.[Franqueado],vdsintese.[Franqueado]))))))))))))


ISNULL(a.data,isnull(vdgreg.data,isnull(vd364.data, isnull(atualgregsss.data, isnull(atual364sss.data, isnull(vdgregsss.data, isnull(vd364sss.data, isnull(metafl.data, isnull(metavd.data, isnull(b.data,isnull(dn.data,isnull(pt.data,isnull(vdsintese.data,dmr.data))))))))))))),
ISNULL(a.idcanal,isnull(vdgreg.idcanal,isnull(vd364.idcanal,  isnull(atualgregsss.idcanal, isnull(atual364sss.idcanal, isnull(vdgregsss.idcanal, isnull(vd364sss.idcanal, isnull(metafl.idcanal, isnull(metavd.idcanal, isnull(b.idcanal,isnull(dn.idcanal,isnull(pt.idcanal,isnull(vdsintese.idcanal,dmr.idcanal))))))))))))),
ISNULL(a.idcanalnegocio,isnull(vdgreg.idcanalnegocio,isnull(vd364.idcanalnegocio,  isnull(atualgregsss.idcanalnegocio, isnull(atual364sss.idcanalnegocio, isnull(vdgregsss.idcanalnegocio, isnull(vd364sss.idcanalnegocio, isnull(metafl.idcanalnegocio, isnull(metavd.idcanalnegocio, isnull(b.idcanalnegocio,isnull(dn.idcanalnegocio,isnull(pt.idcanalnegocio,isnull(vdsintese.idcanalnegocio,dmr.idcanalnegocio))))))))))))),
ISNULL(a.idfilial,isnull(vdgreg.idfilial,isnull(vd364.idfilial,  isnull(atualgregsss.idfilial, isnull(atual364sss.idfilial, isnull(vdgregsss.idfilial, isnull(vd364sss.idfilial, isnull(metafl.idfilial, isnull(metavd.idfilial, isnull(b.idfilial,isnull(dn.idfilial,isnull(pt.idfilial,isnull(vdsintese.idfilial,dmr.idfilial))))))))))))),
ISNULL(a.idvendedor,isnull(vdgreg.idvendedor,isnull(vd364.idvendedor,  isnull(atualgregsss.idvendedor, isnull(atual364sss.idvendedor, isnull(vdgregsss.idvendedor, isnull(vd364sss.idvendedor, isnull(metafl.idvendedor, isnull(metavd.idvendedor, isnull(b.idvendedor,isnull(dn.idvendedor,isnull(pt.idvendedor,isnull(vdsintese.idvendedor,dmr.idvendedor))))))))))))),
ISNULL(a.[Supervisor],isnull(vdgreg.[Supervisor],isnull(vd364.[Supervisor], isnull(atualgregsss.[Supervisor], isnull(atual364sss.[Supervisor], isnull(vdgregsss.[Supervisor], isnull(vd364sss.[Supervisor], isnull(metafl.[Supervisor], isnull(metavd.[Supervisor], isnull(b.[Supervisor],isnull(dn.SupervisorAtual,isnull(pt.SupervisorAtual,isnull(vdsintese.Supervisor,dmr.SupervisorAtual))))))))))))),
ISNULL(a.[Flag Atividade],isnull(vdgreg.[Flag Atividade],isnull(vd364.[Flag Atividade], isnull(atualgregsss.[Flag Atividade], isnull(atual364sss.[Flag Atividade], isnull(vdgregsss.[Flag Atividade], isnull(vd364sss.[Flag Atividade], isnull(metafl.[Flag Atividade], isnull(metavd.[Flag Atividade], isnull(b.[Flag Atividade],isnull(dn.[Flag Atividade],isnull(pt.[Flag Atividade],isnull(vdsintese.[Flag Atividade],dmr.[Flag Atividade]))))))))))))),
ISNULL(a.[Franqueado],isnull(vdgreg.[Franqueado],isnull(vd364.[Franqueado], isnull(atualgregsss.[Franqueado], isnull(atual364sss.[Franqueado], isnull(vdgregsss.[Franqueado], isnull(vd364sss.[Franqueado], isnull(metafl.[Franqueado], isnull(metavd.[Franqueado], isnull(b.[Franqueado],isnull(dn.[Franqueado],isnull(pt.[Franqueado],isnull(vdsintese.[Franqueado],dmr.[Franqueado])))))))))))))




) B
LEFT JOIN #auxsss ASSS on ASSS.Idfilial = b.IdFilial and ASSS.mes = datepart(month,b.data)
LEFT JOIN [RESERVA_DW].[dbo].[tbDimData]           D  WITH(NOLOCK) ON D.Data = B.Data
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFILIAL]         F WITH(NOLOCK) ON f.idFilial = B.idfilial
LEFT JOIN #filialcorner FC on FC.CodFilial = F.codfilial
LEFT JOIN #filialcornerreversa FR on FR.codfilial = F.codfilial
LEFT JOIN #filialcornerbaw FB on FB.codfilial = F.codfilial
LEFT JOIN #filialcornerreserva FRS on FRS.codfilial = F.codfilial --join adicionado 15/08/23
LEFT JOIN #filialcornersimples FS on FS.codfilial = F.codfilial
LEFT JOIN #filialcornerGO FG on FG.codfilial = F.codfilial
LEFT JOIN #filialcorneroficina FCO on FCO.codfilial = F.codfilial
LEFT JOIN #top20 tp on tp.IdVendedor = b.IdVendedor
LEFT JOIN [RESERVA_DW].[dbo].[tbDimVendedor] v on ISNULL(B.[IdVendedor] 	 , 0) = v.idvendedor
--LEFT JOIN #atividadefilial af on af.Idfilial = B.IdFilial and af.Data = B.Data
where B.Data >= @dataexclusao


update [dbo].[AGG_VD_CN_FL_VDD_MC_DIA] 
set idfilial = isnull(idnovo,idfilial)
from  [dbo].[AGG_VD_CN_FL_VDD_MC_DIA]  a
inner join #auxmudarfilial b on b.idantigo = a.idfilial


END
GO
