(** Interface to databases. *)

(** To report errors. *)
exception SQL_Error of string


(** The various SQL types for columns. *)
type sql_column_type =
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

(** The type of connections to databases. *)
type connection
          
(** [create base user passwd] creates a connection to data source
   [base], as user [user], with password [passwd]. 
   @raise SQL_Error if we could not connect to the database.*)
val connect : string -> string -> string -> connection

(** Disconnect from a database. The given connection should not be used
   after this function was called.
   @raise SQL_Error if an error occured while disconnecting.*)
val disconnect : connection -> unit

(** [execute c q] executes query [q] through connection [c] and 
   returns the result as a pair [(error_code, recordlist)], 
   where a record is a [string list]. The [error_code] is 0
   if no error occured.*)
val execute : connection -> string -> int * string list list

(* [execute_with_info c q] executes query [q] through connection [c] and 
   returns the result as a tuple [(error_code, type_list, record list)], 
   where [type_list] indicates the SQL types of the returned columns,
   and a record is a [string list]. 
   The [error_code is] 0 if no error occured.*)
val execute_with_info :
    connection -> string -> int * (string * sql_column_type) list * string list list


(** Object-oriented interface *)

(* The class which represents a connection to a database. 
   The connection occurs when the object is created.
   @raise SQL_Error if an error occured during the connection to the database.*)
class data_base :
  string ->
  string ->
  string ->
  object
    (** @deprecated The connection to the database oocurs when the object is created.*)
    method connect : unit -> unit

    (** Disconnect from the database. The objet should not be used after calling this method.
       @raise SQL_Error if an error occurs while disconnecting.*)
    method disconnect : unit -> unit

    (** [#execute q] executes query [q] and 
       returns the result as a pair [(error_code, recordlist)], 
       where a record is a [string list]. The [error_code] is 0
       if no error occured.*)
    method execute : string -> int * (string list list)

    (* [#execute_with_info q] executes query [q] and 
       returns the result as a tuple [(error_code, type_list, record list)], 
       where [type_list] indicates the SQL types of the returned columns,
       and a record is a [string list]. 
       The [error_code is] 0 if no error occured.*)
    method execute_with_info : string -> int * ((string * sql_column_type) list) * (string list list)
  end


