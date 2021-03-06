//+------------------------------------------------------------------+
//|                                                   EAForexAUD.mq5 |
//|                            Copyright ® 2021, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2021, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.0"

//--- Inclusão de arquivos
#include "Estrategias\HAUDUSD.mqh"

//--- Variáveis estáticas
static int sinalAConfirmar = 0;
static ENUM_SYMBOL_CALC_MODE mercadoAOperar = SYMBOL_CALC_MODE_FOREX;
static int magicNumber = 19851024;
static int tickBarraTimer = 1; // Padrão, nova barra

//--- Parâmetros de entrada


//+------------------------------------------------------------------+
//| Inicialização do Expert Advisor                                  |
//+------------------------------------------------------------------+
int OnInit() {
   
   //--- Exibe informações sobre a conta de negociação
   cAccount.relatorioInformacoesConta();
   
   /*** Carrega os parâmetros do EA do arquivo ***/
   
   //--- Nome do arquivo
   string filename = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" + _Symbol + ".bin";
   
   //--- Verifica se o arquivo existe
   if (FileIsExist(filename)) {
      //--- Abre o arquivo para leitura
      int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN);
      if (fileHandle != INVALID_HANDLE) {
         //--- Lê o magic number do EA
         magicNumber = FileReadInteger(fileHandle);
         
         //--- Fecha o arquivo
         FileClose(fileHandle);
      }      
      
   } else {
   
      //--- Gera o magic number do EA
      MathSrand(GetTickCount());
      magicNumber = MathRand() * 255;
      
      //--- Abre o arquivo para escrita
      int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN);
      if (fileHandle != INVALID_HANDLE) {
         // Grava o magic number do EA no arquivo
         FileWriteInteger(fileHandle, magicNumber);
         
         //--- Fecha o arquivo
         FileClose(fileHandle);
      }
   }
   
   //--- Cria um temporizador de 1 minuto
   EventSetTimer(60);
   
   //--- Inicializa a classe para stop móvel
   trailingStop.Init(_Symbol, _Period, magicNumber, true, true, false);
   
   //--- Carrega os parâmetros do indicador NRTR
   if (!trailingStop.setupParameters(40, 2)) {
      Alert("Erro na inicialização da classe de stop móvel! Saindo...");
      return(INIT_FAILED);
   }
   
   //--- Define o mercado que o EA está operando
   mercadoAOperar = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
   
   //--- Salva o valor do saldo atual da conta
   cMoney.saldoConta = AccountInfoDouble(ACCOUNT_BALANCE);
   
   //--- Inicia o stop móvel para as posições abertas
   trailingStop.on();
   
   //--- Inicializa os indicadores usados pela estratégia
   int inicializarEA = INIT_FAILED;
   
   tickBarraTimer = cAUDUSD.onTickBarTimer();
   inicializarEA = cAUDUSD.init();
   
   //--- Retorna o sinal de inicialização do EA   
   return(inicializarEA);
}

//+------------------------------------------------------------------+
//| Encerramento do Expert Advisor                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   //--- Libera os indicadores usado pela estratégia
   cAUDUSD.release();
   
   //--- Encerra o stop móvel
   trailingStop.Deinit();
   
   //--- Destrói o temporizador
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Método que recebe os ticks vindo do gráfico                      |
//+------------------------------------------------------------------+
void OnTick() {
   
    //--- Checa se as posições precisam ser encerradas após a chegada de um novo tick
    sinalSaidaNegociacao(0);
   
   //--- Verifica se a estratégia aciona os sinais de negociação após uma
   //--- nova barra no gráfico
   if (temNovaBarra()) {
   
      //--- Checa se as posições precisam ser encerradas
      sinalSaidaNegociacao(1);
   
      if (tickBarraTimer == 1) {
         //--- Verifica se possui sinal de negociação a confirmar
         sinalAConfirmar = sinalNegociacao();
         if (sinalAConfirmar != 0) {
            confirmarSinal();         
         }
      }
      
      //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
      //--- estratégia de negociação escolhida. A notificação é disparada com a chegada
      //--- de uma nova barra
      notificarUsuario(1);
   }
      
   //--- Verifica se a estratégia aciona os sinais de negociação após um novo tick
   if (tickBarraTimer == 0) {
   
      //--- Verifica se possui sinal de negociação a confirmar
      sinalAConfirmar = sinalNegociacao();
      if (sinalAConfirmar != 0) {
         confirmarSinal();         
      }
      
   }
   
   //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
   //--- estratégia de negociação escolhida. A notificação é disparada com a chegada
   //--- de um novo tick
   notificarUsuario(0);   
}

//+------------------------------------------------------------------+
//| Conjuntos de rotinas padronizadas a serem executadas a cada      |
//| minuto (60 segundos).                                            |
//+------------------------------------------------------------------+
void OnTimer() {

   //--- Verifica se o mercado ainda está aberto para poder realizar o 
   //--- trailing stop das posições abertas
   
   //--- Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   if (mercadoAberto(horaAtual)) {
   
      //--- Atualiza os dados do stop móvel
      trailingStop.refresh();
      
      //--- Realiza o stop móvel das posições abertas
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            trailingStop.doStopLoss(PositionGetTicket(i));
         }         
      }
   
   }

   //--- Checa se as posições precisam ser encerradas
   sinalSaidaNegociacao(9);
   
   //--- Verifica se a estratégia aciona os sinais de negociação após transcorrer
   //--- o tempo no timer
   if (tickBarraTimer == 9) {
   
      //--- Verifica se possui sinal de negociação a confirmar
      sinalAConfirmar = sinalNegociacao();
      if (sinalAConfirmar != 0) {
         confirmarSinal();         
      }
            
   }
   
   //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
   //--- estratégia de negociação escolhida. A notificação é disparada com a
   //--- passagem de um novo ciclo do timer.
   notificarUsuario(9);
   
}

//+------------------------------------------------------------------+
//|  Função responsável por informar se o momento é de abrir uma     |
//|  posição de compra ou venda.                                     |
//|                                                                  |
//|  Valor negativo - Abre uma posição de venda                      |
//|  Valor positivo - Abre uma posição de compra                     |
//|  Valor zero (0) - Nenhum posição é aberta                        |
//+------------------------------------------------------------------+
int sinalNegociacao() {

   //--- Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   //--- Verifica se o mercado está aberto para negociações
   if (mercadoAberto(horaAtual)) {
   
      return(cAUDUSD.sinalNegociacao());
   
   }
   
   return(0);
}

//+------------------------------------------------------------------+
//|  Função responsável por verificar se é o momento de encerrar a   |
//|  posição de compra ou venda aberta. Caso a estratégia retorna o  |
//|  valor 0 significa que as posições abertas para o símbolo atual  |
//|  devem ser encerradas.                                           |
//+------------------------------------------------------------------+
void sinalSaidaNegociacao(int chamadaSaida) {

   //--- O padrão é manter as posições abertas
   int sinal = -1;
   
   sinal = cAUDUSD.sinalSaidaNegociacao(chamadaSaida);

   //--- Verifica o sinal de saída da negociação aberta
   if (sinal == 0) {
      //--- Encerra as posições para o símbolo atual
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            string mensagem = "";
            
            //--- Constrói a mensagem
            if (PositionGetDouble(POSITION_PROFIT) >= 0) {
               mensagem = "Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " fechado com o lucro de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT));
            } else {
               mensagem = "Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " fechado com o prejuízo de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT));
            }
            
            //--- Envia a ordem para encerrar a posição
            cOrder.fecharPosicao(PositionGetTicket(i));
            
            //--- Envia a notificação para o usuário            
            cUtil.enviarMensagemUsuario(mensagem);
            
         }
      }
   }
   
   //--- Verifica o saldo atual da conta e atualiza o atributo correspondente
   //--- em cMoney para poder realizar a proteção do novo saldo
   if ((AccountInfoDouble(ACCOUNT_BALANCE) - cMoney.saldoConta) > 100) {
      //--- Incrementa o saldo da conta em cMoney
      cMoney.saldoConta += 100;
   }
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é de abrir uma    |
//|  posição de compra ou venda. Esta função é chamada sempre que se |
//|  obter a confirmação do sinal a partir de outro indicador ou     |
//|  outra forma de cálculo.                                         |
//|                                                                  |
//|  -1 - Confirma a abertura da posição de venda                    |
//|  +1 - Confirma a abertura da posição de compra                   |
//|   0 - Informa que nenhuma posição deve ser aberta                |
//+------------------------------------------------------------------+
int sinalConfirmacao() {

   return(cAUDUSD.sinalConfirmacao(sinalAConfirmar));
   
}

//+------------------------------------------------------------------+
//|  Chama o método notificarUsuario() da estratégia selecionada     |
//|  para poder realizar notificar o usuário de algum evento em      |
//|  particular ou de uma intervenção que precisa ser feita durante a|
//|  negociação. O método recebe um sinal de chamada, que identifica |
//|  qual evento realizou a chamada.                                 |
//+------------------------------------------------------------------+
void notificarUsuario(int sinalChamada) {

   cAUDUSD.notificarUsuario(sinalChamada);

}

//+------------------------------------------------------------------+
//| Retorna o valor do stop loss de acordo com os critérios definidos|
//| pela estratégia selecionada.                                     |
//+------------------------------------------------------------------+
double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   return(cAUDUSD.obterStopLoss(tipoOrdem, preco));

}

//+------------------------------------------------------------------+
//| Retorna o valor do take profit de acordo com os critérios        |
//| definidos pela estratégia selecionada.                           |
//+------------------------------------------------------------------+
double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   return(cAUDUSD.obterTakeProfit(tipoOrdem, preco));

}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar o sinal de negociação indicado |
//|  na abertura da nova barra e abrir uma nova posição de compra/   |
//|  venda de acordo com a tendência do mercado.                     |
//+------------------------------------------------------------------+
void confirmarSinal() {

   //--- Obtém o sinal de confirmação recebido
   int sinalConfirmado = sinalConfirmacao();
   
   if (sinalAConfirmar > 0 && sinalConfirmado == 1) {
      
      //--- Verifica se existe uma posição de compra já aberta
      if (cOrder.existePosicoesAbertas(POSITION_TYPE_BUY)) {
         //--- Substituir com algum código útil
      } else {
                  
         //--- Confere se a posição contrária foi realmente fechada
         if (!cOrder.existePosicoesAbertas(POSITION_TYPE_SELL)) {
            //--- Abre a nova posição de compra
            realizarNegociacao(ORDER_TYPE_BUY);
         }
         
      }
      
   } else if (sinalAConfirmar < 0 && sinalConfirmado == -1) {
         
      //--- Verifica se existe uma posição de venda já aberta
      if (cOrder.existePosicoesAbertas(POSITION_TYPE_SELL)) {
         //--- Substituir com algum código útil
      } else {
         
         //--- Confere se a posição contrária foi realmente fechada
         if (!cOrder.existePosicoesAbertas(POSITION_TYPE_BUY)) {
         
            //--- Abre a nova posição de venda
            realizarNegociacao(ORDER_TYPE_SELL);
         }
      }
      
   } else {
      //--- Delega para a estratégia a realização da abertura de novas posições
      //--- e o fechamento das existentes.
      cAUDUSD.realizarNegociacao();
   }
   
}
   
//+------------------------------------------------------------------+
//|  Função responsável por realizar a negociação propriamente dita, |
//|  obtendo as informações do último preço recebido para calcular o |
//|  spread, stop loss e take profit da ordem a ser enviada.         |
//+------------------------------------------------------------------+   
void realizarNegociacao(ENUM_ORDER_TYPE tipoOrdem) {

   //--- Obtém o valor do spread
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   //--- Obtém o tamanho do tick
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   //--- Obtém as informações do último preço da cotação
   MqlTick ultimoPreco;
   if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
      Print("Erro ao obter a última cotação! - Erro ", GetLastError());
      return;
   }
   
   if (tipoOrdem == ORDER_TYPE_BUY) {
   
      // Verifica se existe margem disponível para abertura na nova posição de compra
      if (!cOrder.possuiMargemParaAbrirNovaPosicao(cMoney.obterTamanhoLote(), _Symbol, POSITION_TYPE_BUY)) {
         //--- Emite um alerta informando a falta de margem disponível
         cUtil.enviarMensagem(TERMINAL, "Sem margem disponível para abertura de novas posições!");
         return;
      }
      
      //--- Ajusta o preço nos casos do tick vier com um valor inválido
      double preco = ultimoPreco.ask;
      
      if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
         // Diminui o resto da divisão do preço com o tick size para igualar ao
         // último múltiplo do valor de tick size
         if (fmod(preco, tickSize) != 0) {
            preco = preco - fmod(preco, tickSize);
         }
      }
      
      //--- Envia a ordem de compra
      cOrder.enviaOrdem(ORDER_TYPE_BUY, 
         TRADE_ACTION_DEAL, 
         preco, 
         cMoney.obterTamanhoLote(), 
         obterStopLoss(tipoOrdem, preco), 
         obterTakeProfit(tipoOrdem, preco));
   
   } else {
   
      // Verifica se existe margem disponível para abertura na nova posição de venda
      if (!cOrder.possuiMargemParaAbrirNovaPosicao(cMoney.obterTamanhoLote(), _Symbol, POSITION_TYPE_SELL)) {
         //--- Emite um alerta informando a falta de margem disponível
         cUtil.enviarMensagem(TERMINAL, "Sem margem disponível para abertura de novas posições!");
         return;
      }
      
      //--- Ajusta o preço nos casos do tick vier com um valor inválido
      double preco = ultimoPreco.bid;
      
      if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
         // Diminui o resto da divisão do preço com o tick size para igualar ao
         // último múltiplo do valor de tick size
         if (fmod(preco, tickSize) != 0) {
            preco = preco - fmod(preco, tickSize);
         }
      }

      //--- Envia a ordem de venda
      cOrder.enviaOrdem(ORDER_TYPE_SELL, 
         TRADE_ACTION_DEAL, 
         preco, 
         cMoney.obterTamanhoLote(), 
         obterStopLoss(tipoOrdem, preco), 
         obterTakeProfit(tipoOrdem, preco));
    
   } 
}

//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra no gráfico           |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool temNovaBarra() {

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
//|  Retorna true caso esteja dentro do perído permitido pelo        |
//|  mercado que o usuário está operando (BM&FBovespa ou Forex).     |
//|                                                                  |
//|  Todas as ordens pendentes e posições abertas são encerradas     |
//|  quando estão fora dos horários dos pregões.                     |
//+------------------------------------------------------------------+  
bool mercadoAberto(MqlDateTime &hora) {

   switch(mercadoAOperar) {
      case SYMBOL_CALC_MODE_EXCH_STOCKS:
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
         //--- Verifica se a hora está entre 10h e 17h
         if (hora.hour >= 10 && hora.hour < 17) {
            return(true);
         }      
         break;
      case SYMBOL_CALC_MODE_FOREX:
      case SYMBOL_CALC_MODE_CFD:
         if ( (hora.day_of_week == 1 && hora.hour == 0) || (hora.day_of_week == 5 && hora.hour == 23) ) {
            //--- Sai do switch para poder fechar as ordens e posições abertas
            break;
         } else {
            return(true);
         }
         
         break;
   }
   
   //--- Caso a hora não se encaixa em nenhuma das condições acima, todas as ordens
   //--- pendentes e posições abertas são fechadas
         
   //-- Fecha todas as posições abertas
   if (PositionsTotal() > 0) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         cOrder.fecharPosicao(PositionGetTicket(i));
      }
   }
   
   return(false);
}
//+------------------------------------------------------------------+