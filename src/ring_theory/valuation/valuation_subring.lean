/-
Copyright (c) 2022 Adam Topaz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adam Topaz
-/
import ring_theory.valuation.valuation_ring
import ring_theory.localization.as_subring
import algebraic_geometry.prime_spectrum.basic

/-!

# Valuation subrings of a field

# Projects

The order structure on `valuation_subring K`.

-/

variables (K : Type*) [field K]

/-- A valuation subring of a field `K` is a subring `A` such that for every `x : K`,
either `x ∈ A` or `x⁻¹ ∈ K`. -/
structure valuation_subring extends subring K :=
(mem_or_inv_mem' : ∀ x : K, x ∈ carrier ∨ x⁻¹ ∈ carrier)

namespace valuation_subring

variables {K} (A : valuation_subring K)

instance : set_like (valuation_subring K) K :=
{ coe := λ A, A.to_subring,
  coe_injective' := λ A B h, by { obtain ⟨⟨⟩⟩ := A, obtain ⟨⟨⟩⟩ := B, congr, exact h } }

@[simp] lemma mem_carrier (x : K) : x ∈ A.carrier ↔ x ∈ A := iff.refl _
@[simp] lemma mem_to_subring (x : K) : x ∈ A.to_subring ↔ x ∈ A := iff.refl _

@[ext] lemma ext (A B : valuation_subring K)
  (h : ∀ x, x ∈ A ↔ x ∈ B) : A = B := set_like.ext h

lemma zero_mem : (0 : K) ∈ A := A.to_subring.zero_mem
lemma one_mem : (1 : K) ∈ A := A.to_subring.one_mem
lemma add_mem (x y : K) : x ∈ A → y ∈ A → x + y ∈ A := A.to_subring.add_mem
lemma mul_mem (x y : K) : x ∈ A → y ∈ A → x * y ∈ A := A.to_subring.mul_mem

lemma mem_or_inv_mem (x : K) : x ∈ A ∨ x⁻¹ ∈ A := A.mem_or_inv_mem' _

instance : comm_ring A := show comm_ring A.to_subring, by apply_instance
instance : is_domain A := show is_domain A.to_subring, by apply_instance

instance : has_top (valuation_subring K) := has_top.mk $
{ mem_or_inv_mem' := λ x, or.inl trivial,
  ..(⊤ : subring K) }

lemma mem_top (x : K) : x ∈ (⊤ : valuation_subring K) := trivial

lemma le_top : A ≤ ⊤ := λ a ha, mem_top _

instance : order_top (valuation_subring K) :=
{ top := ⊤,
  le_top := le_top }

instance : inhabited (valuation_subring K) := ⟨⊤⟩

instance : valuation_ring A :=
begin
  constructor,
  intros a b,
  by_cases (b : K) = 0, { use 0, left, ext, simp [h] },
  by_cases (a : K) = 0, { use 0, right, ext, simp [h] },
  cases A.mem_or_inv_mem (a/b) with hh hh,
  { use ⟨a/b,hh⟩, right, ext, field_simp, ring },
  { rw (show (a/b : K)⁻¹ = b/a, by field_simp) at hh,
    use ⟨b/a,hh⟩, left, ext, field_simp, ring },
end

instance : algebra A K :=
show algebra A.to_subring K, by apply_instance

@[simp]
lemma algebra_map_apply (a : A) : algebra_map A K a = a := rfl

instance : is_fraction_ring A K :=
{ map_units := λ ⟨y,hy⟩,
    (units.mk0 (y : K) (λ c, non_zero_divisors.ne_zero hy $ subtype.ext c)).is_unit,
  surj := λ z, begin
    by_cases z = 0, { use (0,1), simp [h] },
    cases A.mem_or_inv_mem z with hh hh,
    { use (⟨z,hh⟩,1), simp },
    { refine ⟨⟨1,⟨⟨_,hh⟩,_⟩⟩, mul_inv_cancel h⟩,
      exact mem_non_zero_divisors_iff_ne_zero.2 (λ c, h (inv_eq_zero.mp (congr_arg coe c))) },
  end,
  eq_iff_exists := λ a b, ⟨ λ h, ⟨1, by { ext, simpa using h }⟩, λ ⟨c,h⟩,
    congr_arg coe ((mul_eq_mul_right_iff.1 h).resolve_right (non_zero_divisors.ne_zero c.2)) ⟩ }

/-- The value group of the valuation associated to `A`. -/
@[derive linear_ordered_comm_group_with_zero]
def value_group := valuation_ring.value_group A K

/-- Any valuation subring of `K` induces a natural valuation on `K`. -/
def valuation : valuation K A.value_group := valuation_ring.valuation A K

lemma valuation_le_one (a : A) : A.valuation a ≤ 1 :=
(valuation_ring.mem_integer_iff A K _).2 ⟨a,rfl⟩

lemma mem_of_valuation_le_one (x : K) (h : A.valuation x ≤ 1) : x ∈ A :=
let ⟨a,ha⟩ := (valuation_ring.mem_integer_iff A K x).1 h in ha ▸ a.2

lemma valuation_le_one_iff (x : K) : A.valuation x ≤ 1 ↔ x ∈ A :=
⟨mem_of_valuation_le_one _ _, λ ha, A.valuation_le_one ⟨x,ha⟩⟩

lemma valuation_eq_iff (x y : K) : A.valuation x = A.valuation y ↔
  ∃ a : Aˣ, (a : K) * y = x := quotient.eq'

lemma valuation_le_iff (x y : K) : A.valuation x ≤ A.valuation y ↔
  ∃ a : A, (a : K) * y = x := iff.rfl

lemma valuation_surjective : function.surjective A.valuation := surjective_quot_mk _

lemma valuation_unit (a : Aˣ) : A.valuation a = 1 :=
by { rw [← A.valuation.map_one, valuation_eq_iff], use a, simp }

lemma valuation_eq_one_iff (a : A) : is_unit a ↔ A.valuation a = 1 :=
⟨ λ h, A.valuation_unit h.unit,
  λ h, begin
    have ha : (a : K) ≠ 0,
    { intro c, rw [c, A.valuation.map_zero] at h, exact zero_ne_one h },
    have ha' : (a : K)⁻¹ ∈ A,
    { rw [← valuation_le_one_iff, A.valuation.map_inv, h, inv_one] },
    exact is_unit_of_mul_eq_one a ⟨a⁻¹, ha'⟩ (by { ext, field_simp }),
  end ⟩

lemma valuation_lt_one_or_eq_one (a : A) : A.valuation a < 1 ∨ A.valuation a = 1 :=
lt_or_eq_of_le (A.valuation_le_one a)

lemma valuation_lt_one_iff (a : A) : a ∈ local_ring.maximal_ideal A ↔ A.valuation a < 1 :=
begin
  rw local_ring.mem_maximal_ideal,
  dsimp [nonunits], rw valuation_eq_one_iff,
  exact (A.valuation_le_one a).lt_iff_ne.symm,
end

/-- A subring `R` of `K` such that for all `x : K` either `x ∈ R` or `x⁻¹ ∈ R` is
  a valuation subring of `K`. -/
def of_subring (R : subring K) (hR : ∀ x : K, x ∈ R ∨ x⁻¹ ∈ R) : valuation_subring K :=
{ mem_or_inv_mem' := hR, ..R }

@[simp]
lemma mem_of_subring (R : subring K) (hR : ∀ x : K, x ∈ R ∨ x⁻¹ ∈ R) (x : K) :
  x ∈ of_subring R hR ↔ x ∈ R := iff.refl _

def of_le (R : valuation_subring K) (S : subring K) (h : R.to_subring ≤ S) :
  valuation_subring K :=
{ mem_or_inv_mem' := λ x, (R.mem_or_inv_mem x).imp (@h x) (@h _), ..S}

section order

instance : semilattice_sup (valuation_subring K) :=
{ sup := λ R S, of_le R (R.to_subring ⊔ S.to_subring) $ le_sup_left,
  le_sup_left := λ R S x hx, (le_sup_left : R.to_subring ≤ R.to_subring ⊔ S.to_subring) hx,
  le_sup_right := λ R S x hx, (le_sup_right : S.to_subring ≤ R.to_subring ⊔ S.to_subring) hx,
  sup_le := λ R S T hR hT x hx, (sup_le hR hT : R.to_subring ⊔ S.to_subring ≤ T.to_subring) hx,
  ..(infer_instance : partial_order (valuation_subring K)) }

/-- The ring homomorphism induced by the partial order. -/
def inclusion (R S : valuation_subring K) (h : R ≤ S) : R →+* S :=
subring.inclusion h

def subtype (R : valuation_subring K) : R →+* K :=
subring.subtype R.to_subring

def map_of_le (R S : valuation_subring K) (h : R ≤ S) :
  R.value_group →*₀ S.value_group :=
{ to_fun := quotient.map' id $ λ x y ⟨u,hu⟩, ⟨units.map (R.inclusion S h).to_monoid_hom u, hu⟩,
  map_zero' := rfl,
  map_one' := rfl,
  map_mul' := by { rintro ⟨⟩ ⟨⟩, refl } }

@[mono]
lemma monotone_map_of_le (R S : valuation_subring K) (h : R ≤ S) :
  monotone (R.map_of_le S h) :=
by { rintros ⟨x⟩ ⟨y⟩ ⟨a,ha⟩, exact ⟨R.inclusion S h a, ha⟩ }

@[simp]
lemma map_of_le_comp_valuation (R S : valuation_subring K) (h : R ≤ S) :
  R.map_of_le S h ∘ R.valuation = S.valuation := by { ext, refl }

@[simp]
lemma map_of_le_valuation_apply (R S : valuation_subring K) (h : R ≤ S) (x : K) :
  R.map_of_le S h (R.valuation x) = S.valuation x := rfl

def ideal_of_le (R S : valuation_subring K) (h : R ≤ S) : ideal R :=
{ carrier := { r | S.valuation r < 1 },
  add_mem' := λ a b ha hb, lt_of_le_of_lt (S.valuation.map_add a b) (max_lt ha hb),
  zero_mem' := zero_lt_one₀,
  smul_mem' := begin
    rintros c a (ha : S.valuation _ < _), rw smul_eq_mul,
    let t : S := ⟨c, h c.2⟩,
    change S.valuation (c * a) < _,
    rw S.valuation.map_mul,
    refine lt_of_le_of_lt _ ha,
    refine mul_le_of_le_one_left' _,
    rw S.valuation_le_one_iff,
    exact h c.2
  end }

instance prime_ideal_of_le (R S : valuation_subring K) (h : R ≤ S) :
  (ideal_of_le R S h).is_prime :=
begin
  constructor,
  { rw ideal.ne_top_iff_one, rintro (c : S.valuation _ < _),
    push_cast at c, rw S.valuation.map_one at c, exact ne_of_lt c rfl },
  { rintros x y (hh : S.valuation _ < _), push_cast at hh,
    rw S.valuation.map_mul at hh,
    by_cases hx : S.valuation x < 1, { exact or.inl hx },
    right,
    have : S.valuation x = 1,
    { cases S.valuation_lt_one_or_eq_one ⟨x, h x.2⟩ with h1 h1,
      { contradiction },
      { assumption } },
    { rwa [this, one_mul] at hh, } }
end

def of_prime (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  valuation_subring K :=
of_le A (localization.subring K P.prime_compl $
  le_non_zero_divisors_of_no_zero_divisors $ not_not_intro P.zero_mem) $
λ a ha, ⟨⟨a, ha⟩, 1, P.prime_compl.one_mem, by simp⟩

instance of_prime_algebra (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  algebra A (A.of_prime P) :=
show algebra A (localization.subring _ P.prime_compl
  (le_non_zero_divisors_of_no_zero_divisors $ not_not_intro P.zero_mem)),
by apply_instance

instance of_prime_scalar_tower (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  is_scalar_tower A (A.of_prime P) K :=
show is_scalar_tower A (localization.subring _ P.prime_compl
  (le_non_zero_divisors_of_no_zero_divisors $ not_not_intro P.zero_mem)) K,
by apply_instance

instance of_prime_localization (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  is_localization.at_prime (A.of_prime P) P :=
show is_localization P.prime_compl
  (localization.subring _ P.prime_compl
  (le_non_zero_divisors_of_no_zero_divisors $ not_not_intro P.zero_mem)),
  by apply_instance

lemma le_of_prime (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  A ≤ of_prime A P :=
λ a ha, ⟨⟨a, ha⟩, 1, P.prime_compl.one_mem, by simp⟩

lemma of_prime_valuation_eq_one_iff_mem_prime_compl
  (A : valuation_subring K)
  (P : ideal A) [P.is_prime] (x : A) :
  (of_prime A P).valuation x = 1 ↔ x ∈ P.prime_compl :=
begin
  rw ← is_localization.at_prime.is_unit_to_map_iff (A.of_prime P) P x,
  let y : A.of_prime P := ⟨x, le_of_prime _ _ x.2⟩,
  change (A.of_prime P).valuation y = 1 ↔ is_unit y,
  exact (valuation_eq_one_iff _ _).symm,
end

@[simp]
lemma ideal_of_le_of_prime (A : valuation_subring K) (P : ideal A) [P.is_prime] :
  ideal_of_le A (of_prime A P) (le_of_prime A P) = P :=
begin
  ext a,
  change (A.of_prime P).valuation a < 1 ↔ _,
  have : (A.of_prime P).valuation a ≤ 1,
  { rw [← (A.map_of_le (A.of_prime P) (A.le_of_prime _)).map_one,
      ← A.map_of_le_valuation_apply (A.of_prime P) (le_of_prime _ _)],
    mono,
    apply valuation_le_one },
  replace this := lt_or_eq_of_le this,
  cases this,
  { refine ⟨_, λ _, this⟩,
    intro _, rw ← is_localization.at_prime.to_map_mem_maximal_iff (A.of_prime P) P,
    rwa valuation_lt_one_iff },
  { split,
    { intro h, rw this at h, exact false.elim (ne_of_lt h rfl) },
    { intro h,
      rw ← is_localization.at_prime.to_map_mem_maximal_iff (A.of_prime P) P at h,
      rwa valuation_lt_one_iff at h } }
end

@[simp]
lemma of_prime_ideal_of_le (R S : valuation_subring K) (h : R ≤ S) :
  of_prime R (ideal_of_le R S h) = S :=
begin
  ext x,
  split,
  { rintro ⟨a,r,hr,rfl⟩,
    change _ ∉ _ at hr, dsimp [ideal_of_le] at hr,
    let s : S := R.inclusion S h r,
    change ¬ S.valuation s < 1 at hr,
    have hs : S.valuation s = 1,
    { cases S.valuation_lt_one_or_eq_one s, { contradiction }, { assumption } },
    rw [← valuation_le_one_iff, valuation.map_mul, valuation.map_inv],
    rw [mul_inv_le_iff₀, one_mul], erw hs,
    rw valuation_le_one_iff, apply h, exact a.2,
    { erw hs, exact one_ne_zero } },
  { intro hx,
    by_cases hγ : R.valuation x ≤ 1,
    { use x, rwa valuation_le_one_iff at hγ, use 1, split, apply submonoid.one_mem _, simp },
    use 1, simp only [ring_hom.map_one, one_mul], push_neg at hγ,
    use x⁻¹, rw [← valuation_le_one_iff, valuation.map_inv,
      ← inv_one, inv_le_inv₀], exact le_of_lt hγ,
    { intro c, rw c at hγ,
      apply not_lt_of_lt hγ,
      exact zero_lt_one₀, },
    { exact one_ne_zero },
    split,
    { change ¬ (S.valuation _ < 1),
      push_neg, push_cast, rw [valuation.map_inv, ← inv_one, inv_le_inv₀],
      { rwa valuation_le_one_iff, },
      { exact one_ne_zero },
      { intro c, rw ← R.valuation.map_one at hγ,
        replace hγ := le_of_lt hγ, replace hγ := monotone_map_of_le R S h hγ,
        simp only [valuation.map_one, (map_of_le _ _ _).map_one, map_of_le_valuation_apply] at hγ,
        rw c at hγ,
        apply not_lt_of_le hγ, exact zero_lt_one₀ } },
    { simp } }
end

lemma of_prime_le_of_le (P Q : ideal A) [P.is_prime] [Q.is_prime]
  (h : P ≤ Q) : of_prime A Q ≤ of_prime A P :=
begin
  rintros x ⟨a,s,hs,rfl⟩,
  exact ⟨a, s, λ c, hs (h c), rfl⟩,
end

lemma ideal_of_le_le_of_le (R S : valuation_subring K)
  (hR : A ≤ R) (hS : A ≤ S) (h : R ≤ S) :
  ideal_of_le A S hS ≤ ideal_of_le A R hR :=
begin
  rintros x (hx : S.valuation _ < 1),
  change R.valuation _ < 1,
  by_contra c, push_neg at c, replace c := monotone_map_of_le R S h c,
  rw [(map_of_le _ _ _).map_one, map_of_le_valuation_apply] at c,
  apply not_le_of_lt hx c,
end

@[simps]
def prime_spectrum_equiv :
  prime_spectrum A ≃ { S | A ≤ S } :=
{ to_fun := λ P, ⟨of_prime A P.as_ideal, le_of_prime _ _⟩,
  inv_fun := λ S, ⟨ideal_of_le _ S S.2, infer_instance⟩,
  left_inv := λ P, by { ext1, simpa },
  right_inv := λ S, by { ext1, simp } }

@[simps]
def prime_spectrum_order_equiv :
  order_dual (prime_spectrum A) ≃o { S | A ≤ S } :=
{ map_rel_iff' := begin
    intros P Q, dsimp, split,
    { intros h,
      let P' : prime_spectrum A := P,
      let Q' : prime_spectrum A := Q,
      change Q' ≤ P',
      rw ← (prime_spectrum_equiv A).symm_apply_apply P',
      rw ← (prime_spectrum_equiv A).symm_apply_apply Q',
      apply ideal_of_le_le_of_le,
      exact h },
    { intros h,
      apply of_prime_le_of_le,
      exact h }
  end,
  ..(prime_spectrum_equiv A) }

open_locale classical

noncomputable
instance linear_order_overring : linear_order { S | A ≤ S } :=
{ le_total := begin
    intros R S,
    let P := ideal_of_le A R R.2,
    let Q := ideal_of_le A S S.2,
    cases le_total P Q,
    { right, change S.1 ≤ R.1,
      rw ← of_prime_ideal_of_le A R.1 R.2,
      rw ← of_prime_ideal_of_le A S.1 S.2,
      apply of_prime_le_of_le, exact h },
    { left, change R.1 ≤ S.1,
      rw ← of_prime_ideal_of_le A R.1 R.2,
      rw ← of_prime_ideal_of_le A S.1 S.2,
      apply of_prime_le_of_le, exact h }
  end,
  decidable_le := infer_instance,
  ..(infer_instance : partial_order _) }

end order

end valuation_subring
