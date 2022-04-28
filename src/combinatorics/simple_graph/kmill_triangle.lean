/-
Copyright (c) 2022 Mathlib contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller, Eric Rodriguez
-/
import .clique
import .degree_sum
import algebra.big_operators
import analysis.inner_product_space.pi_L2

/-! # Main results to go into triangle module

recall that "triangle free" means `G.clique_free 3`
-/

open finset
open_locale big_operators

namespace simple_graph

variables {V : Type*} {G : simple_graph V}

lemma common_neighbors_of_triangle_free (htf : G.clique_free 3)
  {u v : V} (huv : G.adj u v) :
  G.common_neighbors u v = ∅ :=
begin
  classical,
  ext w,
  simp only [mem_common_neighbors, set.mem_empty_eq, iff_false],
  rintro ⟨huw, hvw⟩,
  apply htf {u, v, w},
  simp only [*, is_3_clique_triple_iff, and_self],
end

lemma triangle_free_iff_common_neighbors_eq_empty :
  G.clique_free 3 ↔ ∀ {u v : V}, G.adj u v → G.common_neighbors u v = ∅ :=
begin
  classical,
  refine ⟨common_neighbors_of_triangle_free, _⟩,
  intros h s,
  rw [is_3_clique_iff],
  push_neg,
  rintros u v w huv huw hvw rfl,
  have : w ∈ G.common_neighbors u v := by simp [huw, hvw],
  simpa only [h huv],
end

lemma degree_add_degree_le_of_triangle_free [fintype V]
  (htf : G.clique_free 3)
  {u v : V} (huv : G.adj u v)
  [fintype (G.neighbor_set u)] [fintype (G.neighbor_set v)] :
  G.degree u + G.degree v ≤ fintype.card V :=
begin
  classical,
  convert_to (G.neighbor_set u ∪ G.neighbor_set v).to_finset.card ≤ _,
  { rw [set.to_finset_union, card_union_eq],
    { simp },
    { rw [set.to_finset_disjoint_iff, set.disjoint_iff_inter_eq_empty,
        ← common_neighbors_eq, common_neighbors_of_triangle_free htf huv] } },
  exact card_le_univ _,
end

lemma sum_degree_pow_two_le_of_triangle_free [fintype V]
  [decidable_eq V] [decidable_rel G.adj]
  (htf : G.clique_free 3) :
  ∑ v, G.degree v ^ 2 ≤ G.edge_finset.card * fintype.card V :=
begin
  calc ∑ v, G.degree v ^ 2
        = ∑ v, ∑ e in G.incidence_finset v, G.degree v : _
    ... = ∑ e in G.edge_finset, ∑ v in univ.filter (∈ e), G.degree v : _
    ... ≤ ∑ e in G.edge_finset, fintype.card V : _
    ... = G.edge_finset.card * fintype.card V : _,
  { simp only [pow_two, sum_const, card_incidence_finset_eq_degree,
      nsmul_eq_mul, nat.cast_id], },
  { simp only [sum_filter],
    rw [sum_comm],
    apply sum_congr rfl,
    rintro u -,
    rw [← sum_filter],
    apply sum_congr _ (λ _ _, rfl),
    ext e,
    refine sym2.ind (λ v w, _) e,
    simp [mk_mem_incidence_set_iff], },
  { apply sum_le_sum,
    intros e he,
    rw mem_edge_finset at he,
    refine sym2.ind (λ v w he, _) e he,
    simp only [mem_edge_set] at he,
    simp only [filter_or, eq_comm, filter_eq, sym2.mem_iff, mem_univ, if_true],
    rw [sum_union],
    { simp only [sum_singleton],
      exact degree_add_degree_le_of_triangle_free htf he },
    { simp only [disjoint_singleton, ne.def, he.ne, not_false_iff] } },
  { rw [sum_const, nsmul_eq_mul, nat.cast_id] },
end

-- generalized from proof by Junyan Xu
lemma cauchy_schwarz {α : Type*} [fintype α] (f g : α → ℝ) :
  (∑ x, f x * g x) ^ 2 ≤ (∑ x, f x ^ 2) * (∑ x, g x ^ 2) :=
begin
  change euclidean_space ℝ α at f,
  change euclidean_space ℝ α at g,
  have := @abs_inner_le_norm ℝ _ _ _ f g,
  rw [← abs_norm_eq_norm f, ← abs_norm_eq_norm g, ← abs_mul,
    pi_Lp.inner_apply, is_R_or_C.abs_to_real] at this,
  convert sq_le_sq this using 1,
  rw mul_pow,
  iterate 2 { rw [euclidean_space.norm_eq, real.sq_sqrt] },
  { congr; simp only [is_R_or_C.norm_eq_abs, is_R_or_C.abs_to_real, pow_bit0_abs], },
  iterate 2 { exact finset.sum_nonneg' (λ _, sq_nonneg _) },
end

lemma cauchy_schwarz_nat {α : Type*} [fintype α] (f g : α → ℕ) :
  (∑ x, f x * g x) ^ 2 ≤ (∑ x, f x ^ 2) * (∑ x, g x ^ 2) :=
by exact_mod_cast cauchy_schwarz (λ x, f x) (λ x, g x)

lemma cauchy {α : Type*} [fintype α] (f : α → ℕ) :
  (∑ x, f x) ^ 2 ≤ fintype.card α * ∑ x, f x ^ 2 :=
by simpa using cauchy_schwarz_nat (λ _, 1) f

lemma card_edge_set_le_of_triangle_free [fintype V]
  [decidable_eq V] [decidable_rel G.adj]
  (htf : G.clique_free 3) :
  G.edge_finset.card ≤ fintype.card V ^ 2 / 4 :=
begin
  have := calc (2 * G.edge_finset.card) ^ 2
        = (∑ v, G.degree v) ^ 2 : by rw G.sum_degrees_eq_twice_card_edges
    ... ≤ fintype.card V * (∑ v, G.degree v ^ 2) : cauchy _
    ... ≤ fintype.card V * (G.edge_finset.card * fintype.card V) :
      mul_le_mul (le_refl _) (sum_degree_pow_two_le_of_triangle_free htf) (zero_le _) (zero_le _)
    ... = fintype.card V ^ 2 * G.edge_finset.card : by ring,
  obtain (h : G.edge_finset.card = 0) | h := eq_zero_or_pos,
  { simp [h] },
  { rw [pow_two, ← mul_assoc, mul_le_mul_right h, mul_comm 2, mul_assoc] at this,
    rw [nat.le_div_iff_mul_le _ _ (by norm_num : 0 < 4)],
    exact this },
end

/-- Theorem 2 in Bollobas "Modern Graph Theory" -/
theorem not_triangle_free_of_lt_card_edge_set [fintype V]
  [decidable_eq V] [decidable_rel G.adj]
  (h : fintype.card V ^ 2 / 4 < G.edge_finset.card) : ¬ G.clique_free 3 :=
begin
  classical,
  contrapose! h,
  convert card_edge_set_le_of_triangle_free h,
end

@[simp] lemma two_mul_add_one_div_two (n : ℕ) : (2*n + 1) / 2 = n :=
begin
  rw [nat.add_div two_pos, n.mul_div_cancel_left two_pos],
  norm_num,
end

lemma four_mul_add_one_div_four (n : ℕ) : (4*n + 1) / 4 = n :=
begin
  rw [nat.add_div four_pos, n.mul_div_cancel_left four_pos],
  norm_num,
end

lemma pow_two_div_four_eq (n : ℕ) :
  n ^ 2 / 4 = (n / 2) * ((n + 1) / 2) :=
begin
  obtain ⟨k, rfl | rfl⟩ := nat.even_or_odd' n,
  { norm_num [mul_pow],
    rw pow_two, },
  { simp only [pow_two, add_assoc, two_mul_add_one_div_two, nat.add_div_right, nat.succ_pos',
      nat.mul_div_right],
    simp only [mul_add, add_mul, mul_one, one_mul],
    convert_to (4 * (k * (k + 1)) + 1) / 4 = _,
    { congr' 1,
      ring, },
    rw [four_mul_add_one_div_four], },
end

instance (V W : Type*) [decidable_eq V] [decidable_eq W] :
  decidable_rel (complete_bipartite_graph V W).adj :=
begin
  intros a b,
  obtain (a|a) := a; obtain (b|b) := b; simp; apply_instance,
end

section edge_equiv

open sum

private def to_pair {α β} :
  Π (v w : (α ⊕ β)), (complete_bipartite_graph α β).adj v w → α × β
| (inl a) (inl a') h := by simpa using h
| (inl a) (inr b) h := (a, b)
| (inr b) (inl a) h := (a, b)
| (inr b) (inr b') h := by simpa using h

def complete_bipartite_edge_equiv {V W} : (complete_bipartite_graph V W).edge_set ≃ V × W :=
{ to_fun := λ x',
  begin
    refine quotient.hrec_on x'.1 (λ p hx, to_pair p.1 p.2 hx) _ x'.2,
    rintro ⟨v₁ | w₁, v₂ | w₂⟩ ⟨v₃ | w₃, v₄ | w₄⟩ (⟨_, _⟩ | ⟨_, _⟩); ext1 h;
    simp only [to_pair, heq_iff_eq, eq_self_iff_true,
      mem_edge_set, is_left, is_right, complete_bipartite_graph_adj, coe_sort_tt, coe_sort_ff,
      and_false, false_and, and_self,
      or_false, false_or, or_self, forall_false_left, forall_true_left],
  end,
  inv_fun := λ x, ⟨⟦(sum.inl x.1, sum.inr x.2)⟧, by simp⟩,
  left_inv := λ x',
  begin
    obtain ⟨x, hx⟩ := x',
    refine sym2.ind _ x hx,
    rintro (x | x) (y | y) (⟨⟨⟩, ⟨⟩⟩ | ⟨⟨⟩, ⟨⟩⟩);
    { simp! only [subtype.mk_eq_mk, quotient.eq],
      constructor }
  end,
  right_inv := λ ⟨v, w⟩, rfl }

end edge_equiv

def set.to_finset_equiv {α} {s : set α} [fintype s] : s.to_finset ≃ s :=
equiv.subtype_equiv_prop s.coe_to_finset

-- unused
def edge_set_equiv_edge_finset {α} [fintype α] [decidable_eq α]
  (G : simple_graph α) [decidable_rel G.adj] : G.edge_finset ≃ G.edge_set :=
set.to_finset_equiv

lemma card_edge_finset [fintype V] [fintype G.edge_set] [decidable_eq V] [decidable_rel G.adj] :
  G.edge_finset.card = fintype.card G.edge_set :=
by { rw [edge_finset, set.to_finset_card], congr }

lemma bipartite_num_edges (n : ℕ) :
  (complete_bipartite_graph (fin (n / 2)) (fin ((n + 1) / 2))).edge_finset.card
  = n ^ 2 / 4 :=
begin
  rw card_edge_finset,
  refine eq.trans (fintype.card_congr complete_bipartite_edge_equiv) _,
  simp [pow_two_div_four_eq],
end

/-- Therefore the bound in `simple_graph.not_triangle_free_of_lt_card_edge_set` is strict. -/
lemma bipartite_triangle_free (n : ℕ) :
  (complete_bipartite_graph (fin (n / 2)) (fin ((n + 1) / 2))).clique_free 3 :=
begin
  simp_rw [clique_free, is_3_clique_iff],
  push_neg,
  intros s a b c,
  simp only [complete_bipartite_graph_adj, ne.def],
  obtain (a|a) := a; obtain (b|b) := b; obtain (c|c) := c; simp,
end

end simple_graph
