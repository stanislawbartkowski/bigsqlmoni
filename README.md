# bigsqlmoni

Monitoring for BigSQL

https://www.ibm.com/support/knowledgecenter/en/SSCRJT_5.0.3/com.ibm.swg.im.bigsql.doc/doc/admin_monitor-bigsql-query.html

# Inspiration

BigSQL which is based on DB2 provides a variety of different metrics reflecting workload and performance of SQL Engine.  
But the single metric is only the number, and by itself does not provide any meaningful information unless one is familiar with DB2 internals. For instance: assuming the EXT_TABLE_RECV_WAIT_TIME brings 11630, what it means? It is good or bad?
Metrics are cumulative, so instead of pure values much more informative is trend how the metrics are growing. One can assume that when the metric is growing rapidly it means heavy workload underway.

# Solution description

## General 

The solution allows harvesting current metrics values and keeps all historical values. It also pivots the data, one row of metrics transforms into a series of records: metric id / metric value. There is a view defined which transform absolute values into a difference between two consecutive measures. 
The solution contains the following elements:
* Simple database schema, three tables and two views.
* Schema deployment, the tables name including the schema name are configurable
* DB2 SQL module containing stored procedures to collect data and extract data
* Two ways of data collecting, as Linux crontab job or DB2 scheduled task
* A simple example of data analysis to predict oncoming heavy workload. This topic requires further tunning.

## Database schema description
![alt text](images/Zrzut%20ekranu%20z%202018-12-02%2023-21-22.png)

| File        | Description
| ------------- |:-------------:|
| ttable | Metric values header |
| mtable | List of detailed metrics values connected to single ttable record through foreign key |
| dictable | Static table, description for measure id, only measures present in dictable are collected |
| vmetrics | View containing the difference between two consecutive values for a metric |
| vsummetrics | View containing a sum of metric values across members |


## File description

| File        | Description
| ------------- |:-------------:|
| createdicttable.sql | Template to create dictionary table, metrics description |
| createmoni.sql | Template to create moni module containing stored procedures |
| createmonitables.sql | Template to create header and detail tables |
| createview.sql | Template to create supporting views |
| crontab | Sample crontab file |
| dict.txt | Description for metrics |
| extract.sh | Bash script file to extract data in CSV format |
| info.txt | Useful informations |
| installmon.sh | Bash script file to install table and view schema |
| moni.rc | Configuration file |
| monistand.sql | Template query to select data |
| monjob.sh | Bash script file to collect next bunch of statistics 
| proc.rc | Common shared bash functions
| report.sh | Bash script file for monitoring

# Schema deployment

## Configuration

It is a good practice to install the solution in a separate schema and use separate user authorized only for monitoring task.

Modify moni.rc file if necessary

| Variable | Description | Default value
| --------- |:---------------|:---------:|
| BIGSQLDB | Database name | bigsql |
| BUGUSER  | Database user, can be commented out if local connection | Commented out
| BIGPASSWD | Database password , can be commented out if local connection | Commented out
| DICTTEXT | File used to feed dictatble table ! dict.txt
| DICTABLE | The name of dicttable, can contain schema | MONIT.dictable
| TTABLE | The name of header table | MONIT.ttable
| VTABLE | The name of metrics detail table | MONIT.mtable
| VVIEW | The name of supporting view containing the difference between consecutive metric values | VVIEW=MONIT.vmetrics
| MODULE | The name of a module, container for stored procedures | MONIT.moni
| FROMAVG | THe beginning of reference average period in YYYY-MM-DD format | "2018-08-07"
| TOAVG | The end of reference average period | "2018-08-09"
| LIMIT | |
| THRESH | |

## Schema creation

```bash
./installmon.sh dictable
./installmon.sh valtables
./installmon.sh views
./installmon.sh module
```
Important: ./installmon.sh valtables removes tables if exist. Should be used with caution, otherwise, all monitoring data collected so far maybe wiped out.

# Collecting data

## Prepare monitoring query

There is a number of monitoring views available. More details: https://www.ibm.com/support/knowledgecenter/en/SSCRJT_5.0.1/com.ibm.swg.im.bigsql.admin.doc/doc/admin_monitor-bigsql-query.html

The tool is able to analyze dynamically any query and feed metrics table. The general rules are:
* Only BIGINT column types are collected.
* The column name should be enlisted in DICTABLE/dict.txt
* If MEMBER column is discovered, it is copied to the MEMBER column in the metrics table
* All other columns are ignored.
* Values equal to zero are ignored.

Example:
```sql
SELECT * FROM TABLE(MON_GET_WORKLOAD('SYSDEFAULTUSERWORKLOAD',-2))
```
All columns reported and found in DICTABLE are collected. It is the most general monitoring query.
```sql
SELECT MEMBER, ROWS_READ, EXT_TABLE_RECV_WAIT_TIME FROM TABLE(MON_GET_DATABASE( -2)) order by MEMBER
```
Only ROWS_READ and EXT_TABLE_RECV_WAIT_TIME metrics are collected.

## GATHERMONITORING stored procedure

The GATHERMONITORING procedure takes two parameters.
* The first is the monitoring query to be executed
* The second is the monitoring identifier/type. The identifier is significant if more then one monitoring query is applied. It allows differentiating metrics coming from different queries. The identifier is assigned to 'typ' column in 'ttable' table.

The procedure executes the query and analyzes the result set as described above. For every execution, a single 'ttable' record is created and a list of the corresponding record in 'mtable' table.

## Collecting monitoring data as crontab job.

Data can be collected using Linux crontab job. Firstly a wrapping bash script file should be created. Example (monjob.sh)
```bash
source /etc/profile
source $HOME/.bashrc
source `dirname $0`/moni.rc

DB=BIGSQL
DB2=db2

date
$DB2 connect to $DB 
$DB2 "CALL $MODULE.GATHERMONITORING ('SELECT * FROM TABLE(MON_GET_WORKLOAD(''SYSDEFAULTUSERWORKLOAD'',-2))','WORKLOAD')"
$DB2 terminate
```
The script should fulfil requirements for crontab job. The monitoring query looks like:
```sql
SELECT * FROM TABLE(MON_GET_WORKLOAD(''SYSDEFAULTUSERWORKLOAD'',-2))
```
and metrics identifier 'WORKLOAD'. The identifier matters only if there is more then one monitoring query.

Next step is to prepare a valid 'crontab' file. Example:
```
* * * * * /home/sb/bigmoni/monjob.sh >>/tmp/bigmoni/moni.out 2>&1
```
Very important: The crontab schedule defines to time interval the monitoring data is collected. In this example, to crontab job is executed every minute, so the data collected reflects one-minute interval. One can specify a different schedule if different data precision is required.

## Collecting monitoring data as DB2 task 

Another method is to use DB2 task scheduler.

https://www.ibm.com/support/knowledgecenter/ro/SSEPGG_11.1.0/com.ibm.db2.luw.admin.gui.doc/doc/c0054380.html

Firstly it necessary to create a wrapping stored procedure. Passing parameters to a procedure used as a task is possible but complicated.

```sql
CREATE OR REPLACE PROCEDURE MONIT.RUNJOB ()
P1: BEGIN  
  CALL MONIT.MONI.GATHERMONITORING ('SELECT * FROM TABLE(MON_GET_WORKLOAD(''SYSDEFAULTUSERWORKLOAD'',-2))','WORKLOAD');
END P1
@
```
The SP can be deployed using command:
```bash
db2 -td@ -vf spmon.db2
```
Next step is to start the task.

```bash
CALL SYSPROC.ADMIN_TASK_ADD('Collecting metrics every minute', NULL,  NULL, NULL,'*  * * * *','MONIT', 'RUNJOB',NULL,NULL,NULL);
```
The task will be activated after several minutes.
The execution can be monitored by a query:
```bash
db2 "SELECT * from SYSTOOLS.ADMIN_TASK_STATUS"
```
Like crontab, the task schedule defines the time interval. Here the data is collected every one minute.

# Metrics extraction

## EMITTEXT, extract data as CSV file

Data can be extracted using EMITTEXT stored procedure. The output can be used for off-line analysis. The output file is stored on the host where BigSQL Head is installed.

EMITTEXT stored procedure takes three parameters:
* Investigative query to extract data
* Directory where output file is saved.  
* Output file name

An example of data extraction (extract.sh bash script)
```bash
source `dirname $0`/proc.rc
EXPORTDIR=/tmp/export

#set -x
#w

export() {
  mkdir -p $EXPORTDIR
  # very important for non bigsql user
  # give bigsql, instance owner, write access to this directory
  chmod 777 $EXPORTDIR
  db2connect
  db2 "CALL UTL_DIR.CREATE_OR_REPLACE_DIRECTORY('expdir','$EXPORTDIR')"
  [ $? -eq 0 ] || logfail "Cannot CREATE_OR_REPLACE_DIRECTORY"
  db2 "CALL $MODULE.EMITTEXT('select num,times,0 as member,id,sum(val) as val from $VVIEW group by times,num,id order by num','expdir','num.txt')"
  [ $? -eq 0 ] || logfail "CALL EMITTEXT failed"
  db2close
}

export
```
The investigative query can be modified according to needs. The output file is stored in /tmp/export/num.txt file.

## Extract data directly
For online analysis supporting monit.vmetrics view can be queried directly. The view returns a difference between two consecutive metric values.

For instance, assuming that metrics go:

| NUM | Metric | Value
| --------- |:---------------|:---------:|
| 123 | ROWS_READ | 133268  |
| 124 | ROWS_READ | 227095  |
| 125 | ROWS_READ | 321590  |
| 126 | ROWS_READ | 359820  |
| 127 | ROWS_READ | 493445 |
| 128 | ROWS_READ | 531738 |
| 129 | ROWS_READ | 532131 |
| 130 | ROWS_READ | 551722 |

The corresponding entries in monit.vmetrics will look like:

| NUM | Metric | Value
| --------- |:---------------|:---------:|
| 121 | ROWS_READ | 37781  |
| 122 | ROWS_READ | 93827  |
| 123 | ROWS_READ | 94495  |
| 124 | ROWS_READ | 38230  |
| 125 | ROWS_READ | 133625 |
| 126 | ROWS_READ | 38293 |
| 127 | ROWS_READ | 393 |
| 128 | ROWS_READ | 19591 |

# Metrics analysis
It does not make any sense to gather statistics for the purpose of gathering only. This topic requires further analysis. So far I developed a simple solution to discover heavy workload oncoming.
* Collect metrics for an average workload
* Collect metrics for heavy workload and note which metrics are changing significantly. The following metrics are good candidates: ROWS_READ, FCM_MESSAGE_RECV_WAIT_TIME, FCM_TQ_SEND_VOLUME, FCM_TQ_SEND_WAITS_TOTAL, EXT_TABLE_RECV_VOLUME, EXT_TABLE_RECV_WAIT_TIME,FCM_TQ_RECVS_TOTAL,FCM_TQ_RECV_WAITS_TOTAL.
* Compare the average for a normal workload with the average for a heavy workload.
* If the average for current workload exceeds significantly the normal average then raise the alarm.

The solution is implemented in instalmon.sh script file:
```bash
runforid() {
  local id=$1
  runquery "SELECT AVG(VAL) FROM $VSUMVIEW WHERE ID='$id' AND TIMES>'$FROMAVG' AND TIMES<'$TOAVG'"
  local AVG=$RES
  runquery "SELECT AVG(VAL) FROM (SELECT VAL,NUM FROM $VSUMVIEW WHERE ID='$id' ORDER BY NUM DESC LIMIT $LIMIT)"
  local CURR=$RES
  log "$id AVG=$AVG CURR=$CURR"
  if expr $CURR \> $AVG \* $TRESH; then
    local da=`date`
    alert "$da $id AVG=$AVG CURRENT=$CURR"
  fi
}

runmonitor() {
#  runforid ROWS_READ
  while read -r id; do
    runforid $id
  done <`dirname $0`/listmon.txt
}


```
The parameters are defined in 'moni.rc' file

| Variable | Description | Default value
| --------- |:---------------|:---------:|
| FROMAVG | Beginning of reference normal workload | "2018-08-07" |
| TOAVG | The end of reference normal workload | "2018-08-11" |
| LIMIT | Number of metrics backwards to calculate current average | 5 |
| TRESH | Threshold multipliers to raise the alert | 3, meaning that current average should exceed normal 3 times |

Monitoring can be enabled as another crontab job.
```bash
source /etc/profile
source $HOME/.bashrc
`dirname $0`/installmon.sh monitor
```
Corresponding crontab line
```
* * * * * /var/iophome/bigsql/eh2bahw/moni/report.sh >>/tmp/moni/report.out 2>&1
```
The job checks the current average every one minute and raises the alarm if the average exceeds the threshold. The alert is written to listmon.txt file.
But this solution is lame and during testing did not provide satisfactory results, requires further investigation and tunning.
