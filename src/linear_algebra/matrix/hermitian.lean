/-
Copyright (c) 2022 Alexander Bentkamp. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alexander Bentkamp
-/
import analysis.inner_product_space.spectrum

/-! # Hermitian matrices

This file defines hermitian matrices and some basic results about them.

## Main definition

 * `matrix.is_hermitian `: a matrix `A : matrix n n α` is hermitian if `Aᴴ = A`.

## Tags

self-adjoint matrix, hermitian matrix

-/

namespace matrix

variables {α β : Type*} {m n : Type*} {A : matrix n n α}

open_locale matrix

local notation `⟪`x`, `y`⟫` := @inner α (pi_Lp 2 (λ (_ : n), α)) _ x y

section non_unital_semiring

variables [non_unital_semiring α] [star_ring α] [non_unital_semiring β] [star_ring β]

/-- A matrix is hermitian if it is equal to its conjugate transpose. On the reals, this definition
captures symmetric matrices. -/
def is_hermitian (A : matrix n n α) : Prop := Aᴴ = A

lemma is_hermitian.eq {A : matrix n n α} (h : A.is_hermitian) : Aᴴ = A := h

@[ext]
lemma is_hermitian.ext {A : matrix n n α} : (∀ i j, star (A j i) = A i j) → A.is_hermitian :=
by { intros h, ext i j, exact h i j }

lemma is_hermitian.apply {A : matrix n n α} (h : A.is_hermitian) (i j : n) : star (A j i) = A i j :=
by { unfold is_hermitian at h, rw [← h, conj_transpose_apply, star_star, h] }

lemma is_hermitian.ext_iff {A : matrix n n α} : A.is_hermitian ↔ ∀ i j, star (A j i) = A i j :=
⟨is_hermitian.apply, is_hermitian.ext⟩

lemma is_hermitian_mul_conj_transpose_self [fintype n] (A : matrix n n α) :
  (A ⬝ Aᴴ).is_hermitian :=
by rw [is_hermitian, conj_transpose_mul, conj_transpose_conj_transpose]

lemma is_hermitian_transpose_mul_self [fintype n] (A : matrix n n α) :
  (Aᴴ ⬝ A).is_hermitian :=
by rw [is_hermitian, conj_transpose_mul, conj_transpose_conj_transpose]

lemma is_hermitian_add_transpose_self (A : matrix n n α) :
  (A + Aᴴ).is_hermitian :=
by simp [is_hermitian, add_comm]

lemma is_hermitian_transpose_add_self (A : matrix n n α) :
  (Aᴴ + A).is_hermitian :=
by simp [is_hermitian, add_comm]

@[simp] lemma is_hermitian_zero :
  (0 : matrix n n α).is_hermitian :=
conj_transpose_zero

-- TODO: move
lemma conj_transpose_map {A : matrix n n α} (f : α → β) (hf : f ∘ star = star ∘ f) :
  Aᴴ.map f = (A.map f)ᴴ :=
by rw [conj_transpose, conj_transpose, ←transpose_map, map_map, map_map, hf]

@[simp] lemma is_hermitian.map {A : matrix n n α} (h : A.is_hermitian) (f : α → β)
    (hf : f ∘ star = star ∘ f) :
  (A.map f).is_hermitian :=
by {refine (conj_transpose_map f hf).symm.trans _, rw h.eq }

@[simp] lemma is_hermitian.transpose {A : matrix n n α} (h : A.is_hermitian) :
  Aᵀ.is_hermitian :=
by { rw [is_hermitian, conj_transpose, transpose_map], congr, exact h }

@[simp] lemma is_hermitian.conj_transpose {A : matrix n n α} (h : A.is_hermitian) :
  Aᴴ.is_hermitian :=
h.transpose.map _ rfl

@[simp] lemma is_hermitian.add {A B : matrix n n α} (hA : A.is_hermitian) (hB : B.is_hermitian) :
  (A + B).is_hermitian :=
(conj_transpose_add _ _).trans (hA.symm ▸ hB.symm ▸ rfl)

@[simp] lemma is_hermitian.minor {A : matrix n n α} (h : A.is_hermitian) (f : m → n) :
  (A.minor f f).is_hermitian :=
(conj_transpose_minor _ _ _).trans (h.symm ▸ rfl)

/-- The real diagonal matrix `diagonal v` is hermitian. -/
@[simp] lemma is_hermitian_diagonal [decidable_eq n] (v : n → ℝ) :
  (diagonal v).is_hermitian :=
diagonal_conj_transpose _

/-- A block matrix `A.from_blocks B C D` is hermitian,
    if `A` and `D` are hermitian and `Bᴴ = C`. -/
lemma is_hermitian.from_blocks
  {A : matrix m m α} {B : matrix m n α} {C : matrix n m α} {D : matrix n n α}
  (hA : A.is_hermitian) (hBC : Bᴴ = C) (hD : D.is_hermitian) :
  (A.from_blocks B C D).is_hermitian :=
begin
  have hCB : Cᴴ = B, {rw ← hBC, simp},
  unfold matrix.is_hermitian,
  rw from_blocks_conj_transpose,
  congr;
  assumption
end

/-- This is the `iff` version of `matrix.is_hermitian.from_blocks`. -/
lemma is_hermitian_from_blocks_iff
  {A : matrix m m α} {B : matrix m n α} {C : matrix n m α} {D : matrix n n α} :
  (A.from_blocks B C D).is_hermitian ↔ A.is_hermitian ∧ Bᴴ = C ∧ Cᴴ = B ∧ D.is_hermitian :=
⟨λ h, ⟨congr_arg to_blocks₁₁ h, congr_arg to_blocks₂₁ h,
       congr_arg to_blocks₁₂ h, congr_arg to_blocks₂₂ h⟩,
 λ ⟨hA, hBC, hCB, hD⟩, is_hermitian.from_blocks hA hBC hD⟩

end non_unital_semiring

section semiring

variables [semiring α] [star_ring α] [semiring β] [star_ring β]

@[simp] lemma is_hermitian_one [decidable_eq n] :
  (1 : matrix n n α).is_hermitian :=
conj_transpose_one

end semiring

section ring

variables [ring α] [star_ring α] [ring β] [star_ring β]

@[simp] lemma is_hermitian.neg {A : matrix n n α} (h : A.is_hermitian) :
  (-A).is_hermitian :=
(conj_transpose_neg _).trans (congr_arg _ h)

@[simp] lemma is_hermitian.sub {A B : matrix n n α} (hA : A.is_hermitian) (hB : B.is_hermitian) :
  (A - B).is_hermitian :=
(conj_transpose_sub _ _).trans (hA.symm ▸ hB.symm ▸ rfl)

end ring

section is_R_or_C

variables [is_R_or_C α] [is_R_or_C β]

/-- A matrix is hermitian iff the corresponding linear map is self adjoint. -/
lemma is_hermitian_iff_is_self_adjoint [fintype n] [decidable_eq n] {A : matrix n n α} :
  is_hermitian A ↔ inner_product_space.is_self_adjoint
    ((pi_Lp.linear_equiv α (λ _ : n, α)).symm.conj A.to_lin' : module.End α (pi_Lp 2 _)) :=
begin
  rw [inner_product_space.is_self_adjoint, (pi_Lp.equiv 2 (λ _ : n, α)).symm.surjective.forall₂],
  simp only [linear_equiv.conj_apply, linear_map.comp_apply, linear_equiv.coe_coe,
    pi_Lp.linear_equiv_apply, pi_Lp.linear_equiv_symm_apply, linear_equiv.symm_symm],
  simp_rw [euclidean_space.inner_eq_star_dot_product, equiv.apply_symm_apply, to_lin'_apply,
    star_mul_vec, dot_product_mul_vec],
  split,
  { rintro (h : Aᴴ = A) x y,
    rw h },
  { intro h,
    ext i j,
    simpa only [(pi.single_star i 1).symm, ← star_mul_vec, mul_one, dot_product_single,
      single_vec_mul, star_one, one_mul] using
        h (@pi.single _ _ _ (λ i, add_zero_class.to_has_zero α) i 1)
          (@pi.single _ _ _ (λ i, add_zero_class.to_has_zero α) j 1) }
end

end is_R_or_C

end matrix
