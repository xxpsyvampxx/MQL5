//+------------------------------------------------------------------+
//|                                           ArtigoEAIniciantes.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.3"
#property description "Artigo: Guia passo a passo para iniciantes para escrever um Expert Advisor no MQL5"
#property description "Link: https://www.mql5.com/pt/articles/100"
#property description "Changelog:"
#property description "v1.1 - Permite ter n posições de compra e venda abertos."
#property description "v1.2 - Melhoria na exibição dos alertas."
#property description "v1.3 - Trailing stop de ordens usando os sinais do indicador NRTR."
#property description "v1.4 - Incluído o indicador de Dunnigan no lugar o ADX e MA."

//--- Include files
#include <Artigos\ArtigoTrailingStop.mqh>

//--- input parameters
input int      StopLoss=30;      // Stop Loss (US$)
input int      TakeProfit=100;   // Take Profit (US$)
input int      EA_Magic=12345;   // EA Magic Number
input double   Lot=0.1;          // Lots to Trade
input int      openPositions=10; // Quantity of open positions
input int      TrailingNRTRPeriod = 40; // Trailing NRTR Period
input double   TrailingNRTRK   =  2; // Trailing NRTR K

//--- other global parameters
int dunniganHandle; // Handle para o indicador Dunnigan
double buyValue[], sellValue[];
double closePrice; // Variable to store the close value of a bar
int STP, TKP; // To be used for Stop Loss and Take Profit values
ulong buyTicket[], sellTicket[]; // Open positions tickets
CNRTRStop trailingStop; // Trailing stop using NRTR indicator signals

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   //--- Inicialização do trailing stop
   trailingStop.Init(_Symbol, PERIOD_CURRENT, EA_Magic, true, true, false);
   if (!trailingStop.setupParameters(TrailingNRTRPeriod, TrailingNRTRK)) {
      Alert("Erro na inicialização da classe Trailing Stop! Saindo...");
      return(-1);
   }
   trailingStop.startTimer();
   trailingStop.on();
   
   //--- Obtém o handle para o indicador Dunnigan
   dunniganHandle = iCustom(_Symbol, _Period, "Custom\\DunniganIndicator.ex5");
   
   if (dunniganHandle < 0) {
      Alert("Error creating handles for indicators - error: ", GetLastError(), "!!!");
      return(INIT_FAILED);
   }
   
   //--- Let us handle currency pairs with 5 or 3 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   if (_Digits == 5 || _Digits == 3)
   {
      STP = STP * 10;
      TKP = TKP * 10;
   }
   
   // Resize que ticket array
   ArrayResize(buyTicket, openPositions);
   ArrayResize(sellTicket, openPositions);
   
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(dunniganHandle);
  }

//+------------------------------------------------------------------+
//| Expert onTimer function                                 |
//+------------------------------------------------------------------+
void OnTimer() {
   trailingStop.refresh();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   // Do we have enough bars to work with?
   if (Bars(_Symbol, _Period) < 60) // if total bars is less than 60 bars
   {
      Alert("We have less than 60 bars, EA will now exit!!!");
      return;
   }
   
   /*
      We will use the static oldTime variable to serve the bar time.
      At each OnTick() execution we will check the current bar time with the saved one.
      If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   */
   static datetime oldTime;
   datetime newTime[1];
   bool isNewBar = false;
   
   // Coping the last bar time to the element newTime[0]
   int copied = CopyTime(_Symbol, _Period, 0, 1, newTime);
   if (copied > 0) // OK, the data has been copied successfully
   {
      if (oldTime != newTime[0]) // if old time isn't equal to new bar time
      {
         isNewBar = true; // if it isn't a first call, the new bar has appeared
         if (MQL5InfoInteger(MQL5_DEBUGGING))
         {
            Print("We have new bar here ", newTime[0], " old time was ", oldTime);
         }
         oldTime = newTime[0];
      }
   }
   else 
   {
      Alert("Error in copying historical times data, error = ", GetLastError());
      return;
   }
   
   //--- EA should only check for new trade if we have a new bar
   if (isNewBar == false)
   {
      return;
   }
   
   //--- Do we have enough bars to work with?
   int myBars = Bars(_Symbol, _Period);
   if (myBars < 60) // if total bars is less than 60 bars
   {
      Alert("We have less than 60 bars, EA will now exit!!!");
      return;
   }
   
   //--- Define some MQL5 structs we will use for our trade
   MqlTick latestPrice; // To be used for getting recent/lastest price quotes
   MqlTradeRequest tradeRequest; // To be used for sending our trade requests
   MqlTradeResult tradeResult; // To be used to get our trade results
   MqlRates tradeRate[]; // To be used to store the prices, volumes and spread of each bar
   ZeroMemory(tradeRequest); // Initialization of tradeRequest struct
   
   //--- Get the last price quote using the MQL5 MqlTick struct
   if (!SymbolInfoTick(_Symbol, latestPrice))
   {
      Alert("Error getting the latest price quote - error: ", GetLastError(), "!!!");
      return;
   }
   
   //--- Get the details of the latest 3 bars
   if (CopyRates(_Symbol, _Period, 0, 3, tradeRate) < 0)
   {
      Alert("Error copying rates/history data - error: ", GetLastError(), "!!!");
      return;
   }
   
   //--- Copy the new values of our indicators to buffers (arrays) using the handle
   if (CopyBuffer(dunniganHandle, 0, 0, 1, sellValue) < 0 || CopyBuffer(dunniganHandle, 1, 0, 1, buyValue) < 0) {
      Alert("Erro ao copiar os valores do buffer do indicador - error: ", GetLastError(), "!!!");
      return;      
   }
   
   // We have no errors, so continue
   
   // Do we have positions opened already?
   
   bool buyOpened = true; // variable to hold the result of Buy opened position
   bool sellOpened = true; // variable to hold the result of Sell opened position
   
   // Verifica se existem posições abertas disponíveis em buyTicket[]
   // Para as posições já abertas, ajuste-se o stop móvel para garantir um maior
   // ganho nas operações.
   for (int i = 0; i < ArraySize(buyTicket); i++) {
      if (PositionSelectByTicket(buyTicket[i])) {
         //continue; 
         trailingStop.doStopLoss(buyTicket[i]);
      } else {
         // Por segurança define a posição como zero
         buyTicket[i] = 0;
         buyOpened = false;
         break;
      }
   }
   
   // Verifica se existem posições abertas disponíveis em sellTicket[]
   // Para as posições já abertas, ajuste-se o stop móvel para garantir um maior
   // ganho nas operações.
   for (int i = 0; i < ArraySize(sellTicket); i++) {
      if (PositionSelectByTicket(sellTicket[i])) {
         //continue;
         trailingStop.doStopLoss(sellTicket[i]);
      } else {
         // Por segurança define a posição como zero
         sellTicket[i] = 0;
         sellOpened = false;
         break;
      }
   }
   
   // Copy the bar close price for the previous bar prior to the current bar, that is Bar 1
   closePrice = tradeRate[1].close;

   // Verifica se existe preço de compra disponível no buffer do indicador
   bool buyCondition = (buyValue[0] > 0);
   
   //--- Put all together
   if (buyCondition)
   {
      if (buyOpened) // any opened buy position?
      {
         Print("We already have a Buy Position!!!");
         return; // Don't open a new Buy Position
      } 
      tradeRequest.action = TRADE_ACTION_DEAL; // immediate order execution
      tradeRequest.price = NormalizeDouble(latestPrice.ask, _Digits); // latest ask price
      tradeRequest.sl = NormalizeDouble(latestPrice.ask - STP * _Point, _Digits); // Stop Loss
      tradeRequest.tp = NormalizeDouble(latestPrice.ask + TKP * _Point, _Digits); // Take Profit
      tradeRequest.symbol = _Symbol; // current pair
      tradeRequest.volume = Lot; // number of lots to trade
      tradeRequest.magic = EA_Magic; // Order Magic Number
      tradeRequest.type = ORDER_TYPE_BUY; // Buy order
      tradeRequest.type_filling = ORDER_FILLING_FOK; // Order execution type
      tradeRequest.deviation = 100; // Deviation from current price
      //--- Send order
      bool result = OrderSend(tradeRequest, tradeResult);
      
      // Get the result code
      if (tradeResult.retcode == 10009 || tradeResult.retcode ==10008) // Request is completed or order places
      {
         // Verifica qual índice do array buyTicket está livre
         for (int i = 0; i < ArraySize(buyTicket); i++) {
            if (buyTicket[i] == 0) {
               // Índice livre, armazena o número do ticket
               buyTicket[i] = tradeResult.order;
               Alert("A Buy order has been successfully places with Ticket #", buyTicket[i], "!!!");
               break;
            }
         }
      }
      else 
      {
         Alert("The Buy order request could not be completed - error: ", GetLastError());
         ResetLastError();
         return;
      }   
   }
    
   // Verifica se existe preço de venda disponível no buffer do indicador
   bool sellCondition = (sellValue[0] > 0);
   
   //--- Put all together
   if (sellCondition)
   {
      if (sellOpened) // any opened sell position?
      {
         Print("We already have a Sell Position!!!");
         return; // Don't open a new Sell Position
      } 
      tradeRequest.action = TRADE_ACTION_DEAL; // immediate order execution
      tradeRequest.price = NormalizeDouble(latestPrice.bid, _Digits); // latest ask price
      tradeRequest.sl = NormalizeDouble(latestPrice.bid + STP * _Point, _Digits); // Stop Loss
      tradeRequest.tp = NormalizeDouble(latestPrice.bid - TKP * _Point, _Digits); // Take Profit
      tradeRequest.symbol = _Symbol; // current pair
      tradeRequest.volume = Lot; // number of lots to trade
      tradeRequest.magic = EA_Magic; // Order Magic Number
      tradeRequest.type = ORDER_TYPE_SELL; // Sell order
      tradeRequest.type_filling = ORDER_FILLING_FOK; // Order execution type
      tradeRequest.deviation = 100; // Deviation from current price
      //--- Send order
      bool result = OrderSend(tradeRequest, tradeResult);
      
      // Get the result code
      if (tradeResult.retcode == 10009 || tradeResult.retcode ==10008) // Request is completed or order places
      {
         // Verifica qual índice do array buyTicket está livre
         for (int i = 0; i < ArraySize(sellTicket); i++) {
            if (sellTicket[i] == 0) {
               // Índice livre, armazena o número do ticket
               sellTicket[i] = tradeResult.order;
               Alert("A Sell order has been successfully places with Ticket #", sellTicket[i], "!!!");
               break;
            }
         }
      }
      else 
      {
         Alert("The Sell order request could not be completed - error: ", GetLastError());
         ResetLastError();
         return;
      }  
   }
  }
//+------------------------------------------------------------------+