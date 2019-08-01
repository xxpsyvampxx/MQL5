//+------------------------------------------------------------------+
//|                                                       HForex.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Arquivo MQH que contém as estratégias para negociação no mercado Forex."

//--- Inclusão de arquivos
#include "..\\HStrategy.mqh"

//+------------------------------------------------------------------+
//| Classe ForexAMA - Sinais de negociação baseado no Adaptive       |
//| Moving Average (AMA) usando as configurações padrão do indicador.|
//+------------------------------------------------------------------+
class CForexAMA : public CStrategy {

   private:
      int amaHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CForexAMA::init(void) {

   this.amaHandle = iAMA(_Symbol, _Period, 9, 2, 30, 0, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.amaHandle < 0) {
      Alert("Erro ao criar o indicador! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CForexAMA::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.amaHandle);
}

int CForexAMA::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double amaBuffer[]; // Armazena os valores do indicador AMA
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.amaHandle, 0, 0, 4, amaBuffer) < 4) {
      Print("Falha ao copiar os dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(amaBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os dados do indicador para determinar o sinal de negociação
   if (amaBuffer[3] < amaBuffer[2] && amaBuffer[2] < amaBuffer[1]) {
      sinal = 1;
   } else if (amaBuffer[3] > amaBuffer[2] && amaBuffer[2] > amaBuffer[1]) {
      sinal = -1;
   } else {
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CForexAMA::sinalConfirmacao(int sinalNegociacao) {
   
   int sinal = 0;
   
   /*
      Foi incluído confirmação de sinal baseado na posição do corpo da barra em relação a 
      AMA. O ganho é bem pequeno, mas já é um ganho.
   */
   
   //--- Para confirmar que o gráfico está mesmo em tendência, e não lateral, verifica
   //--- se a barra anterior (valores open e close) está acima ou abaixo da AMA
   
   double amaBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.amaHandle, 0, 0, 2, amaBuffer) < 2) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(amaBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 1) {
      
      if (amaBuffer[1] < iOpen(_Symbol, _Period, 1) && amaBuffer[1] < iClose(_Symbol, _Period, 1)) {
         sinal = 1;
      }
   
   } else if (sinalNegociacao == -1) {

      if (amaBuffer[1] > iOpen(_Symbol, _Period, 1) && amaBuffer[1] > iClose(_Symbol, _Period, 1)) {
         sinal = -1;
      }
   
   } 
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CForexAMA::sinalSaidaNegociacao(int chamadaSaida) {
   
   /*
      Os backtesting feitos usando o lucro garantido mostraram que, apesar de eu ter um
      percentual elevado de negociações lucrativas, as perdas que eu obtive anulam os ganhos
      e ainda geram prejuízo. Ou seja, os lucros não cobrem as perdas. Este fato fica evidente
      quando comparei o resultado de AUDUSD de Jul-Dez/2008 sem controles com um teste com o 
      controle de lucro. O controle de prejuízo gerou muito mais perdas, apesar de mais de 70%
      das negociações fecharem com lucro.
   */
   
   
   //--- Verifica se a chamada veio do método OnTimer()
   //--- O lucro garantido foi ativado para poder operar na conta real
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   
   /* Nos backtestings com AUDUSD utilizar o limite de prejuízo gerou bons ganhos durante o 
      período 2018-2019. Mas ao testar no período Jul-Dez/2008 gerou muitos prejuízos por 
      conta de muita oscilação do mercado, que acabou gerando muitas reversões e falsos sinais
      para a AMA. Até aumentando o valor limite, ainda gera prejuízo. Para o período de 2008 o 
      ideal é ter um recurso de reversão das posições, e/ou garantir o máximo de ganho possível
      para aguentar os stop loss.
   */
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }
   
   
   /*
      E usar ambas as estratégias não melhora muito os resultados referente ao período Jul-Dez/2008.
      Já quando comparamos com os resultados de 2018 até hoje, usar ambas as estratégias diminui
      as perdas obtidas quando usamos somente o lucro garantido, mas segue em desvantagem quando se
      compara com o controle de perda.
      Portanto, para a estratégia ForexAMA ficou o controle de perdas com o valor de 50.
   */
   
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CBMFBovespaForex - Sinais de negociação baseado no        |
//| cruzamento de MAs de 5 e 20 períodos, e também do oscilador      |
//| estocástico. Os dois indicadores dão sinais de negociação, que   |
//| são confirmados pelo NRTR e a posição da barra anterior em       |
//| relação a MA exponencial de 20 períodos, evitando assim abertura |
//| de novas posições contrários a tendência.                        |
//+------------------------------------------------------------------+
class CBMFBovespaForex : public CStrategy {

   private:
      int estocasticoHandle;
      int maAgilHandle;
      int maCurtaHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CBMFBovespaForex::init(void) {

   maAgilHandle = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
   maCurtaHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   estocasticoHandle = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maAgilHandle < 0 || maCurtaHandle < 0 || estocasticoHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CBMFBovespaForex::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maAgilHandle);
   IndicatorRelease(maCurtaHandle);
   IndicatorRelease(estocasticoHandle);
}

int CBMFBovespaForex::sinalNegociacao(void) {

   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maAgilBuffer[], maCurtaBuffer[]; // Armazena os valores das médias móveis
   double estocasticoBuffer[]; // Armazena os valores do oscilador estocástico
   
   //--- Copia o valor dos indicadores para seus respectivos buffers
   if (CopyBuffer(maAgilHandle, 0, 0, 3, maAgilBuffer) < 3
         || CopyBuffer(maCurtaHandle, 0, 0, 3, maCurtaBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(estocasticoHandle, 0, 0, 3, estocasticoBuffer) < 3) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maAgilBuffer, true) || !ArraySetAsSeries(maCurtaBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(estocasticoBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica a MA das barras para determinar a tendência
   if (maAgilBuffer[2] < maCurtaBuffer[1] && maAgilBuffer[1] > maCurtaBuffer[1]) {
      // Tendência em alta
      sinal = 1;
   } else if (maAgilBuffer[2] > maCurtaBuffer[1] && maAgilBuffer[1] < maCurtaBuffer[1]) {
      // Tendência em baixa
      sinal = -1;
   } else {
      // Sem tendência
      sinal = 0;
   }
   
   //--- Caso o sinal gerado pelas MAs seja zero, obtém-se o sinal de negociação do 
   //--- estocástico
   if (sinal == 0) {
      if (estocasticoBuffer[2] < 20 && estocasticoBuffer[1] > 20) {
         sinal = 1;
      } else if (estocasticoBuffer[2] > 80 && estocasticoBuffer[1] < 80) {
         sinal = -1;
      } else {
         sinal = 0;
      }
   }
   
   //--- Caso nenhum sinal tenha sido gerado, usa-se o NRTR para gerar o sinal de negociação
   if (sinal == 0) {
      if (trailingStop.trend() == 1) {
         //--- Confirmado o sinal de compra
         sinal = 2;
      } else if (trailingStop.trend() == -1) {
         //--- Confirmado o sinal de venda
         sinal = -2;
      } else {
         sinal = 0;
      }
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CBMFBovespaForex::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Compara o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR
   
   //--- Tendência está a favor?
   if (sinalNegociacao == 1 && trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (sinalNegociacao == -1 && trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Para confirmar que o gráfico está mesmo em tendência, e não lateral, verifica
   //--- se a barra anterior está acima ou abaixo da MA curta
   
   double maBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.maCurtaHandle, 0, 0, 4, maBuffer) < 4) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 2) {
      
      if (maBuffer[1] < iOpen(_Symbol, _Period, 1) && maBuffer[1] < iClose(_Symbol, _Period, 1)
         && maBuffer[1] < iHigh(_Symbol, _Period, 1) && maBuffer[1] < iLow(_Symbol, _Period, 1)) {
         
         sinal = 1;
      
      }
   
   } else if (sinalNegociacao == -2) {

      if (maBuffer[1] > iOpen(_Symbol, _Period, 1) && maBuffer[1] > iClose(_Symbol, _Period, 1)
         && maBuffer[1] > iHigh(_Symbol, _Period, 1) && maBuffer[1] > iLow(_Symbol, _Period, 1)) {
         
         sinal = -1;
      
      }
   
   } 
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CBMFBovespaForex::sinalSaidaNegociacao(int chamadaSaida) {
   
   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -25) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }
   
   
   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CTendenciaNRTR - Sinais de negociação do NRTR com         |
//| com confirmação da tendência a partir da posição das barras em   |
//| relação a MA exponencial de 20 períodos.                         |
//+------------------------------------------------------------------+
class CTendenciaNRTR : public CStrategy {

   private:
      int maHandle;
      int contNotificarUsuario;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      virtual void notificarUsuario(int sinalChamada);
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CTendenciaNRTR::init(void) {

   //--- Inicializa as variáveis
   this.contNotificarUsuario = 0;
   
   maHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (maHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CTendenciaNRTR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(maHandle);
}

int CTendenciaNRTR::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   //--- Obtém o sinal de negociação com o valor atual de suporte e resistência
   //--- do indicador NRTR. O indicador já está instanciado pois o mesmo é usado
   //--- para trailing stop
   
   //--- Tendência está a favor?
   if (trailingStop.trend() == 1) {
      //--- Confirmado o sinal de compra
      sinal = 1;
   } else if (trailingStop.trend() == -1) {
      //--- Confirmado o sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CTendenciaNRTR::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.maHandle, 0, 0, 4, maBuffer) < 4) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica qual posição da barra anterior em relação a MA curta para poder confirmar o sinal
   if (sinalNegociacao == 1) {
   
      if (maBuffer[1] < iOpen(_Symbol, _Period, 1) && maBuffer[1] < iClose(_Symbol, _Period, 1)
         && maBuffer[1] < iHigh(_Symbol, _Period, 1) && maBuffer[1] < iLow(_Symbol, _Period, 1)
         && maBuffer[2] < iOpen(_Symbol, _Period, 2) && maBuffer[2] < iClose(_Symbol, _Period, 2)
         && maBuffer[2] < iHigh(_Symbol, _Period, 2) && maBuffer[2] < iLow(_Symbol, _Period, 2)) {
         
         sinal = 1;
      
      }
   
   } else if (sinalNegociacao == -1) {

      if (maBuffer[1] > iOpen(_Symbol, _Period, 1) && maBuffer[1] > iClose(_Symbol, _Period, 1)
         && maBuffer[1] > iHigh(_Symbol, _Period, 1) && maBuffer[1] > iLow(_Symbol, _Period, 1)
         && maBuffer[2] > iOpen(_Symbol, _Period, 2) && maBuffer[2] > iClose(_Symbol, _Period, 2)
         && maBuffer[2] > iHigh(_Symbol, _Period, 2) && maBuffer[2] > iLow(_Symbol, _Period, 2)) {
         
         sinal = -1;
      
      }
   
   } else {
      //--- Sinal não confirmado
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CTendenciaNRTR::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }

   return(-1);
}

void CTendenciaNRTR::notificarUsuario(int sinalChamada) {
   
   //--- Notifica a cada 5 minutos das perdas financeiras
   if (sinalChamada == 9 && this.contNotificarUsuario == 5) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -25) {
               //--- Envia uma mensage ao usuário informando do prejuízo
               cUtil.enviarMensagemUsuario("Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " está gerando prejuízo de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT)) + "...");
            }
            this.contNotificarUsuario = 0;
            break;
         }
      }
   } else if (sinalChamada == 9) {  
      this.contNotificarUsuario++;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CTendenciaNRTRvolatile - Sinais de negociação do indicador|
//| customizado NRTR volatile, disponível na pasta                   |
//| Indicators/Artigos.                                              |
//+------------------------------------------------------------------+
class CTendenciaNRTRvolatile : public CStrategy {

   private:
      //--- Atributos
      int nrtrHandle;
      int maHandle;
      
   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CTendenciaNRTRvolatile::init(void) {

   //--- Parâmetros: período = 12; k = 1
   this.nrtrHandle = iCustom(_Symbol, _Period, "Artigos\\NRTRvolatile", 12, 1);
   
   this.maHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.nrtrHandle < 0 || maHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CTendenciaNRTRvolatile::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.nrtrHandle);
   IndicatorRelease(this.maHandle);
}

int CTendenciaNRTRvolatile::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double upBuffer[], downBuffer[], signalUpBuffer[], signalDownBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.nrtrHandle, 2, 0, 1, upBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 3, 0, 1, downBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 0, 0, 1, signalUpBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 1, 0, 1, signalDownBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(upBuffer, true) || !ArraySetAsSeries(downBuffer, true)
      || !ArraySetAsSeries(signalUpBuffer, true) || !ArraySetAsSeries(signalDownBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica o sinal da tendência
   if (signalUpBuffer[0] > 0) {
      //--- Tendência em alta
      sinal = 1;
   } else if (signalDownBuffer[0] > 0) {
      //--- Tendência em baixa
      sinal = -1;
   } else {
      //--- Tendência não definida
      sinal = 0;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CTendenciaNRTRvolatile::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double maBuffer[]; // Armazena os valores das médias móveis
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.maHandle, 0, 0, 4, maBuffer) < 4) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(maBuffer, true)) {
      Print("Falha ao definir o buffer como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica qual posição da barra anterior em relação a MA curta para poder confirmar o sinal
   if (sinalNegociacao == 1) {
   
      if (maBuffer[1] < iOpen(_Symbol, _Period, 1) && maBuffer[1] < iClose(_Symbol, _Period, 1)
         && maBuffer[1] < iHigh(_Symbol, _Period, 1) && maBuffer[1] < iLow(_Symbol, _Period, 1)
         && maBuffer[2] < iOpen(_Symbol, _Period, 2) && maBuffer[2] < iClose(_Symbol, _Period, 2)
         && maBuffer[2] < iHigh(_Symbol, _Period, 2) && maBuffer[2] < iLow(_Symbol, _Period, 2)) {
         
         sinal = 1;
      
      }
   
   } else if (sinalNegociacao == -1) {

      if (maBuffer[1] > iOpen(_Symbol, _Period, 1) && maBuffer[1] > iClose(_Symbol, _Period, 1)
         && maBuffer[1] > iHigh(_Symbol, _Period, 1) && maBuffer[1] > iLow(_Symbol, _Period, 1)
         && maBuffer[2] > iOpen(_Symbol, _Period, 2) && maBuffer[2] > iClose(_Symbol, _Period, 2)
         && maBuffer[2] > iHigh(_Symbol, _Period, 2) && maBuffer[2] > iLow(_Symbol, _Period, 2)) {
         
         sinal = -1;
      
      }
   
   } else {
      //--- Sinal não confirmado
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CTendenciaNRTRvolatile::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
   
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }

   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CDunnigan - Sinais de negociação do indicador Dunnigan.   |
//+------------------------------------------------------------------+
class CDunnigan : public CStrategy {

   private:
      int dunniganHandle;

   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CDunnigan::init(void) {
   
   this.dunniganHandle = dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan.ex5", 1); // Abertura/Fechamento
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.dunniganHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CDunnigan::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.dunniganHandle);
}

int CDunnigan::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double vendaBuffer[], compraBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.dunniganHandle, 0, 0, 1, vendaBuffer) < 1
      || CopyBuffer(this.dunniganHandle, 1, 0, 1, compraBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(vendaBuffer, true) || !ArraySetAsSeries(compraBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os buffers de compra e venda para determinar a tendência da nova barra
   if (compraBuffer[0] > 0 && vendaBuffer[0] == 0) {
      //--- Sinal de compra
      sinal = 1;
   } else if (compraBuffer[0] == 0 && vendaBuffer[0] > 0) {
      //--- Sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CDunnigan::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   if (sinalNegociacao == 1) {
      sinal = 1;
   } else if (sinalNegociacao == -1) {
      sinal = -1;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CDunnigan::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }

   return(-1);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Classe CDunniganNRTR - Sinais de negociação do indicador         |
//| Dunnigan com confirmação através dos sinais do NRTRvolatile.     |
//+------------------------------------------------------------------+
class CDunniganNRTR : public CStrategy {

   private:
      //--- Atributos
      int dunniganHandle;
      int nrtrHandle;
      
   public:
      //--- Métodos
      virtual int init(void);
      virtual void release(void);
      virtual int sinalNegociacao(void);
      virtual int sinalConfirmacao(int sinalNegociacao);
      virtual int sinalSaidaNegociacao(int chamadaSaida);  
      
      int onTickBarTimer(void) {
         return(1); // Nova barra
      }    

};

int CDunniganNRTR::init(void) {
   
   //--- Parâmetro: Abertura/Fechamento
   this.dunniganHandle = iCustom(_Symbol, _Period, "herculeshssj\\IDunnigan", 1);
   
   //--- Parâmetros: período = 12; k = 1
   this.nrtrHandle = iCustom(_Symbol, _Period, "Artigos\\NRTRvolatile", 12, 1);
   
   //--- Verifica se os indicadores foram criados com sucesso
   if (this.dunniganHandle < 0 || this.nrtrHandle < 0) {
      Alert("Erro ao criar os indicadores! Erro ", GetLastError());
      return(INIT_FAILED);
   }
   
   //--- Retorna o sinal de sucesso
   return(INIT_SUCCEEDED);
   
}

void CDunniganNRTR::release(void) {
   //--- Libera os indicadores
   IndicatorRelease(this.dunniganHandle);
   IndicatorRelease(this.nrtrHandle);
}

int CDunniganNRTR::sinalNegociacao(void) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double vendaBuffer[], compraBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.dunniganHandle, 0, 0, 1, vendaBuffer) < 1
      || CopyBuffer(this.dunniganHandle, 1, 0, 1, compraBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(vendaBuffer, true) || !ArraySetAsSeries(compraBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Verifica os buffers de compra e venda para determinar a tendência da nova barra
   if (compraBuffer[0] > 0 && vendaBuffer[0] == 0) {
      //--- Sinal de compra
      sinal = 1;
   } else if (compraBuffer[0] == 0 && vendaBuffer[0] > 0) {
      //--- Sinal de venda
      sinal = -1;
   }
   
   //--- Retorna o sinal de negociação
   return(sinal);
   
}

int CDunniganNRTR::sinalConfirmacao(int sinalNegociacao) {
   
   //--- Zero significa que não é pra abrir nenhum posição
   int sinal = 0;
   
   double upBuffer[], downBuffer[], signalUpBuffer[], signalDownBuffer[];
   
   //--- Copia o valor do indicador para seu respectivo buffer
   if (CopyBuffer(this.nrtrHandle, 2, 0, 1, upBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 3, 0, 1, downBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 0, 0, 1, signalUpBuffer) < 1
      || CopyBuffer(this.nrtrHandle, 1, 0, 1, signalDownBuffer) < 1) {
      Print("Falha ao copiar dados do indicador para o buffer! Erro ", GetLastError());
      return(sinal);
   }
   
   //--- Define os buffers como série temporal
   if (!ArraySetAsSeries(upBuffer, true) || !ArraySetAsSeries(downBuffer, true)
      || !ArraySetAsSeries(signalUpBuffer, true) || !ArraySetAsSeries(signalDownBuffer, true)) {
      Print("Falha ao definir os buffers como série temporal! Erro ", GetLastError());
      return(sinal);
   }
   
   if (sinalNegociacao == 1 && (upBuffer[0] > 0 || signalUpBuffer[0] > 0)) {
      //--- Tendência em alta
      sinal = 1;
   } else if (sinalNegociacao == -1 && (downBuffer[0] > 0 || signalDownBuffer[0] > 0)) {
      //--- Tendência em baixa
      sinal = -1;
   } else {
      //--- Tendência não definida
      sinal = 0;
   }
   
   //--- Retorna o sinal de confirmação
   return(sinal);
   
}

int CDunniganNRTR::sinalSaidaNegociacao(int chamadaSaida) {

   //--- Verifica se a chamada veio do método OnTimer()
   if (chamadaSaida == 9) {
   
      //--- Verifica se o ativo atingiu o lucro desejado para poder encerrar a posição
      if (cMoney.atingiuLucroDesejado()) {
         return(0); // Pode encerrar as posições abertas
      }
   }
   
   if (chamadaSaida == 0) {
      //--- Verifica o tamanho do prejuízo para poder encerrar as posições
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double lucro = PositionGetDouble(POSITION_PROFIT);
            if (lucro <= -50) {
               //--- Encerra a posição quando o prejuízo alcançar o limite máximo estabelecido
               return(0); // Pode encerrar as posições abertas
            }
         }
      }
   }

   return(-1);
}

//+------------------------------------------------------------------+

/* Desde ponto em diante ficam as declarações das classes das estratégias
   declaradas neste arquivo MQH
*/

//--- Declaração de classes
CBMFBovespaForex cBMFBovespaForex;
CTendenciaNRTR cTendenciaNRTR;
CTendenciaNRTRvolatile cTendenciaNRTRvolatile;
CDunnigan cDunnigan;
CDunniganNRTR cDunniganNRTR;
CForexAMA cForexAMA;

//+------------------------------------------------------------------+