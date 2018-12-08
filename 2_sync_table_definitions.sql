-- This script is designed to be re-ran whenever a new table is to be shared

-- create table based on a common definition.
-- Normally this will just be a proper table definion, but we are using CTAS from sample data for this POC
-- select a random sample between 50,000 and 150,000 rows from the customer sample table, so that the combined results look interesting
set sample_size=(select 50000+(ABS(RANDOM()) % 100000));
create table if not exists CONSORTIUM_SHARING.MOBILE.CUSTOMER as (select * from SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER sample ($sample_size rows));
grant ownership on table CONSORTIUM_SHARING.MOBILE.CUSTOMER to role SYSADMIN;

-- create a secure view for this table in order to share it outbound.
create secure view if not exists CONSORTIUM_SHARING.MOBILE.CUSTOMER_OUTBOUND_VIEW as
(select current_account() as SNOWFLAKE_ID,* from CONSORTIUM_SHARING.MOBILE.CUSTOMER);

-- add the view to the share
grant select on view CONSORTIUM_SHARING.MOBILE.CUSTOMER_OUTBOUND_VIEW to share MOBILE_CONSORTIUM_SHARE;
