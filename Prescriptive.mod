/*********************************************
 * OPL 22.1.1.0 Model
 * Author: Lekhu
 * Creation Date: 11-Apr-2024 at 1:55:36 AM
 *********************************************/
// Sets
{string} Suppliers = ...;
{string} Refineries = ...;
{string} Products = ...;
{string} Tankers = ...;

// Parameters
float supply[Suppliers] = ...;
float capacity[Refineries] = ...;
float demand[Refineries][Products] = ...;
float api[Suppliers] = ...;
float sulphur[Suppliers] = ...;
float min_api[Products] = ...;
float max_api[Products] = ...;
float max_sulphur[Products] = ...;
int num_tankers[Tankers] = ...;
float crude_price[Suppliers] = ...;
float product_price[Products] = ...;
float processing_cost = 19;
float excess_discount = 0.07;
float port_cost[Suppliers][Refineries][Tankers] = ...;
float tanker_rate[Tankers] = ...;
float fuel_cost[Tankers] = ...;
float trip_time[Suppliers][Refineries] = ...;

// Decision variables
dvar float+ x[Suppliers][Refineries];
dvar float+ y[Suppliers][Refineries][Products];
dvar float+ z[Suppliers][Refineries][Tankers];
dvar boolean tanker_used[Suppliers][Refineries][Tankers];
dvar float+ excess[Refineries][Products];

// Objective function
maximize
  sum(j in Refineries, k in Products) 
    (product_price[k] * demand[j][k] 
     + (1 - excess_discount) * product_price[k] * excess[j][k])
  - sum(i in Suppliers, j in Refineries) crude_price[i] * x[i][j]
  - sum(i in Suppliers, j in Refineries) processing_cost * x[i][j]
  - sum(i in Suppliers, j in Refineries, t in Tankers) 
      (port_cost[i][j][t] + tanker_rate[t] * ceil(trip_time[i][j] / 24) 
       + fuel_cost[t] * trip_time[i][j]) * tanker_used[i][j][t];

subject to {
  // Crude oil supply constraints
  forall(i in Suppliers)
    sum(j in Refineries) x[i][j] <= supply[i];
  
  // Refinery capacity constraints
  forall(j in Refineries)  
    sum(i in Suppliers) x[i][j] <= capacity[j];

  // Petroleum product demand constraints  
  forall(k in Products, j in Refineries)
    sum(i in Suppliers) y[i][j][k] >= demand[j][k];
    
  // Excess production constraints
  forall(k in Products, j in Refineries)
    excess[j][k] == sum(i in Suppliers) y[i][j][k] - demand[j][k];
  
  // Crude oil property constraints
  forall(j in Refineries){
    sum(i in Suppliers) x[i][j] * api[i] >= sum(i in Suppliers, k in Products) y[i][j][k] * min_api[k];
    sum(i in Suppliers) x[i][j] * api[i] <= sum(i in Suppliers, k in Products) y[i][j][k] * max_api[k];
    sum(i in Suppliers) x[i][j] * sulphur[i] <= sum(i in Suppliers, k in Products) y[i][j][k] * max_sulphur[k];  
}
   
  // Production quantity constraints
  forall(i in Suppliers, j in Refineries)
    sum(k in Products) y[i][j][k] <= x[i][j];
  
  // Transportation constraints  
  forall(i in Suppliers, j in Refineries)
    sum(t in Tankers) z[i][j][t] == x[i][j];
   
  forall(i in Suppliers, j in Refineries, t in Tankers)  
    z[i][j][t] <= 1000000 * tanker_used[i][j][t];
      
  forall(t in Tankers)
    sum(i in Suppliers, j in Refineries) tanker_used[i][j][t] <= num_tankers[t];
}

execute {
  // Print optimal solution
  writeln("Objective value: ", cplex.getObjValue());

  writeln("\nCrude Oil Purchases and Shipping:");
  for (var i in Suppliers) {
    for (var j in Refineries) {
      if (x[i][j] > 0) {
        writeln("Purchase ", x[i][j], " barrels of ", i, " crude and ship to ", j, " refinery");
        for (var t in Tankers) {
          if (tanker_used[i][j][t] == 1) {
            writeln("  using ", tanker_used[i][j][t], " tanker(s) of type ", t);
          }
        }
      }
    }
}
}  
