(*
  Semantics of panLang
*)
open preamble panLangTheory;
local open alignmentTheory wordSemTheory ffiTheory in end;

val _ = new_theory"panSem";
val _ = set_grammar_ancestry [
  "panLang", "alignment",
  "finite_map", "misc", "wordSem", "ffi"
]

val _ = Datatype `
  word_fun = Word ('a word)
           | Label funname`;

val _ = Datatype `
  state =
    <| locals    : varname |-> 'a word_fun
     ; fsigmap    : funname |-> varname list
     ; code      : funname |-> (num # ('a panLang$prog))  (* num is function arity *)
     ; memory    : 'a word -> 'a word_fun
     ; memaddrs  : ('a word) set
     ; clock     : num
     ; be        : bool   (* TODISC: do we need that *)
     ; extstate  : 'ffi ffi_state (* TODISC *)
     ; triggered : bool
     ; stopped   : bool
     ; global_clock : num (* natural number clock for the time being *)
     ; elapsed_time : num|>`

val state_component_equality = theorem"state_component_equality";

val _ = Datatype `
  result = Error
         | TimeOut
         | Break
         | Continue
         | Return ('w word_fun)
         | Exception ('w word_fun)
         | FinalFFI final_event (* TODISC *)`

val s = ``(s:('a,'ffi) panSem$state)``

(* TODISC: adding these defs from wordsem for word_fun memory *)
val mem_store_def = Define `
  mem_store (addr:'a word) (w:'a word_fun) ^s =
    if addr IN s.memaddrs then
      SOME (s with memory := (addr =+ w) s.memory)
    else NONE`

val mem_store_byte_def = Define `
  mem_store_byte m dm be w b =
    case m (byte_align w) of
    | Word v =>
        if byte_align w IN dm
        then SOME ((byte_align w =+ Word (set_byte w b v be)) m)
        else NONE
    | Label _ => NONE`

val mem_load_def = Define `
  mem_load (addr:'a word) ^s =
    if addr IN s.memaddrs then
      SOME (s.memory addr)
    else NONE`

val mem_load_byte_def = Define `
  mem_load_byte m dm be w =
    case m (byte_align w) of
    | Label _ => NONE
    | Word v =>
        if byte_align w IN dm
        then SOME (get_byte w v be) else NONE`

val the_words_def = Define `
  (the_words [] = SOME []) /\
  (the_words (w::ws) =
     case (w,the_words ws) of
     | SOME (Word x), SOME xs => SOME (x::xs)
     | _ => NONE)`


val get_var_def = Define `
  get_var v ^s = FLOOKUP s.locals v`;

val get_vars_def = Define `
  (get_vars [] ^s = SOME []) /\
  (get_vars (v::vs) s =
     case get_var v s of
     | NONE => NONE
     | SOME x => (case get_vars vs s of
                  | NONE => NONE
                  | SOME xs => SOME (x::xs)))`;

val set_var_def = Define `
  set_var v w ^s =
      (s with locals := s.locals |+ (v,w))`;

(*val set_vars_def = Define `
  set_vars vs xs ^s =
    (s with locals := (alist_insert vs xs s.locals))`;
*)

val upd_locals_def = Define `
   upd_locals varargs ^s =
    s with <| locals := FEMPTY |++ varargs  |>`;

val empty_locals_def = Define `
   empty_locals ^s =
    s with <| locals := FEMPTY |>`;

val lookup_code_def = Define `
  lookup_code fname len code =
    case (FLOOKUP code fname) of
      | SOME (arity, prog) => if len = arity then SOME prog else NONE
      | _ => NONE`


val locals_fun_def = Define `
  locals_fun fname fsigmap args =
    case (FLOOKUP fsigmap fname) of
      | SOME vlist => if LENGTH vlist = LENGTH args
                      then SOME (alist_to_fmap (ZIP (vlist,args))) else NONE
      | _ => NONE`


(* TODISC: to think about negation *)
val eval_def = tDefine "eval"`
  (eval ^s (Const w) = SOME (Word w)) /\
  (eval s (Var v) = get_var v s) /\
  (eval s (Load addr) =
    case eval s addr of
     | SOME (Word w) => mem_load w s
     | _ => NONE) /\
  (eval s (LoadByte addr) =
    case eval s addr of
     | SOME (Word w) =>
        (case mem_load_byte s.memory s.memaddrs s.be w of
           | NONE => NONE
           | SOME w => SOME (Word (w2w w)))
     | _ => NONE) /\
  (eval s (Op op es) =
    case the_words (MAP (eval s) es) of
      | SOME ws => (OPTION_MAP Word (word_op op ws))
      | _ => NONE) /\
  (eval s (Cmp cmp e1 e2) =
    case (eval s e1, eval s e2) of
     | (SOME (Word w1), SOME (Word w2)) => SOME (Word (v2w [word_cmp cmp w1 w2]))  (* TODISC: should we define b2w instead of v2w *)
     | _ => NONE) /\
  (eval s (Shift sh e n) =
    case eval s e of
     | SOME (Word w) => OPTION_MAP Word (word_sh sh w n)
     | _ => NONE)`
  (WF_REL_TAC `measure (exp_size ARB o SND)`
   \\ REPEAT STRIP_TAC \\ IMP_RES_TAC MEM_IMP_exp_size
   \\ TRY (FIRST_X_ASSUM (ASSUME_TAC o Q.SPEC `ARB`))
   \\ DECIDE_TAC)


val dec_clock_def = Define `
  dec_clock ^s = s with clock := s.clock - 1`;

val fix_clock_def = Define `
  fix_clock old_s (res,new_s) =
    (res,new_s with
      <| clock := if old_s.clock < new_s.clock then old_s.clock else new_s.clock |>)`

val fix_clock_IMP_LESS_EQ = Q.prove(
  `!x. fix_clock ^s x = (res,s1) ==> s1.clock <= s.clock`,
  full_simp_tac(srw_ss())[fix_clock_def,FORALL_PROD] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ decide_tac);

(*
val int_cmp_def = Define `
  (int_cmp Equal i1 i2 = (i1=i2)) /\
  (int_cmp NotEq i1 i2 = (i1<>i2)) /\
  (int_cmp Less i1 i2 =  (i1<i2)) /\
  (int_cmp LessEq i1 i2 = (i1<=i2)) /\
  (int_cmp Greater i1 i2 = (i1>i2)) /\
  (int_cmp GreaterEq i1 i2 = (i1>=i2))`

val trig_chk_def = Define `
  trig_chk s grd ct imm res =
   if (~s.triggered /\ ~s.stopped /\ int_cmp grd ct imm)
   then res else (SOME Error,s)`
*)

val trig_chk_def = Define `
  trig_chk s res =
   if (~s.triggered /\ ~s.stopped)
   then res else (SOME Error,s)`

val stop_chk = Define `
  stop_chk s res =
   if (s.triggered /\ ~s.stopped)
   then res else (SOME Error,s)`

val start_chk = Define `
  start_chk s res =
   if (s.triggered /\ ~s.stopped)
   then res else (SOME Error,s)`


(*
val _ = Datatype `
  state =
    <| locals    : varname |-> 'a word_fun
     ; fsigmap    : funname |-> varname list
     ; code      : funname |-> (num # ('a panLang$prog))  (* num is function arity *)
     ; memory    : 'a word -> 'a word_fun
     ; memaddrs  : ('a word) set
     ; clock     : num
     ; be        : bool   (* TODISC: do we need that *)
     ; extstate  : 'ffi ffi_state (* TODISC *)
     ; triggered : bool
     ; stopped   : bool
     ; global_clock : num (* natural number clock for the time being *)
     ; elapsed_time : num|>`
*)

val evaluate_def = tDefine "evaluate"`
  (evaluate (Start:'a panLang$prog,^s) =
   let et = s.global_clock - s.elapsed_time in
   if ARB et
   then  trig_chk s (NONE, s with <|elapsed_time := s.global_clock ; global_clock := s.global_clock + 1;
                                    triggered := T; stopped := F|>)
   else (SOME Error,s)) /\
  (evaluate (Stop,s) =
    stop_chk s (NONE, s with <|stopped := T  ; triggered := F|>)) /\
  (evaluate (Skip,s) =  start_chk s (NONE,s)) /\
  (evaluate (Assign v e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (NONE, set_var v w s)
     | NONE => (SOME Error, s))) /\
  (evaluate (Store e v,s) = start_chk s
   (case (eval s e, get_var v s) of
     | (SOME (Word adr), SOME w) =>
        (case mem_store adr w s of
          | SOME st => (NONE, st)
          | NONE => (SOME Error, s))
     | _ => (SOME Error, s)))/\
  (evaluate (StoreByte e v,s) = start_chk s
   (case (eval s e, get_var v s) of
     | (SOME (Word adr), SOME (Word w)) =>
        (case mem_store_byte s.memory s.memaddrs s.be adr (w2w w) of
          | SOME m => (NONE, s with memory := m)
          | NONE => (SOME Error, s))
     | _ => (SOME Error, s))) /\
  (evaluate (Seq c1 c2,s) = start_chk s
    (let (res,s1) = fix_clock s (evaluate (c1,s)) in
       if res = NONE then evaluate (c2,s1) else (res,s1))) /\
  (evaluate (If e c1 c2,s) = start_chk s
   (case (eval s e) of
     | SOME (Word w) =>
       if (w <> 0w) then evaluate (c1,s)  (* False is 0, True is everything else *)
       else evaluate (c2,s)
     | _ => (SOME Error,s))) /\
  (evaluate (Break,s) = start_chk s (SOME Break,s)) /\
  (evaluate (Continue,s) = start_chk s (SOME Continue,s)) /\
  (evaluate (While e c,s) = start_chk s
   (case (eval s e) of
     | SOME (Word w) =>
       if (w <> 0w) then
        let (res,s1) = fix_clock s (evaluate (c,s)) in
          if s1.clock = 0 then (SOME TimeOut,empty_locals s1)
          else
           case res of
            | SOME Continue => evaluate (While e c,dec_clock s1)
            | NONE => evaluate (While e c,dec_clock s1)
            | _ => (res,s1)
       else (NONE,s)
    | _ => (SOME Error,s))) /\
  (evaluate (Return e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (SOME (Return w),empty_locals s) (* TODISC: should we empty locals here? *)
     | _ => (SOME Error,s))) /\
  (evaluate (Raise e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (SOME (Exception w), s)  (* TODISC: should we empty locals here? *)
     | _ => (SOME Error,s))) /\
 (evaluate (Tick,s) = start_chk s
  (if s.clock = 0 then (SOME TimeOut,empty_locals s)
   else (NONE,dec_clock s))) /\

 (* TODISC: tried pushing Ret rt => inward, things got compicated so thought to first have a working semantics
  **main confusion** here: why we are doing s.clock = 0 before even evaluating prog  *)

 (evaluate (Call caltyp trgt argexps,s) = start_chk s
  (case (eval s trgt, OPT_MMAP (eval s) argexps) of
    | (SOME (Label fname), SOME args) =>
       (case lookup_code fname (LENGTH args) s.code, locals_fun fname s.fsigmap args of
         | (SOME prog, SOME newlocals) => if s.clock = 0 then (SOME TimeOut,empty_locals s) else
           (case caltyp of
             | Tail =>
               (case evaluate (prog, (dec_clock s) with locals:= newlocals) of
                 | (NONE,s) => (SOME Error,s)
                 | (SOME res,s) => (SOME res,s))
             | Ret rt =>
               (case fix_clock ((dec_clock s) with locals:= newlocals)
                               (evaluate (prog, (dec_clock s) with locals:= newlocals)) of
                 (* TODISC: NONE result is different from res, should not be moved down *)
                 | (NONE,st) => (SOME Error,(st with locals := s.locals))
                 | (SOME (Return retv),st) => (NONE, set_var rt retv (st with locals := s.locals))
                 | (res,st) => (res,(st with locals := s.locals)))
             | Handle rt evar p =>
               (case fix_clock ((dec_clock s) with locals:= newlocals)
                               (evaluate (prog, (dec_clock s) with locals:= newlocals)) of
                 | (NONE,st) => (SOME Error,(st with locals := s.locals))
                 | (SOME (Return retv),st) => (NONE, set_var rt retv (st with locals := s.locals))
                 | (SOME (Exception exn),st) => evaluate (p, set_var evar exn (st with locals := s.locals))
                 | (res,st) => (res,(st with locals := s.locals))))
      | (_,_) => (SOME Error,s))
    | (_, _) => (SOME Error,s))) /\
  (evaluate (ExtCall retv fname args, s) = ARB) `
    cheat
  (*
  (WF_REL_TAC `(inv_image (measure I LEX measure (prog_size (K 0)))
                  (\(xs,^s). (s.clock,xs)))`
   \\ REPEAT STRIP_TAC \\ TRY (full_simp_tac(srw_ss())[] \\ DECIDE_TAC)
   \\ imp_res_tac fix_clock_IMP_LESS_EQ \\ full_simp_tac(srw_ss())[]
   \\ imp_res_tac (GSYM fix_clock_IMP_LESS_EQ)
   \\ full_simp_tac(srw_ss())[set_var_def,upd_locals_def,dec_clock_def, LET_THM]
   \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
   \\ every_case_tac \\ full_simp_tac(srw_ss())[]
   \\ decide_tac) *)

val evaluate_ind = theorem"evaluate_ind";

(*

(* only being used in FFI *)
val cut_env_def = Define `
  cut_env (name_set:num_set) env =
    if domain name_set SUBSET domain env
    then SOME (inter env name_set)
    else NONE`
*)


val evaluate_def = tDefine "evaluate"`
  (evaluate ((Start ct grd imm):'a panLang$prog,^s) =
    trig_chk s ct grd imm (NONE, s with <|triggered := T; stopped := F|>)) /\
  (evaluate (Stop,s) =
    stop_chk s (NONE, s with <|stopped := T  ; triggered := F|>)) /\
  (evaluate (Skip,s) =  start_chk s (NONE,s)) /\
  (evaluate (Assign v e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (NONE, set_var v w s)
     | NONE => (SOME Error, s))) /\
  (evaluate (Store e v,s) = start_chk s
   (case (eval s e, get_var v s) of
     | (SOME (Word adr), SOME w) =>
        (case mem_store adr w s of
          | SOME st => (NONE, st)
          | NONE => (SOME Error, s))
     | _ => (SOME Error, s)))/\
  (evaluate (StoreByte e v,s) = start_chk s
   (case (eval s e, get_var v s) of
     | (SOME (Word adr), SOME (Word w)) =>
        (case mem_store_byte s.memory s.memaddrs s.be adr (w2w w) of
          | SOME m => (NONE, s with memory := m)
          | NONE => (SOME Error, s))
     | _ => (SOME Error, s))) /\
  (evaluate (Seq c1 c2,s) = start_chk s
    (let (res,s1) = fix_clock s (evaluate (c1,s)) in
       if res = NONE then evaluate (c2,s1) else (res,s1))) /\
  (evaluate (If e c1 c2,s) = start_chk s
   (case (eval s e) of
     | SOME (Word w) =>
       if (w <> 0w) then evaluate (c1,s)  (* False is 0, True is everything else *)
       else evaluate (c2,s)
     | _ => (SOME Error,s))) /\
  (evaluate (Break,s) = start_chk s (SOME Break,s)) /\
  (evaluate (Continue,s) = start_chk s (SOME Continue,s)) /\
  (evaluate (While e c,s) = start_chk s
   (case (eval s e) of
     | SOME (Word w) =>
       if (w <> 0w) then
        let (res,s1) = fix_clock s (evaluate (c,s)) in
          if s1.clock = 0 then (SOME TimeOut,empty_locals s1)
          else
           case res of
            | SOME Continue => evaluate (While e c,dec_clock s1)
            | NONE => evaluate (While e c,dec_clock s1)
            | _ => (res,s1)
       else (NONE,s)
    | _ => (SOME Error,s))) /\
  (evaluate (Return e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (SOME (Return w),empty_locals s) (* TODISC: should we empty locals here? *)
     | _ => (SOME Error,s))) /\
  (evaluate (Raise e,s) = start_chk s
   (case (eval s e) of
     | SOME w => (SOME (Exception w), s)  (* TODISC: should we empty locals here? *)
     | _ => (SOME Error,s))) /\
 (evaluate (Tick,s) = start_chk s
  (if s.clock = 0 then (SOME TimeOut,empty_locals s)
   else (NONE,dec_clock s))) /\

 (* TODISC: tried pushing Ret rt => inward, things got compicated so thought to first have a working semantics
  **main confusion** here: why we are doing s.clock = 0 before even evaluating prog  *)

 (evaluate (Call caltyp trgt argexps,s) = start_chk s
  (case (eval s trgt, OPT_MMAP (eval s) argexps) of
    | (SOME (Label fname), SOME args) =>
       (case lookup_code fname (LENGTH args) s.code, locals_fun fname s.fsigmap args of
         | (SOME prog, SOME newlocals) => if s.clock = 0 then (SOME TimeOut,empty_locals s) else
           (case caltyp of
             | Tail =>
               (case evaluate (prog, (dec_clock s) with locals:= newlocals) of
                 | (NONE,s) => (SOME Error,s)
                 | (SOME res,s) => (SOME res,s))
             | Ret rt =>
               (case fix_clock ((dec_clock s) with locals:= newlocals)
                               (evaluate (prog, (dec_clock s) with locals:= newlocals)) of
                 (* TODISC: NONE result is different from res, should not be moved down *)
                 | (NONE,st) => (SOME Error,(st with locals := s.locals))
                 | (SOME (Return retv),st) => (NONE, set_var rt retv (st with locals := s.locals))
                 | (res,st) => (res,(st with locals := s.locals)))
             | Handle rt evar p =>
               (case fix_clock ((dec_clock s) with locals:= newlocals)
                               (evaluate (prog, (dec_clock s) with locals:= newlocals)) of
                 | (NONE,st) => (SOME Error,(st with locals := s.locals))
                 | (SOME (Return retv),st) => (NONE, set_var rt retv (st with locals := s.locals))
                 | (SOME (Exception exn),st) => evaluate (p, set_var evar exn (st with locals := s.locals))
                 | (res,st) => (res,(st with locals := s.locals))))
      | (_,_) => (SOME Error,s))
    | (_, _) => (SOME Error,s))) /\
  (evaluate (ExtCall retv fname args, s) = ARB) `
    cheat
  (*
  (WF_REL_TAC `(inv_image (measure I LEX measure (prog_size (K 0)))
                  (\(xs,^s). (s.clock,xs)))`
   \\ REPEAT STRIP_TAC \\ TRY (full_simp_tac(srw_ss())[] \\ DECIDE_TAC)
   \\ imp_res_tac fix_clock_IMP_LESS_EQ \\ full_simp_tac(srw_ss())[]
   \\ imp_res_tac (GSYM fix_clock_IMP_LESS_EQ)
   \\ full_simp_tac(srw_ss())[set_var_def,upd_locals_def,dec_clock_def, LET_THM]
   \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
   \\ every_case_tac \\ full_simp_tac(srw_ss())[]
   \\ decide_tac) *)

val evaluate_ind = theorem"evaluate_ind";

(*

(* only being used in FFI *)
val cut_env_def = Define `
  cut_env (name_set:num_set) env =
    if domain name_set SUBSET domain env
    then SOME (inter env name_set)
    else NONE`
*)




Theorem evaluate_clock:
   !prog s r s'. (evaluate (prog,s) = (r,s')) ==>
                 s'.clock <= s.clock
Proof
  recInduct evaluate_ind \\ REPEAT STRIP_TAC
  \\ POP_ASSUM MP_TAC \\ ONCE_REWRITE_TAC [evaluate_def]
  \\ rw [] \\ every_case_tac
  \\ fs [set_vars_def,set_var_def, mem_store_def,call_env_def,dec_clock_def, LET_THM]
  \\ rveq \\ fs []
  \\ rpt (pairarg_tac \\ fs [])
  \\ every_case_tac \\ fs [] \\ rveq
  \\ imp_res_tac fix_clock_IMP_LESS_EQ
  \\ imp_res_tac LESS_EQ_TRANS \\ fs []
QED

val fix_clock_evaluate = Q.prove(
  `fix_clock s (evaluate (prog,s)) = evaluate (prog,s)`,
  Cases_on `evaluate (prog,s)` \\ fs [fix_clock_def]
  \\ imp_res_tac evaluate_clock \\ fs [GSYM NOT_LESS, state_component_equality]);

val evaluate_ind = save_thm("evaluate_ind",
  REWRITE_RULE [fix_clock_evaluate] evaluate_ind);

val evaluate_def = save_thm("evaluate_def[compute]",
  REWRITE_RULE [fix_clock_evaluate] evaluate_def);

val _ = map delete_binding ["evaluate_AUX_def", "evaluate_primitive_def"];

val _ = export_theory();
