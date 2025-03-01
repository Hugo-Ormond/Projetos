USE [RESERVA_DW]
GO
/****** Object:  StoredProcedure [dbo].[UpCarga_FatoEcommerceVendaItemTableau]    Script Date: 01/02/2024 15:42:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE PROC [dbo].[UpCarga_FatoEcommerceVendaItemTableau] @TIPO VARCHAR(50) = 'INCREMENTAL'

AS

BEGIN

--declare @TIPO VARCHAR(50)

--select @TIPO = 'INCREMENTAL'

DECLARE @data_ini DATETIME

IF @tipo = 'FULL'
	SELECT @data_ini = '20000101'

IF @tipo = 'INCREMENTAL'
	SELECT @data_ini = CONVERT(DATETIME,CONVERT(CHAR(10),GETDATE()-45,103),103)


/*------------------------------TEMPORÁRIA AUXILIAR LENTE_DIA------------------------------
IF OBJECT_ID('tempdb..#TEMP_001') IS NOT NULL

DROP TABLE #TEMP_001

SELECT	IdPedido, IdTicket, [IdPedidoNotaFiscal], IdCliente, IdDispositivos, IdSourceMedium, IdCampanha, IdLetreiro, IdMarca, IdSTV
		, IdTipoMensagem, IdFormaPagamento, IdCanal, IdFilial, IdMeioVenda, IdProdutos, IdCorProdutos, IdTamanhoProdutos, IdTipoAtendimento
		, IdTipoVenda, IdFaseVenda, IdColecao, IdHora, IdVisaoComercial, IdStatusPedido, IdMeioDeEntrega, IdPromotorVenda, [IdData]
		, [IdCupomProduto], [IdCupomPedido], [IdSite]
		, [DataVenda], [DataFaturamento], [DataAprovacao], [DataExpedicao], [DataEntrega], [DataComercial], [DataEntregaPedido]
		, [MomentoVenda], [DataCancelamento], [ValorVenda], [ValorDescontoVenda], [ValorCustoVenda], [ValorCancelado], [ValorColocado]			
		, [ValorCustoGerencial], [QuantidadeVenda], [QuantidadeCancelada], [IdAssinatura], [IdVendedor]			
INTO #TEMP_001
FROM	[dbo].[v_tbFatoEcommerceVendaItemTableau_002] A */

------------------------------TEMPORÁRIA AUXILIAR LENTE------------------------------
--SELECT	IdPedido, IdTicket, [IdPedidoNotaFiscal], IdCliente, IdDispositivos, IdSourceMedium, IdCampanha, IdLetreiro, IdMarca, IdSTV
--		, IdTipoMensagem, IdFormaPagamento, IdCanal, IdFilial, IdMeioVenda, IdProdutos, IdCorProdutos, IdTamanhoProdutos, IdTipoAtendimento
--		, IdTipoVenda, IdFaseVenda, IdColecao, IdHora, IdVisaoComercial, IdStatusPedido, IdMeioDeEntrega, IdPromotorVenda, [IdData], [IdCupomProduto], [IdCupomPedido]
--		, [DataVenda], [DataFaturamento], [DataAprovacao], [DataExpedicao], [DataEntrega], [DataComercial], [DataEntregaPedido]
--		, [MomentoVenda], [DataCancelamento], [ValorVenda], [ValorDescontoVenda], [ValorCustoVenda], [ValorCancelado], [ValorColocado]			
--		, [ValorCustoGerencial], [QuantidadeVenda], [QuantidadeCancelada]		
--INTO #TEMP_002
--FROM [dbo].[v_tbFatoEcommerceVendaItemTableau_003]	A

--DECLARE @data_ini DATETIME
--SELECT @data_ini = CONVERT(DATETIME,CONVERT(CHAR(10),GETDATE()-60,103),103)

IF OBJECT_ID('tempdb..#TEMP_002') IS NOT NULL

DROP TABLE #TEMP_002

CREATE TABLE [dbo].[#TEMP_002](
	[IdPedido] [int] NOT NULL,
	[IdTicket] [int] NOT NULL,
	[IdPedidoNotaFiscal] [int] NOT NULL,
	[IdCliente] [int] NOT NULL,
	[IdDispositivos] [int] NOT NULL,
	[IdSourceMedium] [int] NOT NULL,
	[IdCampanha] [int] NOT NULL,
	[IdLetreiro] [int] NOT NULL,
	[IdMarca] [int] NOT NULL,
	[IdSTV] [int] NOT NULL,
	[IdTipoMensagem] [int] NOT NULL,
	[IdFormaPagamento] [int] NOT NULL,
	[IdCanal] [int] NOT NULL,
	[IdFilial] [int] NOT NULL,
	[IdFilialExpedicao] [int] NOT NULL, -- nova coluna criada 
	[IdFilialFaturamento] [int] NOT NULL, -- nova coluna criada 	
	[IdMeioVenda] [int] NOT NULL,
	[IdProdutos] [int] NOT NULL,
	[IdCorProdutos] [int] NOT NULL,
	[IdTamanhoProdutos] [int] NOT NULL,
	[IdTipoAtendimento] [int] NOT NULL,
	[IdTipoVenda] [int] NOT NULL,
	[IdFaseVenda] [int] NOT NULL,
	[IdColecao] [int] NOT NULL,
	[IdHora] [int] NOT NULL,
	[IdVisaoComercial] [int] NOT NULL,
	[IdStatusPedido] [int] NOT NULL,
	[IdMeioDeEntrega] [int] NOT NULL,
	[IdPromotorVenda] [int] NOT NULL,
	[IdData] [int] NOT NULL,
	[IdCupomProduto] [int] NOT NULL,
	[IdCupomPedido] [int] NOT NULL,
	[IdSite] [int] NOT NULL,
	[DataVenda] [datetime] NULL,
	[DataFaturamento] [datetime] NULL,
	[DataAprovacao] [datetime] NULL,
	[DataExpedicao] [datetime] NULL,
	[DataEntrega] [datetime] NULL,
	[DataComercial] [datetime] NULL,
	[DataEntregaPedido] [datetime] NULL,
	[MomentoVenda] [datetime] NULL,
	[DataCancelamento] [datetime] NULL,
	[ValorVenda] [float] NOT NULL,
	[ValorDescontoVenda] [float] NOT NULL,
	[ValorCustoVenda] [float] NOT NULL,
	[ValorCancelado] [float] NOT NULL,
	[ValorColocado] [float] NOT NULL,
	[ValorCustoGerencial] [float] NOT NULL,
	[QuantidadeVenda] [float] NOT NULL,
	[QuantidadeCancelada] [float] NOT NULL,
	[IdAssinatura]	[int] NOT NULL,
	[IdVendedor]	[int] NOT NULL,
	[DataPrevisãoEntrega]  [datetime] NULL,
	[DataLimiteExpedicao] [datetime] NULL,
	[DataLimiteOD] [datetime] NULL,
	[IdModelodeEntrega] [int] NOT NULL,
	[IdCanaldeMidia] [int] NOT NULL,
	[IdEmbalagemDePresente] [int] NOT NULL,
	[IdSKU] [int] NOT NULL,
	[IdPlatform] [int] NOT NULL
) ON [PRIMARY]

--declare @data_ini datetime

--select @data_ini = CONVERT(DATETIME,CONVERT(CHAR(10),GETDATE()-2,103),103)

INSERT INTO #TEMP_002

exec p_tbFatoEcommerceVendaItemTableau_003 @data_ini

--------------------------------TEMPORÁRIA AUXILIAR SESSOES------------------------------

------------------------------TEMPORÁRIA AUXILIAR VENDAS------------------------------
IF OBJECT_ID('tempdb..#AUX_VENDA_ITEM') IS NOT NULL

DROP TABLE #AUX_VENDA_ITEM

SELECT	IdPedido					=	ISNULL(IdPedido,0) 
		, IdTicket					=	ISNULL(IdTicket,0)
		, [IdPedidoNotaFiscal]		=	ISNULL([IdPedidoNotaFiscal],0)				
		, IdCliente					=	ISNULL(IdCliente,0)							
		, IdDispositivos			=	ISNULL(SQ.IdDispositivos,0)--ISNULL(SQ.IdDispositivos,B.IdDispositivos)	
		, IdSourceMedium			=	ISNULL(SQ.IdSourceMedium,0)--ISNULL(SQ.IdSourceMedium,B.IdSourceMedium)	
		, IdCampanha				=	ISNULL(SQ.IdCampanha,0)--ISNULL(SQ.IdCampanha,B.IdCampanha)			
		, IdLetreiro				=	ISNULL(IdLetreiro, 0)							
		, IdMarca					=	ISNULL(SQ.IdMarca,0)--ISNULL(SQ.IdMarca,B.IdMarca)					
		, IdSTV						=	ISNULL(IdSTV, 0)								
		, IdTipoMensagem			=	ISNULL(IdTipoMensagem, 0)						
		, IdFormaPagamento			=	ISNULL(IdFormaPagamento,0)					
		, IdCanal					=	ISNULL(SQ.IdCanal,0)--ISNULL(SQ.IdCanal,B.IdCanal)					
		, IdFilial					=	ISNULL(IdFilial, 0)
		, IdFilialExpedicao         =   ISNULL(IdFilialExpedicao, 0)   -- nova coluna criada 
	    , IdFilialFaturamento       =   ISNULL(IdFilialFaturamento, 0) -- nova coluna criada 	
		, IdMeioVenda				=	ISNULL(IdMeioVenda, 0)						
		, IdProdutos				=	ISNULL(IdProdutos, 0)							
		, IdCorProdutos				=	ISNULL(IdCorProdutos, 0)							
		, IdTamanhoProdutos			=	ISNULL(IdTamanhoProdutos, 0)							
		, IdTipoAtendimento			=	ISNULL(IdTipoAtendimento, 0)					
		, IdTipoVenda				=	ISNULL(IdTipoVenda, 0)						
		, IdFaseVenda				=	ISNULL(IdFaseVenda, 0)						
		, IdColecao					=	ISNULL(IdColecao, 0)							
		, IdHora					=	ISNULL(SQ.IdHora,0)	--ISNULL(SQ.IdHora,B.IdHora)					
		, IdVisaoComercial			=	ISNULL(IdVisaoComercial, 0)					
		, IdStatusPedido			=	ISNULL(IdStatusPedido, 0)						
		, IdMeioDeEntrega			=	ISNULL(IdMeioDeEntrega, 0)		
		, IdPromotorVenda			=	ISNULL(IdPromotorVenda, 0)
		, [IdData]					=	ISNULL(SQ.[IdData], 0)--ISNULL(SQ.[IdData], B.[IdData])		
		, [IdCupomProduto]			=   ISNULL(IdCupomProduto	    , 0)
		, [IdCupomPedido]			=   ISNULL(IdCupomPedido	    , 0)
		, [IdSite]					=   ISNULL(IdSite				, 0)
		, [DataVenda]				=	SQ.DataVenda--ISNULL(SQ.DataVenda, B.Data)
		, [DataFaturamento]	
		, [DataAprovacao]	
		, [DataExpedicao]
		, [DataEntrega]
		, [DataComercial]		
		, [DataEntregaPedido]	
		, [MomentoVenda]		
		, [DataCancelamento]		
		, [ValorVenda]				=	ISNULL([ValorVenda],0)			
		, [ValorDescontoVenda]		=	ISNULL([ValorDescontoVenda], 0)		
		, [ValorCustoVenda]			=	ISNULL([ValorCustoVenda], 0)	
		, [ValorCancelado]			=	ISNULL([ValorCancelado], 0)		
		, [ValorColocado]			=	ISNULL([ValorColocado], 0)			
		, [ValorCustoGerencial]		=	ISNULL([ValorCustoGerencial], 0)	
		, [QuantidadeVenda]			=	ISNULL([QuantidadeVenda], 0)	
		, [QuantidadeCancelada]		=	ISNULL([QuantidadeCancelada], 0)
		, [IdAssinatura]			=	ISNULL([IdAssinatura], 0)
		, [IdVendedor]			    =	ISNULL([IdVendedor]	, 0)
		, [DataPrevisãoEntrega] 
		, [DataLimiteExpedicao]
		, [DataLimiteOD]
		, [IdModelodeEntrega]       =	ISNULL([IdModelodeEntrega] 	, 0)
		, [IdCanaldeMidia]			=	ISNULL([IdCanaldeMidia] 	, 0)
		, [IdEmbalagemDePresente]	=	ISNULL([IdEmbalagemDePresente] 	, 0)
		, [IdSKU]                   =	ISNULL([IdSKU] 	, 0)
		, [IdPlatform]             =	ISNULL([IdPlatform] 	, 0)
INTO #AUX_VENDA_ITEM
FROM	(
		SELECT	IdPedido, IdTicket, [IdPedidoNotaFiscal], IdCliente, IdDispositivos, IdSourceMedium, IdCampanha, IdLetreiro, IdMarca, IdSTV
				, IdTipoMensagem, IdFormaPagamento, IdCanal, IdFilial, IdFilialExpedicao, IdFilialFaturamento, IdMeioVenda, IdProdutos, IdCorProdutos, IdTamanhoProdutos, IdTipoAtendimento
				, IdTipoVenda, IdFaseVenda, IdColecao, IdHora, IdVisaoComercial, IdStatusPedido, IdMeioDeEntrega, IdPromotorVenda
				, [IdData], [IdCupomProduto], [IdCupomPedido], [IdSite]
				, [DataVenda], [DataFaturamento], [DataAprovacao], [DataExpedicao], [DataEntrega], [DataComercial], [DataEntregaPedido]
				, [MomentoVenda], [DataCancelamento], [ValorVenda], [ValorDescontoVenda], [ValorCustoVenda], [ValorCancelado], [ValorColocado]			
				, [ValorCustoGerencial], [QuantidadeVenda], [QuantidadeCancelada], [IdAssinatura], [IdVendedor]
				, [DataPrevisãoEntrega], [DataLimiteExpedicao], [DataLimiteOD]	, [IdModelodeEntrega], [IdCanaldeMidia], [IdEmbalagemDePresente], [IdSKU],[IdPlatform]
		FROM #TEMP_002	A
		) SQ

-------------------------VERIFICADOR INCREMENTAL
IF @TIPO = 'INCREMENTAL' 
------------BLOCO QUE SOMENTE ATUALIZA O DIA DE HOJE----------
	BEGIN
	
	DECLARE @DATA DATE = CONVERT(DATE,DATEADD(DAY,-45,GETDATE())) 
	
	
select distinct datavenda [data] into #auxdatas2 from reserva_ods..tbodslinxvendaitem
where DataVenda >= CONVERT(DATE,DATEADD(DAY,-45,GETDATE()))  or datafaturamento >= dateadd(day,-10,getdate())


	DELETE	DEL_A
	FROM	[RESERVA_DW].[dbo].[tbFatoEcommerceVendaItemTableau] DEL_A
	LEFT JOIN	[tbDimData] DEL_B ON DEL_A.IdData = DEL_B.IdData 
	join #auxdatas2 c on c.data = del_b.Data
	WHERE c.data is not null
	
	INSERT INTO [dbo].[tbFatoEcommerceVendaItemTableau] (	  IdPedido					
															, IdTicket					
															, [IdPedidoNotaFiscal]		
															, IdCliente					
															, IdDispositivos				
															, IdSourceMedium									  
															, IdCampanha					
															, IdLetreiro					
															, IdMarca						
															, IdSTV						
															, IdTipoMensagem				
															, IdFormaPagamento			
															, IdCanal						
															, IdFilial	
															, IdFilialExpedicao -- novo campo colocado
															, IdFilialFaturamento -- novo campo colocado
															, IdMeioVenda					
															, IdProdutos		
															, IdCorProdutos		
															, IdTamanhoProdutos	
															, IdTipoAtendimento			
															, IdTipoVenda					
															, IdFaseVenda					
															, IdColecao					
															, IdHora						
															, IdVisaoComercial			
															, IdStatusPedido				
															, IdMeioDeEntrega			
															, IdPromotorVenda			
															, [IdData]		
															, [IdCupomProduto]
															, [IdCupomPedido]
															, [IdSite]
															, [Data Faturamento]	
															, [Data Aprovacao]	
															, [Data Expedicao]
															, [Data Entrega]
															, [Data Comercial]		
															, [Data Entrega Pedido]	
															, [Momento Venda]		
															, [Data Cancelamento]		
															, [Valor Venda]				
															, [Valor Desconto Venda]		
															, [Valor Custo Venda]			
															, [Valor Cancelado]			
															, [Valor Colocado]			
															, [Valor Custo Gerencial]		
															, [Quantidade Venda]			
															, [Quantidade Cancelada]
															, [IdAssinatura]
															, [IdVendedor] 
															, [Incremental]
															, [DataPrevisãoEntrega]	
															, [DataLimiteExpedição]
															, [DataLimiteOD]
															, [IdModelodeEntrega]
															, [IdCanaldeMidia]
															, [IdEmbalagemDePresente]
															, [IdSKU]
															,[IdPlatform]
															)

	SELECT	IdPedido					=	ISNULL(IdPedido,0) 
			, IdTicket					=	ISNULL(IdTicket, 0)
			, [IdPedidoNotaFiscal]		=	ISNULL([IdPedidoNotaFiscal],0)				
			, IdCliente					=	ISNULL(IdCliente,0)							
			, IdDispositivos			=	ISNULL(SQ.IdDispositivos,0)	--ISNULL(SQ.IdDispositivos,B.IdDispositivos)	
			, IdSourceMedium			=	ISNULL(SQ.IdSourceMedium,0)	--ISNULL(SQ.IdSourceMedium,B.IdSourceMedium)	
			, IdCampanha				=	ISNULL(SQ.IdCampanha,0)		--ISNULL(SQ.IdCampanha,B.IdCampanha)			
			, IdLetreiro				=	ISNULL(SQ.IdLetreiro,0)		--ISNULL(SQ.IdLetreiro, B.IdLetreiro)							
			, IdMarca					=	ISNULL(SQ.IdMarca,0)		--ISNULL(SQ.IdMarca,B.IdMarca)					
			, IdSTV						=	ISNULL(IdSTV, 0)								
			, IdTipoMensagem			=	ISNULL(IdTipoMensagem, 0)						
			, IdFormaPagamento			=	ISNULL(IdFormaPagamento,0)					
			, IdCanal					=	ISNULL(SQ.IdCanal,0)--ISNULL(SQ.IdCanal,B.IdCanal)					
			, IdFilial					=	ISNULL(IdFilial, 0)			
			, IdFilialExpedicao			=	ISNULL(IdFilialExpedicao, 0) -- novo campo colocado
			, IdFilialFaturamento       =	ISNULL(IdFilialFaturamento, 0) -- novo campo colocado
			, IdMeioVenda				=	ISNULL(IdMeioVenda, 0)						
			, IdProdutos				=	ISNULL(IdProdutos, 0)
			, IdCorProdutos				=	ISNULL(IdCorProdutos, 0)
			, IdTamanhoProdutos			=	ISNULL(IdTamanhoProdutos, 0)
			, IdTipoAtendimento			=	ISNULL(IdTipoAtendimento, 0)					
			, IdTipoVenda				=	ISNULL(IdTipoVenda, 0)						
			, IdFaseVenda				=	ISNULL(IdFaseVenda, 0)						
			, IdColecao					=	ISNULL(IdColecao, 0)							
			, IdHora					=	ISNULL(SQ.IdHora,0)--ISNULL(SQ.IdHora,B.IdHora)					
			, IdVisaoComercial			=	ISNULL(IdVisaoComercial, 0)					
			, IdStatusPedido			=	ISNULL(IdStatusPedido, 0)						
			, IdMeioDeEntrega			=	ISNULL(IdMeioDeEntrega, 0)		
			, IdPromotorVenda			=	ISNULL(SQ.IdPromotorVenda, 0)--ISNULL(SQ.IdPromotorVenda, B.IdPromotorVenda)
			, [IdData]					=	ISNULL(SQ.[IdData], 0)	
			, [IdCupomProduto]			=   ISNULL(IdCupomProduto	    , 0)
			, [IdCupomPedido]			=   ISNULL(IdCupomPedido	    , 0)
			, [IdSite]					=   ISNULL(IdSite				, 0)
			, [DataFaturamento]	
			, [DataAprovacao]	
			, [DataExpedicao]
			, [DataEntrega]
			, [DataComercial]		
			, [DataEntregaPedido]	
			, [MomentoVenda]		
			, [DataCancelamento]		
			, [ValorVenda]				=	ISNULL([ValorVenda],0)			
			, [ValorDescontoVenda]		=	ISNULL([ValorDescontoVenda], 0)	
			, [ValorCustoVenda]			=	ISNULL([ValorCustoVenda], 0)		
			, [ValorCancelado]			=	ISNULL([ValorCancelado], 0)		
			, [ValorColocado]			=	ISNULL([ValorColocado], 0)		
			, [ValorCustoGerencial]		=	ISNULL([ValorCustoGerencial], 0)	
			, [QuantidadeVenda]			=	ISNULL([QuantidadeVenda], 0)		
			, [QuantidadeCancelada]		=	ISNULL([QuantidadeCancelada], 0)
			, [IdAssinatura]			=	ISNULL([IdAssinatura], 0)
			, [IdVendedor]			    =	ISNULL([IdVendedor]	, 0)
			, [Incremental]             = 0
			, [DataPrevisãoEntrega]	
			, [DataLimiteExpedicao]
			, [DataLimiteOD]
			, [IdModelodeEntrega]       =	ISNULL([IdModelodeEntrega] 	, 0)
			, [IdCanaldeMidia]			=	ISNULL([IdCanaldeMidia], 0)
			, [IdEmbalagemDePresente]	=	ISNULL([IdEmbalagemDePresente], 0)
			, [IdSKU]                   =	ISNULL([IdSKU], 0)
			, [IdPlatform]              =	ISNULL([IdPlatform], 0)
	FROM	(SELECT * FROM #AUX_VENDA_ITEM) SQ

	END
ELSE 
----------BLOCO QUE ATUALIZA A TABELA INTEIRA----------
	BEGIN
	TRUNCATE TABLE [dbo].[tbFatoEcommerceVendaItemTableau]						
	


	INSERT INTO [dbo].[tbFatoEcommerceVendaItemTableau] (	  IdPedido					
															, IdTicket					
															, [IdPedidoNotaFiscal]		
															, IdCliente					
															, IdDispositivos				
															, IdSourceMedium									  
															, IdCampanha					
															, IdLetreiro					
															, IdMarca						
															, IdSTV						
															, IdTipoMensagem				
															, IdFormaPagamento			
															, IdCanal						
															, IdFilial	
															, IdFilialExpedicao -- novo campo colocado
															, IdFilialFaturamento -- novo campo colocado
															, IdMeioVenda					
															, IdProdutos		
															, IdCorProdutos		
															, IdTamanhoProdutos	
															, IdTipoAtendimento			
															, IdTipoVenda					
															, IdFaseVenda					
															, IdColecao					
															, IdHora						
															, IdVisaoComercial			
															, IdStatusPedido				
															, IdMeioDeEntrega			
															, IdPromotorVenda			
															, [IdData]	
															, [IdCupomProduto]
															, [IdCupomPedido]
															, [IdSite]
															, [Data Faturamento]	
															, [Data Aprovacao]	
															, [Data Expedicao]
															, [Data Entrega]
															, [Data Comercial]		
															, [Data Entrega Pedido]	
															, [Momento Venda]		
															, [Data Cancelamento]		
															, [Valor Venda]				
															, [Valor Desconto Venda]		
															, [Valor Custo Venda]			
															, [Valor Cancelado]			
															, [Valor Colocado]			
															, [Valor Custo Gerencial]		
															, [Quantidade Venda]			
															, [Quantidade Cancelada]
															, [IdAssinatura]
															, [IdVendedor]
															, [Incremental]
															, [DataPrevisãoEntrega]	
															, [DataLimiteExpedição]
															, [DataLimiteOD] 
															, [IdModelodeEntrega]
															, [IdCanaldeMidia]
															, [IdEmbalagemDePresente]
															, [IdSKU]
															, [IdPlatform])

	SELECT	IdPedido					=	ISNULL(IdPedido,0) 
			, IdTicket					=	ISNULL(IdTicket, 0)
			, [IdPedidoNotaFiscal]		=	ISNULL([IdPedidoNotaFiscal],0)				
			, IdCliente					=	ISNULL(IdCliente,0)							
			, IdDispositivos			=	ISNULL(SQ.IdDispositivos,0)--ISNULL(SQ.IdDispositivos,B.IdDispositivos)	
			, IdSourceMedium			=	ISNULL(SQ.IdSourceMedium,0)--ISNULL(SQ.IdSourceMedium,B.IdSourceMedium)	
			, IdCampanha				=	ISNULL(SQ.IdCampanha,0)--ISNULL(SQ.IdCampanha,B.IdCampanha)			
			, IdLetreiro				=	ISNULL(SQ.IdLetreiro,0)--ISNULL(SQ.IdLetreiro, B.IdLetreiro)							
			, IdMarca					=	ISNULL(SQ.IdMarca,0)--ISNULL(SQ.IdMarca,B.IdMarca)					
			, IdSTV						=	ISNULL(IdSTV, 0)								
			, IdTipoMensagem			=	ISNULL(IdTipoMensagem, 0)						
			, IdFormaPagamento			=	ISNULL(IdFormaPagamento,0)					
			, IdCanal					=	ISNULL(SQ.IdCanal,0)--ISNULL(SQ.IdCanal,B.IdCanal)					
			, IdFilial					=	ISNULL(IdFilial, 0)		
			, IdFilialExpedicao			=	ISNULL(IdFilialExpedicao, 0) -- novo campo colocado
			, IdFilialFaturamento       =	ISNULL(IdFilialFaturamento, 0) -- novo campo colocado
			, IdMeioVenda				=	ISNULL(IdMeioVenda, 0)						
			, IdProdutos				=	ISNULL(IdProdutos			, 0)
			, IdCorProdutos				=	ISNULL(IdCorProdutos		, 0)
			, IdTamanhoProdutos			=	ISNULL(IdTamanhoProdutos	, 0)
			, IdTipoAtendimento			=	ISNULL(IdTipoAtendimento	, 0)					
			, IdTipoVenda				=	ISNULL(IdTipoVenda			, 0)						
			, IdFaseVenda				=	ISNULL(IdFaseVenda			, 0)						
			, IdColecao					=	ISNULL(IdColecao			, 0)							
			, IdHora					=	ISNULL(SQ.IdHora			, 0)--ISNULL(SQ.IdHora,B.IdHora)					
			, IdVisaoComercial			=	ISNULL(IdVisaoComercial		, 0)					
			, IdStatusPedido			=	ISNULL(IdStatusPedido		, 0)						
			, IdMeioDeEntrega			=	ISNULL(IdMeioDeEntrega		, 0)		
			, IdPromotorVenda			=	ISNULL(SQ.IdPromotorVenda	, 0)--ISNULL(SQ.IdPromotorVenda, B.IdPromotorVenda)
			, [IdData]					=	ISNULL(SQ.[IdData]			, 0)--ISNULL(SQ.[IdData], B.[IdData])	
			, [IdCupomProduto]			=   ISNULL(IdCupomProduto	    , 0)
			, [IdCupomPedido]			=   ISNULL(IdCupomPedido	    , 0)
			, [IdSite]					=   ISNULL(IdSite				, 0)
			, [DataFaturamento]	
			, [DataAprovacao]	
			, [DataExpedicao]
			, [DataEntrega]
			, [DataComercial]		
			, [DataEntregaPedido]	
			, [MomentoVenda]		
			, [DataCancelamento]		
			, [ValorVenda]				=	ISNULL([ValorVenda]			,0)			
			, [ValorDescontoVenda]		=	ISNULL([ValorDescontoVenda]	, 0)	
			, [ValorCustoVenda]			=	ISNULL([ValorCustoVenda]	, 0)		
			, [ValorCancelado]			=	ISNULL([ValorCancelado]		, 0)		
			, [ValorColocado]			=	ISNULL([ValorColocado]		, 0)		
			, [ValorCustoGerencial]		=	ISNULL([ValorCustoGerencial], 0)	
			, [QuantidadeVenda]			=	ISNULL([QuantidadeVenda]	, 0)		
			, [QuantidadeCancelada]		=	ISNULL([QuantidadeCancelada], 0)
			, [IdAssinatura]			=	ISNULL([IdAssinatura]		, 0)	
			, [IdVendedor]			    =	ISNULL([IdVendedor]			, 0)
			, [Incremental]             =	0
			, [DataPrevisãoEntrega]	
			, [DataLimiteExpedicao]
			, [DataLimiteOD] 
			, [IdModelodeEntrega]       =	ISNULL([IdModelodeEntrega] 	, 0)
			, [IdCanaldeMidia]			=	ISNULL([IdCanaldeMidia]		, 0)
			, [IdEmbalagemDePresente]	=	ISNULL([IdEmbalagemDePresente]		, 0)
			, [IdSKU]                   =	ISNULL([IdSKU], 0)
			, [IdPlatform]              =	ISNULL([IdPlatform], 0)
	FROM	#AUX_VENDA_ITEM SQ
	
	END

END

GO
