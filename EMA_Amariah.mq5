//+------------------------------------------------------------------+
//|                                                  EMA_Amariah.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//--------Variables-------------
input int black_EMA_Period=5;
input int blue_EMA_Period=9;
input int lotSize= 0.01;
input int EMA_period=15; //15minutes
CTrade trade;
int emaHandle;
double p_close; // Variable to store the close value of a bar
double emaVal5[], emaVal9[]; // Dynamic array to hold the values of Exponential Moving Average for each bars

/*void OnTick()
  {
  
     double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),Digits);
     
     if(black_EMA_Period>blue_EMA_Period){
     trade.Buy(lotSize,NULL,Ask,0,(Ask+100 *_Point),NULL);
     
     }
     
     if(black_EMA_Period<blue_EMA_Period){
     trade.Sell(lotSize,NULL,Ask,0,(Ask+100 *_Point),NULL);
     
     }
  
   
  } */
  
  int OnInit()
  {

//--- Get the handle for Moving Average indicator
   emaHandle=iMA(_Symbol,_Period,EMA_period,0,MODE_EMA,PRICE_CLOSE);
//--- What if handle returns Invalid Handle
   if(emaHandle<0)
     {
      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");
      return (-1);
     }
     
     return 1; //not sure why this is needed. it gave me an error when I didn't have it
 }

//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release our indicator handles
   
   IndicatorRelease(emaHandle);
  }
  
  
 void OnTick()
 
 {
 
 //--- Define some MQL5 Structures we will use for our trade
   MqlTick latest_price;      // To be used for getting recent/latest price quotes
   MqlTradeRequest mrequest;  // To be used for sending our trade requests
   MqlTradeResult mresult;    // To be used to get our trade results
   MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
   ZeroMemory(mrequest);     // Initialization of mrequest structure


//--- Do we have positions opened already?
    bool Buy_opened=false;  // variable to hold the result of Buy opened position
    bool Sell_opened=false; // variable to hold the result of Sell opened position
    
    if (PositionSelect(_Symbol) ==true)  // we have an opened position
    {
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            Buy_opened = true;  //It is a Buy
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            Sell_opened = true; // It is a Sell
         }
    }
    
    // Copy the bar close price for the previous bar prior to the current bar, that is Bar 1
   p_close=mrate[1].close;  // bar 1 close price
   
    bool Buy_Condition_1 = (emaVal5[0]>emaVal5[1]) && (emaVal5[1]>emaVal5[2]); // EMA-5 Increasing upwards
    bool Buy_Condition_2 = p_close > emaVal5[1];         // previous price closed above EMA-5
    bool Buy_Condition_3 = (emaVal5[0]>emaVal9[0]) && (emaVal5[1]>emaVal9[1]) && (emaVal5[2]>emaVal9[2]);  //black EMA goes over blue EMA
    
    if(Buy_Condition_1 && Buy_Condition_2 && Buy_Condition_3)
     {
         // any opened Buy position?
         if (Buy_opened) 
         {
            Alert("We already have a Buy Position!!!"); 
            return;    // Don't open a new Buy Position
         }
         
     }
 
 
    mrequest.action = TRADE_ACTION_DEAL;                                // immediate order execution
    mrequest.price = NormalizeDouble(latest_price.ask,_Digits);          // latest ask price
    mrequest.symbol = _Symbol;                                         // currency pair
    mrequest.volume = lotSize;                                            // number of lots to trade
    mrequest.type = ORDER_TYPE_BUY;                                     // Buy Order
    
    OrderSend(mrequest,mresult);
 
 
 
 /*
    2. Check for a Short/Sell Setup : MA-8 decreasing downwards, 
    previous price close below it, ADX > 22, -DI > +DI
*/
//--- Declare bool type variables to hold our Sell Conditions
   bool Sell_Condition_1 = (emaVal5[0]<emaVal5[1]) && (emaVal5[1]<emaVal5[2]);  // MA-5 decreasing downwards
   bool Sell_Condition_2 = (p_close <emaVal5[1]);                         // Previous price closed below MA-5
   bool Sell_Condition_3 = (emaVal5[0]<emaVal9[0]) && (emaVal5[1]<emaVal9[1]) && (emaVal5[2]<emaVal9[2]);  //black EMA goes over blue EMA
   
   
   if(Sell_Condition_1 && Sell_Condition_2 && Sell_Condition_3)
   {
        // any opened Sell position?
            if (Sell_opened) 
            {
                Alert("We already have a Sell position!!!"); 
                return;    // Don't open a new Sell Position
            }
   }
   
    mrequest.action = TRADE_ACTION_DEAL;                                 // immediate order execution
    mrequest.price = NormalizeDouble(latest_price.bid,_Digits);          // latest Bid price
    mrequest.symbol = _Symbol;                                         // currency pair
    mrequest.volume = lotSize;                                            // number of lots to trade
    mrequest.type= ORDER_TYPE_SELL;                                     // Sell Order
    
     OrderSend(mrequest,mresult);
 }
  
  
  