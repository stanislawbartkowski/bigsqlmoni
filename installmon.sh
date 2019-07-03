source `dirname $0`/proc.rc

#set -x
#w

dropobject() {
  local -r what=$1
  local -r oname=$2
  log "Drop $what $oname"
  db2 -tv "DROP $what $oname" >>$LOGFILE
  # do not verify the exit
}

droptable() {
  dropobject table $1
}

runcreatescript() {
  local scripttable=$1
  local tablename=$2
  local tablename1=$3
  local tablename2=$4
  local viewname=$5
  local viewsum=$6
  log "Run $scripttable, table name $2"
  cat $scripttable | sed s/XXtablenameXX/$tablename/g | sed s/XXtablename1XX/$tablename1/g | sed s/XXtablename2XX/$tablename2/g | sed s/XXviewnameXX/$viewname/g | sed s/XXviewsumXX/$viewsum/g | db2 -tv >>$LOGFILE
  [ $? -eq 0 ] || logfail "Cannot create"
  log "Created"
}

# db2 grant dataaccess on database to user sb

importdictable() {
  # copy DICT to /tmp to be accessible by bigsql engine
  local tdict=/tmp/$DICTTXT
  cp $DICTTXT $tdict
  db2connect
  droptable $DICTABLE
  runcreatescript createdicttable.sql $DICTABLE
  log "Load data from $tdict into $DICTABLE "
  db2 -tv "load client from $tdict of del modified by coldel| insert into $DICTABLE" >>$LOGFILE
  [ $? -eq 0 ] || logfail "Cannot load data"
  db2close
  rm $tdict
}

createvaltables() {
  db2connect
  droptable $VTABLE
  droptable $TTABLE
  runcreatescript createmonitables.sql $TTABLE $VTABLE $DICTABLE
  [ $? -eq 0 ] || logfail "Cannot create data"
  db2close
}

createmodule() {
  db2connect
  log "Create module $MODULE"
  cat createmoni.sql | sed s/XXmoduleXX/$MODULE/g | sed s/XXdictableXX/$DICTABLE/g | sed s/XXtablenameXX/$TTABLE/g | sed s/XXtablename1XX/$VTABLE/g | db2 -td@ -v >>$LOGFILE
  local -r RES=$?
  if [ $RES -eq 2 ]; then
    echo "Warning is reported. The module is created but verify the log gile $LOGFILE"
  else
    [ $RES -eq 0 ] || logfail "Cannot create module"
  fi
  db2close
}

dropall() {
  log "Drop module"
  db2connect
  dropobject module $MODULE
  log "Drop tables"
  droptable $VTABLE
  droptable $TTABLE
  droptable $DICTABLE
  log "Drop views"
  dropobject view $VVIEW
  dropobject view $VSUMVIEW
  log "drop monit.runjob"
  dropobject procedure monit.runjob
  db2close
}

drawhelp() {
  echo "installmon /par/"
  echo "par : dictable"
  echo "      valtables"
  echo "      views"
  echo "      module"
  echo "      monitor"
  echo "      dropall"
}

createviews() {
  db2connect
  runcreatescript createview.sql $TTABLE $VTABLE $DICTABLE $VVIEW $VSUMVIEW
  [ $? -eq 0 ] || logfail "Cannot create data"
  db2close
}

runquery() {
  local query="$1"
  db2connect
  log "$1"
  local TEMPFILE=`mktemp`
  db2 -txz $LOGFILE $query >$TEMPFILE
  RES=`cat $TEMPFILE | sed s/[\ ,\.]//g`
  db2close
}

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



mkdir -p $LOGDIR

case $1 in
  "dictable") importdictable;;
  "valtables") createvaltables;;
  "views") createviews;;
  "module") createmodule;;
  "monitor") runmonitor;;
  "dropall") dropall;;
  *) drawhelp; exit 4;;
esac
