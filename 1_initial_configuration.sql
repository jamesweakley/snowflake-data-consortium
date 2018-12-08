-- This script is designed to be run once only in each account, at first join of the consortium, as the role ACCOUNTADMIN.
-- It can be ran again, but it will have no effect

-- create a database to store the consortium's common definitions (not the table data though)
create database if not exists CONSORTIUM_SHARING;
create schema if not exists CONSORTIUM_SHARING.MOBILE;

grant usage on database CONSORTIUM_SHARING to role SYSADMIN;
grant usage on schema CONSORTIUM_SHARING.MOBILE to role SYSADMIN;

-- create the share and configure it
create share if not exists MOBILE_CONSORTIUM_SHARE;
grant usage on database CONSORTIUM_SHARING to share MOBILE_CONSORTIUM_SHARE;
grant usage on schema CONSORTIUM_SHARING.MOBILE to share MOBILE_CONSORTIUM_SHARE;

