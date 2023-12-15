//+------------------------------------------------------------------+
//|                                            SSL Channel Chart.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_label1  "Bears"
#property indicator_color1 clrOrange
#property indicator_type1   DRAW_LINE
#property indicator_width1  2
#property indicator_label2  "Bulls"
#property indicator_color2 clrAqua
#property indicator_type2   DRAW_LINE
#property indicator_width2  2

//------------------------------------------------------------------

//---- input parameters
input int McGinleyPeriod = 10;
//---- buffers

double BearsBuffer[];
double BullsBuffer[];
double HighLowValidation[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BearsBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BullsBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HighLowValidation, INDICATOR_CALCULATIONS);

   ArraySetAsSeries(BearsBuffer, true);
   ArraySetAsSeries(BullsBuffer, true);
   ArraySetAsSeries(HighLowValidation, true);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int counted_bars = prev_calculated;
   int i, limit;

   if (counted_bars < 0) return(-1);
   if (counted_bars > 0) counted_bars--;

   limit = MathMax(rates_total - counted_bars - McGinleyPeriod, 1);

   for (i = limit; i >= 0; i--)
   {
      HighLowValidation[i] = HighLowValidation[i + 1];

      double MMAHigh = 0;
      double MMALow = 0;

      for (int j = 0; j < McGinleyPeriod; j++)
      {
         MMAHigh += high[rates_total - j - 1 - i] * (j + 1);
         MMALow += low[rates_total - j - 1 - i] * (j + 1);
      }

      MMAHigh = MMAHigh / ((McGinleyPeriod * (McGinleyPeriod + 1)) / 2);
      MMALow = MMALow / ((McGinleyPeriod * (McGinleyPeriod + 1)) / 2);

      if (close[rates_total - 1 - i] > MMAHigh) HighLowValidation[i] = 1;
      if (close[rates_total - 1 - i] < MMALow) HighLowValidation[i] = -1;

      if (HighLowValidation[i] == -1)
      {
         BearsBuffer[i] = MMAHigh;
         BullsBuffer[i] = MMALow;
      }
      else
      {
         BearsBuffer[i] = MMALow;
         BullsBuffer[i] = MMAHigh;
      }
   }

   // Plot arrows at crossover points
   for (i = limit; i >= 0; i--)
   {
      if (i > 0 && HighLowValidation[i] != HighLowValidation[i - 1])
      {
         double arrowPrice = HighLowValidation[i] == 1 ? BullsBuffer[i] : BearsBuffer[i];
         int arrowType = HighLowValidation[i] == 1 ? 233 : 234; // Up arrow (233) for Bulls, Down arrow (234) for Bears

         ObjectCreate(0, "CrossoverArrow_" + IntegerToString(i), OBJ_ARROW, 0, time[rates_total - 1 - i], arrowPrice);
         ObjectSetInteger(0, "CrossoverArrow_" + IntegerToString(i), OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, "CrossoverArrow_" + IntegerToString(i), OBJPROP_SELECTED, false);
         ObjectSetInteger(0, "CrossoverArrow_" + IntegerToString(i), OBJPROP_ARROWCODE, arrowType);
         ObjectSetInteger(0, "CrossoverArrow_" + IntegerToString(i), OBJPROP_COLOR, clrWhite);
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete all arrows when the indicator is removed
   for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if (StringFind(objName, "CrossoverArrow_") != -1 || StringFind(objName, "CrossoverTriangle_") != -1)
         ObjectDelete(0, objName);
   }
}
