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
     NOT DETERMINISTIC
     SPECIFIC ST_LISTKEY

    -- Date Format ISO is required for dates prior to 1940.
    set option COMMIT=*NONE,DATFMT=*ISO,TIMFMT=*HMS,
               BINDOPT = 'BNDSRVPGM(SQLTOOLS/SQLTOOLS)'
BEGIN

   RETURN  SELECT
        DBKLIB,
        DBKFIL,
        DBKFMT,
        DBKPOS,
        case dbkord WHEN 'A' then 'A' ELSE 'D' end,
        DBKFLD,
        D.DATA_TYPE,
        CASE WHEN D.NUMERIC_PRECISION is NULL THEN D.LENGTH
             ELSE D.NUMERIC_PRECISION end ,
             NUMERIC_SCALE,
        D.COLUMN_NAME,
        D.TABLE_NAME,
        DBKLB2

  FROM QSYS.QADBKFLD
         left outer join QSYS2.SYSCOLUMNS D
           on (DBKFLD,DBKFIL,DBKLIB) =
              (SYSTEM_COLUMN_NAME,SYSTEM_TABLE_NAME,SYSTEM_TABLE_SCHEMA)
        WHERE trim(DBKFIL) LIKE upper(file_name) and trim(DBKLIB) IN
              CASE WHEN library_name = '*LIBL' THEN
                       (SELECT NAME FROM qsys2.library_list_info
                        ORDER BY COLNO)
                   ELSE (upper(library_name)) end
         ORDER  BY  dbklib,dbkfil,dbkfmt,DBKPOS;
 end ;


LABEL on specific routine sqltools.ST_LISTKEY IS
'Retrieve the Key Field List for a file';

comment on specific function sqltools.ST_LISTKEY IS
'List the Key Fields for the given File/Table';

comment on parameter specific function sqltools.ST_LISTKEY
( LIBRARY_NAME is 'The library/schema that contains the table.
  if unspecified, the default is *LIBL',
  FILE_NAME is 'The name of the database file whose key list is returned.');  
