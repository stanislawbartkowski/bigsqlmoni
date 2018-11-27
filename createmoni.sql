CREATE OR REPLACE MODULE XXmoduleXX@

ALTER MODULE XXmoduleXX PUBLISH
  TYPE moniheaderTYPE AS VARCHAR(2000) ARRAY[VARCHAR(100)]@

ALTER MODULE XXmoduleXX PUBLISH
  TYPE monivalueTYPE AS BIGINT ARRAY[VARCHAR(100)]@

ALTER MODULE XXmoduleXX PUBLISH
PROCEDURE P(IN LINE VARCHAR(10000))
P1: BEGIN
  CALL DBMS_OUTPUT.PUT_LINE(LINE);
  CALL DBMS_OUTPUT.NEW_LINE();
END P1
@

ALTER MODULE XXmoduleXX PUBLISH
PROCEDURE GATHERMONITORING (
  IN STMT VARCHAR(20000),
  IN ID VARCHAR(20)
)
P1: BEGIN

  DECLARE curid INTEGER; -- DBMS_SQL cursor id
  DECLARE col DBMS_SQL.DESC_TAB; -- DBMS_SQL statement descriptos
  DECLARE col_cnt INTEGER; -- number of columns
  DECLARE i INTEGER DEFAULT 1;
  DECLARE v_status INTEGER;
  DECLARE n VARCHAR(1000);
  DECLARE v VARCHAR(1000);
  DECLARE LASTID INTEGER; -- ID. autoincremental from TTABLE
--  DECLARE VAL BIGINT; -- value (BIGINT)
  DECLARE VALD DECFLOAT; -- value (BIGINT)
  DECLARE CNAME VARCHAR(100); -- column name

  DECLARE EX BOOLEAN; -- column of interest, exists in DICTTABLE

  DECLARE MEMBERI INTEGER DEFAULT -1; -- MEMBER column (if exists)
  DECLARE MEMBER INTEGER DEFAULT -1; -- MEMBER value (if not -1)

  -- statement to verify if cname in DICTTABLE, column of interest
  DECLARE te VARCHAR(1000);
  DECLARE CUR CURSOR FOR stmt;
  SET te = 'select exists( select 1 from XXdictableXX where id = ? ) from sysibm.sysdummy1';
  PREPARE stmt FROM te;

  -- open and analyze the statement
  CALL DBMS_SQL.OPEN_CURSOR(curid);
  CALL DBMS_SQL.PARSE(curid,STMT,DBMS_SQL.native);
  CALL DBMS_SQL.DESCRIBE_COLUMNS(curid,col_cnt,col);
  -- col_cnt : number of columns, col, column descriptor


  -- generate header, row in XXtablenameXX, current time
  INSERT INTO XXtablenameXX VALUES(DEFAULT,CURRENT_TIMESTAMP,ID);
  -- take autoincremented number, primary key
  select IDENTITY_VAL_LOCAL() INTO LASTID from sysibm.sysdummy1;

  -- loop across columns
  -- identify MEMBER and assign value
  SET i = 1;
  colloop: LOOP
    IF i > col_cnt THEN LEAVE colloop; END IF;
    IF col[i].col_name = 'MEMBER' THEN
        SET MEMBERI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_INT(curid,i,MEMBER);
    END IF;
    -- 492, BIGINT, only these columns are analyzed
--    IF col[i].col_type = 492 THEN  CALL DBMS_SQL.DEFINE_COLUMN_INT(curid,i,VAL); END IF;
    IF col[i].col_type = 492 THEN  CALL DBMS_SQL.DEFINE_COLUMN_NUMBER(curid,i,VALD); END IF;
    SET i = i + 1;
  END LOOP;

  -- execute the statement
  CALL DBMS_SQL.EXECUTE(curid,v_status);

  -- loop, fetch the result
  fetchloop: LOOP
    CALL DBMS_SQL.FETCH_ROWS(curid,v_status);
    if v_status = 0 THEN LEAVE fetchloop; END IF;
    -- take member value if exeists
     IF MEMBERI <> -1 THEN
       CALL DBMS_SQL.COLUMN_VALUE_INT(curid,MEMBERI,MEMBER);
     END IF;

     -- loop across all columns
     SET i = 1;
     colloop1: LOOP

       IF i > col_cnt THEN LEAVE colloop1; END IF;
       SET CNAME= col[i].col_name;
       IF CNAME = 'MEMBER' THEN   CALL DBMS_SQL.COLUMN_VALUE_INT(curid,i,MEMBER); END IF;
       IF col[i].col_type = 492 THEN
          -- check if column exists in DICTTABLE
          OPEN CUR USING CNAME;
          FETCH CUR INTO EX ;
          CLOSE CUR;
          if EX = 1 THEN
--            CALL DBMS_SQL.COLUMN_VALUE_INT(curid,i,VAL);
            CALL DBMS_SQL.COLUMN_VALUE_NUMBER(curid,i,vald);
            -- only non zero values
            IF vald <> 0 THEN
              INSERT INTO XXtablename1XX VALUES(LASTID,CNAME,VALD,MEMBER);
            END IF;
           END IF;
       END IF;
       SET i = i + 1;

      END LOOP;


  END LOOP;

  CALL DBMS_SQL.CLOSE_CURSOR(curid);
END P1
@

-- NUM INTEGER
-- TIMES TIMESTAMP
-- ID VARCHAR(100)
-- DESC VARCHAR(2000)
-- VAL BIGINT
ALTER MODULE XXmoduleXX PUBLISH
PROCEDURE EMITTEXT (
  IN que VARCHAR(2000),
  IN v_dirAlias VARCHAR(50),
  IN v_fileName VARCHAR(50))
P1: BEGIN
   DECLARE v_exp_file UTL_FILE.FILE_TYPE;
   DECLARE header moniheaderTYPE;
   DECLARE vals monivalueTYPE;

   DECLARE curid INTEGER; -- DBMS_SQL cursor id
   DECLARE col DBMS_SQL.DESC_TAB; -- DBMS_SQL statement descriptos
   DECLARE col_cnt INTEGER; -- number of columns
   DECLARE i INTEGER DEFAULT 1;
   DECLARE v_status INTEGER;
   DECLARE eof INTEGER;
   DECLARE WRITEHEADER INTEGER;


   DECLARE numI INTEGER DEFAULT -1;
   DECLARE timesI INTEGER DEFAULT -1;
   DECLARE idI INTEGER DEFAULT -1;
   DECLARE descI INTEGER DEFAULT -1;
   DECLARE valI INTEGER DEFAULT -1;
   DECLARE memberI INTEGER DEFAULT -1;


   DECLARE num INTEGER;
   DECLARE times TIMESTAMP;
   DECLARE id VARCHAR(100);
   DECLARE desc VARCHAR(2000);
   -- DECLARE val BIGINT;
   DECLARE vald DECFLOAT;
   DECLARE valb BIGINT;
   DECLARE member INTEGER DEFAULT 0;

   DECLARE lastnum INTEGER;
   DECLARE lastmember INTEGER;

   DECLARE CUR CURSOR FOR SELECT T.ID,T.DESC FROM UNNEST(header) AS T(ID,DESC);
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET EOF = 1;

   -- output file
   SET v_exp_file = UTL_FILE.FOPEN(v_dirAlias,v_fileName,'w',30000);

   -- identify column numbers for fields of interest
   CALL DBMS_SQL.OPEN_CURSOR(curid);
   CALL DBMS_SQL.PARSE(curid,que,DBMS_SQL.native);
   CALL DBMS_SQL.DESCRIBE_COLUMNS(curid,col_cnt,col);

   SET i = 1;
  loopcol: LOOP
     IF i > col_cnt THEN LEAVE loopcol; END IF;
     IF col[i].col_name = 'NUM' THEN
        SET numI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_INT(curid,i,num);
     END IF;
     IF col[i].col_name = 'TIMES' THEN
        SET timesI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_TIMESTAMP(curid,i,times);
     END IF;
     IF col[i].col_name = 'ID' THEN
        SET idI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_VARCHAR(curid,i,id,100);
     END IF;
     IF col[i].col_name = 'DESC' THEN
        SET descI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_VARCHAR(curid,i,desc,2000);
     END IF;
     IF col[i].col_name = 'MEMBER' THEN
        SET memberI = i;
        CALL DBMS_SQL.DEFINE_COLUMN_INT(curid,i,member);
     END IF;
     IF col[i].col_name = 'VAL' THEN
        SET valI = i;
      --  CALL DBMS_SQL.DEFINE_COLUMN_INT(curid,i,val);
        CALL DBMS_SQL.DEFINE_COLUMN_NUMBER(curid,i,vald);
     END IF;

     SET i = i + 1;
   END LOOP;


   -- first run, collect the metritcs ID and NAMES
   -- to prepare first two line of the output
   -- open and analyze the statement

   -- execute the statement
   CALL DBMS_SQL.EXECUTE(curid,v_status);
  fetchloop1: LOOP
     CALL DBMS_SQL.FETCH_ROWS(curid,v_status);
     if v_status = 0 THEN LEAVE fetchloop1; END IF;
     CALL DBMS_SQL.COLUMN_VALUE_VARCHAR(curid,idI,id);
     SET desc = '';
     IF descI <> -1 THEN CALL DBMS_SQL.COLUMN_VALUE_VARCHAR(curid,descI,desc); END IF;
     SET header[id] = desc;
     SET vals[id] = 0;
   END LOOP;

   SET WRITEHEADER = 0;
--   WHILE WRITEHEADER < 2 DO
   WHILE WRITEHEADER < 1 DO
     -- create text file header
     OPEN cur;
     SET eof = 0;
     SET i = 0;
     FETCH FROM CUR INTO id,desc;
     -- additional columns at the beginning
     CALL UTL_FILE.PUT(v_exp_file,'TIMES|MEMBER|NO|');
     WHILE eof = 0 DO
       IF i > 0 THEN CALL UTL_FILE.PUT(v_exp_file,'|'); END IF;
       FETCH FROM CUR INTO id,desc;

       IF WRITEHEADER = 0 THEN CALL UTL_FILE.PUT(v_exp_file,id);
       ELSE CALL UTL_FILE.PUT(v_exp_file,desc);
       END IF;

       SET i = i + 1;
     END WHILE;
     CALL UTL_FILE.NEW_LINE(v_exp_file);
     CLOSE cur;
     SET WRITEHEADER = WRITEHEADER + 1;
    END WHILE;

    -- run statement again and collect values
   CALL DBMS_SQL.EXECUTE(curid,v_status); -- execute again
   SET lastnum = -1;
  fetchloop2: LOOP
     CALL DBMS_SQL.FETCH_ROWS(curid,v_status);
     if v_status <> 0 THEN
       CALL DBMS_SQL.COLUMN_VALUE_INT(curid,numI,num);
       IF memberI <> -1 THEN
         CALL DBMS_SQL.COLUMN_VALUE_INT(curid,memberI,member);
       END IF;
     END IF;
     IF (v_status = 0 OR num <> lastnum OR member <> lastmember ) AND lastnum <> -1 THEN
       -- write next line
       CALL UTL_FILE.PUT(v_exp_file,'' || times);
       CALL UTL_FILE.PUT(v_exp_file,'|' || lastmember);
       CALL UTL_FILE.PUT(v_exp_file,'|' || lastnum);
       OPEN cur;
       SET eof = 0;
       FETCH FROM CUR INTO id,desc;
       WHILE eof = 0 DO
         FETCH FROM CUR INTO id,desc;
         SET valb = vals[id];
         -- zero immediately
         SET vals[id] = 0;
         CALL UTL_FILE.PUT(v_exp_file,'|' || valb);
       END WHILE;
       CALL UTL_FILE.NEW_LINE(v_exp_file);
       CLOSE cur;
     END IF;
     IF v_status = 0 THEN LEAVE fetchloop2; END IF;

     SET lastnum = num;
     SET lastmember = member;
     CALL DBMS_SQL.COLUMN_VALUE_VARCHAR(curid,idI,id);
     -- CALL DBMS_SQL.COLUMN_VALUE_INT(curid,valI,val);
     CALL DBMS_SQL.COLUMN_VALUE_NUMBER(curid,valI,vald);
     CALL DBMS_SQL.COLUMN_VALUE_TIMESTAMP(curid,timesI,times);
     SET vals[id] = vald;
   END LOOP;

   CALL DBMS_SQL.CLOSE_CURSOR(curid);
   CALL UTL_FILE.FCLOSE_ALL();
END P1
@
