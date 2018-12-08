-- consortium membership changes (new or departing member)

-- populate a list of consortium members and their snowflake accounts
create or replace table CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS (SNOWFLAKE_ID,COMPANY_NAME) as 
select * from ( values
('II42339', 'Silver Mobile'), 
('LY01550', 'Network fuse'), 
('JTEST2', 'Houndphone'), 
('JTEST3', 'Venus Networks')
);

-- Need to be able to run the statement for all account except for this one
alter share MOBILE_CONSORTIUM_SHARE add accounts=II42339;
alter share MOBILE_CONSORTIUM_SHARE add accounts=LY01550;
alter share MOBILE_CONSORTIUM_SHARE add accounts=JTEST2;
alter share MOBILE_CONSORTIUM_SHARE add accounts=JTEST3;

-- Need to be able to run the statement for all account except for this one
create or replace database "CONSORTIUM_SHARING.INBOUND.JTEST2" from share JTEST2.MOBILE_CONSORTIUM_SHARE;
create or replace database "CONSORTIUM_SHARING.INBOUND.JTEST3" from share JTEST3.MOBILE_CONSORTIUM_SHARE;
create or replace database "CONSORTIUM_SHARING.INBOUND.II42339" from share II42339.MOBILE_CONSORTIUM_SHARE;
create or replace database "CONSORTIUM_SHARING.INBOUND.LY01550" from share LY01550.MOBILE_CONSORTIUM_SHARE;

-- this view will look different for each account, as its own data comes from the local table and the rest from the inbound shares
-- another candidate for generating via stored proc
create or replace view CONSORTIUM_SHARING.MOBILE.CUSTOMER_COMBINED as(
select * from "CONSORTIUM_SHARING"."MOBILE"."CUSTOMER_OUTBOUND_VIEW"
union
select * from "CONSORTIUM_SHARING.INBOUND.JTEST2"."MOBILE"."CUSTOMER_OUTBOUND_VIEW"
union
select * from "CONSORTIUM_SHARING.INBOUND.JTEST3"."MOBILE"."CUSTOMER_OUTBOUND_VIEW"
union
select * from "CONSORTIUM_SHARING.INBOUND.LY01550"."MOBILE"."CUSTOMER_OUTBOUND_VIEW"
)

-- should display all accounts in the consortium, with customer counts next to them (between 50k and 150k records each)
select SNOWFLAKE_ID,count(*) from CONSORTIUM_SHARING.MOBILE.CUSTOMER_COMBINED
GROUP BY SNOWFLAKE_ID
