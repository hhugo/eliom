(* Ocsigen
 * http://www.ocsigen.org
 * Copyright (C) 2007 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)


open Eliom_lib

(** Type of names in a form *)
type 'a param_name = string

(** empty type used when it is not possible to use the parameter in a form *)
type no_param_name

type ('a,'b) binsum = Inj1 of 'a | Inj2 of 'b;;

type 'an listnames =
    {it:'el 'a. ('an -> 'el -> 'a -> 'a) -> 'el list -> 'a -> 'a}

type coordinates =
    {abscissa: int;
     ordinate: int}

type 'a setoneradio = [ `Set of 'a | `One of 'a | `Radio of 'a ]
type 'a oneradio = [ `One of 'a | `Radio of 'a ]
type 'a setone = [ `Set of 'a | `One of 'a ]

type 'a to_and_from = {
  of_string : string -> 'a;
  to_string : 'a -> string
}

type _ atom =
  | TFloat     : float atom
  | TInt       : int atom
  | TInt32     : int32 atom
  | TInt64     : int64 atom
  | TNativeint : nativeint atom
  | TBool      : bool atom
  | TString    : string atom

let string_of_atom (type a) (p : a atom) : (a -> string) = match p with
  | TFloat  -> string_of_float
  | TInt    -> string_of_int
  | TInt32  -> Int32.to_string
  | TInt64  -> Int64.to_string
  | TNativeint -> Nativeint.to_string
  | TBool   -> string_of_bool
  | TString -> (fun s -> s)

let atom_of_string (type a) (p : a atom) : (string -> a) = match p with
  | TFloat  -> float_of_string
  | TInt    -> int_of_string
  | TInt32  -> Int32.of_string
  | TInt64  -> Int64.of_string
  | TNativeint -> Nativeint.of_string
  | TBool   -> bool_of_string
  | TString -> (fun s -> s)

let to_from_of_atom x =
  {to_string=string_of_atom x;
   of_string=atom_of_string x}

type 'a filter = ('a -> unit) option

type raw = (((string * string) * (string * string) list) option * string Ocsigen_stream.t option)
type 'a caml = string (* marshaled values of type 'a *)

type suff = [ `WithoutSuffix | `WithSuffix | `Endsuffix ]

type (_,_,_) params_type =
  | TProd : ( ('a, [`WithoutSuffix], 'an) params_type * ('b, [<`WithoutSuffix|`Endsuffix] as 'e, 'bn) params_type) -> (('a * 'b),'e, 'an * 'bn) params_type
  | TOption : (('a,[`WithoutSuffix],'an) params_type * bool) -> ('a option,[`WithoutSuffix], 'an) params_type
  | TList : (string * ('a, [`WithoutSuffix], 'an) params_type) -> ('a list, [`WithoutSuffix], 'an listnames) params_type
  | TSet : ('a, [`WithoutSuffix], [ `One of 'an ] param_name) params_type ->  ('a list, [`WithoutSuffix], [ `Set of 'an ] param_name) params_type
  | TSum : (('a, [`WithoutSuffix], 'an) params_type * ('b,[`WithoutSuffix], 'bn) params_type) -> (('a,'b) binsum, [`WithoutSuffix], 'an * 'bn ) params_type

  | TAtom : (string * 'a atom) -> ('a,[`WithoutSuffix],[`One of 'a] param_name) params_type
  | TFile : string -> (file_info , [`WithoutSuffix], [ `One of file_info ] param_name) params_type

  | TUserType : (string * 'a to_and_from) -> ('a,[`WithoutSuffix], [ `One of 'a ] param_name) params_type
  | TTypeFilter : (('a,[<suff] as 's,'an) params_type * 'a filter) -> ('a,'s,'an) params_type
  (* remove TCoord *)

  | TESuffix :  string -> (string list , [`Endsuffix], [ `One of string list ] param_name) params_type
  | TESuffixs : string -> (string, [`Endsuffix], [ `One of string ] param_name) params_type
  | TESuffixu : (string * 'a to_and_from) -> ('a, [`Endsuffix], [ `One of 'a ] param_name) params_type
  | TSuffix : (bool * ('s, [<`WithoutSuffix|`Endsuffix], 'sn) params_type) -> ('s , [`WithSuffix], 'sn) params_type
  (* bool = redirect the version without suffix to the suffix version *)

  | TUnit : (unit, [`WithoutSuffix], unit) params_type
  | TAny : ((string * string) list, [`WithoutSuffix], unit) params_type
  | TConst : string -> (unit, [`WithoutSuffix], [ `One of unit ] param_name) params_type
  | TNLParams : ('a, [<suff] as 'tipo, 'names) non_localized_params -> ('a, 'tipo, 'names) params_type

  | TJson :  (string * 'a Deriving_Json.t option) -> ('a, [`WithoutSuffix], [ `One of 'a caml ] param_name) params_type
  (* custom *)
  | TRaw_post_data : (raw, [ `WithoutSuffix ], no_param_name) params_type

and ('a, 'tipo, 'names) non_localized_params =
  (string *
  bool (* persistent *) *
  ('a option Polytables.key * 'a option Polytables.key))
  * ('a, 'tipo, 'names) params_type


(* As GADT are not implemented in OCaml for now, we define our own
   constructors for params_type *)
let int (n : string) = TAtom (n,TInt)

let int32 (n : string) = TAtom (n,TInt32)

let int64 (n : string) = TAtom (n,TInt64)

let float (n : string) = TAtom (n,TFloat)

let bool (n : string) = TAtom (n,TBool)

let string (n : string) = TAtom (n,TString)

let file (n : string) = TFile n

let unit = TUnit

let type_checker check t = TTypeFilter (t, Some check)

let user_type ~(of_string : string -> 'a) ~(to_string : 'a -> string) (n : string) =
  TUserType (n,{of_string;to_string})

let sum t1 t2 = TSum (t1, t2)

let prod t1 t2 = TProd (t1,t2)

let ( ** ) = prod

let opt t = TOption(t,false)

let neopt t = TOption(t,true)

let radio f (n : string) = TOption (f n,false)

let list (n : string) t = TList (n,t)

let set f (n : string) = TSet (f n)

let any = TAny

let suffix_const (v : string) = TConst v

let all_suffix (n : string) = TESuffix n

let all_suffix_string (n : string) = TESuffixs n

let all_suffix_user ~(of_string : string -> 'a) ~(to_string : 'a -> string) (n : string) =
  TESuffixu (n, {of_string; to_string})

let suffix ?(redirect_if_not_suffix = true) s = TSuffix (redirect_if_not_suffix, s)

let suffix_prod ?(redirect_if_not_suffix = true)
    (s : ('s, [<`WithoutSuffix|`Endsuffix], 'sn) params_type)
    (t : ('a, [`WithoutSuffix], 'an) params_type) :
    (('s * 'a), [`WithSuffix], 'sn * 'an) params_type =
  Obj.magic(TProd (Obj.magic (TSuffix (redirect_if_not_suffix, s)), t))




let caml (n : string) typ = TJson (n, Some typ)

let raw_post_data = TRaw_post_data

(******************************************************************)
let make_list_suffix i = "["^(string_of_int i)^"]"


let rec make_suffix : type a b c. (a,b,c) params_type -> a -> string list = fun typ params -> match typ with
  | TNLParams (_, t) -> make_suffix t params
  | TProd (t1, t2) ->
    (make_suffix t1 (fst params)) @
    (make_suffix t2 (snd params))
  | TAtom (_,a) -> [string_of_atom a params]
  | TUnit -> [""]
  | TConst v -> [v]
  | TOption (t,_) ->
    (match params with
      | None -> [""]
      | Some v -> make_suffix t v)
  | TList (_, t)->
    (match params with
      | [] -> [""]
      | a::l ->
        (make_suffix t a)@
        (make_suffix typ l))
  | TSet t ->
    (match params with
      | [] -> [""]
      | a::l ->
        (make_suffix t a)@
        (make_suffix typ l))
  | TUserType (_, to_and_from) -> [to_and_from.to_string params]
  | TTypeFilter (t, check) -> make_suffix t params
  | TSum (t1, t2) ->
    (match params with
      | Inj1 p -> make_suffix t1 p
      | Inj2 p -> make_suffix t2 p)
  | TESuffixs _ -> [params]
  (* | TAny ->       (match params with [] -> [""] | p -> p) *)
  | TESuffix _ -> (match params with [] -> [""] | p -> p)
  | TESuffixu (_, to_and_from) -> [to_and_from.to_string params]
  | TJson (_, typ) -> (* server or client side *)
    [ to_json ?typ params ]
  | _ -> raise (Eliom_Internal_Error "Bad parameter type in suffix")


let rec aux : type a b c. (a,b,c) params_type -> string list option -> 'y -> a -> string -> string -> 'z -> ('x * 'y * 'z) =
  fun typ psuff nlp params pref suff l ->
  let open Eliommod_parameters in
  match typ with
    | TNLParams ((name, _, _), t) ->
      let psuff, nlp, nl = aux t psuff nlp params pref suff [] in
      (psuff, String.Table.add name nl nlp, l)
    | TProd (t1, t2) ->
      let psuff, nlp, l1 =
        aux t1 psuff nlp (fst params) pref suff l
      in
      aux t2 psuff nlp (snd params) pref suff l1
    | TOption (t,_) ->
      (match params with
        | None -> psuff, nlp, l
        | Some v -> aux t psuff nlp v pref suff l)
    | TList (list_name, t) ->
      let pref2 = pref^list_name^suff^"." in
      fst
        (List.fold_left
           (fun ((psuff, nlp, s), i) p ->
              ((aux t psuff nlp p pref2 (make_list_suffix i) s), (i+1)))
           ((psuff, nlp, l), 0) params)
    | TSet t ->
      List.fold_left
        (fun (psuff, nlp, l) v -> aux t psuff nlp v pref suff l)
        (psuff, nlp, l)
        params
    | TAtom (name,a) -> psuff,nlp,((pref^name^suff,(string_of_atom a params))::l )
    | TSum (t1, t2) -> (match params with
        | Inj1 v -> aux t1 psuff nlp v pref suff l
        | Inj2 v -> aux t2 psuff nlp v pref suff l)
    | TFile name -> psuff, nlp, ((pref^name^suff),insert_file params)::l
    | TUserType (name, {of_string; to_string}) ->
      psuff, nlp,
      ((pref^name^suff),
       insert_string (to_string params))::l
    | TTypeFilter (t, check) -> aux t psuff nlp params pref suff l
    | TUnit -> psuff, nlp, l
    | TAny -> psuff, nlp, l@params
    | TConst _ -> psuff, nlp, l
    | TESuffix _ -> raise (Eliom_Internal_Error "Bad use of suffix")
    | TESuffixs _ -> raise (Eliom_Internal_Error "Bad use of suffix")
    | TESuffixu _ -> raise (Eliom_Internal_Error "Bad use of suffix")
    | TSuffix (_, s) -> Some (make_suffix s params), nlp, l
    | TJson (name, typ) -> (* server or client side *)
      psuff, nlp, ((pref^name^suff),
                   insert_string (to_json ?typ params))::l
    | TRaw_post_data ->
      failwith "Constructing an URL with raw POST data not possible"


(******************************************************************)
(* The following function takes a 'a params_type and a 'a and
   constructs the list of parameters (GET or POST)
   (This is a marshalling function towards HTTP parameters format) *)
let construct_params_list_raw : type a b c. 's -> (a,b,c) params_type -> a -> 't * 's * ((string * string) list) = fun nlp typ params ->
  aux typ None nlp params "" "" []




(** Given a parameter type, get the two functions
    that converts from and to strings. You should
    only use this function on
    - options ;
    - basic types : int, int32, int64, float, string
    - marshal
    - unit
    - string
    - bool
 *)
let rec get_to_and_from : type a b c. (a,b,c) params_type -> a to_and_from = function
  | TOption (o,_) ->
    let {to_string;of_string} = get_to_and_from o in
    {of_string=(fun s -> try Some (of_string s) with _ -> None);
     to_string=(function
         | Some alpha -> to_string alpha
         | None -> "")}
  | TUserType (_, x) -> x
  | TESuffixu (_, x) -> x
  | TAtom(_,a) -> to_from_of_atom a
  | TJson (_, typ) -> (* server or client side *)
    {of_string=(fun s -> of_json ?typ s);
     to_string=(fun d -> to_json ?typ d)}
  | TUnit -> {of_string=(fun _ -> ());
              to_string=(fun () -> "")}
  | _ ->
    failwith "get_to_and_from: not implemented"


let guard construct name guard =
  let {of_string; to_string} = get_to_and_from (construct name) in
  TUserType (name, {
      of_string= (fun s -> let alpha = of_string s in assert (guard alpha); alpha);
      to_string})

(** Walk the parameter tree to search for a parameter, given its name *)
let rec walk_parameter_tree : type a b c. string -> (a,b,c) params_type -> a to_and_from option = fun name x ->
  let get name' =
    if name = name' then
      Some (get_to_and_from x)
    else
      None in
  match x with
    | TUserType (name', _) -> get name'
    | TAtom (name',_) -> get name'
    | TFile name' -> get name'
    | TConst name' -> get name'
    | TESuffix name' -> get name'
    | TESuffixs name' -> get name'
    | TJson (name', _) -> get name'
    | TESuffixu (name', _) -> get name'
    | TTypeFilter (t, _) -> walk_parameter_tree name t
    | TSuffix ( _, o) -> walk_parameter_tree name o
    | TAny -> None
    | TNLParams _ -> None
    | TUnit -> None
    | TOption (o,_) -> failwith "walk_parameter_tree with option"
    | TSet o -> failwith "walk_parameter_tree with set"
    | TList (_, o) -> failwith "walk_parameter_tree with list"
    | TProd (a, b) -> failwith "walk_parameter_tree with tuple"
    | TSum (a, b) -> failwith "walk_parameter_tree with sum"
    | TRaw_post_data -> failwith "walk_parameter_tree with raw post data"


(* contruct the string of parameters (& separated) for GET and POST *)
let construct_params_string l =
  Url.make_encoded_parameters (Eliommod_parameters.get_param_list l)

let construct_params_list nonlocparams typ p =
  let (suff, nonlocparams, pl) = construct_params_list_raw nonlocparams typ p in
  let nlp = String.Table.fold (fun _ l s -> l@s) nonlocparams [] in
  let pl = pl@nlp in (* pl at beginning *)
  (suff, pl)


let construct_params nonlocparams typ p =
  let suff, pl = construct_params_list nonlocparams typ p in
  (suff, construct_params_string pl)




let make_params_names : type a b c. (a,b,c) params_type -> bool * c = fun params ->
  let rec aux : type a b c. bool -> string -> string -> (a,b,c) params_type -> bool * c = fun issuffix prefix suffix x ->
    match x with
      | TNLParams (_, t) -> aux issuffix prefix suffix t
      | TProd (t1, t2) ->
        let issuffix, a = aux issuffix prefix suffix t1 in
        let issuffix, b = aux issuffix prefix suffix t2 in
        issuffix, (a, b)
      | TAtom(name,a) -> issuffix, prefix^name^suffix
      | TFile name -> issuffix, prefix^name^suffix
      | TUserType (name, _) -> issuffix, prefix^name^suffix
      | TJson (name, _)        -> issuffix, prefix^name^suffix
      | TUnit -> issuffix, ()
      | TAny -> issuffix, ()
      | TConst _ -> issuffix, ""
      | TSet t -> aux issuffix prefix suffix t
      | TESuffix n -> issuffix, n
      | TESuffixs n -> issuffix,n
      | TESuffixu (n, _) -> issuffix, n
      | TSuffix (_, t) -> aux true prefix suffix t
      | TOption (t,_) -> aux issuffix prefix suffix t
      | TSum (t1, t2) ->
        let _, a = aux issuffix prefix suffix t1 in
        let _, b = aux issuffix prefix suffix t2 in
        issuffix, (a, b)
      (* TSuffix cannot be inside TSum *)
      | TList (name, t1) ->
        (issuffix,
         {it =
            (fun f l init ->
               let length = List.length l in
               snd
                 (List.fold_right
                    (fun el (i, l2) ->
                       let i'= i-1 in
                       (i', (f (snd (aux issuffix (prefix^name^suffix^".")
                                       (make_list_suffix i') t1)) el
                               l2)))
                    l
                    (length, init)))})
      (* TSuffix cannot be inside TList *)
      | TTypeFilter (t, _) -> aux issuffix prefix suffix t
      | TRaw_post_data -> failwith "Not possible with raw post data"
  in aux false "" "" params

let string_of_param_name = id



(* Add a prefix to parameters *)
let rec add_pref_params : type a b c. string -> (a,b,c) params_type -> (a,b,c) params_type = fun pref x ->
  match x with
  | TNLParams (a, t) -> TNLParams (a, add_pref_params pref t)
  | TProd (t1, t2) -> TProd ((add_pref_params pref t1),
                             (add_pref_params pref t2))
  | TOption (t,b) -> TOption (add_pref_params pref t,b)
  | TAtom(name,a) -> TAtom (pref^name,a)
  | TList (list_name, t) -> TList (pref^list_name, t)
  | TSet t -> TSet (add_pref_params pref t)
  | TSum (t1, t2) -> TSum ((add_pref_params pref t1),
                           (add_pref_params pref t2))
  | TFile name -> TFile (pref^name)
  | TUserType (name, to_of) -> TUserType (pref^name, to_of)
  | TUnit -> TUnit
  | TAny -> TAny
  | TConst v -> TConst v
  | TESuffix n -> TESuffix n
  | TESuffixs n -> TESuffixs n
  | TESuffixu a -> TESuffixu a
  | TSuffix s -> TSuffix s
  | TJson (name, typ) -> TJson (pref^name, typ)
  | TTypeFilter a -> TTypeFilter a
  | TRaw_post_data -> failwith "Not possible with raw post data"


(*****************************************************************************)
(* Non localized parameters *)

let nl_prod
    (t : ('a, 'su, 'an) params_type)
    (s : ('s, [ `WithoutSuffix ], 'sn) non_localized_params) :
    (('a * 's), 'su, 'an * 'sn) params_type =
  Obj.magic (TProd (Obj.magic t, TNLParams s))

(* removes from nlp set the nlp parameters that are present in param
   specification *)
let rec remove_from_nlp : type a b c. 's -> (a,b,c) params_type -> 's  = fun nlp x ->
  match x with
    | TNLParams ((n, _, _), _) -> String.Table.remove n nlp
    | TProd (t1, t2) ->
      let nlp = remove_from_nlp nlp t1 in
      remove_from_nlp nlp t2
    | _ -> nlp

type nl_params_set = (string * Eliommod_parameters.param) list String.Table.t

let empty_nl_params_set = String.Table.empty

let add_nl_parameter (s : nl_params_set) t v =
  (fun (_, a, _) -> a) (construct_params_list_raw s (TNLParams t) v)

let table_of_nl_params_set = id

let list_of_nl_params_set nlp = snd (construct_params_list nlp unit ())

let string_of_nl_params_set nlp =
  Url.make_encoded_parameters
    (Eliommod_parameters.get_param_list (list_of_nl_params_set nlp))

let get_nl_params_names t = snd (make_params_names (TNLParams t))

let make_nlp_name persistent prefix name =
  let pr = if persistent then "p_" else "n_" in
  pr^prefix^"-"^name

let make_non_localized_parameters
    ~prefix
    ~name
    ?(persistent = false)
    (p : ('a, [ `WithoutSuffix ], 'b) params_type)
    : ('a, [ `WithoutSuffix ], 'b) non_localized_params =
  let name = make_nlp_name persistent prefix name in
  if String.contains name '.'
  then failwith "Non localized parameters names cannot contain dots."
  else
    ((name,
      persistent,
      (Polytables.make_key () (* GET *),
       Polytables.make_key () (* POST *))),
     add_pref_params (Eliom_common.nl_param_prefix^name^".") p)




(*****************************************************************************)
let rec contains_suffix : type a b c. (a,b,c) params_type -> bool option = function
  | TProd (a, b) ->
    (match contains_suffix a with
      | None -> contains_suffix b
      | c -> c)
  | TSuffix (b, _) -> Some b
  | _ -> None

(*****************************************************************************)

let rec wrap_param_type : type a b c. (a,b,c) params_type -> (a,b,c) params_type = function
  | TNLParams (a, t) -> TNLParams (a, wrap_param_type t)
  | TProd (t1, t2) -> TProd ((wrap_param_type t1),
                             (wrap_param_type t2))
  | TOption (t,b) -> TOption (wrap_param_type t,b)
  | TList (list_name, t) -> TList (list_name, t)
  | TSet t -> TSet (wrap_param_type t)
  | TSum (t1, t2) -> TSum ((wrap_param_type t1),
                           (wrap_param_type t2))
  | TUserType (name, _) ->
    (*VVV *)
    failwith ("User service parameters '"^name^"' type not supported client side.")
  (* We remove the type information here: not possible to send a closure.
     marshaling is just basic json marshaling on client side. *)
  | TJson (name, _) -> TJson (name, None)
  (* the filter is only on server side (at least for now) *)
  | TTypeFilter (t, _) -> TTypeFilter (t, None)
  | t -> t
