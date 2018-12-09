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
-- if this account is a viewer, map each inbound share to a database
-- returns a string that includes a log of what happened
create or replace procedure CONSORTIUM_SHARING.MOBILE.UPDATE_MEMBERSHIP()
  returns string
  language javascript
  as
  $$
  var returnString="";
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
    returnString=returnString+"This account is a contributor\n"
    results = snowflake.execute({
      sqlText: "select listagg(SNOWFLAKE_ID,',') FROM CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS WHERE SNOWFLAKE_ID!=current_account() and VIEWER=true;"
    });
    results.next();
    var other_viewers=results.getColumnValue(1);
    returnString=returnString+"Updating outbound share to include the following accounts: "+other_viewers+"\n"
    snowflake.execute({
      sqlText: "alter share MOBILE_CONSORTIUM_SHARE set accounts="+other_viewers
    });
  }
  if (am_i_a_viewer){
    returnString=returnString+"This account is a viewer\n"
    // TODO: for each contributor other than this account:
    // create a view that unions the inbound table from all other contributors, plus this account's table too if we're a contributor
    
    var inbound_view_statements=[]
    inbound_view_statements.push("select * from \"CONSORTIUM_SHARING\".\"MOBILE\".\"CUSTOMER_OUTBOUND_VIEW\"")
    
    var other_contributors = snowflake.execute({
      sqlText: "select SNOWFLAKE_ID FROM CONSORTIUM_SHARING.MOBILE.CONSORTIUM_MEMBERS WHERE SNOWFLAKE_ID!=current_account() and CONTRIBUTOR=true;"
    });
    while (other_contributors.next()){
      var snowflake_account = other_contributors.getColumnValue(1);
      try {
        snowflake.execute({
          sqlText: "create database if not exists \"CONSORTIUM_SHARING.INBOUND."+snowflake_account+"\" from share "+snowflake_account+".MOBILE_CONSORTIUM_SHARE;"
        });
        returnString=returnString+"Share from contributor "+snowflake_account+" is mapped to database \"CONSORTIUM_SHARING.INBOUND."+snowflake_account+"\"\n";
        // add the view from this contributor to the collective view we'll create below
        inbound_view_statements.push("select * from \"CONSORTIUM_SHARING.INBOUND."+snowflake_account+"\".\"MOBILE\".\"CUSTOMER_OUTBOUND_VIEW\"")
      }
      catch(err) {
         returnString=returnString+"Unable to map database for contributor "+snowflake_account+": "+err.message+"\n";
      }
    }
    var create_view_statement = "create or replace view CONSORTIUM_SHARING.MOBILE.CUSTOMER_COMBINED as("+inbound_view_statements.join(' union ')+")"
    returnString=returnString+"Create combined view with definition:"+create_view_statement+"\n";
    snowflake.execute({
      sqlText: create_view_statement
    });
  }
  return returnString;
  $$
  ;
USE DATABASE CONSORTIUM_SHARING;
USE SCHEMA MOBILE;

call UPDATE_MEMBERSHIP()

-- should display all accounts in the consortium, with customer counts next to them (between 50k and 150k records each)
select SNOWFLAKE_ID,count(*) from CONSORTIUM_SHARING.MOBILE.CUSTOMER_COMBINED
GROUP BY SNOWFLAKE_ID
