(* Interface to databases. *)

exception SQL_Error of string
    (* To report errors. *)

type sql_column_type =
    (* The various SQL types for columns. *)
  | SQL_unknown
  | SQL_char
  | SQL_numeric
  | SQL_decimal
  | SQL_integer
  | SQL_smallint
  | SQL_float
  | SQL_real
  | SQL_double
  | SQL_varchar
  | SQL_date
  | SQL_time
  | SQL_timestamp
  | SQL_longvarchar
  | SQL_binary
  | SQL_varbinary
  | SQL_longvarbinary
  | SQL_bigint
  | SQL_tinyint
  | SQL_bit

      
module SQL_column :
    sig 
      type t = sql_column_type 
      val string : sql_column_type -> string 
    end

(** Classic interface *)

type connection
    (* The type of connections to databases. *)
      
val connect : string -> string -> string -> connection
    (* [create base user passwd] creates a connection to data source
       [base], as user [user], with password [passwd]. 
       @raise SQL_Error if we could not connect to the database.*)

val disconnect : connection -> unit
    (* Disconnect from a database. The given connection should not be used
       after this function was called.
       @raise SQL_Error if an error occured while disconnecting.*)

val execute : connection -> string -> int * string list list
    (* [execute c q] executes query [q] through connection [c] and 
       returns the result as a pair [(error_code, recordlist)], 
       where a record is a [string list]. The [error_code] is 0
       if no error occured.*)

val execute_with_info :
    connection -> string -> int * (string * sql_column_type) list * string list list
    (* [execute_with_info c q] executes query [q] through connection [c] and 
       returns the result as a tuple [(error_code, type_list, record list)], 
       where [type_list] indicates the SQL types of the returned columns,
       and a record is a [string list]. 
       The [error_code is] 0 if no error occured.*)


(** Object-oriented interface *)

class data_base :
  string ->
  string ->
  string ->
  object
    method connect : unit -> unit
	(* @deprecated The connection to the database oocurs when the object is created.*)

    method disconnect : unit -> unit
	(* Disconnect from the database. The objet should not be used after calling this method.
	   @raise SQL_Error if an error occurs while disconnecting.*)

    method execute : string -> int * (string list list)
	(* [#execute q] executes query [q] and 
	   returns the result as a pair [(error_code, recordlist)], 
	   where a record is a [string list]. The [error_code] is 0
	   if no error occured.*)

    method execute_with_info : string -> int * ((string * sql_column_type) list) * (string list list)
	(* [#execute_with_info q] executes query [q] and 
	   returns the result as a tuple [(error_code, type_list, record list)], 
	   where [type_list] indicates the SQL types of the returned columns,
	   and a record is a [string list]. 
	   The [error_code is] 0 if no error occured.*)
  end
      (* The class which represents a connection to a database. 
	 The connection occurs when the object is created.
	 @raise SQL_Error if an error occured during the connection to the database.*)


