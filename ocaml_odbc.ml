(* Definitions des types abstraits                       *)

type sQLHENV
type sQLHDBC
type env

module type Sql_column_type =
  sig
    type t
    val string : t -> string
  end

module Interface (Sql_col : Sql_column_type) =
  struct
    (*  Constructeurs des types abstraits (valeur vide) *)
    external value_SQLHENV : unit -> sQLHENV = "value_HENV_c" 
    external value_SQLHDBC : unit -> sQLHDBC = "value_HDBC_c"

    (*  Fonctions C utilisées *)
    external initDB : string -> string -> string -> (int*sQLHENV*sQLHDBC) = "initDB_c"
    external execDB : sQLHENV -> sQLHDBC -> string -> int * env = "execDB_c"
    external itereDB : env -> int -> (int*string list list) = "itere_execDB_c"
    external free_execDB : env -> unit = "free_execDB_c"
    external get_infoDB : env -> sQLHENV -> sQLHDBC -> (string * Sql_col.t) list = "get_infoDB_c"
    external exitDB : sQLHENV -> sQLHDBC -> int = "exitDB_c"
  end



