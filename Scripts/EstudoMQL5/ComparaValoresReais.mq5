//+------------------------------------------------------------------+
//|                                          ComparaValoresReais.mq5 |
//|                              Copyright 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"

bool CompareDoubles(double number1,double number2) 
  { 
   if(NormalizeDouble(number1-number2,8)==0) return(true); 
   else return(false); 
  } 
  
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
  double first=0.3; 
   double second=3.0; 
   double third=second-2.7; 
   if(first!=third) 
     { 
      if(CompareDoubles(first,third)) 
         printf("%.16f e %.16f são iguais",first,third); 
     } 
 
  }
//+------------------------------------------------------------------+
