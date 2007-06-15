/*****************************************************************************/
/*              OCamlODBC                                                    */
/*                                                                           */
/*  Copyright (C) 2004 Institut National de Recherche en Informatique et     */
/*  en Automatique. All rights reserved.                                     */
/*                                                                           */
/*  This program is free software; you can redistribute it and/or modify     */
/*  it under the terms of the GNU Lesser General Public License as published */
/*  by the Free Software Foundation; either version 2.1 of the License, or   */
/*  any later version.                                                       */
/*                                                                           */
/*  This program is distributed in the hope that it will be useful,          */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/*  GNU Lesser General Public License for more details.                      */
/*                                                                           */
/*  You should have received a copy of the GNU Lesser General Public License */
/*  along with this program; if not, write to the Free Software              */
/*  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                 */
/*  02111-1307  USA                                                          */
/*                                                                           */
/*  Contact: Maxence.Guesdon@inria.fr                                        */
/*****************************************************************************/

#ifndef lint
static char vcid[]="$Id: ocaml_odbc_c.c,v 1.15 2007-06-15 21:49:19 chris Exp $";
#endif /* lint */

//#define DEBUG_LIGHT 1
//#define DEBUG2 1
//#define DEBUG3 1

//in makefile, or not: #define ODBC2 1

#ifndef ODBC2
#define OLD_POINTERS 1
#endif


/*---| includes (common) |---*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

/* Includes pour OCAML */
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>

/*---| includes (unixODBC/DB2/iODBC/mSQL/Oracle/Intersolv/WIN32) |----------*/
#ifdef iODBC
#  include <iodbc.h>
#  include <isql.h>
#  include <isqlext.h>
#endif

#ifdef unixODBC
#  include <odbcinst.h>
#  include <sql.h>
#  include <sqlext.h>
#endif

#ifdef DB2
#  include "sqlcli1.h"
#endif

#ifdef mSQL
#  include <sqlcli_.h>
#endif

#ifdef ORACLE
#  include <sqlcli_.h>
#endif

#ifdef INTERSOLV
#  include <sqlext.h>
#endif

#ifdef WIN32
#include <windows.h>
#include <sql.h>
#include <sqlext.h>
#endif


#define MAX_COLUMNS     128
#define COLUMN_SIZE     8000


/* The constants used to represent the OCaml constructors for Column
   types.  In the OCaml type (Libocaml_odbc.sql_column_type), the
   constructors must appear in the same order.  */

/* unknown type */
#define OCAML_SQL_UNKNOWN 0

/* these are standard SQL datatypes */
#define OCAML_SQL_CHAR 1
#define OCAML_SQL_NUMERIC 2
#define OCAML_SQL_DECIMAL 3
#define OCAML_SQL_INTEGER 4
#define OCAML_SQL_SMALLINT 5
#define OCAML_SQL_FLOAT 6
#define OCAML_SQL_REAL 7
#define OCAML_SQL_DOUBLE 8
#define OCAML_SQL_VARCHAR 9

/* extend SQL datatypes */
#define OCAML_SQL_DATE 10
#define OCAML_SQL_TIME 11
#define OCAML_SQL_TIMESTAMP 12
#define OCAML_SQL_LONGVARCHAR 13
#define OCAML_SQL_BINARY 14
#define OCAML_SQL_VARBINARY 15
#define OCAML_SQL_LONGVARBINARY 16
#define OCAML_SQL_BIGINT 17
#define OCAML_SQL_TINYINT 18
#define OCAML_SQL_BIT 19

/* later : add database specific types */






/* Prototype */
void displayError( HENV   hEnv,
                   HDBC   hDbc,
                   HSTMT  hStmt,
                   int       iRC,
                   int       iLineNum
                 );

void print_sql_info(SQLHDBC hdbc);

/* Constructeurs des types abstraits ODBC */
CAMLprim
value ocamlodbc_HENV_c ()
{
  return(Val_int(SQL_NULL_HENV));
}

CAMLprim
value ocamlodbc_HDBC_c ()
{
  return(Val_int(SQL_NULL_HDBC));
}



/*-----------------------------------------------------------------------------
 * initDB_c
 *-----------------------------------------------------------------------------
 * function: initialisation of DB access
 * input:    char *pszDB                                            (not null)
 *             pointer to string containing the database name
 *           char *pszUser                                          (not null)
 *             pointer to string containing the user name
 *           char *pszPassword
 *             pointer to string containing the password
 * output:   int
 *             != 0 - error
 *             == 0 - no error
 *           HENV *phEnv
 *             pointer to DB environment
 *           HDBC *phDbc
 *             pointer to DB context
 *-----------------------------------------------------------------------------
 */
CAMLprim
value ocamlodbc_initDB_c(value v_nom_base, value v_nom_user, value v_password)
{
  CAMLparam3(v_nom_base, v_nom_user, v_password);
  CAMLlocal1(res);
  char *nom_base = String_val(v_nom_base);
  char *nom_user = String_val(v_nom_user);
  char *password = String_val(v_password);
  RETCODE result;
  HENV *phEnv = SQL_NULL_HENV;
  HDBC *phDbc = SQL_NULL_HDBC;

#ifdef DEBUG2
  printf("initDB nombase : \"%s\", nom_user : \"%s\", Password : \"%s\"\n",
         nom_base, nom_user, password);
  fflush(stdout);
#endif

  /* Allocation de la structure de retour */
  res = alloc_tuple(3);

  /* Test des parametres */
  if( NULL == nom_base || NULL == nom_user ) {
#ifdef DEBUG2
    printf("  Erreur de parametre\n");
    fflush(stdout);
#endif
    Field(res,0) = Val_int ((int) -1);
    Field(res,1) = Val_long ((long) SQL_NULL_HENV);
    Field(res,2) = Val_long ((long) SQL_NULL_HDBC);
    CAMLreturn(res);
  }

  /* Allocation memoire des structures HDBC, HENV */
  phDbc = (HDBC *) malloc(sizeof(HDBC));
  phEnv = (HENV *) malloc(sizeof(HENV));
  if( phDbc ==  (HDBC *)NULL || phEnv == (HENV *) NULL) {
#ifdef DEBUG2
    printf("  Erreur allocation memoire \n");
    fflush(stdout);
#endif
    caml_raise_out_of_memory();
  }

  /*
  ** get DB environment
  */
  result = SQLAllocEnv( phEnv );
  if( SQL_SUCCESS != result )
  {
#ifdef DEBUG2
    printf("  Erreur SQLAlloctEnv\n");
    fflush(stdout);
    displayError( *phEnv, SQL_NULL_HDBC, SQL_NULL_HENV, result, __LINE__ );
#endif
    Field(res,0) = Val_int ((int) result);
    Field(res,1) = Val_long ((long) SQL_NULL_HENV);
    Field(res,2) = Val_long ((long) SQL_NULL_HDBC);
    CAMLreturn(res);
  }

  /*
  ** allocate a connection handle
  */
  result = SQLAllocConnect( *phEnv, phDbc );
  if( SQL_SUCCESS != result )
  {
#ifdef DEBUG2
    printf("  Erreur SQLAllocConnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
    Field(res,0) = Val_int ((int) result);
    Field(res,1) = Val_long ((long) SQL_NULL_HENV);
    Field(res,2) = Val_long ((long) SQL_NULL_HDBC);
    CAMLreturn(res);
  }

  /*
  ** connect to server
  */
#ifdef DEBUG2
  printf("  ...connecting to server \"%s\" as user \"%s\" (%s)\n",
         nom_base,
         nom_user,
         (NULL != password) ? password : "<no password set>"
    );
#endif
  result = SQLConnect(*phDbc, nom_base, SQL_NTS,
                      nom_user, SQL_NTS,
                      password, SQL_NTS
                      );
  if( SQL_SUCCESS != result && SQL_SUCCESS_WITH_INFO != result )
  {
#ifdef DEBUG2
    printf("  Erreur SQLConnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
    Field(res,0) = Val_int ((int) result);
    Field(res,1) = Val_long ((long) SQL_NULL_HENV);
    Field(res,2) = Val_long ((long) SQL_NULL_HDBC);
    CAMLreturn(res);
  }

  Field(res,0) = Val_int ((int) 0);
  Field(res,1) = Val_long ((long) phEnv);
  Field(res,2) = Val_long ((long) phDbc);
  CAMLreturn(res);
}


#define MAXBUFLEN 1024

/*-----------------------------------------------------------------------------
 * initDB_driver_c
 *-----------------------------------------------------------------------------
 * function: initialisation of DB access
 * input:    char *connect_string                               (not null)
 *             pointer to ODBC driver connection string.  The string is driver
 *             dependent.  It includes the username and password if applicable.
 *           int prompt
 *             != 0 if the driver should raise a dialog box to request username
 *                  and password
 *             == 0 if the driver should not prompt
 * output:   int
 *             != 0 - error
 *             == 0 - no error
 *           HENV *phEnv
 *             pointer to DB environment
 *           HDBC *phDbc
 *             pointer to DB context
 *-----------------------------------------------------------------------------
 */
CAMLprim
value ocamlodbc_initDB_driver_c(value v_connect_string, value v_prompt)
{
  CAMLparam2 (v_connect_string,v_prompt);
  CAMLlocal1 (res);

  char *connect_string = String_val(v_connect_string);
  int prompt = Bool_val(v_prompt);
  RETCODE result;
  //HENV *phEnv = SQL_NULL_HENV;
  //HDBC *phDbc = SQL_NULL_HDBC;

  SQLHENV      henv = SQL_NULL_HENV;
  SQLHDBC      hdbc1 = SQL_NULL_HDBC;
  SQLHSTMT     hstmt1 = SQL_NULL_HSTMT;

  SQLCHAR      ConnStrIn[MAXBUFLEN] = "";

  SQLCHAR      ConnStrOut[MAXBUFLEN];
  SQLSMALLINT  cbConnStrOut = 0;

  SQLRETURN    cliRC = SQL_SUCCESS;

  /* allocate an environment handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
  res = alloc_tuple(3);
  if (cliRC != SQL_SUCCESS)
  {
#ifdef DEBUG2
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  cliRC = %d\n", cliRC);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    fflush(stdout);
#endif
    caml_failwith("Ocaml_odbc.initDB_driver: error while allocating the environment handle");
  }

  /* set attribute to enable application to run as OCBC 3.0 application */
#ifdef ODBC2
  cliRC = SQLSetEnvAttr(henv,
                        SQL_ATTR_ODBC_VERSION,
                        (void *)SQL_OV_ODBC2,
                        0);
#endif

  //ENV_HANDLE_CHECK(henv, cliRC);

  cliRC = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc1);
  if (cliRC != SQL_SUCCESS)
  {
#ifdef DEBUG2
    printf("\n--ERROR while allocating the environment handle.\n");
    printf("  cliRC = %d\n", cliRC);
    printf("  line  = %d\n", __LINE__);
    printf("  file  = %s\n", __FILE__);
    fflush(stdout);
#endif
    caml_failwith("Ocaml_odbc.initDB_driver: error while allocating the environment handle");
  }

  // Make connection without data source. Ask that driver
  // prompt if insufficient information. Driver returns
  // SQL_ERROR and application prompts user
  // for missing information. Window handle not needed for
  // SQL_DRIVER_NOPROMPT.
  result = SQLDriverConnect(hdbc1,          // Connection handle
                            NULL,           // Window handle
                            connect_string, // Input connect string
                            SQL_NTS,        // Null-terminated string
                            ConnStrOut,     // Address of output buffer
                            MAXBUFLEN,      // Size of output buffer
                            &cbConnStrOut,  // Address of output length
                            (prompt ? SQL_DRIVER_PROMPT : SQL_DRIVER_NOPROMPT));

  if(result == SQL_SUCCESS_WITH_INFO)
    print_sql_info(hdbc1);

  Field(res,0) = Val_int (result);
  if(result == SQL_SUCCESS_WITH_INFO) {Field(res,0) = Val_int (0);}
  if(result == SQL_NO_DATA) {Field(res,0) = Val_int (-11);}
  if(result == SQL_ERROR) {Field(res,0) = Val_int (-12);}
  if(result == SQL_INVALID_HANDLE) {Field(res,0) = Val_int (-13);}

  Field(res,1) = Val_long ((long) henv);
  Field(res,2) = Val_long ((long) hdbc1);
  //printf("henv=%0x, hdbc=%0x\n",henv,hdbc1); fflush(stdout);
  CAMLreturn(res);
}


/*-----------------------------------------------------------------------------
 * exitDB
 *-----------------------------------------------------------------------------
 * function: withdraw of DB access
 * input:    HENV *phEnv
 *             pointer to DB environment
 *           HDBC *phDbc
 *             pointer to DB context
 * output:   int
 *             != 0 - error
 *             == 0 - no error
 *-----------------------------------------------------------------------------
 */
CAMLprim
value ocamlodbc_exitDB_c(value v_phEnv, value v_phDbc)
{
  CAMLparam2 (v_phEnv, v_phDbc);
  HENV *phEnv = (HENV *) (Unsigned_long_val(v_phEnv));
  HDBC *phDbc = (HDBC *) (Unsigned_long_val(v_phDbc));
  RETCODE result;

#ifdef DEBUG2
  printf("exitDB\n");
  fflush(stdout);
#endif

  /* Test des parametres */
  if( SQL_NULL_HENV == phEnv || SQL_NULL_HDBC == phDbc ) {
#ifdef DEBUG2
    printf("  Erreur parametres\n");
    fflush(stdout);
#endif
    CAMLreturn (Val_int ((int)-1));
  }

#ifdef DEBUG3
  printf("<1>"); fflush(stdout);
#endif
  /*
  ** commit transactions
  */
#ifdef OLD_POINTERS
  result = SQLTransact( *phEnv, *phDbc, SQL_COMMIT );
#else
  result = SQLTransact( phEnv, phDbc, SQL_COMMIT );
#endif
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLTransact\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
}

  /*
  ** disconnect from DB
  */
#ifdef DEBUG3
  printf("<2>"); fflush(stdout);
#endif
#ifdef OLD_POINTERS
  result = SQLDisconnect( *phDbc );
#else
  result = SQLDisconnect( phDbc );
#endif
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLDisconnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
  }

  /*
  ** free connection to DB
  */
#ifdef DEBUG3
  printf("<3>"); fflush(stdout);
#endif
#ifdef OLD_POINTERS
  result = SQLFreeConnect( *phDbc );
#else
  result = SQLFreeConnect( phDbc );
#endif
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLFreeConnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
  }
  else
    *phDbc = SQL_NULL_HDBC;

  /*
  ** free environment
  */
#ifdef DEBUG3
  printf("<4>"); fflush(stdout);
#endif
#ifdef OLD_POINTERS
  result = SQLFreeEnv( *phEnv );
#else
  result = SQLFreeEnv( phEnv );
#endif
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLFreeEnv\n");
    fflush(stdout);
    displayError( *phEnv, SQL_NULL_HDBC, SQL_NULL_HENV, result, __LINE__ );
#endif
  }
  else
    *phEnv = SQL_NULL_HENV;

#ifdef DEBUG3
  printf("<5>"); fflush(stdout);
#endif

  CAMLreturn(Val_int((int) 0));
}


/*-----------------------------------------------------------------------------
 * execDB_c
 *-----------------------------------------------------------------------------
 * function: execution of a command, display of results
 * input:    HENV hEnv
 *             handle for DB environment
 *           HDBC hDbc
 *             handle for DB context
 *           char *pszSqlStmt
 *             pointer to string containing the SQL statement
 * output:   int
 *             != 0 - error
 *             == 0 - no error
 *           int list
 *-----------------------------------------------------------------------------
 */

typedef struct {
  HSTMT      exec_hstmt;                    /* handle for statement    */
  SWORD      exec_iResColumns;              /* number of result cols   */
  int        exec_iRowCount;                /* number of rows affected */
  SQLPOINTER exec_pData[MAX_COLUMNS+1];
  /* pointer to results exec_pData[1..exec_iResColumns]
     (column 0 is not used) */
  SQLINTEGER exec_indicator[MAX_COLUMNS+1]; /* [1..exec_iResColumns] */
  HENV *phEnv;
  HDBC *phDbc;
} env ;


/* Allocate the result pair (in case of error) and return it.  */
#define execDB_return_error(result)                          \
  retour = alloc_tuple (2) ;                                 \
  Store_field (retour, 0, Val_int((int) result));            \
  Store_field (retour, 1, caml_q_env);                       \
  CAMLreturn(retour)


CAMLprim
value ocamlodbc_execDB_c(value v_phEnv, value v_phDbc, value v_cmd)
{
  CAMLparam3(v_phEnv, v_phDbc, v_cmd);
  CAMLlocal1(caml_q_env) ;
  CAMLlocal1(retour) ;
  char *cmd = String_val(v_cmd);
  int exec_ci = 0;
  SQLCHAR     exec_szColName[COLUMN_SIZE];   /* name of column          */
  SQLSMALLINT exec_cbColName;                /* length of column name   */
  SQLSMALLINT exec_fColType;                 /* type of column          */
  SQLUINTEGER exec_uiColPrecision;           /* precision of column     */
  SQLSMALLINT exec_iColScaling;              /* scaling of column       */
  SQLSMALLINT exec_fColNullable;             /* is column nullable?     */
  SQLINTEGER  collen;
  RETCODE result = 0;
  env* q_env = (env*) malloc(sizeof(env));
  caml_q_env = (value) q_env;

  q_env->exec_iResColumns = 0;
  q_env->exec_iRowCount = 0;
  q_env->exec_pData[0] = NULL;
  q_env->phEnv = (HENV *) (Unsigned_long_val(v_phEnv));
  q_env->phDbc = (HDBC *) (Unsigned_long_val(v_phDbc));
  //printf("phEnv=%0x, phDbc=%0x\n",q_env->phEnv,q_env->phDbc); fflush(stdout);
  /*  caml_q_env = alloc (sizeof(env*), Abstract_tag);
  Store_field (caml_q_env, 0, (value) q_env);
  */

#ifdef DEBUG2
  printf("execDB cmd: \"%s\"\n", cmd);
  fflush(stdout);
#endif

#ifdef DEBUG3
   printf("<1>"); fflush(stdout);
#endif

  /*
  ** check parameter list
  */
  if( '\0' == cmd[0]
      || q_env->phEnv == SQL_NULL_HENV
      || q_env->phDbc == SQL_NULL_HDBC ) {
#ifdef DEBUG2
    printf("  Erreur parametres\n");
    fflush(stdout);
#endif
    execDB_return_error(-1);
  }
#ifdef DEBUG3
  printf("<2>"); fflush(stdout);
#endif

  /*
  ** get statement handle
  */
#ifdef ODBC2
#ifdef DEBUG3
  int x = (int)(*(q_env->phDbc));
  printf("<2.5,%0x>", x); fflush(stdout);
#endif
  result = SQLAllocHandle(SQL_HANDLE_STMT,
                          q_env->phDbc, &(q_env->exec_hstmt) );
#else
  result = SQLAllocStmt(*(q_env->phDbc), &(q_env->exec_hstmt) );
#endif
#ifdef DEBUG3
  printf("<3>"); fflush(stdout);
#endif
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLAllocStmt\n");
    fflush(stdout);
    displayError( *(q_env->phEnv),
                  *(q_env->phDbc),
                  q_env->exec_hstmt,
                  result, __LINE__ );
#endif
    execDB_return_error(result);
  }

  /*
  ** prepare statement
  */
  if( SQL_SUCCESS != (result=SQLPrepare(q_env->exec_hstmt, cmd, SQL_NTS)) ) {
#ifdef DEBUG2
    printf("  Erreur SQLPrepare\n");
    printf("  %s\n", cmd);
    fflush(stdout);
    displayError(*(q_env->phEnv),
                 *(q_env->phDbc),
                 q_env->exec_hstmt,
                 result, __LINE__ );
#endif
    execDB_return_error(result);
  }

  /*
  ** execute statement
  */
  result = SQLExecute(q_env->exec_hstmt);
  if( result == SQL_SUCCESS) {}
  else if(result == SQL_SUCCESS_WITH_INFO)
    print_sql_info(q_env->phDbc);
  else {
#ifdef DEBUG2
    printf("  Erreur SQLExecute\n");
    fflush(stdout);
    displayError( *(q_env->phEnv),
                  *(q_env->phDbc),
                  q_env->exec_hstmt,
                  result, __LINE__ );
#endif
    execDB_return_error(result);
  }
  /*
  ** get number of rows affected / columns returned
  */
  q_env->exec_iRowCount = 0;
  result = SQLRowCount(q_env->exec_hstmt,
                       (SQLINTEGER FAR *) &(q_env->exec_iRowCount) );
#ifdef DEBUG_LIGHT
  printf("  number of rows affected    : %d\n",
         (SQL_SUCCESS == result) ? q_env->exec_iRowCount : -1);
#endif
  q_env->exec_iResColumns = 0;
  result = SQLNumResultCols(q_env->exec_hstmt,
                            (SWORD FAR *) &(q_env->exec_iResColumns) );
#ifdef DEBUG_LIGHT
  printf("  number of columns returned : %d\n",
         (SQL_SUCCESS == result) ? q_env->exec_iResColumns : -1);
  fflush(stdout);
#endif

  /*
  ** get table description and create list with pointers
  */
  if( 0 < q_env->exec_iResColumns )
  {
#ifdef DEBUG2
    printf("  Binding result columns:\n" );
#endif
    for( exec_ci = q_env->exec_iResColumns;  exec_ci >=1;  exec_ci-- )
      {
        if( SQL_SUCCESS !=
            (result = SQLDescribeCol(
              q_env->exec_hstmt,
              exec_ci, /* ColumnNumber */
              &(exec_szColName[0]), /* ColumnName */
              sizeof(exec_szColName) - 1, /* BufferLength */
              &(exec_cbColName), /* NameLengthPtr */
              &(exec_fColType), /* DataTypePtr */
              (SQLUINTEGER*) &exec_uiColPrecision, /* ColumnSizePtr (length) */
              &(exec_iColScaling), /* DecimalDigitsPtr (scale) */
              &(exec_fColNullable) /* NullablePtr */
              ))
          )
          {
#ifdef DEBUG2
            printf("  Erreur SQLDescribeCol\n");
            fflush(stdout);
            displayError( *(q_env->phEnv),
                          *(q_env->phDbc),
                          q_env->exec_hstmt,
                          result, __LINE__ );
#endif
            execDB_return_error(result);
          }
        /*
        ** Bind the columns
        **
        ** See: http://publib.boulder.ibm.com/infocenter/iseries/v5r3/index.jsp?topic=/cli/rzadpfndecol.htm
        */
        SQLColAttributes(q_env->exec_hstmt, exec_ci, SQL_COLUMN_DISPLAY_SIZE,
                         NULL, 0, NULL, &collen);
        collen++; /* Final \0 */
        (q_env->exec_pData)[exec_ci] = NULL;
        (q_env->exec_indicator)[exec_ci] = 0;
        if( NULL == ((q_env->exec_pData)[exec_ci] = malloc(collen)) )
          {
            caml_raise_out_of_memory();
          }
        //memset( (q_env->exec_pData)[exec_ci], 0, exec_uiColPrecision +1 );
        result = SQLBindCol(
          q_env->exec_hstmt,
          exec_ci,
          SQL_C_CHAR, /* TargetType */
          (q_env->exec_pData)[exec_ci], /* TargetValuePtr */
          collen, /* BufferLength */
          &(q_env->exec_indicator[exec_ci]) /* StrLen_or_IndPtr */
          );
#ifdef DEBUG2
        printf("  q_env->exec_pData[%i] = %p\t(collen=%i, result=%i)\n",
               exec_ci, (q_env->exec_pData)[exec_ci], collen, result);
#endif
      }
  }

  /* on retourne 1 s'il n'y a pas de colonnes, ou 0 sinon.  (1 =
     SQL_SUCCESS_WITH_INFO thus won't conflict with another return
     value.) */
  if ( 0 < q_env->exec_iResColumns )
    {
      retour = alloc_tuple (2) ;
      Store_field (retour, 0, Val_int(0));
      Store_field (retour, 1, caml_q_env);
      CAMLreturn(retour);
    }
  else
    {
      retour = alloc_tuple (2) ;
      Store_field (retour, 0, Val_int(1));
      Store_field (retour, 1, caml_q_env);
      CAMLreturn(retour);
    }
}


/* free_ExecDB_c : fonction de désallocation des structures allouées par
   execDB_c */
CAMLprim
value ocamlodbc_free_execDB_c(value caml_q_env)
{
  CAMLparam1(caml_q_env);
  int result;
  int exec_ci = 0;
  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env ;
#ifdef DEBUG2
  printf("free_execDB_c\n");
#endif
    /*
    ** free allocated memory
    */
  for( exec_ci = 1;  exec_ci <= q_env->exec_iResColumns;  exec_ci++ )
    {
#ifdef DEBUG2
      fprintf(stderr, "  free(q_env->exec_pData[%i] %s NULL)", exec_ci,
              (q_env->exec_pData[exec_ci] == NULL) ? "==" : "!=");
      fflush(stderr);
#endif

      free( q_env->exec_pData[exec_ci] );
#ifdef DEBUG2
      fprintf(stderr, "  Ok\n");  fflush(stderr);
#endif
      q_env->exec_pData[exec_ci] = NULL;
    } /* for */
#ifdef DEBUG2
  fprintf(stderr, "  free\n");
  fflush(stderr);
#endif
  /*
  ** free statement handle
  */
  result = SQLFreeStmt(q_env->exec_hstmt, SQL_DROP );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("  Erreur SQLFreeStmt\n");
    fflush(stdout);
    displayError( *(q_env->phEnv),
                  *(q_env->phDbc),
                  q_env->exec_hstmt,
                  result, __LINE__ );

#endif
  }
  free(q_env);
#ifdef DEBUG2
  fprintf(stderr, "end free_execDB_c\n");
  fflush(stderr);
#endif
  CAMLreturn(Val_unit);
}



/* Fonction prenant un code de type SQL et retournant la constante
   correspondant au bon constructeur OCaml. */
static
int get_OCaml_SQL_type_code (int code)
{
  switch (code)
    {
    case SQL_CHAR: 	return (OCAML_SQL_CHAR);
    case SQL_BINARY: 	return (OCAML_SQL_BINARY);
    case SQL_DATE: 	return (OCAML_SQL_DATE);
    case SQL_DECIMAL: 	return (OCAML_SQL_DECIMAL);
    case SQL_DOUBLE: 	return (OCAML_SQL_DOUBLE);
    case SQL_FLOAT: 	return (OCAML_SQL_FLOAT);
    case SQL_INTEGER: 	return (OCAML_SQL_INTEGER);
    case SQL_LONGVARCHAR: return (OCAML_SQL_LONGVARCHAR);
    case SQL_LONGVARBINARY: return (OCAML_SQL_LONGVARBINARY);
    case SQL_NUMERIC: 	return (OCAML_SQL_NUMERIC);
    case SQL_REAL: 	return (OCAML_SQL_REAL);
    case SQL_SMALLINT: 	return (OCAML_SQL_SMALLINT);
    case SQL_TIME: 	return (OCAML_SQL_TIME);
    case SQL_TIMESTAMP: return (OCAML_SQL_TIMESTAMP);
    case SQL_VARCHAR: 	return (OCAML_SQL_VARCHAR);
    case SQL_VARBINARY: return (OCAML_SQL_VARBINARY);
    case SQL_TINYINT: 	return (OCAML_SQL_TINYINT);
    default: 		return (OCAML_SQL_UNKNOWN);
    }
}

/* Fonction retournant la liste des couples (nom, type) pour chaque
   champ retourné par la dernière requête exécutée et non encore
   libérée. */
CAMLprim
value ocamlodbc_get_infoDB_c(value caml_q_env)
{
  CAMLparam1(caml_q_env);
  CAMLlocal2(info_temp, info_l_head);
  CAMLlocal1(info_cpl);
  int exec_ci = 0;
  SQLCHAR     exec_szColName[COLUMN_SIZE];    /* name of column          */
  SQLSMALLINT exec_cbColName;                 /* length of column name   */
  SQLSMALLINT exec_fColType;                  /* type of column          */
  SQLUINTEGER exec_uiColPrecision;            /* precision of column     */
  SQLSMALLINT exec_iColScaling;               /* scaling of column       */
  SQLSMALLINT exec_fColNullable;              /* is column nullable?     */
  RETCODE result = 0;

  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env ;

#ifdef DEBUG2
  printf("get_infoDB\n");
  fflush(stdout);
#endif

  /*
  ** check parameter list
  */
  if( (q_env->phEnv) == SQL_NULL_HENV || (q_env->phDbc) == SQL_NULL_HDBC ) {
#ifdef DEBUG2
    printf("  Erreur paramètres\n");
    fflush(stdout);
#endif
    /* On retourne une liste vide */
    info_l_head = Val_int (0);
    CAMLreturn(info_l_head);
  }

  /*
  ** get table description and create list with pointers
  */
  if(q_env->exec_iResColumns <= 0) {
      caml_failwith("Ocamlodbc.execute: no columns in the result!");  
  }
  
#ifdef DEBUG2
  printf("  result columns:\n");
#endif
  /* Initialisation de la liste des descriptions de colonnes */
  info_l_head = Val_int(0);

  for( exec_ci = q_env->exec_iResColumns; exec_ci >=1; exec_ci-- ) {
    /*
    ** display table info
    */
#ifdef DEBUG2
    printf( "    [%03u] ", exec_ci ); fflush( stdout );
#endif
    if( SQL_SUCCESS !=
        (result=SQLDescribeCol(q_env->exec_hstmt,
                               exec_ci,
                               &(exec_szColName[0]),
                               sizeof(exec_szColName) - 1,
                               &(exec_cbColName),
                               &(exec_fColType),
                               (UDWORD FAR *) &(exec_uiColPrecision),
                               &(exec_iColScaling),
                               &(exec_fColNullable)     )
          )) {
#ifdef DEBUG2
      printf("  Erreur SQLDescribeCol\n");
      fflush(stdout);
      displayError( *(q_env->phEnv),
                    *(q_env->phDbc),
                    q_env->exec_hstmt,
                    result, __LINE__ );
#endif
      /* Allocation de la structure de retour */
      info_l_head = Val_int(0);
      CAMLreturn(info_l_head);
    }

#ifdef DEBUG2
    printf( "  %s type=", exec_szColName );
    switch( exec_fColType ) {
#ifndef INTERSOLV
  /*        case SQL_BLOB:               printf( "BLOB" );           break;
            case SQL_BLOB_LOCATOR:       printf( "BLOB_LOCATOR" );   break;*/
    case SQL_CHAR:               printf( "CHAR" );           break;
    case SQL_BINARY:             printf( "BINARY" );         break;
  /*        case SQL_CLOB:               printf( "CLOB" );           break;
            case SQL_CLOB_LOCATOR:       printf( "CLOB_LOCATOR" );   break;*/
    case SQL_DATE:               printf( "DATE" );           break;
  /*        case SQL_DBCLOB:             printf( "DBCLOB" );         break;
            case SQL_DBCLOB_LOCATOR:     printf( "DBCLOB_LOCATOR" ); break;*/
    case SQL_DECIMAL:            printf( "DECIMAL" );        break;
    case SQL_DOUBLE:             printf( "DOUBLE" );         break;
    case SQL_FLOAT:              printf( "FLOAT" );          break;
  /*        case SQL_GRAPHIC:            printf( "GRAPHIC" );        break;*/
    case SQL_INTEGER:            printf( "INTEGER" );        break;
    case SQL_LONGVARCHAR:        printf( "LONGVARCHAR" );    break;
    case SQL_LONGVARBINARY:      printf( "LONGVARBINARY" );  break;
  /*        case SQL_LONGVARGRAPHIC:     printf( "LONGVARGRAPHIC" ); break;*/
    case SQL_NUMERIC:            printf( "NUMERIC" );        break;
    case SQL_REAL:               printf( "REAL" );           break;
    case SQL_SMALLINT:           printf( "SMALLINT" );       break;
    case SQL_TIME:               printf( "TIME" );           break;
    case SQL_TIMESTAMP:          printf( "TIMESTAMP" );      break;
    case SQL_VARCHAR:            printf( "VARCHAR" );        break;
    case SQL_VARBINARY:          printf( "VARBINARY" );      break;
  /*        case SQL_VARGRAPHIC:         printf( "VARGRAPHIC" );     break;*/
    case SQL_TINYINT:            printf( "TINYINT" );    break;
    default:                     printf( "unknown" );
#endif
    } /* switch */
    printf( " precision=%u scaling=%d nullable=%s\n",
            exec_uiColPrecision, exec_iColScaling,
            (SQL_NO_NULLS == exec_fColNullable) ? "YES" : "NO"
      );
#endif
      /* Construction des éléments de la liste */
    info_temp = alloc_tuple (2);
    info_cpl = alloc_tuple (2);
    Store_field (info_cpl, 0, copy_string(exec_szColName));
    Store_field (info_cpl, 1,
                 Val_int(get_OCaml_SQL_type_code ((int)exec_fColType)));
    Store_field (info_temp, 0, info_cpl);
    Store_field (info_temp, 1, info_l_head);
    info_l_head = info_temp;
  }
#ifdef DEBUG2
  printf("  Point N\n");
#endif
  CAMLreturn(info_l_head);
}




/* itere_execDB_c : fonction récupérant un certain nombre
   d'enregistrements, pour la requête exécutée par la fonction execDB.
*/
CAMLprim
value ocamlodbc_itere_execDB_c (value caml_q_env, value vnb_records)
{
  CAMLparam2(caml_q_env, vnb_records);
  CAMLlocal1(exec_res);
  CAMLlocal2(exec_string_list_list, some);
  CAMLlocal5(exec_temp, exec_temp2, exec_l_head, exec_l_head2,
             exec_string_list);

  RETCODE result = 0;
  int i;
  int exec_ci = 0;
  int nb_records = Int_val(vnb_records);
  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env;

#ifdef DEBUG2
  printf( "itere_execDB_c\n");
#endif

  exec_l_head2 = Val_int(0);
  exec_string_list_list = exec_l_head2;
  exec_temp2 = Val_int(0);

#ifdef DEBUG2
  printf( "  nb_records = %d (max)\n", nb_records );
#endif

  if (0 < q_env->exec_iResColumns)
    {
#ifdef DEBUG2
      printf("  0 < q_env->exec_iResColumns = %i\n", q_env->exec_iResColumns);
#endif
      for(i = 0; i < nb_records; i++)
        {
          result = SQLFetch(q_env->exec_hstmt);
          if (SQL_SUCCESS != result && SQL_SUCCESS_WITH_INFO != result)
            {
              break;
            }
#ifdef DEBUG2
          printf( "  --> " );
#endif
          exec_l_head = Val_int(0); /* empty list */

          for( exec_ci = q_env->exec_iResColumns; exec_ci >= 1; exec_ci-- )
            {
              exec_temp = alloc_tuple (2);
              Store_field (exec_temp, 1, exec_l_head);
              exec_l_head = exec_temp;

              if (q_env->exec_indicator[exec_ci] == SQL_NULL_DATA) {
#ifdef DEBUG2
                printf ("NULL");
#endif
                /* Return [None] */
                Store_field(exec_temp,0, Val_int(0));
              }
              else {
#ifdef DEBUG2
                printf("'%s' ", (NULL == q_env->exec_pData[exec_ci]) ?
                       "<ERROR>" : q_env->exec_pData[exec_ci] );
                fflush(stdout);
#endif
                /* Return [Some(data)] */
                some = caml_alloc(1, 0);
                Store_field(some, 0,
                            copy_string((NULL == q_env->exec_pData[exec_ci]) ?
                                        "<ERROR>" :
                                        q_env->exec_pData[exec_ci]));
                Store_field(exec_temp, 0, some);
              }
            } /* for */
#ifdef DEBUG2
          printf( "<--\n" );
#endif
          exec_string_list = exec_l_head;

          exec_l_head2 = alloc_tuple(2);
          Store_field (exec_l_head2, 0, exec_string_list);
          Store_field (exec_l_head2, 1, Val_int(0));

          if (exec_temp2 != Val_int(0) ) {
            Store_field (exec_temp2, 1, exec_l_head2);
          }
          exec_temp2 = exec_l_head2;

          if (exec_string_list_list == Val_int(0)) {
#ifdef DEBUG2
            printf("  on crée la tête\n");
#endif
            exec_string_list_list = exec_temp2;
          }
        } /* for */
    } /* if(0 < q_env->exec_iResColumns) */

  /*
  ** display last return code
  */
#ifdef DEBUG2
  switch( result )
    {
    case SQL_SUCCESS:           printf("  SQL_SUCCESS\n" );           break;
    case SQL_SUCCESS_WITH_INFO: printf("  SQL_SUCCESS_WITH_INFO\n" ); break;
    case SQL_ERROR:             printf("  SQL_ERROR\n" );
      displayError(*(q_env->phEnv), *(q_env->phDbc), q_env->exec_hstmt,
                   result, __LINE__ );
      break;
    case SQL_INVALID_HANDLE:    printf("  SQL_INVALID_HANDLE\n" );     break;
    case SQL_NO_DATA_FOUND:     printf("  SQL_NO_DATA_FOUND\n" );      break;
    default:                    printf("  unknown result = %d\n", result );
    } /* switch */
#endif

  /* on renvoie le nombre de records retournés */
  exec_res = alloc_tuple(2);
  Store_field(exec_res,0, Val_int(i));
#ifdef DEBUG2
  printf("  Number of returned rows: %i\n", i);
#endif
  Store_field(exec_res,1, exec_string_list_list);
  CAMLreturn(exec_res);
}



/*-----------------------------------------------------------------------------
 * displayError
 *-----------------------------------------------------------------------------
 * function: display an error message for a given error code
 * input:    HENV hEnv
 *             DB environment handle
 *           HDBC hDbc
 *             DB context handle
 *           HSTMT hStmt
 *             statement handle
 *           int iRC
 *             error code
 *           int iLineNum
 *             line number, where error occurred
 * output:   <none>
 *-----------------------------------------------------------------------------
 */
void displayError( HENV hEnv, HDBC hDbc, HSTMT hStmt,
                   int iRC, int iLineNum
                 )
{ /*---| variables |---*/
  SQLCHAR           szBuffer[ SQL_MAX_MESSAGE_LENGTH ];    /* msg. buffer    */
  SQLCHAR           szSqlState[ 8 /*SQL_SQLSTATE_SIZE*/ ]; /* statement buf. */
  SQLINTEGER        iSqlCode;                              /* return code    */
  SQLSMALLINT       iLength;                               /* return length  */

  /*---| program |---*/
  /*
  ** display native error code
  */
  /* fprintf( stderr, "\a-----------------------\n" ); */
  fprintf( stdout, "-----------------------\n" );
  fprintf( stdout, "SQL error              : %d\n", iRC );
  fprintf( stdout, "line number            : %d\n", iLineNum );

  /*
  ** display all error messages corresponding to this code
  */
  while( SQL_SUCCESS == SQLError( hEnv, hDbc, hStmt, szSqlState,
                                  &iSqlCode, szBuffer,
                                  SQL_MAX_MESSAGE_LENGTH - 1, &iLength
                                )
       )
  {
    fprintf( stdout, "SQL state              : %s\n", szSqlState );
    fprintf( stdout, "native error code      : %ld\n", iSqlCode );
    fprintf( stdout, "%s\n", szBuffer );
  } /* while */

  fprintf( stderr, "-----------------------\n" );
  /* fprintf( stderr, "\a-----------------------\n" ); */
  fflush(stderr);
  fflush(stdout);
} /* displayError */


void print_sql_info(SQLHDBC hdbc)
{
  SQLRETURN res2;
  SQLCHAR state = 0;
  SQLINTEGER nativeState = 0;
  SQLCHAR msg[MAXBUFLEN+1];
  SQLSMALLINT msgLength = 0;
  do {
    res2 = SQLGetDiagRec(SQL_HANDLE_DBC,
                         hdbc,
                         1, //SQLSMALLINT     RecNumber,
                         &state, //SQLCHAR *     Sqlstate,
                         &nativeState, //SQLINTEGER *     NativeErrorPtr,
                         msg, // SQLCHAR *     MessageText,
                         MAXBUFLEN, // SQLSMALLINT     BufferLength,
                         &msgLength //SQLSMALLINT *     TextLengthPtr
                         );
    printf("state=%0xh, nativeState=%0xh, msg=%s\n", state, nativeState, msg);
  } while(res2==SQL_SUCCESS_WITH_INFO);;
  fflush(stdout);
}
