-- consortium membership changes (new or departing member)

-- populate a list of consortium members and their snowflake accounts
create or replace table CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS (SNOWFLAKE_ID varchar(8),COMPANY_NAME varchar(100),CONTRIBUTOR boolean, VIEWER boolean) as 
select * from (values
('II42339', 'Silver Mobile',true,true), 
('LY01550', 'Network fuse',true,true), 
('JTEST2', 'Houndphone',true,true), 
('JTEST3', 'Venus Networks',true,true)
);

-- if this account is a contributor, update the outbound share to include all viewers

-- returns true when finished
create or replace procedure CONSORTIUM_SHARING.MOBILE.UPDATE_MEMBERSHIP()
  returns boolean
  language javascript
  as
  $$
  var results = snowflake.execute({
    sqlText: "select count(*) from CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS where SNOWFLAKE_ID=current_account() and CONTRIBUTOR=true;"
  });
  results.next();
  var am_i_a_contributor=results.getColumnValue(1) > 0
  
  results = snowflake.execute({
    sqlText: "select count(*) from CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS where SNOWFLAKE_ID=current_account() and VIEWER=true;"
  });
  results.next();
  var am_i_a_viewer=results.getColumnValue(1) > 0
  
  if (am_i_a_contributor){
    results = snowflake.execute({
      sqlText: "select listagg(SNOWFLAKE_ID,',') FROM CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS WHERE SNOWFLAKE_ID!=current_account() and VIEWER=true;"
    });
    results.next();
    var other_viewers=results.getColumnValue(1);
    snowflake.execute({
      sqlText: "alter share MOBILE_CONSORTIUM_SHARE set accounts="+other_viewers
    });
  }
  if (am_i_a_viewer){
    // TODO: for each contributor other than this account:
    // create database if not exists "CONSORTIUM_SHARING.INBOUND.(account)" from share (account).MOBILE_CONSORTIUM_SHARE;
    // create a view that unions the inbound table from all other contributors, plus this account's table too if we're a contributor
  }
  
  return true;
  $$
  ;
USE DATABASE CONSORTIUM_SHARING;
USE SCHEMA MOBILE;

call UPDATE_MEMBERSHIP()
