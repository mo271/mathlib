/-
Copyright (c) 2021 Christopher Hoskin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christopher Hoskin
-/
import algebra.jordan.basic

/-!
# Special Jordan algebras

A commutative multiplication on a real or complex space can be constructed from any multiplicaion by
"symmetrisation" i.e
```
a∘b = 1/2(ab+ba).
```
When the original multiplication is associative, the symmetrised algebra is a commutative Jordan
algebra. A commutative Jordan algebra which can be constructed in this way from an associative
multiplication is said to be a special Jordan algebra.

## Main results

- `comm_jordan` : The symmeterised algebra arising from an associative algebra is a commutative Jordan
  algebra.

## Implementation notes

The approach taken here is inspired by algebra.opposites.

## References

* [Hanche-Olsen and Størmer, Jordan Operator Algebras][hancheolsenstormer1984]
-/

open function

/--
The symmetrised algebra has the same underlying space as the original algebra.
-/
def sym_alg (α : Type*) : Type* := α

postfix `ˢʸᵐ`:std.prec.max_plus := sym_alg

namespace sym_alg

variables {α : Type*}

/-- The element of `sym_alg α` that represents `a : α`. -/
@[pp_nodot]
def sym : α → αˢʸᵐ := id

/-- The element of `α` represented by `x : αˢʸᵐ`. -/
@[pp_nodot]
def unsym : αˢʸᵐ → α := id

@[simp] lemma unsym_sym (a : α) : unsym (sym a) = a := rfl
@[simp] lemma sym_unsym (a : α) : sym (unsym a) = a := rfl

@[simp] lemma sym_comp_unsym : (sym : α → αˢʸᵐ) ∘ unsym = id := rfl
@[simp] lemma unsym_comp_sym : (unsym : αˢʸᵐ → α) ∘ sym = id := rfl

/-- The canonical bijection between `α` and `αˢʸᵐ`. -/
@[simps apply symm_apply { fully_applied := ff }]
def sym_equiv : α ≃ αˢʸᵐ := ⟨sym, unsym, unsym_sym, sym_unsym⟩

lemma sym_bijective : bijective (sym : α → αˢʸᵐ) := sym_equiv.bijective
lemma unsym_bijective : bijective (unsym : αˢʸᵐ → α) := sym_equiv.symm.bijective
lemma sym_injective : injective (sym : α → αˢʸᵐ) := sym_bijective.injective
lemma sym_surjective : surjective (sym : α → αˢʸᵐ) := sym_bijective.surjective
lemma unsym_injective : injective (unsym : αˢʸᵐ → α) := unsym_bijective.injective
lemma unsym_surjective : surjective (unsym : αˢʸᵐ → α) := unsym_bijective.surjective

@[simp] lemma sym_inj {a b : α} : sym a = sym b ↔ a = b := sym_injective.eq_iff
@[simp] lemma unsym_inj {a b : αˢʸᵐ} : unsym a = unsym b ↔ a = b := unsym_injective.eq_iff

instance [nontrivial α] : nontrivial αˢʸᵐ := sym_injective.nontrivial
instance [inhabited α] : inhabited αˢʸᵐ := ⟨sym default⟩
instance [subsingleton α] : subsingleton αˢʸᵐ := unsym_injective.subsingleton
instance [unique α] : unique αˢʸᵐ := unique.mk' _
instance [is_empty α] : is_empty αˢʸᵐ := function.is_empty unsym


instance [has_zero α] : has_zero (αˢʸᵐ) := { zero := sym 0 }

instance [has_one α] : has_one αˢʸᵐ := { one := sym 1 }

instance [has_add α] : has_add αˢʸᵐ :=
{ add := λ a b, sym (unsym a + unsym b) }

instance [has_sub α] : has_sub αˢʸᵐ := { sub := λ a b, sym (unsym a - unsym b) }

instance [has_neg α] : has_neg αˢʸᵐ :=
{ neg := λ a, sym (-unsym a) }

/- Introduce the symmetrised multiplication-/
instance [has_add α] [has_mul α] [has_one α] [invertible (2 : α)] : has_mul(αˢʸᵐ) :=
{ mul := λ a b, sym (⅟2 * (unsym a * unsym b + unsym b * unsym a)) }

@[to_additive] instance [has_inv α] : has_inv αˢʸᵐ :=
{ inv := λ a, sym $ (unsym a)⁻¹ }

instance (R : Type*) [has_scalar R α] : has_scalar R αˢʸᵐ :=
{ smul := λ r a, sym (r • unsym a) }

@[simp] lemma sym_zero [has_zero α] : sym (0 : α) = 0 := rfl
@[simp] lemma unsym_zero [has_zero α] : unsym (0 : αˢʸᵐ) = 0 := rfl

@[simp, to_additive] lemma sym_one [has_one α] : sym (1 : α) = 1 := rfl
@[simp, to_additive] lemma unsym_one [has_one α] : unsym (1 : αˢʸᵐ) = 1 := rfl

@[simp] lemma sym_add [has_add α] (a b : α) : sym (a + b) = sym a + sym b := rfl
@[simp] lemma unsym_add [has_add α] (a b : αˢʸᵐ) : unsym (a + b) = unsym a + unsym b := rfl

@[simp] lemma sym_neg [has_neg α] (a : α) : sym (-a) = -sym a := rfl
@[simp] lemma unsym_neg [has_neg α] (a : αˢʸᵐ) : unsym (-a) = -unsym a := rfl

@[simp, to_additive] lemma sym_inv [has_inv α] (a : α) : sym (a⁻¹) = (sym a)⁻¹ := rfl
@[simp, to_additive] lemma unsym_inv [has_inv α] (a : αˢʸᵐ) : unsym (a⁻¹) = (unsym a)⁻¹ := rfl

@[simp] lemma sym_sub [has_sub α] (a b : α) : sym (a - b) = sym a - sym b := rfl
@[simp] lemma unsym_sub [has_sub α] (a b : αˢʸᵐ) : unsym (a - b) = unsym a - unsym b := rfl

@[simp] lemma sym_smul {R : Type*} [has_scalar R α] (c : R) (a : α) : sym (c • a) = c • sym a := rfl
@[simp] lemma unsym_smul {R : Type*} [has_scalar R α] (c : R) (a : αˢʸᵐ) :
  unsym (c • a) = c • unsym a := rfl


@[simp] lemma unsym_eq_zero_iff {α} [has_zero α] (a : αˢʸᵐ) : a.unsym = (0 : α) ↔ a = (0 : αˢʸᵐ) :=
unsym_injective.eq_iff' rfl

@[simp] lemma sym_eq_zero_iff [has_zero α] (a : α) : sym a = (0 : αˢʸᵐ) ↔ a = (0 : α) :=
sym_injective.eq_iff' rfl

lemma unsym_ne_zero_iff [has_zero α] (a : αˢʸᵐ) : a.unsym ≠ (0 : α) ↔ a ≠ (0 : αˢʸᵐ) :=
not_congr $ unsym_eq_zero_iff a

lemma sym_ne_zero_iff [has_zero α] (a : α) : sym a ≠ (0 : αˢʸᵐ) ↔ a ≠ (0 : α) :=
not_congr $ sym_eq_zero_iff a

@[simp] lemma unsym_eq_one_iff [has_one α] (a : αˢʸᵐ) : a.unsym = 1 ↔ a = 1 :=
unsym_injective.eq_iff' rfl

@[simp] lemma sym_eq_one_iff [has_one α] (a : α) : sym a = 1 ↔ a = 1 :=
sym_injective.eq_iff' rfl

instance [add_comm_semigroup α] : add_comm_semigroup (αˢʸᵐ) :=
unsym_injective.add_comm_semigroup _ (λ _ _, rfl)

instance [add_monoid α] : add_monoid (αˢʸᵐ) :=
unsym_injective.add_monoid_smul _ rfl (λ _ _, rfl) (λ _ _, rfl)

instance [add_group α] : add_group (αˢʸᵐ) :=
unsym_injective.add_group_smul _ rfl
  (λ _ _, rfl) (λ _, rfl) (λ _ _, rfl) (λ _ _, rfl) (λ _ _, rfl)

instance [add_comm_monoid α] : add_comm_monoid (αˢʸᵐ) :=
{ ..sym_alg.add_comm_semigroup, ..sym_alg.add_monoid }

instance [add_comm_group α] : add_comm_group (αˢʸᵐ) :=
{ ..sym_alg.add_comm_monoid, ..sym_alg.add_group }

instance {R : Type*} [semiring R] [add_comm_monoid α] [module R α] : module R αˢʸᵐ :=
function.injective.module R ⟨unsym, rfl, λ _ _, rfl⟩ (λ _ _, id) (λ _ _, rfl)

lemma mul_def [ring α] [invertible (2 : α)] (a b : αˢʸᵐ) :
  a * b = sym (⅟2*(unsym a * unsym b + unsym b * unsym a)) := by refl

instance [has_mul α] [has_add α] [has_one α] [invertible (2 : α)] (a : α) [invertible a] :
  invertible (sym a) :=
{ inv_of := sym ⅟a,
  inv_of_mul_self := begin
    change ⅟2 * (⅟a * a + a * ⅟a) = 1,
    rw [mul_inv_of_self, inv_of_mul_self],
    exact mul_inv_of_self (⅟ 2),
  end,
  mul_inv_of_self := begin
    change ⅟2 * (a* ⅟a + ⅟a * a)=1,
    rw [mul_inv_of_self, inv_of_mul_self],
    exact mul_inv_of_self (⅟ 2),
  end }

lemma unsym_mul [has_mul α] [has_add α] [has_one α] [invertible (2 : α)] (a b : αˢʸᵐ) :
  unsym (a * b) = ⅟2*(unsym a * unsym b + unsym b * unsym a) := by refl

lemma sym_mul_sym [has_mul α] [has_add α] [has_one α] [invertible (2 : α)] (a b : α) : sym a * sym b
  = sym (⅟2*(a * b + b * a)) :=
begin
  change sym ⅟(2)*(a * b + b * a) = sym ⅟(2)*(a * b + b * a),
  refl,
end

/- The symmetrisation of a real (unital, associative) algebra is a non-associative ring -/
instance [ring α] [invertible (2 : α)] : non_unital_non_assoc_ring (αˢʸᵐ) :=
{ zero_mul := λ _,
  begin
    rw [mul_def, unsym_zero, zero_mul, mul_zero, add_zero, mul_zero, sym_zero],
    exact rfl,
  end,
  mul_zero :=  λ _,
  begin
    rw [mul_def, unsym_zero, zero_mul, mul_zero, add_zero, mul_zero, sym_zero],
    exact rfl,
  end,
  left_distrib := λ a b c, begin
    change ⅟2 * (unsym a *(unsym b + unsym c) + (unsym b + unsym c) *unsym a) =
      ⅟2 * (unsym a * unsym b + unsym b * unsym a) + (⅟2) * (unsym a * unsym c + unsym c * unsym a),
    rw [←mul_add, mul_add (unsym a), add_mul, ← add_assoc, ← add_assoc, ← sub_eq_zero, ← mul_sub,
      add_sub_add_right_eq_sub, add_assoc, add_assoc, add_sub_add_left_eq_sub],
    abel,
    rw mul_zero,
  end,
  right_distrib := λ a b c, begin
    change ⅟2 * ((unsym a + unsym b) * unsym c + unsym c * (unsym a + unsym b)) =
      ⅟2 *(unsym a * unsym c + unsym c * unsym a) + ⅟2 * (unsym b * unsym c + unsym c * unsym b),
    rw [←mul_add, add_mul, mul_add (unsym c), ←add_assoc, ←add_assoc, ← sub_eq_zero, ← mul_sub,
      add_sub_add_right_eq_sub, add_assoc, add_assoc, add_sub_add_left_eq_sub],
    abel,
    rw mul_zero,
  end,
  ..sym_alg.has_mul,
  ..sym_alg.add_comm_group, }

/- The squaring operation coincides for both multiplications -/
lemma sym_squares [ring α] [invertible (2 : α)] (a : αˢʸᵐ) : unsym(a*a) = unsym a * unsym a :=
begin
  rw [mul_def, unsym_sym],
  abel,
  simp only [int.cast_bit0, int.cast_one, inv_of_mul_self_assoc, zsmul_eq_mul],
end

/- 2 commutes with every element of a ring -/
lemma two_commute [ring α] (a : α) : commute 2 a := begin
  --convert commute.semiconj_by 2 a,
  unfold _root_.commute,
  rw [semiconj_by, mul_two, two_mul],
end

/- If 2 is invertible, ⅟2 commutes with every element of a ring -/
lemma half_commute [ring α] [invertible (2 : α)] (a : α) : commute (⅟2) a :=
  commute.inv_of_left (two_commute a)

universe u

/- The symmetrisation of a real (unital, associative) algebra multiplication is a commutative
Jordan non-associative ring -/
instance (α : Type u) [ring α] [invertible (2 : α)] : comm_jordan (αˢʸᵐ) :=
{ comm := λ a,
  begin
    intro,
    change ⅟2 * (unsym a * unsym b + unsym b * unsym a) =
      ⅟2 * (unsym b * unsym a + unsym a * unsym b),
    rw add_comm,
  end,
  jordan := λ a,
  begin
    intro,
    change ⅟2 * (⅟2 * (unsym a * unsym b + unsym b * unsym a) * unsym(a*a)
      + unsym(a*a) * (⅟2 * (unsym a * unsym b + unsym b * unsym a)))
      = ⅟2 * (unsym a * (⅟2 * (unsym b * unsym(a*a) + unsym(a*a) * unsym b))
        + (⅟2 * (unsym b * unsym(a*a) + unsym(a*a) * unsym b)) * unsym a),
    -- Rearrange LHS
    rw [← mul_assoc, ← commute.eq (half_commute (unsym (a*a))), mul_assoc, mul_assoc, ← mul_add,
      ← mul_assoc, add_mul, mul_add (unsym (a * a)), ← add_assoc, ← mul_assoc, ← mul_assoc],
    -- Rearrange RHS
    rw [← mul_assoc, ← commute.eq (half_commute (unsym a)), mul_assoc (⅟2) (unsym a),
      mul_assoc (⅟2) _ (unsym a), ← mul_add, ← mul_assoc],
    nth_rewrite_rhs 0 mul_add (unsym a),
    rw [add_mul, ← add_assoc, ← mul_assoc, ← mul_assoc],

    rw sym_squares,
    rw [← mul_assoc, ← mul_assoc, ← mul_assoc, ← mul_assoc, ← sub_eq_zero, ← mul_sub],

    convert mul_zero (⅟(2:α) * ⅟(2:α)),
    rw [add_sub_add_right_eq_sub, add_assoc, add_assoc, add_sub_add_left_eq_sub, add_comm,
      add_sub_add_right_eq_sub, sub_eq_zero],
  end }

end sym_alg
