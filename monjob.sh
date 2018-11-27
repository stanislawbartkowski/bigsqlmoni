source /etc/profile
source $HOME/.bashrc
source `dirname $0`/moni.rc

#DB2HOME=/var/iophome/bigsql
#DB2HOME=/home/bigsql
DB=BIGSQL

#DB=TESTMONI
#DB2=$DB2HOME/sqllib/bin/db2
DB2=db2

date
$DB2 connect to $DB 
$DB2 "CALL $MODULE.GATHERMONITORING ('SELECT * FROM TABLE(MON_GET_WORKLOAD(''SYSDEFAULTUSERWORKLOAD'',-2))','WORKLOAD')"
$DB2 terminate
