/-
Copyright (c) 2021 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anne Baanen
-/

import algebra.is_prime_pow
import field_theory.separable
import linear_algebra.free_module.finite.rank
import linear_algebra.free_module.pid
import linear_algebra.matrix.nonsingular_inverse
import ring_theory.dedekind_domain.ideal
import ring_theory.localization.module

/-!
# Ramification index and inertia degree

If `P : ideal S` lies over `p : ideal R` for the ring extension `f : R →+* S`
(assuming `P` and `p` are prime or maximal where needed).
The **ramification index** `ramification_idx f p P` is the multiplicity of `P` in `map f p`,
and the **inertia degree** `inertia_deg f p P` is the degree of the field extension
`(S / P) : (R / p)`.

The main theorem `sum_ramification_inertia` states that for all coprime `P` lying over `p`,
`Σ P, ramification_idx f p P * inertia_deg f p P` equals the degree of the field extension
`Frac(S) : Frac(R)`.

## Implementation notes

Often the above theory is set up in the case where:
 * `R` is the ring of integers of a number field `K`,
 * `L` is a finite separable extension of `K`,
 * `S` is the integral closure of `R` in `L`,
 * `p` and `P` are maximal ideals,
 * `P` is an ideal lying over `p`
We will try to relax the above hypotheses as much as possible.

-/

open_locale big_operators
open_locale non_zero_divisors

universes u v

variables {R : Type u} [comm_ring R]
variables {S : Type v} [comm_ring S] (f : R →+* S)
variables (p : ideal R) (P : ideal S)

open finite_dimensional
open ideal
open unique_factorization_monoid

section move_me

open fractional_ideal

open_locale pointwise

open_locale matrix

/-- Promote a surjective ring homomorphism to an equivalence by dividing out its kernel. -/
noncomputable def ideal.lift_equiv {R S : Type*} [comm_ring R] [comm_ring S] (f : R →+* S)
  (hf : function.surjective f)
  (I : ideal R) (h : f.ker = I) : (R ⧸ I) ≃+* S :=
ring_equiv.of_bijective (ideal.quotient.lift I f (λ x hx, f.mem_ker.mp (h.symm ▸ hx))) begin
  split,
  { rintro ⟨x⟩ ⟨y⟩ hxy,
    simp only [submodule.quotient.quot_mk_eq_mk, ideal.quotient.mk_eq_mk] at *,
    suffices : x - y ∈ I, { simpa only [ideal.quotient.eq, h] using this },
    have : f (x - y) = 0, { simpa only [map_sub, sub_eq_zero] using hxy },
    exact h ▸ f.mem_ker.mp this },
  { intro y,
    obtain ⟨x, hx⟩ := hf y,
    use ideal.quotient.mk I x,
    simpa using hx },
end

/-- Promote a surjective linear map to an equivalence by dividing out its kernel. -/
noncomputable def submodule.lift_equiv {R M N : Type*} [comm_ring R] [add_comm_group M]
  [add_comm_group N] [module R M] [module R N]
  (f : M →ₗ[R] N) (hf : function.surjective f)
  (p : submodule R M) (h : f.ker = p) : (M ⧸ p) ≃ₗ[R] N :=
linear_equiv.of_bijective (p.liftq f h.ge)
  (by { rintro ⟨x⟩ ⟨y⟩ hxy, simp only [submodule.quotient.quot_mk_eq_mk] at *,
        suffices : x - y ∈ p, { simpa only [submodule.quotient.eq, h] using this },
        have : f (x - y) = 0, { simpa only [map_sub, sub_eq_zero] using hxy },
        exact h ▸ linear_map.mem_ker.mp this })
  (by { intro y, obtain ⟨x, hx⟩ := hf y, use p.mkq x, simpa using hx })

theorem ideal.is_prime.mul_mem_iff {R : Type*} [comm_semiring R] {I : ideal R} (hI : I.is_prime)
  {a b : R} : a * b ∈ I ↔ a ∈ I ∨ b ∈ I :=
⟨hI.mem_or_mem, λ h, h.cases_on (I.mul_mem_right b) (I.mul_mem_left a)⟩

lemma ideal.is_prime.mul_mem_pow {R : Type*} [comm_ring R] [is_domain R]
  [is_dedekind_domain R]
  (I : ideal R) [hI : I.is_prime]
  {a b : R} {n : ℕ} (h : a * b ∈ I^n) : a ∈ I ∨ b ∈ I^n :=
begin
  cases n, { simp },
  by_cases hI0 : I = ⊥, { simpa [pow_succ, hI0] using h },
  simp only [← submodule.span_singleton_le_iff_mem, ideal.submodule_span_eq, ← ideal.dvd_iff_le,
    ← ideal.span_singleton_mul_span_singleton] at h ⊢,
  by_cases ha : I ∣ span {a},
  { exact or.inl ha },
  rw mul_comm at h,
  exact or.inr (prime.pow_dvd_of_dvd_mul_right ((ideal.prime_iff_is_prime hI0).mpr hI) _ ha h),
end

@[simp]
lemma ideal.quotient.mk_mem_map_mk {R : Type*} [comm_ring R] {I J : ideal R} {x : R} :
  ideal.quotient.mk I x ∈ J.map I^.quotient.mk ↔ x ∈ J ⊔ I :=
by rw [← ideal.mem_comap, ideal.comap_map_of_surjective _ ideal.quotient.mk_surjective,
       ← ring_hom.ker_eq_comap_bot, ideal.mk_ker]

@[simp] lemma multiset.repeat_inter {α : Type*} [decidable_eq α] (x : α) (n : ℕ) (s : multiset α) :
  multiset.repeat x n ∩ s = multiset.repeat x (min n (s.count x)) :=
begin
  refine le_antisymm _ _,
  { simp only [multiset.le_iff_count, multiset.count_inter, multiset.count_repeat],
    intro a,
    split_ifs with h,
    { rw h },
    { rw [nat.zero_min] } },
  simp only [multiset.le_inter_iff, ← multiset.le_count_iff_repeat_le, multiset.count_inter,
    multiset.count_repeat_self],
end

@[simp] lemma multiset.inter_repeat {α : Type*} [decidable_eq α] (s : multiset α) (x : α) (n : ℕ)  :
  s ∩ multiset.repeat x n = multiset.repeat x (min (s.count x) n) :=
by rw [multiset.inter_comm, multiset.repeat_inter, min_comm]

lemma count_normalized_factors_eq {M : Type*} [cancel_comm_monoid_with_zero M]
  [nontrivial M] [decidable_eq M]
  [normalization_monoid M] [unique_factorization_monoid M]
  {p x : M} (hp : prime p) (hnorm : normalize p = p) {n : ℕ}
  (hle : p^n ∣ x) (hlt : ¬ (p^(n+1) ∣ x)) :
  (normalized_factors x).count p = n :=
begin
  letI : decidable_rel ((∣) : M → M → Prop) := λ _ _, classical.prop_decidable _,
  by_cases hx0 : x = 0,
  { simp [hx0] at hlt, contradiction },
  rw [← enat.coe_inj],
  convert (multiplicity_eq_count_normalized_factors hp.irreducible hx0).symm,
  { exact hnorm.symm },
  exact (multiplicity.eq_coe_iff.mpr ⟨hle, hlt⟩).symm
end

section
open_locale classical

lemma ideal.count_normalized_factors_eq {R : Type*} [comm_ring R] [is_domain R]
  [is_dedekind_domain R] {p x : ideal R} (hp0 : p ≠ ⊥) [hp : p.is_prime] {n : ℕ}
  (hle : x ≤ p^n) (hlt : ¬ (x ≤ p^(n+1))) :
  (normalized_factors x).count p = n :=
count_normalized_factors_eq ((ideal.prime_iff_is_prime hp0).mpr hp) (normalize_eq _)
  (ideal.dvd_iff_le.mpr hle) (mt ideal.le_of_dvd hlt)
end

lemma char_zero.nsmul_eq_zero_iff {R : Type*} [semiring R] [no_zero_divisors R] [char_zero R]
  {n : ℕ} {x : R} :
  n • x = 0 ↔ n = 0 ∨ x = 0 :=
⟨λ h, by rwa [nsmul_eq_mul, mul_eq_zero, nat.cast_eq_zero] at h,
 by { rintros (h | h); simp [h]}⟩

lemma cardinal.nsmul_lt_omega_iff {n : ℕ} (hn : n ≠ 0) {a : cardinal} :
  n • a < cardinal.omega ↔ a < cardinal.omega :=
begin
  cases n,
  { contradiction },
  clear hn,
  induction n with n ih,
  { simp },
  rw [succ_nsmul, cardinal.add_lt_omega_iff, ih, and_self]
end

lemma finite_dimensional_iff_of_rank_eq_nsmul
  {K V W : Type*} [field K] [add_comm_group V] [add_comm_group W] [module K V] [module K W]
  {n : ℕ} (hn : n ≠ 0) (hVW : module.rank K V = n • module.rank K W) :
  finite_dimensional K V ↔ finite_dimensional K W :=
by simp only [finite_dimensional, ← is_noetherian.iff_fg, is_noetherian.iff_dim_lt_omega, hVW,
  cardinal.nsmul_lt_omega_iff hn]

section chinese_remainder

lemma ideal.le_mul_of_no_prime_factors {R : Type*} [comm_ring R] [is_domain R]
  [is_dedekind_domain R] {I J K : ideal R} (coprime : ∀ P, J ≤ P → K ≤ P → ¬ is_prime P)
  (hJ : I ≤ J) (hK : I ≤ K) : I ≤ J * K :=
begin
  simp only [← ideal.dvd_iff_le] at coprime hJ hK ⊢,
  by_cases hJ0 : J = 0,
  { simpa only [hJ0, zero_mul] using hJ },
  obtain ⟨I', rfl⟩ := hK,
  rw mul_comm,
  exact mul_dvd_mul_left K
    (unique_factorization_monoid.dvd_of_dvd_mul_right_of_no_prime_factors hJ0
      (λ P hPJ hPK, mt ideal.is_prime_of_prime (coprime P hPJ hPK))
      hJ)
end

lemma ideal.le_of_pow_le_prime {R : Type*} [comm_ring R] [is_domain R] [is_dedekind_domain R]
  {I P : ideal R} [hP : P.is_prime] {n : ℕ} (h : I^n ≤ P) : I ≤ P :=
begin
  by_cases hP0 : P = ⊥,
  { simp only [hP0, le_bot_iff] at ⊢ h,
    exact pow_eq_zero h },
  rw ← ideal.dvd_iff_le at ⊢ h,
  exact ((ideal.prime_iff_is_prime hP0).mpr hP).dvd_of_dvd_pow h
end

lemma ideal.pow_le_prime_iff {R : Type*} [comm_ring R] [is_domain R] [is_dedekind_domain R]
  {I P : ideal R} [hP : P.is_prime] {n : ℕ} (hn : n ≠ 0) : I^n ≤ P ↔ I ≤ P :=
⟨ideal.le_of_pow_le_prime, λ h, trans (ideal.pow_le_self hn) h⟩

lemma ideal.prod_le_prime {ι R : Type*} [comm_ring R] [is_domain R] [is_dedekind_domain R]
  {s : finset ι} {f : ι → ideal R} {P : ideal R} [hP : P.is_prime] :
  ∏ i in s, f i ≤ P ↔ ∃ i ∈ s, f i ≤ P :=
begin
  by_cases hP0 : P = ⊥,
  { simp only [hP0, le_bot_iff],
    rw [← ideal.zero_eq_bot, finset.prod_eq_zero_iff] },
  simp only [← ideal.dvd_iff_le],
  exact ((ideal.prime_iff_is_prime hP0).mpr hP).dvd_finset_prod_iff _
end

lemma ideal.prime_le_prime_iff_eq {R : Type*} [comm_ring R] [is_domain R]
  [is_dedekind_domain R] {P Q : ideal R} [hP : P.is_prime] [hQ : Q.is_prime] (hP0 : P ≠ ⊥) :
  P ≤ Q ↔ P = Q :=
begin
  by_cases hQ0 : Q = ⊥,
  { rw [hQ0, le_bot_iff] },
  rw ← ideal.dvd_iff_le,
  exact (prime_dvd_prime_iff_eq
      ((ideal.prime_iff_is_prime hQ0).mpr hQ) ((ideal.prime_iff_is_prime hP0).mpr hP)).trans
    eq_comm
end

lemma ideal.coprime_of_no_prime_ge {R : Type*} [comm_ring R] {I J : ideal R}
  (h : ∀ P, I ≤ P → J ≤ P → ¬ is_prime P) : I ⊔ J = ⊤ :=
begin
  by_contra hIJ,
  obtain ⟨P, hP, hIJ⟩ := ideal.exists_le_maximal _ hIJ,
  exact h P (le_trans le_sup_left hIJ) (le_trans le_sup_right hIJ) hP.is_prime
end

/-- The intersection of distinct prime powers in a Dedekind domain is the product of these
prime powers. -/
lemma is_dedekind_domain.inf_prime_pow_eq_prod {R ι : Type*} [comm_ring R] [is_domain R]
  [is_dedekind_domain R] (s : finset ι) (f : ι → ideal R) (e : ι → ℕ)
  (prime : ∀ i, prime (f i)) (coprime : ∀ i j, i ≠ j → f i ≠ f j) :
  s.inf (λ i, f i ^ e i) = ∏ i in s, f i ^ e i :=
begin
  letI := classical.dec_eq ι,
  refine s.induction _ _,
  { simp },
  intros a s ha ih,
  rw [finset.inf_insert, finset.prod_insert ha, ih],
  refine le_antisymm (ideal.le_mul_of_no_prime_factors _ inf_le_left inf_le_right) ideal.mul_le_inf,
  intros P hPa hPs hPp,
  haveI := hPp,
  obtain ⟨b, hb, hPb⟩ := ideal.prod_le_prime.mp hPs,
  haveI := ideal.is_prime_of_prime (prime a), haveI := ideal.is_prime_of_prime (prime b),
  refine coprime a b _
    (((ideal.prime_le_prime_iff_eq _).mp (ideal.le_of_pow_le_prime hPa)).trans
      ((ideal.prime_le_prime_iff_eq _).mp (ideal.le_of_pow_le_prime hPb)).symm),
  { unfreezingI { rintro rfl }, contradiction },
  { exact (prime a).ne_zero },
  { exact (prime b).ne_zero },
end

/-- **Chinese remainder theorem** for a Dedekind domain: if the ideal `I` factors as
`∏ i, P i ^ e i`, then `R ⧸ I` factors as `Π i, R ⧸ (P i ^ e i)`. -/
noncomputable def is_dedekind_domain.quotient_equiv_pi_of_prod_eq {R ι : Type*} [comm_ring R]
  [is_domain R] [fintype ι] [is_dedekind_domain R] (I : ideal R) (P : ι → ideal R) (e : ι → ℕ)
  (prime : ∀ i, prime (P i)) (coprime : ∀ i j, i ≠ j → P i ≠ P j)
  (prod_eq : (∏ i, P i ^ e i) = I) :
  R ⧸ I ≃+* Π i, R ⧸ (P i ^ e i) :=
(ideal.quot_equiv_of_eq (by { simp only [← prod_eq, finset.inf_eq_infi,
  ← is_dedekind_domain.inf_prime_pow_eq_prod _ _ _ prime coprime, finset.mem_univ, cinfi_pos] }))
    .trans $
ideal.quotient_inf_ring_equiv_pi_quotient _ (λ i j hij, ideal.coprime_of_no_prime_ge (begin
  intros P hPi hPj hPp,
  haveI := hPp,
  haveI := ideal.is_prime_of_prime (prime i), haveI := ideal.is_prime_of_prime (prime j),
  exact coprime i j hij
    (((ideal.prime_le_prime_iff_eq (prime i).ne_zero).mp (ideal.le_of_pow_le_prime hPi)).trans
      ((ideal.prime_le_prime_iff_eq (prime j).ne_zero).mp (ideal.le_of_pow_le_prime hPj)).symm)
end))

@[to_additive]
lemma finset.prod_coe_sort {α M : Type*} [comm_monoid M] (s : finset α) (f : α → M) :
  ∏ i : s, f i = ∏ i in s, f i :=
by rw [← @finset.prod_attach _ _ s, finset.univ_eq_attach]; refl

@[to_additive]
lemma finset.prod_coe_sort_eq_attach {α M : Type*} [comm_monoid M] (s : finset α) (f : s → M) :
  ∏ i : s, f i = ∏ i in s.attach, f i :=
finset.prod_bij (λ a ha, a) (λ a _, finset.mem_attach _ a) (λ _ _, rfl) (λ _ _ _ _ h, h)
  (λ a _, ⟨a, finset.mem_univ _, rfl⟩)

lemma finset.erase_insert_eq_erase {α : Type*} [decidable_eq α] (s : finset α) (a : α) :
  (insert a s).erase a = s.erase a :=
by by_cases ha : a ∈ s; { simp [ha, finset.erase_insert] }

@[to_additive]
lemma multiset.prod_to_finset {α M : Type*} [decidable_eq α] [comm_monoid M] (s : multiset α)
  (f : α → M) : (∏ i in s.to_finset, f i ^ s.count i) = (s.map f).prod :=
begin
  refine s.induction _ _,
  { simp },
  intros a s ih,
  rw [multiset.to_finset_cons, multiset.map_cons, multiset.prod_cons],
  calc  ∏ i in insert a s.to_finset, f i ^ (a ::ₘ s).count i
      = f a * (f a ^ s.count a * ∏ i in s.to_finset.erase a, f i ^ s.count i) : _
  ... = f a * ∏ i in s.to_finset, f i ^ s.count i : _
  ... = f a * (multiset.map f s).prod : by rw ih,
  { rw [← finset.mul_prod_erase _ _ (finset.mem_insert_self a _), multiset.count_cons_self,
        pow_succ, mul_assoc],
    congr' 2,
    refine finset.prod_congr (finset.erase_insert_eq_erase _ _) (λ b hb, _),
    rw multiset.count_cons_of_ne,
    rintro rfl,
    have := finset.not_mem_erase b s.to_finset,
    contradiction },
  by_cases ha : a ∈ s,
  { rw ← finset.mul_prod_erase _ _ (multiset.mem_to_finset.mpr ha) },
  { rw [finset.erase_eq_of_not_mem (mt multiset.mem_to_finset.mp ha),
        multiset.count_eq_zero.mpr ha, pow_zero, one_mul] },
end

/-- **Chinese remainder theorem** for a Dedekind domain: `R ⧸ I` factors as `Π i, R ⧸ (P i ^ e i)`,
where `P i` ranges over the prime factors of `I` and `e i` over the multiplicities. -/
noncomputable def is_dedekind_domain.quotient_equiv_pi_factors {R : Type u} [comm_ring R]
  [decidable_eq (ideal R)] [is_domain R] [is_dedekind_domain R] {I : ideal R} (hI : I ≠ ⊥) :
  R ⧸ I ≃+* Π (P : (factors I).to_finset), R ⧸ ((P : ideal R) ^ (factors I).count P) :=
is_dedekind_domain.quotient_equiv_pi_of_prod_eq _ _ _
  (λ (P : (factors I).to_finset), prime_of_factor _ (multiset.mem_to_finset.mp P.prop))
  (λ i j hij, subtype.coe_injective.ne hij)
  (calc ∏ (P : (factors I).to_finset), (P : ideal R) ^ (factors I).count (P : ideal R)
      = ∏ P in (factors I).to_finset, P ^ (factors I).count P
    : finset.prod_coe_sort (factors I).to_finset (λ P, P ^ (factors I).count P)
  ... = ((factors I).map (λ P, P)).prod : multiset.prod_to_finset (factors I) (λ P, P)
  ... = (factors I).prod : by rw multiset.map_id'
  ... = I : (@associated_iff_eq (ideal R) _ ideal.unique_units _ _).mp (factors_prod hI))

@[simp] lemma is_dedekind_domain.quotient_equiv_pi_factors_mk {R : Type u} [comm_ring R]
  [decidable_eq (ideal R)] [is_domain R] [is_dedekind_domain R] {I : ideal R} (hI : I ≠ ⊥)
  (x : R) : is_dedekind_domain.quotient_equiv_pi_factors hI (ideal.quotient.mk I x) =
    λ P, ideal.quotient.mk _ x :=
rfl

end chinese_remainder

end move_me

section dec_eq

open_locale classical

/-- The ramification index of `P` over `p` is the largest exponent `n`
such that `p` is contained in `P^n`.

In particular, if `p` is not contained in `P^n`, then the ramification index is `0`.

If there is no largest such `n` (e.g. because `p = ⊥`),
then `ramification_idx` is defined to be `0`.
-/
noncomputable def ramification_idx : ℕ :=
if h : ∃ n, map f p ≤ P ^ n ∧ ¬ map f p ≤ P ^ (n + 1)
then nat.find h
else 0

lemma ramification_idx_eq_find (h : ∃ n, map f p ≤ P ^ n ∧ ¬ map f p ≤ P ^ (n + 1)) :
  ramification_idx f p P = nat.find h :=
dif_pos h

lemma ramification_idx_spec (n : ℕ) (hle : map f p ≤ P ^ n) (hgt : ¬ map f p ≤ P ^ (n + 1)) :
  ramification_idx f p P = n :=
begin
  rw ramification_idx_eq_find f p P ⟨n, hle, hgt⟩,
  refine le_antisymm (nat.find_min' _ ⟨hle, hgt⟩) (le_of_not_gt (λ (h : nat.find _ < n), _)),
  obtain ⟨hle', hgt'⟩ := nat.find_spec ⟨n, and.intro hle hgt⟩,
  exact hgt' (hle.trans (ideal.pow_le_pow h))
end

@[simp] lemma ramification_idx_bot : ramification_idx f ⊥ P = 0 :=
dif_neg $ not_exists.mpr $ λ n hn, hn.2 (ideal.map_bot.le.trans bot_le)

@[simp] lemma ramification_idx_of_not_le (h : ¬ map f p ≤ P) : ramification_idx f p P = 0 :=
begin
  rw [ramification_idx, dif_pos, nat.find_eq_zero ⟨0, _⟩];
    rw [zero_add, pow_zero, pow_one, ideal.one_eq_top];
    exact ⟨le_top, h⟩
end

lemma ramification_idx_ne_zero {e : ℕ} (he : e ≠ 0)
  (hle : map f p ≤ P ^ e) (hnle : ¬ map f p ≤ P ^ (e + 1)):
  ramification_idx f p P ≠ 0 :=
by rwa ramification_idx_spec f p P e hle hnle

variables {f p P}

lemma le_pow_ramification_idx_of_ne_zero (h : ramification_idx f p P ≠ 0) :
  map f p ≤ P ^ ramification_idx f p P :=
begin
  rw ramification_idx at ⊢ h, split_ifs at ⊢ h with hex,
  swap, contradiction,
  exact (nat.find_spec hex).1
end

lemma is_dedekind_domain.ramification_idx_eq_normalized_factors_count
  [is_domain S] [is_dedekind_domain S]
  (hp0 : map f p ≠ ⊥) (hP : P.is_prime) (hP0 : P ≠ ⊥) :
  ramification_idx f p P = (normalized_factors (map f p)).count P :=
begin
  have hPirr := (ideal.prime_of_is_prime hP0 hP).irreducible,
  refine ramification_idx_spec _ _ _ _ (ideal.le_of_dvd _) (mt ideal.dvd_iff_le.mpr _);
    rw [dvd_iff_normalized_factors_le_normalized_factors (pow_ne_zero _ hP0) hp0,
        normalized_factors_pow, normalized_factors_irreducible hPirr, normalize_eq,
        multiset.nsmul_singleton, ← multiset.le_count_iff_repeat_le],
  { exact (nat.lt_succ_self _).not_le },
end

@[simp] lemma normalized_factors_eq_factors {M : Type*} [cancel_comm_monoid_with_zero M]
  [unique_factorization_monoid M] [unique (Mˣ)] (x : M) : normalized_factors x = factors x :=
by { unfold normalized_factors, convert multiset.map_id (factors x), ext p, exact normalize_eq p }

lemma is_dedekind_domain.ramification_idx_eq_factors_count [is_domain S] [is_dedekind_domain S]
  (hp0 : map f p ≠ ⊥) (hP : P.is_prime) (hP0 : P ≠ ⊥) :
  ramification_idx f p P = (factors (map f p)).count P :=
begin
  rw [is_dedekind_domain.ramification_idx_eq_normalized_factors_count hp0 hP hP0,
      normalized_factors_eq_factors],
end

lemma is_dedekind_domain.ramification_idx_ne_zero [is_domain S] [is_dedekind_domain S]
  (hp0 : map f p ≠ ⊥) (hP : P.is_prime) (le : map f p ≤ P) : ramification_idx f p P ≠ 0 :=
begin
  have hP0 : P ≠ ⊥,
  { unfreezingI { rintro rfl },
    have := le_bot_iff.mp le,
    contradiction },
  have hPirr := (ideal.prime_of_is_prime hP0 hP).irreducible,
  rw is_dedekind_domain.ramification_idx_eq_normalized_factors_count hp0 hP hP0,
  obtain ⟨P', hP', P'_eq⟩ :=
    exists_mem_normalized_factors_of_dvd hp0 hPirr (ideal.dvd_iff_le.mpr le),
  rwa [multiset.count_ne_zero, associated_iff_eq.mp P'_eq],
end

lemma is_dedekind_domain.le_pow_ramification_idx [is_domain S] [is_dedekind_domain S]
  (hp0 : map f p ≠ ⊥) (hP : P.is_prime) (le : map f p ≤ P) :
  map f p ≤ P ^ ramification_idx f p P :=
le_pow_ramification_idx_of_ne_zero (is_dedekind_domain.ramification_idx_ne_zero hp0 hP le)

variables (f p P)

local attribute [instance] ideal.quotient.field

/-- The inertia degree of `P : ideal S` lying over `p : ideal R` is the degree of the
extension `(S / P) : (R / p)`.

We do not assume `P` lies over `p` in the definition; we return `0` instead.

See `inertia_deg_algebra_map` for the common case where `f = algebra_map R S`
and there is an algebra structure `R / p → S / P`.
-/
noncomputable def inertia_deg [hp : p.is_maximal] : ℕ :=
if hPp : comap f P = p
then @finrank (R ⧸ p) (S ⧸ P) _ _ $ @algebra.to_module _ _ _ _ $ ring_hom.to_algebra $
ideal.quotient.lift p (P^.quotient.mk^.comp f) $
λ a ha, quotient.eq_zero_iff_mem.mpr $ mem_comap.mp $ hPp.symm ▸ ha
else 0

-- Useful for the `nontriviality` tactic using `comap_eq_of_scalar_tower_quotient`.
@[simp] lemma inertia_deg_of_subsingleton [hp : p.is_maximal] [hQ : subsingleton (S ⧸ P)] :
  inertia_deg f p P = 0 :=
begin
  have := ideal.quotient.subsingleton_iff.mp hQ,
  unfreezingI { subst this },
  exact dif_neg (λ h, hp.ne_top $ h.symm.trans comap_top)
end

@[simp] lemma inertia_deg_algebra_map [algebra R S] [algebra (R ⧸ p) (S ⧸ P)]
  [is_scalar_tower R (R ⧸ p) (S ⧸ P)]
  [hp : p.is_maximal] :
  inertia_deg (algebra_map R S) p P = finrank (R ⧸ p) (S ⧸ P) :=
begin
  nontriviality (S ⧸ P) using [inertia_deg_of_subsingleton, finrank_zero_of_subsingleton],
  have := comap_eq_of_scalar_tower_quotient (algebra_map (R ⧸ p) (S ⧸ P)).injective,
  rw [inertia_deg, dif_pos this],
  congr,
  refine algebra.algebra_ext _ _ (λ x', quotient.induction_on' x' $ λ x, _),
  change ideal.quotient.lift p _ _ (ideal.quotient.mk p x) =
    algebra_map _ _ (ideal.quotient.mk p x),
  rw [ideal.quotient.lift_mk, ← ideal.quotient.algebra_map_eq, ← is_scalar_tower.algebra_map_eq,
      ← ideal.quotient.algebra_map_eq, ← is_scalar_tower.algebra_map_apply]
end

end dec_eq

-- TODO: generalize?
lemma finrank_quotient_map.linear_independent_of_injective
  {R S K : Type*} [comm_ring R] [is_domain R] [comm_ring S] [algebra R S]
  (hRS : function.injective (algebra_map R S)) [field K] [algebra R K] [is_fraction_ring R K]
  {ι V V' V'' : Type*} [add_comm_group V] [module R V] [module K V] [is_scalar_tower R K V]
  [add_comm_group V'] [module R V'] [module S V'] [is_scalar_tower R S V']
  [add_comm_group V''] [module R V''] (f : V'' →ₗ[R] V) (hf : function.injective f)
  (f' : V'' →ₗ[R] V') {b : ι → V''}
  (hb' : linear_independent S (f' ∘ b)) : linear_independent K (f ∘ b) :=
begin
  apply linear_independent.localization K R⁰,
  rw f.linear_independent_iff (linear_map.ker_eq_bot.mpr hf),
  refine linear_independent.of_comp f' (linear_independent.restrict_scalars_algebras _ hb'),
  simpa only [algebra.smul_def, mul_one] using hRS,
  { apply_instance }
end

-- TODO: generalize?
lemma finrank_quotient_map.linear_independent_of_nontrivial
  {R S K : Type*} [comm_ring R] [is_domain R] [is_dedekind_domain R]
  [comm_ring S] [algebra R S] (hRS : (algebra_map R S).ker ≠ ⊤)
  [field K] [algebra R K] [is_fraction_ring R K] {ι V V' V'' : Type*}
  [add_comm_group V] [module R V] [module K V] [is_scalar_tower R K V]
  [add_comm_group V'] [module R V'] [module S V'] [is_scalar_tower R S V']
  [add_comm_group V''] [module R V''] (f : V'' →ₗ[R] V) (hf : function.injective f)
  (f' : V'' →ₗ[R] V') {b : ι → V''}
  (hb' : linear_independent S (f' ∘ b)) : linear_independent K (f ∘ b) :=
begin
  contrapose! hb' with hb,
  -- If we have a nontrivial linear dependence with coefficients `g` in `K`,
  -- then we can find a linear dependence with coefficients `I.quotient.mk g'` in `R/I`.
  simp only [linear_independent_iff', not_forall] at hb ⊢,
  obtain ⟨s, g, eq, j', hj's, hj'g⟩ := hb,
  refine ⟨s, _⟩,
  obtain ⟨a, hag, j, hjs, hgI⟩ :=
    ideal.exist_integer_multiples_not_mem hRS s g hj's hj'g,
  choose g'' hg'' using hag,
  letI := classical.prop_decidable,
  let g' := λ i, if h : i ∈ s then g'' i h else 0,
  have hg' : ∀ i ∈ s, algebra_map _ _ (g' i) = a * g i,
  { intros i hi, exact (congr_arg _ (dif_pos hi)).trans (hg'' i hi) },
  have hgI : algebra_map R S (g' j) ≠ 0,
  { simp only [fractional_ideal.mem_coe_ideal, not_exists, not_and'] at hgI,
    exact hgI _ (hg' j hjs) },
  refine ⟨λ i, algebra_map R S (g' i), _, j, hjs, hgI⟩,
  have eq : f (∑ i in s, g' i • (b i)) = 0,
  { rw [linear_map.map_sum, ← smul_zero a, ← eq, finset.smul_sum, finset.sum_congr rfl],
    intros i hi,
    rw [linear_map.map_smul, ← is_scalar_tower.algebra_map_smul K, hg' i hi, ← smul_assoc,
        smul_eq_mul],
    apply_instance },
  simp only [is_scalar_tower.algebra_map_smul, ← linear_map.map_smul, ← linear_map.map_sum,
          (f.map_eq_zero_iff hf).mp eq, linear_map.map_zero],
end

open_locale matrix

/-- If `b` mod `p` spans `S/p` as `R/p`-space, then `b` itself spans `Frac(S)` as `Frac(R)`-space.
-/
lemma finrank_quotient_map.span_eq_top [is_domain R] [is_domain S] {K L : Type*} [field K] [field L]
  [algebra R K] [algebra R S] [algebra S L] [is_fraction_ring S L] [algebra K L] [is_noetherian R S]
  [algebra R L] [is_scalar_tower R S L] [is_scalar_tower R K L] [is_integral_closure S R L]
  (hRL : function.injective (algebra_map R L)) (hp : p ≠ ⊤)
  (b : set S) (hb' : submodule.span R b ⊔ (p.map (algebra_map R S)).restrict_scalars R = ⊤) :
  submodule.span K (algebra_map S L '' b) = ⊤ :=
begin
  -- Let `M` be the `R`-module spanned by the proposed basis elements.
  set M : submodule R S := submodule.span R b with hM,
  -- Then `S / M` is generated by some finite set of `n` vectors `a`.
  letI h : module.finite R (S ⧸ M) :=
    module.finite.of_surjective (submodule.mkq _) (submodule.quotient.mk_surjective _),
  obtain ⟨n, a, ha⟩ := @@module.finite.exists_fin _ _ _ h,
  -- Because the image of `p` in `S / M` is `⊤`,
  have smul_top_eq : p • (⊤ : submodule R (S ⧸ M)) = ⊤,
  { calc p • ⊤ = submodule.map M.mkq (p • ⊤) :
      by rw [submodule.map_smul'', submodule.map_top, M.range_mkq]
    ... = ⊤ : by rw [ideal.smul_top_eq_map, (submodule.map_mkq_eq_top M _).mpr hb'] },
  -- we can write the elements of `a` as `p`-linear combinations of other elements of `a`.
  have exists_sum : ∀ x : (S ⧸ M), ∃ a' : fin n → R, (∀ i, a' i ∈ p) ∧ ∑ i, a' i • a i = x,
  { intro x,
    obtain ⟨a'', ha'', hx⟩ := submodule.exists_sum_of_mem_ideal_smul_span p set.univ a x _,
    refine ⟨λ i, a'' ⟨i, set.mem_univ _⟩, λ i, ha'' _, _⟩,
    rwa [finsupp.sum_fintype, fintype.sum_equiv (equiv.set.univ (fin n))] at hx,
    { intros, simp only [eq_self_iff_true, subtype.coe_eta, equiv.set.univ_apply] },
    { intros, simp only [zero_smul] },
    rw [set.image_univ, ha, smul_top_eq],
    exact submodule.mem_top },
  choose A' hA'p hA' using λ i, exists_sum (a i),
  -- This gives us a(n invertible) matrix `A` such that `det A ∈ M = span R b`,
  let A : matrix (fin n) (fin n) R := A' - 1,
  let B := A.adjugate,
  have A_smul : ∀ i, ∑ j, A i j • a j = 0,
  { intros,
    simp only [A, pi.sub_apply, sub_smul, finset.sum_sub_distrib, hA', matrix.one_apply, ite_smul,
      one_smul, zero_smul, finset.sum_ite_eq, finset.mem_univ, if_true, sub_self] },
  -- since `span S {det A} / M = 0`.
  have d_smul : ∀ i, A.det • a i = 0,
  { intro i,
    calc A.det • a i = ∑ j, (B ⬝ A) i j • a j : _
                 ... = ∑ k, B i k • ∑ j, (A k j • a j) : _
                 ... = 0 : finset.sum_eq_zero (λ k _, _),
    { simp only [matrix.adjugate_mul, pi.smul_apply, matrix.one_apply, mul_ite, ite_smul,
        smul_eq_mul, mul_one, mul_zero, one_smul, zero_smul, finset.sum_ite_eq, finset.mem_univ,
        if_true] },
    { simp only [matrix.mul_apply, finset.smul_sum, finset.sum_smul, smul_smul],
      rw finset.sum_comm },
    { rw [A_smul, smul_zero] } },
  -- In the rings of integers we have the desired inclusion.
  have span_d : (submodule.span S ({algebra_map R S A.det} : set S)).restrict_scalars R ≤ M,
  { intros x hx,
    rw submodule.restrict_scalars_mem at hx,
    obtain ⟨x', rfl⟩ := submodule.mem_span_singleton.mp hx,
    rw [smul_eq_mul, mul_comm, ← algebra.smul_def] at ⊢ hx,
    rw [← submodule.quotient.mk_eq_zero, submodule.quotient.mk_smul],
    obtain ⟨a', _, quot_x_eq⟩ := exists_sum (submodule.quotient.mk x'),
    simp_rw [← quot_x_eq, finset.smul_sum, smul_comm A.det, d_smul, smul_zero,
      finset.sum_const_zero] },
  -- So now we lift everything to the fraction field.
  refine top_le_iff.mp (calc ⊤ = (ideal.span {algebra_map R L A.det}).restrict_scalars K : _
                           ... ≤ submodule.span K (algebra_map S L '' b) : _),
  -- Because `det A ≠ 0`, we have `span L {det A} = ⊤`.
  { rw [eq_comm, submodule.restrict_scalars_eq_top_iff, ideal.span_singleton_eq_top],
    refine is_unit.mk0 _ ((map_ne_zero_iff ((algebra_map R L)) hRL).mpr (
      @ne_zero_of_map _ _ _ _ _ _ (ideal.quotient.mk p) _ _)),
    haveI := ideal.quotient.nontrivial hp,
    calc ideal.quotient.mk p (A.det)
          = matrix.det ((ideal.quotient.mk p).map_matrix A) :
        by rw [ring_hom.map_det, ring_hom.map_matrix_apply]
      ... = matrix.det ((ideal.quotient.mk p).map_matrix (A' - 1)) : rfl
      ... = matrix.det (λ i j, (ideal.quotient.mk p) (A' i j) -
              (1 : matrix (fin n) (fin n) (R ⧸ p)) i j) : _
      ... = matrix.det (-1 : matrix (fin n) (fin n) (R ⧸ p)) : _
      ... = (-1 : R ⧸ p) ^ n : by rw [matrix.det_neg, fintype.card_fin, matrix.det_one, mul_one]
      ... ≠ 0 : is_unit.ne_zero (is_unit_one.neg.pow _),
    { refine congr_arg matrix.det (matrix.ext (λ i j, _)),
      rw [map_sub, ring_hom.map_matrix_apply, map_one],
      refl },
    { refine congr_arg matrix.det (matrix.ext (λ i j, _)),
      rw [ideal.quotient.eq_zero_iff_mem.mpr (hA'p i j), zero_sub],
      refl } },
  -- And we conclude `L = span L {det A} ≤ span K b`, so `span K b` spans everything.
  { intros x hx,
    rw [submodule.restrict_scalars_mem, is_scalar_tower.algebra_map_apply R S L] at hx,
    refine is_fraction_ring.ideal_span_singleton_map_subset R _ hRL span_d hx,
    haveI : no_zero_smul_divisors R L := no_zero_smul_divisors.of_algebra_map_injective hRL,
    rw ← is_fraction_ring.is_algebraic_iff' R S,
    intros x,
    exact is_integral.is_algebraic _ (is_integral_of_noetherian infer_instance _) },
end


/-- If `p` is a maximal ideal of `R`, and `R` is contained in `S`,
then the dimension `[S/pS : R/p]` is equal to `[Frac(S) : Frac(R)]`. -/
lemma finrank_quotient_map [is_domain R] [is_domain S] [is_dedekind_domain R]
  (K L : Type*) [field K] [field L]
  [algebra R S] [algebra R K] [algebra S L] [algebra K L]
  [algebra R L] [is_scalar_tower R K L] [is_scalar_tower R S L] [is_integral_closure S R L]
  [is_fraction_ring R K] [is_fraction_ring S L]
  (hRL : function.injective (algebra_map R L))
  [hp : p.is_maximal] [is_noetherian R S] :
  finrank (R ⧸ p) (S ⧸ map (algebra_map R S) p) = finrank K L :=
begin
  letI : field (R ⧸ p) := ideal.quotient.field _,
  let ι := module.free.choose_basis_index (R ⧸ p) (S ⧸ map (algebra_map R S) p),
  let b : basis ι _ _ := module.free.choose_basis (R ⧸ p) (S ⧸ map (algebra_map R S) p),
  let b' : ι → S := λ i, (ideal.quotient.mk_surjective (b i)).some,
  have b_eq_b' : ⇑ b = (submodule.mkq _).restrict_scalars R ∘ b' :=
    funext (λ i, (ideal.quotient.mk_surjective (b i)).some_spec.symm),
  let b'' : ι → L := algebra_map S L ∘ b',
  have b''_li : linear_independent _ b'' := _,
  have b''_sp : submodule.span _ (set.range b'') = ⊤ := _,
  let c : basis ι K L := basis.mk b''_li b''_sp,
  rw [finrank_eq_card_basis b, finrank_eq_card_basis c],
  { rw set.range_comp,
    refine finrank_quotient_map.span_eq_top p hRL hp.ne_top _ (top_le_iff.mp _),
    rw [← submodule.ker_mkq (submodule.restrict_scalars R (map (algebra_map R S) p)),
        ← linear_map.map_le_map_iff],
    -- TODO: here we're using that the quotient modulo `submodule.restrict_scalars`
    -- is defeq to the original quotient
    calc submodule.map (submodule.restrict_scalars R (map (algebra_map R S) p)).mkq ⊤ = ⊤
      : by rw [submodule.map_top, submodule.range_mkq]
    ... ≤ (submodule.span (R ⧸ p) (set.range ⇑b)).restrict_scalars R : b.span_eq.ge
    ... = submodule.span R (set.range ⇑b)
      : algebra.span_restrict_scalars_eq_span_of_surjective ideal.quotient.mk_surjective _
    ... = submodule.map (submodule.restrict_scalars R _).mkq (submodule.span R (set.range b'))
      : by { rw [b_eq_b', set.range_comp, submodule.map_span], refl } },
  { have := b.linear_independent, rw b_eq_b' at this,
    convert finrank_quotient_map.linear_independent_of_nontrivial _
      ((algebra.linear_map S L).restrict_scalars R) _
      ((submodule.mkq _).restrict_scalars R)
      this,
    { rw [quotient.algebra_map_eq, ideal.mk_ker], exact hp.ne_top },
    { apply_instance }, { apply_instance }, { apply_instance },
    exact is_fraction_ring.injective S L },
end

variables [hfp : fact (p ≤ comap f P)]
include hfp

/-- If `P` lies over `p`, then `R / p` has a canonical map to `S / P`. -/
instance ideal.quotient.algebra_quotient_of_fact_le_comap :
  algebra (R ⧸ p) (S ⧸ P) :=
quotient.algebra_quotient_of_le_comap (fact.out (p ≤ comap f P))

@[simp] lemma ideal.quotient.algebra_map_quotient_of_fact_le_comap (x : R) :
  algebra_map (R ⧸ p) (S ⧸ P) (ideal.quotient.mk p x) = ideal.quotient.mk _ (f x) :=
rfl

@[simp] lemma quotient.mk_smul_mk_quotient_map_quotient (x : R) (y : S) :
  ideal.quotient.mk p x • ideal.quotient.mk P y = ideal.quotient.mk _ (f x * y) :=
rfl

omit hfp

@[simp] lemma map_quotient_mk_self {R : Type*} [comm_ring R] (I : ideal R) :
  map (ideal.quotient.mk I) I = ⊥ :=
by simp only [eq_bot_iff, ideal.map_le_iff_le_comap, ← ring_hom.ker_eq_comap_bot,
  ideal.mk_ker, le_refl]

variables (e : ℕ) [hfPe : fact (p ≤ comap f (P^e))]
include hfPe

/-- The inclusion `(P^(i + 1) / P^e) ⊂ (P^i / P^e)`. -/
@[simps]
def pow_quot_succ_inclusion (i : ℕ) :
  ideal.map (P^e)^.quotient.mk (P ^ (i + 1)) →ₗ[R ⧸ p] ideal.map (P^e)^.quotient.mk (P ^ i) :=
{ to_fun := λ x, ⟨x, ideal.map_mono (ideal.pow_le_pow i.le_succ) x.2⟩,
  map_add' := λ x y, rfl,
  map_smul' := λ c x, rfl }

lemma pow_quot_succ_inclusion_injective (i : ℕ) :
  function.injective (pow_quot_succ_inclusion f p P e i) :=
begin
  rw [← linear_map.ker_eq_bot, linear_map.ker_eq_bot'],
  rintro ⟨x, hx⟩ hx0,
  rw subtype.ext_iff at hx0 ⊢,
  rwa pow_quot_succ_inclusion_apply_coe at hx0
end

instance [fact (e ≠ 0)] : fact (p ≤ comap f P) :=
⟨(fact.out $ p ≤ comap f (P^e)).trans (comap_mono (ideal.pow_le_self (fact.out _)))⟩

/-- `S ⧸ P` embeds into the quotient by `P^(i+1) ⧸ P^e` as a subspace of `P^i ⧸ P^e`.

See `quotient_to_quotient_range_pow_quot_succ` for this as a linear map,
and `quotient_range_pow_quot_succ_inclusion_equiv` for this as a linear equivalence.
-/
def quotient_to_quotient_range_pow_quot_succ_aux (i : ℕ) (a : S) (a_mem : a ∈ P^i) :
  S ⧸ P → (_ ⧸ (pow_quot_succ_inclusion f p P e i).range) :=
quotient.map' (λ (x : S), ⟨_, ideal.mem_map_of_mem _ (ideal.mul_mem_left _ x a_mem)⟩)
  (λ x y (h : x - y ∈ P), show _ - _ ∈ _, begin
    simp only [_root_.map_mul, linear_map.mem_range],
    refine ⟨⟨_, ideal.mem_map_of_mem _ (ideal.mul_mem_mul h a_mem)⟩, _⟩,
    ext,
    rw [pow_quot_succ_inclusion_apply_coe, subtype.coe_mk, submodule.coe_sub, subtype.coe_mk,
        subtype.coe_mk, _root_.map_mul, map_sub, sub_mul]
  end)

lemma quotient_to_quotient_range_pow_quot_succ_aux_mk (i : ℕ) (a : S) (a_mem : a ∈ P^i) (x : S) :
  quotient_to_quotient_range_pow_quot_succ_aux f p P e i a a_mem (submodule.quotient.mk x) =
    submodule.quotient.mk ⟨_, ideal.mem_map_of_mem _ (ideal.mul_mem_left _ x a_mem)⟩ :=
by apply quotient.map'_mk'

/-- `S ⧸ P` embeds into the quotient by `P^(i+1) ⧸ P^e` as a subspace of `P^i ⧸ P^e`. -/
def quotient_to_quotient_range_pow_quot_succ [fact (e ≠ 0)] (i : ℕ) (a : S) (a_mem : a ∈ P^i) :
  S ⧸ P →ₗ[R ⧸ p] (_ ⧸ (pow_quot_succ_inclusion f p P e i).range) :=
{ to_fun := quotient_to_quotient_range_pow_quot_succ_aux f p P e i a a_mem, map_add' := begin
  intros x y, refine quotient.induction_on' x (λ x, quotient.induction_on' y (λ y, _)),
  simp only [submodule.quotient.mk'_eq_mk, ← submodule.quotient.mk_add,
             quotient_to_quotient_range_pow_quot_succ_aux_mk, add_mul],
  refine congr_arg submodule.quotient.mk _,
  ext,
  refl
end, map_smul' := begin
  intros x y, refine quotient.induction_on' x (λ x, quotient.induction_on' y (λ y, _)),
  simp only [submodule.quotient.mk'_eq_mk, ← submodule.quotient.mk_add,
             quotient_to_quotient_range_pow_quot_succ_aux_mk, ring_hom.id_apply],
  refine congr_arg submodule.quotient.mk _,
  ext,
  simp only [subtype.coe_mk, _root_.map_mul, algebra.smul_def, submodule.coe_mk, mul_assoc,
             ideal.quotient.mk_eq_mk, submodule.coe_smul_of_tower,
             ideal.quotient.algebra_map_quotient_of_fact_le_comap]
end }


lemma quotient_to_quotient_range_pow_quot_succ_mk [fact (e ≠ 0)] (i : ℕ)
  (a : S) (a_mem : a ∈ P^i) (x : S) :
  quotient_to_quotient_range_pow_quot_succ f p P e i a a_mem (submodule.quotient.mk x) =
    submodule.quotient.mk ⟨_, ideal.mem_map_of_mem _ (ideal.mul_mem_left _ x a_mem)⟩ :=
quotient_to_quotient_range_pow_quot_succ_aux_mk f p P e i a a_mem x

lemma quotient_to_quotient_range_pow_quot_succ_injective [is_domain S] [is_dedekind_domain S]
  [fact (e ≠ 0)] [P.is_prime] {i : ℕ} (hi : i < e)
  {a : S} (a_mem : a ∈ P^i) (a_not_mem : a ∉ P^(i + 1)) :
  function.injective (quotient_to_quotient_range_pow_quot_succ f p P e i a a_mem) :=
λ x, quotient.induction_on' x $ λ x y, quotient.induction_on' y $ λ y h,
begin
  have Pe_le_Pi1 : P^e ≤ P^(i + 1) := ideal.pow_le_pow hi,
  simp only [submodule.quotient.mk'_eq_mk, quotient_to_quotient_range_pow_quot_succ_mk,
    submodule.quotient.eq, linear_map.mem_range, subtype.ext_iff, subtype.coe_mk,
    submodule.coe_sub] at ⊢ h,
  rcases h with ⟨⟨⟨z⟩, hz⟩, h⟩,
  rw [submodule.quotient.quot_mk_eq_mk, ideal.quotient.mk_eq_mk, ideal.quotient.mk_mem_map_mk,
      sup_eq_left.mpr Pe_le_Pi1] at hz,
  rw [pow_quot_succ_inclusion_apply_coe, subtype.coe_mk, submodule.quotient.quot_mk_eq_mk,
      ideal.quotient.mk_eq_mk, ← map_sub, ideal.quotient.eq, ← sub_mul] at h,
  exact (ideal.is_prime.mul_mem_pow _
    ((submodule.sub_mem_iff_right _ hz).mp (Pe_le_Pi1 h))).resolve_right a_not_mem,
end

lemma quotient_to_quotient_range_pow_quot_succ_surjective [is_domain S] [is_dedekind_domain S]
  [fact (e ≠ 0)] (hP0 : P ≠ ⊥) [hP : P.is_prime] {i : ℕ} (hi : i < e)
  {a : S} (a_mem : a ∈ P^i) (a_not_mem : a ∉ P^(i + 1)) :
  function.surjective (quotient_to_quotient_range_pow_quot_succ f p P e i a a_mem) :=
begin
  rintro ⟨⟨⟨x⟩, hx⟩⟩,
  have Pe_le_Pi : P^e ≤ P^i := ideal.pow_le_pow hi.le,
  have Pe_le_Pi1 : P^e ≤ P^(i + 1) := ideal.pow_le_pow hi,
  rw [submodule.quotient.quot_mk_eq_mk, ideal.quotient.mk_eq_mk, ideal.quotient.mk_mem_map_mk,
      sup_eq_left.mpr Pe_le_Pi] at hx,
  suffices hx' : x ∈ ideal.span {a} ⊔ P^(i+1),
  { obtain ⟨y', hy', z, hz, rfl⟩ := submodule.mem_sup.mp hx',
    obtain ⟨y, rfl⟩ := ideal.mem_span_singleton.mp hy',
    refine ⟨submodule.quotient.mk y, _⟩,
    simp only [submodule.quotient.quot_mk_eq_mk, quotient_to_quotient_range_pow_quot_succ_mk,
        submodule.quotient.eq, linear_map.mem_range, subtype.ext_iff, subtype.coe_mk,
        submodule.coe_sub],
    refine ⟨⟨_, ideal.mem_map_of_mem _ (submodule.neg_mem _ hz)⟩, _⟩,
    rw [pow_quot_succ_inclusion_apply_coe, subtype.coe_mk, ideal.quotient.mk_eq_mk, map_add,
        mul_comm y a, sub_add_cancel', map_neg] },
  letI := classical.dec_eq (ideal S),
  rw [sup_eq_prod_inf_factors _ (pow_ne_zero _ hP0), normalized_factors_pow,
      normalized_factors_irreducible ((ideal.prime_iff_is_prime hP0).mpr hP).irreducible,
      normalize_eq, multiset.nsmul_singleton, multiset.inter_repeat, multiset.prod_repeat],
  rw [← submodule.span_singleton_le_iff_mem, ideal.submodule_span_eq] at a_mem a_not_mem,
  rwa [ideal.count_normalized_factors_eq hP0 a_mem a_not_mem, min_eq_left i.le_succ],
  { intro ha,
    rw ideal.span_singleton_eq_bot.mp ha at a_not_mem,
    have := (P^(i+1)).zero_mem,
    contradiction },
end

/-- Quotienting `P^i / P^e` by its subspace `P^(i+1) ⧸ P^e` is `R ⧸ p`-linear to `S ⧸ P`. -/
noncomputable def quotient_range_pow_quot_succ_inclusion_equiv [is_domain S] [is_dedekind_domain S]
  [fact (e ≠ 0)] [P.is_prime] (hP : P ≠ ⊥) {i : ℕ} (hi : i < e) :
  (_ ⧸ (pow_quot_succ_inclusion f p P e i).range) ≃ₗ[R ⧸ p] S ⧸ P :=
begin
  choose a a_mem a_not_mem using set_like.exists_of_lt
    (ideal.strict_anti_pow P hP (ideal.is_prime.ne_top infer_instance) (le_refl i.succ)),
  refine (linear_equiv.of_bijective
    (quotient_to_quotient_range_pow_quot_succ f p P e i a a_mem) _ _).symm,
  { exact quotient_to_quotient_range_pow_quot_succ_injective f p P e hi a_mem a_not_mem },
  { exact quotient_to_quotient_range_pow_quot_succ_surjective f p P e hP hi a_mem a_not_mem }
end

/-- Since the inclusion `(P^(i + 1) / P^e) ⊂ (P^i / P^e)` has a kernel isomorphic to `P / S`,
`[P^i / P^e : R / p] = [P^(i+1) / P^e : R / p] + [P / S : R / p]` -/
lemma dim_pow_quot_aux [is_domain S] [is_dedekind_domain S] [p.is_maximal] [P.is_prime]
  (hP0 : P ≠ ⊥) {i : ℕ} [fact (e ≠ 0)] (hi : i < e) :
  module.rank (R ⧸ p) (ideal.map (P^e)^.quotient.mk (P ^ i)) =
  module.rank (R ⧸ p) (S ⧸ P) + module.rank (R ⧸ p) (ideal.map (P^e)^.quotient.mk (P ^ (i + 1))) :=
begin
  letI : field (R ⧸ p) := ideal.quotient.field _,
  rw [dim_eq_of_injective _ (pow_quot_succ_inclusion_injective f p P e i),
      (quotient_range_pow_quot_succ_inclusion_equiv f p P e hP0 hi).symm.dim_eq],
  exact (dim_quotient_add_dim (linear_map.range (pow_quot_succ_inclusion f p P e i))).symm,
end

lemma dim_pow_quot [is_domain S] [is_dedekind_domain S] [p.is_maximal] [P.is_prime]
  (hP0 : P ≠ ⊥) (i : ℕ) [fact (e ≠ 0)] (hi : i ≤ e) :
  module.rank (R ⧸ p) (ideal.map (P^e)^.quotient.mk (P ^ i)) =
  (e - i) • module.rank (R ⧸ p) (S ⧸ P) :=
begin
  refine @nat.decreasing_induction' _ i e (λ j lt_e le_j ih, _) hi _,
  { rw [dim_pow_quot_aux f p P _ hP0 lt_e, ih, ← succ_nsmul, nat.sub_succ, ← nat.succ_eq_add_one,
      nat.succ_pred_eq_of_pos (nat.sub_pos_of_lt lt_e)] },
  { rw [nat.sub_self, zero_nsmul, map_quotient_mk_self],
    exact dim_bot (R ⧸ p) (S ⧸ (P^e)) }
end

omit hfPe

/-- If `p` is a maximal ideal of `R`, `S` extends `R` and `P^e` lies over `p`,
then the dimension `[S/(P^e) : R/p]` is equal to `e * [S/P : R/p]`. -/
lemma dim_prime_pow [is_domain S] [is_dedekind_domain S] [p.is_maximal] [P.is_prime] (hP0 : P ≠ ⊥)
  {e : ℕ} (he : e ≠ 0) (hp : p ≤ comap f (P ^ e)) :
  @module.rank (R ⧸ p) (S ⧸ P^e) _ _ (@algebra.to_module _ _ _ _ $
    quotient.algebra_quotient_of_le_comap hp) =
  e • @module.rank (R ⧸ p) (S ⧸ P) _ _ (@algebra.to_module _ _ _ _ $
    quotient.algebra_quotient_of_le_comap $ hp.trans $ comap_mono $ pow_le_self he) :=
begin
  letI : fact (e ≠ 0) := ⟨he⟩,
  letI : fact _ := ⟨hp⟩,
  have := dim_pow_quot f p P e hP0 0 (nat.zero_le e),
  rw [pow_zero, nat.sub_zero, ideal.one_eq_top, ideal.map_top] at this,
  exact (dim_top (R ⧸ p) _).symm.trans this
end

/-- If `p` is a maximal ideal of `R`, `S` extends `R` and `P^e` lies over `p`,
then the dimension `[S/(P^e) : R/p]`, as a natural number, is equal to `e * [S/P : R/p]`. -/
lemma finrank_prime_pow [is_domain S] [is_dedekind_domain S]
  (hP0 : P ≠ ⊥) [p.is_maximal] [P.is_prime]
  {e : ℕ} (he : e ≠ 0) (hp : p ≤ comap f (P ^ e)) :
  @finrank (R ⧸ p) (S ⧸ P^e) _ _ (@algebra.to_module _ _ _ _ $
    quotient.algebra_quotient_of_le_comap hp) =
  e * @finrank (R ⧸ p) (S ⧸ P) _ _ (@algebra.to_module _ _ _ _ $
    quotient.algebra_quotient_of_le_comap $ hp.trans $ comap_mono $ pow_le_self he) :=
begin
  letI := quotient.algebra_quotient_of_le_comap hp,
  letI := quotient.algebra_quotient_of_le_comap (hp.trans (comap_mono (pow_le_self he))),
  letI := ideal.quotient.field p,
  have hdim := dim_prime_pow _ _ _ hP0 he hp,
  by_cases hP : finite_dimensional (R ⧸ p) (S ⧸ P),
  { haveI := hP,
    haveI := (finite_dimensional_iff_of_rank_eq_nsmul he hdim).mpr hP,
    apply cardinal.nat_cast_injective,
    rw [finrank_eq_dim, nat.cast_mul, finrank_eq_dim, hdim, nsmul_eq_mul] },
  have hPe := mt (finite_dimensional_iff_of_rank_eq_nsmul he hdim).mp hP,
  simp only [finrank_of_infinite_dimensional hP, finrank_of_infinite_dimensional hPe, mul_zero],
end

section factors_map

open_locale classical

/-! ## Properties of the factors of `p.map (algebra_map R S)` -/

lemma ne_zero_of_exists_mem_factors {M : Type*} [cancel_comm_monoid_with_zero M]
  [unique_factorization_monoid M] {p a : M} (h : p ∈ factors a) : a ≠ 0 :=
begin
  intro ha,
  rw [factors, dif_pos ha] at h,
  exact multiset.not_mem_zero _ h
end

lemma dvd_of_factor {M : Type*} [cancel_comm_monoid_with_zero M] [unique_factorization_monoid M]
  {p a : M} (h : p ∈ factors a) : p ∣ a :=
dvd_trans (multiset.dvd_prod h) (associated.dvd (factors_prod (ne_zero_of_exists_mem_factors h)))

variables [is_domain S] [is_dedekind_domain S][algebra R S]

lemma factors.ne_bot (P : (factors (map (algebra_map R S) p)).to_finset) :
  (P : ideal S) ≠ ⊥ :=
(prime_of_factor _ (multiset.mem_to_finset.mp P.2)).ne_zero

instance factors.is_prime (P : (factors (map (algebra_map R S) p)).to_finset) :
  is_prime (P : ideal S) :=
ideal.is_prime_of_prime (prime_of_factor _ (multiset.mem_to_finset.mp P.2))

lemma factors.ramification_idx_ne_zero (P : (factors (map (algebra_map R S) p)).to_finset) :
  ramification_idx (algebra_map R S) p P ≠ 0 :=
is_dedekind_domain.ramification_idx_ne_zero
  (ne_zero_of_exists_mem_factors (multiset.mem_to_finset.mp P.2))
  (factors.is_prime p P)
  (ideal.le_of_dvd (dvd_of_factor (multiset.mem_to_finset.mp P.2)))

lemma factors.map_le_pow_ramification_idx (P : (factors (map (algebra_map R S) p)).to_finset) :
  map (algebra_map R S) p ≤ P ^ ramification_idx (algebra_map R S) p P :=
is_dedekind_domain.le_pow_ramification_idx
  (ne_zero_of_exists_mem_factors (multiset.mem_to_finset.mp P.2))
  (factors.is_prime p P)
  (ideal.le_of_dvd (dvd_of_factor (multiset.mem_to_finset.mp P.2)))

lemma factors.le_comap_pow_ramification_idx (P : (factors (map (algebra_map R S) p)).to_finset) :
  p ≤ comap (algebra_map R S) (P ^ ramification_idx (algebra_map R S) p P) :=
map_le_iff_le_comap.mp (factors.map_le_pow_ramification_idx p P)

variables (S)

noncomputable instance factors.algebra_quotient_quotient_pow
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  algebra (R ⧸ p) (S ⧸ (P : ideal S) ^ ramification_idx (algebra_map R S) p P) :=
quotient.algebra_quotient_of_le_comap (factors.le_comap_pow_ramification_idx _ P)

instance factors.algebra_quotient_quotient
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  algebra (R ⧸ p) (S ⧸ (P : ideal S)) :=
quotient.algebra_quotient_of_le_comap ((factors.le_comap_pow_ramification_idx _ P).trans
  (comap_mono (ideal.pow_le_self (factors.ramification_idx_ne_zero p P))))

variables {S}

@[simp] lemma factors.algebra_map_quotient_quotient_mk
  (P : (factors (map (algebra_map R S) p)).to_finset) (x : R) :
  algebra_map (R ⧸ p) (S ⧸ (P : ideal S)) (ideal.quotient.mk _ x) =
    ideal.quotient.mk _ (algebra_map R S x) :=
rfl

instance factors.is_scalar_tower
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  is_scalar_tower R (R ⧸ p) (S ⧸ (P : ideal S)) :=
is_scalar_tower.of_algebra_map_eq (λ x, by simp only [ideal.quotient.mk_algebra_map,
 ideal.quotient.algebra_map_eq, factors.algebra_map_quotient_quotient_mk])

local attribute [instance] ideal.quotient.field

lemma factors.finrank_pow_ramification_idx [p.is_maximal]
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  finrank (R ⧸ p) (S ⧸ (P : ideal S) ^ ramification_idx (algebra_map R S) p P) =
    ramification_idx (algebra_map R S) p P * inertia_deg (algebra_map R S) p P :=
begin
  rw [finrank_prime_pow, inertia_deg_algebra_map],
  { exact factors.ne_bot p P },
  { exact factors.ramification_idx_ne_zero p P },
end

instance factors.finite_dimensional_quotient [is_noetherian R S] [p.is_maximal]
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  finite_dimensional (R ⧸ p) (S ⧸ (P : ideal S)) :=
is_noetherian.iff_fg.mp $
is_noetherian_of_tower R $
is_noetherian_of_surjective S (ideal.quotient.mkₐ _ _).to_linear_map $
linear_map.range_eq_top.mpr ideal.quotient.mk_surjective

lemma factors.inertia_deg_ne_zero [is_noetherian R S] [p.is_maximal]
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  inertia_deg (algebra_map R S) p P ≠ 0 :=
by { rw inertia_deg_algebra_map, exact (finite_dimensional.finrank_pos_iff.mpr infer_instance).ne' }

instance factors.finite_dimensional_quotient_pow [is_noetherian R S] [p.is_maximal]
  (P : (factors (map (algebra_map R S) p)).to_finset) :
  finite_dimensional (R ⧸ p) (S ⧸ (P : ideal S) ^ ramification_idx (algebra_map R S) p P) :=
begin
  refine finite_dimensional.finite_dimensional_of_finrank _,
  rw [pos_iff_ne_zero, factors.finrank_pow_ramification_idx],
  exact mul_ne_zero (factors.ramification_idx_ne_zero p P) (factors.inertia_deg_ne_zero p P)
end

universes w

/-- **Chinese remainder theorem** for a ring of integers: if the prime ideal `p : ideal R`
factors in `S` as `∏ i, P i ^ e i`, then `S ⧸ I` factors as `Π i, R ⧸ (P i ^ e i)`. -/
noncomputable def factors.pi_quotient_equiv
  (p : ideal R) (hp : map (algebra_map R S) p ≠ ⊥) :
  (S ⧸ map (algebra_map R S) p) ≃+* Π (P : (factors (map (algebra_map R S) p)).to_finset),
    S ⧸ ((P : ideal S) ^ ramification_idx (algebra_map R S) p P) :=
(is_dedekind_domain.quotient_equiv_pi_factors hp).trans $
(@ring_equiv.Pi_congr_right (factors (map (algebra_map R S) p)).to_finset
  (λ P, S ⧸ (P : ideal S) ^ (factors (map (algebra_map R S) p)).count P)
  (λ P, S ⧸ (P : ideal S) ^ ramification_idx (algebra_map R S) p P) _ _
  (λ P : (factors (map (algebra_map R S) p)).to_finset, ideal.quot_equiv_of_eq $
  by rw is_dedekind_domain.ramification_idx_eq_factors_count hp
    (factors.is_prime p P) (factors.ne_bot p P)))

@[simp] lemma factors.pi_quotient_equiv_mk
  (p : ideal R) (hp : map (algebra_map R S) p ≠ ⊥) (x : S) :
  factors.pi_quotient_equiv p hp (ideal.quotient.mk _ x) = λ P, ideal.quotient.mk _ x :=
rfl

@[simp] lemma factors.pi_quotient_equiv_map
  (p : ideal R) (hp : map (algebra_map R S) p ≠ ⊥) (x : R) :
  factors.pi_quotient_equiv p hp (algebra_map _ _ x) =
    λ P, ideal.quotient.mk _ (algebra_map _ _ x) :=
rfl

/-- **Chinese remainder theorem** for a ring of integers: if the prime ideal `p : ideal R`
factors in `S` as `∏ i, P i ^ e i`,
then `S ⧸ I` factors `R ⧸ I`-linearly as `Π i, R ⧸ (P i ^ e i)`. -/
noncomputable def factors.pi_quotient_linear_equiv
  (p : ideal R) (hp : map (algebra_map R S) p ≠ ⊥) :
  (S ⧸ map (algebra_map R S) p) ≃ₗ[R ⧸ p] Π (P : (factors (map (algebra_map R S) p)).to_finset),
    S ⧸ ((P : ideal S) ^ ramification_idx (algebra_map R S) p P) :=
{ map_smul' := begin
   rintro ⟨c⟩ ⟨x⟩, ext P,
   simp only [ideal.quotient.mk_algebra_map,
     factors.pi_quotient_equiv_mk, factors.pi_quotient_equiv_map, submodule.quotient.quot_mk_eq_mk,
     pi.algebra_map_apply, ring_equiv.to_fun_eq_coe, pi.mul_apply,
     ideal.quotient.algebra_map_quotient_map_quotient, ideal.quotient.mk_eq_mk, algebra.smul_def,
     _root_.map_mul, ring_hom_comp_triple.comp_apply],
   congr
  end,
  .. factors.pi_quotient_equiv p hp }

/-- The **fundamental identity** of ramification index `e` and inertia degree `f`:
for `P` ranging over the primes lying over `p`, `∑ P, e P * f P = [Frac(S) : Frac(R)]`;
if `Frac(S) : Frac(R)` is a finite extension, `p` is maximal
and `S` is the integral closure of `R` in `L`. -/
theorem sum_ramification_inertia (K L : Type*) [field K] [field L]
  [is_domain R] [is_dedekind_domain R]
  [algebra R K] [is_fraction_ring R K] [algebra S L] [is_fraction_ring S L]
  [algebra K L] [algebra R L] [is_scalar_tower R S L] [is_scalar_tower R K L]
  [is_noetherian R S] [is_integral_closure S R L] [p.is_maximal] (hp0 : p ≠ ⊥) :
  ∑ P in (factors (map (algebra_map R S) p)).to_finset,
    ramification_idx (algebra_map R S) p P * inertia_deg (algebra_map R S) p P =
    finrank K L :=
begin
  set e := ramification_idx (algebra_map R S) p,
  set f := inertia_deg (algebra_map R S) p,
  have inj_RL : function.injective (algebra_map R L),
  { rw [is_scalar_tower.algebra_map_eq R K L, ring_hom.coe_comp],
    exact (ring_hom.injective _).comp (is_fraction_ring.injective R K) },
  have inj_RS : function.injective (algebra_map R S),
  { refine function.injective.of_comp (show function.injective (algebra_map S L ∘ _), from _),
    rw [← ring_hom.coe_comp, ← is_scalar_tower.algebra_map_eq],
    exact inj_RL },
  calc  ∑ P in (factors (map (algebra_map R S) p)).to_finset, e P * f P
      = ∑ P in (factors (map (algebra_map R S) p)).to_finset.attach,
          finrank (R ⧸ p) (S ⧸ (P : ideal S)^(e P)) : _
  ... = finrank (R ⧸ p) (Π P : (factors (map (algebra_map R S) p)).to_finset,
          (S ⧸ (P : ideal S)^(e P))) :
    (module.free.finrank_pi_fintype (R ⧸ p)).symm
  ... = finrank (R ⧸ p) (S ⧸ map (algebra_map R S) p) : _
  ... = finrank K L : _,
  { rw ← finset.sum_attach,
    refine finset.sum_congr rfl (λ P _, _),
    rw factors.finrank_pow_ramification_idx },
  { refine linear_equiv.finrank_eq (factors.pi_quotient_linear_equiv p _).symm,
    rwa [ne.def, ideal.map_eq_bot_iff_le_ker, (ring_hom.injective_iff_ker_eq_bot _).mp inj_RS,
         le_bot_iff] },
  { exact finrank_quotient_map _ _ _ inj_RL },
end

end factors_map
