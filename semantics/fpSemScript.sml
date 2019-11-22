(*Generated by Lem from fpSem.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory fpValTreeTheory fpOptTheory machine_ieeeTheory;

val _ = numLib.prefer_num();



val _ = new_theory "fpSem"

(*
  Definitions of the floating point operations used in CakeML.
*)
(*open import Pervasives*)
(*open import Lib*)
(*open import FpOpt*)
(*open import FpValTree*)

(*open import {hol} `machine_ieeeTheory`*)
(*open import {isabelle} `IEEE_Floating_Point.FP64`*)

(*type rounding*)

(**
  This defines the floating-point semantics operating on 64-bit words
**)
(*val fp64_lessThan     : word64 -> word64 -> bool*)
(*val fp64_lessEqual    : word64 -> word64 -> bool*)
(*val fp64_greaterThan  : word64 -> word64 -> bool*)
(*val fp64_greaterEqual : word64 -> word64 -> bool*)
(*val fp64_equal        : word64 -> word64 -> bool*)

(*val fp64_isNan      :word64 -> bool*)

(*val fp64_abs    : word64 -> word64*)
(*val fp64_negate : word64 -> word64*)
(*val fp64_sqrt   : rounding -> word64 -> word64*)

(*val fp64_add : rounding -> word64 -> word64 -> word64*)
(*val fp64_sub : rounding -> word64 -> word64 -> word64*)
(*val fp64_mul : rounding -> word64 -> word64 -> word64*)
(*val fp64_div : rounding -> word64 -> word64 -> word64*)

(*val fp64_mul_add : rounding -> word64 -> word64 -> word64 -> word64*)

(*val roundTiesToEven : rounding*)

(*val fp_cmp_comp : fp_cmp -> word64 -> word64 -> bool*)
val _ = Define `
 ((fp_cmp_comp:fp_cmp -> word64 -> word64 -> bool) fop=  ((case fop of
    FP_Less => fp64_lessThan
  | FP_LessEqual => fp64_lessEqual
  | FP_Greater => fp64_greaterThan
  | FP_GreaterEqual => fp64_greaterEqual
  | FP_Equal => fp64_equal
)))`;


(*
val fp_pred_comp : fp_pred -> word64 -> bool
let fp_pred_comp fp = match fp with
  | FP_NaN -> fp64_isNan
end
*)

(*val fp_uop_comp : fp_uop -> word64 -> word64*)
val _ = Define `
 ((fp_uop_comp:fp_uop -> word64 -> word64) fop=  ((case fop of
    FP_Abs => fp64_abs
  | FP_Neg => fp64_negate
  | FP_Sqrt => fp64_sqrt roundTiesToEven
)))`;


(*val fp_bop_comp : fp_bop -> word64 -> word64 -> word64*)
val _ = Define `
 ((fp_bop_comp:fp_bop -> word64 -> word64 -> word64) fop=  ((case fop of
    FP_Add => fp64_add roundTiesToEven
  | FP_Sub => fp64_sub roundTiesToEven
  | FP_Mul => fp64_mul roundTiesToEven
  | FP_Div => fp64_div roundTiesToEven
)))`;


val _ = Define `
 ((fpfma:word64 -> word64 -> word64 -> word64) v1 v2 v3=  (fp64_mul_add roundTiesToEven v2 v3 v1))`;


(*val fp_top_comp : fp_top -> word64 -> word64 -> word64 -> word64*)
val _ = Define `
 ((fp_top_comp:fp_top -> word64 -> word64 -> word64 -> word64) fop=  ((case fop of
    FP_Fma => fpfma
)))`;


(*val fp_opt_comp: forall 'v. fp_opt -> 'v -> 'v*)
val _ = Define `
 ((fp_opt_comp:fp_opt -> 'v -> 'v) sc v=  ((case sc of
    Opt => v
  | NoOpt => v
)))`;


(* Compression function for value trees,
   evaluating lazy trees into word64 or bool *)
(*val compress_word: fp_word_val -> word64*)
 val compress_word_defn = Defn.Hol_multi_defns `
 ((compress_word:fp_word_val -> word64) (Fp_const w1)=  w1)
    /\ ((compress_word:fp_word_val -> word64) (Fp_uop u1 v1)=  (fp_uop_comp u1 (compress_word v1)))
    /\ ((compress_word:fp_word_val -> word64) (Fp_bop b v1 v2)=
         (fp_bop_comp b (compress_word v1) (compress_word v2)))
    /\ ((compress_word:fp_word_val -> word64) (Fp_top t v1 v2 v3)=
         (fp_top_comp t (compress_word v1) (compress_word v2) (compress_word v3)))
    /\ ((compress_word:fp_word_val -> word64) (Fp_wopt sc v)=  (compress_word v))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) compress_word_defn;

(*val compress_bool : fp_bool_val -> bool*)
 val compress_bool_defn = Defn.Hol_multi_defns `
 (* compress_bool (Fp_pred p v1) = fp_pred_comp p (compress_word v1)
    and *) ((compress_bool:fp_bool_val -> bool) (Fp_cmp cmp v1 v2)=
         (fp_cmp_comp cmp (compress_word v1) (compress_word v2)))
    /\ ((compress_bool:fp_bool_val -> bool) (Fp_bopt sc v)=  (compress_bool v))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) compress_bool_defn;
val _ = export_theory()

