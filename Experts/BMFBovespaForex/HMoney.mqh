//+------------------------------------------------------------------+
//|                                                       HMoney.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para gerenciamento financeiro da conta."

//--- Inclusão de arquivos
#include "HAccount.mqh"

//--- Declaração de classes
CAccount cAccount; // Classe com métodos para obter informações sobre a conta

//+------------------------------------------------------------------+
//| Classe CMoney - responsável por gerenciar os recursos financeiros|
//| disponíveis na conta.                                            |
//+------------------------------------------------------------------+
class CMoney {
      
   public:
      //--- Atributos
      double lucroGarantido;
      double tamanhoLote;
      double passoLote;
      
      //--- Métodos
      void CMoney() {};            // Construtor
      void ~CMoney() {};           // Construtor
      bool atingiuLucroDesejado(void);
      void limparVariaveis(void);
      double obterTamanhoLote(void);
};

//+------------------------------------------------------------------+
//| Retorna true quando o lucro das posições abertas atingir o lucro |
//| alvo desejado. O valor alvo é proporcional ao tamanho da margem  |
//| para abertura da posição para o símbolo atual.                   |
//+------------------------------------------------------------------+
bool CMoney::atingiuLucroDesejado(void) {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         
         double lucro = PositionGetDouble(POSITION_PROFIT);
         double valorAlvo = cAccount
            .obterMargemNecessariaParaNovaPosicao(PositionGetDouble(POSITION_VOLUME), 
               (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
            * 0.25; // 25% da margem disponível para abertura
         
         //--- Nos casos que o valorAlvo for menor que um, usa-se volume * 50;
         if (valorAlvo < 1) {
            valorAlvo = PositionGetDouble(POSITION_VOLUME) * 50;
         }
         
         if (lucro > valorAlvo) {
            
            //--- Se o lucro garantido está sendo definido pela primeira vez, o lucro atual será o lucro garantido
            if (this.lucroGarantido == 0) {
               this.lucroGarantido = lucro;
            } else {
               //--- Verifica se o lucro ultrapassou 25% do lucro garantido
               if ( lucro > (this.lucroGarantido * 1.25) ) {
                  //--- Define o novo lucro garantido
                  this.lucroGarantido = lucro;                  
                  
               } else if (lucro <= (lucroGarantido * 0.85) ) {
                  // Reseta as variáveis
                  this.lucroGarantido = 0;
               
                  //--- Retorna true informando que o lucro desejado foi atingido
                  return(true);
               
               }
            }
            
         } 
      }         
   }
   
   return(false);
}

//+------------------------------------------------------------------+
//| Limpa as variáveis de instância e variáveis estáticas.           |
//+------------------------------------------------------------------+
void CMoney::limparVariaveis(void) {
   this.tamanhoLote = 0;
}

//+------------------------------------------------------------------+
//| Retorna o valor do tamanho do lote para abrir novas posições.    |
//| Caso o histórico de negociações seja positivo, ou seja, o saldo  |
//| atual da conta suporte maior exposição a risco, será retornado   |
//| um valor maior do que o tamanho do lote padrão (atualmente em    |
//| 0.1 para Forex, 1, para minicontrato e 5 para contratos cheios.  |
//+------------------------------------------------------------------+
double CMoney::obterTamanhoLote(void) {

   //--- Determina o tamanho do lote
   if (this.tamanhoLote <= 0) {
      if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) > 0.1) {
         this.passoLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         this.tamanhoLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      } else {
         //--- Define o tamanho do lote e o step padrão
         this.passoLote = 0.1;
         this.tamanhoLote = 0.1;
      }
   }
   
   return(this.tamanhoLote);
}
//+------------------------------------------------------------------+