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
#db2 "CALL MON.MONI.EMITTEXT('SELECT * FROM MON.VMETRICS ORDER BY NUM,MEMBER LIMIT 90000','expdir','num.txt')"
#db2 "CALL MON.MONI.EMITTEXT('SELECT * FROM MON.VMETRICS WHERE MEMBER=0 ORDER BY NUM,MEMBER','expdir','num.txt')"
#db2 "CALL $MODULE.EMITTEXT('SELECT * FROM $VVIEW WHERE MEMBER=0 AND TIMES < ''2018-07-29'' ORDER BY NUM,MEMBER','expdir','num.txt')"
#db2 "CALL $MODULE.EMITTEXT('SELECT * FROM $VVIEW ORDER BY NUM,MEMBER','expdir','num.txt')"
  db2 "CALL $MODULE.EMITTEXT('select num,times,0 as member,id,sum(val) as val from $VVIEW group by times,num,id order by num','expdir','num.txt')"
  [ $? -eq 0 ] || logfail "CALL EMITTEXT failed"
  db2close
}

export
