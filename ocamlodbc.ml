(* *)

(* Nom du logiciel. *)
let logiciel = "OCamlODBC"

(* Version du logiciel. *)
let version = "2.4"

exception SQL_Error of string

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
;;

(* Le module pour les types de colonne SQL *)
module SQL_column =
  struct
    type t = sql_column_type
    let string col_type = 
      match col_type with
	SQL_unknown -> "SQL_unknown"
      | SQL_char -> "SQL_char"
      | SQL_numeric -> "SQL_numeric" 
      |	SQL_decimal -> "SQL_decimal"
      | SQL_integer -> "SQL_integer"
      | SQL_smallint -> "SQL_smallint" 
      | SQL_float -> "SQL_float"
      | SQL_real -> "SQL_real"
      | SQL_double -> "SQL_double"
      | SQL_varchar -> "SQL_varchar"
      | SQL_date -> "SQL_date"
      | SQL_time -> "SQL_time"
      | SQL_timestamp -> "SQL_timestamp"
      | SQL_longvarchar -> "SQL_longvarchar"
      | SQL_binary -> "SQL_binary"
      | SQL_varbinary -> "SQL_varbinary"
      | SQL_longvarbinary -> "SQL_longvarbinary"
      | SQL_bigint -> "SQL_bigint"
      | SQL_tinyint -> "SQL_tinyint"
      | SQL_bit -> "SQL_bit"
  end;;

(* Le module d'interface utilisant notre définition de type de colonne SQL *)
module SQLInterface = Ocaml_odbc.Interface (SQL_column);;

(* [Mo] Ce module contient les messages utilisateurs [Mo] *)
(* suceptible de devenir un fichier avec le nom du logiciel et la version *)
module OCamlODBC_messages =
  struct
    let disconnect = "ODBC : problem while disconnecting"
    let connection nom_base nom_user pzPasswd iRC1 = "Error while connecting to database "^nom_base^" as "^nom_user^" with password <"^pzPasswd^"> : "^(string_of_int iRC1)
  end

(** Classic interface. *)
type connection =
    {
      phEnv : Ocaml_odbc.sQLHENV ;
      phDbc : Ocaml_odbc.sQLHDBC ;
      base : string ;
      user : string ;
      passwd : string ;
    } 

(* Create a connection with a database. 
   @raise SQL_Error if we could not connect to the database.*)
let connect base user passwd =
  let (iRC1,hEnv,pHDbc) = SQLInterface.initDB base user passwd in
  if (iRC1 = 0) then 
    {
      phEnv = hEnv;
      phDbc = pHDbc;
      base = base ;
      user = user ;
      passwd = passwd ;
    } 
  else
    raise (SQL_Error (OCamlODBC_messages.connection base user passwd iRC1))

let disconnect connection = 
  let iRC = (SQLInterface.exitDB connection.phEnv connection.phDbc) in
  if (iRC > 0) then 
    raise (SQL_Error OCamlODBC_messages.disconnect)
  else 
    ()

(* Cette fonction privée exécute une requête interrompue par des appels
   réguliers au GC. Elle retourne un triplet : code d'erreur (0 si ok),
   liste de couples (nom, type) pour décrire les colonnes retournées,
   liste de liste de chaines représentant les enregistrements.
*)
let pv_execute connection ?(get_info=false) req = 
  if req = "" then
    (-1, ([] : (string * sql_column_type) list), [])
  else
    (
     let phEnv = connection.phEnv in
     let phDbc = connection.phDbc in
     let (ret, env) = SQLInterface.execDB phEnv phDbc req in
     match ret with
       0 ->
	 let l_desc_col = 
	   if get_info then
             (* récupérer les informations sur les champs retournés
		(nom et type) par la dernière requête exécutée *)
	     SQLInterface.get_infoDB env phEnv phDbc
	   else
	     []
	 in
         (* récupérer les records en plusieurs fois *)
	 (
	  let cpt = ref 0 in
	  let rec iter () = 
	    let nb_rec = 40 in
	    let (n, ll_res) = SQLInterface.itereDB env nb_rec in
	    cpt := !cpt + n;
	    (*Gc.minor();*)
	    if n < nb_rec then
	      ll_res
	    else
	      ll_res@(iter ())
	  in
	  let l = iter () in
	  let _ = SQLInterface.free_execDB env in
	  (ret, l_desc_col, l)
      	 )

     | 1 ->
	 (* pas de colonne, donc pas d'enregistrements à récupérer *)
	 let _ = SQLInterface.free_execDB env in
	 (0, [], [])
     | _ ->
	 let _ = SQLInterface.free_execDB env in
	 (ret, [], ([] : string list list))
    )

(* Cette fonction prend une requête sous forme de chaine
   de caractères, exécute la requête et retourne un couple
   (code d'erreur (0 si ok), liste de liste de chaines).*)
let execute connection req =
  let (c, _, l) = pv_execute connection req in
  (c, l)

(* Cette fonction prend une requête sous forme de chaine
   de caractères, exécute la requête et retourne un triplet
   (code d'erreur (0 si ok), liste de couples (nom, type)
   décrivant les colonnes, liste de liste de chaines).*)
let execute_with_info connection req =
  pv_execute connection ~get_info: true req

(** Object-oriented interface. *)

(* 
   @param base the database to connect to
   @param user the user to use when connecting
   @param passwd the password to use when connecting, can be [""]
*)
class data_base base user passwd =
  object (self)
    (* The connection, initialized when the object is created. *)
    val connection = connect base user passwd
    (* The flag to indicates whether we are connected or not,
       used not to disconnect more than once.*)
    val mutable connected = true

    method connect () = ()

    method disconnect () = 
      if connected then
	(
	 connected <- false;
	 disconnect connection
	)
	
    method execute req = execute connection req

    method execute_with_info req = pv_execute connection ~get_info: true req

  end
