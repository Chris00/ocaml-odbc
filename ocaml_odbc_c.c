/*---| includes (common) |---*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

/* Includes pour OCAML */
#include <mlvalues.h>
#include <alloc.h>
#include <memory.h>

/*---| includes (unixODBC/DB2/iODBC/mSQL/Oracle/Intersolv/WIN32) |-----------------------------*/
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

/* #undef DEBUG2 */
/*#define DEBUG2      */

#define MAX_COLUMNS     128
#define COLUMN_SIZE     8000


/* The constants used to represent the OCaml constructors for Column types.
 In the OCaml type (Libocaml_odbc.sql_column_type), the constructors must
 appear in the same order.*/

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
void      displayError( HENV   hEnv,
                        HDBC   hDbc,
                        HSTMT  hStmt,
                        int       iRC,
                        int       iLineNum
                      );

/* Constructeurs des types abstraits ODBC */
value value_HENV_c () 
{
  return(Val_int(SQL_NULL_HENV));
}

value value_HDBC_c ()
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
value initDB_c( value v_nom_base, value v_nom_user, value v_password)
{ 
  CAMLparam3 (v_nom_base, v_nom_user, v_password);
  CAMLlocal1 (res);

  char *nom_base = String_val(v_nom_base);
  char *nom_user = String_val(v_nom_user);
  char *password = String_val(v_password);
  RETCODE result;
  HENV *phEnv = SQL_NULL_HENV;
  HDBC *phDbc = SQL_NULL_HDBC;

#ifdef DEBUG2
  printf("Appel de initDB nombase : %s, nom_user : %s, Password : %s\n", nom_base, nom_user, password);
  fflush(stdout);
#endif

  /* Allocation de la structure de retour */
  res =  alloc_tuple(3);

  /* Test des parametres */
  if( NULL == nom_base || NULL == nom_user ) {
#ifdef DEBUG2
    printf("Erreur de parametre\n");
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
    printf("Erreur allocation memoire \n");
    fflush(stdout);
#endif
    Field(res,0) = Val_int ((int) -2);
    Field(res,1) = Val_long ((long) SQL_NULL_HENV);
    Field(res,2) = Val_long ((long) SQL_NULL_HDBC);
    CAMLreturn(res);
  }

  /*
  ** get DB environment
  */
  result = SQLAllocEnv( phEnv );
  if( SQL_SUCCESS != result )
  {
#ifdef DEBUG2
    printf("Erreur SQLAlloctEnv\n");
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
    printf("Erreur SQLAllocConnect\n");
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
  printf(  "....connecting to server '%s' as user '%s' (%s)\n",
           nom_base,
           nom_user,
           (NULL != password) ? password : "<no password set>"
         );
#endif
  result = SQLConnect( *phDbc, nom_base,       SQL_NTS,
                            nom_user,     SQL_NTS,
                            password, SQL_NTS
                  );
  if( SQL_SUCCESS != result && SQL_SUCCESS_WITH_INFO != result )
  {
#ifdef DEBUG2
    printf("Erreur SQLConnect\n");
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
value exitDB_c( value v_phEnv, value v_phDbc)
{ 
  CAMLparam2 (v_phEnv, v_phDbc);
  CAMLlocal1 (res);
  HENV *phEnv = (HENV *) (Long_val(v_phEnv));
  HDBC *phDbc = (HDBC *) (Long_val(v_phDbc));
  RETCODE result;

#ifdef DEBUG2
  printf("Appel de exitDB\n");
  fflush(stdout);
#endif

  /* Test des parametres */
  if( SQL_NULL_HENV == phEnv || SQL_NULL_HDBC == phDbc ) {
#ifdef DEBUG2
    printf("Erreur parametres\n");
    fflush(stdout);
#endif
    CAMLreturn (Val_int ((int)-1));
  }
   /*
  ** commit transactions
  */
  result = SQLTransact( *phEnv, *phDbc, SQL_COMMIT );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLTransact\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
  }

  /*
  ** disconnect from DB
  */
  result = SQLDisconnect( *phDbc );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLDisconnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
  }

  /*
  ** free connection to DB
  */
  result = SQLFreeConnect( *phDbc );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLFreeConnect\n");
    fflush(stdout);
    displayError( *phEnv, *phDbc, SQL_NULL_HENV, result, __LINE__ );
#endif
  }
  else
    *phDbc = SQL_NULL_HDBC;

  /*
  ** free environment
  */
  result = SQLFreeEnv( *phEnv );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLFreeEnv\n");
    fflush(stdout);
    displayError( *phEnv, SQL_NULL_HDBC, SQL_NULL_HENV, result, __LINE__ );
#endif
  }
  else
    *phEnv = SQL_NULL_HENV;
 
  res = Val_int ((int) 0);
  CAMLreturn(res);
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
  HSTMT       exec_hstmt;                       /* handle for statement     */
  SWORD       exec_iResColumns;                 /* number of result cols    */
  int         exec_iRowCount;                   /* number of rows affected  */
  void        *exec_pData[MAX_COLUMNS+1];       /* pointer to results (column 0 is not used) */
  SQLINTEGER  exec_indicator[MAX_COLUMNS+1];
  HENV *phEnv;
  HDBC *phDbc;
} env ;

env * new_env (void) {
  env* q_env = (env*) malloc (sizeof(env));

  q_env->exec_iResColumns = 0;
  q_env->exec_iRowCount = 0;
  q_env->exec_pData[0] = NULL;
  q_env->phEnv = NULL;
  q_env->phDbc = NULL;
  
  return q_env ;  
}

value execDB_c( value v_phEnv, value v_phDbc, value v_cmd)
{ 
  CAMLparam3(v_phEnv, v_phDbc, v_cmd);
  CAMLlocal1 (exec_res);
  CAMLlocal1 (caml_q_env) ;
  CAMLlocal1 (retour) ;
  char *cmd = String_val(v_cmd);
  int exec_ci = 0;
  SQLCHAR     exec_szColName[COLUMN_SIZE];          /* name of column          */
  SQLSMALLINT exec_cbColName;                       /* length of column name   */
  SQLSMALLINT exec_fColType;                        /* type of column          */
  SQLUINTEGER exec_uiColPrecision;                  /* precision of column     */
  SQLSMALLINT exec_iColScaling;                     /* scaling of column       */
  SQLSMALLINT exec_fColNullable;                    /* is column nullable?     */
  RETCODE result = 0;
  env* q_env = new_env ();
  caml_q_env = (value) q_env;

  /*  caml_q_env = alloc (sizeof(env*), Abstract_tag);
  Store_field (caml_q_env, 0, (value) q_env);
  */
  q_env->phEnv = (HENV *) (Long_val(v_phEnv));
  q_env->phDbc = (HDBC *) (Long_val(v_phDbc));

#ifdef DEBUG2
  printf("Appel de execDB cmd : %s\n", cmd);
  fflush(stdout);
#endif

  /*
  ** check parameter list
  */
  if( '\0' == cmd[0] 
      || q_env->phEnv == SQL_NULL_HENV 
      || q_env->phDbc == SQL_NULL_HDBC ) {
#ifdef DEBUG2
    printf("Erreur parametres\n");
    fflush(stdout);
#endif
    /* Allocation de la structure de retour */
    exec_res = Val_int ((int) -1);
    retour = alloc_tuple (2) ;
    Store_field (retour, 0, exec_res);
    Store_field (retour, 1, caml_q_env);
    CAMLreturn(retour);  
  }

  /*
  ** get statement handle
  */
  result = SQLAllocStmt( *(q_env->phDbc), &(q_env->exec_hstmt) );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLAllocStmt\n");
    fflush(stdout);
    displayError( *(q_env->phEnv), 
		  *(q_env->phDbc), 
		  q_env->exec_hstmt, 
		  result, __LINE__ );
#endif
    /* Allocation de la structure de retour */
    exec_res = Val_int ((int) result);
    retour = alloc_tuple (2) ;
    Store_field (retour, 0, exec_res);
    Store_field (retour, 1, caml_q_env);
    CAMLreturn(retour);
  }

  /*
  ** prepare statement
  */
  if( SQL_SUCCESS != (result=SQLPrepare(q_env->exec_hstmt, cmd, SQL_NTS)) ) {
#ifdef DEBUG2
    printf("Erreur SQLPrepare\n");
    printf("%s\n", cmd);
    fflush(stdout);
    displayError( *(q_env->phEnv), 
		  *(q_env->phDbc), 
		  q_env->exec_hstmt, 
		  result, __LINE__ );
#endif
    /* Allocation de la structure de retour */
    exec_res = Val_int ((int) result);
    retour = alloc_tuple (2) ;
    Store_field (retour, 0, exec_res);
    Store_field (retour, 1, caml_q_env);
    CAMLreturn(retour);
  }

  /*
  ** execute statement
  */
  if( SQL_SUCCESS != (result=SQLExecute(q_env->exec_hstmt)) ) {
#ifdef DEBUG2
    printf("Erreur SQLExecute\n");
    fflush(stdout);
    displayError( *(q_env->phEnv), 
		  *(q_env->phDbc), 
		  q_env->exec_hstmt, 
		  result, __LINE__ );
#endif
    /* Allocation de la structure de retour */
    exec_res = Val_int ((int) result);
    retour = alloc_tuple (2) ;
    Store_field (retour, 0, exec_res);
    Store_field (retour, 1, caml_q_env);
    CAMLreturn(retour);
  }
  /*
  ** get number of rows affected / columns returned
  */
  q_env->exec_iRowCount = 0;
  result = SQLRowCount(q_env->exec_hstmt, 
		       (SQLINTEGER FAR *) &(q_env->exec_iRowCount) );
#ifdef DEBUG2
  printf( "number of rows affected    : %d\n",
          (SQL_SUCCESS == result) ? q_env->exec_iRowCount
                               : -1
        );
#endif
  q_env->exec_iResColumns = 0;
  result = SQLNumResultCols(q_env->exec_hstmt,
			    (SWORD FAR *) &(q_env->exec_iResColumns) );
#ifdef DEBUG2
  printf( "number of columns returned : %d\n",
          (SQL_SUCCESS == result) ? q_env->exec_iResColumns
                               : -1
        );
#endif

  /*
  ** get table description and create list with pointers
  */
  if( 0 < q_env->exec_iResColumns )
  { 
#ifdef DEBUG2
    printf( "result columns:\n" );
#endif
    for( exec_ci = q_env->exec_iResColumns; 
	 exec_ci >=1; 
	 exec_ci-- )
      { 
	if( SQL_SUCCESS != (result=SQLDescribeCol( q_env->exec_hstmt, 
						   exec_ci, 
						   &(exec_szColName[0]),
						   sizeof(exec_szColName) - 1,
						   &(exec_cbColName), 
						   &(exec_fColType),
						   (UDWORD FAR *) &(exec_uiColPrecision),
						   &(exec_iColScaling), 
						   &(exec_fColNullable)
						   )
			    )
	    )
	  { 
#ifdef DEBUG2
	    printf("Erreur SQLDescribeCol\n");
	    fflush(stdout);
	    displayError( *(q_env->phEnv), 
			  *(q_env->phDbc), 
			  q_env->exec_hstmt, 
			  result, __LINE__ );
#endif
	    exec_res = Val_int(result);
	    retour = alloc_tuple (2) ;
	    Store_field (retour, 0, exec_res);
	    Store_field (retour, 1, caml_q_env);
	    CAMLreturn(retour);
	  }
	/*
	** create list with data entries
	*/
	(q_env->exec_pData)[exec_ci] = NULL;
	(q_env->exec_indicator)[exec_ci]=0;
	if( NULL == ((q_env->exec_pData)[exec_ci]=malloc((exec_uiColPrecision) +1)) )
	  {
	    result = -1;
	  }
	else
	  {
	    memset( (q_env->exec_pData)[exec_ci], 0, (exec_uiColPrecision) +1 );
	    result = SQLBindCol( q_env->exec_hstmt, 
				 exec_ci, 
				 SQL_C_CHAR, 
				 (q_env->exec_pData)[exec_ci],
				 (exec_uiColPrecision)+1, 
				 &(q_env->exec_indicator[exec_ci])
				 );
	  }
      }
  }

  /* on retourne 1 s'il n'y a pas de colonnes, ou 0 sinon */
  if ( 0 < q_env->exec_iResColumns )
    {
      exec_res = Val_int(0);
      retour = alloc_tuple (2) ;
      Store_field (retour, 0, exec_res);
      Store_field (retour, 1, caml_q_env);
      CAMLreturn(retour);
    }
  else
    { 
      exec_res = Val_int(1);
      retour = alloc_tuple (2) ;
      Store_field (retour, 0, exec_res);
      Store_field (retour, 1, caml_q_env);
      CAMLreturn(retour);
    }
}


/* itere_execDB_c : fonction récupérant un certain nombre
   d'enregistrements, pour la requête exécutée par la fonction
   execDB.
*/
value itere_execDB_c (value caml_q_env, value nb_records_ml) {
  CAMLparam2 (caml_q_env, nb_records_ml);
  CAMLlocal1 (exec_res);
  CAMLlocal1 (exec_string_list_list);
  CAMLlocal5 (exec_temp, exec_temp2, exec_l_head, exec_l_head2, exec_string_list);

  RETCODE result = 0;
  int i = 0;
  int exec_ci = 0;
  int at_least_one_row = 0; /* there is at least one row to return */
  int nb_records = Int_val (nb_records_ml);
  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env;

#ifdef DEBUG2
  printf( "itere_execDB_c start\n");
#endif     

  exec_l_head2 = Val_int(0);
  exec_string_list_list = exec_l_head2;
  exec_temp2 = Val_int(0);

#ifdef DEBUG2
  printf( "nb_records = %d\n", nb_records );
#endif     

  if (0 < q_env->exec_iResColumns )
    {
#ifdef DEBUG2
      printf( " 0 < q_env->exec_iResColumns \n" );
#endif      
      while (i < nb_records) {
	if (! ( SQL_SUCCESS           == (result=SQLFetch(q_env->exec_hstmt)) ||
		SQL_SUCCESS_WITH_INFO == result ))
	  {
	    break;
	  }
	else
	  {
	    at_least_one_row = 1;
#ifdef DEBUG2
	    printf( "  --> " );
#endif
	    exec_l_head = Val_int(0);

	    for( exec_ci = q_env->exec_iResColumns; exec_ci >= 1; exec_ci-- )
	      {
		exec_temp = alloc_tuple (2);
		Store_field (exec_temp, 1, exec_l_head);
		exec_l_head = exec_temp;

		if (q_env->exec_indicator[exec_ci] == SQL_NULL_DATA) {
#ifdef DEBUG2
		  printf ("NULL");
#endif
		  Store_field(exec_temp,0, copy_string("NULL"));
		}
		else {
#ifdef DEBUG2
		  printf( "'%s' ", (NULL == q_env->exec_pData[exec_ci]) ? 
			  "<ERROR>" : q_env->exec_pData[exec_ci] );
		  fflush( stdout );
#endif
		  Store_field(exec_temp, 0, 
			      copy_string((NULL == q_env->exec_pData[exec_ci]) ? 
					  "<ERROR>" : q_env->exec_pData[exec_ci]));
		}
	      } /* for */
#ifdef DEBUG2
	    printf( " <--\n" );
#endif
	    exec_string_list = exec_l_head;

	    exec_l_head2 = alloc_tuple (2);	    
	    Store_field (exec_l_head2, 0, exec_string_list);
	    Store_field (exec_l_head2, 1, Val_int(0));

	    if (exec_temp2 != Val_int(0) ) {
	      Store_field (exec_temp2, 1, exec_l_head2);
	    }
	    exec_temp2 = exec_l_head2;

	    if (exec_string_list_list == Val_int(0)) {
#ifdef DEBUG2
	      printf("on crée la tête\n");
#endif
	      exec_string_list_list = exec_temp2;
	    }
	    i++;
	  }
      } /* while */
    } /* if */
  else
    {}
  
  /*
  ** display last return code
  */
#ifdef DEBUG2
  switch( result )
    {
    case SQL_SUCCESS:           printf( "SQL_SUCCESS\n" );           break;
    case SQL_SUCCESS_WITH_INFO: printf( "SQL_SUCCESS_WITH_INFO\n" ); break;
    case SQL_ERROR:             printf( "SQL_ERROR\n" );
      displayError( *(q_env->phEnv), *(q_env->phDbc), q_env->exec_hstmt, result, __LINE__ );
      break;
    case SQL_INVALID_HANDLE:    printf( "SQL_INVALID_HANDLE\n" );     break;
    case SQL_NO_DATA_FOUND:     printf( "SQL_NO_DATA_FOUND\n" );      break;
    default:                    printf( "unknown result = %d\n", result );
    } /* switch */
  printf("avant retour de itere_2\n");
#endif

  /* on renvoie le nombre de records retournés */
  exec_res = alloc_tuple(2);
  Store_field(exec_res,0,Val_int (i));
#ifdef DEBUG2
  printf("avant retour de itere_2bis\n"); 
#endif
  Store_field(exec_res,1, exec_string_list_list);
#ifdef DEBUG2
  printf("avant retour de itere_2ter\n");
#endif
  CAMLreturn(exec_res);
}

/* Fonction prenant un code de type SQL et retournant la constante
   correspondant au bon constructeur OCaml. */
int get_OCaml_SQL_type_code (int code)
{
  switch (code)
    {
    case SQL_CHAR: return (OCAML_SQL_CHAR);
    case SQL_BINARY: return (OCAML_SQL_BINARY);
    case SQL_DATE: return (OCAML_SQL_DATE);
    case SQL_DECIMAL: return (OCAML_SQL_DECIMAL);
    case SQL_DOUBLE: return (OCAML_SQL_DOUBLE);
    case SQL_FLOAT: return (OCAML_SQL_FLOAT);
    case SQL_INTEGER: return (OCAML_SQL_INTEGER);
    case SQL_LONGVARCHAR: return (OCAML_SQL_LONGVARCHAR);
    case SQL_LONGVARBINARY: return (OCAML_SQL_LONGVARBINARY);
    case SQL_NUMERIC: return (OCAML_SQL_NUMERIC);
    case SQL_REAL: return (OCAML_SQL_REAL);
    case SQL_SMALLINT: return (OCAML_SQL_SMALLINT);
    case SQL_TIME: return (OCAML_SQL_TIME);
    case SQL_TIMESTAMP: return (OCAML_SQL_TIMESTAMP);
    case SQL_VARCHAR: return (OCAML_SQL_VARCHAR);
    case SQL_VARBINARY: return (OCAML_SQL_VARBINARY);
    default: return (OCAML_SQL_UNKNOWN);
  }

}

/* Fonction retournant la liste des couples (nom, type)
pour chaque champ retourné par la dernière requête exécutée
et non encore libérée. */
value get_infoDB_c(value caml_q_env, value v_phEnv, value v_phDbc)
{ 
  CAMLparam2 (v_phEnv, v_phDbc);
  CAMLlocal2 (info_temp, info_l_head);
  CAMLlocal1 (info_cpl);
  int exec_ci = 0;
  SQLCHAR     exec_szColName[COLUMN_SIZE];          /* name of column          */
  SQLSMALLINT exec_cbColName;                       /* length of column name   */
  SQLSMALLINT exec_fColType;                        /* type of column          */
  SQLUINTEGER exec_uiColPrecision;                  /* precision of column     */
  SQLSMALLINT exec_iColScaling;                     /* scaling of column       */
  SQLSMALLINT exec_fColNullable;                    /* is column nullable?     */
  RETCODE result = 0;

  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env ;

#ifdef DEBUG2
  printf("Appel de get_infoDB cmd :\n");
  fflush(stdout);
#endif

  /*
  ** check parameter list
  */
  if( (q_env->phEnv) == SQL_NULL_HENV || (q_env->phDbc) == SQL_NULL_HDBC ) {
#ifdef DEBUG2
    printf("Erreur paramètres\n");
    fflush(stdout);
#endif
    /* On retourne une liste vide */
    info_l_head = Val_int (0);
    CAMLreturn(info_l_head);  
  }

  /*
  ** get table description and create list with pointers
  */
  if( 0 < q_env->exec_iResColumns )
  { 
#ifdef DEBUG2
    printf( "result columns:\n" );
#endif
    /* Initialisation de la liste des descriptions de colonnes */
    info_l_head = Val_int(0);
    
    for( exec_ci = q_env->exec_iResColumns; exec_ci >=1; exec_ci-- )
    { /*
      ** display table info
      */
#ifdef DEBUG2
      printf( "  [%03u] ", exec_ci ); fflush( stdout );
#endif
      if( SQL_SUCCESS != (result=SQLDescribeCol(q_env->exec_hstmt, 
						exec_ci, 
						&(exec_szColName[0]),
						sizeof(exec_szColName) - 1,
						&(exec_cbColName), 
						&(exec_fColType),
						(UDWORD FAR *) &(exec_uiColPrecision),
						&(exec_iColScaling), 
						&(exec_fColNullable)
                                            )
                          )
         ) { 
#ifdef DEBUG2
	printf("Erreur SQLDescribeCol\n");
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
      printf( "%s type=", exec_szColName );
      switch( exec_fColType )
	{
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
      Store_field (info_cpl, 0, copy_string (exec_szColName));
      Store_field (info_cpl, 1, Val_int(get_OCaml_SQL_type_code ((int)exec_fColType)));
      Store_field (info_temp, 0, info_cpl);
      Store_field (info_temp, 1, info_l_head);
      info_l_head = info_temp;
    }
#ifdef DEBUG2
    printf("Point N\n");
#endif
    CAMLreturn(info_l_head);
  } /* if */

}


/* free_ExecDB_c : fonction de désallocation des structures allouées par 
   execDB_c */
void free_execDB_c (value caml_q_env) {
  int result;
  int exec_ci = 0;
  /*env* q_env = (env*) Field (caml_q_env, 0);*/
  env* q_env = (env*) caml_q_env ;
#ifdef DEBUG2
  printf( "free_execDB_c start\n");
#endif   
    /*
    ** free allocated memory
    */
  for( exec_ci = 1 ;
	 exec_ci <= q_env->exec_iResColumns; 
	 exec_ci++ )
    { 
#ifdef DEBUG2
      fprintf(stderr, "free for exe_ci = %d\n", exec_ci);
      fflush(stderr);
      if (q_env->exec_pData[0] == NULL) {
	fprintf(stderr, "(q_env->exec_pData[0] == NULL)\n");
	fflush(stderr);
      }
      else
	{
	fprintf(stderr, "(q_env->exec_pData[0] != NULL)\n");
	fflush(stderr);
	}
#endif

      free( q_env->exec_pData[exec_ci] );
#ifdef DEBUG2
      fprintf(stderr, "free( q_env->exec_pData[%d] ) Ok\n", exec_ci);
      fflush(stderr);
#endif
      q_env->exec_pData[exec_ci] = NULL;
    } /* for */
#ifdef DEBUG2
  fprintf(stderr, "free\n");
  fflush(stderr);
#endif
  /*
  ** free statement handle
  */
  result = SQLFreeStmt(q_env->exec_hstmt, SQL_DROP );
  if( SQL_SUCCESS != result ) {
#ifdef DEBUG2
    printf("Erreur SQLFreeStmt\n");
    fflush(stdout);
    displayError( *(q_env->phEnv),
		  *(q_env->phDbc), 
		  q_env->exec_hstmt, 
		  result, __LINE__ );
    
#endif
  }
  free(q_env);
#ifdef DEBUG2
  fprintf(stderr, "fin free_execDB_c\n");
  fflush(stderr);
#endif
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
  SQLCHAR           szSqlState[ 8 /*SQL_SQLSTATE_SIZE*/ ];       /* statement buf. */
  SQLINTEGER        iSqlCode;                              /* return code    */
  SQLSMALLINT       iLength;                               /* return length  */

  /*---| program |---*/
  /*
  ** display native error code
  */
  /* fprintf( stderr, "\a-----------------------\n" ); */
  fprintf( stderr, "-----------------------\n" );
  fprintf( stderr, "SQL error              : %d\n", iRC );
  fprintf( stderr, "line number            : %d\n", iLineNum );

  /*
  ** display all error messages corresponding to this code
  */
  while( SQL_SUCCESS == SQLError( hEnv, hDbc, hStmt, szSqlState,
                                  &iSqlCode, szBuffer,
                                  SQL_MAX_MESSAGE_LENGTH - 1, &iLength
                                )
       )
  {
    fprintf( stderr, "SQL state              : %s\n", szSqlState );
    fprintf( stderr, "native error code      : %ld\n", iSqlCode );
    fprintf( stderr, "%s\n", szBuffer );
  } /* while */

  fprintf( stderr, "-----------------------\n" );
  /* fprintf( stderr, "\a-----------------------\n" ); */

} /* displayError */
