(*[Mo] This module contains the context class, used to
   load, write and manage the history of queries.[Mo]*)


(*[Cl] This class is used to manage the history of queries
   and provide access to the database
   through  all the application.[Cl]*)
class context (base : string) (db : Ocamlodbc.data_base) =
  object (self)
    (*[At] The name of the history file. [At]*)
    val history_file = 
      Filename.concat Biniki_messages.home Biniki_messages.history_file

    (*[At] The history of queries.[At]*)
    val mutable history_queries = ([] : string list)

    (*[Me] Access to the history of queries. [Me]*)
    method history_queries = history_queries

    (*[Me] This method adds a query to the history. [Me]*)
    method add_query s = 
      let s2 = Biniki_misc.remove_trailing_spaces s in
      if List.mem s2 history_queries then
	()
      else
	(
	 history_queries <- s :: history_queries;
	 try
	   Biniki_misc.output_string_list history_file history_queries
	 with
	   Failure s ->
	     Biniki_misc.message_box Biniki_messages.mErreur s
	)

    (*[Me] Access to the database. [Me]*)
    method database = db 

    (*[Me] Access to the database name. [Me]*)
    method base = base

    initializer
      (* we must read the list of queries in the history file *)
      try
	history_queries <- Biniki_misc.input_string_list history_file
      with
	Failure s ->
	  (* couldn't read the history file *)
	  Biniki_misc.message_box Biniki_messages.mErreur s
  end
