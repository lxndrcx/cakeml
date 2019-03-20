(*
  Implement and prove correct monadic version of encoder
*)
open preamble state_transformerTheory
open ml_monadBaseLib ml_monadBaseTheory
open asmTheory lab_to_targetTheory

val _ = new_theory "monadic_enc"
val _ = ParseExtras.temp_tight_equality();
val _ = monadsyntax.temp_add_monadsyntax()

val _ = temp_overload_on ("monad_bind", ``st_ex_bind``);
val _ = temp_overload_on ("monad_unitbind", ``\x y. st_ex_bind x (\z. y)``);
val _ = temp_overload_on ("monad_ignore_bind", ``\x y. st_ex_bind x (\z. y)``);
val _ = temp_overload_on ("return", ``st_ex_return``);

(* The state is just an array *)
val _ = Hol_datatype `
  enc_state_64 = <|
       hash_tab : ((64 asm # word8 list) list) list
     |>`

val accessors = define_monad_access_funs ``:enc_state_64``;

val hash_tab_accessors = el 1 accessors;
val (hash_tab,get_hash_tab_def,set_hash_tab_def) = hash_tab_accessors;

(* Data type for the exceptions *)
val _ = Hol_datatype`
  state_exn = Fail of string | Subscript`;

(* Monadic functions to handle the exceptions *)
val exn_functions = define_monad_exception_functions ``:state_exn`` ``:enc_state_64``;
val _ = temp_overload_on ("failwith", ``raise_Fail``);

val sub_exn = ``Subscript``;
val update_exn = ``Subscript``;

(* Fixed-size array manipulators *)
val arr_manip = define_MFarray_manip_funs
  [hash_tab_accessors] sub_exn update_exn;

fun accessor_thm (a,b,c,d,e,f) = LIST_CONJ [b,c,d,e,f]

val hash_tab_manip = el 1 arr_manip;

val hash_tab_accessor = save_thm("hash_tab_accessor",accessor_thm hash_tab_manip);

(*
  This hash function is roughly a rolling hash
  The modulus m is a hash size parameter
*)
val hash_reg_imm_def = Define`
  (hash_reg_imm m (Reg reg) = reg) ∧
  (hash_reg_imm m (Imm imm) = 67n + (w2n imm MOD m))`

val hash_binop_def = Define`
  (hash_binop Add = 0n) ∧
  (hash_binop Sub = 1n) ∧
  (hash_binop And = 2n) ∧
  (hash_binop Or  = 3n) ∧
  (hash_binop Xor = 4n)`

val hash_cmp_def = Define`
  (hash_cmp Equal = 5n) ∧
  (hash_cmp Lower = 6n) ∧
  (hash_cmp Less  = 7n) ∧
  (hash_cmp Test  = 8n) ∧
  (hash_cmp NotEqual = 9n) ∧
  (hash_cmp NotLower = 10n) ∧
  (hash_cmp NotLess  = 11n) ∧
  (hash_cmp NotTest  = 12n)`

val hash_shift_def = Define`
  (hash_shift Lsl = 13n) ∧
  (hash_shift Lsr = 14n) ∧
  (hash_shift Asr = 15n) ∧
  (hash_shift Ror = 16n)`

val hash_memop_def = Define`
  (hash_memop Load   = 17n) ∧
  (hash_memop Load8  = 18n) ∧
  (hash_memop Store  = 19n) ∧
  (hash_memop Store8 = 20n)`

val roll_hash_def = Define`
  (roll_hash [] acc = acc) ∧
  (roll_hash (x::xs) acc = roll_hash xs (31n * acc + x))`

(*
Roughly, roll_hash [b;c;d;e] a
gives
roll_hash [b; c; d; e] a = 31 * (31 * (31 * (31 * a + b) + c) + d) + e

Try to put largest terms at the end of the list!
*)

val hash_arith_def = Define`
  (hash_arith m (Binop bop r1 r2 ri) =
    roll_hash [hash_binop bop; r1; r2; hash_reg_imm m ri] 21n) ∧
  (hash_arith m (Shift sh r1 r2 n) =
    roll_hash [hash_shift sh; r1; r2; n] 22n) ∧
  (hash_arith m (Div r1 r2 r3) =
    roll_hash [r1;r2;r3] 23n) ∧
  (hash_arith m (LongMul r1 r2 r3 r4) =
    roll_hash [r1;r2;r3;r4] 24n) ∧
  (hash_arith m (LongDiv r1 r2 r3 r4 r5) =
    roll_hash [r1;r2;r3;r4;r5] 25n) ∧
  (hash_arith m (AddCarry r1 r2 r3 r4) =
    roll_hash [r1;r2;r3;r4] 26n) ∧
  (hash_arith m (AddOverflow r1 r2 r3 r4) =
    roll_hash [r1;r2;r3;r4] 27n) ∧
  (hash_arith m (SubOverflow r1 r2 r3 r4) =
    roll_hash [r1;r2;r3;r4] 28n)`

val hash_fp_def = Define`
  (hash_fp (FPLess r f1 f2) =
    roll_hash [r;f1;f2] 29n) ∧
  (hash_fp (FPLessEqual r f1 f2) =
    roll_hash [r;f1;f2] 30n) ∧
  (hash_fp (FPEqual r f1 f2) =
    roll_hash [r;f1;f2] 31n) ∧

  (hash_fp (FPAbs f1 f2) =
    roll_hash [f1;f2] 32n) ∧
  (hash_fp (FPNeg f1 f2) =
    roll_hash [f1;f2] 33n) ∧
  (hash_fp (FPSqrt f1 f2) =
    roll_hash [f1;f2] 34n) ∧

  (hash_fp (FPAdd f1 f2 f3) =
    roll_hash [f1;f2;f3] 35n) ∧
  (hash_fp (FPSub f1 f2 f3) =
    roll_hash [f1;f2;f3] 36n) ∧
  (hash_fp (FPMul f1 f2 f3) =
    roll_hash [f1;f2;f3] 37n) ∧
  (hash_fp (FPDiv f1 f2 f3) =
    roll_hash [f1;f2;f3] 38n) ∧

  (hash_fp (FPMov f1 f2) =
    roll_hash [f1;f2] 39n) ∧
  (hash_fp (FPMovToReg r1 r2 f) =
    roll_hash [r1;r2;f] 40n) ∧
  (hash_fp (FPMovFromReg f r1 r2) =
    roll_hash [f;r1;r2] 41n) ∧
  (hash_fp (FPToInt f1 f2) =
    roll_hash [f1;f2] 42n) ∧
  (hash_fp (FPFromInt f1 f2) =
    roll_hash [f1;f2] 43n)`

val hash_inst_def = Define`
  (hash_inst m Skip = 44n) ∧
  (hash_inst m (Const r w) =
    roll_hash [r;w2n w MOD m] 45n) ∧
  (hash_inst m (Arith a) =
    roll_hash [hash_arith m a] 46n) ∧
  (hash_inst m (Mem mop r (Addr rr w)) =
    roll_hash [hash_memop mop; r; rr; w2n w MOD m] 47n) ∧
  (hash_inst m (FP fp) =
    roll_hash [hash_fp fp] 48n)`

val hash_asm_def = Define`
  (hash_asm m (Inst i) =
    roll_hash [hash_inst m i] 49n) ∧
  (hash_asm m (Jump w) =
    roll_hash [w2n w MOD m] 50n) ∧
  (hash_asm m (JumpCmp c r ri w) =
    roll_hash [hash_cmp c; r; hash_reg_imm m ri; w2n w MOD m] 51n) ∧
  (hash_asm m (Call w) =
    roll_hash [w2n w MOD m] 52n) ∧
  (hash_asm m (JumpReg r) =
    roll_hash [r] 53n) ∧
  (hash_asm m (Loc r w) =
    roll_hash [r; w2n w MOD m] 54n)`

val lookup_insert_table_def = Define`
  lookup_insert_table enc n a =
  let v = hash_asm n a MOD n in
  do
    ls <- hash_tab_sub v;
    case ALOOKUP ls a of
      NONE =>
      do
        encode <- return (enc a);
        update_hash_tab v ((a,encode)::ls);
        return encode
      od
    | SOME res =>
      return res
  od`

val enc_line_hash_def = Define `
  (enc_line_hash enc skip_len n (Label n1 n2 n3) =
    return (Label n1 n2 skip_len)) ∧
  (enc_line_hash enc skip_len n (Asm a _ _) =
    do
      bs <- lookup_insert_table enc n (cbw_to_asm a);
      return (Asm a bs (LENGTH bs))
    od) ∧
  (enc_line_hash enc skip_len n (LabAsm l _ _ _) =
     do
       bs <- lookup_insert_table enc n (lab_inst 0w l);
       return (LabAsm l 0w bs (LENGTH bs))
     od)`

val enc_line_hash_ls_def = Define`
  (enc_line_hash_ls enc skip_len n [] = return []) ∧
  (enc_line_hash_ls enc skip_len n (x::xs) =
  do
    fx <- enc_line_hash enc skip_len n x;
    fxs <- enc_line_hash_ls enc skip_len n xs;
    return (fx::fxs)
  od)`

val enc_sec_hash_ls_def = Define`
  (enc_sec_hash_ls enc skip_len n [] = return []) ∧
  (enc_sec_hash_ls enc skip_len n (x::xs) =
  case x of Section k ys =>
  do
    ls <- enc_line_hash_ls enc skip_len n ys;
    rest <- enc_sec_hash_ls enc skip_len n xs;
    return (Section k ls::rest)
  od)`

val enc_sec_hash_ls_full_def = Define`
  enc_sec_hash_ls_full enc n xs =
  enc_sec_hash_ls enc (LENGTH (enc (Inst Skip))) n xs`

(* As we are using fixed-size array, we need to define a different record type for the initialization *)
val array_fields_names = ["hash_tab"];
val run_ienc_state_64_def = define_run ``:enc_state_64``
                                      array_fields_names
                                      "ienc_state_64";

val enc_secs_aux_def = Define`
  enc_secs_aux enc n xs =
    run_ienc_state_64 (enc_sec_hash_ls_full enc n xs) <| hash_tab := (n, []) |>`

val enc_secs_def = Define`
  enc_secs enc n xs =
    case enc_secs_aux enc (if n = 0 then 1 else n) xs of
      Success xs => xs
    | Failure _ => []`

(* prove that enc_secs gives the same behavior as enc_sec_list *)

val msimps = [st_ex_bind_def,st_ex_return_def];

Theorem Msub_eqn[simp] `
  ∀e n ls v.
  Msub e n ls =
  if n < LENGTH ls then Success (EL n ls)
                   else Failure e`
  (ho_match_mp_tac Msub_ind>>rw[]>>
  simp[Once Msub_def]>>
  Cases_on`ls`>>fs[]>>
  IF_CASES_TAC>>fs[]>>
  Cases_on`n`>>fs[]);

Theorem hash_tab_sub_eqn[simp] `
  hash_tab_sub n s =
  if n < LENGTH s.hash_tab then
    (Success (EL n s.hash_tab),s)
  else
    (Failure (Subscript),s)`
  (rw[fetch "-" "hash_tab_sub_def"]>>
  fs[Marray_sub_def]);

Theorem Mupdate_eqn[simp] `
  ∀e x n ls.
  Mupdate e x n ls =
  if n < LENGTH ls then
    Success (LUPDATE x n ls)
  else
    Failure e`
  (ho_match_mp_tac Mupdate_ind>>rw[]>>
  simp[Once Mupdate_def]>>
  Cases_on`ls`>>fs[]>>
  IF_CASES_TAC>>fs[LUPDATE_def]>>
  Cases_on`n`>>fs[LUPDATE_def]);

Theorem update_hash_tab_eqn[simp] `
  update_hash_tab n t s =
  if n < LENGTH s.hash_tab then
     (Success (),s with hash_tab := LUPDATE t n s.hash_tab)
  else
     (Failure (Subscript),s)`
  (rw[fetch "-" "update_hash_tab_def"]>>
  fs[Marray_update_def]);

val good_table_def = Define`
  good_table enc n s ⇔
  EVERY (λls. EVERY (λ(x,y). enc x = y) ls) s.hash_tab ∧
  LENGTH s.hash_tab = n`

val lookup_insert_table_correct = Q.prove(`
  good_table enc n s ∧
  0 < n ⇒
  ∃s'.
  lookup_insert_table enc n aa s = (Success (enc aa), s') ∧
  good_table enc n s'`,
  rw[]>>fs[lookup_insert_table_def]>>
  simp msimps>>
  reverse IF_CASES_TAC
  >- (
    fs[good_table_def]>>
    rfs[])>>
  simp[]>>
  TOP_CASE_TAC
  >- (
    fs[good_table_def]>>
    match_mp_tac IMP_EVERY_LUPDATE>>fs[]>>
    drule EL_MEM>>
    metis_tac[EVERY_MEM])
  >>
  fs[good_table_def]>>
  drule EL_MEM>>
  drule ALOOKUP_MEM>>
  fs[EVERY_MEM]>>
  rw[]>> first_x_assum drule>>
  disch_then drule>>
  fs[]);

val enc_line_hash_correct = Q.prove(`
  ∀line.
  good_table enc n s ∧ 0 < n ⇒
  ∃s'.
  enc_line_hash enc skip_len n line s =
  (Success (enc_line enc skip_len line),s') ∧
  good_table enc n s'`,
  Cases>>fs[enc_line_hash_def,enc_line_def]>>
  fs msimps>>
  qmatch_goalsub_abbrev_tac`lookup_insert_table _ _ aa`>>
  rw[]>>
  drule lookup_insert_table_correct>>rw[]>>simp[]);

val enc_line_hash_ls_correct = Q.prove(`
  ∀xs s.
  good_table enc n s ∧ 0 < n ⇒
  ∃s'.
  enc_line_hash_ls enc skip_len n xs s =
  (Success (MAP (enc_line enc skip_len) xs), s') ∧
  good_table enc n s'`,
  Induct>>fs[enc_line_hash_ls_def]>>
  fs msimps>>
  rw[]>> simp[]>>
  drule enc_line_hash_correct>>
  disch_then (qspec_then `h` assume_tac)>>rfs[]>>
  first_x_assum drule>>
  rw[]>>simp[]);

val enc_sec_hash_ls_correct = Q.prove(`
  ∀xs s.
  good_table enc n s ∧ 0 < n ⇒
  ∃s'.
  enc_sec_hash_ls enc skip_len n xs s =
  (Success (MAP (enc_sec enc skip_len) xs), s') ∧
  good_table enc n s'`,
  Induct>>fs[enc_sec_hash_ls_def]>>
  fs msimps>>
  rw[]>> simp[]>>
  TOP_CASE_TAC>>simp[]>>
  drule enc_line_hash_ls_correct>>
  simp[]>>
  disch_then(qspec_then`l` assume_tac)>>fs[]>>
  first_x_assum drule>>rw[]>>
  simp[enc_sec_def]);

Theorem enc_secs_correct`
  enc_secs enc n xs =
  (enc_sec_list enc xs)`
  (
  fs[enc_secs_def,enc_secs_aux_def]>>
  fs[fetch "-" "run_ienc_state_64_def",run_def]>>
  simp[enc_sec_hash_ls_full_def]>>
  qmatch_goalsub_abbrev_tac `_ enc sl nn xs s`>>
  qspecl_then [`sl`,`nn`,`enc`,`xs`,`s`] mp_tac (GEN_ALL enc_sec_hash_ls_correct)>>
  impl_tac>-
    (unabbrev_all_tac>>fs[good_table_def,EVERY_REPLICATE])>>
  rw[]>>
  fs[enc_sec_list_def]);

val _ = export_theory();
