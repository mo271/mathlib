/-
Copyright (c) 2022 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import tactic.move_add
import data.polynomial.degree.lemmas

/-! # `compute_degree` a tactic for compute `nat_degree`s of polynomials

This file defines two main tactics `compute_degree` and `compute_degree_le`.
Applied when the goal is of the form `f.nat_degree = d` or `f.nat_degree ≤ d`, they try to solve it.

See the corresponding doc-strings for more details.

##  Future work

* Add functionality to deal with exponents that are not necessarily natural numbers.
  It may not be hard to allow an option argument to be passed to `compute_degree` that would
  let the tactic know which one is the term of highest degree.  This would bypass the step
  where the exponents get sorted and may make it accessible to continue with the rest of the
  argument with minimal change.
* Add functionality to close `monic` goals and compute `leading_coeff`s.
* Add support for proving goals of the from `f.nat_degree ≠ 0`.
* Add support for `degree` (as opposed to just `nat_degree`).

##  Implementation details

We start with a goal of the form `f.nat_degree = d` (the case `f.nat_degree ≤ d` follows a similar,
easier pattern).

First, we focus on an elementary term of the polynomial `f` and we extract the degree in easy cases:
if `f` is
* `monomial n r`, then we guess `n`,
* `C a`, then we guess `0`,
* `polynomial.X`, then we guess `1`,
* `X ^ n`, then we guess `n`,
* everything else, then we guess `f.nat_degree`.
This happens in `extract_deg_single_term`.

Second, with input a product, we sum the guesses made above on each factor and add them up.
This happens in `extract_deg_single_summand`.

Third, we scan the summands of `f`, searching for one with highest guessed degree.  Here, if a
guess is not a closed term of type `ℕ`, the tactic fails.  This could be improved, but is not
currently in scope.  We return the first term with highest degree and the guessed degree.
This happens in `extract_top_degree_term_and_deg`.

Now, `compute_degree_le` chains together a few lemmas to conclude.  It guesses that the degree of a
sum of terms is at most the degree of each individual term.

_Heuristic:_ there is no cancellation among the terms, at least the ones of highest degree.

Finally, `compute_degree` takes one extra step.  It isolates the term of highest guessed degree
and assumes that all remaining terms have smaller degree.  It checks that the degree of the highest
term is what it is claimed (and further assumes that the highest term is a pure `X`-power, `X ^ n`,
a pure `X` term or a product of one of these by `C a` and checks that the assumption `a ≠ 0` is in
context).
`compute_degree` then outsources the rest of the computation to `compute_degree_le`, once the goal
has been appropriately replaced.

###  Error reporting
The tactics report that
* naturals involving variables are not allowed in exponents;
* when a simple lemma application would have sufficed (via a `Try this: ...`);
* when the guessed degree is incompatible with the goal, suggesting a sharper value.
-/

namespace polynomial
/-- Useful to expose easy hypotheses:
* `df` should be dealt with by `single_term_resolve`,
* `dg` should be dealt with by `compute_degree_le`.
-/
lemma nat_degree_add_left_succ {R : Type*} [semiring R] (n : ℕ) (f g : polynomial R)
  (df : f.nat_degree = n + 1) (dg : g.nat_degree ≤ n) :
  (g + f).nat_degree = n + 1 :=
by rwa nat_degree_add_eq_right_of_nat_degree_lt (dg.trans_lt (nat.lt_of_succ_le df.ge))

lemma nat_degree_bit0 {R : Type*} [semiring R] (a : polynomial R) :
  (bit0 a).nat_degree ≤ a.nat_degree :=
(nat_degree_add_le _ _).trans (by simp)

lemma nat_degree_bit1 {R : Type*} [semiring R] (a : polynomial R) :
  (bit1 a).nat_degree ≤ a.nat_degree :=
(nat_degree_add_le _ _).trans (by simp [nat_degree_bit0])

lemma nat_degree_zero' {R : Type*} [semiring R] :
  (0 : polynomial R).nat_degree = 0 :=
nat_degree_zero

lemma nat_degree_one' {R : Type*} [semiring R] :
  (1 : polynomial R).nat_degree = 0 :=
nat_degree_one

end polynomial

namespace tactic
open expr

meta def is_num : expr → option ℕ
| `(has_zero.zero) := some 0
| `(has_one.one) := some 1
| `(bit0 %%a) := match is_num a with
  | some an := some (bit0 an)
  | none := none
  end
| `(bit1 %%a) := match is_num a with
  | some an := some (bit1 an)
  | none := none
  end
| _ := none

meta def convert_num_to_C_num (a : expr) : tactic unit :=
match is_num a with
| some an := do
  `(@polynomial %%R %%inst) ← infer_type a,
  n_eq_Cn ← to_expr ``(%%a = polynomial.C (%%an : %%R)),
  (_, nproof) ← solve_aux n_eq_Cn
    `[ simp only [nat.cast_bit1, nat.cast_bit0, nat.cast_one, C_bit1, C_bit0, map_one] ],
  rewrite_target nproof
| none := skip
end

/-- `C_mul_terms e` produces a proof of `e.nat_degree = ??` in the case in which `e` is of the form
`C a * X (^ n)?`.  It has special support for `C 1`, when there is a `nontrivial` assumption on the
base-semiring. -/
meta def C_mul_terms : expr → tactic unit
| `(has_mul.mul %%a %%X) := do match X with
  | `(polynomial.X) := do  -- a * X
    convert_num_to_C_num a,
    refine ``(polynomial.nat_degree_C_mul_X _ _),
    try assumption
  | `(@has_pow.pow (@polynomial %%R %%nin) ℕ %%inst %%mX %%n) := do  -- a * X ^ n
    convert_num_to_C_num a,
    refine ``(polynomial.nat_degree_C_mul_X_pow %%n _ _),
    assumption <|> interactive.exact ``(one_ne_zero) <|> skip
  | _ := trace "The leading term is not of the form\n`C a * X (^ n)`\n\n"
  end
| _ := fail "The leading term is not of the form\n`C a * X (^ n)`\n\n"

/--  Let `e` be an expression.  Assume that `e` is either a pure `X`-power or `C a` times a pure
`X`-power in a polynomial ring over `R`.
`single_term_resolve e` produces a proof of the goal `e.nat_degree = d`, where `d` is the
exponent of `X`.

Assumptions: either there is an assumption in context asserting that the constant in front of the
power of `X` is non-zero, or the tactic `nontriviality R` succeeds. -/
meta def single_term_resolve : expr → tactic unit
| (app `(⇑(@polynomial.monomial %%R %%inst %%n)) x) :=
  refine ``(polynomial.nat_degree_monomial_eq %%n _) *>
  assumption <|> interactive.exact ``(one_ne_zero) <|> skip
| (app `(⇑(@polynomial.C %%R %%inst)) x) :=
  interactive.exact ``(polynomial.nat_degree_C _)
| `(@has_pow.pow (@polynomial %%R %%nin) ℕ %%inst %%mX %%n) :=
  nontriviality_by_assumption R *>
  refine ``(polynomial.nat_degree_X_pow %%n)
| `(@polynomial.X %%R %%inst) :=
  nontriviality_by_assumption R *>
  interactive.exact ``(polynomial.nat_degree_X)
| e := C_mul_terms e

/--
 `guess_degree e` assumes that `e` is a single summand of a polynomial and makes an attempt
 at guessing its degree.  It returns a closed natural number, via `expr.to_nat` or fails.
Currently, `guess_degree` supports:
* `monomial n r`,     guessing `n`,
* `C a`               guessing `0`,
*  `bit0 f, bit1 f`,  guessing `guess_degree f`,
                               (this could give wrong results, e.g. `bit0 f = 0` if the
                                characteristic of the ground ring is `2`),
* `polynomial.X`,     guessing `1`,
* `polynomial.X ^ n`, guessing `n`,
* `f * g`,            guessing `guess_degree f + guess_degree g`,
* on anything else it fails.
 -/
meta def guess_degree : expr → tactic ℕ
| `(has_zero.zero)         := return 0
| `(has_one.one)           := return 0
| `(bit0 %%a)              := guess_degree a
| `(bit1 %%a)              := guess_degree a
| `(has_mul.mul %%a %%b)   := do da ← guess_degree a, db ← guess_degree b,
                                return $ da + db
| `(polynomial.X)          := return 1
| (app `(⇑polynomial.C) x) := return 0
| `(polynomial.X ^ %%n)    := n.to_nat <|>
  fail format!"The exponent of 'X ^ {n}' is not a closed natural number"
| (app `(⇑(polynomial.monomial %%n)) x) := n.to_nat <|>
  fail format!"The exponent of 'monomial {n} {x}' is not a closed natural number"
| e                                     := fail format!"cannot guess the degree of '{e}'"

meta def guess_degree_expr : expr → expr
| `(has_zero.zero)         := `(0)
| `(has_one.one)           := `(0)
| `(bit0 %%a)              := guess_degree_expr a
| `(bit1 %%a)              := guess_degree_expr a
| `(has_mul.mul %%a %%b)   := let da := guess_degree_expr a in let db := guess_degree_expr b in
                              expr.mk_app `(has_add.add : ℕ → ℕ → ℕ) [da, db]
| `(polynomial.X)          := `(1)
| (app `(⇑polynomial.C) x) := `(0)
| `(polynomial.X ^ %%n)    := n
| (app `(⇑(polynomial.monomial %%n)) x) := n
| e                                     := `(0) --expr.mk_app `(polynomial.nat_degree) [e]

meta def single_term_resolve_le : expr → tactic unit
| `(%%a * %%Xp) := do
  let da  := guess_degree_expr a,
  let dXp := guess_degree_expr Xp,
  refine ``(polynomial.nat_degree_mul_le.trans ((add_le_add _ _).trans (_ : %%da + %%dXp ≤ _)))
| `(has_one.one) :=
   refine ``(polynomial.nat_degree_one.le.trans (nat.zero_le _))
| `(has_zero.zero) := refine ``(polynomial.nat_degree_zero.le.trans (nat.zero_le _))
| `(bit0 %%a) := do refine ``((polynomial.nat_degree_bit0 %%a).trans _),
  single_term_resolve_le a
| `(bit1 %%a) := do refine ``((polynomial.nat_degree_bit1 %%a).trans _),
  single_term_resolve_le a
| (app `(⇑(@polynomial.monomial %%R %%inst %%n)) x) :=
  refine ``((polynomial.nat_degree_monomial_le %%x).trans _)
| (app `(⇑polynomial.C) x) :=
  interactive.exact ``((polynomial.nat_degree_C _).le.trans (nat.zero_le _))
| `(@has_pow.pow (@polynomial %%R %%nin) ℕ %%inst %%mX %%n) :=
  refine ``((polynomial.nat_degree_X_pow_le %%n).trans _)
| `(@polynomial.X %%R %%inst) :=
  refine ``(polynomial.nat_degree_X_le.trans _)
--| (app f Xp) := do
--  match f with
--  | (app `(has_mul.mul) a) := do
--      da ← guess_degree a, dXp ← guess_degree Xp,trace da, trace dXp,
--  refine ``(polynomial.nat_degree_mul_le.trans ((add_le_add _ _).trans (_ : %%da + %%dXp ≤ _)))
--  any_goals' (try `[ norm_num])
  --,
--  gs ← get_goals,trace gs,
--  gs.mmap' (λ s : expr, match s with
--  | `(%%lhs ≤ %%rhs) := infer_type lhs >>= trace >> infer_type rhs >>= trace
--  | _ := fail "sorry"
--  end)
--  | _ := fail "oh no!"
--  end
--  single_term_resolve_le a,
--  single_term_resolve_le Xp
--| (app (app `(has_mul.mul) %%a) %%Xp) := do da ← guess_degree a, dXp ← guess_degree Xp,trace da, trace dXp,
--  refine ``(polynomial.nat_degree_mul_le.trans ((add_le_add _ _).trans (_ : %%da + %%dXp ≤ _))),
--  gs ← get_goals,trace gs,
--  gs.mmap' (λ s : expr, match s with
--  | `(%%lhs ≤ %%rhs) := infer_type lhs >>= trace >> infer_type rhs >>= trace
--  | _ := skip
--  end)
----  single_term_resolve_le a,
----  single_term_resolve_le Xp
| e := try `[norm_num] >> try assumption --skip--C_mul_terms e

/-- `extract_top_degree_term_and_deg e` takes an expression `e` looks for summands in `e`
(assuming the Type of `e` is `R[X]`), and produces the pairs `(e',deg)`, where `e'` is
a summand of `e` of maximal guessed degree equal to `deg`.

The tactic fails if `e` contains no summand (this probably means something else went wrong
somewhere else). -/
meta def extract_top_degree_term_and_deg (e : expr) : tactic (expr × ℕ) :=
do summ ← e.list_summands,
  nat_degs ← summ.mmap guess_degree,
  let summ_and_degs := summ.zip nat_degs in
  match summ_and_degs.argmax (λ e : expr × ℕ, e.2) with
  | none := fail
      "'`compute_degree`' could not find summands: something has gone very wrong!\n\n"
  | (some first) := return first
  end

/--  These are the cases in which an easy lemma computes the degree. -/
meta def single_term_suggestions : tactic unit := do
interactive.exact ``(polynomial.nat_degree_X_pow _), trace "Try this: exact nat_degree_X_pow _" <|>
interactive.exact ``(polynomial.nat_degree_C _),     trace "Try this: exact nat_degree_C _"     <|>
interactive.exact ``(polynomial.nat_degree_X),       trace "Try this: exact nat_degree_X"       <|>
fail "easy lemmas do not work"

end tactic

namespace tactic.interactive
open tactic

/--  `compute_degree_le` tries to solve a goal of the form `f.nat_degree ≤ d`, where `d : ℕ` and `f`
satisfies:
* `f` is a sum of expression of the form
  `C a * X ^ n, C a * X, C a, X ^ n, X, monomial n a, monomial n a * monomial m b`,
* all exponents and the `n` in `monomial n a` are *closed* terms of type `ℕ`.

If the given degree is smaller than the one that the tactic computes,
then the tactic suggests the degree that it computed.

The tactic also reports when it is used with non-closed natural numbers as exponents. -/
meta def compute_degree_le : tactic unit :=
do repeat $ refine ``((polynomial.nat_degree_add_le_iff_left _ _ _).mpr _),
  (repeat $ do
   `(polynomial.nat_degree %%lhs ≤ %%rhs) ← target,
    single_term_resolve_le lhs),
  try $ any_goals' `[ norm_num ],
  try $ any_goals' assumption
/-
  gs ← get_goals,--gs.mmap infer_type >>= trace, failed
  gs.mmap' (λ s,
--   infer_type s >>= trace >>
match s with
    | (expr.app f g) := trace f >> trace g-- >>
--    | (expr.app `(has_le.le) (`(polynomial.nat_degree %%lhs) )) := trace lhs-- >>
--    | (expr.app (expr.app `(has_le.le) `(polynomial.nat_degree) %%lhs) %%deg) :=
--     try $ single_term_resolve_le lhs
    | e := infer_type e >>= trace >>fail "oh what a goal!"
      end)
-/
/-
  `[repeat { rw polynomial.monomial_mul_monomial }],
  try $ any_goals' $ refine ``((polynomial.nat_degree_monomial_le _).trans _),
  repeat $ refine ``((polynomial.nat_degree_C_mul_le _ _).trans _),
  repeat $ refine ``((polynomial.nat_degree_X_pow_le _).trans _),
  repeat $ refine ``(polynomial.nat_degree_X_le.trans _),
  `[try { any_goals { norm_num } }],
  try $ any_goals' $ assumption <|>
do `(polynomial.nat_degree %%tl ≤ %%tr) ← target |
    fail "Goal is not of the form `f.nat_degree ≤ d\n\n",
  (lead,m') ← extract_top_degree_term_and_deg tl,
  td ← eval_expr ℕ tr | fail
    "currently, there is no support for some of the terms appearing in the polynomial",
  if td < m' then
    do pptl ← pp tl, ppm' ← pp m',
    trace sformat!"should the degree be '{m'}'?\n\n",
    trace sformat!"Try this: {pptl}.nat_degree ≤ {ppm'}", failed
  else fail "sorry, the tactic failed, but I do not know why."
-/

/--  `compute_degree` tries to solve a goal of the form `f.nat_degree = d` or  `f.degree = d`,
where `d : ℕ` and `f` satisfies:
* `f` is a sum of expressions of the form
  `C a * X ^ n, C a * X, C a, X ^ n, X, monomial n a, monomial n a * monomial m b`;
* all exponents and the `n` in `monomial n a` are *closed* terms of type `ℕ`;
* the term with largest exponent is `C a * X ^ n, X ^ n, C a * X, X, C a` and is the unique term of
  its degree (repetitions are allowed in terms of smaller degree);
* if the leading term involves a product with `C a`, there must be in context the assumption
  `a ≠ 0`;
* if the goal is computing `degree`, instead of `nat_degree`, then the expected degree `d` should
  not be `⊥`.

If the given degree does not match what the tactic computes,
then the tactic suggests the degree that it computed.

The tactic also reports when it is used with non-closed natural numbers as exponents. -/
meta def compute_degree : tactic unit :=
do t ← target,
  match t with
  | `(polynomial.nat_degree %%tl = %%tr) := do
    (lead,m') ← extract_top_degree_term_and_deg tl,-- <|> fail
--      "currently, there is no support for some of the terms appearing in the polynomial",
    td ← eval_expr ℕ tr,
    if m' ≠ td then
      do pptl ← pp tl, ppm' ← pp m',
        trace sformat!"should the nat_degree be '{m'}'?\n\n",
        trace sformat!"Try this: {pptl}.nat_degree = {ppm'}", failed
    else
      move_op.with_errors ``((+)) [(ff, pexpr.of_expr lead)] none,
      refine ``(polynomial.nat_degree_add_left_succ _ %%lead _ _ _),
      single_term_resolve lead,
      compute_degree_le
  | `(polynomial.degree %%tl = %%tr) := do
    refine ``((polynomial.degree_eq_iff_nat_degree_eq_of_pos _).mpr _),
    interactive.rotate,
    `(_ = %%tr1) ← target,
    td ← eval_expr ℕ tr1,
    (lead,m') ← extract_top_degree_term_and_deg tl,
    if m' ≠ td then
      do pptl ← pp tl, ppm' ← pp m',
        trace sformat!"should the degree be '{m'}'?\n\n",
        trace sformat!"Try this: {pptl}.degree = {ppm'}", failed
    else
      move_op.with_errors ``((+)) [(ff, pexpr.of_expr lead)] none,
      refine ``(polynomial.nat_degree_add_left_succ _ %%lead _ _ _),
      single_term_resolve lead,
      compute_degree_le
  |_ := fail "Goals is not of the form\n`f.nat_degree = d` or `f.degree = d`"
  end

add_tactic_doc
{ name := "compute_degree_le",
  category := doc_category.tactic,
  decl_names := [`tactic.interactive.compute_degree],
  tags := ["arithmetic, finishing"] }

add_tactic_doc
{ name := "compute_degree",
  category := doc_category.tactic,
  decl_names := [`tactic.interactive.compute_degree],
  tags := ["arithmetic, finishing"] }

end tactic.interactive
