//+------------------------------------------------------------------+
//|                                              InterfaceAnimal.mq5 |
//|                              Copyright 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.00"

//--- interface básica para descrever animais 
interface IAnimal 
  { 
//--- métodos da interface padrão têm acesso público 
   void Sound();  // som que produz o animal 
  }; 
//+------------------------------------------------------------------+ 
//|  a classe CCat é herdada da interface IAnimal                    | 
//+------------------------------------------------------------------+ 
class CCat : public IAnimal 
  { 
public: 
                     CCat() { Print("Cat was born"); } 
                    ~CCat() { Print("Cat is dead");  } 
   //--- implementamos o método Sound da interface IAnimal 
   void Sound(){ Print("meou"); } 
  }; 
//+------------------------------------------------------------------+ 
//|  a classe CDog é herdada da interface IAnimal                    | 
//+------------------------------------------------------------------+ 
class CDog : public IAnimal 
  { 
public: 
                     CDog() { Print("Dog was born"); } 
                    ~CDog() { Print("Dog is dead");  } 
   //--- implementamos o método Sound da interface IAnimal 
   void Sound(){ Print("guaf"); } 
  }; 


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   //--- matriz do ponteiro para o objeto do tipo IAnimal 
   IAnimal *animals[2]; 
//--- geramos descendente IAnimal e salvamos os ponteiros para eles nas suas matrizes     
   animals[0]=new CCat; 
   animals[1]=new CDog; 
//--- chamamos o método Sound() da interface base IAnimal para cada descendente   
   for(int i=0;i<ArraySize(animals);++i) 
      animals[i].Sound(); 
//--- removemos objetos 
   for(int i=0;i<ArraySize(animals);++i) 
      delete animals[i]; 
//--- resultado da execução 
/* 
   Cat was born 
   Dog was born 
   meou 
   guaf 
   Cat is dead 
   Dog is dead 
*/ 
  }
//+------------------------------------------------------------------+
