//+------------------------------------------------------------------+
//|                                                   SignalNRTR.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"

//--- Include
#include "..\..\ExpertSignal.mqh" // classe CExpertSignal

// wizard description start
//+-------------------------------------------------------------------+
//| Description of the class                                          |
//| Title=Signals of indicator 'NRTR'                                 |
//| Type=SignalAdvanced                                               |
//| Name=NRTR                                                         |
//| ShortName=NRTR                                                    |
//| Class=SignalNRTR                                                  |
//| Page=????                                                         |
//| Parameter=PeriodDyn,int,12,Período do canal dinâmico              |
//| Parameter=PercentDev,double,0.1,Largura do corredor em porcentagem|
//+-------------------------------------------------------------------+
// wizard description end
//+-------------------------------------------------------------------+
//| Class SignalNRTR.                                                 |
//| Purpose: Class of generator of trade signals based on             |
//|          the 'NRTR' indicator.                                    |
//| Is derived from the CExpertSignal class.                          |
//+-------------------------------------------------------------------+

class SignalNRTR : public CExpertSignal
  {
protected:
   int m_period_dyn; // Período do canal
   double m_percent_dev; // Largura do canal como uma porcentagem do preço
   CiCustom m_nrtr; // object indicator
   
   //--- Methods of getting data
   double UpSignal(int index) {
      return(m_nrtr.GetData(2, index));
   }
   double DnSignal(int index) {
      return(m_nrtr.GetData(3, index));
   }
   double BuffUpVal(int index) {
      return(m_nrtr.GetData(0, index));
   }
   double BuffDnVal(int index) {
      return(m_nrtr.GetData(1, index));
   }
   
public:
   SignalNRTR();
   ~SignalNRTR();
   bool ValidationSettings();
   bool InitIndicators(CIndicators *indicators);
   bool InitNRTR(CIndicators *indicators); 
   int LongCondition(void);
   int ShortCondition(void);
   
   //--- Methods of setting adjustable parameters
   void PeriodDyn(int value) {
      m_period_dyn = value;
   }
   
   void PercentDev(double value) {
      m_percent_dev = value;
   }
   
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalNRTR::SignalNRTR() : m_period_dyn(12), m_percent_dev(0.1)
  {
      //--- Initialization of protected data
      m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
      
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalNRTR::~SignalNRTR()
  {
  }

//+------------------------------------------------------------------+
//| O método verifica os parâmetros de entrada                       |
//+------------------------------------------------------------------+
bool SignalNRTR:: ValidationSettings()
  {
      // Chamamos o método da classe base
      if (!CExpertSignal::ValidationSettings()) {
         return(false);
      }
      
      // O período deve ser superior a 1
      if (m_period_dyn < 2) {
         Print("Período deve ser superior a 1");
         return(false);
      }
      
      // A largura do corredor deve ser positiva
      if (m_percent_dev <= 0) {
         Print("A largura do corredor deve ser positiva");
         return(false);
      }
      
      return(true);
  }
    
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalNRTR::InitIndicators(CIndicators *indicators) {
   //--- Check pointer
   if (indicators == NULL) {
      return(false);
   }
   
   // Initialization of indicators and timeseries of additional filters
   if (!CExpertSignal::InitIndicators(indicators)) {
      return(false);
   }
   
   //--- Create and initialize NRTR indicator
   if (!InitNRTR(indicators)) {
      return(false);
   }
   
   return(true);
}

//+------------------------------------------------------------------+
//| Create NRTR indicators.                                          |
//+------------------------------------------------------------------+  
bool SignalNRTR::InitNRTR(CIndicators *indicators) {
   //--- Check pointer
   if (indicators == NULL) {
      return(false);
   }
   
   //--- Add object to collection
   if (!indicators.Add(GetPointer(m_nrtr))) {
      Print(__FUNCTION__ + ": error adding object!");
      return(false);
   }
   
   //--- Criação de parâmetros do NRTR
   MqlParam parameters[3];
   
   parameters[0].type = TYPE_STRING;
   parameters[0].string_value = "Artigos\\NRTRIndicator.ex5";
   parameters[1].type = TYPE_INT;
   parameters[1].integer_value = m_period_dyn; // Período
   parameters[2].type = TYPE_DOUBLE;
   parameters[2].double_value = m_percent_dev; // Largura do canal
   
   //--- Initialize object
   if (!m_nrtr.Create(m_symbol.Name(), m_period, IND_CUSTOM, 3, parameters)) {
      Print(__FUNCTION__ + ": error initializing object!");
      return(false);
   }
   
   //--- OK
   return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalNRTR::LongCondition(void) {
   int idx = StartIndex();
   if (UpSignal(idx)) {
      return 100;
   } else {
      return 0;
   }
}
   
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalNRTR::ShortCondition(void) {
   int idx = StartIndex();
   if (DnSignal(idx)) {
      return 100;
   } else {
      return 0;
   }
}
//+------------------------------------------------------------------+