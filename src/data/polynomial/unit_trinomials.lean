/-
Copyright (c) 2022 Thomas Browning. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning
-/

import analysis.complex.polynomial
import data.polynomial.mirror

namespace polynomial
open_locale polynomial

open finset

lemma int.is_unit_mul_self {a : ℤ} (ha : is_unit a) : a * a = 1 :=
(int.is_unit_eq_one_or ha).elim (λ h, h.symm ▸ rfl) (λ h, h.symm ▸ rfl)

lemma int.is_unit_sq {a : ℤ} (ha : is_unit a) : a ^ 2 = 1 :=
by rw [sq, int.is_unit_mul_self ha]

@[simp] lemma int.units_sq (u : ℤˣ) : u ^ 2 = 1 :=
by rw [units.ext_iff, units.coe_pow, units.coe_one, int.is_unit_sq u.is_unit]

@[simp] lemma int.units_mul_self (u : ℤˣ) : u * u = 1 :=
by rw [←sq, int.units_sq]

lemma int.units_inv_eq_self (u : ℤˣ) : u⁻¹ = u :=
by rw [inv_eq_iff_mul_eq_one, int.units_mul_self]

section semiring

variables {R : Type*} [semiring R] (p : R[X]) {k m n : ℕ} {u v w : R}

lemma trinomial_support_le : (C u * X ^ k + C v * X ^ m + C w * X ^ n).support ⊆ {k, m, n} :=
support_add.trans (union_subset (support_add.trans (union_subset (support_C_mul_X_pow'.trans
  (singleton_subset_iff.mpr (mem_insert_self k {m, n}))) (support_C_mul_X_pow'.trans
  (singleton_subset_iff.mpr (mem_insert_of_mem (mem_insert_self m {n}))))))
  (support_C_mul_X_pow'.trans (singleton_subset_iff.mpr
  (mem_insert_of_mem (mem_insert_of_mem $ mem_singleton_self n)))))

lemma trinomial_coeff_k (hkm : k < m) (hmn : m < n) :
  coeff (C u * X ^ k + C v * X ^ m + C w * X ^ n) k = u :=
by rw [coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow,
  if_pos rfl, if_neg hkm.ne, if_neg (hkm.trans hmn).ne, add_zero, add_zero]

lemma trinomial_coeff_m (hkm : k < m) (hmn : m < n) :
  coeff (C u * X ^ k + C v * X ^ m + C w * X ^ n) m = v :=
by rw [coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow,
  if_neg hkm.ne', if_pos rfl, if_neg hmn.ne, zero_add, add_zero]

lemma trinomial_coeff_n (hkm : k < m) (hmn : m < n) :
  coeff (C u * X ^ k + C v * X ^ m + C w * X ^ n) n = w :=
by rw [coeff_add, coeff_add, coeff_C_mul_X_pow, coeff_C_mul_X_pow, coeff_C_mul_X_pow,
  if_neg (hkm.trans hmn).ne', if_neg hmn.ne', if_pos rfl, zero_add, zero_add]

lemma trinomial_support_eq (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) (hv : v ≠ 0) (hw : w ≠ 0) :
  (C u * X ^ k + C v * X ^ m + C w * X ^ n).support = {k, m, n} :=
subset_antisymm trinomial_support_le (by
{ rw [insert_subset, mem_support_iff, trinomial_coeff_k hkm hmn, insert_subset, mem_support_iff,
    trinomial_coeff_m hkm hmn, singleton_subset_iff, mem_support_iff, trinomial_coeff_n hkm hmn],
  exact ⟨hu, hv, hw⟩ })

lemma trinomial_nat_degree (hkm : k < m) (hmn : m < n) (hw : w ≠ 0) :
  nat_degree (C u * X ^ k + C v * X ^ m + C w * X ^ n) = n :=
begin
  refine nat_degree_eq_of_degree_eq_some (le_antisymm (sup_le (λ i hi, _))
    (le_degree_of_ne_zero (by rwa trinomial_coeff_n hkm hmn))),
  have := trinomial_support_le hi,
  rw [mem_insert, mem_insert, mem_singleton] at this,
  rcases this with rfl | rfl | rfl,
  { exact with_bot.coe_le_coe.mpr (hkm.trans hmn).le },
  { exact with_bot.coe_le_coe.mpr hmn.le },
  { exact le_rfl },
end

lemma trinomial_nat_trailing_degree (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) :
  nat_trailing_degree (C u * X ^ k + C v * X ^ m + C w * X ^ n) = k :=
begin
  refine nat_trailing_degree_eq_of_trailing_degree_eq_some (le_antisymm
    (le_trailing_degree_of_ne_zero (by rwa trinomial_coeff_k hkm hmn)) (le_inf (λ i hi, _))),
  have := trinomial_support_le hi,
  rw [mem_insert, mem_insert, mem_singleton] at this,
  rcases this with rfl | rfl | rfl,
  { exact le_rfl },
  { exact with_top.coe_le_coe.mpr hkm.le },
  { exact with_top.coe_le_coe.mpr (hkm.trans hmn).le },
end

lemma trinomial_mirror (hkm : k < m) (hmn : m < n) (hu : u ≠ 0) (hw : w ≠ 0) :
  mirror (C u * X ^ k + C v * X ^ m + C w * X ^ n) =
    C w * X ^ k + C v * X ^ (n - m + k) + C u * X ^ n :=
by rw [mirror, trinomial_nat_trailing_degree hkm hmn hu, reverse, trinomial_nat_degree hkm hmn hw,
  reflect_add, reflect_add, reflect_C_mul_X_pow, reflect_C_mul_X_pow, reflect_C_mul_X_pow,
  rev_at_le (hkm.trans hmn).le, rev_at_le hmn.le, rev_at_le le_rfl, add_mul, add_mul, mul_assoc,
  mul_assoc, mul_assoc, ←pow_add, ←pow_add, ←pow_add, nat.sub_add_cancel (hkm.trans hmn).le,
  nat.sub_self, zero_add, add_comm, add_assoc, add_comm (C u * X ^ n)]

/-- A unit trinomial is a trinomial whose three nonzero coeffients are units. -/
def is_unit_trinomial := ∃ {k m n : ℕ} (hkm : k < m) (hmn : m < n) {u v w : R}
  (hu : is_unit u) (hv : is_unit v) (hw : is_unit w), p = C u * X ^ k + C v * X ^ m + C w * X ^ n

end semiring

section domain

variables {R : Type*} [comm_ring R] [is_domain R] (p : R[X])

lemma coeff_mul_mirror :
  coeff (p * mirror p) (nat_degree p + nat_trailing_degree p) = p.sum (λ n, (^ 2)) :=
begin
  rw [coeff_mul, nat.sum_antidiagonal_eq_sum_range_succ_mk],
  refine (sum_congr rfl (λ n hn, _)).trans (p.sum_eq_of_subset (λ n, (^ 2))
    (λ n, zero_pow zero_lt_two) _ (λ n hn, mem_range_succ_iff.mpr
    ((le_nat_degree_of_mem_supp n hn).trans (nat.le_add_right _ _)))).symm,
  rw [coeff_mirror, ←rev_at_le (mem_range_succ_iff.mp hn), rev_at_invol, ←sq],
end

lemma nat_degree_mul_mirror : nat_degree (p * mirror p) = 2 * nat_degree p :=
begin
  by_cases hp : p = 0,
  { rw [hp, zero_mul, nat_degree_zero, mul_zero] },
  rw [nat_degree_mul hp (mt p.mirror_eq_zero.mp hp), mirror_nat_degree, two_mul],
end

lemma nat_trailing_degree_mul_mirror :
  nat_trailing_degree (p * mirror p) = 2 * nat_trailing_degree p :=
begin
  by_cases hp : p = 0,
  { rw [hp, zero_mul, nat_trailing_degree_zero, mul_zero] },
  rw [nat_trailing_degree_mul hp (mt p.mirror_eq_zero.mp hp), mirror_nat_trailing_degree, two_mul],
end

variables {p}

lemma is_unit_trinomial.not_is_unit (hp : is_unit_trinomial p) : ¬ is_unit p :=
begin
  obtain ⟨k, m, n, hkm, hmn, u, v, w, hu, hv, hw, rfl⟩ := hp,
  exact λ h, ne_zero_of_lt hmn ((trinomial_nat_degree hkm hmn hw.ne_zero).symm.trans
    (nat_degree_eq_of_degree_eq_some (degree_eq_zero_of_is_unit h))),
end

end domain

variables {p : ℤ[X]}

lemma is_unit_trinomial_iff : is_unit_trinomial p ↔ coeff (p * mirror p)
  ((nat_degree (p * mirror p) + nat_trailing_degree (p * mirror p)) / 2) = 3 :=
begin
  rw [nat_degree_mul_mirror, nat_trailing_degree_mul_mirror, ←mul_add,
      nat.mul_div_right _ zero_lt_two, coeff_mul_mirror],
  refine ⟨_, λ hp, _⟩,
  { rintros ⟨k, m, n, hkm, hmn, u, v, w, hu, hv, hw, rfl⟩,
    rw [sum_def, trinomial_support_eq hkm hmn hu.ne_zero hv.ne_zero hw.ne_zero,
      sum_insert (mt mem_insert.mp (not_or hkm.ne (mt mem_singleton.mp (hkm.trans hmn).ne))),
      sum_insert (mt mem_singleton.mp hmn.ne), sum_singleton,
      trinomial_coeff_k hkm hmn, trinomial_coeff_m hkm hmn, trinomial_coeff_n hkm hmn],
    simp only,
    simp_rw [int.is_unit_sq hu, int.is_unit_sq hv, int.is_unit_sq hw],
    refl },
  { sorry },
end

#print int.is_unit_eq_one_or

lemma is_unit_trinomial.irreducible1 (hp : is_unit_trinomial p)
  (h : ∀ q : ℤ[X], q ∣ p → q ∣ mirror p → is_unit q) :
  irreducible p :=
begin
  refine irreducible_of_mirror hp.not_is_unit (λ q hpq, _) h,
  have key : is_unit_trinomial q := by rwa [is_unit_trinomial_iff, ←hpq, ←is_unit_trinomial_iff],
  /-
  * Use `nat_degree_mul_mirror` and `nat_trailing_degree_mul_mirror` to show that `p` and `q`
    have the same `nat_degree` and `nat_trailing_degree`.
  * WLOG mirror to make middle degrees match (both ≤ half)
  * WLOG negate to make leading coefficients match (both +1)


  -/



  -- this is a big result!
  sorry
end

lemma is_unit_trinomial.irreducible2 (hp : is_unit_trinomial p)
  (h : ∀ z : ℂ, ¬ (aeval z p = 0 ∧ aeval z (mirror p) = 0)) : irreducible p :=
begin
  refine hp.irreducible1 (λ q hq hq', _),
  suffices : ¬ (0 < q.nat_degree),
  { rw [not_lt, nat.le_zero_iff] at this,
    rw [eq_C_of_nat_degree_eq_zero this, is_unit_C, ←this],
    cases hq with h fgh,
    apply @is_unit_of_mul_is_unit_left _ _ q.leading_coeff h.leading_coeff,
    rw [←leading_coeff_mul, ←fgh],
    sorry },
  intro hq'',
  have inj : function.injective (algebra_map ℤ ℂ) := (algebra_map ℤ ℂ).injective_int,
  rw [nat_degree_pos_iff_degree_pos, ←degree_map_eq_of_injective inj] at hq'',
  cases complex.exists_root hq'' with z hz,
  apply h z,
  rw [is_root, eval_map, ←aeval_def] at hz,
  split,
  { cases hq with g' hg',
    rw [hg', aeval_mul, hz, zero_mul] },
  { cases hq' with g' hg',
    rw [hg', aeval_mul, hz, zero_mul] },
end

-- figure out what the most "user-friendly" statement is (it's probably not the one below)

lemma is_unit_trinomial.irreducible3 (hp : is_unit_trinomial p)
  (hp1 : ¬ X ∣ p) (hp2 : ¬ X ^ 2 + X + 1 ∣ p) (hp3 : ¬ X ^ 2 - X + 1 ∣ p) : irreducible p :=
begin
  refine hp.irreducible2 (λ z hz, _),
  sorry,
end

lemma selmer_irreducible {n : ℕ} (hn : 1 < n) : irreducible (X ^ n - X - 1 : ℤ[X]) :=
begin
  let p : ℤ[X] := X ^ n - X - 1,
  have hp : is_unit_trinomial p,
  { refine ⟨0, 1, n, zero_lt_one, hn, 1, -1, -1, is_unit_one, is_unit_one.neg, is_unit_one.neg, _⟩,
    rw [C_neg, neg_mul, neg_mul, C_1, one_mul, one_mul, one_mul, pow_zero, pow_one],
    sorry },
  refine hp.irreducible3 _ _ _,
  { sorry },
  { sorry },
  { sorry },
end

end polynomial
