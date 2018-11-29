# bigsqlmoni

Monitoring for BigSQL

https://www.ibm.com/support/knowledgecenter/en/SSCRJT_5.0.3/com.ibm.swg.im.bigsql.doc/doc/admin_monitor-bigsql-query.html

###Inspiration

BigSQL which is based on DB2, provides a variety of different metrics reflecting workload and performance of SQL Engine.  
But the single metric is only the number, and by itself does not provide any meaningful information unless one is familiar with DB2
internals. For instance: assuming the EXT_TABLE_RECV_WAIT_TIME brings 11630, what is means? It is good or bad?
Instead of pure numbers, much more valuable is observing the trends and provided that the metrics is growing or lowering, try to make 
some conclusion out of it.

##TODO

### General description
## Istallation
##TODO
## Data collection
##TODO
## Monitoring
##TODO

### Schema description

##TODO

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

##TODO

### Schema deployment

## Configuration

It is a good practice to install the solution in separate schema and use seperate user authorized only for monitoring task.

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
| VVIEW | The name of supporting view to extract data | VVIEW=MONIT.vmetrics
| MODULE | The name of module, container for stored procedures | MONIT.moni
| FROMAVG | THe beginning of reference averge period in YYYY-MM-DD format | "2018-08-07"
| TOAVG | The end of reference average period | "2018-08-09"
| LIMIT | |
| THRESH | |

# Schema creation

```bash
./installmon.sh dictable
./installmon.sh valtables
./installmon.sh views
./installmon.sh module
```
