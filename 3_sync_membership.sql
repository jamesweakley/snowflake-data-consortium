-- consortium membership changes (new or departing member)

-- populate a list of consortium members and their snowflake accounts
create or replace table CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS (SNOWFLAKE_ID,COMPANY_NAME) as 
select * from ( values
('II42339', 'Silver Mobile'), 
('JTEST2', 'Houndphone'), 
('JTEST3', 'Venus Networks')
);

-- Not sure how to update the share membership, either using the above table or with fixed statements
alter share MOBILE_CONSORTIUM_SHARE add ACCOUNTS = ?
