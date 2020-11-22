CREATE DATABASE IF NOT EXISTS STR_ANLYTCS_STG_TBLS;
CREATE DATABASE IF NOT EXISTS STR_ANLYTCS_MART_TBLS;


CREATE external table if not exists STR_ANLYTCS_MART_TBLS.SHC_WIFI_ACCESS_PT_AVAIL_temp 
(
ACCESS_PT_ID VARCHAR(25) COMMENT 'Access Point Identifier' ,
ACCESS_PT_STAT_DT DATE COMMENT 'Access Point Status Date',
LOCN_NBR INT COMMENT 'Location Number' ,
ACCESS_PT_UNAVL_MINUT_QTY INT COMMENT 'Access Point Unavailable Minute Quantity' ,
ACCESS_PT_UNAVL_IND CHAR(1) COMMENT 'Access Point Unavailable Indicator' ,
DATASET_ID BIGINT ,
CREAT_TS TIMESTAMP ,
MOD_TS TIMESTAMP)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES('ACCESS_PT_ID.serialization.encoding'='ISO-8859-1','ACCESS_PT_UNAVL_IND.serialization.encoding'='ISO-8859-1',"field.delim"=",")
STORED AS TEXTFILE
location '/user/hshaik0/hive_avail_prod/avail_prod/';

CREATE table STR_ANLYTCS_MART_TBLS.SHC_WIFI_ACCESS_PT_AVAIL as SELECT *  FROM STR_ANLYTCS_MART_TBLS.SHC_WIFI_ACCESS_PT_AVAIL_temp WHERE ACCESS_PT_STAT_DT > date_add(CURRENT_DATE(),-400);

CREATE TABLE IF NOT EXISTS STR_ANLYTCS_STG_TBLS.DLY_ACCESS_PT_AVAIL
     (
      STAT_DT DATE COMMENT  'Status Date',
      STR_NBR VARCHAR(15) COMMENT 'Store Number' ,
      ACCESS_PT_NM VARCHAR(30) COMMENT 'Access Point Name',
      ACCESS_PT_UNAVL_IND CHAR(1) COMMENT 'Access Point Unavailable Indicator',
      ACCESS_PT_UNAVL_MINUT_QTY INT  COMMENT 'Access Point Unavailable Minute Quantity',
      OUTAGE_BEG_TM TIMESTAMP COMMENT 'Outage Start Time',
      OUTAGE_END_TM TIMESTAMP  COMMENT 'Outage End Time',
      CREAT_TS TIMESTAMP  )
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES('STR_NBR.serialization.encoding'='ISO-8859-1','ACCESS_PT_NM.serialization.encoding'='ISO-8859-1','ACCESS_PT_UNAVL_IND.serialization.encoding'='ISO-8859-1',"field.delim"="|")
STORED AS TEXTFILE
location '/user/hshaik0/availablity_summary/';

CREATE TABLE IF NOT EXISTS TMP_DLY_ACCESS_PT_AVAIL AS 
SELECT ACCESS_PT_NM,
 STAT_DT,
 STR_NBR,
 ACCESS_PT_UNAVL_IND,
 sum(ACCESS_PT_UNAVL_MINUT_QTY) ACCESS_PT_UNAVL_MINUT_QTY,
 max(CREAT_TS) CREAT_TS
 from
 STR_ANLYTCS_STG_TBLS.DLY_ACCESS_PT_AVAIL;

CREATE TABLE TMP_DLY_ACCESS_PT_AVAIL_TEMP AS SELECT ACCESS_PT_NM,STAT_DT,STR_NBR,ACCESS_PT_UNAVL_IND,sum(ACCESS_PT_UNAVL_MINUT_QTY) ACCESS_PT_UNAVL_MINUT_QTY, max(CREAT_TS) CREAT_TS,CAST(SUBSTR(STR_NBR,2) AS INT) AS NEW_STR_NBR FROM TMP_DLY_ACCESS_PT_AVAIL;

CREATE TABLE TMP_DLY_ACCESS_PT_AVAIL_TEMP_ORIGINAL AS SELECT ACCESS_PT_NM,STAT_DT,CONCAT(SUBSTR(STR_NBR,1,1),NEW_STR_NBR) AS STR_NBR,ACCESS_PT_UNAVL_IND,sum(ACCESS_PT_UNAVL_MINUT_QTY) ACCESS_PT_UNAVL_MINUT_QTY, max(CREAT_TS) CREAT_TS FROM TMP_DLY_ACCESS_PT_AVAIL_TEMP
group by
ACCESS_PT_NM ,
STAT_DT,
STR_NBR,
ACCESS_PT_UNAVL_IND;

CREATE DATABASE IF NOT EXISTS  ALEX_DW_VIEWS;

CREATE TABLE IF NOT EXISTS ALEX_DW_VIEWS.REF_SHC_LOC(
 SHC_LOCN_NBR           INT, 
 NATL_NBR               INT ,
 SLL_FMT                INT,
 VP_OVRHD_NBR           INT, 
 RGN_OVRHD_NBR          INT ,
 DM_OVRHD_NBR           INT,
 LOCN_NBR               INT,
 LOCN_LVL               SMALLINT, 
 FORMAT_TYPE            CHAR(3) ,
 FORMAT_SUB_TYPE        CHAR(2),
 STR_FMT                CHAR(3),
 ORIG_FACILITY_NBR      CHAR(7),
 ORIG_FACILITY_NBR_INT  INT,
 AMMC_OVRHD_NBR         INT,
 AMMC_MGR_NM            VARCHAR(20) ,
 RPT_STR_NBR            INT ,
 LOCN_CTY               VARCHAR(25),
 LOCN_ST_CD             CHAR(2),
 ZIP_CD                 CHAR(5), 
 ZIP_PLS_4              CHAR(4),
 OCN_OPN_DT             DATE,
 LOCN_CLS_DT            DATE  ,
 SHC_LOCN_DESC          VARCHAR(50),
 NATL_DESC              VARCHAR(50),
 SLL_FMT_DESC           VARCHAR(50),
 VP_RGN_NM              VARCHAR(50),
 RGN_MGR_NM             VARCHAR(50), 
 DM_MGR_NM              VARCHAR(50),
 LOCN_NM                VARCHAR(50) )
row format delimited
fields terminated by ','
location '/user/hshaik0/ref_shc_location/';


CREATE TABLE IF NOT EXISTS SHC_WIFI_ACCESS_PT_AVAIL_VOLT
AS SELECT STG.ACCESS_PT_NM ACCESS_PT_ID,
 STG.STAT_DT ACCESS_PT_STAT_DT,
 CASE WHEN LCN.LOCN_NBR IS NULL THEN -1 ELSE LCN.LOCN_NBR END LOCN_NBR,
 STG.ACCESS_PT_UNAVL_IND,
 STG.ACCESS_PT_UNAVL_MINUT_QTY ACCESS_PT_UNAVL_MINUT_QTY,
 CAST(CURRENT_DATE() AS INT) AS DATASET_ID,
 STG.CREAT_TS,
 CAST(NULL AS TIMESTAMP) MOD_TS
 FROM TMP_DLY_ACCESS_PT_AVAIL_TEMP_ORIGINAL STG LEFT OUTER JOIN ALEX_DW_VIEWS.REF_SHC_LOC LCN
 ON CAST(SUBSTR(STG.STR_NBR,2) AS INT) IS NOT NULL=LCN.LOCN_NBR;


CREATE TABLE IF NOT EXISTS A AS
 SELECT CAST(ACCESS_PT_ID  AS varchar(25)) ,
 ACCESS_PT_STAT_DT ,
 LOCN_NBR ,
 CAST(ACCESS_PT_UNAVL_MINUT_QTY AS INT) ,
 ACCESS_PT_UNAVL_IND  ,
 DATASET_ID ,
 CREAT_TS ,
 MOD_TS
 FROM SHC_WIFI_ACCESS_PT_AVAIL_VOLT;
 
CREATE TABLE IF NOT EXISTS SHI_TEMP(
 access_pt_id            varchar(25),
 access_pt_stat_dt       date,
 locn_nbr                int,
 access_pt_unavl_minut_qty       bigint,
 access_pt_unavl_ind     char(1),
 dataset_id              bigint,
 creat_ts                timestamp,
 mod_ts                  timestamp
  )
 ROW FORMAT DELIMITED;

INSERT OVERWRITE TABLE SHI_TEMP select TRGT.access_pt_id ,TRGT.access_pt_stat_dt,TRGT.locn_nbr ,a.access_pt_unavl_minut_qty ,a.access_pt_unavl_ind,TRGT.dataset_id ,TRGT.creat_ts ,TRGT.mod_ts FROM  STR_ANLYTCS_MART_TBLS.SHC_WIFI_ACCESS_PT_AVAIL TRGT,A a WHERE TRGT.ACCESS_PT_ID=a.ACCESS_PT_ID AND TRGT.LOCN_NBR=a.LOCN_NBR AND TRGT.ACCESS_PT_STAT_DT=a.ACCESS_PT_STAT_DT;

INSERT INTO TABLE SHI_TEMP select a.access_pt_id ,a.access_pt_stat_dt,a.locn_nbr ,a.access_pt_unavl_minut_qty ,a.access_pt_unavl_ind,a.dataset_id ,a.creat_ts ,a.mod_ts FROM  STR_ANLYTCS_MART_TBLS.SHC_WIFI_ACCESS_PT_AVAIL TRGT,A a WHERE TRGT.ACCESS_PT_ID!=a.ACCESS_PT_ID OR TRGT.LOCN_NBR!=a.LOCN_NBR OR TRGT.ACCESS_PT_STAT_DT!=a.ACCESS_PT_STAT_DT;









