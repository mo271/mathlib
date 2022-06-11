/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro
-/
import data.finset.sort
import data.set.functor

/-!
# Finite sets

This file defines predicates for finite and infinite sets and provides
`fintype` instances for many set constructions. It also proves basic facts
about finite sets and gives ways to manipulate `set.finite` expressions.

## Main definitions

* `set.finite : set α → Prop`
* `set.infinite : set α → Prop`
* `set.finite_of_fintype` to prove `set.finite` for a `set` from a `fintype` instance.
* `set.finite.to_finset` to noncomputably produce a `finset` from a `set.finite` proof.
  (See `set.to_finset` for a computable version.)

## Implementation

A finite set is defined to be a set whose coercion to a type has a `fintype` instance.
Since `set.finite` is `Prop`-valued, this is the mere fact that the `fintype` instance
exists.

There are two components to finiteness constructions. The first is `fintype` instances for each
construction. This gives a way to actually compute a `finset` that represents the set, and these
may be accessed using `set.to_finset`. This gets the `finset` in the correct form, since otherwise
`finset.univ : finset s` is a `finset` for the subtype for `s`. The second component is
"constructors" for `set.finite` that give proofs that `fintype` instances exist classically given
other `set.finite` proofs. Unlike the `fintype` instances, these *do not* use any decidability
instances since they do not compute anything.

## Tags

finite sets
-/

open set function

universes u v w x
variables {α : Type u} {β : Type v} {ι : Sort w} {γ : Type x}

namespace set

/-- A set is finite if there is a `finset` with the same elements.
This is represented as there being a `fintype` instance for the set
coerced to a type.

Note: this is a custom inductive type rather than `nonempty (fintype s)`
so that it won't be frozen as a local instance. -/
@[protected] inductive finite (s : set α) : Prop
| intro : fintype s → finite

-- The `protected` attribute does not take effect within the same namespace block.
end set

namespace set

/-- Constructor for `set.finite` with the `fintype` as an instance argument. -/
theorem finite_of_fintype (s : set α) [h : fintype s] : s.finite := ⟨h⟩

lemma finite_def {s : set α} : s.finite ↔ nonempty (fintype s) := ⟨λ ⟨h⟩, ⟨h⟩, λ ⟨h⟩, ⟨h⟩⟩

/-- A finite set coerced to a type is a `fintype`.
This is the `fintype` projection for a `set.finite`.

Note that because `finite` isn't a typeclass, this definition will not fire if it
is made into an instance -/
noncomputable def finite.fintype {s : set α} (h : s.finite) : fintype s :=
(finite_def.mp h).some

/-- Using choice, get the `finset` that represents this `set.` -/
noncomputable def finite.to_finset {s : set α} (h : s.finite) : finset α :=
@set.to_finset _ _ h.fintype

theorem finite.exists_finset {s : set α} (h : s.finite) :
  ∃ s' : finset α, ∀ a : α, a ∈ s' ↔ a ∈ s :=
by { casesI h, exact ⟨s.to_finset, λ _, mem_to_finset⟩ }

theorem finite.exists_finset_coe {s : set α} (h : s.finite) :
  ∃ s' : finset α, ↑s' = s :=
by { casesI h, exact ⟨s.to_finset, s.coe_to_finset⟩ }

/-- Finite sets can be lifted to finsets. -/
instance : can_lift (set α) (finset α) :=
{ coe := coe,
  cond := set.finite,
  prf := λ s hs, hs.exists_finset_coe }

/-- A set is infinite if it is not finite.

This is protected so that it does not conflict with global `infinite`. -/
protected def infinite (s : set α) : Prop := ¬ s.finite

@[simp] lemma not_infinite {s : set α} : ¬ s.infinite ↔ s.finite := not_not

/-- See also `fintype_or_infinite`. -/
lemma finite_or_infinite {s : set α} : s.finite ∨ s.infinite := em _


/-! ### Basic properties of `set.finite.to_finset` -/

section finite_to_finset

@[simp] lemma finite.coe_to_finset {s : set α} (h : s.finite) : (h.to_finset : set α) = s :=
@set.coe_to_finset _ s h.fintype

@[simp] theorem finite.mem_to_finset {s : set α} (h : s.finite) {a : α} : a ∈ h.to_finset ↔ a ∈ s :=
@mem_to_finset _ _ h.fintype _

@[simp] theorem finite.nonempty_to_finset {s : set α} (h : s.finite) :
  h.to_finset.nonempty ↔ s.nonempty :=
by rw [← finset.coe_nonempty, finite.coe_to_finset]

@[simp] lemma finite.coe_sort_to_finset {s : set α} (h : s.finite) :
  (h.to_finset : Type*) = s :=
by rw [← finset.coe_sort_coe _, h.coe_to_finset]

@[simp] lemma finite_empty_to_finset (h : (∅ : set α).finite) : h.to_finset = ∅ :=
by rw [← finset.coe_inj, h.coe_to_finset, finset.coe_empty]

@[simp] lemma finite.to_finset_inj {s t : set α} {hs : s.finite} {ht : t.finite} :
  hs.to_finset = ht.to_finset ↔ s = t :=
by simp only [←finset.coe_inj, finite.coe_to_finset]

lemma subset_to_finset_iff {s : finset α} {t : set α} (ht : t.finite) :
  s ⊆ ht.to_finset ↔ ↑s ⊆ t :=
by rw [← finset.coe_subset, ht.coe_to_finset]

@[simp] lemma finite_to_finset_eq_empty_iff {s : set α} {h : s.finite} :
  h.to_finset = ∅ ↔ s = ∅ :=
by simp only [←finset.coe_inj, finite.coe_to_finset, finset.coe_empty]

@[simp, mono] lemma finite.to_finset_mono {s t : set α} {hs : s.finite} {ht : t.finite} :
  hs.to_finset ⊆ ht.to_finset ↔ s ⊆ t :=
begin
  split,
  { intros h x,
    rw [← hs.mem_to_finset, ← ht.mem_to_finset],
    exact λ hx, h hx },
  { intros h x,
    rw [hs.mem_to_finset, ht.mem_to_finset],
    exact λ hx, h hx }
end

@[simp, mono] lemma finite.to_finset_strict_mono {s t : set α} {hs : s.finite} {ht : t.finite} :
  hs.to_finset ⊂ ht.to_finset ↔ s ⊂ t :=
begin
  rw [←lt_eq_ssubset, ←finset.lt_iff_ssubset, lt_iff_le_and_ne, lt_iff_le_and_ne],
  simp
end

end finite_to_finset


/-! ### Fintype instances

Every instance here should have a corresponding `set.finite` constructor in the next section.
 -/

section fintype_instances

instance fintype_univ [fintype α] : fintype (@univ α) :=
fintype.of_equiv α (equiv.set.univ α).symm

/-- If `(set.univ : set α)` is finite then `α` is a finite type. -/
noncomputable def fintype_of_finite_univ (H : (univ : set α).finite) : fintype α :=
@fintype.of_equiv _ (univ : set α) H.fintype (equiv.set.univ _)

instance fintype_union [decidable_eq α] (s t : set α) [fintype s] [fintype t] :
  fintype (s ∪ t : set α) := fintype.of_finset (s.to_finset ∪ t.to_finset) $ by simp

instance fintype_sep (s : set α) (p : α → Prop) [fintype s] [decidable_pred p] :
  fintype ({a ∈ s | p a} : set α) := fintype.of_finset (s.to_finset.filter p) $ by simp

instance fintype_inter (s t : set α) [decidable_eq α] [fintype s] [fintype t] :
  fintype (s ∩ t : set α) := fintype.of_finset (s.to_finset ∩ t.to_finset) $ by simp

/-- A `fintype` instance for set intersection where the left set has a `fintype` instance. -/
instance fintype_inter_of_left (s t : set α) [fintype s] [decidable_pred (∈ t)] :
  fintype (s ∩ t : set α) := fintype.of_finset (s.to_finset.filter (∈ t)) $ by simp

/-- A `fintype` instance for set intersection where the right set has a `fintype` instance. -/
instance fintype_inter_of_right (s t : set α) [fintype t] [decidable_pred (∈ s)] :
  fintype (s ∩ t : set α) := fintype.of_finset (t.to_finset.filter (∈ s)) $ by simp [and_comm]

/-- A `fintype` structure on a set defines a `fintype` structure on its subset. -/
def fintype_subset (s : set α) {t : set α} [fintype s] [decidable_pred (∈ t)] (h : t ⊆ s) :
  fintype t :=
by { rw ← inter_eq_self_of_subset_right h, apply set.fintype_inter_of_left }

instance fintype_diff [decidable_eq α] (s t : set α) [fintype s] [fintype t] :
  fintype (s \ t : set α) := fintype.of_finset (s.to_finset \ t.to_finset) $ by simp

instance fintype_diff_left (s t : set α) [fintype s] [decidable_pred (∈ t)] :
  fintype (s \ t : set α) := set.fintype_sep s (∈ tᶜ)

instance fintype_Union [decidable_eq α] [fintype (plift ι)]
  (f : ι → set α) [∀ i, fintype (f i)] : fintype (⋃ i, f i) :=
fintype.of_finset (finset.univ.bUnion (λ i : plift ι, (f i.down).to_finset)) $ by simp

instance fintype_sUnion [decidable_eq α] {s : set (set α)}
  [fintype s] [H : ∀ (t : s), fintype (t : set α)] : fintype (⋃₀ s) :=
by { rw sUnion_eq_Union, exact @set.fintype_Union _ _ _ _ _ H }

/-- A union of sets with `fintype` structure over a set with `fintype` structure has a `fintype`
structure. -/
def fintype_bUnion [decidable_eq α] {ι : Type*} (s : set ι) [fintype s]
  (t : ι → set α) (H : ∀ i ∈ s, fintype (t i)) : fintype (⋃(x ∈ s), t x) :=
fintype.of_finset
(s.to_finset.attach.bUnion
  (λ x, by { haveI := H x (by simpa using x.property), exact (t x).to_finset })) $ by simp

instance fintype_bUnion' [decidable_eq α] {ι : Type*} (s : set ι) [fintype s]
  (t : ι → set α) [∀ i, fintype (t i)] : fintype (⋃(x ∈ s), t x) :=
fintype.of_finset (s.to_finset.bUnion (λ x, (t x).to_finset)) $ by simp

/-- If `s : set α` is a set with `fintype` instance and `f : α → set β` is a function such that
each `f a`, `a ∈ s`, has a `fintype` structure, then `s >>= f` has a `fintype` structure. -/
def fintype_bind {α β} [decidable_eq β] (s : set α) [fintype s]
  (f : α → set β) (H : ∀ a ∈ s, fintype (f a)) : fintype (s >>= f) :=
set.fintype_bUnion s f H

instance fintype_bind' {α β} [decidable_eq β] (s : set α) [fintype s]
  (f : α → set β) [H : ∀ a, fintype (f a)] : fintype (s >>= f) :=
set.fintype_bUnion' s f

instance fintype_empty : fintype (∅ : set α) := fintype.of_finset ∅ $ by simp

instance fintype_singleton (a : α) : fintype ({a} : set α) := fintype.of_finset {a} $ by simp

instance fintype_pure : ∀ a : α, fintype (pure a : set α) :=
set.fintype_singleton

/-- A `fintype` instance for inserting an element into a `set` using the
corresponding `insert` function on `finset`. This requires `decidable_eq α`.
There is also `set.fintype_insert'` when `a ∈ s` is decidable. -/
instance fintype_insert (a : α) (s : set α) [decidable_eq α] [fintype s] :
  fintype (insert a s : set α) :=
fintype.of_finset (insert a s.to_finset) $ by simp

/-- A `fintype` structure on `insert a s` when inserting a new element. -/
def fintype_insert_of_not_mem {a : α} (s : set α) [fintype s] (h : a ∉ s) :
  fintype (insert a s : set α) :=
fintype.of_finset ⟨a ::ₘ s.to_finset.1, s.to_finset.nodup.cons (by simp [h]) ⟩ $ by simp

/-- A `fintype` structure on `insert a s` when inserting a pre-existing element. -/
def fintype_insert_of_mem {a : α} (s : set α) [fintype s] (h : a ∈ s) :
  fintype (insert a s : set α) :=
fintype.of_finset s.to_finset $ by simp [h]

/-- The `set.fintype_insert` instance requires decidable equality, but when `a ∈ s`
is decidable for this particular `a` we can still get a `fintype` instance by using
`set.fintype_insert_of_not_mem` or `set.fintype_insert_of_mem`.

This instance pre-dates `set.fintype_insert`, and it is less efficient.
When `decidable_mem_of_fintype` is made a local instance, then this instance would
override `set.fintype_insert` if not for the fact that its priority has been
adjusted. See Note [lower instance priority]. -/
@[priority 100]
instance fintype_insert' (a : α) (s : set α) [decidable $ a ∈ s] [fintype s] :
  fintype (insert a s : set α) :=
if h : a ∈ s then fintype_insert_of_mem s h else fintype_insert_of_not_mem s h

instance fintype_image [decidable_eq β] (s : set α) (f : α → β) [fintype s] : fintype (f '' s) :=
fintype.of_finset (s.to_finset.image f) $ by simp

/-- If a function `f` has a partial inverse and sends a set `s` to a set with `[fintype]` instance,
then `s` has a `fintype` structure as well. -/
def fintype_of_fintype_image (s : set α)
  {f : α → β} {g} (I : is_partial_inv f g) [fintype (f '' s)] : fintype s :=
fintype.of_finset ⟨_, (f '' s).to_finset.2.filter_map g $ injective_of_partial_inv_right I⟩ $ λ a,
begin
  suffices : (∃ b x, f x = b ∧ g b = some a ∧ x ∈ s) ↔ a ∈ s,
  by simpa [exists_and_distrib_left.symm, and.comm, and.left_comm, and.assoc],
  rw exists_swap,
  suffices : (∃ x, x ∈ s ∧ g (f x) = some a) ↔ a ∈ s, {simpa [and.comm, and.left_comm, and.assoc]},
  simp [I _, (injective_of_partial_inv I).eq_iff]
end

instance fintype_range [decidable_eq α] (f : ι → α) [fintype (plift ι)] :
  fintype (range f) :=
fintype.of_finset (finset.univ.image $ f ∘ plift.down) $ by simp [equiv.plift.exists_congr_left]

instance fintype_map {α β} [decidable_eq β] :
  ∀ (s : set α) (f : α → β) [fintype s], fintype (f <$> s) := set.fintype_image

instance fintype_lt_nat (n : ℕ) : fintype {i | i < n} :=
fintype.of_finset (finset.range n) $ by simp

instance fintype_le_nat (n : ℕ) : fintype {i | i ≤ n} :=
by simpa [nat.lt_succ_iff] using set.fintype_lt_nat (n+1)

/-- This is not an instance so that it does not conflict with the one
in src/order/locally_finite. -/
def nat.fintype_Iio (n : ℕ) : fintype (Iio n) :=
set.fintype_lt_nat n

instance fintype_prod (s : set α) (t : set β) [fintype s] [fintype t] :
  fintype (s ×ˢ t : set (α × β)) :=
fintype.of_finset (s.to_finset.product t.to_finset) $ by simp

/-- `image2 f s t` is `fintype` if `s` and `t` are. -/
instance fintype_image2 [decidable_eq γ] (f : α → β → γ) (s : set α) (t : set β)
  [hs : fintype s] [ht : fintype t] : fintype (image2 f s t : set γ) :=
by { rw ← image_prod, apply set.fintype_image }

instance fintype_seq [decidable_eq β] (f : set (α → β)) (s : set α) [fintype f] [fintype s] :
  fintype (f.seq s) :=
by { rw seq_def, apply set.fintype_bUnion' }

instance fintype_seq' {α β : Type u} [decidable_eq β]
  (f : set (α → β)) (s : set α) [fintype f] [fintype s] : fintype (f <*> s) :=
set.fintype_seq f s

instance fintype_mem_finset (s : finset α) : fintype {a | a ∈ s} :=
finset.fintype_coe_sort s

end fintype_instances


/-! ### Constructors for `set.finite`

Every constructor here should have a corresponding `fintype` instance in the previous section
(or in the `fintype` module).

The implementation of these constructors ideally should be no more than `set.finite_of_fintype`,
after possibly setting up some `fintype` and classical `decidable` instances.
-/
section set_finite_constructors

theorem finite.of_fintype [fintype α] (s : set α) : s.finite :=
by { classical, apply finite_of_fintype }

@[nontriviality] lemma finite.of_subsingleton [subsingleton α] (s : set α) : s.finite :=
finite.of_fintype s

theorem finite_univ [fintype α] : (@univ α).finite := finite_of_fintype _

theorem finite.union {s t : set α} (hs : s.finite) (ht : t.finite) : (s ∪ t).finite :=
by { classical, casesI hs, casesI ht, apply finite_of_fintype }

lemma finite.sup {s t : set α} : s.finite → t.finite → (s ⊔ t).finite := finite.union

theorem finite.sep {s : set α} (hs : s.finite) (p : α → Prop) : {a ∈ s | p a}.finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite.inter_of_left {s : set α} (hs : s.finite) (t : set α) : (s ∩ t).finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite.inter_of_right {s : set α} (hs : s.finite) (t : set α) : (t ∩ s).finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite.inf_of_left {s : set α} (h : s.finite) (t : set α) : (s ⊓ t).finite :=
h.inter_of_left t

theorem finite.inf_of_right {s : set α} (h : s.finite) (t : set α) : (t ⊓ s).finite :=
h.inter_of_right t

theorem finite.subset {s : set α} (hs : s.finite) {t : set α} (ht : t ⊆ s) : t.finite :=
by { classical, casesI hs, haveI := set.fintype_subset _ ht, apply finite_of_fintype }

theorem finite.diff {s : set α} (hs : s.finite) (t : set α) : (s \ t).finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite.of_diff {s t : set α} (hd : (s \ t).finite) (ht : t.finite) : s.finite :=
(hd.union ht).subset $ subset_diff_union _ _

theorem finite_Union [fintype (plift ι)] {f : ι → set α} (H : ∀ i, (f i).finite) :
  (⋃ i, f i).finite :=
by { classical, haveI := λ i, (H i).fintype, apply finite_of_fintype }

theorem finite.sUnion {s : set (set α)} (hs : s.finite) (H : ∀ t ∈ s, set.finite t) :
  (⋃₀ s).finite :=
by { classical, casesI hs, haveI := λ (i : s), (H i i.2).fintype, apply finite_of_fintype }

theorem finite.bUnion {ι} {s : set ι} (hs : s.finite)
  {t : ι → set α} (ht : ∀ i ∈ s, (t i).finite) : (⋃(i ∈ s), t i).finite :=
by { classical, casesI hs,
     haveI := fintype_bUnion s t (λ i hi, (ht i hi).fintype), apply finite_of_fintype }

/-- Dependent version of `finite.bUnion`. -/
theorem finite.bUnion' {ι} {s : set ι} (hs : s.finite)
  {t : Π (i ∈ s), set α} (ht : ∀ i ∈ s, (t i ‹_›).finite) : (⋃(i ∈ s), t i ‹_›).finite :=
by { casesI hs, rw [bUnion_eq_Union], apply finite_Union (λ (i : s), ht i.1 i.2), }

theorem finite.sInter {α : Type*} {s : set (set α)} {t : set α} (ht : t ∈ s)
  (hf : t.finite) : (⋂₀ s).finite :=
hf.subset (sInter_subset_of_mem ht)

theorem finite.bind {α β} {s : set α} {f : α → set β} (h : s.finite) (hf : ∀ a ∈ s, (f a).finite) :
  (s >>= f).finite :=
h.bUnion hf

@[simp] theorem finite_empty : (∅ : set α).finite := finite_of_fintype _

@[simp] theorem finite_singleton (a : α) : ({a} : set α).finite := finite_of_fintype _

theorem finite_pure (a : α) : (pure a : set α).finite := finite_of_fintype _

@[simp] theorem finite.insert (a : α) {s : set α} (hs : s.finite) : (insert a s).finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite.image {s : set α} (f : α → β) (hs : s.finite) : (f '' s).finite :=
by { classical, casesI hs, apply finite_of_fintype }

theorem finite_range (f : ι → α) [fintype (plift ι)] : (range f).finite :=
by { classical, apply finite_of_fintype }

lemma finite.dependent_image {s : set α} (hs : s.finite) (F : Π i ∈ s, β) :
  {y : β | ∃ x (hx : x ∈ s), y = F x hx}.finite :=
by { casesI hs, simpa [range, eq_comm] using finite_range (λ x : s, F x x.2) }

theorem finite.map {α β} {s : set α} : ∀ (f : α → β), s.finite → (f <$> s).finite :=
finite.image

theorem finite.of_finite_image {s : set α} {f : α → β} (h : (f '' s).finite) (hi : set.inj_on f s) :
  s.finite :=
by { casesI h, exact ⟨fintype.of_injective (λ a, (⟨f a.1, mem_image_of_mem f a.2⟩ : f '' s))
                       (λ a b eq, subtype.eq $ hi a.2 b.2 $ subtype.ext_iff_val.1 eq)⟩ }

theorem finite.of_preimage {f : α → β} {s : set β} (h : (f ⁻¹' s).finite) (hf : surjective f) :
  s.finite :=
hf.image_preimage s ▸ h.image _

theorem finite.preimage {s : set β} {f : α → β}
  (I : set.inj_on f (f⁻¹' s)) (h : s.finite) : (f ⁻¹' s).finite :=
(h.subset (image_preimage_subset f s)).of_finite_image I

theorem finite.preimage_embedding {s : set β} (f : α ↪ β) (h : s.finite) : (f ⁻¹' s).finite :=
h.preimage (λ _ _ _ _ h', f.injective h')

lemma finite_lt_nat (n : ℕ) : set.finite {i | i < n} := finite_of_fintype _

lemma finite_le_nat (n : ℕ) : set.finite {i | i ≤ n} := finite_of_fintype _

lemma finite.prod {s : set α} {t : set β} (hs : s.finite) (ht : t.finite) :
  (s ×ˢ t : set (α × β)).finite :=
by { classical, casesI hs, casesI ht, apply finite_of_fintype }

lemma finite.image2 (f : α → β → γ) {s : set α} {t : set β} (hs : s.finite) (ht : t.finite) :
  (image2 f s t).finite :=
by { classical, casesI hs, casesI ht, apply finite_of_fintype }

theorem finite.seq {f : set (α → β)} {s : set α} (hf : f.finite) (hs : s.finite) :
  (f.seq s).finite :=
by { classical, casesI hf, casesI hs, apply finite_of_fintype }

theorem finite.seq' {α β : Type u} {f : set (α → β)} {s : set α} (hf : f.finite) (hs : s.finite) :
  (f <*> s).finite :=
hf.seq hs

theorem finite_mem_finset (s : finset α) : {a | a ∈ s}.finite := finite_of_fintype _

lemma subsingleton.finite {s : set α} (h : s.subsingleton) : s.finite :=
h.induction_on finite_empty finite_singleton

theorem exists_finite_iff_finset {p : set α → Prop} :
  (∃ s : set α, s.finite ∧ p s) ↔ ∃ s : finset α, p ↑s :=
⟨λ ⟨s, hs, hps⟩, ⟨hs.to_finset, hs.coe_to_finset.symm ▸ hps⟩,
  λ ⟨s, hs⟩, ⟨↑s, finite_mem_finset s, hs⟩⟩

/-- There are finitely many subsets of a given finite set -/
lemma finite.finite_subsets {α : Type u} {a : set α} (h : a.finite) : {b | b ⊆ a}.finite :=
⟨fintype.of_finset ((finset.powerset h.to_finset).map finset.coe_emb.1) $ λ s,
  by simpa [← @exists_finite_iff_finset α (λ t, t ⊆ a ∧ t = s), subset_to_finset_iff,
    ← and.assoc] using h.subset⟩

/-- Finite product of finite sets is finite -/
lemma finite.pi {δ : Type*} [fintype δ] {κ : δ → Type*} {t : Π d, set (κ d)}
  (ht : ∀ d, (t d).finite) :
  (pi univ t).finite :=
begin
  lift t to Π d, finset (κ d) using ht,
  classical,
  rw ← fintype.coe_pi_finset,
  exact finite_of_fintype (fintype.pi_finset t),
end

/-- A finite union of finsets is finite. -/
lemma union_finset_finite_of_range_finite (f : α → finset β) (h : (range f).finite) :
  (⋃ a, (f a : set β)).finite :=
by { rw ← bUnion_range, exact h.bUnion (λ y hy, finite_of_fintype y) }

lemma finite_range_ite {p : α → Prop} [decidable_pred p] {f g : α → β} (hf : (range f).finite)
  (hg : (range g).finite) : (range (λ x, if p x then f x else g x)).finite :=
(hf.union hg).subset range_ite_subset

lemma finite_range_const {c : β} : (range (λ x : α, c)).finite :=
(finite_singleton c).subset range_const_subset

end set_finite_constructors


/-! ### Properties -/

instance finite.inhabited : inhabited {s : set α // s.finite} := ⟨⟨∅, finite_empty⟩⟩

@[simp] lemma finite_union {s t : set α} : (s ∪ t).finite ↔ s.finite ∧ t.finite :=
⟨λ h, ⟨h.subset (subset_union_left _ _), h.subset (subset_union_right _ _)⟩,
 λ ⟨hs, ht⟩, hs.union ht⟩

theorem finite_image_iff {s : set α} {f : α → β} (hi : inj_on f s) :
  (f '' s).finite ↔ s.finite :=
⟨λ h, h.of_finite_image hi, finite.image _⟩

lemma univ_finite_iff_nonempty_fintype :
  (univ : set α).finite ↔ nonempty (fintype α) :=
⟨λ h, ⟨fintype_of_finite_univ h⟩, λ ⟨_i⟩, by exactI finite_univ⟩

lemma finite.to_finset_insert [decidable_eq α] {a : α} {s : set α} (hs : s.finite) :
  (hs.insert a).to_finset = insert a hs.to_finset :=
finset.ext $ by simp

lemma finite.fin_embedding {s : set α} (h : s.finite) : ∃ (n : ℕ) (f : fin n ↪ α), range f = s :=
⟨_, (fintype.equiv_fin (h.to_finset : set α)).symm.as_embedding, by simp⟩

lemma finite.fin_param {s : set α} (h : s.finite) :
  ∃ (n : ℕ) (f : fin n → α), injective f ∧ range f = s :=
let ⟨n, f, hf⟩ := h.fin_embedding in ⟨n, f, f.injective, hf⟩

lemma finite_option {s : set (option α)} : s.finite ↔ {x : α | some x ∈ s}.finite :=
⟨λ h, h.preimage_embedding embedding.some,
  λ h, ((h.image some).insert none).subset $
    λ x, option.cases_on x (λ _, or.inl rfl) (λ x hx, or.inr $ mem_image_of_mem _ hx)⟩

lemma finite_image_fst_and_snd_iff {s : set (α × β)} :
  (prod.fst '' s).finite ∧ (prod.snd '' s).finite ↔ s.finite :=
⟨λ h, (h.1.prod h.2).subset $ λ x h, ⟨mem_image_of_mem _ h, mem_image_of_mem _ h⟩,
  λ h, ⟨h.image _, h.image _⟩⟩

lemma forall_finite_image_eval_iff {δ : Type*} [fintype δ] {κ : δ → Type*} {s : set (Π d, κ d)} :
  (∀ d, (eval d '' s).finite) ↔ s.finite :=
⟨λ h, (finite.pi h).subset $ subset_pi_eval_image _ _, λ h d, h.image _⟩

lemma finite_subset_Union {s : set α} (hs : s.finite)
  {ι} {t : ι → set α} (h : s ⊆ ⋃ i, t i) : ∃ I : set ι, I.finite ∧ s ⊆ ⋃ i ∈ I, t i :=
begin
  casesI hs,
  choose f hf using show ∀ x : s, ∃ i, x.1 ∈ t i, {simpa [subset_def] using h},
  refine ⟨range f, finite_range f, λ x hx, _⟩,
  rw [bUnion_range, mem_Union],
  exact ⟨⟨x, hx⟩, hf _⟩
end

lemma eq_finite_Union_of_finite_subset_Union  {ι} {s : ι → set α} {t : set α} (tfin : t.finite)
  (h : t ⊆ ⋃ i, s i) :
  ∃ I : set ι, I.finite ∧ ∃ σ : {i | i ∈ I} → set α,
     (∀ i, (σ i).finite) ∧ (∀ i, σ i ⊆ s i) ∧ t = ⋃ i, σ i :=
let ⟨I, Ifin, hI⟩ := finite_subset_Union tfin h in
⟨I, Ifin, λ x, s x ∩ t,
    λ i, tfin.subset (inter_subset_right _ _),
    λ i, inter_subset_left _ _,
    begin
      ext x,
      rw mem_Union,
      split,
      { intro x_in,
        rcases mem_Union.mp (hI x_in) with ⟨i, _, ⟨hi, rfl⟩, H⟩,
        use [i, hi, H, x_in] },
      { rintros ⟨i, hi, H⟩,
        exact H }
    end⟩

@[elab_as_eliminator]
theorem finite.induction_on {C : set α → Prop} {s : set α} (h : s.finite)
  (H0 : C ∅) (H1 : ∀ {a s}, a ∉ s → set.finite s → C s → C (insert a s)) : C s :=
let ⟨t⟩ := h in by exactI
match s.to_finset, @mem_to_finset _ s _ with
| ⟨l, nd⟩, al := begin
    change ∀ a, a ∈ l ↔ a ∈ s at al,
    clear _let_match _match t h, revert s nd al,
    refine multiset.induction_on l _ (λ a l IH, _); intros s nd al,
    { rw show s = ∅, from eq_empty_iff_forall_not_mem.2 (by simpa using al),
      exact H0 },
    { rw ← show insert a {x | x ∈ l} = s, from set.ext (by simpa using al),
      cases multiset.nodup_cons.1 nd with m nd',
      refine H1 _ ⟨finset.subtype.fintype ⟨l, nd'⟩⟩ (IH nd' (λ _, iff.rfl)),
      exact m }
  end
end

@[elab_as_eliminator]
theorem finite.dinduction_on {C : ∀ (s : set α), s.finite → Prop} {s : set α} (h : s.finite)
  (H0 : C ∅ finite_empty)
  (H1 : ∀ {a s}, a ∉ s → ∀ h : set.finite s, C s h → C (insert a s) (h.insert a)) :
  C s h :=
have ∀ h : s.finite, C s h,
  from finite.induction_on h (λ h, H0) (λ a s has hs ih h, H1 has hs (ih _)),
this h

section
local attribute [instance] nat.fintype_Iio

/--
If `P` is some relation between terms of `γ` and sets in `γ`,
such that every finite set `t : set γ` has some `c : γ` related to it,
then there is a recursively defined sequence `u` in `γ`
so `u n` is related to the image of `{0, 1, ..., n-1}` under `u`.

(We use this later to show sequentially compact sets
are totally bounded.)
-/
lemma seq_of_forall_finite_exists  {γ : Type*}
  {P : γ → set γ → Prop} (h : ∀ t : set γ, t.finite → ∃ c, P c t) :
  ∃ u : ℕ → γ, ∀ n, P (u n) (u '' Iio n) :=
⟨λ n, @nat.strong_rec_on' (λ _, γ) n $ λ n ih, classical.some $ h
    (range $ λ m : Iio n, ih m.1 m.2)
    (finite_range _),
λ n, begin
  classical,
  refine nat.strong_rec_on' n (λ n ih, _),
  rw nat.strong_rec_on_beta', convert classical.some_spec (h _ _),
  ext x, split,
  { rintros ⟨m, hmn, rfl⟩, exact ⟨⟨m, hmn⟩, rfl⟩ },
  { rintros ⟨⟨m, hmn⟩, rfl⟩, exact ⟨m, hmn, rfl⟩ }
end⟩

end


/-! ### Cardinality -/

theorem empty_card : fintype.card (∅ : set α) = 0 := rfl

@[simp] theorem empty_card' {h : fintype.{u} (∅ : set α)} :
  @fintype.card (∅ : set α) h = 0 :=
eq.trans (by congr) empty_card

theorem card_fintype_insert_of_not_mem {a : α} (s : set α) [fintype s] (h : a ∉ s) :
  @fintype.card _ (fintype_insert_of_not_mem s h) = fintype.card s + 1 :=
by rw [fintype_insert_of_not_mem, fintype.card_of_finset];
   simp [finset.card, to_finset]; refl

@[simp] theorem card_insert {a : α} (s : set α)
  [fintype s] (h : a ∉ s) {d : fintype.{u} (insert a s : set α)} :
  @fintype.card _ d = fintype.card s + 1 :=
by rw ← card_fintype_insert_of_not_mem s h; congr

lemma card_image_of_inj_on {s : set α} [fintype s]
  {f : α → β} [fintype (f '' s)] (H : ∀x∈s, ∀y∈s, f x = f y → x = y) :
  fintype.card (f '' s) = fintype.card s :=
by haveI := classical.prop_decidable; exact
calc fintype.card (f '' s) = (s.to_finset.image f).card : fintype.card_of_finset' _ (by simp)
... = s.to_finset.card : finset.card_image_of_inj_on
    (λ x hx y hy hxy, H x (mem_to_finset.1 hx) y (mem_to_finset.1 hy) hxy)
... = fintype.card s : (fintype.card_of_finset' _ (λ a, mem_to_finset)).symm

lemma card_image_of_injective (s : set α) [fintype s]
  {f : α → β} [fintype (f '' s)] (H : function.injective f) :
  fintype.card (f '' s) = fintype.card s :=
card_image_of_inj_on $ λ _ _ _ _ h, H h

@[simp] theorem card_singleton (a : α) :
  fintype.card ({a} : set α) = 1 :=
fintype.card_of_subsingleton _

lemma card_lt_card {s t : set α} [fintype s] [fintype t] (h : s ⊂ t) :
  fintype.card s < fintype.card t :=
fintype.card_lt_of_injective_not_surjective (set.inclusion h.1) (set.inclusion_injective h.1) $
  λ hst, (ssubset_iff_subset_ne.1 h).2 (eq_of_inclusion_surjective hst)

lemma card_le_of_subset {s t : set α} [fintype s] [fintype t] (hsub : s ⊆ t) :
  fintype.card s ≤ fintype.card t :=
fintype.card_le_of_injective (set.inclusion hsub) (set.inclusion_injective hsub)

lemma eq_of_subset_of_card_le {s t : set α} [fintype s] [fintype t]
   (hsub : s ⊆ t) (hcard : fintype.card t ≤ fintype.card s) : s = t :=
(eq_or_ssubset_of_subset hsub).elim id
  (λ h, absurd hcard $ not_le_of_lt $ card_lt_card h)

lemma card_range_of_injective [fintype α] {f : α → β} (hf : injective f)
  [fintype (range f)] : fintype.card (range f) = fintype.card α :=
eq.symm $ fintype.card_congr $ equiv.of_injective f hf

lemma finite.card_to_finset {s : set α} [fintype s] (h : s.finite) :
  h.to_finset.card = fintype.card s :=
begin
  rw [← finset.card_attach, finset.attach_eq_univ, ← fintype.card],
  refine fintype.card_congr (equiv.set_congr _),
  ext x,
  show x ∈ h.to_finset ↔ x ∈ s,
  simp,
end

lemma card_ne_eq [fintype α] (a : α) [fintype {x : α | x ≠ a}] :
  fintype.card {x : α | x ≠ a} = fintype.card α - 1 :=
begin
  haveI := classical.dec_eq α,
  rw [←to_finset_card, to_finset_ne_eq_erase, finset.card_erase_of_mem (finset.mem_univ _),
      finset.card_univ],
end


/-! ### Infinite sets -/

theorem infinite_univ_iff : (@univ α).infinite ↔ infinite α :=
⟨λ h₁, ⟨λ h₂, h₁ $ @finite_univ α h₂⟩, λ ⟨h₁⟩ h₂, h₁ (fintype_of_finite_univ h₂)⟩

theorem infinite_univ [h : infinite α] : (@univ α).infinite :=
infinite_univ_iff.2 h

theorem infinite_coe_iff {s : set α} : infinite s ↔ s.infinite :=
⟨λ ⟨h₁⟩ h₂, h₁ h₂.fintype, λ h₁, ⟨λ h₂, h₁ ⟨h₂⟩⟩⟩

theorem infinite.to_subtype {s : set α} (h : s.infinite) : infinite s :=
infinite_coe_iff.2 h

/-- Embedding of `ℕ` into an infinite set. -/
noncomputable def infinite.nat_embedding (s : set α) (h : s.infinite) : ℕ ↪ s :=
by { haveI := h.to_subtype, exact infinite.nat_embedding s }

lemma infinite.exists_subset_card_eq {s : set α} (hs : s.infinite) (n : ℕ) :
  ∃ t : finset α, ↑t ⊆ s ∧ t.card = n :=
⟨((finset.range n).map (hs.nat_embedding _)).map (embedding.subtype _), by simp⟩

lemma infinite.nonempty {s : set α} (h : s.infinite) : s.nonempty :=
let a := infinite.nat_embedding s h 37 in ⟨a.1, a.2⟩

lemma infinite_of_finite_compl [infinite α] {s : set α} (hs : sᶜ.finite) : s.infinite :=
λ h, set.infinite_univ (by simpa using hs.union h)

lemma finite.infinite_compl [infinite α] {s : set α} (hs : s.finite) : sᶜ.infinite :=
λ h, set.infinite_univ (by simpa using hs.union h)

protected theorem infinite.mono {s t : set α} (h : s ⊆ t) : s.infinite → t.infinite :=
mt (λ ht, ht.subset h)

lemma infinite.diff {s t : set α} (hs : s.infinite) (ht : t.finite) : (s \ t).infinite :=
λ h, hs $ h.of_diff ht

@[simp] lemma infinite_union {s t : set α} : (s ∪ t).infinite ↔ s.infinite ∨ t.infinite :=
by simp only [set.infinite, finite_union, not_and_distrib]

theorem infinite_of_infinite_image (f : α → β) {s : set α} (hs : (f '' s).infinite) :
  s.infinite :=
mt (finite.image f) hs

theorem infinite_image_iff {s : set α} {f : α → β} (hi : inj_on f s) :
  (f '' s).infinite ↔ s.infinite :=
not_congr $ finite_image_iff hi

theorem infinite_of_inj_on_maps_to {s : set α} {t : set β} {f : α → β}
  (hi : inj_on f s) (hm : maps_to f s t) (hs : s.infinite) : t.infinite :=
((infinite_image_iff hi).2 hs).mono (maps_to'.mp hm)

theorem infinite.exists_ne_map_eq_of_maps_to {s : set α} {t : set β} {f : α → β}
  (hs : s.infinite) (hf : maps_to f s t) (ht : t.finite) :
  ∃ (x ∈ s) (y ∈ s), x ≠ y ∧ f x = f y :=
begin
  contrapose! ht,
  exact infinite_of_inj_on_maps_to (λ x hx y hy, not_imp_not.1 (ht x hx y hy)) hf hs
end

theorem infinite_range_of_injective [infinite α] {f : α → β} (hi : injective f) :
  (range f).infinite :=
by { rw [←image_univ, infinite_image_iff (inj_on_of_injective hi _)], exact infinite_univ }

theorem infinite_of_injective_forall_mem [infinite α] {s : set β} {f : α → β}
  (hi : injective f) (hf : ∀ x : α, f x ∈ s) : s.infinite :=
by { rw ←range_subset_iff at hf, exact (infinite_range_of_injective hi).mono hf }

lemma infinite.exists_nat_lt {s : set ℕ} (hs : s.infinite) (n : ℕ) : ∃ m ∈ s, n < m :=
let ⟨m, hm⟩ := (hs.diff $ set.finite_le_nat n).nonempty in ⟨m, by simpa using hm⟩

lemma infinite.exists_not_mem_finset {s : set α} (hs : s.infinite) (f : finset α) :
  ∃ a ∈ s, a ∉ f :=
let ⟨a, has, haf⟩ := (hs.diff (finite_of_fintype f)).nonempty
in ⟨a, has, λ h, haf $ finset.mem_coe.1 h⟩


/-! ### Order properties -/

lemma finite_is_top (α : Type*) [partial_order α] : {x : α | is_top x}.finite :=
(subsingleton_is_top α).finite

lemma finite_is_bot (α : Type*) [partial_order α] : {x : α | is_bot x}.finite :=
(subsingleton_is_bot α).finite

theorem infinite.exists_lt_map_eq_of_maps_to [linear_order α] {s : set α} {t : set β} {f : α → β}
  (hs : s.infinite) (hf : maps_to f s t) (ht : t.finite) :
  ∃ (x ∈ s) (y ∈ s), x < y ∧ f x = f y :=
let ⟨x, hx, y, hy, hxy, hf⟩ := hs.exists_ne_map_eq_of_maps_to hf ht
in hxy.lt_or_lt.elim (λ hxy, ⟨x, hx, y, hy, hxy, hf⟩) (λ hyx, ⟨y, hy, x, hx, hyx, hf.symm⟩)

lemma finite.exists_lt_map_eq_of_range_subset [linear_order α] [infinite α] {t : set β}
  {f : α → β} (hf : range f ⊆ t) (ht : t.finite) :
  ∃ a b, a < b ∧ f a = f b :=
begin
  rw [range_subset_iff, ←maps_univ_to] at hf,
  obtain ⟨a, -, b, -, h⟩ := (@infinite_univ α _).exists_lt_map_eq_of_maps_to hf ht,
  exact ⟨a, b, h⟩,
end

lemma exists_min_image [linear_order β] (s : set α) (f : α → β) (h1 : s.finite) :
  s.nonempty → ∃ a ∈ s, ∀ b ∈ s, f a ≤ f b
| ⟨x, hx⟩ := by simpa only [exists_prop, finite.mem_to_finset]
  using h1.to_finset.exists_min_image f ⟨x, h1.mem_to_finset.2 hx⟩

lemma exists_max_image [linear_order β] (s : set α) (f : α → β) (h1 : s.finite) :
  s.nonempty → ∃ a ∈ s, ∀ b ∈ s, f b ≤ f a
| ⟨x, hx⟩ := by simpa only [exists_prop, finite.mem_to_finset]
  using h1.to_finset.exists_max_image f ⟨x, h1.mem_to_finset.2 hx⟩

theorem exists_lower_bound_image [hα : nonempty α] [linear_order β] (s : set α) (f : α → β)
  (h : s.finite) : ∃ (a : α), ∀ b ∈ s, f a ≤ f b :=
begin
  by_cases hs : set.nonempty s,
  { exact let ⟨x₀, H, hx₀⟩ := set.exists_min_image s f h hs in ⟨x₀, λ x hx, hx₀ x hx⟩ },
  { exact nonempty.elim hα (λ a, ⟨a, λ x hx, absurd (set.nonempty_of_mem hx) hs⟩) }
end

theorem exists_upper_bound_image [hα : nonempty α] [linear_order β] (s : set α) (f : α → β)
  (h : s.finite) : ∃ (a : α), ∀ b ∈ s, f b ≤ f a :=
begin
  by_cases hs : set.nonempty s,
  { exact let ⟨x₀, H, hx₀⟩ := set.exists_max_image s f h hs in ⟨x₀, λ x hx, hx₀ x hx⟩ },
  { exact nonempty.elim hα (λ a, ⟨a, λ x hx, absurd (set.nonempty_of_mem hx) hs⟩) }
end

lemma finite.supr_binfi_of_monotone {ι ι' α : Type*} [preorder ι'] [nonempty ι']
  [is_directed ι' (≤)] [order.frame α] {s : set ι} (hs : s.finite) {f : ι → ι' → α}
  (hf : ∀ i ∈ s, monotone (f i)) :
  (⨆ j, ⨅ i ∈ s, f i j) = ⨅ i ∈ s, ⨆ j, f i j :=
begin
  revert hf,
  refine hs.induction_on _ _,
  { intro hf, simp [supr_const] },
  { intros a s has hs ihs hf,
    rw [ball_insert_iff] at hf,
    simp only [infi_insert, ← ihs hf.2],
    exact supr_inf_of_monotone hf.1 (λ j₁ j₂ hj, infi₂_mono $ λ i hi, hf.2 i hi hj) }
end

lemma finite.supr_binfi_of_antitone {ι ι' α : Type*} [preorder ι'] [nonempty ι']
  [is_directed ι' (swap (≤))] [order.frame α] {s : set ι} (hs : s.finite) {f : ι → ι' → α}
  (hf : ∀ i ∈ s, antitone (f i)) :
  (⨆ j, ⨅ i ∈ s, f i j) = ⨅ i ∈ s, ⨆ j, f i j :=
@finite.supr_binfi_of_monotone ι ι'ᵒᵈ α _ _ _ _ _ hs _ (λ i hi, (hf i hi).dual_left)

lemma finite.infi_bsupr_of_monotone {ι ι' α : Type*} [preorder ι'] [nonempty ι']
  [is_directed ι' (swap (≤))] [order.coframe α] {s : set ι} (hs : s.finite) {f : ι → ι' → α}
  (hf : ∀ i ∈ s, monotone (f i)) :
  (⨅ j, ⨆ i ∈ s, f i j) = ⨆ i ∈ s, ⨅ j, f i j :=
hs.supr_binfi_of_antitone (λ i hi, (hf i hi).dual_right)

lemma finite.infi_bsupr_of_antitone {ι ι' α : Type*} [preorder ι'] [nonempty ι']
  [is_directed ι' (≤)] [order.coframe α] {s : set ι} (hs : s.finite) {f : ι → ι' → α}
  (hf : ∀ i ∈ s, antitone (f i)) :
  (⨅ j, ⨆ i ∈ s, f i j) = ⨆ i ∈ s, ⨅ j, f i j :=
hs.supr_binfi_of_monotone (λ i hi, (hf i hi).dual_right)

lemma _root_.supr_infi_of_monotone {ι ι' α : Type*} [fintype ι] [preorder ι'] [nonempty ι']
  [is_directed ι' (≤)] [order.frame α] {f : ι → ι' → α} (hf : ∀ i, monotone (f i)) :
  (⨆ j, ⨅ i, f i j) = ⨅ i, ⨆ j, f i j :=
by simpa only [infi_univ] using finite_univ.supr_binfi_of_monotone (λ i hi, hf i)

lemma _root_.supr_infi_of_antitone {ι ι' α : Type*} [fintype ι] [preorder ι'] [nonempty ι']
  [is_directed ι' (swap (≤))] [order.frame α] {f : ι → ι' → α} (hf : ∀ i, antitone (f i)) :
  (⨆ j, ⨅ i, f i j) = ⨅ i, ⨆ j, f i j :=
@supr_infi_of_monotone ι ι'ᵒᵈ α _ _ _ _ _ _ (λ i, (hf i).dual_left)

lemma _root_.infi_supr_of_monotone {ι ι' α : Type*} [fintype ι] [preorder ι'] [nonempty ι']
  [is_directed ι' (swap (≤))] [order.coframe α] {f : ι → ι' → α} (hf : ∀ i, monotone (f i)) :
  (⨅ j, ⨆ i, f i j) = ⨆ i, ⨅ j, f i j :=
supr_infi_of_antitone (λ i, (hf i).dual_right)

lemma _root_.infi_supr_of_antitone {ι ι' α : Type*} [fintype ι] [preorder ι'] [nonempty ι']
  [is_directed ι' (≤)] [order.coframe α] {f : ι → ι' → α} (hf : ∀ i, antitone (f i)) :
  (⨅ j, ⨆ i, f i j) = ⨆ i, ⨅ j, f i j :=
supr_infi_of_monotone (λ i, (hf i).dual_right)

/-- An increasing union distributes over finite intersection. -/
lemma Union_Inter_of_monotone {ι ι' α : Type*} [fintype ι] [preorder ι'] [is_directed ι' (≤)]
  [nonempty ι'] {s : ι → ι' → set α} (hs : ∀ i, monotone (s i)) :
  (⋃ j : ι', ⋂ i : ι, s i j) = ⋂ i : ι, ⋃ j : ι', s i j :=
supr_infi_of_monotone hs

/-- A decreasing union distributes over finite intersection. -/
lemma Union_Inter_of_antitone {ι ι' α : Type*} [fintype ι] [preorder ι'] [is_directed ι' (swap (≤))]
  [nonempty ι'] {s : ι → ι' → set α} (hs : ∀ i, antitone (s i)) :
  (⋃ j : ι', ⋂ i : ι, s i j) = ⋂ i : ι, ⋃ j : ι', s i j :=
supr_infi_of_antitone hs

/-- An increasing intersection distributes over finite union. -/
lemma Inter_Union_of_monotone {ι ι' α : Type*} [fintype ι] [preorder ι'] [is_directed ι' (swap (≤))]
  [nonempty ι'] {s : ι → ι' → set α} (hs : ∀ i, monotone (s i)) :
  (⋂ j : ι', ⋃ i : ι, s i j) = ⋃ i : ι, ⋂ j : ι', s i j :=
infi_supr_of_monotone hs

/-- A decreasing intersection distributes over finite union. -/
lemma Inter_Union_of_antitone {ι ι' α : Type*} [fintype ι] [preorder ι'] [is_directed ι' (≤)]
  [nonempty ι'] {s : ι → ι' → set α} (hs : ∀ i, antitone (s i)) :
  (⋂ j : ι', ⋃ i : ι, s i j) = ⋃ i : ι, ⋂ j : ι', s i j :=
infi_supr_of_antitone hs

lemma Union_pi_of_monotone {ι ι' : Type*} [linear_order ι'] [nonempty ι'] {α : ι → Type*}
  {I : set ι} {s : Π i, ι' → set (α i)} (hI : I.finite) (hs : ∀ i ∈ I, monotone (s i)) :
  (⋃ j : ι', I.pi (λ i, s i j)) = I.pi (λ i, ⋃ j, s i j) :=
begin
  simp only [pi_def, bInter_eq_Inter, preimage_Union],
  haveI := hI.fintype,
  exact Union_Inter_of_monotone (λ i j₁ j₂ h, preimage_mono $ hs i i.2 h)
end

lemma Union_univ_pi_of_monotone {ι ι' : Type*} [linear_order ι'] [nonempty ι'] [fintype ι]
  {α : ι → Type*} {s : Π i, ι' → set (α i)} (hs : ∀ i, monotone (s i)) :
  (⋃ j : ι', pi univ (λ i, s i j)) = pi univ (λ i, ⋃ j, s i j) :=
Union_pi_of_monotone (finite.of_fintype _) (λ i _, hs i)

lemma range_find_greatest_subset {P : α → ℕ → Prop} [∀ x, decidable_pred (P x)] {b : ℕ}:
  range (λ x, nat.find_greatest (P x) b) ⊆ ↑(finset.range (b + 1)) :=
by { rw range_subset_iff, intro x, simp [nat.lt_succ_iff, nat.find_greatest_le] }

lemma finite_range_find_greatest {P : α → ℕ → Prop} [∀ x, decidable_pred (P x)] {b : ℕ} :
  (range (λ x, nat.find_greatest (P x) b)).finite :=
(finite_of_fintype ↑(finset.range (b + 1))).subset range_find_greatest_subset

lemma finite.exists_maximal_wrt [partial_order β] (f : α → β) (s : set α) (h : set.finite s) :
  s.nonempty → ∃ a ∈ s, ∀ a' ∈ s, f a ≤ f a' → f a = f a' :=
begin
  classical,
  refine h.induction_on _ _,
  { exact λ h, absurd h empty_not_nonempty },
  intros a s his _ ih _,
  cases s.eq_empty_or_nonempty with h h,
  { use a, simp [h] },
  rcases ih h with ⟨b, hb, ih⟩,
  by_cases f b ≤ f a,
  { refine ⟨a, set.mem_insert _ _, λ c hc hac, le_antisymm hac _⟩,
    rcases set.mem_insert_iff.1 hc with rfl | hcs,
    { refl },
    { rwa [← ih c hcs (le_trans h hac)] } },
  { refine ⟨b, set.mem_insert_of_mem _ hb, λ c hc hbc, _⟩,
    rcases set.mem_insert_iff.1 hc with rfl | hcs,
    { exact (h hbc).elim },
    { exact ih c hcs hbc } }
end

section

variables [semilattice_sup α] [nonempty α] {s : set α}

/--A finite set is bounded above.-/
protected lemma finite.bdd_above (hs : s.finite) : bdd_above s :=
finite.induction_on hs bdd_above_empty $ λ a s _ _ h, h.insert a

/--A finite union of sets which are all bounded above is still bounded above.-/
lemma finite.bdd_above_bUnion {I : set β} {S : β → set α} (H : I.finite) :
  (bdd_above (⋃i∈I, S i)) ↔ (∀i ∈ I, bdd_above (S i)) :=
finite.induction_on H
  (by simp only [bUnion_empty, bdd_above_empty, ball_empty_iff])
  (λ a s ha _ hs, by simp only [bUnion_insert, ball_insert_iff, bdd_above_union, hs])

lemma infinite_of_not_bdd_above : ¬ bdd_above s → s.infinite :=
begin
  contrapose!,
  rw not_infinite,
  apply finite.bdd_above,
end

end

section

variables [semilattice_inf α] [nonempty α] {s : set α}

/--A finite set is bounded below.-/
protected lemma finite.bdd_below (hs : s.finite) : bdd_below s := @finite.bdd_above αᵒᵈ _ _ _ hs

/--A finite union of sets which are all bounded below is still bounded below.-/
lemma finite.bdd_below_bUnion {I : set β} {S : β → set α} (H : I.finite) :
  bdd_below (⋃ i ∈ I, S i) ↔ ∀ i ∈ I, bdd_below (S i) :=
@finite.bdd_above_bUnion αᵒᵈ _ _ _ _ _ H

lemma infinite_of_not_bdd_below : ¬ bdd_below s → s.infinite :=
begin
  contrapose!,
  rw not_infinite,
  apply finite.bdd_below,
end

end

end set

namespace finset

/-- A finset is bounded above. -/
protected lemma bdd_above [semilattice_sup α] [nonempty α] (s : finset α) :
  bdd_above (↑s : set α) :=
(set.finite_of_fintype ↑s).bdd_above

/-- A finset is bounded below. -/
protected lemma bdd_below [semilattice_inf α] [nonempty α] (s : finset α) :
  bdd_below (↑s : set α) :=
(set.finite_of_fintype ↑s).bdd_below

end finset

/--
If a set `s` does not contain any elements between any pair of elements `x, z ∈ s` with `x ≤ z`
(i.e if given `x, y, z ∈ s` such that `x ≤ y ≤ z`, then `y` is either `x` or `z`), then `s` is
finite.
-/
lemma set.finite_of_forall_between_eq_endpoints {α : Type*} [linear_order α] (s : set α)
  (h : ∀ (x ∈ s) (y ∈ s) (z ∈ s), x ≤ y → y ≤ z → x = y ∨ y = z) :
  set.finite s :=
begin
  by_contra hinf,
  change s.infinite at hinf,
  rcases hinf.exists_subset_card_eq 3 with ⟨t, hts, ht⟩,
  let f := t.order_iso_of_fin ht,
  let x := f 0,
  let y := f 1,
  let z := f 2,
  have := h x (hts x.2) y (hts y.2) z (hts z.2)
    (f.monotone $ by dec_trivial) (f.monotone $ by dec_trivial),
  have key₁ : (0 : fin 3) ≠ 1 := by dec_trivial,
  have key₂ : (1 : fin 3) ≠ 2 := by dec_trivial,
  cases this,
  { dsimp only [x, y] at this, exact key₁ (f.injective $ subtype.coe_injective this) },
  { dsimp only [y, z] at this, exact key₂ (f.injective $ subtype.coe_injective this) }
end

/-! ### Finset -/

namespace finset

/-- Gives a `set.finite` for the `finset` coerced to a `set`.
This is a wrapper around `set.finite_of_fintype`. -/
lemma finite_to_set (s : finset α) : (s : set α).finite := set.finite_of_fintype _

@[simp] lemma finite_to_set_to_finset {α : Type*} (s : finset α) :
  s.finite_to_set.to_finset = s :=
by { ext, rw [set.finite.mem_to_finset, mem_coe] }

end finset
