//+------------------------------------------------------------------+
//|                                       ArtificialIntelligence.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"
#property description "Versão modificada e atualizada do EA ArtificialIntelligence desenvolvido originalmente por Yury V. Reshetov - ICQ:282715499 - http://reshetov.xnet.uz/."
#property description "Artigo: Como desenvolver uma estratégia de negociação lucrativa."
#property description "Link: https://www.mql5.com/pt/articles/1447"
#property description "Versão original do EA disponível em https://www.mql5.com/en/code/10281. As adaptações de MQL4 para MQL5 foram baseadas no artigo https://www.mql5.com/pt/articles/81."

//--- Parâmetros de entrada
input int x1 = 120; // Variável x1
input int x2 = 172; // Variável x2
input int x3 = 39; // Variável x3
input int x4 = 172; // Variável x4

input double stopLoss = 50; // Stop loss
input double lots = 0.1; // Lots
input int    magicNumber = 89898; // Número mágico EA

//--- Variáveis estáticas
static int spread = 10;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   if (isNewBar()) {
   
      //--- Obtém o valor do spread
      spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      
      //--- Obtém as informações do último preço da cotação
      MqlTick ultimoPreco;
      if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
         Print("Erro ao obter a última cotação - error ", GetLastError());
         return;
      }
      
      //--- Obtém o valor do perceptron
      double perceptronValue = perceptron();
      
      if (MQL5InfoInteger(MQL5_DEBUGGING)) {
         Print("Valor do perceptron: ", perceptronValue);
         Print("Valor do spread: ", spread);
      }
      
      //--- Verifica as posições abertas
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_BUY) {
            Print("Posição de compra!");
            
            //--- Verifica o lucro da posição      
            if (ultimoPreco.bid > (PositionGetDouble(POSITION_SL) + (stopLoss * 2 + spread) * _Point)) {
               Print("********** Entrei no IF de compra com lucro. **********");
               Print("Último preço: ", ultimoPreco.bid);
               Print("Valor comparado no if: ", (PositionGetDouble(POSITION_SL) + (stopLoss * 2 + spread) * _Point));
               
               if (perceptronValue < 0) {
                  //--- Abre uma nova ordem na posição reversa para poder encerrar
                  Print("*** ENCERRA A POSIÇÃO ***");                
                  MarketOrder(ORDER_TYPE_SELL, 
                     TRADE_ACTION_DEAL, 
                     ultimoPreco.bid, 
                     lots, 
                     0, 
                     0,
                     100,
                     PositionGetTicket(i));
               } else {
                  //--- Ajusta o stop loss da posição
                  Print("Trailing stop...");
                  MarketOrder(ORDER_TYPE_SELL, 
                     TRADE_ACTION_SLTP, 
                     PositionGetDouble(POSITION_PRICE_OPEN), 
                     PositionGetDouble(POSITION_VOLUME), 
                     ultimoPreco.ask - stopLoss * _Point, 
                     PositionGetDouble(POSITION_TP),
                     100,
                     PositionGetTicket(i));                  
               }
            }
            
         } else {
            Print("Posição de venda!");
            
            //--- Verifica o lucro da posição      
            if (ultimoPreco.ask < (PositionGetDouble(POSITION_SL) - (stopLoss * 2 + spread) * _Point)) {
               Print("********** Entrei no IF de venda com lucro. **********");
               Print("Último preço: ", ultimoPreco.ask);
               Print("Valor comparado no if: ", (PositionGetDouble(POSITION_SL) - (stopLoss * 2 + spread) * _Point));
               
               if (perceptronValue > 0) {
                  //--- Abre uma nova ordem na posição reversa para poder encerrar
                  Print("*** ENCERRA A POSIÇÃO ***");
                  MarketOrder(ORDER_TYPE_BUY, 
                     TRADE_ACTION_DEAL, 
                     ultimoPreco.ask, 
                     lots, 
                     0, 
                     0,
                     100,
                     PositionGetTicket(i));
               } else {
                  Print("Trailing stop...");
                  MarketOrder(ORDER_TYPE_BUY, 
                     TRADE_ACTION_SLTP, 
                     PositionGetDouble(POSITION_PRICE_OPEN), 
                     PositionGetDouble(POSITION_VOLUME), 
                     ultimoPreco.bid + stopLoss * _Point, 
                     PositionGetDouble(POSITION_TP),
                     100,
                     PositionGetTicket(i));
               }
            }
         }
      }
      
      //--- Verifica a possibilidade de abrir posições longas e curtas
      if (perceptronValue > 0 ) {
         Print("Uma nova ordem de compra foi enviada!");
         MarketOrder(ORDER_TYPE_BUY, 
                     TRADE_ACTION_DEAL, 
                     ultimoPreco.ask, 
                     lots, 
                     ultimoPreco.ask - stopLoss * _Point, 
                     0);
      } else {
         Print("Uma nova ordem de venda foi enviada!");
         MarketOrder(ORDER_TYPE_SELL, 
                     TRADE_ACTION_DEAL, 
                     ultimoPreco.bid, 
                     lots, 
                     ultimoPreco.bid + stopLoss * _Point, 
                     0);
      }
      
   }

}

//+------------------------------------------------------------------+ 
//|  Efetua uma operação de negociação a mercado                     |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+
bool MarketOrder(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation = 100,
                 ulong positionTicket = 0) {
   
   //--- Declaração e inicialização das estruturas
   MqlTradeRequest tradeRequest; // Envia as requisições de negociação
   MqlTradeResult tradeResult; // Receba o resultado das requisições de negociação
   ZeroMemory(tradeRequest); // Inicializa a estrutura
   ZeroMemory(tradeResult); // Inicializa a estrutura
   
   //--- Popula os campos da estrutura tradeRequest
   tradeRequest.action = typeAction; // Tipo de execução da ordem
   tradeRequest.price = NormalizeDouble(price, _Digits); // Preço da ordem
   tradeRequest.sl = NormalizeDouble(stop, _Digits); // Stop loss da ordem
   tradeRequest.tp = NormalizeDouble(profit, _Digits); // Take profit da ordem
   tradeRequest.symbol = _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type = typeOrder; // Tipo de ordem
   tradeRequest.magic = magicNumber; // Número mágico do EA
   tradeRequest.type_filling = ORDER_FILLING_FOK; // Tipo de execução da ordem
   tradeRequest.deviation = deviation; // Desvio permitido em relação ao preço
   tradeRequest.position = positionTicket; // Ticket da posição
   
   //--- Envia a ordem
   if (!OrderSend(tradeRequest, tradeResult)) {
      //-- Exibimos as informações sobre a falha
      Alert("Não foi possível enviar a ordem. Erro ", GetLastError());
      PrintFormat("Envio de ordem %s %s %.2f a %.5f, erro %d", tradeRequest.symbol, EnumToString(typeOrder), volume, tradeRequest.price, GetLastError());
      return(false);
   }
   
   //-- Exibimos as informações sobre a ordem bem-sucedida
   Alert("Uma nova ordem foi enviada com sucesso! Ticket #", tradeResult.order);
   PrintFormat("Código %u, negociação %I64u, ticket #%I64u", tradeResult.retcode, tradeResult.deal, tradeResult.order);
   return(true);
}

//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra                      |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool isNewBar() {

   static datetime barTime = 0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime = iTime(_Symbol, _Period, 0); // Obtemos o tempo de abertura da barra zero
   
   //-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
   if (barTime != currentBarTime) {
      barTime = currentBarTime;
      if (MQL5InfoInteger(MQL5_DEBUGGING)) {
         //--- Exibimos uma mensagem sobre o tempo de abertura da nova barra
         PrintFormat("%s: nova barra em %s %s aberta em %s", __FUNCTION__, _Symbol,
            StringSubstr(EnumToString(_Period), 7), TimeToString(TimeCurrent(), TIME_SECONDS));
      }
      
      return(true); // temos uma nova barra
   }

   return(false); // não há nenhuma barra nova
}

//+------------------------------------------------------------------+
//|  PERCEPTRON - uma função de perceber e reconhecer                |
//+------------------------------------------------------------------+
double perceptron() {
   double w1 = x1 - 100.0;
   double w2 = x2 - 100.0;
   double w3 = x3 - 100.0;
   double w4 = x4 - 100.0;
   double a1 = iACMQL4(_Symbol, PERIOD_CURRENT, 0);
   double a2 = iACMQL4(_Symbol, PERIOD_CURRENT, 7);
   double a3 = iACMQL4(_Symbol, PERIOD_CURRENT, 14);
   double a4 = iACMQL4(_Symbol, PERIOD_CURRENT, 21);
   return (w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
}

//+------------------------------------------------------------------+
//|  Versão adaptada do MQL4 para MQL5 do oscilador                  |
//|  Aceleração/Desaceleração Bill Williams.                         |
//|                                                                  |
//|  Trecho de código adaptado do artigo                             |
//|  https://www.mql5.com/pt/articles/81.                            |
//+------------------------------------------------------------------+
double iACMQL4(string symbol, ENUM_TIMEFRAMES timeframe, int shift) {
   int handle = iAC(symbol, timeframe);
   if (handle < 0) {
      Print("Falha ao criar o handle do objeto iAC! Erro ", GetLastError());
   } else {
      double buffer[];
      if (CopyBuffer(handle, 0, shift, 1, buffer) > 0) {
         return(buffer[0]);
      } else {
         Print("Falha ao copiar os dados do buffer do indicador! Erro ", GetLastError());
      }
   }
   return(-1);
}