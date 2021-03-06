#############################################################################
#             OCamlODBC                                                     #
#                                                                           #
# Copyright (C) 2004-2011 Institut National de Recherche en Informatique    #
# et en Automatique. All rights reserved.                                   #
#                                                                           #
# This program is free software; you can redistribute it and/or modify      #
# it under the terms of the GNU Lesser General Public License as published  #
# by the Free Software Foundation; either version 2.1 of the License, or    #
# any later version.                                                        #
#                                                                           #
# This program is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
# GNU Lesser General Public License for more details.                       #
#                                                                           #
# You should have received a copy of the GNU Lesser General Public License  #
# along with this program; if not, write to the Free Software               #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                  #
# 02111-1307  USA                                                           #
#                                                                           #
# Contact: Maxence.Guesdon@inria.fr                                         #
#############################################################################

AC_INIT(odbc, 3.0, Christophe.Troestler@umons.ac.be)

AC_MSG_RESULT([Configuring $PACKAGE_STRING])

AC_CONFIG_MACRO_DIR([m4])

# Check for Ocaml compilers
AC_PROG_OCAML
if test "$OCAMLC" = "no"; then
  AC_MSG_ERROR([You must install the OCaml compiler])
fi
if test "$OCAMLMKLIB" = "no" ; then
  AC_MSG_ERROR(Cannot find ocamlmklib)
fi

# Check for databases

AC_PROG_CC()

############ POSTGRES ##################
POSTGRES=yes
POSTGRES_LIBS=no
AC_MSG_RESULT(======== configure PostgreSQL ========)
AC_ARG_WITH(pg_incs, [  --with-pg-incs=INCLUDES (-I options to find PostgreSQL ODBC headers)],
    if test "$withval" != "no" ; then  
	POSTGRES_INCS="$withval"
    else
        POSTGRES_INCS=""
    fi)
AC_ARG_WITH(pg_libs, [  --with-pg-libs=DIRS (-L options to find PostgreSQL ODBC libs)],
    if test "$withval" != "no" ; then  
	POSTGRES_LIBDIRS="$withval"
    else
        POSTGRES_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $POSTGRES_INCS $POSTGRES_LIBDIRS"

AC_CHECK_HEADERS(iodbc.h,,[POSTGRES=no])
AC_CHECK_HEADERS(isql.h,,[POSTGRES=no])
AC_CHECK_HEADERS(isqlext.h,,[POSTGRES=no])
if test "$POSTGRES" = "no"; then
  AC_MSG_RESULT(PostgreSQL ODBC headers not found)
else
  AC_MSG_RESULT(PostgreSQL ODBC headers found)
  dnl Checking for PostgreSQL ODBC lib -lpsqlodbc
  AC_CHECK_LIB(psqlodbc,SQLAllocEnv,POSTGRES_LIBS=-lpsqlodbc)
fi
if test "$POSTGRES_LIBS" = "no"; then
  AC_MSG_RESULT(No PostgreSQL ODBC support)
else
  AC_MSG_RESULT(PostgreSQL ODBC support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED postgres"
fi

CPP_FLAGS="$OLD_CPPFLAGS"

############ MYSQL ##################
MYSQL=yes
MYSQL_LIBS=no
AC_MSG_RESULT(======== configure MySQL ========)
AC_ARG_WITH(mysql_incs, [  --with-mysql-incs=INCLUDES (-I options to find MySQL ODBC headers)],
    if test "$withval" != "no" ; then  
	MYSQL_INCS="$withval"
    else
        MYSQL_INCS=""
    fi)
AC_ARG_WITH(mysql_libs, [  --with-mysql-libs=DIRS (-L options to find MySQL ODBC libs)],
    if test "$withval" != "no" ; then  
	MYSQL_LIBDIRS="$withval"
    else
        MYSQL_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $MYSQL_INCS $MYSQL_LIBDIRS"

AC_CHECK_HEADERS(iodbc.h,,[MYSQL=no])
AC_CHECK_HEADERS(isql.h,,[MYSQL=no])
AC_CHECK_HEADERS(isqlext.h,,[MYSQL=no])
if test "$MYSQL" = "no"; then
  AC_MSG_RESULT(MySQL ODBC headers not found)
else
  AC_MSG_RESULT(MySQL ODBC headers found)
  dnl Checking for MySQL ODBC lib -lmyodbc_mysql
  AC_CHECK_LIB(myodbc_mysql,SQLAllocEnv,MYSQL_LIBS=-lmyodbc_mysql)
fi
if test "$MYSQL_LIBS" = "no"; then
  AC_MSG_RESULT(No MySQL ODBC support)
else
  AC_MSG_RESULT(MySQL ODBC support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED mysql"
fi

CPP_FLAGS="$OLD_CPPFLAGS"

############ UNIXODBC ##################
UNIXODBC=yes
UNIXODBC_LIBS=no
AC_MSG_RESULT(======== configure unixODBC ========)
AC_ARG_WITH(unixodbc_incs, [  --with-unixodbc-incs=INCLUDES (-I options to find unixODBC headers)],
    if test "$withval" != "no" ; then  
	UNIXODBC_INCS="$withval"
    else
        UNIXODBC_INCS=""
    fi)
AC_ARG_WITH(unixodbc_libs, [  --with-unixodbc-libs=DIRS (-L options to find unixODBC libs)],
    if test "$withval" != "no" ; then  
	UNIXODBC_LIBDIRS="$withval"
    else
        UNIXODBC_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $UNIXODBC_INCS $UNIXODBC_LIBDIRS"

AC_CHECK_HEADERS(odbcinst.h,,[UNIXODBC=no])
AC_CHECK_HEADERS(sql.h,,[UNIXODBC=no])
AC_CHECK_HEADERS(sqlext.h,,[UNIXODBC=no])
if test "$UNIXODBC" = "no"; then
  AC_MSG_RESULT(unixODBC headers not found)
else
  AC_MSG_RESULT(unixODBC headers found)
  dnl Checking for unixODBC lib -lodbc
  AC_CHECK_LIB(odbc,SQLAllocEnv,UNIXODBC_LIBS=-lodbc)
fi
if test "$UNIXODBC_LIBS" = "no"; then
  AC_MSG_RESULT(No unixODBC support)
else
  AC_MSG_RESULT(unixODBC support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED unixodbc"
fi

CPP_FLAGS="$OLD_CPPFLAGS"

############ DB2 ##################
DB2=yes
DB2_LIBS=no
AC_MSG_RESULT(======== configure DB2 ========)
AC_ARG_WITH(db2_incs, [  --with-db2-incs=INCLUDES (-I options to find DB2 headers)],
    if test "$withval" != "no" ; then  
	DB2_INCS="$withval"
    else
        DB2_INCS=""
    fi)
AC_ARG_WITH(db2_libs, [  --with-db2-libs=DIRS (-L options to find DB2 libs)],
    if test "$withval" != "no" ; then  
	DB2_LIBDIRS="$withval"
    else
        DB2_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $DB2_INCS $DB2_LIBDIRS"

AC_CHECK_HEADERS(sqlcli1.h,,[DB2=no])
if test "$DB2" = "no"; then
  AC_MSG_RESULT(DB2 headers not found)
else
  AC_MSG_RESULT(DB2 headers found)
  dnl Checking for DB2 lib -ldb2
  AC_CHECK_LIB(db2,SQLAllocEnv,DB2_LIBS=-ldb2)
fi
if test "$DB2_LIBS" = "no"; then
  AC_MSG_RESULT(No DB2 support)
else
  AC_MSG_RESULT(DB2 support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED db2"
fi

CPP_FLAGS="$OLD_CPPFLAGS"

############ OPENINGRES ##################
OPENINGRES=yes
OPENINGRES_LIBS=no
AC_MSG_RESULT(======== configure OPENINGRES ========)
AC_ARG_WITH(db2_incs, [  --with-ingres-incs=INCLUDES (-I options to find OPENINGRES headers)],
    if test "$withval" != "no" ; then  
	OPENINGRES_INCS="$withval"
    else
        OPENINGRES_INCS=""
    fi)
AC_ARG_WITH(db2_libs, [  --with-ingres-libs=DIRS (-L options to find OPENINGRES libs)],
    if test "$withval" != "no" ; then  
	OPENINGRES_LIBDIRS="$withval"
    else
        OPENINGRES_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $OPENINGRES_INCS $OPENINGRES_LIBDIRS"

AC_CHECK_HEADERS(sqlext.h,,[OPENINGRES=no])
if test "$OPENINGRES" = "no"; then
  AC_MSG_RESULT(OPENINGRES headers not found)
else
  AC_MSG_RESULT(OPENINGRES headers found)
  dnl Checking for OPENINGRES lib -lodbc
  AC_CHECK_LIB(odbc,SQLAllocEnv,OPENINGRES_LIBS=-lodbc)
fi
if test "$OPENINGRES_LIBS" = "no"; then
  AC_MSG_RESULT(No OPENINGRES support)
else
  AC_MSG_RESULT(OPENINGRES support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED openingres"
fi

CPP_FLAGS="$OLD_CPPFLAGS"

############ ORACLE through DataDirect "Connect for ODBC" driver  ##################
ORACLECFO=yes
ORACLECFO_LIBS=no
AC_MSG_RESULT(======== configure ORACLE through DataDirect "Connect for ODBC" driver ========)
AC_ARG_WITH(oraclecfo_incs, [  --with-oraclecfo-incs=INCLUDES (-I options to find Connect for ODBC headers)],
    if test "$withval" != "no" ; then  
	ORACLECFO_INCS="$withval"
    else
        ORACLECFO_INCS=""
    fi)
AC_ARG_WITH(oraclecfo_libs, [  --with-oraclecfo-libs=DIRS (-L options to find Connect for ODBC libs)],
    if test "$withval" != "no" ; then  
	ORACLECFO_LIBDIRS="$withval"
    else
        ORACLECFO_LIBDIRS=""
    fi)
OLD_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $ORACLECFO_INCS $ORACLECFO_LIBDIRS"

AC_CHECK_HEADERS(sqlcli_.h,,[ORACLECFO=no])
if test "$ORACLECFO" = "no"; then
  AC_MSG_RESULT(ORACLECFO headers not found)
else
  AC_MSG_RESULT(ORACLECFO headers found)
  dnl Checking for ORACLECFO lib -lodbc
  AC_CHECK_LIB(odbc,SQLAllocEnv,ORACLECFO_LIBS=-lodbc)
fi
if test "$ORACLECFO_LIBS" = "no"; then
  AC_MSG_RESULT(No Oracle through DataDirect "Connect for ODBC" driver support)
else
  AC_MSG_RESULT(Oracle through DataDirect "Connect for ODBC" driver support)
  DATABASES_INSTALLED="$DATABASES_INSTALLED oracle"
fi

CPP_FLAGS="$OLD_CPPFLAGS"


# Check for OCaml libraries

AC_CHECK_OCAML_PKG([lablgtk2])
if test "$OCAML_PKG_lablgtk2" = "no"; then
  AC_MSG_WARN([Biniki will not be compiled.])
fi

# substitutions to perform
AC_SUBST(PACKAGE_NAME)
AC_SUBST(PACKAGE_VERSION)
AC_SUBST(OCAMLC)
AC_SUBST(OCAMLOPT)
AC_SUBST(OCAMLDEP)
AC_SUBST(OCAMLLEX)
AC_SUBST(OCAMLYACC)
AC_SUBST(OCAMLBEST)
AC_SUBST(OCAMLVERSION)
AC_SUBST(OCAMLLIB)
AC_SUBST(OCAMLDOC)
AC_SUBST(OCAMLBIN)

AC_SUBST(DATABASES_INSTALLED)
AC_SUBST(CC)

AC_SUBST(POSTGRES_INCS)
AC_SUBST(POSTGRES_LIBDIRS)
AC_SUBST(POSTGRES_LIBS)

AC_SUBST(MYSQL_INCS)
AC_SUBST(MYSQL_LIBDIRS)
AC_SUBST(MYSQL_LIBS)

AC_SUBST(UNIXODBC_INCS)
AC_SUBST(UNIXODBC_LIBDIRS)
AC_SUBST(UNIXODBC_LIBS)

AC_SUBST(DB2_INCS)
AC_SUBST(DB2_LIBDIRS)
AC_SUBST(DB2_LIBS)

AC_SUBST(OPENINGRES_INCS)
AC_SUBST(OPENINGRES_LIBDIRS)
AC_SUBST(OPENINGRES_LIBS)

AC_SUBST(ORACLECFO_INCS)
AC_SUBST(ORACLECFO_LIBDIRS)
AC_SUBST(ORACLECFO_LIBS)

AC_CONFIG_FILES([META],[chmod a-w META])
AC_CONFIG_FILES([Makefile.master],[chmod a-w Makefile.master])
AC_CONFIG_FILES([opam/opam],[chmod a-w opam/opam])
AC_OUTPUT
