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

Modify moni.rc file if necessary

| Variable | Description | Default value
| --------- |:---------------|:---------:|
