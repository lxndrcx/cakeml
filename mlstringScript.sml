open HolKernel boolLib bossLib lcsymtacs stringTheory
val _ = ParseExtras.temp_tight_equality()
val _ = new_theory"mlstring"

(* Defines strings as a separate type from char list. This theory should be
   moved into HOL, either as its own theory, or as an addendum to stringTheory *)

val _ = Datatype`mlstring = strlit string`

val implode_def = Define`
  implode = strlit`

val explode_def = Define`
  explode (strlit ls) = ls`
val _ = export_rewrites["explode_def"]

val explode_implode = store_thm("explode_implode",
  ``∀x. explode (implode x) = x``,
  rw[implode_def])

val implode_explode = store_thm("implode_explode",
  ``∀x. implode (explode x) = x``,
  Cases >> rw[implode_def])

val explode_11 = store_thm("explode_11",
  ``∀s1 s2. explode s1 = explode s2 ⇔ s1 = s2``,
  Cases >> Cases >> simp[])

(* TODO: don't explode/implode once CakeML supports string append *)
val strcat_def = Define`
  strcat s1 s2 = implode(explode s1 ++ explode s2)`
val _ = Parse.add_infix("^",480,Parse.LEFT)
val _ = Parse.overload_on("^",``λx y. strcat x y``)

val strlen_def = Define`
  strlen s = LENGTH (explode s)`

val mlstring_lt_def = Define`
  mlstring_lt (strlit s1) (strlit s2) ⇔
    string_lt s1 s2`

val _ = export_theory()
