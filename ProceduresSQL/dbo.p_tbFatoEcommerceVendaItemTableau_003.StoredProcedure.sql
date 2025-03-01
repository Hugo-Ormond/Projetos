USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[p_tbFatoEcommerceVendaItemTableau_003]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















CREATE PROCEDURE [dbo].[p_tbFatoEcommerceVendaItemTableau_003] @data_ini datetime

AS




IF OBJECT_ID('tempdb..#aux') IS NOT NULL
DROP TABLE #aux

select * 
into #aux 
from	(	SELECT	DISTINCT isnull(isnull(codpedidovtex,codpedido),'(Não Informado)') pedido, site, codproduto,
					max(convert(date,dataprevisaoentrega)) DataPrevisaoEntrega--, count(distinct(dataprevisaoentrega)) datas
			FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceVendaItem] WITH (NOLOCK)
			WHERE isnull(isnull(codpedidovtex,codpedido),'(Não Informado)') <> ''
				and site <> '' and site is not null and codproduto <> '' and codproduto is not null and DataPrevisaoEntrega is not null
			GROUP BY  isnull(codpedidovtex,codpedido), site, codproduto
		) a --where datas = '1'

-------------------data limite de expedição e data limite de On Demand-------------------
IF OBJECT_ID('tempdb..#auxCD') IS NOT NULL
DROP TABLE #auxCD

SELECT DISTINCT CD.Pedido, DataLimiteExpedicao, DataLimiteOD, VE.PedidoCliente
INTO #auxCD
FROM RESERVA_ODS..tbodscdpedidos CD	WITH (NOLOCK)
LEFT JOIN RESERVA_ODS..tbOdsLinxVendas VE	WITH (NOLOCK) ON CD.PEDIDO = VE.Pedido



select distinct datavenda [data] into #auxdatas from reserva_ods..tbodslinxvendaitem
where DataVenda >= @data_ini or datafaturamento >= dateadd(day,-10,getdate())


SELECT	ev2.DataPrevisaoEntrega as [DataPrevisãoEntrega] ,
		CD.DataLimiteExpedicao, CD.DataLimiteOD,
		VI.Pedido, 
		VI.CodPedido, 
		PedidoTrat = CASE	WHEN LEFT(VI.Pedido, 4) = 'FCN-' 
							THEN SUBSTRING(VI.Pedido,5,13)
							ELSE ISNULL(EV.CodPedidoVTEX,VI.Pedido) END, --[dbo].[fnAjustePedido](VI.Pedido) PedidoTrat, 
		VI.Site, VI.CPFCliente, VI.DataVenda, VI.CodFilial, VI.CodFilialExpedicao, VI.CodFilialFaturamento, VI.CPFVendedor, VI.QuantidadeVenda,
		VI.[ValorVenda], VI.[ValorDescontoVenda], VI.[ValorCustoVenda], VI.[ValorCancelado], VI.[ValorColocado],
		VI.[DataFaturamento], VI.[DataAprovacao], VI.[DataExpedicao], VI.[DataEntrega], VI.[DataComercial], 
		VI.[DataEntregaPedido], VI.[MomentoVenda], VI.[DataCancelamento], VI.[ValorColocadoS/Frete], VI.Ticket, 
		VI.[ValorCustoGerencial], VI.[QuantidadeCancelada], VI.CanalNegocio, VI.NotaFiscalVenda, VI.NotaFiscalTroca,
		VI.FormaPagamento, VI.SubCanal, VI.MeioVenda, VI.CodProduto, VI.CodCor, VI.Tamanho, VI.TipoAtendimento, 
		VI.TipoVenda, VI.FaseVenda, VI.CodColecao, VI.VisaoComercial, VI.Status, VI.MeioDeEntrega, VI.Canal, VI.Assinatura, 
		VI.Vendedor, EV.EmbalagemPresente, vi.MeioVendaoriginal
INTO	 #tbOdsLinxVendaItem   
FROM	[RESERVA_ODS].[dbo].[tbOdsLinxVendaItem]	VI	WITH (NOLOCK)
        JOIn #auxdatas d on d.data = vi.DataVenda
		LEFT JOIN	[RESERVA_ODS].[dbo].[tbOdsEcommerceVenda] EV WITH (NOLOCK)	on	VI.Pedido = EV.CodPedido
																				and VI.DataVenda = convert(date,EV.DataVenda)
																				and vi.Site = EV.Site
		LEFT JOIN   #aux EV2		ON	ISNULL(ISNULL(ev.codpedidovtex,vi.codpedido),'(Não Informado)') = ev2.pedido
																					--and VI.DataVenda = convert(date,EV2.DataVenda)
																					and isnull(VI.Site,'(Não Informado)') = isnull(ev2.Site,'(Não Informado)')
																					and isnull(VI.CodProduto,'(Não Informado)') = isnull(ev2.CodProduto,'(Não Informado)')
		LEFT JOIN	#auxCD CD		ON	CD.PedidoCliente = VI.Pedido
WHERE	VI.CanalNegocio = 'ONLINE' AND VI.ValorVenda >= 0 --AND VI.DataVenda >= @data_ini
and d.data is not null 
------------------------------------VENDAS REALIZADAS NO DIA DO LENTE_DIA------------------------------------

SELECT	IdPedido					= ISNULL(PDD.IdPedido			, 0)
		, IdTicket					= ISNULL(TKT.IdTicket			, 0)
		, [IdPedidoNotaFiscal]		= ISNULL(PNF.IdPedidoNotaFiscal	, 0)
		, IdCliente					= ISNULL(CLI.IdCliente			, 0)
		, IdDispositivos			= ISNULL(DIT.IdDispositivos		, 0)
		, IdSourceMedium			= ISNULL(SM.IdSourceMedium		, 0)
		, IdCampanha				= ISNULL(CAM.IdCampanha			, 0)
		, IdLetreiro				= ISNULL(LET.IdMarca			, 0)
		, IdMarca					= ISNULL(DMA.IdMarca			, 0)
		, IdSTV						= ISNULL(DSTV.IdSTV				, 0)
		, IdTipoMensagem			= 0
		, IdFormaPagamento			= ISNULL(FP.IdFormaPagamento	, 0)
		, IdCanal					= ISNULL(CN.IdCanal				, 0)
		, IdFilial					= ISNULL(FL.IdFilial			, 0)
		,[IdFilialExpedicao]		= ISNULL(FL2.IdFilial			, 0) -- nova linha colocada no script  
		,[IdFilialFaturamento]		= ISNULL(FL3.IdFilial			, 0) -- nova linha colocada no script
		, IdMeioVenda				= ISNULL(MV.IdMeioVenda			, 0)
		, IdProdutos				= ISNULL(PR.IdProdutos			, 0)
		, IdCorProdutos				= ISNULL(CPR.IdCorProdutos		, 0)
		, IdTamanhoProdutos			= ISNULL(TPR.IdTamanhoProdutos	, 0)
		, IdTipoAtendimento			= ISNULL(TA.IdTipoAtendimento	, 0)
		, IdTipoVenda				= ISNULL(TV.IdTipoVenda			, 0)
		, IdFaseVenda				= ISNULL(VC.IdFaseVenda			, 0)
		, IdColecao					= ISNULL(CO.IdColecao			, 0)
		, IdHora					= ISNULL(HR.IdHora				, 0)
		, IdVisaoComercial			= ISNULL(VK.IdVisaoComercial	, 0)
		, IdStatusPedido			= ISNULL(STP.IdStatusPedido		, 0)
		, IdMeioDeEntrega			= ISNULL(ME.IdMeioDeEntrega		, 0)
		, IdPromotorVenda			= ISNULL(PV.IdPromotorVenda		, 0)
		, [IdData]					= ISNULL(DT.IdData				, 0)
		, [IdCupomProduto]			= ISNULL(DPR.IdCupomProduto	    , 0)
		, [IdCupomPedido]			= ISNULL(DPD.IdCupomPedido	    , 0)
		, [IdSite]					= ISNULL(DSI.IdSite				, 0)
		, VI.[DataVenda]
		, [DataFaturamento]
		, [DataAprovacao]
		, [DataExpedicao]
		, [DataEntrega]
		, [DataComercial]
		, [DataEntregaPedido]
		, [MomentoVenda]
		, [DataCancelamento]
		, [ValorVenda]				= ISNULL(VI.[ValorVenda]			, 0)
		, [ValorDescontoVenda]		= ISNULL(VI.[ValorDescontoVenda]	, 0)
		, [ValorCustoVenda]			= ISNULL(VI.[ValorCustoVenda]		, 0)
		, [ValorCancelado]			= ISNULL(VI.[ValorCancelado]		, 0)
		, [ValorColocado]			= ISNULL(VI.[ValorColocado]			, 0)		
		/*ISNULL(CASE	WHEN VI.[ValorColocado]	IS NULL THEN 0 
													ELSE VI.[ValorColocadoS/Frete]+(Isnull((VFP.FreteFinal/VFP.QuantidadeTotal),0)*(VI.[QuantidadeVenda]+VI.[QuantidadeCancelada])) 
													END,0) */
		, [ValorCustoGerencial]		= ISNULL(VI.[ValorCustoGerencial]	, 0)
		, [QuantidadeVenda]			= ISNULL(VI.[QuantidadeVenda]+VI.[QuantidadeCancelada]		, 0)
		, [QuantidadeCancelada]		= ISNULL(VI.[QuantidadeCancelada]	, 0)
		, [IdAssinatura]			= ISNULL(DA.IdAssinatura, 0)
		, [IdVendedor]			    = ISNULL(VD.IdVendedor, 0)
		, [DataPrevisãoEntrega]
		, VI.[DataLimiteExpedicao]
		, VI.[DataLimiteOD]
		, [IdModelodeEntrega]       = ISNULL(MDE.[IdModelodeEntrega]	, 0)
		, IdCanaldeMidia			= ISNULL(CDM.IdCanaldeMidia			, 0)
		, IdEmbalagemDePresente		= ISNULL(DEDP.IdEmbalagemDePresente , 0)
		, IdSKU		= ISNULL(SKU.IdSKU , 0)
		,IdPlatform = ISNULL(GE.IdPlatform , 0)
--into #teste
FROM	#tbOdsLinxVendaItem	VI	WITH (NOLOCK)
LEFT JOIN  (
	select distinct codproduto, case when CodPedidoVtex = '' then codpedido else  isnull(CodPedidoVtex, codpedido)  end pedido, site, isnull(storeid , '(Não Informado)') storeid,
     RANK() OVER   
    (PARTITION BY codproduto, case when CodPedidoVtex = '' then codpedido else  isnull(CodPedidoVtex, codpedido)  end, site  ORDER BY 
	 isnull(storeid , '(Não Informado)') ASC) rkg 
     FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceVendaItem] WITH (NOLOCK)
	 ) EVI                                                   on evi.codproduto = vi.codproduto
                                                            and evi.pedido
															  = case when vi.codpedido = '' then vi.pedido else isnull(vi.codpedido, vi.pedido) end
															and evi.site       = vi.site
															and evi.rkg        = 1
LEFT JOIN  (
	select	distinct  case when PedidoOrigem = '' then codpedido else  isnull(PedidoOrigem, codpedido)  end pedido, 
			site, isnull(MetodoEnvio , '(Não Informado)') MetodoEnvio,
			RANK() OVER   
			(PARTITION BY  case when PedidoOrigem = '' then codpedido else  isnull(PedidoOrigem, codpedido)  end, site  ORDER BY 
	 isnull(MetodoEnvio , '(Não Informado)') ASC) rkg 
     FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceEnvio] WITH (NOLOCK)
	 )	 EEV                                                                on eev.pedido 
	                                                                             = case when vi.codpedido = '' then vi.pedido else isnull(vi.codpedido, vi.pedido) end
                                                                           and eev.Site      = vi.site
																		   and eev.rkg       = 1
------------------------------------------VALOR DE FRETE DO PEDIDO
LEFT JOIN	(	SELECT	VI.Pedido, VI.Site, VI.CPFCliente, VI.DataVenda, VI.CodFilial, VI.CPFVendedor, EV.FreteFinal, VI.QuantidadeTotal
				FROM	(	SELECT	*,
									ROW_NUMBER() OVER (PARTITION BY CodPedido ORDER BY MetodoEnvio) row_num 
							FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceEnvio]		EV WITH (NOLOCK)--1210658
						) EV
				JOIN [RESERVA_ODS].[dbo].[tbOdsEcommerceCliente]	EC	WITH(NOLOCK)			ON	EC.CodUsuario	= EV.CodUsuario
																									AND EC.Site		= EV.Site
																									AND EV.row_num	= 1
				JOIN	(	SELECT	Pedido, Site, CPFCliente, DataVenda, CodFilial, 
									CPFVendedor, sum(QuantidadeVenda+QuantidadeCancelada) QuantidadeTotal
							FROM	#tbOdsLinxVendaItem	VI	
							WHERE Site IS NOT NULL AND DataVenda IS NOT NULL AND Pedido <> '' AND CanalNegocio = 'ONLINE'
							GROUP BY Pedido, Site, CPFCliente, DataVenda, CodFilial, CPFVendedor
						)	VI		ON VI.Pedido			= EV.CodPedido
									AND VI.Site				= EV.Site
									AND VI.CPFCliente		= EC.CPFCliente
			) VFP	ON	VFP.Pedido = VI.Pedido
					AND VFP.Site = VI.Site
					AND VFP.CPFCliente = VI.CPFCliente
					AND VFP.DataVenda = VI.DataVenda
					AND VFP.CodFilial = VI.CodFilial
					AND VFP.CPFVendedor = VI.CPFVendedor
------------------------------------------
LEFT JOIN	(
			SELECT Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro,	CanaldeMidia
			FROM (
					SELECT	Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro,	CanaldeMidia,
							ROW_NUMBER() OVER (PARTITION BY CodPedido ORDER BY DATA) row_num
					FROM [RESERVA_ODS].[dbo].[tbOdsBIGoogleAnalyticsVendaEcommerce] a WITH (NOLOCK)
					) b
			WHERE	CodPedidoTrat LIKE 'OFC%' AND   row_num = 1
			)	GE_OFC ON	
						GE_OFC.CodPedidoTrat = VI.PedidoTrat--[dbo].[fnAjustePedido](VI.Pedido)
						AND GE_OFC.Data = VI.DataVenda
/*LEFT JOIN	(
			SELECT Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro, CanaldeMidia
			FROM (
					SELECT	Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro,	CanaldeMidia,
							ROW_NUMBER() OVER (PARTITION BY CodPedido ORDER BY DATA) row_num
					FROM [RESERVA_ODS].[dbo].[tbOdsBIGoogleAnalyticsVendaEcommerce] a WITH (NOLOCK)
					) b
			WHERE   row_num = 1
			)	GE ON	GE.CodPedido = VI.PedidoTrat--[dbo].[fnAjustePedido](VI.Pedido)
						AND CASE	WHEN LEFT(VI.Pedido, 4) = 'FCN-' 
									THEN '20000101'
									ELSE GE.Data END	= CASE	WHEN LEFT(VI.Pedido, 4) = 'FCN-' 
																THEN '20000101'
																ELSE VI.DataVenda END	*/	
LEFT JOIN	(
			SELECT Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro, CanaldeMidia,IdPlatform
			FROM (
					SELECT	Data, CodPedido, CodPedidoTrat, Dispositivo, Fonte, Meio, Segmento, Griffe, Campanha, Letreiro,	CanaldeMidia,IdPlatform,
							ROW_NUMBER() OVER (PARTITION BY CodPedido ORDER BY DATA) row_num
					FROM [RESERVA_ODS].[dbo].[tbOdsBIGoogleAnalyticsVendaEcommerce] a WITH (NOLOCK) 
							left join reserva_dw..tbDimPlatform dp on a.Platform = dp.CodPlatform
					) b
			WHERE  CodPedidoTrat NOT LIKE 'OFC%' AND  row_num = 1
			)	GE ON	GE.CodPedido = VI.PedidoTrat--[dbo].[fnAjustePedido](VI.Pedido)
						AND CASE	WHEN LEFT(VI.Pedido, 4) = 'FCN-' 
									THEN '20000101'
									ELSE GE.Data END	= CASE	WHEN LEFT(VI.Pedido, 4) = 'FCN-' 
																THEN '20000101'
																ELSE VI.DataVenda END																	
---------------------------------------------DIMENSÕES---------------------------------------------
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimPedido]				PDD		WITH (NOLOCK)	ON	PDD.Pedido					=	(CASE WHEN vi.Pedido = '' or vi.Pedido = '-' then '(Não Informado)' ELSE ISNULL(vi.Pedido, '(Não Informado)') END	)
																					AND PDD.CodPedido				=	(CASE WHEN vi.CodPedido = '' or vi.CodPedido = '-' then '(Não Informado)' ELSE ISNULL(vi.CodPedido, '(Não Informado)') END	)
																					AND PDD.DataVenda				=	ISNULL(VI.DataVenda, '1900-01-01')
																					AND PDD.Site					=	ISNULL(VI.Site, '(Não Informado)')
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimTicket]				TKT		WITH (NOLOCK)	ON	TKT.Ticket					=	ISNULL(VI.Ticket, '(Não Informado)')
																					AND TKT.DataVenda				=	ISNULL(VI.DataVenda, '1900-01-01')
																					AND TKT.CodFilial				=	ISNULL(VI.CodFilial, '(Não Informado)')
																					AND TKT.CPFCliente				=	ISNULL(VI.CPFCliente, '(Não Informado)')
																					AND TKT.CPFVendedor				=	ISNULL(VI.CPFVendedor, '(Não Informado)')
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimPedidoNotaFiscal]		PNF		WITH (NOLOCK)	ON	PNF.NotaFiscalVenda			=	ISNULL(VI.NotaFiscalVenda, '(Não Informado)')
																					AND PNF.NotaFiscalTroca			=	ISNULL(VI.NotaFiscalTroca, '(Não Informado)')
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimCliente]				CLI		WITH (NOLOCK)	ON	CLI.CodCliente				=	ISNULL(VI.CPFCliente, '(Não Informado)')--OK					
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimDispositivos]			DIT		WITH (NOLOCK)	ON	DIT.CodDispositivo			=	ISNULL(GE.Dispositivo,ISNULL(GE_OFC.Dispositivo, '(Não Informado)'))--OK
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimCampanha]				CAM		WITH (NOLOCK)	ON	CAM.CodCampanha				=	ISNULL(GE.Campanha, ISNULL(GE_OFC.Campanha, '(Não Informado)'))--OK
LEFT JOIN	reserva_dw..tbdimstv DSTV WITH (NOLOCK) ON	DSTV.Cpfvendedor				=	ISNULL(VI.CPFVendedor, '(Não Informado)')
																						--AND DSTV.CpfVendedor		=	ISNULL(VI.CPFVendedor, '1900-01-01')
-----------------------------------------------------------SMS INICIO-----------------------------------------------------------

-----------------------------------------------------------SMS FIM-----------------------------------------------------------
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFormaPagamento]			FP		WITH (NOLOCK)	ON	FP.CodFormaPagamento	=	ISNULL(VI.FormaPagamento,'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimCanaldeMidia]			CDM		WITH (NOLOCK)	ON	CDM.CanaldeMidia		=	ISNULL(GE.CanaldeMidia, ISNULL(GE_OFC.CanaldeMidia, '(Não Informado)'))
LEFT JOIN [RESERVA_DW].[dbo].[tbDimCanal]					CN		WITH (NOLOCK)	ON	'ONLINE' = CN.CodCanal
																					AND CASE	WHEN	VI.SubCanal <> 'MARKETPLACE OUT'
																										AND VI.SubCanal <> 'APP' 
																										AND VI.SubCanal <> 'MKT PLACE IN' THEN 'SITE'
																								ELSE VI.SubCanal END	= CN.CodSubCanal
																					--CASE	WHEN VI.Canal IN ('VAREJO', 'FRANQUIA SELL OUT') THEN 'ONLINE'
																					--			ELSE VI.Canal END		= CN.CodCanal		
																					--AND CASE	WHEN VI.Canal IN ('VAREJO', 'FRANQUIA SELL OUT') THEN 'SITE'
																					--			ELSE VI.SubCanal END	= CN.CodSubCanal
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFilial]					FL		WITH (NOLOCK)	ON	FL.CodFilial			= ISNULL(VI.CodFilial,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFilial]				    FL2	    WITH (NOLOCK)	ON	FL2.CodFilial	        = ISNULL(VI.CodFilialExpedicao, '(Não Informado)') -- novo join colocado no script
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFilial]				    FL3     WITH (NOLOCK)	ON	FL3.CodFilial           = ISNULL(VI.CodFilialFaturamento, '(Não Informado)') -- novo join colocado no script

LEFT JOIN [RESERVA_DW].[dbo].[tbDimVendedor]			VD	WITH (NOLOCK)		ON	VD.CodVendedor				= ISNULL(VI.Vendedor, '(Não Informado)')
																				AND VI.DataVenda >= ISNULL(VD.DataAtivacao, '19990101') 
																				AND VI.DataVenda <= ISNULL(VD.DataDesativacao, '20500101')
																				AND VD.TipoFilial				= CASE	WHEN FL.TipoFilial = 'FRANQUIA' 
																														THEN FL.TipoFilial ELSE 'LOJA' END--mudança de tipofilial para CodFilial
LEFT JOIN [RESERVA_DW].[dbo].[tbDimMeioVenda]				MV		WITH (NOLOCK)	ON	MV.CodMeioVenda			= ISNULL(VI.MeioVenda,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimProdutos]				PR		WITH (NOLOCK)	ON	PR.CodProduto			= ISNULL(VI.CodProduto, '(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimCorProdutos]				CPR		WITH (NOLOCK)	ON	CPR.CodProduto			= ISNULL(VI.CodProduto, '(Não Informado)')
																					AND CPR.CodCor				= ISNULL(VI.CodCor,		'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimTamanhoProdutos]			TPR		WITH (NOLOCK)	ON	TPR.CodProduto			= ISNULL(VI.CodProduto, '(Não Informado)')
																					AND TPR.CodTamanho			= ISNULL(VI.Tamanho,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimTipoAtendimento]			TA		WITH (NOLOCK)	ON	TA.CodTipoAtendimento	= ISNULL(VI.TipoAtendimento,'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimTipoVenda]				TV		WITH (NOLOCK)	ON	TV.CodTipoVenda			= ISNULL(VI.TipoVenda,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimFaseVenda]				VC		WITH (NOLOCK)	ON	VC.CodFaseVenda			= ISNULL(VI.FaseVenda,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimColecao]					CO		WITH (NOLOCK)	ON	CO.CodColecao			= ISNULL(VI.CodColecao,	'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimData]					DT		WITH (NOLOCK)	ON	DT.Data					= VI.DataVenda
LEFT JOIN [RESERVA_DW].[dbo].[tbDimHora]					HR		WITH (NOLOCK)	ON	HR.CodHora				= CONVERT(varchar(50),DATEPART(hour,VI.MomentoVenda))
LEFT JOIN [RESERVA_DW].[dbo].[tbDimVisaoComercial]			VK		WITH (NOLOCK)	ON	VK.CodVisaoComercial	= ISNULL(VI.VisaoComercial,'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimStatusPedido]			STP		WITH (NOLOCK)	ON	STP.CodStatusPedido		= ISNULL(VI.Status,'(Não Informado)')
LEFT JOIN [RESERVA_DW].[dbo].[tbDimMeioDeEntrega]			ME		WITH (NOLOCK)	ON	ME.MeioDeEntrega		= ISNULL(VI.MeioDeEntrega,'(Não Informado)')
LEFT JOIN  (select * from
               (SELECT distinct promotion, coupon, orderid, productid, description, convert(datetime,convert(varchar(10), Data ,112)) data, RANK() OVER   
               (partition by  orderid, productid,  data ORDER BY total, promotion,description  asc) AS ordem
               FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceCii]   WITH (NOLOCK)  
                      ) b
            WHERE b.ordem = '1' and (promotion <> '' or coupon <> '')  )  OPR                     ON  OPR.orderid                 = ISNULL(VI.Pedido, '(Não Informado)')
                                                                                                  AND OPR.productid               = ISNULL(VI.CodProduto, '(Não Informado)')
															              	                      AND  convert(datetime,convert(varchar(10), OPR.Data ,112)) =  VI.DataVenda
LEFT JOIN [RESERVA_DW].[dbo].[tbDimCupomProduto]	                      DPR     WITH (NOLOCK)   ON  DPR.Coupon                  = ISNULL(OPR.Coupon       , '(Não Informado)')
                                                                                                  AND DPR.Promotion               = ISNULL(OPR.Promotion 	, '(Não Informado)')
											                                                      AND DPR.Description             = ISNULL(OPR.Description	, '(Não Informado)')
LEFT JOIN (select * from
               (SELECT distinct promotion, coupon, orderid, description, convert(datetime,convert(varchar(10), Data ,112)) data, RANK() OVER   
               (partition by  orderid, data ORDER BY total, promotion, coupon,description asc) AS ordem
               FROM [RESERVA_ODS].[dbo].[tbOdsEcommerceOi]   WITH (NOLOCK)  
                      ) b
            WHERE b.ordem = '1' and (promotion <> '' or coupon <> '')  )  OPD						ON  OPD.orderid                 = ISNULL(VI.Pedido, '(Não Informado)')
															              							AND  convert(datetime,convert(varchar(10), OPD.Data ,112)) =  VI.DataVenda 
/*ANTIGO*/
/*LEFT JOIN [RESERVA_DW].[dbo].[tbDimCupomPedido]	                          DPD    WITH (NOLOCK)		ON  DPD.promotion               = CASE WHEN OPD.promotion = 'ajuste-store-credit' THEN 'Cashback' ELSE isnull( OPD.Promotion   , '(Não Informado)') END
																									AND DPD.coupon                  = CASE WHEN OPD.Coupon    = 'ajuste-store-credit' THEN 'Cashback' ELSE isnull(OPD.Coupon   , '(Não Informado)')     END
																									AND DPD.Description             = ISNULL   (OPD.Description, '(Não Informado)') */
/*NOVO*/
LEFT JOIN (select max(IdCupomPedido) IdCupomPedido,Promotion,Coupon,Description from [RESERVA_DW].[dbo].[tbDimCupomPedido] WITH (NOLOCK)
group by Promotion,Coupon,Description  )   DPD      	
ON  DPD.promotion               = CASE WHEN OPD.promotion = 'ajuste-store-credit' THEN 'Cashback' ELSE isnull( OPD.Promotion   , '(Não Informado)') END
																									AND DPD.coupon                  = CASE WHEN OPD.Coupon    = 'ajuste-store-credit' THEN 'Cashback' ELSE isnull(OPD.Coupon   , '(Não Informado)')     END
																									AND DPD.Description             = ISNULL   (OPD.Description, '(Não Informado)')
LEFT JOIN tbDimSite DSI WITH (NOLOCK) ON ISNULL(VI.Site, '(Não Informado)') = DSI.CodSite
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimSourceMedium]			SM		WITH (NOLOCK)	ON	SM.Source					=	CASE WHEN DPD.Coupon like '%todevolta%' THEN 'CRM'
                                                                                                                        ELSE ISNULL(GE.Fonte, ISNULL(GE_OFC.Fonte, '(Não Informado)')) END--OK
																					AND SM.Medium					=	CASE WHEN DPD.Coupon like '%todevolta%' THEN 'RECV'
																					                                    ELSE ISNULL(GE.Meio, ISNULL(GE_OFC.Meio, '(Não Informado)')) END
LEFT JOIN [RESERVA_DW].[dbo].[tbDimPromotorVenda]			PV		WITH (NOLOCK)	ON	PV.PromotorVenda		= CASE	WHEN	VI.Subcanal = 'MARKETPLACE OUT' 
																																 THEN 'MARKETPLACE'
																														WHEN VI.MeioVendaoriginal IN (	'AFILIADOS','BE EVA','FASE 1 STV','FASE 2 STV','RONY',
																																				'STV 2','STV ATACADO','STV FRANQUEADO','STV FRANQUIA',
																																				'STV PARCEIROS OFC','STV SEDE','STV SITES PROMO', 
																																				'STV PARCERIAS', 'LIVE STV','STV DESLIGADOS','STV CUPOM ANTIGO') or vi.MeioVendaoriginal like '%STV%' THEN 'STV'
																														WHEN VI.MeioVendaoriginal IN ('C. DIGITAL','COMERCIO DIGITAL','PLANO B') THEN 'CDIG'
																														WHEN VI.Canal = ('ONLINE') OR VI.SubCanal = 'SITE'  OR vi.MeioVendaoriginal = 'LIVELO' THEN 'VDIG'
																														ELSE '(Não Informado)' END
LEFT JOIN [RESERVA_DW].[dbo].[tbDimAssinatura]	DA	WITH (NOLOCK)	ON	DA.CodAssinatura = ISNULL(VI.Assinatura, '(Não Informado)')
------------------------INSERINDO NOVO JOIN DE MARCAS 25/06/2021------------------------
LEFT JOIN	[RESERVA_DW].[dbo].[tbDimMarca]					LET		WITH (NOLOCK)	ON	LET.CodMarca = CASE	WHEN VI.CanalNegocio IN ('OFFLINE','FRANQUIA SELL OUT') 
																							THEN ISNULL(FL.Marca, '(Não Informado)') 
																							ELSE ISNULL(PR.Griffe, '(Não Informado)') END
--LEFT JOIN	[RESERVA_DW].[dbo].[tbDimMarca]					LET		WITH (NOLOCK)	ON	LET.CodMarca				=	ISNULL(GE.Letreiro, ISNULL(GE_OFC.Letreiro, '(Não Informado)'))--OK

LEFT JOIN [RESERVA_DW].[dbo].[tbDimMarca]	DMA	WITH (NOLOCK)	ON	DMA.CodMarca = CASE	WHEN VI.CanalNegocio IN ('OFFLINE','FRANQUIA SELL OUT') 
																							THEN ISNULL(FL.Marca, '(Não Informado)') 
																							ELSE ISNULL(PR.Griffe, '(Não Informado)') END
--LEFT JOIN [RESERVA_DW].[dbo].[tbDimMarca]	DMA2 WITH (NOLOCK)	ON	DMA2.CodMarca = CASE	WHEN VI.Canal IN ('VAREJO','FRANQUIA SELL OUT') 
--																							THEN ISNULL(FL.Marca, '(Não Informado)') 
--																							ELSE ISNULL(PR.Griffe, '(Não Informado)') END
LEFT JOIN [RESERVA_DW].[dbo].[tbDimModelodeEntrega] MDE WITH (NOLOCK)	ON MDE.ModelodeEntrega = CASE WHEN (vi.site = 'sintese-vtex' and isnull(EEV.MetodoEnvio,'(Não Informado)') = '0')
                                                                                                        OR (vi.site = 'UseReserva-OCC' and isnull(EEV.MetodoEnvio,'(Não Informado)') = 'inStorePickupShippingGroup' and EVI.storeid <> 'CD')
																										OR (vi.site = 'oficina-site' and isnull(EEV.MetodoEnvio,'(Não Informado)') = 'inStorePickupShippingGroup')
																										    THEN 'BOPIS'
																									  WHEN (vi.site = 'sintese-vtex' and isnull(EEV.MetodoEnvio,'(Não Informado)') <> '0')
                                                                                                        OR (vi.site = 'UseReserva-OCC' and isnull(EEV.MetodoEnvio,'(Não Informado)') <> 'inStorePickupShippingGroup' and EVI.storeid <> 'CD')
																										OR (vi.site = 'oficina-lojas' and isnull(EEV.MetodoEnvio,'(Não Informado)') <> 'inStorePickupShippingGroup')
																										    THEN 'SFS'
																									  WHEN (vi.site in ('Reserva-vtex','Reserva-app') and isnull(EEV.MetodoEnvio,'(Não Informado)') = '0')
                                                                                                        OR (vi.site = 'UseReserva-OCC' and isnull(EEV.MetodoEnvio,'(Não Informado)') = 'inStorePickupShippingGroup' and EVI.storeid = 'CD')
																										OR (vi.site = 'oficina-lojas' and isnull(EEV.MetodoEnvio,'(Não Informado)') = 'inStorePickupShippingGroup')
																										    THEN 'Ship to'
																									  WHEN (vi.site in ('Reserva-vtex','Reserva-app') and isnull(EEV.MetodoEnvio,'(Não Informado)') <> '0')
                                                                                                        OR (vi.site = 'UseReserva-OCC' and isnull(EEV.MetodoEnvio,'(Não Informado)') <> 'inStorePickupShippingGroup' and EVI.storeid = 'CD')
																										OR (vi.site = 'oficina-site' and isnull(EEV.MetodoEnvio,'(Não Informado)') <> 'inStorePickupShippingGroup')
																										OR vi.site in ('MktPlace','mktin_vtex','mktin_vtex','oficina-market-out','RSV_INK','Farfetch','farfetch_intl','Mktplace-vtex','WISE')
																										    THEN 'SFDC'
																									ELSE '(Não Informado)' END
-----------------------------------------------------------adição dim Embalagem De Presente(11/08/2022 barrientos)----------------------------------------------------------------
LEFT JOIN [RESERVA_DW].[dbo].[tbDimEmbalagemDePresente]	DEDP	WITH (NOLOCK)	ON	DEDP.CodEmbalagemDePresente = ISNULL(VI.EmbalagemPresente,'0')
LEFT JOIN [RESERVA_DW].[dbo].[tbdimSKU] SKU WITH (NOLOCK) ON SKU.codproduto = VI.Codproduto
                                                         AND SKU.codcor     = VI.codcor
														 AND SKU.CodTamanho = VI.Tamanho 

WHERE VI.CanalNegocio = 'ONLINE' and VI.ValorVenda >= 0

GO
