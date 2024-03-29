use snowflake;

//=============================================================================
// Account-level resource monitor
//=============================================================================
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR 
  MONTHLY_ACCOUNT_BUDGET 
WITH 
  CREDIT_QUOTA    = 300
  FREQUENCY       = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
TRIGGERS
  ON 50 PERCENT DO NOTIFY
  ON 75 PERCENT DO NOTIFY
  ON 90 PERCENT DO NOTIFY
  ON 95 PERCENT DO SUSPEND
  ON 99 PERCENT DO SUSPEND_IMMEDIATE;

ALTER ACCOUNT SET RESOURCE_MONITOR = MONTHLY_ACCOUNT_BUDGET;
//=============================================================================


//=============================================================================
// Warehouse-level resource monitor
//=============================================================================
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR 
  MONTHLY_DEMO_WH_BUDGET 
WITH 
  CREDIT_QUOTA    = 30
  FREQUENCY       = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
TRIGGERS 
  ON 80 PERCENT DO NOTIFY
  ON 95 PERCENT DO SUSPEND
  ON 99 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE COMPUTE_WH SET RESOURCE_MONITOR = MONTHLY_DEMO_WH_BUDGET;
//=============================================================================