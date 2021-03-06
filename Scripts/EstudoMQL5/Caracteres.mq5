//+------------------------------------------------------------------+
//|                                                   Caracteres.mq5 |
//|                              Copyright 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
  /*
//---
   //--- define constantes de caracteres 
   int symbol_0='0'; 
   int symbol_9=symbol_0+9; // obtém o símbolo '9' 
//--- valores de saída de constantes 
   printf("Num formato decimal: symbol_0 = %d,  symbol_9 = %d",symbol_0,symbol_9); 
   printf("Num formato hexadecimal: symbol_0 = 0x%x,  symbol_9 = 0x%x",symbol_0,symbol_9); 
//--- entrada de constantes em uma string 
   string test="";  
   StringSetCharacter(test,0,symbol_0); 
   StringSetCharacter(test,1,symbol_9); 
//--- isso é como eles se apresentam em uma string 
   Print(test);
   */

//+------------------------------------------------------------------+
/*
//--- declara constantes de caracteres 
   int a='A'; 
   int b='$'; 
   int c='©';      // código 0xA9 
   int d='\xAE';   // código do símbolo ® 
//--- saída imprime constantes 
   Print(a,b,c,d); 
//--- acrescenta um caractere na string 
   string test=""; 
   StringSetCharacter(test,0,a); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,b); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,c); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,d); 
   Print(test); 
//--- representa caracteres como número 
   int a1=65; 
   int b1=36; 
   int c1=169; 
   int d1=174; 
//--- acrescenta um caractere na string 
   StringSetCharacter(test,1,a1); 
   Print(test); 
//--- acrescenta um caractere na string 
   StringSetCharacter(test,1,b1); 
   Print(test); 
//--- acrescenta um caractere na string 
   StringSetCharacter(test,1,c1); 
   Print(test); 
//--- acrescenta um caractere na string 
   StringSetCharacter(test,1,d1); 
   Print(test); 
   */
//+------------------------------------------------------------------+

//---  
   int a=0xAE;     // o código de ® corresponde ao literal '\xAE'  
   int b=0x24;     // o código de $ corresponde ao literal '\x24'  
   int c=0xA9;     // o código de © corresponde ao literal '\xA9'  
   int d=0x263A;   // o código de ? corresponde ao literal '\x263A'  
//--- mostrar valores 
   Print(a,b,c,d); 
//--- acrescenta um caractere na string 
   string test=""; 
   StringSetCharacter(test,0,a); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,b); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,c); 
   Print(test); 
//--- substitui um caractere na string 
   StringSetCharacter(test,0,d); 
   Print(test); 
//--- código de terno cartão 
   int a1=0x2660; 
   int b1=0x2661; 
   int c1=0x2662; 
   int d1=0x2663; 
//--- acrescenta um caractere de espadas 
   StringSetCharacter(test,1,a1); 
   Print(test); 
//--- acrescenta um caractere de copas 
   StringSetCharacter(test,2,b1); 
   Print(test); 
//--- acrescenta um caractere de ouros 
   StringSetCharacter(test,3,c1); 
   Print(test); 
//--- acrescenta um caractere de paus 
   StringSetCharacter(test,4,d1); 
   Print(test); 
//--- Exemplo de literais de caractere em uma string 
   test="Rainha\x2660Ás\x2662"; 
   printf("%s",test); 
  }

