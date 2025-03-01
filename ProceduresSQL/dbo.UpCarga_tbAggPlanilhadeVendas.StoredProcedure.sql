USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[UpCarga_tbAggPlanilhadeVendas]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO













CREATE  PROCEDURE [dbo].[UpCarga_tbAggPlanilhadeVendas]
AS
BEGIN



----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
---------------------------------------PARAMETROS DE DATA-------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

declare @data               Date = CONVERT(DATE,DATEADD(DAY,-1,GETDATE()))
declare @IniMes             Date = CONVERT(DATE,DATEADD(DAY,-1*(DATEPART(DAY,@data)-1),@data))
declare @FimMes             Date = DATEADD(DAY,-1,DATEADD(MONTH,1,@IniMes))
declare @IniMesPassado      Date = DATEADD(month,-1,@inimes)
declare @IniMesPassado2     Date = DATEADD(month,-2,@inimes)
declare @FimMesPassado      Date = DATEADD(DAY,-1,@inimes)
declare @FimMesPassado2     Date = DATEADD(DAY,-1,@IniMesPassado)
declare @inimespassadogreg  Date = DATEADD(year, -1, @IniMesPassado)
declare @inimespassado364   Date = DATEADD(day, -364, @IniMesPassado)
declare @fimmesgreg         Date = DATEADD(year, -1, @fimmes)
declare @fimmes364          Date = DATEADD(day, -364, @fimmes)
declare @dataexclusao       Date = (CASE WHEN datepart(day,getdate()) <=  1 then @IniMes else @IniMes end)
declare @dataexclusaofim    Date = (CASE WHEN datepart(day,getdate()) <=  1 then @data else @data end)

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR PARA ATUALIZACAO DA FILIAL (CASO MUDANCA DE CNPJ)-----------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#auxmudarfilial') IS NOT NULL

DROP TABLE #auxmudarfilial

select  distinct f.Filial filialantigo, max(f2.Filial) filialnovo into #auxmudarfilial 
from  [reserva_ods].[dbo].[tbOdsLinxDeParaFiliais] a
left join tbdimfilial f with(nolock) on f.codfilial = a.codfilialantigo
left join tbdimfilial f2 with(nolock) on f2.codfilial = a.codfilialnovo
where f2.[Flag Atividade] = 'Ativa'
group by f.Filial

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIARES PARA VERIFICAR SE A FILIAL TEM CORNER---------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#filialcornermini') IS NOT NULL
DROP TABLE #filialcornermini 
IF OBJECT_ID('tempdb..#filialcornergo') IS NOT NULL
DROP TABLE #filialcornergo
IF OBJECT_ID('tempdb..#filialcornerreserva') IS NOT NULL
DROP TABLE #filialcornerreserva
IF OBJECT_ID('tempdb..#filialcornerreversa') IS NOT NULL
DROP TABLE #filialcornerreversa
IF OBJECT_ID('tempdb..#filialcorneroficina') IS NOT NULL
DROP TABLE #filialcorneroficina
IF OBJECT_ID('tempdb..#filialcornerbaw') IS NOT NULL
DROP TABLE #filialcornerbaw
IF OBJECT_ID('tempdb..#filialcornersimples') IS NOT NULL
DROP TABLE #filialcornersimples

select distinct codfilial, [PossuiCornerMini] = 'Sim' into #filialcornermini from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'RESERVA MINI' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'RESERVA MINI'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerGo] = 'Sim' into #filialcornergo from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'GO' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'GO'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerOficina] = 'Sim' into #filialcorneroficina from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'OFICINA RESERVA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'OFICINA RESERVA'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerReversa] = 'Sim' into #filialcornerreversa from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'REVERSA' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'REVERSA'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerBaw] = 'Sim' into #filialcornerBaw from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'Baw' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'Baw'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerSimples] = 'Sim' into #filialcornerSimples from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'Simples' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'Simples'
group by a.codfilial) a

select distinct codfilial, [PossuiCornerReserva] = 'Sim' into #filialcornerReserva from 
(SELECT distinct a.codfilial, meta = sum(case when
griffeagrupada = 'Reserva' then (meta) else 0 end) from [RESERVA_ODS].[dbo].[tbOdsLinxMetaFilial] a with(nolock)
 full join [RESERVA_ODS].[dbo].[tbOdsLinxMarca] b with(nolock) on b.CodFilial = a.CodFilial
where data between @dataexclusao and @FimMes and isnull(b.marca,a.letreiro) <> 'Reserva'
group by a.codfilial) a

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR DE META PARA VALIDACAO DE VALIDADE SSSG---------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#tbmetas') IS NOT NULL

DROP TABLE #tbmetas

select data, idfilial, [Meta Atual], SSS364 = case when [Meta Atual] <> 0 and [Meta 364 (n-1)] <> 0 then 'Sim' else 'Não' end,
SSSGREG = case when [Meta Atual] <> 0 and [Meta Greg (n-1)] <> 0 then 'Sim' else 'Não' end
 INTO	#tbmetas
 FROM
(
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
) b

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR PARA VALIDACAO DE ATIVIDADE DA FILIAL-----------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

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

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR PARA VALORES DE REGRA DE FECHAMENTO-------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#auxcancelados') IS NOT NULL

DROP TABLE #auxcancelados

select data, [Promotor],idcanal, IdCanalNegocio, idfilial, idvendedor, idprodutos, [Cancelado]
into #auxcancelados
from (
select convert(date,@fimmespassado) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial] 
       ,[IdVendedor] 
       ,idprodutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = sum( [Valor Cancelado])
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a 
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
--left join tbdimfilial f on f.idfilial = a.idfilial
--left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado or convert(date,[Data Cancelamento])  = dateadd(day,1,@fimmespassado)) and IdTabela = '1'
and d1.Data between @IniMesPassado and @FimMesPassado and meiovenda in ('plano b','stv')
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]  
       ,[IdVendedor] 
       ,IdProdutos
	   ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end


UNION ALL 


select convert(date,@fimmespassado2) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = sum( [Valor Cancelado])
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
--left join tbdimfilial f on f.idfilial = a.idfilial
--left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado2 or convert(date,[Data Cancelamento])  = dateadd(day,1,@fimmespassado2)) and IdTabela = '1'
and d1.Data between @IniMesPassado2 and @FimMesPassado2 and meiovenda in ('plano b','stv')
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end


UNION ALL 


select convert(date,@fimmes) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = sum( [Valor Cancelado])
	  -- ,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
--left join tbdimfilial f on f.idfilial = a.idfilial
--left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @FimMes or convert(date,[Data Cancelamento])  = dateadd(day,1,@FimMes)) and IdTabela = '1'
and d1.Data between @IniMes and @fimmes and meiovenda in ('plano b','stv')
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   --,ma.[IdMarca]

UNION ALL 

select  dateadd(day,1,convert(date,@fimmespassado)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = -1*sum( [Valor Cancelado])
	   --,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
--left join tbdimfilial f on f.idfilial = a.idfilial
--left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado ) and IdTabela = '1'
and d1.Data between @IniMesPassado and @FimMesPassado and meiovenda in ('plano b','stv')
group by [IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
      ,IdProdutos
	  ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end

UNION ALL 

select  dateadd(day,1,convert(date,@fimmespassado2)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = -1*sum( [Valor Cancelado])
	   --,ma.[IdMarca] as Idmarca2
	   FROM
[dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d1 on d1.iddata = a.iddata
left join tbDimPromotorVenda p on p.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m on m.IdMeioVenda = a.IdMeioVendaOriginal
--left join tbdimfilial f on f.idfilial = a.idfilial
--left join #atividadefilial af on af.idfilial = f.idfilial
--left join tbdimprodutos pr on pr.idprodutos = a.idprodutos
--left join tbDimMarca ma on ma.SubmarcaGestão = pr.Griffe

where (convert(date,[Data Cancelamento])  = @fimmespassado2 ) and IdTabela = '1'
and d1.Data between @IniMesPassado2 and @FimMesPassado2 and meiovenda in ('plano b','stv')
and convert(date,[Data Cancelamento]) <> '2022-06-01'
group by [IdCanal] 
       ,[IdCanalNegocio] 
       , a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   
UNION ALL 

select  dateadd(day,1,convert(date,@fimmes)) as Data
       ,[IdCanal] 
       ,[IdCanalNegocio] 
       ,a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,Promotor = case when meiovenda = 'plano b' then 'Plano B' else 'STV' end
	   ,[Cancelado]              = -1*sum( [Valor Cancelado])
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

where (convert(date,[Data Cancelamento])  = @fimmes ) and IdTabela = '1'
and d1.Data between @inimes and @fimmes and meiovenda in ('plano b','stv')
group by [IdCanal] 
       ,[IdCanalNegocio] 
       , a.[IdFilial]   
       ,[IdVendedor] 
       ,IdProdutos
	   ,case when meiovenda = 'plano b' then 'Plano B' else 'STV' end

	   ) c
--left join tbdimdata d1 on d1.data = c.Data
where [Cancelado] <> 0

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIARES PARA FUTURO UNION ALL-------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR DE CANCELADOS (REGRA DE FECHAMENTO)-------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#cancelados') IS NOT NULL

DROP TABLE #cancelados


SELECT [Data]                     = [Data]
      ,[Canal]					  = [Canal]
      ,[CanalNegocio]			  = [CanalNegocio]
      ,[idfilial]				  = [idfilial]
      ,[idvendedor]				  = [idvendedor]
      ,[Id-Pedido/Ticket]         = '(Não Informado)'
      ,[MarcaProduto]             = [Marca Produto]
	  ,[Promotor]                 = [Promotor]
      ,[VendaAtual]				  = 0
      ,[Venda364]				  = 0
      ,[VendaGreg]				  = 0
      ,[VendaAtualGregSSS]		  = 0
      ,[VendaAtual364SSS]		  = 0
      ,[VendaGregSSS]			  = 0
      ,[Venda364SSS]			  = 0
      ,[CanceladoFechamento]      = [Cancelado]
      ,[QtdeVenda]                = 0
      ,[MetaFilial]				  = 0
      ,[MetaVendedor]			  = 0
	  into #cancelados
from #auxcancelados a
left join tbDimCanal c with(nolock) on c.IdCanal = a.idcanal
left join tbdimcanalnegocio cn with(nolock) on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbDimProdutos p with(nolock) on p.IdProdutos = a.IdProdutos
left join tbdimmarca m with(nolock) on m.SubmarcaGestão = p.griffe

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR VENDAS ATUAIS-----------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#atual') IS NOT NULL

DROP TABLE #atual

SELECT [Data]                     = d.data
      ,[Canal]
      ,[CanalNegocio]
      ,[idfilial]                 = a.idfilial
      ,[idvendedor] 
      ,[Id-Pedido/Ticket] = CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      ,[MarcaProduto] = [Marca Produto]
	  ,[Promotor]                 = CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END
      ,[VendaAtual]				  = sum([Valor Venda])
      ,[Venda364]				  = 0
      ,[VendaGreg]				  = 0
      ,[VendaAtualGregSSS]		  = sum(case when SSSGREG = 'Sim' then [Valor Venda] else 0 end)
      ,[VendaAtual364SSS]		  = sum(case when SSS364 = 'Sim' then [Valor Venda] else 0 end)
      ,[VendaGregSSS]			  = 0
      ,[Venda364SSS]			  = 0
      ,[CanceladoFechamento]      = sum(CASE WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then [Valor Cancelado] else 0 END)
      ,[QtdeVenda]                = sum([quantidade venda])
      ,[MetaFilial]				  = 0
      ,[MetaVendedor]			  = 0
	  into #atual
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimCanal c with(nolock) on c.IdCanal = a.idcanal
left join tbdimcanalnegocio cn with(nolock) on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbDimProdutos p with(nolock) on p.IdProdutos = a.IdProdutos
left join tbdimmarca ma with(nolock) on ma.SubmarcaGestão = p.griffe
left join tbDimPromotorVenda pr with(nolock)  on pr.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m with(nolock)  on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t with(nolock)  on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbdimfilial fl on fl.IdFilial = a.IdFilial
left join #tbmetas me on me.Idfilial = a.IdFilial and me.data =  d.data
WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and d.Data between @IniMesPassado and @FimMes and IdTabela = '1'
and TipoFilial in ('Loja','Franquia')
group by 
d.[Data]
      ,[Canal]
      ,[CanalNegocio]
      ,a.[idfilial]
      ,[idvendedor]
      , CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      , [Marca Produto]
	  , CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR VENDAS GREGORIANA-------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#greg') IS NOT NULL

DROP TABLE #greg


SELECT [Data]                     = dateadd(year,1,d.data)
      ,[Canal]
      ,[CanalNegocio]
      ,[idfilial]                 = a.idfilial
      ,[idvendedor]
      ,[Id-Pedido/Ticket] = CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      ,[MarcaProduto] = [Marca Produto]
	  ,[Promotor]                 = CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END
      ,[VendaAtual]				  = 0
      ,[Venda364]				  = 0
      ,[VendaGreg]				  = sum([Valor Venda])
      ,[VendaAtualGregSSS]		  = 0
      ,[VendaAtual364SSS]		  = 0
      ,[VendaGregSSS]			  = sum(case when SSSGREG = 'Sim' then [Valor Venda] else 0 end)
      ,[Venda364SSS]			  = 0
      ,[CanceladoFechamento]      = 0
      ,[QtdeVenda]                = 0
      ,[MetaFilial]				  = 0
      ,[MetaVendedor]			  = 0
	  into #greg
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimCanal c with(nolock) on c.IdCanal = a.idcanal
left join tbdimcanalnegocio cn with(nolock) on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbDimProdutos p with(nolock) on p.IdProdutos = a.IdProdutos
left join tbdimmarca ma with(nolock) on ma.SubmarcaGestão = p.griffe
left join tbDimPromotorVenda pr with(nolock)  on pr.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m with(nolock)  on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t with(nolock)  on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbdimfilial fl on fl.IdFilial = a.IdFilial
left join #tbmetas me on me.Idfilial = a.IdFilial and me.data =  dateadd(year,1,d.data)
WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and d.Data between @inimespassadogreg and dateadd(month,1,@fimmesgreg)  and IdTabela = '1'
and TipoFilial in ('Loja','Franquia')
group by 
dateadd(year,1,d.data)
      ,[Canal]
      ,[CanalNegocio]
      ,a.[idfilial]
      ,[idvendedor]
      , CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      , [Marca Produto]
	  , CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR VENDAS 364--------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#364') IS NOT NULL

DROP TABLE #364

SELECT [Data]                     = dateadd(day,364,d.data)
      ,[Canal]
      ,[CanalNegocio]
      ,[idfilial]                 = a.idfilial
      ,[idvendedor]
      ,[Id-Pedido/Ticket] = CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      ,[MarcaProduto] = [Marca Produto]
	  ,[Promotor]                 = CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END
      ,[VendaAtual]				  = 0
      ,[Venda364]				  = sum([Valor Venda])
      ,[VendaGreg]				  = 0
      ,[VendaAtualGregSSS]		  = 0
      ,[VendaAtual364SSS]		  = 0
      ,[VendaGregSSS]			  = 0
      ,[Venda364SSS]			  = sum(case when SSS364 = 'Sim' then [Valor Venda] else 0 end)
      ,[CanceladoFechamento]      = 0
      ,[QtdeVenda]                = 0
      ,[MetaFilial]				  = 0
      ,[MetaVendedor]			  = 0
	  into #364
FROM [dbo].[tbFatoVendaItemTableau] a
left join tbdimdata d on d.iddata = a.iddata
left join tbDimCanal c with(nolock) on c.IdCanal = a.idcanal
left join tbdimcanalnegocio cn with(nolock) on cn.IdCanalNegocio = a.IdCanalNegocio
left join tbDimProdutos p with(nolock) on p.IdProdutos = a.IdProdutos
left join tbdimmarca ma with(nolock) on ma.SubmarcaGestão = p.griffe
left join tbDimPromotorVenda pr with(nolock)  on pr.IdPromotorVenda = a.IdPromotorVenda
left join tbDimMeioVenda m with(nolock)  on m.IdMeioVenda = a.IdMeioVendaOriginal
left join tbDimTipoAtendimento t with(nolock)  on t.IdTipoAtendimento = a.IdTipoAtendimento
left join tbdimpedido pd on pd.idpedido = a.idpedido
left join tbdimfilial fl on fl.IdFilial = a.IdFilial
left join #tbmetas me on me.Idfilial = a.IdFilial and me.data =  dateadd(day,364,d.data)
WHERE (MeioVenda in ('local', 'delivery','plano b') or TipoAtendimento = 'reservado' or PromotorVenda = 'stv')
and d.Data between @inimespassado364 and dateadd(month,1,@fimmes364) and IdTabela = '1'
and TipoFilial in ('Loja','Franquia')
group by 
dateadd(day,364,d.data)
      ,[Canal]
      ,[CanalNegocio]
      ,a.[idfilial]
      ,[idvendedor]
      , CASE WHEN [Valor Venda] <= 0 then NULL else 
	  CONVERT(varchar,CASE WHEN canalnegocio = 'online' then pedidooriginal else   convert(varchar,a.[idticket]) end) END
      , [Marca Produto]
	  , CASE WHEN MeioVenda = 'Plano B' then 'Plano B'
	                                     WHEN PromotorVenda = 'STV' then 'STV'
										 WHEN TipoAtendimento = 'reservado' then 'Mala'
										 WHEN MeioVenda = 'Local' and TipoAtendimento <> 'reservado' then 'Chão de Loja'
										 WHEN MeioVenda = 'Delivery' and TipoAtendimento <> 'reservado' then 'Delivery'
										 END
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR METAS DA FILIAL---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#metafilial') IS NOT NULL

DROP TABLE #metafilial


SELECT [Data]                     
      ,[Canal]                    = '(Não Informado)'
      ,[CanalNegocio]			  = '(Não Informado)'
      ,[idfilial]                 = a.idfilial
      ,[idvendedor]               = 0
      ,[Id-Pedido/Ticket]         = '(Não Informado)'
      ,[MarcaProduto]             = '(Não Informado)'
	  ,[Promotor]                 = '(Não Informado)'
      ,[VendaAtual]				  = 0
      ,[Venda364]				  = 0
      ,[VendaGreg]				  = 0
      ,[VendaAtualGregSSS]		  = 0
      ,[VendaAtual364SSS]		  = 0
      ,[VendaGregSSS]			  = 0
      ,[Venda364SSS]			  = 0
      ,[CanceladoFechamento]      = 0
      ,[QtdeVenda]                = 0
      ,[MetaFilial]				  = sum([Meta Atual])
      ,[MetaVendedor]			  = 0
	  into #metafilial
	  FROM [dbo].[tbFatoMetaFilialTableau] a
	  left join tbdimdata d on d.iddata = a.iddata
	  where Data between @inimespassado and @fimmes 
	  GROUP BY 
	  DATA
	  ,a.idfilial

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR METAS DO VENDEDOR-------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#metavendedor') IS NOT NULL

DROP TABLE #metavendedor

SELECT [Data]                     
      ,[Canal]                    = '(Não Informado)'
      ,[CanalNegocio]			  = '(Não Informado)'
      ,[idfilial]                 = a.idfilial
      ,[idvendedor]               = [IdVendedor]
      ,[Id-Pedido/Ticket]         = '(Não Informado)'
      ,[MarcaProduto]             = '(Não Informado)'
	  ,[Promotor]                 = '(Não Informado)'
      ,[VendaAtual]				  = 0
      ,[Venda364]				  = 0
      ,[VendaGreg]				  = 0
      ,[VendaAtualGregSSS]		  = 0
      ,[VendaAtual364SSS]		  = 0
      ,[VendaGregSSS]			  = 0
      ,[Venda364SSS]			  = 0
      ,[CanceladoFechamento]      = 0
      ,[QtdeVenda]                = 0
      ,[MetaFilial]				  = 0
      ,[MetaVendedor]			  = sum([Meta])
	  into #metavendedor
	  FROM [dbo].[tbFatoMetaVendedorTableau] a
	  left join tbdimdata d on d.iddata = a.iddata
	  where Data between @inimespassado and @fimmes 
	  GROUP BY 
	  DATA
	  ,a.idfilial
	  ,[IdVendedor]

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------AUXILIAR FINA - UNINDO TODAS AS ANTERIORES---------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
	  	  
IF OBJECT_ID('tempdb..#auxfinal') IS NOT NULL

DROP TABLE #auxfinal

select distinct 
Data
,Canal
,CanalNegocio
,idfilial
,idvendedor
,[Id-Pedido/Ticket]
,MarcaProduto
,Promotor
,VendaAtual = sum(VendaAtual)
,Venda364 =sum(Venda364)
,VendaGreg = sum(VendaGreg)
,VendaAtualGregSSS = sum(VendaAtualGregSSS)
,VendaAtual364SSS = sum(VendaAtual364SSS)
,VendaGregSSS = sum(VendaGregSSS)
,Venda364SSS = sum(Venda364SSS)
,CanceladoFechamento = sum(CanceladoFechamento)
,QtdeVenda = sum(QtdeVenda)
,MetaFilial = sum(MetaFilial)
,MetaVendedor = sum(MetaVendedor)
into #auxfinal FROm
(
select * from #cancelados
UNION ALL
select * from #atual
UNION ALL
select * from #greg
UNION ALL
select * from #364
UNION ALL
select * from #metafilial
UNION ALL
select * from #metavendedor
) a
GROUP BY 
Data
,Canal
,CanalNegocio
,idfilial
,idvendedor
,[Id-Pedido/Ticket]
,MarcaProduto
,Promotor

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------DELETE INSERT NA TABELA FINAL AGG PLAN DE VENDAS---------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

delete a from [dbo].[tbAggPlanilhadeVendas] a
where Data >= @dataexclusao

INSERT INTO [dbo].[tbAggPlanilhadeVendas]
select 
[Data]
      ,[Canal]
      ,[CanalNegocio]
      ,[CodFilial]               = f.CodFilial
      ,[MarcaFilial]             = Marca
      ,[TipoFilial]              = f.TipoFilial
      ,[Filial]                  = f.Filial
      ,[AtividadeFilial]         = CASE WHEN atividade = 'Ativa' then 'Ativa' else 'Inativa' end
      ,[FilialOFF]               = [Loja OFF]
      ,[FilialReforma]           = [Loja Reforma]
      ,[DataInauguracaoReforma]  = [Data Inauguração Reforma]
      ,[PossuiCornerMini]        = ISNULL([PossuiCornerMini]   ,'Não')
      ,[PossuiCornerReversa]	 = ISNULL([PossuiCornerReversa],'Não')
      ,[PossuiCornerBaw]		 = ISNULL([PossuiCornerBaw]	   ,'Não')
      ,[PossuiCornerSimples]	 = ISNULL([PossuiCornerSimples],'Não')
      ,[PossuiCornerGO]			 = ISNULL([PossuiCornerGO]	   ,'Não')
      ,[PossuiCornerOficina]	 = ISNULL([PossuiCornerOficina],'Não')
      ,[PossuiCornerReserva]	 = ISNULL([PossuiCornerReserva],'Não')
      ,[Supervisor]              = ISNULL(f.SupervisorAtual,'(Não Informado)')
      ,[Franqueado]              = ISNULL(f.[Franqueado],'(Não Informado)')
      ,[Gerente]                 = ISNULL(f.Gerente,'(Não Informado)')
      ,[GerenteComercial]        = ISNULL(f.[Gerente Comercial],'(Não Informado)')
      ,[Vendedor]                
      ,[AtividadeVendedor]       =  CASE WHEN DataDesativacao is null then 'Ativo' else 'Inativo' END
      ,[Id-Pedido/Ticket]
      ,[MarcaProduto]
      ,[Promotor]
      ,[VendaAtual]
      ,[Venda364]
      ,[VendaGreg]
      ,[VendaAtualGregSSS]
      ,[VendaAtual364SSS]
      ,[VendaGregSSS]
      ,[Venda364SSS]
      ,[CanceladoFechamento]
      ,[QtdeVenda]
      ,[MetaFilial]
      ,[MetaVendedor]
from #auxfinal a
left join #atividadefilial at on at.Idfilial = a.idfilial
left join tbDimFilial f with(nolock) on f.IdFilial = a.idfilial
left join tbDimVendedor v with(nolock) on v.IdVendedor = a.IdVendedor
left join #filialcornermini cm on cm.CodFilial = f.CodFilial
left join #filialcornergo cg on cg.CodFilial = f.CodFilial
left join #filialcornerBaw cb on cb.CodFilial = f.CodFilial
left join #filialcornerSimples cs on cs.CodFilial = f.CodFilial
left join #filialcornerreversa crv on crv.CodFilial = f.CodFilial
left join #filialcornerReserva crs on crs.CodFilial = f.CodFilial
left join #filialcorneroficina co on co.CodFilial = f.CodFilial
where Data >= @dataexclusao

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------ATUALIZACAO DA FILIAL CASO TENHA OCORRIDO MUDANCAS DE CNPJ-----------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

update [dbo].[tbAggPlanilhadeVendas]
set filial = isnull(filialnovo,filialantigo)
from  [dbo].[tbAggPlanilhadeVendas]  a
inner join #auxmudarfilial b on b.filialantigo = a.Filial

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------DELETE INSERT NA TABELA FINAL AGG RKG TIPO PROMOTOR------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------



delete a from [dbo].[tbAggPlanilhadeRkg] a with(nolock)
where Data >= @dataexclusao
and [Tipo]  = 'Rkg Promotor'

INSERT INTO [dbo].[tbAggPlanilhadeRkg]
select distinct 
[Data]
      ,[Canal]
      ,[CanalNegocio]
      ,[CodFilial]               = f.CodFilial
      ,[MarcaFilial]             = Marca
      ,[TipoFilial]              = f.TipoFilial
      ,[Filial]                  = f.Filial
      ,[AtividadeFilial]         = CASE WHEN atividade = 'Ativa' then 'Ativa' else 'Inativa' end
      ,[Supervisor]              = ISNULL(f.SupervisorAtual,'(Não Informado)')
      ,[Franqueado]              = ISNULL(f.[Franqueado],'(Não Informado)')
      ,[Gerente]                 = ISNULL(f.Gerente,'(Não Informado)')
      ,[GerenteComercial]        = ISNULL(f.[Gerente Comercial],'(Não Informado)')
      ,[Vendedor]                
      ,[AtividadeVendedor]       =  CASE WHEN DataDesativacao is null then 'Ativo' else 'Inativo' END
	  ,[Tipo]                    = 'Rkg Promotor'
      ,[Promotor]
	  ,[Indicador]               = 'Não Possui'
      ,[VendaAtual]              = sum([VendaAtual]          )
      ,[Venda364]				 = sum([Venda364]			 )
      ,[VendaGreg]				 = sum([VendaGreg]			 )
      ,[VendaAtualGregSSS]		 = sum([VendaAtualGregSSS]	 )
      ,[VendaAtual364SSS]		 = sum([VendaAtual364SSS]	 )
      ,[VendaGregSSS]			 = sum([VendaGregSSS]		 )
      ,[Venda364SSS]			 = sum([Venda364SSS]		 )
      ,[QtdeTickets]             = count(distinct(case when [Id-Pedido/Ticket] = '(Não Informado)' or  [VendaAtual] = 0 then null else [Id-Pedido/Ticket] end))
      ,[QtdePecas]				 = sum([QtdeVenda])
	  ,[MetaFilial]              = sum([MetaFilial])
	  ,[MetaVendedor]            = sum([MetaVendedor])
	  ,[CanceladoFechamento]     = sum([CanceladoFechamento])
from #auxfinal a
left join #atividadefilial at on at.Idfilial = a.idfilial
left join tbDimFilial f with(nolock) on f.IdFilial = a.idfilial
left join tbDimVendedor v with(nolock) on v.IdVendedor = a.IdVendedor
where Data >= @dataexclusao
and Promotor <> '(Não Informado)'
GROUP BY 
       [Data]
      ,[Canal]
      ,[CanalNegocio]
      ,f.CodFilial
      ,Marca
      ,f.TipoFilial
      ,f.Filial
      ,CASE WHEN atividade = 'Ativa' then 'Ativa' else 'Inativa' end
      ,ISNULL(f.SupervisorAtual,'(Não Informado)')
      ,ISNULL(f.[Franqueado],'(Não Informado)')
      ,ISNULL(f.Gerente,'(Não Informado)')
      ,ISNULL(f.[Gerente Comercial],'(Não Informado)')
      ,[Vendedor]
      ,CASE WHEN DataDesativacao is null then 'Ativo' else 'Inativo' END
      ,[Promotor]

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-------------------------------ATUALIZACAO DA FILIAL CASO TENHA OCORRIDO MUDANCAS DE CNPJ-----------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

update [dbo].[tbAggPlanilhadeRkg]
set filial = isnull(filialnovo,filialantigo)
from  [dbo].[tbAggPlanilhadeRkg]  a
inner join #auxmudarfilial b on b.filialantigo = a.Filial


END
GO
