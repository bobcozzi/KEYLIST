 CREATE or REPLACE FUNCTION sqltools.key_List(
                                library_name  varchar(128) default '*LIBL',
                                file_name     varchar(128)
                                    )
     RETURNS TABLE (
              LIBRARY_NAME varchar(10),
              FILE_NAME    varchar(10),
              RCDFMT       varchar(10),
              ORDINAL_POSITION  int,
              ASCDESC      char(1),
              COLUMN_NAME  varchar(10),
              DATA_TYPE    varchar(10),
              LENGTH       int,
              DECPOS       smallInt,
              LONG_COLUMN_NAME varchar(128),
              LONG_TABLE_NAME varchar(128),
              LONG_SCHEMA_NAME varchar(128)
                   )
     LANGUAGE SQL
     READS SQL DATA
     DISALLOW PARALLEL
     NO EXTERNAL ACTION
     STATEMENT DETERMINISTIC
     SPECIFIC ST_LISTKEY

    -- Date Format ISO is required for dates prior to 1940.
    set option COMMIT=*NONE,DATFMT=*ISO,TIMFMT=*HMS

R: BEGIN
   RETURN  
     WITH fileID (fileName, libName, fName) AS
    (
     SELECT OBJLONGNAME,
            objlongschema,
            objname
     FROM TABLE (object_statistics(upper(LIBRARY_NAME), '*FILE',
                                   upper(FILE_NAME))) OD
    )
    SELECT DBKLIB,
           DBKFIL,
           DBKFMT,
           DBKPOS,
           CASE dbkord
             WHEN 'A' THEN 'A'
             ELSE 'D'
           END,
           DBKFLD,
           D.DATA_TYPE,
           CASE
             WHEN D.NUMERIC_PRECISION IS NULL THEN D.LENGTH
             ELSE D.NUMERIC_PRECISION
           END,
           NUMERIC_SCALE,
           D.COLUMN_NAME,
           D.TABLE_NAME,
           DBKLB2
      FROM QSYS.QADBKFLD KF
           INNER JOIN FILEID FD
             ON (TRIM(KF.DBKFIL), TRIM(KF.DBKLB2)) = (FD.fName, FD.LIBNAME)
           LEFT OUTER JOIN QSYS2.SYSCOLUMNS D
             ON (KF.DBKFLD, KF.DBKFIL, KF.DBKLIB) =
                (D.SYSTEM_COLUMN_NAME,
                 D.SYSTEM_TABLE_NAME,
                 D.SYSTEM_TABLE_SCHEMA)
      ORDER  BY  KF.dbklib,KF.dbkfil,KF.dbkfmt,KF.DBKPOS;   
 end ;


LABEL on specific routine sqltools.ST_LISTKEY IS
'Retrieve the Key Field List for a file';

comment on specific function sqltools.ST_LISTKEY IS
'List the Key Fields for the given File/Table';

comment on parameter specific function sqltools.ST_LISTKEY
( LIBRARY_NAME is 'The library/schema that contains the table.
  if unspecified, the default is *LIBL',
  FILE_NAME is 'The name of the database file whose key list is returned.
   NOTE: On IBM i V7R3 and later, this parameter may be generic.'
);
