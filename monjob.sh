source /etc/profile
source $HOME/.bashrc
source `dirname $0`/moni.rc

DB=BIGSQL
DB2=db2

date
$DB2 connect to $DB
$DB2 "CALL $MODULE.GATHERMONITORING ('SELECT * FROM TABLE(MON_GET_WORKLOAD(''SYSDEFAULTUSERWORKLOAD'',-2))','WORKLOAD')"
$DB2 terminate
