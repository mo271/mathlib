import number_theory.dirichlet_character_properties
import number_theory.spl_value

lemma units.coe_map_of_dvd {a b : ℕ} (h : a ∣ b) (x : units (zmod b)) :
  is_unit (x : zmod a) :=
begin
  change is_unit ((x : zmod b) : zmod a),
  rw ←zmod.cast_hom_apply (x : zmod b),
  swap 3, { refine zmod.char_p _, },
  swap, { apply h, },
  rw [←ring_hom.coe_monoid_hom, ←units.coe_map],
  apply units.is_unit,
end

lemma is_unit_of_is_coprime {a b : ℕ} (h : a ∣ b) {x : ℕ} (hx : is_coprime (x : ℤ) b) :
  is_unit (x : zmod a) :=
begin
  rw nat.is_coprime_iff_coprime at hx,
  set y := zmod.unit_of_coprime _ hx,
  convert_to is_unit ((y : zmod b) : zmod a),
  { rw ←zmod.cast_nat_cast h x, congr, refine zmod.char_p _, },
    { change is_unit (y : zmod a),
      apply units.coe_map_of_dvd h _, },
end

open dirichlet_character

lemma dirichlet_character.mul_eval_coprime {R : Type*} [comm_monoid_with_zero R]
  {n m : ℕ} [fact (0 < n)] (χ : dirichlet_character R n) (ψ : dirichlet_character R m)
  {a : ℕ} (ha : is_coprime (a : ℤ) ((n * m : ℕ) : ℤ)) :
  asso_dirichlet_character (dirichlet_character.mul χ ψ) a =
  asso_dirichlet_character χ a * (asso_dirichlet_character ψ a) :=
begin
  rw mul,
  have : ((a : zmod (lcm n m)) : zmod (χ.change_level (dvd_lcm_left n m) *
    ψ.change_level (dvd_lcm_right n m)).conductor) = a,
  { rw zmod.cast_nat_cast _ _,
    swap, { refine zmod.char_p _, },
    apply conductor_dvd, },
  rw ← this,
  have dvd : lcm n m ∣ n * m,
  { rw lcm_dvd_iff, refine ⟨(dvd_mul_right _ _), (dvd_mul_left _ _)⟩, },
  rw ←change_level_asso_dirichlet_character_eq' _ (conductor_dvd _) (is_unit_of_is_coprime dvd ha),
  { convert_to asso_dirichlet_character ((χ.change_level (dvd_lcm_left n m) *
      ψ.change_level (dvd_lcm_right n m))) (a : zmod (lcm n m)) = _,
    { delta asso_primitive_character,
      rw ← (factors_through_spec _ (factors_through_conductor (χ.change_level (dvd_lcm_left n m) *
        ψ.change_level (dvd_lcm_right n m)))), },
    rw asso_dirichlet_character_mul,
    rw monoid_hom.mul_apply, congr,
    { rw change_level_asso_dirichlet_character_eq' _ _ (is_unit_of_is_coprime dvd ha),
      { rw zmod.cast_nat_cast (dvd_lcm_left _ _),
        refine zmod.char_p _, }, },
    { rw change_level_asso_dirichlet_character_eq' _ _ (is_unit_of_is_coprime dvd ha),
      { rw zmod.cast_nat_cast (dvd_lcm_right _ _),
        refine zmod.char_p _, }, }, },
end

lemma dirichlet_character.asso_dirichlet_character_eval_mul_sub
  {R : Type*} [monoid_with_zero R] {n : ℕ} (χ : dirichlet_character R n) (k x : ℕ) :
  asso_dirichlet_character χ (k * n - x) = asso_dirichlet_character χ (-1) *
  (asso_dirichlet_character χ x) :=
by { rw [zmod.nat_cast_self, mul_zero, zero_sub, neg_eq_neg_one_mul, monoid_hom.map_mul], }

lemma dirichlet_character.asso_dirichlet_character_eval_mul_sub'
  {R : Type*} [monoid_with_zero R] {n k : ℕ} (χ : dirichlet_character R n) (hk : n ∣ k) (x : ℕ) :
  asso_dirichlet_character χ (k - x) = asso_dirichlet_character χ (-1) *
  (asso_dirichlet_character χ x) :=
by { have : (k : zmod n) = 0,
      { rw [←zmod.nat_cast_mod, nat.mod_eq_zero_of_dvd hk, nat.cast_zero], },
      rw [this, zero_sub, neg_eq_neg_one_mul, monoid_hom.map_mul], }

abbreviation lev {R : Type*} [monoid R] {n : ℕ} (χ : dirichlet_character R n) : ℕ := n

lemma dirichlet_character.lev_mul_dvd {R : Type*} [comm_monoid_with_zero R] {n k : ℕ}
  (χ : dirichlet_character R n) (ψ : dirichlet_character R k) :
  lev (mul χ ψ) ∣ lcm n k := dvd_trans (conductor_dvd _) dvd_rfl

/-lemma dirichlet_character.asso_dirichlet_character_pow {R : Type*} [monoid_with_zero R] {n k : ℕ}
  (χ : dirichlet_character R n) :
  asso_dirichlet_character (χ^k) = (asso_dirichlet_character χ)^k := sorry-/

--lemma zmod.neg_one_eq_sub {n : ℕ} (hn : 0 < n) : ((n - 1 : ℕ) : zmod n) = ((-1 : ℤ) : zmod n) := sorry

lemma dirichlet_character.mul_eval_coprime' {R : Type*} [comm_monoid_with_zero R]
  {n m : ℕ} [fact (0 < n)] [fact (0 < m)] (χ : dirichlet_character R n)
  (ψ : dirichlet_character R m) :
  --{a : ℤ} (ha : is_coprime a ((n * m : ℕ) : ℤ)) :
  asso_dirichlet_character (dirichlet_character.mul χ ψ) (-1 : ℤ) =
  asso_dirichlet_character χ (-1) * (asso_dirichlet_character ψ (-1)) :=
begin
  have lev_dvd : lev (χ.mul ψ) ∣ n * m,
  { apply dvd_trans (conductor_dvd _) (lcm_dvd (dvd_mul_right _ _) (dvd_mul_left _ _)), },
  have one_le : 1 ≤ n * m,
  { rw nat.succ_le_iff, apply nat.mul_pos (fact.out _) (fact.out _),
    any_goals { assumption, }, },
  have f1 : ((-1 : ℤ) : zmod (lev (χ.mul ψ))) = ↑((n * m - 1) : ℕ),
  { rw nat.cast_sub one_le,
    rw ←zmod.nat_coe_zmod_eq_zero_iff_dvd at lev_dvd,
    rw lev_dvd,
    simp only [zero_sub, int.cast_one, nat.cast_one, int.cast_neg], },
  rw f1,
  rw dirichlet_character.mul_eval_coprime,
  have f2 : ((-1 : ℤ) : zmod n) = ↑((n * m - 1) : ℕ),
  { rw nat.cast_sub one_le,
    simp only [zero_sub, int.cast_one, zmod.nat_cast_self, nat.cast_one, nat.cast_mul,
      int.cast_neg, zero_mul], },
  have f3 : ((-1 : ℤ) : zmod m) = ↑((n * m - 1) : ℕ),
  { rw nat.cast_sub one_le,
    simp only [zero_sub, int.cast_one, zmod.nat_cast_self, nat.cast_one, nat.cast_mul,
      int.cast_neg, mul_zero], },
  rw ←f2, rw ←f3, congr, norm_cast, norm_cast,
  { rw nat.is_coprime_iff_coprime,
    by_contradiction,
    obtain ⟨p, h1, h2, h3⟩ := nat.prime.not_coprime_iff_dvd.1 h,
    rw ←zmod.nat_coe_zmod_eq_zero_iff_dvd at h2,
    rw ←zmod.nat_coe_zmod_eq_zero_iff_dvd at h3,
    rw nat.cast_sub _ at h2,
    { rw h3 at h2,
      rw zero_sub at h2,
      rw nat.cast_one at h2,
      rw neg_eq_zero at h2,
      haveI : nontrivial (zmod p), apply zmod.nontrivial _,
      { apply fact_iff.2 (nat.prime.one_lt h1), },
      { apply zero_ne_one h2.symm, }, },
    rw nat.succ_le_iff, apply nat.mul_pos (fact.out _) (fact.out _),
    any_goals { assumption, }, },
end
-- follows for all a : ℤ from this

lemma nat.add_sub_pred (n : ℕ) : n + (n - 1) = 2 * n - 1 :=
begin
  cases n,
  { refl, },
  { rw ←nat.add_sub_assoc (nat.succ_le_succ (nat.zero_le _)), rw nat.succ_mul, rw one_mul, },
end

variables (d p m : nat) [fact (0 < d)] [fact (nat.prime p)]
  {R : Type*} [normed_comm_ring R] (χ : dirichlet_character R (d * p^m))

instance {n : ℕ} : has_pow (dirichlet_character R n) ℕ := monoid.has_pow

lemma teichmuller_character_mod_p_change_level_pow {n : ℕ} (k : ℕ)
  (χ : dirichlet_character R n) (a : units (zmod n)) :
  ((χ: monoid_hom (units (zmod n)) (units R))^k) a = (χ a)^k :=
begin
  exact eq.refl ((χ ^ k) a),
end

lemma teichmuller_character.is_odd_or_is_even :
  (((teichmuller_character p)) (-1 : units (ℤ_[p])) ) = -1 ∨
  (((teichmuller_character p)) (-1 : units (ℤ_[p])) ) = 1 :=
begin
  suffices : ((teichmuller_character p) (-1))^2 = 1,
  { conv_rhs at this { rw ←one_pow 2 },
    rw ←sub_eq_zero at this,
    rw [sq_sub_sq, mul_eq_zero, sub_eq_zero, add_eq_zero_iff_eq_neg] at this,
    cases this,
    { left, rw this, },
    { right,
      simp only [this, units.coe_one], }, },
  { rw [←monoid_hom.map_pow, ←monoid_hom.map_one (teichmuller_character p)],
    congr, rw units.ext_iff,
    simp only [units.coe_one, units.coe_neg_one, nat.neg_one_sq, units.coe_pow], },
end

lemma teichmuller_character_mod_p_eval_neg_one --[no_zero_divisors R] [semi_normed_algebra ℚ_[p] R]
  (hp : 2 < p) : (((teichmuller_character_mod_p p)) (-1) ) = -1 :=
begin
  cases is_odd_or_is_even (teichmuller_character_mod_p p),
  { exact h, },
  { rw [is_even, ←monoid_hom.map_one (teichmuller_character_mod_p p)] at h,
    have := teichmuller_character_mod_p_injective p,
    specialize this h,
    rw [eq_comm, ←units.eq_iff, units.coe_one, units.coe_neg_one, eq_neg_iff_add_eq_zero,
     ←nat.cast_one, ←nat.cast_add, zmod.nat_coe_zmod_eq_zero_iff_dvd,
     nat.dvd_prime (nat.prime_two)] at this,
    exfalso, cases this,
    { apply nat.prime.ne_one (fact.out _) this, },
    { apply ne_of_lt hp this.symm, }, },
end

lemma neg_one_pow_eq_neg_one (hp : 2 < p) : (-1 : units R)^(p - 2) = -1 :=
begin
  rw ←units.eq_iff,
  simp only [units.coe_neg_one, units.coe_pow],
  rw neg_one_pow_eq_pow_mod_two,
  cases nat.prime.eq_two_or_odd _,
  swap 4, { apply fact.out _, assumption, },
  { exfalso, apply ne_of_gt hp h, },
  { have : (p - 2) % 2 = 1,
    { rw [←nat.mod_eq_sub_mod (le_of_lt hp), h], },
    rw [this, pow_one], },
end

example [semi_normed_algebra ℚ_[p] R] [nontrivial R] : function.injective (algebra_map ℚ_[p] R) :=
(algebra_map ℚ_[p] R).injective

lemma teichmuller_character_mod_p_change_level_eval_neg_one
  [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [nontrivial R] (hp : (2 < p))
--  (hinj : function.injective (algebra_map ℚ_[p] R))
  [fact (0 < m)] :
  (((teichmuller_character_mod_p_change_level p d R m)) (-1 : units (zmod (d * p^m))) ) =
  (-1 : units R) :=
begin
  cases is_odd_or_is_even (teichmuller_character_mod_p_change_level p d R m),
  { exact h, },
  { exfalso,
    have := teichmuller_character_mod_p_injective p,
    rw is_even at h,
    delta teichmuller_character_mod_p_change_level at h,
    rw change_level at h,
    simp only [ring_hom.to_monoid_hom_eq_coe, function.comp_app, monoid_hom.coe_comp] at h,
    suffices : ((units.map ↑((algebra_map ℚ_[p] R).comp padic_int.coe.ring_hom)).comp
      (teichmuller_character_mod_p p) ^ (p - 2)) (-1) = 1,
    swap, convert h,
    { rw units.map,
      simp only [one_inv, monoid_hom.mk'_apply, ring_hom.coe_monoid_hom, units.coe_neg_one,
        units.val_eq_coe, units.inv_eq_coe_inv, zmod.cast_hom_apply, units.neg_inv],
      have : ((-1 : zmod (d * p^m)) : zmod p) = -1,
      { rw zmod.cast_neg _,
        swap 3, { apply zmod.char_p _, },
        rw zmod.cast_one _,
        swap, { apply zmod.char_p _, },
        any_goals { apply dvd_mul_of_dvd_right (dvd_pow dvd_rfl
            (ne_zero_of_lt _)) _, exact 0, apply fact.out, }, },
      simp_rw [this], tauto, },
    rw teichmuller_character_mod_p_change_level_pow at this,
    rw monoid_hom.comp_apply at this,
    rw teichmuller_character_mod_p_eval_neg_one p hp at this,
    suffices neg_one_pow : (-1 : units R)^(p - 2) = 1,
    { haveI : char_zero R :=
        (ring_hom.char_zero_iff ((algebra_map ℚ_[p] R).injective)).1 infer_instance,
      apply @nat.cast_add_one_ne_zero R _ _ _ 1,
      rw neg_one_pow_eq_neg_one p hp at neg_one_pow,
      rw ←eq_neg_iff_add_eq_zero, rw nat.cast_one,
      rw ←units.eq_iff at neg_one_pow, rw units.coe_one at neg_one_pow,
      rw units.coe_neg_one at neg_one_pow, rw neg_one_pow, },
    { convert this, rw units.map,
      rw ←units.eq_iff,
      simp, }, },
end
.

lemma teichmuller_character_mod_p_change_level_pow_eval_neg_one
  (k : ℕ) (hp : 2 < p) [semi_normed_algebra ℚ_[p] R] [nontrivial R] [no_zero_divisors R]
  [fact (0 < m)] : ((teichmuller_character_mod_p_change_level p d R m ^ k) is_unit_one.neg.unit) =
  (-1) ^ k :=
begin
  convert_to ((teichmuller_character_mod_p_change_level p d R m) is_unit_one.neg.unit)^k = (-1) ^ k,
  congr',
  convert teichmuller_character_mod_p_change_level_eval_neg_one d p m hp using 1,
  { congr', rw [←units.eq_iff, is_unit.unit_spec],
    simp only [units.coe_neg_one], },
  any_goals { apply_instance, },
end

lemma nat.two_mul_sub_one_mod_two_eq_one {k : ℕ} (hk : 1 ≤ k) : (2 * k - 1) % 2 = 1 :=
begin
  have : 2 * k - 1 = 2 * k + 1 - 2,
  { norm_num, },
  rw this, rw ← nat.mod_eq_sub_mod _,
  { rw ←nat.odd_iff, refine ⟨k, rfl⟩, },
  { apply nat.succ_le_succ (one_le_mul one_le_two hk), },
end

open_locale big_operators
--set_option pp.proofs true
lemma sum_eq_neg_sum_add_dvd (hχ : χ.is_even) [semi_normed_algebra ℚ_[p] R] [nontrivial R]
  [no_zero_divisors R] [fact (0 < m)] (hp : 2 < p) (k : ℕ) (hk : 1 ≤ k) {x : ℕ} (hx : m ≤ x) :
  ∑ (i : ℕ) in finset.range (d * p ^ x).succ, (asso_dirichlet_character (χ.mul
  (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑i * ↑i ^ (k - 1) =
  -1 * ∑ (y : ℕ) in finset.range (d * p ^ x + 1),
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑y *
  ↑y ^ (k - 1) + ↑(d * p ^ x) * ∑ (y : ℕ) in finset.range (d * p ^ x + 1),
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) (-1) *
  ((asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑y *
  ∑ (x_1 : ℕ) in finset.range (k - 1), ↑(d * p ^ x) ^ x_1 * ((-1) * ↑y) ^ (k - 1 - (x_1 + 1)) *
  ↑((k - 1).choose (x_1 + 1))) :=
begin
  have lev_mul_dvd : lev (χ.mul (teichmuller_character_mod_p_change_level
  p d R m ^ k)) ∣ d * p^m,
  { convert dirichlet_character.lev_mul_dvd _ _, rw [lcm_eq_nat_lcm, nat.lcm_self], },
  rw ←finset.sum_flip,
  conv_lhs { apply_congr, skip, rw nat.cast_sub (finset.mem_range_succ_iff.1 H),
    rw dirichlet_character.asso_dirichlet_character_eval_mul_sub' _ (dvd_trans lev_mul_dvd
      (mul_dvd_mul dvd_rfl (pow_dvd_pow _ hx))),
    conv { congr, skip, rw [nat.cast_sub (finset.mem_range_succ_iff.1 H), sub_eq_add_neg,
    add_pow, finset.sum_range_succ', add_comm, pow_zero, one_mul, nat.sub_zero,
    nat.choose_zero_right, nat.cast_one, mul_one, neg_eq_neg_one_mul, mul_pow],
    congr, skip, apply_congr, skip, rw pow_succ, rw mul_assoc ↑(d * p^x) _,
    rw mul_assoc ↑(d * p^x) _, },
    rw [←finset.mul_sum, mul_add, mul_mul_mul_comm, mul_mul_mul_comm _ _ ↑(d * p^x) _,
      mul_comm _ ↑(d * p^x), mul_assoc ↑(d * p^x) _ _], },
  rw finset.sum_add_distrib, rw ←finset.mul_sum, rw ←finset.mul_sum,
  apply congr_arg2 _ (congr_arg2 _ _ _) rfl,
--  apply congr_arg2 _ (congr_arg2 _ _ rfl) rfl,
  { rw ←int.cast_one, rw ←int.cast_neg,
  --rw ←zmod.neg_one_eq_sub _,
    rw dirichlet_character.mul_eval_coprime' _ _,
  --  rw zmod.neg_one_eq_sub _,
    --rw int.cast_neg, rw int.cast_one,
    rw asso_even_dirichlet_character_eval_neg_one _ hχ, rw one_mul,
    rw asso_dirichlet_character_eq_char' _ (is_unit.neg (is_unit_one)),
    convert_to (-1 : R)^k * (-1)^(k -1) = -1,
    { apply congr_arg2 _ _ rfl,
      rw teichmuller_character_mod_p_change_level_pow_eval_neg_one d p m k hp,
      simp only [units.coe_neg_one, units.coe_pow],
      any_goals { apply_instance, }, },
    { rw ←pow_add, rw nat.add_sub_pred, rw nat.neg_one_pow_of_odd _, rw nat.odd_iff,
      rw nat.two_mul_sub_one_mod_two_eq_one hk, },
    any_goals { apply fact_iff.2 (mul_prime_pow_pos p d m), }, },
  { rw ←finset.sum_flip, },
end

lemma nat.pow_eq_mul_pow_sub (k : ℕ) (hk : 1 < k) :
  (d * p^m)^(k - 1) = (d * p^m) * (d * p^m)^(k - 2) :=
begin
  conv_rhs { congr, rw ←pow_one (d * p^m), },
  rw ←pow_add, congr, rw add_comm,
  conv_rhs { rw nat.sub_succ, rw ←nat.succ_eq_add_one,
    rw nat.succ_pred_eq_of_pos (nat.lt_sub_right_iff_add_lt.2 _), skip,
    apply_congr hk, },
end

lemma asso_dc [semi_normed_algebra ℚ_[p] R] [fact (0 < m)] (k : ℕ)
  (hχ : χ.change_level (dvd_lcm_left _ _) *
    (teichmuller_character_mod_p_change_level p d R m ^ k).change_level (dvd_lcm_right _ _) ≠ 1) :
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)))
  ↑(d * p ^ m) = 0 :=
begin
  have dvd : lev (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)) ∣ d * p^m,
  { convert dirichlet_character.lev_mul_dvd _ _,
    rw lcm_eq_nat_lcm, rw nat.lcm_self, },
  rw ←zmod.nat_coe_zmod_eq_zero_iff_dvd at dvd,
  rw dvd,
  rw asso_dirichlet_character_eq_zero _,
  simp only [is_unit_zero_iff],
  convert zero_ne_one,
  apply zmod.nontrivial _,
  apply fact_iff.2 _,
  rw nat.one_lt_iff_ne_zero_and_ne_one,
  refine ⟨λ h, _, λ h, _⟩,
  { rw conductor_eq_zero_iff_level_eq_zero at h, rw lcm_eq_nat_lcm at h,
    rw nat.lcm_self at h, apply ne_zero_of_lt (mul_prime_pow_pos p d m) h, },
  { rw ← conductor_eq_one_iff _ at h,
    apply hχ h,
    rw lcm_eq_nat_lcm, rw nat.lcm_self, apply (mul_prime_pow_pos p d m), },
end

--instance {R : Type*} [normed_comm_ring R] [semi_normed_algebra ℚ_[p] R] : norm_one_class R :=
--by {fconstructor, convert normed_algebra.norm_one ℚ_[p] R, }

example {R : Type*} [comm_ring R] {a b c : R} : a * (b * c) = b * (a * c) := by refine mul_left_comm a b c

lemma norm_sum_le_smul {k : ℕ} [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) {x : ℕ} (hx : m ≤ x) :
  ∥∑ (y : ℕ) in finset.range (d * p ^ x + 1), (asso_dirichlet_character
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ((-1) * ↑y) *
  ∑ (x_1 : ℕ) in finset.range (k - 1), ↑(d * p ^ x) ^ x_1 * ((-1) * ↑y) ^ (k - 1 - (x_1 + 1)) *
  ↑((k - 1).choose (x_1 + 1))∥ ≤ --(d * p ^ x + 1) •
    (dirichlet_character.bound
    (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)) * (k - 1)) :=
begin
  have : ∀ y ∈ finset.range (d * p ^ x + 1),
  ∥(asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)))
    ((-1) * ↑y) * ∑ (x_1 : ℕ) in finset.range (k - 1), ↑(d * p ^ x) ^ x_1 * ((-1) * ↑y) ^
    (k - 1 - (x_1 + 1)) * ↑((k - 1).choose (x_1 + 1)) ∥ ≤ (dirichlet_character.bound
    (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) * (k - 1),
  { intros l hl,
    apply le_trans (norm_mul_le _ _) _,
    --rw ← mul_one ((χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound),
    apply mul_le_mul (le_of_lt (dirichlet_character.lt_bound _ _)) _ (norm_nonneg _)
      (le_of_lt (dirichlet_character.bound_pos _)),
    { simp_rw [mul_pow], simp_rw [mul_left_comm], simp_rw [mul_assoc],
      apply le_trans (norm_sum_le _ _) _,
      have : ∀ a ∈ finset.range (k - 1), ∥(-1 : R) ^ (k - 1 - (a + 1)) * (↑(d * p ^ x) ^ a *
        (↑l ^ (k - 1 - (a + 1)) * ↑((k - 1).choose (a + 1))))∥ ≤ 1,
      { intros a ha,
        apply le_trans (norm_mul_le _ _) _,
        have : (((d * p ^ x) ^ a * (l ^ (k - 1 - (a + 1)) * (k - 1).choose (a + 1)) : ℕ) : R) =
          (algebra_map ℚ_[p] R) (padic_int.coe.ring_hom ((d * p ^ x) ^ a *
          (l ^ (k - 1 - (a + 1)) * (k - 1).choose (a + 1)) : ℤ_[p])),
        { simp only [ring_hom.map_nat_cast, ring_hom.map_pow, nat.cast_mul, nat.cast_pow,
            ring_hom.map_mul], },
        cases neg_one_pow_eq_or R (k - 1 - (a + 1)),
        { rw h, rw normed_algebra.norm_one ℚ_[p] R, rw one_mul,
          rw ← nat.cast_pow, rw ← nat.cast_pow, rw ← nat.cast_mul, rw ← nat.cast_mul,
          rw this, rw norm_algebra_map_eq, apply padic_int.norm_le_one, },
        { rw h, rw norm_neg, rw normed_algebra.norm_one ℚ_[p] R, rw one_mul,
          rw ← nat.cast_pow, rw ← nat.cast_pow, rw ← nat.cast_mul, rw ← nat.cast_mul,
          rw this, rw norm_algebra_map_eq, apply padic_int.norm_le_one, }, },
      { convert le_trans (finset.sum_le_sum this) _,
        rw finset.sum_const, rw finset.card_range, rw nat.smul_one_eq_coe,
        rw nat.cast_sub (le_of_lt hk), rw nat.cast_one, }, }, },
  { apply le_trans (na _ _) _,
    apply cSup_le _ (λ b hb, _),
    { apply set.range_nonempty _, simp only [nonempty_of_inhabited], },
    { cases hb with y hy,
      simp only at hy,
      rw ← hy,
      apply this y.val _,
      rw finset.mem_range,
      apply zmod.val_lt _, apply fact_iff.2 (nat.succ_pos _), }, },
/-    rw (csupr_le_iff' _),
    convert le_trans ((csupr_le_iff' _).2 this) _,
    apply le_trans (norm_sum_le _ _) _,
    convert le_trans (finset.sum_le_sum this) _,
    rw finset.sum_const,
    rw finset.card_range, }, -/
end

instance wut [nontrivial R] [semi_normed_algebra ℚ_[p] R] : char_zero R :=
(ring_hom.char_zero_iff ((algebra_map ℚ_[p] R).injective)).1 infer_instance

lemma sum_odd_char [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R]
  --[fact (0 < n)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) {x : ℕ} (hx : m ≤ x) :
  ∃ y, (2 : R) * ∑ i in finset.range (d * p^x), ((asso_dirichlet_character (dirichlet_character.mul χ
    ((teichmuller_character_mod_p_change_level p d R m)^k))) i * i^(k - 1)) =
    ↑(d * p^x) * y ∧ ∥y∥ ≤ --(d * p ^ x + 1) •
    ((χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k)).bound * (↑k - 1)) +
    ∥(((d * p ^ x : ℕ) : R) ^ (k - 2)) * (1 + 1)∥ * (χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k)).bound :=
begin
  have f1 : ∑ (i : ℕ) in finset.range (d * p ^ x),
    (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R
    m ^ k))) ↑i * ↑i ^ (k - 1) =
  ∑ (i : ℕ) in finset.range (d * p ^ x).succ, (asso_dirichlet_character
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑i * ↑i ^ (k - 1)
   - ((asso_dirichlet_character
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(d * p^x) *
  ↑(d * p^x) ^ (k - 1)),
  { rw [finset.sum_range_succ, add_sub_cancel], },
  rw f1,
  clear f1,
  rw mul_sub, rw mul_comm _ (↑(d * p ^ x) ^ (k - 1)),
  rw ←mul_assoc _ (↑(d * p ^ x) ^ (k - 1)) _, rw mul_comm _ (↑(d * p ^ x) ^ (k - 1)),
  rw mul_assoc _ (2 : R) _, rw ←nat.cast_pow,
  conv { congr, funext, rw sub_eq_iff_eq_add, rw nat.pow_eq_mul_pow_sub d p x k hk,
    rw nat.cast_mul (d * p^x) _, rw mul_assoc ↑(d * p^x) _ _,
    conv { congr, rw ←mul_add ↑(d * p^x) _ _, }, },
  have two_eq_one_add_one : (2 : R) = (1 : R) + (1 : R) := rfl,
  rw two_eq_one_add_one, rw add_mul, rw one_mul,
  conv { congr, funext, conv { congr, to_lhs, congr, skip,
    rw sum_eq_neg_sum_add_dvd d p m _ hχ hp k (le_of_lt hk) hx, }, },
  rw ←neg_eq_neg_one_mul, rw ←add_assoc, rw ←sub_eq_add_neg,
  conv { congr, funext, rw sub_self _, rw zero_add, },
  refine ⟨_, _, _⟩,
  { exact ∑ (y : ℕ) in finset.range (d * p ^ x + 1),
    (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) (-1) *
    ((asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑y *
    ∑ (x_1 : ℕ) in finset.range (k - 1),
    ↑(d * p ^ x) ^ x_1 * ((-1) * ↑y) ^ (k - 1 - (x_1 + 1)) * ↑((k - 1).choose (x_1 + 1))) -
    ↑((d * p ^ x) ^ (k - 2)) * ((1 + 1) * (asso_dirichlet_character (χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(d * p ^ x)), },
  { rw sub_add_cancel, },
  { apply le_trans (norm_sub_le _ _) _,
    conv { congr, congr, congr, apply_congr, skip, rw ← mul_assoc, rw ←monoid_hom.map_mul, },
    apply le_trans (add_le_add (norm_sum_le_smul d p m _ na hk hχ hp hx) (le_refl _)) _,
    rw ← mul_assoc,
    apply le_trans (add_le_add (le_refl _) (norm_mul_le _ _)) _,
    apply le_trans (add_le_add (le_refl _) ((mul_le_mul_left _).2
      (le_of_lt (dirichlet_character.lt_bound _ _)))) _,
    { rw lt_iff_le_and_ne,
      refine ⟨norm_nonneg _, λ h, _⟩,
      rw eq_comm at h, rw norm_eq_zero at h,
      rw mul_eq_zero at h, cases h,
      { rw nat.cast_eq_zero at h, apply pow_ne_zero _ _ h,
        apply ne_zero_of_lt (mul_prime_pow_pos p d _), },
      { rw ← eq_neg_iff_add_eq_zero at h,
        apply zero_ne_one (eq_zero_of_eq_neg R h).symm, }, },
    { rw nat.cast_pow, }, },
end

lemma two_mul_eq_inv_two_smul [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R]
  (a b : R) (h : (2 : R) * a = b) : a = (2 : ℚ_[p])⁻¹ • b :=
begin
  symmetry,
  rw inv_smul_eq_iff' _,
  { rw ← h,
    convert_to _ = ((algebra_map ℚ_[p] R) 2) * a,
    { rw [algebra.algebra_map_eq_smul_one, smul_mul_assoc, one_mul], },
    simp only [h, ring_hom.map_bit0, ring_hom.map_one], },
  { apply two_ne_zero', },
end

lemma coe_eq_ring_hom_map [semi_normed_algebra ℚ_[p] R] (y : ℕ) :
  (algebra_map ℚ_[p] R) (padic_int.coe.ring_hom (y : ℤ_[p])) = ((y : ℕ) : R) :=
by { simp }

lemma norm_coe_eq_ring_hom_map [semi_normed_algebra ℚ_[p] R] (y : ℕ) :
  ∥((y : ℕ) : R)∥ = ∥padic_int.coe.ring_hom (y : ℤ_[p])∥ :=
by { rw [← coe_eq_ring_hom_map p, norm_algebra_map_eq], }

lemma norm_mul_pow_le_one_div_pow [semi_normed_algebra ℚ_[p] R] (y : ℕ) :
  ∥((d * p^y : ℕ) : R)∥ ≤ 1 / p^y :=
begin
  rw nat.cast_mul,
  apply le_trans (norm_mul_le _ _) _,
  rw ← one_mul (1 / (p : ℝ)^y),
  apply mul_le_mul _ _ (norm_nonneg _) zero_le_one,
  { rw norm_coe_eq_ring_hom_map p, apply padic_int.norm_le_one, apply_instance, },
  { --simp, rw padic_int.norm_int_le_pow_iff_dvd,
    apply le_of_eq, rw norm_coe_eq_ring_hom_map p,
    simp only [one_div, ring_hom.map_nat_cast, normed_field.norm_pow, ring_hom.map_pow, inv_pow',
      nat.cast_pow, padic_norm_e.norm_p],
    apply_instance, },
end

lemma norm_mul_two_le_one {k : ℕ} [semi_normed_algebra ℚ_[p] R] (hk : 1 < k) (hp : 2 < p)
  (y : ℕ) : ∥((d * p ^ y : ℕ) : R) ^ (k - 2) * (1 + 1)∥ ≤ 1 :=
begin
  rw ← nat.cast_pow,
  have : (((d * p ^ y) ^ (k - 2) : ℕ) : R) * (1 + 1 : R) = (algebra_map ℚ_[p] R)
     (padic_int.coe.ring_hom (((d * p ^ y) ^ (k - 2) : ℤ_[p]) * (2 : ℤ_[p]))),
  { symmetry,
    simp only [ring_hom.map_nat_cast, ring_hom.map_bit0, ring_hom.map_pow, ring_hom.map_one,
      nat.cast_mul, nat.cast_pow, ring_hom.map_mul],
    refl, },
  rw [this], rw norm_algebra_map_eq,
  apply padic_int.norm_le_one _,
end

lemma sub_add_norm_nonneg {k : ℕ} [semi_normed_algebra ℚ_[p] R] (hk : 1 < k) (y : ℕ) :
  0 ≤ (k : ℝ) - 1 + ∥((d * p ^ y : ℕ) : R) ^ (k - 2) * (1 + 1)∥ :=
begin
  apply add_nonneg _ (norm_nonneg _),
  rw [le_sub_iff_add_le, zero_add], norm_cast,
  apply le_of_lt hk,
end

lemma norm_two_mul_le {k : ℕ} [semi_normed_algebra ℚ_[p] R] (hk : 1 < k) (hp : 2 < p) (y : ℕ) :
  ∥(2⁻¹ : ℚ_[p])∥ * (↑k - 1 + ∥((d * p ^ y : ℕ) : R) ^ (k - 2) * (1 + 1)∥) ≤ k :=
begin
  rw ← one_mul ↑k, apply mul_le_mul,
  { apply le_of_eq, rw normed_field.norm_inv,
    rw inv_eq_one',
    have : ((2 : ℕ) : ℚ_[p]) = (2 : ℚ_[p]), norm_cast,
    rw ← this, rw ← rat.cast_coe_nat,
    rw padic_norm_e.eq_padic_norm,
    rw padic_norm.padic_norm_of_prime_of_ne (λ h, _),
    { rw rat.cast_one, },
    { assumption, },
    { apply nat.prime.fact, },
    { apply ne_of_gt _,
      apply h, apply_instance,
      apply hp, }, },
  { rw one_mul,
    apply le_trans (add_le_add le_rfl (norm_mul_two_le_one d p hk hp _)) _,
    { apply_instance, }, --why is this a problem?
    rw sub_add_cancel, },
  { rw one_mul, convert sub_add_norm_nonneg d p hk y,
    { apply_instance, }, },
  { linarith, },
end

lemma exists_mul_mul_mul_lt {k : ℕ} (ε : ℝ)
  (χ : dirichlet_character R (d * p ^ m)) [nontrivial R] [no_zero_divisors R]
  [semi_normed_algebra ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (hε : ε > 0) :  ∃ x : ℕ,
  ∥(2⁻¹ : ℚ_[p])∥ * (↑k - 1 + ∥((d * p ^ x : ℕ) : R) ^ (k - 2) * (1 + 1)∥) *
  (∥(((d * p ^ x) : ℕ) : R)∥ * (χ.mul
  (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) < ε :=
begin
  have one_div_lt_one : 1 / (p : ℝ) < 1,
  { rw one_div_lt _ _,
    { rw one_div_one, norm_cast, apply nat.prime.one_lt, apply fact.out, },
    { norm_cast, apply nat.prime.pos, apply fact.out, },
    { norm_num, }, },
  have pos' : 0 < ↑k * (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound,
  { apply mul_pos _ (dirichlet_character.bound_pos _), norm_cast,
    apply lt_trans zero_lt_one hk, },
  have pos : 0 < ε / (↑k * (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound),
  { apply div_pos hε pos', },
  refine ⟨classical.some (exists_pow_lt_of_lt_one pos one_div_lt_one), _⟩,
  apply lt_of_le_of_lt (mul_le_mul (norm_two_mul_le d p hk hp _) le_rfl (mul_nonneg (norm_nonneg _)
    (le_of_lt (dirichlet_character.bound_pos _))) (nat.cast_nonneg _)) _,
  { apply_instance, },
  rw mul_left_comm,
  apply lt_of_le_of_lt (mul_le_mul (norm_mul_pow_le_one_div_pow d p _) le_rfl (le_of_lt pos') _) _,
  { apply_instance, },
  { rw ← one_div_pow, apply pow_nonneg _ _,
    apply div_nonneg _ _,
    any_goals { norm_cast, apply nat.zero_le _, }, },
  { rw ← one_div_pow,
    have := classical.some_spec (exists_pow_lt_of_lt_one pos one_div_lt_one),
    apply lt_of_lt_of_le (mul_lt_mul this le_rfl pos' (div_nonneg (le_of_lt hε) (le_of_lt pos'))) _,
    rw div_mul_eq_mul_div, rw mul_div_assoc, rw div_self (λ h, _),
    { rw mul_one, },
    { rw mul_eq_zero at h, cases h,
      { norm_cast at h, rw h at hk, simp only [not_lt_zero'] at hk, apply hk, },
      { have := (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound_pos,
        rw h at this,
        simp only [lt_self_iff_false] at this,
        exact this, }, }, },
end

lemma norm_mul_eq [semi_normed_algebra ℚ_[p] R] (x y : ℕ) :
  ∥(x * y : R)∥ = ∥(x : R)∥ * ∥(y : R)∥ :=
begin
  rw ← nat.cast_mul, rw norm_coe_eq_ring_hom_map p,
  rw nat.cast_mul, rw ring_hom.map_mul,
  rw padic_norm_e.mul,
  rw ← norm_coe_eq_ring_hom_map p, rw ← norm_coe_eq_ring_hom_map p,
  any_goals { apply_instance, },
end

lemma norm_pow_eq [semi_normed_algebra ℚ_[p] R] (x n : ℕ) :
  ∥(x ^ n : R)∥ = ∥(x : R)∥^n :=
begin
  rw ← nat.cast_pow, rw norm_coe_eq_ring_hom_map p,
  rw nat.cast_pow, rw ring_hom.map_pow, rw normed_field.norm_pow,
  rw ← norm_coe_eq_ring_hom_map p,
  any_goals { apply_instance, },
end

lemma norm_le_of_ge [semi_normed_algebra ℚ_[p] R] {x y : ℕ} (h : x ≤ y) :
  ∥((d * p^y : ℕ) : R)∥ ≤ ∥((d * p^x : ℕ) : R)∥ :=
begin
  repeat { rw nat.cast_mul, rw norm_mul_eq p, },
  { apply mul_le_mul le_rfl _ (norm_nonneg _) (norm_nonneg _),
    rw norm_coe_eq_ring_hom_map p, rw norm_coe_eq_ring_hom_map p,
    simp only [ring_hom.map_nat_cast, normed_field.norm_pow, ring_hom.map_pow, inv_pow',
      nat.cast_pow, padic_norm_e.norm_p],
    rw inv_le_inv _ _,
    apply pow_le_pow _ h,
    { norm_cast, apply le_of_lt (nat.prime.one_lt _), apply fact.out, },
    any_goals { norm_cast, apply pow_pos _ _, apply nat.prime.pos _, apply fact.out, },
    any_goals { apply_instance, }, },
  any_goals { apply_instance, },
end
.
lemma sum_even_character [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R]
 --(n : ℕ) --[fact (0 < n)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) :
  filter.tendsto (λ n, ∑ i in finset.range (d * p^n), ((asso_dirichlet_character
  (dirichlet_character.mul χ ((teichmuller_character_mod_p_change_level p d R m)^k)))
  i * i^(k - 1)) ) (@filter.at_top ℕ _) (nhds 0) :=
begin
  rw metric.tendsto_at_top,
  intros ε hε,
  obtain ⟨z, hz⟩ := exists_mul_mul_mul_lt d p m ε χ na hk hχ hp hε,
  refine ⟨max z m, λ x hx, _⟩,
  rw dist_eq_norm, rw sub_zero,
  cases sum_odd_char d p m χ na hk hχ hp _,
  swap 2, exact x,
  { --rw ← smul_eq_mul at h, rw smul_eq_iff_eq_inv_smul at h,
    --rw mul_comm at h, rw eq_comm at h,
    rw two_mul_eq_inv_two_smul p _ _ h.1, rw norm_smul,
    apply lt_of_le_of_lt (mul_le_mul le_rfl (norm_mul_le _ _)
      (norm_nonneg (↑(d * p ^ x) * w)) (norm_nonneg _)) _,
    rw ← mul_assoc,
    apply lt_of_le_of_lt (mul_le_mul le_rfl h.2 (norm_nonneg _) (mul_nonneg (norm_nonneg _)
      (norm_nonneg _))) _, --rw nsmul_eq_mul,
    rw mul_comm _ (k - 1 : ℝ), --rw ← mul_assoc _ (k - 1 : ℝ) _,
    rw ← add_mul, rw mul_mul_mul_comm,
    apply lt_of_le_of_lt _ hz,
    apply mul_le_mul _ _ (mul_nonneg (norm_nonneg _)
      (le_of_lt (dirichlet_character.bound_pos _))) _,
    { apply mul_le_mul le_rfl _ _ (norm_nonneg _),
      { apply add_le_add le_rfl _,
        { exact covariant_swap_add_le_of_covariant_add_le ℝ, },
        { exact ordered_add_comm_monoid.to_covariant_class_left ℝ, },
        { have : ((2 : ℕ) : R) = 1 + 1,
          { simp only [nat.cast_bit0, nat.cast_one], refl, },
          rw ← this, repeat { rw ← nat.cast_pow, rw norm_mul_eq p, }, --rw norm_mul_eq p,
          { apply mul_le_mul _ le_rfl (norm_nonneg _) (norm_nonneg _),
            repeat { rw nat.cast_pow, rw norm_pow_eq p, },
            any_goals { apply_instance, },
            apply pow_le_pow_of_le_left (norm_nonneg _) _ _,
            { apply norm_le_of_ge d p (le_trans (le_max_left _ _) hx), apply_instance, }, },
          any_goals { apply_instance, }, }, },
      { apply sub_add_norm_nonneg, assumption, }, },
    { apply mul_le_mul _ le_rfl (le_of_lt (dirichlet_character.bound_pos _)) (norm_nonneg _),
      { apply norm_le_of_ge d p (le_trans (le_max_left _ _) hx), apply_instance, }, },
    { apply mul_nonneg (norm_nonneg _) _,
      apply sub_add_norm_nonneg, assumption, }, },
  { apply le_trans (le_max_right _ _) hx, },
end
-- btw, this still works without the na condition, since in the end, we divide by d*p^x

lemma dirichlet_character.lev_mul_dvd' {B : Type*} [comm_monoid_with_zero B] {n : ℕ}
  (χ ψ : dirichlet_character B n) : lev (mul χ ψ) ∣ n :=
begin
  apply dvd_trans (dirichlet_character.lev_mul_dvd _ _) _,
  rw [lcm_eq_nat_lcm, nat.lcm_self],
end

lemma nat.sub_one_le (n : ℕ) : n - 1 ≤ n := nat.sub_le n 1

example : group ℚ := multiplicative.group

lemma aux_one [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x y : ℕ) : (algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ k) * (algebra_map ℚ R)
  (polynomial.eval (↑(y.succ) / ↑(d * p ^ x : ℕ)) (bernoulli_poly k)) =
  ((y + 1 : ℕ) : R)^k + ((algebra_map ℚ R) (bernoulli 1 * (k : ℚ))) * ((d * p^x : ℕ) : R) *
  ((y + 1 : ℕ) : R)^k.pred + (d * p^x : ℕ) * (∑ (x_1 : ℕ) in finset.range k.pred,
  (algebra_map ℚ R) (bernoulli (k.pred.succ - x_1) * ↑(k.pred.succ.choose x_1) *
  (((y + 1 : ℕ) : ℚ) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ k.pred)) :=
begin
--  conv_lhs { congr, rw ← ring_hom.to_fun_eq_coe, congr, },
  rw ← (algebra_map ℚ R).map_mul,
  rw bernoulli_poly_def,
  rw polynomial.eval_finset_sum,
  rw finset.mul_sum,
  simp only [polynomial.eval_monomial, div_pow, nat.cast_succ],
--    conv_lhs { rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _], apply_congr, },
  simp_rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _],
  simp_rw [mul_assoc],
  rw finset.sum_range_succ_comm,
  rw div_mul_cancel _,
  { rw (algebra_map ℚ R).map_add,
    conv_lhs { congr, skip, rw ← nat.succ_pred_eq_of_pos (pos_of_gt hk),
      rw finset.sum_range_succ_comm, },
    rw div_mul_comm',
    rw (algebra_map ℚ R).map_add, rw add_assoc,
    congr,
    { simp only [nat.choose_self, ring_hom.map_nat_cast, one_mul, ring_hom.map_add, nat.sub_self,
        bernoulli_zero, ring_hom.map_pow, ring_hom.map_one, nat.cast_one], },
    { rw nat.choose_succ_self_right, rw ← nat.succ_eq_add_one,
      rw nat.succ_pred_eq_of_pos (pos_of_gt hk),
      rw nat.pred_eq_sub_one, rw div_eq_mul_inv,
      rw ← pow_sub' ((d * p^x : ℕ) : ℚ) _ (nat.sub_le k 1),
      { rw nat.sub_sub_self (le_of_lt hk),
        rw pow_one, rw ← mul_assoc, rw (algebra_map ℚ R).map_mul,
        simp only [ring_hom.map_nat_cast, ring_hom.map_add, ring_hom.map_pow, ring_hom.map_one,
          ring_hom.map_mul], },
      { norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), }, },
    { rw ring_hom.map_sum, rw pow_succ',
      conv_lhs { apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, rw ← mul_assoc,
        rw (algebra_map ℚ R).map_mul, },
      rw ← finset.sum_mul, rw mul_comm, rw ring_hom.map_nat_cast,
      conv_rhs { congr, skip, apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, }, }, },
  { norm_cast, apply pow_ne_zero _ (ne_zero_of_lt (mul_prime_pow_pos p d x)), },
end

lemma norm_mul_pow_pos [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] (x : ℕ) : 0 < ∥((d * p^x : ℕ) : R)∥ :=
begin
  rw norm_pos_iff, norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x),
end

/-lemma exists_just [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x y : ℕ) : ∃ z,
  (algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ k) * (algebra_map ℚ R)
  (polynomial.eval (↑(y.succ) / ↑(d * p ^ x : ℕ)) (bernoulli_poly k)) =
  ((y + 1 : ℕ) : R)^k + ((algebra_map ℚ R) (bernoulli 1 * (k : ℚ))) * ((d * p^x : ℕ) : R) *
  ((y + 1 : ℕ) : R)^k.pred + (d * p^x : ℕ) * z ∧ ∥z∥ ≤ ∥((d * p^x : ℕ) : R)∥ *
  ⨆ (x_1 : zmod k.pred), ∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) *
  ↑(k.pred.succ.choose x_1.val) * ( ↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥ :=
begin
  refine ⟨∑ (x_1 : ℕ) in finset.range k.pred, (algebra_map ℚ R) (bernoulli (k.pred.succ - x_1) *
    ↑(k.pred.succ.choose x_1) * ((↑y + 1) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ k.pred),
    _, _⟩,
  { rw ← (algebra_map ℚ R).map_mul,
    rw bernoulli_poly_def,
    rw polynomial.eval_finset_sum,
    rw finset.mul_sum,
    simp only [polynomial.eval_monomial, div_pow, nat.cast_succ],
--    conv_lhs { rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _], apply_congr, },
    simp_rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _],
    simp_rw [mul_assoc],
    rw finset.sum_range_succ_comm,
    rw div_mul_cancel _,
    { rw (algebra_map ℚ R).map_add,
      conv_lhs { congr, skip, rw ← nat.succ_pred_eq_of_pos (pos_of_gt hk),
        rw finset.sum_range_succ_comm, },
      rw div_mul_comm',
      rw (algebra_map ℚ R).map_add, rw add_assoc,
      congr,
      { simp only [nat.choose_self, ring_hom.map_nat_cast, one_mul, ring_hom.map_add, nat.sub_self,
          bernoulli_zero, ring_hom.map_pow, ring_hom.map_one, nat.cast_one], },
      { rw nat.choose_succ_self_right, rw ← nat.succ_eq_add_one,
        rw nat.succ_pred_eq_of_pos (pos_of_gt hk),
        rw nat.pred_eq_sub_one, rw div_eq_mul_inv,
        rw ← pow_sub' ((d * p^x : ℕ) : ℚ) _ (nat.sub_le k 1),
        { rw nat.sub_sub_self (le_of_lt hk),
          rw pow_one, rw ← mul_assoc, rw (algebra_map ℚ R).map_mul,
          simp only [ring_hom.map_nat_cast, ring_hom.map_add, ring_hom.map_pow, ring_hom.map_one,
            ring_hom.map_mul], },
        { norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), }, },
      { rw ring_hom.map_sum, rw pow_succ',
        conv_lhs { apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, rw ← mul_assoc,
          rw (algebra_map ℚ R).map_mul, },
        rw ← finset.sum_mul, rw mul_comm, rw ring_hom.map_nat_cast,
        conv_rhs { congr, skip, apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, }, }, },
    { norm_cast, apply pow_ne_zero _ (ne_zero_of_lt (mul_prime_pow_pos p d x)), }, },
  -- { refine ⟨∥∑ (x_1 : ℕ) in finset.range k.pred, (algebra_map ℚ R)
  --     (bernoulli (k.pred.succ - x_1) * ↑(k.pred.succ.choose x_1) *
  --     ((↑y + 1) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ (k.pred - 1))∥, _⟩,
  { have le : k.pred = k.pred - 1 + 1,
    { rw nat.sub_add_cancel _, rw nat.pred_eq_sub_one, apply nat.le_pred_of_lt hk, },
    apply le_trans (na _ _) _,
    --apply le_trans _ (norm_mul_le _ _),
    apply csupr_le (λ z, _),
    { apply_instance, },

    conv { congr, congr,
      conv { apply_congr, skip, rw le, rw pow_add, rw pow_one, rw ← mul_assoc,
        rw (algebra_map ℚ R).map_mul, },
      rw [← finset.sum_mul], },
    rw mul_comm, --rw ring_hom.map_nat_cast,
    apply le_trans (norm_mul_le _ _) _,
    convert le_rfl,
    { rw ring_hom.map_nat_cast, },
    { rw ← le, }, },
end

lemma exists_just [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x y : ℕ) : ∃ z,
  (algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ k) * (algebra_map ℚ R)
  (polynomial.eval (↑(y.succ) / ↑(d * p ^ x : ℕ)) (bernoulli_poly k)) =
  ((y + 1 : ℕ) : R)^k + ((algebra_map ℚ R) (bernoulli 1 * (k : ℚ))) * ((d * p^x : ℕ) : R) *
  ((y + 1 : ℕ) : R)^k.pred + (d * p^x : ℕ) * z ∧ ∃ M : ℝ, ∥z∥ ≤ ∥((d * p^x : ℕ) : R)∥ * M :=
begin
  refine ⟨∑ (x_1 : ℕ) in finset.range k.pred, (algebra_map ℚ R) (bernoulli (k.pred.succ - x_1) *
    ↑(k.pred.succ.choose x_1) * ((↑y + 1) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ k.pred),
    _, _⟩,
  { rw ← (algebra_map ℚ R).map_mul,
    rw bernoulli_poly_def,
    rw polynomial.eval_finset_sum,
    rw finset.mul_sum,
    simp only [polynomial.eval_monomial, div_pow, nat.cast_succ],
--    conv_lhs { rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _], apply_congr, },
    simp_rw [mul_comm (((d * p ^ x : ℕ) : ℚ) ^ k) _],
    simp_rw [mul_assoc],
    rw finset.sum_range_succ_comm,
    rw div_mul_cancel _,
    { rw (algebra_map ℚ R).map_add,
      conv_lhs { congr, skip, rw ← nat.succ_pred_eq_of_pos (pos_of_gt hk),
        rw finset.sum_range_succ_comm, },
      rw div_mul_comm',
      rw (algebra_map ℚ R).map_add, rw add_assoc,
      congr,
      { simp only [nat.choose_self, ring_hom.map_nat_cast, one_mul, ring_hom.map_add, nat.sub_self,
          bernoulli_zero, ring_hom.map_pow, ring_hom.map_one, nat.cast_one], },
      { rw nat.choose_succ_self_right, rw ← nat.succ_eq_add_one,
        rw nat.succ_pred_eq_of_pos (pos_of_gt hk),
        rw nat.pred_eq_sub_one, rw div_eq_mul_inv,
        rw ← pow_sub' ((d * p^x : ℕ) : ℚ) _ (nat.sub_le k 1),
        { rw nat.sub_sub_self (le_of_lt hk),
          rw pow_one, rw ← mul_assoc, rw (algebra_map ℚ R).map_mul,
          simp only [ring_hom.map_nat_cast, ring_hom.map_add, ring_hom.map_pow, ring_hom.map_one,
            ring_hom.map_mul], },
        { norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), }, },
      { rw ring_hom.map_sum, rw pow_succ',
        conv_lhs { apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, rw ← mul_assoc,
          rw (algebra_map ℚ R).map_mul, },
        rw ← finset.sum_mul, rw mul_comm, rw ring_hom.map_nat_cast,
        conv_rhs { congr, skip, apply_congr, skip, rw ← mul_assoc, rw ← mul_assoc, }, }, },
    { norm_cast, apply pow_ne_zero _ (ne_zero_of_lt (mul_prime_pow_pos p d x)), }, },
  { refine ⟨∥∑ (x_1 : ℕ) in finset.range k.pred, (algebra_map ℚ R)
      (bernoulli (k.pred.succ - x_1) * ↑(k.pred.succ.choose x_1) *
      ((↑y + 1) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ (k.pred - 1))∥, _⟩,
    have le : k.pred = k.pred - 1 + 1,
    { rw nat.sub_add_cancel _, rw nat.pred_eq_sub_one, apply nat.le_pred_of_lt hk, },
    conv { congr, congr,
      conv { apply_congr, skip, rw le, rw pow_add, rw pow_one, rw ← mul_assoc,
        rw (algebra_map ℚ R).map_mul, },
      rw [← finset.sum_mul], },
    rw mul_comm, --rw ring_hom.map_nat_cast,
    apply le_trans (norm_mul_le _ _) _,
    convert le_rfl,
    { rw ring_hom.map_nat_cast, },
    { rw ← le, }, },
end

lemma spec_nonneg [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x y : ℕ) : 0 ≤ (classical.some (classical.some_spec
    (exists_just d p m χ hk hχ hp x y)).2) :=
begin
  have mul_nn : 0 ≤ ∥((d * p^x : ℕ) : R)∥ * (classical.some (classical.some_spec
    (exists_just d p m χ hk hχ hp x y)).2),
  { have := classical.some_spec (classical.some_spec (exists_just d p m χ hk hχ hp x y)).2,
    apply le_trans _ this,
    apply norm_nonneg _, },
  apply nonneg_of_mul_nonneg_left mul_nn (norm_mul_pow_pos d p x),
end

lemma exists_just_cont' [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x : ℕ) : ∃ (M : ℝ),
  (⨆ (i : zmod (d * p^x)),
  ∥classical.some (exists_just d p m χ hk hχ hp x i.val) ∥) ≤ ∥((d * p^x : ℕ) : R)∥ * M ∧
  0 ≤ M :=
begin
  haveI : fact (0 < d * p^x) := imp p d x,
  refine ⟨_, _, _⟩,
  { exact (⨆ (i : zmod (d * p^x)), (classical.some (classical.some_spec
    (exists_just d p m χ hk hχ hp x i.val)).2)), },
  { apply le_trans (csupr_le_csupr _ _) _,
    swap 3, { intro i,
      apply (classical.some_spec (classical.some_spec
      (exists_just d p m χ hk hχ hp x i.val)).2), },
    { apply set.finite.bdd_above _,
      apply_instance,
      exact set.finite_range (λ (i : zmod (d * p ^ x)), ∥↑(d * p ^ x)∥ * classical.some
        (classical.some_spec (exists_just d p m χ hk hχ hp x i.val)).right), },
    { apply csupr_le (λ y, _),
      { apply_instance, },
      { rw mul_le_mul_left _,
        { apply le_csupr_of_le _ _,
          swap 3, { exact y, },
          { apply le_rfl, },
          { apply set.finite.bdd_above _,
            apply_instance,
            exact set.finite_range (λ (i : zmod (d * p ^ x)), classical.some
              (classical.some_spec (exists_just d p m χ hk hχ hp x i.val)).right), }, },
        { rw norm_pos_iff, norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), }, }, }, },
  { apply le_csupr_of_le _ _,
    swap 3, { exact 0, },
    { apply spec_nonneg, },
    { apply set.finite.bdd_above _,
      apply_instance,
      exact set.finite_range (λ (i : zmod (d * p ^ x)), classical.some
        (classical.some_spec (exists_just d p m χ hk hχ hp x i.val)).right), }, },
end-/

lemma aux_two [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even)
  (hp : 2 < p) (x y : ℕ) : ∥(∑ (x_1 : ℕ) in finset.range k.pred,
  (algebra_map ℚ R) (bernoulli (k.pred.succ - x_1) * ↑(k.pred.succ.choose x_1) *
  (((y + 1 : ℕ) : ℚ) ^ x_1 / ↑(d * p ^ x) ^ x_1) * ↑(d * p ^ x) ^ k.pred))∥ ≤
  ∥((d * p^x : ℕ) : R)∥ * (⨆ (x_1 : zmod k.pred), (∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) *
  ↑(k.pred.succ.choose x_1.val) * ( ↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥)) :=
begin
  have le : k.pred = k.pred - 1 + 1,
  { rw nat.sub_add_cancel _, rw nat.pred_eq_sub_one, apply nat.le_pred_of_lt hk, },
  apply le_trans (na _ _) _,
  --apply le_trans _ (norm_mul_le _ _),
  apply csupr_le (λ z, _),
  { apply_instance, },
  conv { congr, congr, find (↑(d * p ^ x) ^ k.pred) { rw [le], rw pow_add, rw pow_one, }, rw ← mul_assoc,
      rw (algebra_map ℚ R).map_mul, rw mul_assoc _ _ (↑(d * p ^ x) ^ (k.pred - 1)), rw div_mul_comm', },
  rw mul_comm, --rw ring_hom.map_nat_cast,
  apply le_trans (norm_mul_le _ _) _,
  rw ring_hom.map_nat_cast,
  rw mul_le_mul_left _,
--  simp_rw [div_mul_comm'],
  conv { congr, rw ← mul_assoc, rw (algebra_map ℚ R).map_mul, },
  apply le_trans (norm_mul_le _ _) _,
  have padic_le : ∥(algebra_map ℚ R) (((y + 1 : ℕ) : ℚ) ^ z.val)∥ ≤ 1,
  { rw ← nat.cast_pow,
    rw ring_hom.map_nat_cast,
    rw norm_coe_eq_ring_hom_map p,
    apply padic_int.norm_le_one _,
    apply_instance, },
  apply le_trans (mul_le_mul le_rfl padic_le (norm_nonneg _) (norm_nonneg _)) _,
  rw mul_one,
  { refine le_cSup _ _,
    { haveI : fact (0 < k.pred),
      { apply fact_iff.2 (nat.lt_pred_iff.2 hk), },
      apply set.finite.bdd_above,
      exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
         (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val) *
            (↑(d * p ^ x) ^ (nat.pred k - 1) / ↑(d * p ^ x) ^ x_1.val))∥), },
    { simp only [set.mem_range, exists_apply_eq_apply], }, },
  { exact norm_mul_pow_pos d p x, },
end

lemma finset.neg_sum {α β : Type*} [ring β] (s : finset α) (f : α → β) :
  ∑ x in s, - (f x) = - ∑ x in s, f x :=
begin
  conv_lhs { apply_congr, skip, rw neg_eq_neg_one_mul, },
  rw ← finset.mul_sum, rw ← neg_eq_neg_one_mul,
end

example (a b : R) : a - a - b = -b := by { rw sub_self, rw zero_sub, }
-- #where

-- lemma bla [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
--   [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
--   (na : ∀ (n : ℕ) (f : ℕ → R), ∥∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
--   [fact (0 < m)] {k : ℕ} (ε : ℝ) (x : ℕ) (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (hε : ε > 0)
--   (ne_zero : (d * p ^ x) ≠ 0) (coe_sub : ↑k - 1 = ↑(k - 1))
--   --(non_unit : ¬is_unit ↑(d * p ^ x))
--   (h' : ∀ (x : ℕ), (asso_dirichlet_character (χ.mul
--     (teichmuller_character_mod_p_change_level p d R m ^ k)).asso_primitive_character) ↑x =
--     (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑x)
--   (f1 : (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).
--     asso_primitive_character.conductor = (χ.mul (teichmuller_character_mod_p_change_level p d R m ^
--     k)).conductor) : ∥∑ (x_1 : ℕ) in finset.range (d * p ^ x),
--   (1 / ((d * p ^ x : ℕ) : ℚ)) • ((asso_dirichlet_character (χ.mul
--   (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(x_1.succ) *
--   (↑(d * p ^ x) * classical.some (exists_just d p m _ hk hχ hp x _)))∥ < ε / 2 :=
-- begin
--   sorry
-- end
-- #exit

lemma inv_smul_self [algebra ℚ R] {n : ℕ} (hn : n ≠ 0) :
  (n : ℚ)⁻¹ • (n : R) = 1 :=
begin
  rw ← one_mul (n : R), rw ← smul_mul_assoc, rw ← algebra.algebra_map_eq_smul_one,
  have : (algebra_map ℚ R) (n : ℚ) = (n : R), simp only [ring_hom.map_nat_cast],
  conv_lhs { congr, skip, rw ← this, }, rw ← (algebra_map ℚ R).map_mul, rw inv_mul_cancel _,
  simp only [ring_hom.map_one],
  { norm_cast, apply hn, },
end

lemma one_div_smul_self [algebra ℚ R] {n : ℕ} (hn : n ≠ 0) :
  (1 / (n : ℚ)) • (n : R) = 1 :=
by { rw [← inv_eq_one_div, inv_smul_self hn], }

lemma norm_asso_dir_char_bound [semi_normed_algebra ℚ_[p] R] [fact (0 < m)] (k : ℕ) (x : ℕ) :
  ⨆ (i : zmod (d * p ^ x)), ∥(asso_dirichlet_character (χ.mul
  (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(i.val.succ)∥ <
  dirichlet_character.bound (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)) :=
begin
  rw supr_Prop_eq,
  refine ⟨0, dirichlet_character.lt_bound _ _⟩,
end

lemma zmod.val_le_self (a n : ℕ) : (a : zmod n).val ≤ a :=
begin
  cases n,
  { simp only [int.nat_cast_eq_coe_nat], refl, },
  { by_cases a < n.succ,
    rw zmod.val_cast_of_lt h,
    apply le_trans (zmod.val_le _) _,
    { apply succ_pos'' _, },
    { apply le_of_not_gt h, }, },
end

lemma not_is_unit_of_not_coprime {m a : ℕ} (ha : is_unit (a : zmod m)) : nat.coprime a m :=
begin
  have f := zmod.val_coe_unit_coprime (is_unit.unit ha),
  rw is_unit.unit_spec at f,
  have : m ∣ (a - (a : zmod m).val),
  { rw ← zmod.nat_coe_zmod_eq_zero_iff_dvd,
    rw nat.cast_sub (zmod.val_le_self _ _),
    rw sub_eq_zero,
    cases m,
    { simp only [int.coe_nat_inj', int.nat_cast_eq_coe_nat], refl, },
    { rw zmod.nat_cast_val, simp only [zmod.cast_nat_cast'], }, },
  cases this with y hy,
  rw nat.sub_eq_iff_eq_add _ at hy,
  { rw hy, rw add_comm, rw ← nat.is_coprime_iff_coprime,
    simp only [int.coe_nat_add, int.coe_nat_mul],
    rw is_coprime.add_mul_left_left_iff,
    rw nat.is_coprime_iff_coprime,
    convert zmod.val_coe_unit_coprime (is_unit.unit ha), },
  { apply zmod.val_le_self, },
end

/-lemma not_is_unit_mul [semi_normed_algebra ℚ_[p] R] [fact (0 < m)] (k : ℕ) {x : ℕ} (hx : m ≤ x) :
  ¬ is_unit ((d * p^x : ℕ) : zmod (χ.change_level (dvd_lcm_left (d * p^m) (d * p^m)) *
    (teichmuller_character_mod_p_change_level p d R m ^ k).change_level
    (dvd_lcm_right (d * p^m) (d * p^m))).conductor) :=
begin
  intro h,
  have h' := not_is_unit_of_not_coprime h,

  sorry
end-/

lemma norm_lim_eq_zero [semi_normed_algebra ℚ_[p] R] (k : R) :
  filter.tendsto (λ n : ℕ, (((d * p^n) : ℕ) : R) * k) (filter.at_top) (nhds 0) :=
begin
  by_cases k = 0,
  { rw h, simp only [mul_zero], exact tendsto_const_nhds, },
  { rw metric.tendsto_at_top,
    rintros ε hε,
    have f : 0 < ∥k∥⁻¹,
    { rw inv_pos, rw norm_pos_iff, apply h, },
    have f1 : 0 < ∥k∥⁻¹ * ε,
    { apply mul_pos f hε, },
    have f2 : 1/(p : ℝ) < 1,
    { rw one_div_lt _ _,
      { rw one_div_one, norm_cast, apply nat.prime.one_lt, apply fact.out, },
      { norm_cast, apply nat.prime.pos, apply fact.out, },
      { norm_num, }, },
    have f3 : 0 ≤ 1 / (p : ℝ),
    { apply div_nonneg _ _,
      any_goals { norm_cast, apply nat.zero_le _, }, },
    refine ⟨classical.some (exists_pow_lt_of_lt_one f1 f2), λ n hn, _⟩,
    rw dist_eq_norm, rw sub_zero,
    apply lt_of_le_of_lt (norm_mul_le _ _) _,
    apply lt_of_le_of_lt (mul_le_mul (norm_mul_pow_le_one_div_pow d p n) le_rfl (norm_nonneg _) _) _,
    { apply_instance, },
    { rw ← one_div_pow, apply pow_nonneg f3 _, },
    rw ← inv_inv' (∥k∥),
    rw mul_inv_lt_iff f,
    { rw ← one_div_pow,
      apply lt_of_le_of_lt (pow_le_pow_of_le_one f3 (le_of_lt f2) hn) _,
      apply classical.some_spec (exists_pow_lt_of_lt_one f1 f2), }, },
end

lemma norm_lim_eq_zero' [semi_normed_algebra ℚ_[p] R] {ε : ℝ} (hε : 0 < ε) {k : ℝ} (hk : 0 ≤ k) :
  ∃ n : ℕ, ∀ x ≥ n, ∥((d * p^x : ℕ) : R)∥ * k < ε :=
begin
  by_cases k = 0,
  { rw h, simp only [mul_zero, hε], simp only [implies_true_iff, exists_const], },
  { have f : 0 < k⁻¹,
    { rw inv_pos, apply lt_of_le_of_ne hk (ne_comm.1 h), },
    have f1 : 0 < k⁻¹ * ε,
    { apply mul_pos f hε, },
    have f2 : 1/(p : ℝ) < 1,
    { rw one_div_lt _ _,
      { rw one_div_one, norm_cast, apply nat.prime.one_lt, apply fact.out, },
      { norm_cast, apply nat.prime.pos, apply fact.out, },
      { norm_num, }, },
    have f3 : 0 ≤ 1 / (p : ℝ),
    { apply div_nonneg _ _,
      any_goals { norm_cast, apply nat.zero_le _, }, },
    obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one f1 f2,
    refine ⟨n, λ x hx, _⟩,
    apply lt_of_le_of_lt (mul_le_mul (norm_mul_pow_le_one_div_pow d p x) le_rfl hk _) _,
    { apply_instance, },
    { rw ← one_div_pow, apply pow_nonneg f3 _, },
    rw ← inv_inv' k,
    rw mul_inv_lt_iff f,
    { rw ← one_div_pow,
      apply lt_of_le_of_lt (pow_le_pow_of_le_one f3 (le_of_lt f2) hx) hn, }, },
end

lemma lim_eq_lim [semi_normed_algebra ℚ_[p] R] {a : R} (k : R) {f : ℕ → R}
  (ha : filter.tendsto f (filter.at_top) (nhds a)) :
  filter.tendsto (λ n : ℕ, f n + (((d * p^n) : ℕ) : R) * k) (filter.at_top) (nhds a) :=
begin
  rw ← add_zero a,
  apply filter.tendsto.add ha (norm_lim_eq_zero d p k),
end

noncomputable abbreviation N1 [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  {k : ℕ} (hk : 1 < k) (ε : ℝ) (hε : 0 < ε) :=
  Inf {n : ℕ | ∀ (x : ℕ) (hx : n ≤ x), ∥(∑ (i : ℕ) in finset.range (d * p ^ x),
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑i *
  ↑i ^ (k - 1))∥ < ε}

-- lemma N1_nonempty : set.nonempty ({n : ℕ | ∀ (x : ℕ), n ≤ x → ∥∑ (i : ℕ) in finset.range (d * p ^ x),
--     (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑i *
--       ↑i ^ (k - 1)∥ < ε})

lemma nat_spec (p : ℕ → Prop) (h : ({n : ℕ | ∀ (x : ℕ), x ≥ n → p x}).nonempty) (x : ℕ)
  (hx : x ≥ Inf {n : ℕ | ∀ (x : ℕ) (hx : x ≥ n), p x}) : p x := nat.Inf_mem h x hx

lemma N1_spec [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N1 d p m χ hk ε hε ≤ x) :
  ∥(∑ (i : ℕ) in finset.range (d * p ^ x),
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑i *
  ↑i ^ (k - 1))∥ < ε :=
begin
  apply nat_spec _ _ x hx,
  refine ⟨classical.some (metric.tendsto_at_top.1 (sum_even_character d p m χ na hk hχ hp) ε hε),
    λ x hx, _⟩,
  rw ← dist_zero_right _,
  apply classical.some_spec (metric.tendsto_at_top.1
    (sum_even_character d p m χ na hk hχ hp) ε hε) x hx,
end

noncomputable abbreviation N2 [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  {k : ℕ} (hk : 1 < k) (ε : ℝ) (hε : 0 < ε) :=
  Inf { n : ℕ | ∀ (x : ℕ) (hx : n ≤ x), ∥((d * p ^ x : ℕ) : R)∥ *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound < ε}

lemma N2_spec [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N2 d p m χ hk ε hε ≤ x) :
  ∥((d * p ^ x : ℕ) : R)∥ *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound < ε :=
begin
  apply nat_spec _ _ x hx,
  refine ⟨classical.some (norm_lim_eq_zero' d p hε (le_of_lt (dirichlet_character.bound_pos
    (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))))), λ x hx, _⟩,
  { exact R, },
  any_goals { apply_instance, },
  apply classical.some_spec (norm_lim_eq_zero' d p hε (le_of_lt (dirichlet_character.bound_pos
    (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))))) x hx,
end

lemma norm_le_one [semi_normed_algebra ℚ_[p] R] (n : ℕ) : ∥(n : R)∥ ≤ 1 :=
begin
  rw norm_coe_eq_ring_hom_map p,
  apply padic_int.norm_le_one,
  apply_instance,
end

lemma lim_even_character_aux1 [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) {x : ℕ} (ε : ℝ) (hε : 0 < ε)
  (hx : N1 d p m χ hk (ε/2) (half_pos hε) ≤ x)
  (h'x : N2 d p m χ hk (ε / 2) (half_pos hε) ≤ x) :
  ∥∑ (x : ℕ) in finset.range (d * p ^ x), (asso_dirichlet_character (χ.mul
  (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(x.succ) * ↑(x + 1) ^ (k - 1)∥ < ε :=
begin
  have pos : 0 < k - 1, { rw nat.lt_sub_left_iff_add_lt, rw add_zero, apply hk, },
  convert_to ∥∑ (x : ℕ) in finset.range (d * p ^ x), (asso_dirichlet_character (χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑x * ↑x ^ (k - 1) +
    (((asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level
    p d R m ^ k))) ↑(1 + (d * p^x).pred : ℕ)) * (((1 + (d * p^x).pred : ℕ) : R) ^ (k - 1)))∥ < ε,
  { apply congr_arg,
    conv_rhs { rw finset.range_eq_Ico, rw finset.sum_eq_sum_Ico_succ_bot (mul_prime_pow_pos p d x),
      rw ← nat.succ_pred_eq_of_pos (mul_prime_pow_pos p d x), rw nat.succ_eq_add_one,
      rw ← finset.sum_Ico_add, rw nat.cast_zero, rw nat.cast_zero, rw zero_pow pos,
      { rw mul_zero, rw zero_add, rw ← add_sub_cancel (∑ (l : ℕ) in finset.Ico 0 (d * p ^ x).pred,
    (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(1 + l : ℕ) *
      ((1 + l : ℕ) : R) ^ (k - 1)) (((asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level
      p d R m ^ k))) ↑(1 + (d * p^x).pred : ℕ)) * (((1 + (d * p^x).pred : ℕ) : R) ^ (k - 1))),  --rw ← this,
      rw ← finset.sum_Ico_succ_top (nat.zero_le _),
      rw ← nat.succ_eq_add_one (d * p^x).pred, rw ← finset.range_eq_Ico,
      rw nat.succ_pred_eq_of_pos (mul_prime_pow_pos p d x), rw sub_add_cancel, apply_congr, skip,
      rw add_comm (1 : ℕ) _, }, }, },
  { apply lt_of_le_of_lt (norm_add_le _ _) _,
    apply lt_of_le_of_lt (add_le_add (le_of_lt (N1_spec d p m χ na hk hχ hp (ε/2) (half_pos hε) x hx))
      (norm_mul_le _ _)) _,
    apply lt_of_le_of_lt (add_le_add le_rfl (mul_le_mul (le_of_lt
      (dirichlet_character.lt_bound _ _)) le_rfl (norm_nonneg _) (le_of_lt
      (dirichlet_character.bound_pos _)) )) _,
    conv { congr, congr, skip, congr, skip, congr, rw add_comm 1 _, rw ← nat.succ_eq_add_one,
      rw nat.succ_pred_eq_of_pos (mul_prime_pow_pos p d x), rw ← nat.succ_pred_eq_of_pos pos,
      rw pow_succ, },
    apply lt_of_le_of_lt (add_le_add le_rfl (mul_le_mul le_rfl (norm_mul_le _ _) _
      (le_of_lt (dirichlet_character.bound_pos _)))) _,
    { apply norm_nonneg _, },
    rw ← mul_assoc,
    rw ← nat.cast_pow,
    apply lt_of_le_of_lt (add_le_add le_rfl (mul_le_mul le_rfl (norm_le_one p _) _ _)) _,
    { apply_instance, },
    { apply norm_nonneg _, },
    { apply mul_nonneg (le_of_lt (dirichlet_character.bound_pos _)) (norm_nonneg _), },
    rw mul_one, rw mul_comm,
    conv { congr, skip, rw ← add_halves ε, },
    rw add_lt_add_iff_left,
    apply N2_spec d p m χ na hk hχ hp (ε/2) (half_pos hε) x h'x, },
end

lemma aux_three {k : ℕ} (x : ℕ) [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] (hk : 1 < k) :
  0 ≤ (⨆ (x_1 : zmod k.pred), ∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) *
  ↑(k.pred.succ.choose x_1.val) * (↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥) *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound :=
begin
  haveI pred_pos : fact (0 < k.pred), { apply fact_iff.2 (nat.lt_pred_iff.2 hk), },
  apply mul_nonneg _ (le_of_lt (dirichlet_character.bound_pos _)),
  apply le_csupr_of_le,
  { apply set.finite.bdd_above _,
    { apply_instance, },
    exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
      (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val) *
        (↑(d * p ^ x) ^ (nat.pred k - 1) / ↑(d * p ^ x) ^ x_1.val))∥), },
  { apply norm_nonneg _, },
  { exact 0, },
end

lemma norm_coe_nat_le_one [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R] (n : ℕ) : ∥(algebra_map ℚ R) n∥ ≤ 1 :=
begin
  rw [ring_hom.map_nat_cast, norm_coe_eq_ring_hom_map p],
  { apply padic_int.norm_le_one, },
  { apply_instance, },
end

noncomputable abbreviation N5 [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  {k : ℕ} (hk : 1 < k) (ε : ℝ) (hε : 0 < ε) :=
  Inf { n : ℕ | ∀ (x : ℕ) (hx : n ≤ x), ∥((d * p ^ x : ℕ) : R)∥ * ((⨆ (x_1 : zmod k.pred),
  ∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) * ↑(k.pred.succ.choose x_1.val))∥) *
 -- (↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥) *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) < ε}

lemma N5_spec [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N5 d p m χ hk ε hε ≤ x) :
  ∥((d * p ^ x : ℕ) : R)∥ * ((⨆ (x_1 : zmod k.pred),
  ∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) * ↑(k.pred.succ.choose x_1.val))∥ ) *
  --(↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥) *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) < ε :=
begin
  have div_four_pos : 0 < ε/6, { linarith, },
  haveI pred_pos : fact (0 < k.pred), { apply fact_iff.2 (nat.lt_pred_iff.2 hk), },
  have nn : 0 ≤ (⨆ (x_1 : zmod k.pred), ∥(algebra_map ℚ R)
  (bernoulli (k.pred.succ - x_1.val) * ↑(k.pred.succ.choose x_1.val))∥) *
--  (↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥) *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound,
  { apply mul_nonneg _ (le_of_lt (dirichlet_character.bound_pos _)),
    apply le_csupr_of_le,
    { apply set.finite.bdd_above _,
      { apply_instance, },
      exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
        (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val))∥), },
--          (↑(d * p ^ x) ^ (nat.pred k - 1) / ↑(d * p ^ x) ^ x_1.val))∥), },
    { apply norm_nonneg _, },
    { exact 0, }, },
  apply nat_spec _ _ x hx,
  refine ⟨classical.some (norm_lim_eq_zero' d p hε nn), λ y hy, _⟩,
  { exact R, },
  any_goals { apply_instance, },
  apply classical.some_spec (norm_lim_eq_zero' d p hε nn) y hy,
end

lemma aux_four {k : ℕ} (ε : ℝ) (x : ℕ) [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (hε : ε > 0)
  (hx : x ≥ N5 d p m χ hk (ε/6) (by linarith)) :
  -- (hx : x ≥ classical.some (@norm_lim_eq_zero' d p _ _ R _ _ _
  -- (show 0 < ε / 4, by linarith) _ (aux_three d p m χ x na hk))) :
--  (ne_zero : ↑(d * p ^ x) ≠ 0) (coe_sub : ↑k - 1 = ↑(k - 1)) :
  ∥∑ (x_1 : ℕ) in finset.range (d * p ^ x).pred, (1 / ((d * p ^ x : ℕ) : ℚ)) •
  ((asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)))
    ↑(x_1.succ) * (↑(d * p ^ x) * (∑ (z : ℕ) in finset.range k.pred,
  (algebra_map ℚ R) (bernoulli (k.pred.succ - z) * ↑(k.pred.succ.choose z) *
  (((x_1 + 1 : ℕ) : ℚ) ^ z / ↑(d * p ^ x) ^ z) * ↑(d * p ^ x) ^ k.pred))))∥ < ε / 3 :=
begin
  have div_four_pos : 0 < ε/6, { linarith, },
  have div_four_lt_div_two : ε/6 < ε/3, { linarith, },
  haveI pred_pos : fact (0 < k.pred), { apply fact_iff.2 (nat.lt_pred_iff.2 hk), },
  apply lt_of_le_of_lt _ div_four_lt_div_two,
  apply le_trans (na _ _) _,
  apply csupr_le (λ y, _),
  { apply_instance, },
  conv { congr, congr, rw mul_comm ((asso_dirichlet_character (χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑((zmod.val y).succ)) _,
    rw ← smul_mul_assoc, rw ← smul_mul_assoc, rw ← inv_eq_one_div,
    rw inv_smul_self (ne_zero_of_lt (mul_prime_pow_pos p d x)), rw one_mul, },
  apply le_trans (norm_mul_le _ _) _,
--  obtain ⟨M, hM⟩ := (classical.some_spec (exists_just d p m _ hk hχ hp x y.val)).2,
  --clear this, clear f1,
  -- conv { congr, congr, congr, conv { apply_congr, skip, rw mul_comm ((asso_dirichlet_character (χ.mul
  --   (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(x_1.succ)) _,
  --   rw ← smul_mul_assoc, }, rw ← finset.mul_sum, rw div_eq_mul_inv, rw one_mul,
  --   rw ← smul_mul_assoc, rw inv_smul_self (ne_zero_of_lt (mul_prime_pow_pos p d x)), rw one_mul, },
  -- apply lt_of_le_of_lt (norm_mul_le _ _) _,
  -- obtain ⟨M, h1M, h2M⟩ := exists_just_cont' d p m _ hk hχ hp x,

  /-obtain ⟨M, hM⟩ := (classical.some_spec (exists_just d p m _ hk hχ hp x 37)).2,
  have norm_pos : 0 ≤ ∥((d * p^x : ℕ) : R)∥ * M,
  { apply le_trans (norm_nonneg _) hM, },
  have M_nonneg : 0 ≤ M,
  { apply nonneg_of_mul_nonneg_left norm_pos _,
    rw norm_pos_iff, norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), },
  apply lt_of_le_of_lt (mul_le_mul hM (na _ _) (norm_nonneg _) norm_pos) _,
  rw mul_assoc, rw mul_comm, rw mul_comm M _,
  apply lt_of_le_of_lt (mul_le_mul _ le_rfl (norm_nonneg _) _) _,
  { exact (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound * M, },
  { apply mul_le_mul _ le_rfl M_nonneg (le_of_lt (dirichlet_character.bound_pos _)),
    { apply csupr_le (λ y, _),
      { apply_instance, },
      { apply le_of_lt (dirichlet_character.lt_bound _ _), }, }, },
  --{ rw norm_pos_iff, norm_cast, apply ne_zero_of_lt (mul_prime_pow_pos p d x), },
  { apply mul_nonneg (le_of_lt (dirichlet_character.bound_pos _)) M_nonneg, },
  { rw mul_comm,
    apply (classical.some_spec (norm_lim_eq_zero' d p (half_pos hε)
      (mul_nonneg (le_of_lt (dirichlet_character.bound_pos (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)))) M_nonneg) )) x _,
    { apply_instance, },
    sorry, }, -/
  apply le_trans (mul_le_mul (aux_two d p m _ na hk hχ hp _ _)
    (le_of_lt (dirichlet_character.lt_bound _ _)) _ _) _,
  { apply norm_nonneg _, },
  { apply mul_nonneg (norm_nonneg _) _,
    apply le_csupr_of_le,
    { apply set.finite.bdd_above _,
      { apply_instance, },
      exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
         (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val) *
            (↑(d * p ^ x) ^ (nat.pred k - 1) / ↑(d * p ^ x) ^ x_1.val))∥), },
    { apply norm_nonneg _, },
    { exact 0, }, },
  { rw mul_assoc, apply le_of_lt_or_eq, left,
    have : (⨆ (x_1 : zmod k.pred), (∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) *
      ↑(k.pred.succ.choose x_1.val) * (↑(d * p ^ x) ^ (k.pred - 1) / ↑(d * p ^ x) ^ x_1.val))∥)) ≤
      ⨆ (x_1 : zmod k.pred), ∥(algebra_map ℚ R) (bernoulli (k.pred.succ - x_1.val) *
      ↑(k.pred.succ.choose x_1.val))∥,
    { apply csupr_le (λ y, _),
      { apply_instance, },
      apply le_csupr_of_le _ _,
      rw (algebra_map ℚ R).map_mul,
      rw div_eq_mul_inv,
      rw ← pow_sub' ((d * p^x : ℕ) : ℚ) _ _,
      rw ← nat.cast_pow,
      apply le_trans (norm_mul_le _ _) _,
      rw ring_hom.map_nat_cast,
      apply le_trans (mul_le_mul le_rfl (norm_le_one p _) _ _) _,
      { apply_instance, },
      any_goals { apply norm_nonneg _, },
      { rw mul_one, },
      { exact nonzero_of_invertible ↑(d * p ^ x), },
      { apply nat.le_pred_of_lt,
        apply zmod.val_lt, },
      { apply set.finite.bdd_above _,
        exact nonempty.intro ε,
        exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
        (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val))∥), }, },
    rw mul_comm, rw mul_assoc,
    apply lt_of_le_of_lt (mul_le_mul this le_rfl _ _) _,
    { apply mul_nonneg (le_of_lt (dirichlet_character.bound_pos _)) (norm_nonneg _), },
    { apply real.Sup_nonneg _ (λ x hx, _), cases hx with y hy, rw ← hy, apply norm_nonneg _, },
    rw mul_comm _ (∥↑(d * p ^ x)∥),
    rw mul_comm, rw mul_assoc,
    rw mul_comm ((χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) _,
    apply N5_spec d p m χ na hk hχ hp (ε/6) div_four_pos x hx, },
    -- apply lt_of_le_of_lt this _,
    -- apply classical.some_spec (norm_lim_eq_zero' d p div_four_pos _) _ _,
    -- { apply_instance, },
    -- { apply mul_nonneg _ (le_of_lt (dirichlet_character.bound_pos _)),
    --   apply le_csupr_of_le,
    --   { apply set.finite.bdd_above _,
    --     { apply_instance, },
    --     exact set.finite_range (λ (x_1 : zmod (nat.pred k)), ∥(algebra_map ℚ R)
    --      (bernoulli ((nat.pred k).succ - x_1.val) * ↑((nat.pred k).succ.choose x_1.val) *
    --         (↑(d * p ^ x) ^ (nat.pred k - 1) / ↑(d * p ^ x) ^ x_1.val))∥), },
    --   { apply norm_nonneg _, },
    --   { exact 0, }, },
    -- { apply hx, }, },
end
--set_option pp.implicit true

lemma mul_eq_asso_pri_char {n : ℕ} (χ : dirichlet_character R n) :
 χ.asso_primitive_character.conductor = χ.conductor :=
 (is_primitive_def χ.asso_primitive_character).1 (asso_primitive_character_is_primitive χ)

lemma lev_mul_eq_conductor {n : ℕ} (χ ψ : dirichlet_character R n) :
  lev (χ.mul ψ) = (χ.mul ψ).conductor :=
by { rw [mul, mul_eq_asso_pri_char], }

lemma nat.pred_add_one_eq_self {n : ℕ} (hn : 0 < n) : n.pred + 1 = n := nat.succ_pred_eq_of_pos hn

lemma aux_five_aux [algebra ℚ R] [semi_normed_algebra ℚ_[p] R] [fact (0 < m)] (k : ℕ) {ε : ℝ}
  (hε : 0 < ε) :
  0 ≤ ∥(algebra_map ℚ R) (polynomial.eval 1 (bernoulli_poly k.pred.pred.succ.succ))∥ * (χ.mul
  (teichmuller_character_mod_p_change_level
  p d R m ^ k.pred.pred.succ.succ)).asso_primitive_character.bound ∧ 0 < ε/3 :=
begin
  split,
  { apply mul_nonneg (norm_nonneg _) (le_of_lt (dirichlet_character.bound_pos _)), },
  { linarith, },
end

noncomputable abbreviation N3 [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  {k : ℕ} (hk : 1 < k) (ε : ℝ) (hε : 0 < ε) :=
  Inf { n : ℕ | ∀ (x : ℕ) (hx : n ≤ x), ∥((d * p ^ x : ℕ) : R)∥ * (∥(algebra_map ℚ R) (polynomial.eval 1
    (bernoulli_poly k.pred.pred.succ.succ))∥ * (χ.mul
  (teichmuller_character_mod_p_change_level p d R
    m ^ k.pred.pred.succ.succ)).asso_primitive_character.bound) < ε}

lemma N3_spec [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N3 d p m χ hk ε hε ≤ x) :
  ∥((d * p ^ x : ℕ) : R)∥ * (∥(algebra_map ℚ R) (polynomial.eval 1 (bernoulli_poly k.pred.pred.succ.succ))∥ *
  (χ.mul (teichmuller_character_mod_p_change_level p d R
  m ^ k.pred.pred.succ.succ)).asso_primitive_character.bound) < ε :=
begin
  apply nat_spec _ _ x hx,
  refine ⟨classical.some (norm_lim_eq_zero' d p hε (aux_five_aux d p m χ k hε).1), λ x hx, _⟩,
  { exact R, },
  any_goals { apply_instance, },
  apply classical.some_spec (norm_lim_eq_zero' d p hε (aux_five_aux d p m χ k hε).1) x hx,
end

lemma aux_five [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
-- (n : ℕ) --[fact (0 < n)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N3 d p m χ hk (ε / 3) (by linarith) ≤ x) :
  ∥(1 / ((d * p ^ x : ℕ) : ℚ)) • ((asso_dirichlet_character
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).asso_primitive_character)
  ↑(d * p ^ x) * ((algebra_map ℚ R) (↑(d * p ^ x) ^ k) *
  (algebra_map ℚ R) (polynomial.eval (↑(d * p ^ x) / ↑(d * p ^ x)) (bernoulli_poly k))))∥ < ε/3 :=
begin
  rw [mul_comm _ ((algebra_map ℚ R) (↑(d * p ^ x) ^ k) *
    (algebra_map ℚ R) (polynomial.eval (↑(d * p ^ x) / ↑(d * p ^ x)) (bernoulli_poly k))),
    mul_assoc, ← smul_mul_assoc, ← nat.succ_pred_eq_of_pos (pos_of_gt hk), pow_succ,
   (algebra_map ℚ R).map_mul, ← smul_mul_assoc, ← inv_eq_one_div, ring_hom.map_nat_cast,
   inv_smul_self (ne_zero_of_lt (mul_prime_pow_pos p d x)), one_mul, div_self _],
  { have pred_pos : 0 < k.pred := nat.lt_pred_iff.2 hk,
    rw [← nat.succ_pred_eq_of_pos pred_pos, pow_succ, (algebra_map ℚ R).map_mul, mul_assoc],
    apply lt_of_le_of_lt (norm_mul_le _ _) _,
    apply lt_of_le_of_lt (mul_le_mul le_rfl (norm_mul_le _ _) _ (norm_nonneg _)) _,
    { apply norm_nonneg _, },
    { rw ← nat.cast_pow,
      apply lt_of_le_of_lt (mul_le_mul le_rfl (mul_le_mul (norm_coe_nat_le_one p _) le_rfl _ _) _ _) _,
      any_goals { apply_instance, },
      { apply norm_nonneg _, },
      { norm_num, },
      { apply mul_nonneg (norm_nonneg _) (norm_nonneg _), },
      { apply norm_nonneg _, },
      { rw one_mul,
        apply lt_of_le_of_lt (mul_le_mul le_rfl (norm_mul_le _ _) _ (norm_nonneg _)) _,
        { apply norm_nonneg _, },
        { rw ← mul_assoc,
          apply lt_of_le_of_lt (mul_le_mul le_rfl (le_of_lt (dirichlet_character.lt_bound _ _))
            _ _) _,
          { apply norm_nonneg _, },
          { apply mul_nonneg (norm_nonneg _) (norm_nonneg _), },
          { rw [mul_assoc, ring_hom.map_nat_cast],
            apply N3_spec d p m χ na hk hχ hp (ε/3) (by linarith) x hx, }, }, }, }, },
  { norm_cast, apply (ne_zero_of_lt (mul_prime_pow_pos p d x)), },
end

lemma aux_6_one [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  {k : ℕ} (hk : 1 < k) {ε : ℝ} (hε : 0 < ε) :
  0 < ε / (6 * ∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥) :=
begin
  apply div_pos hε _,
  apply mul_pos _ _,
  { linarith, },
  rw norm_pos_iff,
  rw algebra.algebra_map_eq_smul_one,
  simp only [bernoulli_one, div_eq_zero_iff, false_or, smul_eq_zero, or_false, ne.def,
    nat.cast_eq_zero, bit0_eq_zero, neg_eq_zero, one_ne_zero, mul_eq_zero],
  apply ne_zero_of_lt hk,
end

noncomputable abbreviation N4 [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  {k : ℕ} (hk : 1 < k) (ε : ℝ) (hε : 0 < ε) :=
  Inf { n : ℕ | ∀ (x : ℕ) (hx : n ≤ x), ∥((d * p ^ x : ℕ) : R)∥ * (∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥ *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) < ε}

lemma N4_spec [nontrivial R] [no_zero_divisors R] [semi_normed_algebra ℚ_[p] R] [algebra ℚ R] [fact (0 < m)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) (ε : ℝ) (hε : 0 < ε) (x : ℕ)
  (hx : N4 d p m χ hk ε hε ≤ x) :
  ∥((d * p ^ x : ℕ) : R)∥ * (∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥ *
  (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound) < ε :=
begin
  have nz : (algebra_map ℚ R) (bernoulli 1 * ↑k) ≠ 0,
  { rw algebra.algebra_map_eq_smul_one,
    simp only [bernoulli_one, div_eq_zero_iff, false_or, smul_eq_zero, or_false, ne.def,
      nat.cast_eq_zero, bit0_eq_zero, neg_eq_zero, one_ne_zero, mul_eq_zero],
    apply ne_zero_of_lt hk, },
  have pos : 0 < ∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥ *
    (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound,
  { apply mul_pos (norm_pos_iff.2 nz) (dirichlet_character.bound_pos _), },
  apply nat_spec _ _ x hx,
  refine ⟨classical.some (norm_lim_eq_zero' d p hε (le_of_lt pos)), λ x hx, _⟩,
  { exact R, },
  any_goals { apply_instance, },
  apply classical.some_spec (norm_lim_eq_zero' d p hε (le_of_lt pos)) x hx,
end

lemma aux_6 [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
-- (n : ℕ) --[fact (0 < n)]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) {ε : ℝ} (hε : 0 < ε) (x : ℕ)
  -- (h1x : classical.some (metric.tendsto_at_top.1 (sum_even_character d p m χ na hk hχ hp) _
  --   (@aux_6_one p _ R _ _ _ _ _ _ k hk ε hε)) ≤ x)
  (h1x : x ≥ N1 d p m χ hk _ (half_pos (@aux_6_one p _ R _ _ _ _ _ _ k hk ε hε)))
  (h2x : x ≥ N2 d p m χ hk _ (half_pos (@aux_6_one p _ R _ _ _ _ _ _ k hk ε hε)))
  (h4x : x ≥ N4 d p m χ hk (ε / 6) (by linarith)) :
  -- (h2x : x ≥ classical.some (metric.tendsto_at_top.1
  --        (norm_lim_eq_zero d p (((d * p ^ x : ℕ) : R) ^ (k - 1).pred))
  --        (ε/(4 * ((χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound))) (div_pos hε (mul_pos zero_lt_four (dirichlet_character.bound_pos _))) )) :
  ∥(1 / ((d * p ^ x : ℕ) : ℚ)) •
      ∑ (x_1 : ℕ) in finset.range (d * p ^ x).pred, (asso_dirichlet_character (χ.mul
      (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(x_1.succ) *
    ((algebra_map ℚ R) (bernoulli 1 * ↑k) * ↑(d * p ^ x) * ↑(1 + x_1) ^ (k - 1))∥ < ε / 3 :=
begin
  have six_pos : 0 < ε/6, { apply div_pos hε _, linarith, },
  have nz : (algebra_map ℚ R) (bernoulli 1 * ↑k) ≠ 0,
  { rw algebra.algebra_map_eq_smul_one,
    simp only [bernoulli_one, div_eq_zero_iff, false_or, smul_eq_zero, or_false, ne.def,
      nat.cast_eq_zero, bit0_eq_zero, neg_eq_zero, one_ne_zero, mul_eq_zero],
    apply ne_zero_of_lt hk, },
  have nnz : ∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥ ≠ 0,
  { simp only [bernoulli_one, div_eq_zero_iff, false_or, norm_eq_zero, ring_hom.map_eq_zero,
      ne.def, nat.cast_eq_zero, bit0_eq_zero, neg_eq_zero, one_ne_zero, mul_eq_zero],
    apply ne_zero_of_lt hk, },
  conv { congr, congr, conv { congr, skip,
  conv { apply_congr, skip, rw ← mul_assoc,
  rw mul_comm ((asso_dirichlet_character (χ.mul
    (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑(x_1.succ)) _,
  rw mul_assoc, rw mul_comm _ (↑(d * p ^ x)), rw add_comm 1 x_1, },
  rw ← finset.mul_sum, },
  rw ← smul_mul_assoc, rw ← smul_mul_assoc,
  rw one_div_smul_self (ne_zero_of_lt (mul_prime_pow_pos p d x)), rw one_mul, },
  conv { congr, congr, conv { congr, skip,
  conv { rw ← add_sub_cancel (∑ (x : ℕ) in finset.range (d * p ^ x).pred,
  (asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)))
  ↑(x.succ) * ↑(x + 1) ^ (k - 1)) ((asso_dirichlet_character (χ.mul
  (teichmuller_character_mod_p_change_level p d R m ^ k))) ↑((d * p^x).pred.succ) *
  ↑((d * p^x).pred + 1) ^ (k - 1)),
  rw ← finset.sum_range_succ,
  rw nat.pred_add_one_eq_self (mul_prime_pow_pos p d x),
  congr, skip, rw ← nat.pred_eq_sub_one k,
  rw ← nat.succ_pred_eq_of_pos (nat.lt_pred_iff.2 hk),
  rw pow_succ', rw ← mul_assoc, rw mul_comm, }, }, rw mul_sub, },
  apply lt_of_le_of_lt (norm_sub_le _ _) _,
  apply lt_of_le_of_lt (add_le_add (norm_mul_le _ _) le_rfl) _,
  apply lt_of_le_of_lt (add_le_add (mul_le_mul le_rfl (le_of_lt (lim_even_character_aux1
    d p m χ na hk hχ hp (ε/(6 * ∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥)) _ h1x h2x)) _ _) le_rfl) _,
  --{ apply aux_6_one p hk hε, any_goals { apply_instance, }, },
  --{ apply h1x, }, --h1x
  --{ sorry, }, --h2x
  { apply norm_nonneg _, },
  { apply norm_nonneg _, },
  { conv { congr, congr,
      rw mul_comm (6 : ℝ) _,
      rw ← mul_div_assoc,
      rw mul_div_mul_left _ _ nnz, skip,
      rw ← mul_assoc _ ↑(d * p^x) _, },
    apply lt_of_le_of_lt (add_le_add le_rfl (norm_mul_le _ _)) _,
    have nlt : ∥(asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level
      p d R m ^ k))) ↑((d * p ^ x).pred.succ) * ↑(d * p ^ x) ^ k.pred.pred∥ <
      dirichlet_character.bound (χ.mul (teichmuller_character_mod_p_change_level
      p d R m ^ k)),
    { apply lt_of_le_of_lt (norm_mul_le _ _) _,
      rw ← mul_one (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound,
      apply mul_lt_mul (dirichlet_character.lt_bound _ _) _ _
        (le_of_lt (dirichlet_character.bound_pos _)),
      { rw ← nat.cast_pow, rw norm_coe_eq_ring_hom_map p, apply padic_int.norm_le_one,
        apply_instance, },
      { rw norm_pos_iff, rw ← nat.cast_pow, norm_cast,
        apply pow_ne_zero _ (ne_zero_of_lt (mul_prime_pow_pos p d x)), }, },
    apply lt_of_le_of_lt (add_le_add le_rfl (mul_le_mul le_rfl (le_of_lt nlt) _ (norm_nonneg _))) _,
    { apply norm_nonneg _, },
    { apply lt_of_le_of_lt (add_le_add le_rfl (mul_le_mul (norm_mul_le _ _) le_rfl
        (le_of_lt (dirichlet_character.bound_pos _)) _)) _,
      { apply mul_nonneg (norm_nonneg _) (norm_nonneg _), },
      rw mul_comm _ (∥↑(d * p ^ x)∥),
      rw mul_assoc,
      have add_six : ε/6 + ε/6 = ε/3, linarith,
      have pos : 0 < ∥(algebra_map ℚ R) (bernoulli 1 * ↑k)∥ *
        (χ.mul (teichmuller_character_mod_p_change_level p d R m ^ k)).bound,
      { apply mul_pos (norm_pos_iff.2 nz) (dirichlet_character.bound_pos _), },
      rw ← add_six,
      rw add_lt_add_iff_left,
      apply N4_spec d p m χ na hk hχ hp (ε/6) (by linarith) _ h4x, }, },
end

/-lemma asso_dirichlet_character_equiv' {m n : ℕ} {S : Type*} [comm_monoid_with_zero S] (h : m = n)
  (ψ : dirichlet_character S m) (a : ℕ) :
  asso_dirichlet_character ((equiv h).to_fun ψ) a = asso_dirichlet_character ψ a :=
begin
  -- delta dirichlet_character.equiv,
  -- simp only [mul_equiv.to_fun_eq_coe, eq_mpr_eq_cast, monoid_hom.coe_mk],
  by_cases h₁ : is_unit (a : zmod m),
  { have h₂ : is_unit (a : zmod n), rw ← h, apply h₁,
    rw asso_dirichlet_character_eq_char' _ h₁,
    rw asso_dirichlet_character_eq_char' _ h₂,
    congr,
    --rw h at ψ,
    convert congr _ _,
    swap, { rw ← h, refine ψ.to_fun, },
    swap, { rw ← h, refine h₁.unit, },
    symmetry, simp,
    convert_to (ψ : dirichlet_character S n) h₂.unit = _,
    { dsimp, apply congr_fun _, dsimp [equiv h], dunfold dirichlet_character.equiv, dsimp, },
    apply congr _ _, },
end-/

lemma asso_dirichlet_character_equiv {S : Type*} [comm_monoid_with_zero S]
  (ψ : dirichlet_character S m) (h : is_primitive ψ) (a : ℕ) :
  asso_dirichlet_character ψ.asso_primitive_character a = asso_dirichlet_character ψ a :=
begin
  by_cases h' : is_unit (a : zmod m),
  { conv_rhs { rw factors_through_spec ψ (factors_through_conductor ψ), },
    rw change_level_asso_dirichlet_character_eq' _ _ h',
    apply congr,
    { congr, },
    { rw zmod.cast_nat_cast _,
      swap, { refine zmod.char_p _, },
      { apply conductor_dvd _, }, }, },
  { repeat { rw asso_dirichlet_character_eq_zero, },
    { assumption, },
    rw (is_primitive_def _).1 h, apply h', },
end
.
lemma lim_even_character [nontrivial R] [no_zero_divisors R] [algebra ℚ R]
  [semi_normed_algebra ℚ_[p] R] [is_scalar_tower ℚ ℚ_[p] R]
  (na : ∀ (n : ℕ) (f : ℕ → R), ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
  [fact (0 < m)] {k : ℕ} (hk : 1 < k) (hχ : χ.is_even) (hp : 2 < p) :
  filter.tendsto (λ n, (1/((d * p^n : ℕ) : ℚ)) • ∑ i in finset.range (d * p^n), ((asso_dirichlet_character
  (dirichlet_character.mul χ ((teichmuller_character_mod_p_change_level p d R m)^k)))
  i * i^k) ) (@filter.at_top ℕ _) (nhds (general_bernoulli_number
  (dirichlet_character.mul χ ((teichmuller_character_mod_p_change_level p d R m)^k)) k)) :=
begin
  rw metric.tendsto_at_top,
  intros ε hε,
  have six_pos : 0 < ε/6, linarith,
  have three_pos : 0 < ε/3, linarith,
  obtain ⟨N, hN⟩ := metric.tendsto_at_top'.1 (sum_even_character d p m χ na hk hχ hp) ε hε,
  set s : set ℕ := {N, m, N1 d p m χ hk _ (half_pos (@aux_6_one p _ R _ _ _ _ _ _ k hk ε hε)),
    N2 d p m χ hk _ (half_pos (@aux_6_one p _ R _ _ _ _ _ _ k hk ε hε)),
    N3 d p m χ hk (ε / 3) three_pos, N4 d p m χ hk (ε / 6) six_pos,
    N5 d p m χ hk (ε / 6) six_pos} with hs,
  set l : ℕ := Sup s with hl,
  refine ⟨l, λ x hx, _⟩,
  have hx' : ∀ y ∈ s, y ≤ x,
  { intros y hy, apply le_trans _ hx,
    apply le_cSup _ hy,
    { apply set.finite.bdd_above,
      simp only [set.finite_singleton, set.finite.insert], }, },
  rw dist_eq_norm,
  rw general_bernoulli_number.eq_sum_bernoulli_of_conductor_dvd _ k _,
  swap 2, { exact (d * p^x), },
  swap 2, { apply fact_iff.2 (mul_prime_pow_pos p d x), },
  swap, { rw ← lev_mul_eq_conductor,
    apply dvd_trans (dirichlet_character.lev_mul_dvd' _ _) _,
    rw nat.mul_dvd_mul_iff_left (fact.out _), apply pow_dvd_pow _ (hx' _ _),
    { simp only [set.mem_insert_iff, true_or, eq_self_iff_true, or_true], },
    apply_instance, },
  have ne_zero : ((d * p^x : ℕ) : ℚ) ≠ 0,
  { norm_cast,
    apply ne_zero_of_lt (mul_prime_pow_pos _ _ _),
    any_goals { apply_instance }, },
  have coe_sub : (k : ℤ) - 1 = ((k - 1 : ℕ) : ℤ),
  { change int.of_nat k - 1 = int.of_nat (k - 1),
    rw int.of_nat_sub (le_of_lt hk),
    rw int.of_nat_one, },
  conv { congr, congr,
    conv { congr, skip, rw coe_sub, rw gpow_coe_nat,
    rw [← one_mul ((algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ (k - 1)))],
    rw ← (algebra_map ℚ R).map_one, rw ← one_div_mul_cancel ne_zero, rw (algebra_map ℚ R).map_mul,
    rw mul_assoc _ _ ((algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ (k - 1))),
    rw ← (algebra_map ℚ R).map_mul, rw ← pow_succ, rw nat.sub_add_cancel (le_of_lt hk),
    rw mul_assoc, rw algebra.algebra_map_eq_smul_one, rw smul_mul_assoc, rw one_mul,
    rw finset.mul_sum, congr, skip, apply_congr, skip,
    rw mul_comm ((algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ k)) _,
    rw mul_assoc,
    rw mul_comm _ ((algebra_map ℚ R) (((d * p ^ x : ℕ) : ℚ) ^ k)), }, rw ← smul_sub,
    rw finset.range_eq_Ico,
    conv { rw finset.sum_eq_sum_Ico_succ_bot (mul_prime_pow_pos p d x),
      rw nat.cast_zero, rw nat.cast_zero, rw zero_pow (pos_of_gt hk), rw mul_zero, rw zero_add,
      rw ← nat.sub_add_cancel (nat.succ_le_iff.2 (mul_prime_pow_pos p d x)),
      rw ← finset.sum_Ico_add, rw finset.sum_Ico_succ_top (nat.zero_le _) _,
      rw ← finset.range_eq_Ico, rw ← nat.pred_eq_sub_one,
      rw nat.succ_pred_eq_of_pos (mul_prime_pow_pos p d x), }, rw ← sub_sub, rw smul_sub, },
  have : ∀ x : ℕ, asso_dirichlet_character (χ.mul (teichmuller_character_mod_p_change_level
      p d R m ^ k)).asso_primitive_character x = asso_dirichlet_character (χ.mul
      (teichmuller_character_mod_p_change_level p d R m ^ k)) x,
  { apply asso_dirichlet_character_equiv,
    apply is_primitive_mul, },
  have f1 : ((χ.mul (teichmuller_character_mod_p_change_level
      p d R m ^ k)).asso_primitive_character).conductor = ((χ.mul
      (teichmuller_character_mod_p_change_level p d R m ^ k))).conductor,
  { rw mul_eq_asso_pri_char, },
  conv { congr, congr, congr, conv { congr, skip, congr, skip, conv { apply_congr, skip,
    rw nat.pred_add_one_eq_self (mul_prime_pow_pos p d x),
    rw aux_one d p m _ na hk hχ hp x _,
    rw add_assoc,
    rw mul_add, rw this _,
    rw add_comm _ 1,
    conv { congr, congr, rw nat.succ_eq_add_one, rw add_comm x_1 1, }, }, }, },
    rw finset.sum_add_distrib, rw ← sub_sub, rw sub_self,
    rw smul_sub, rw sub_sub, rw smul_zero,
    rw zero_sub,
  rw norm_neg,
  rw nat.pred_add_one_eq_self (mul_prime_pow_pos p d x),
  conv { congr, congr, congr, congr, skip, conv { apply_congr, skip, rw mul_add, },
    rw finset.sum_add_distrib, },
  rw smul_add,
      simp_rw [nat.pred_eq_sub_one k],
      apply lt_of_le_of_lt (norm_add_le _ _) _,
      apply lt_of_le_of_lt (add_le_add (norm_add_le _ _) le_rfl) _,
      have add_third : ε/3 + ε/3 + ε/3 = ε, linarith,
      have three_pos : 0 < ε/3, { apply div_pos hε _, linarith, },
      have six_pos : 0 < ε/6, { apply div_pos hε _, linarith, },
      apply lt_of_lt_of_le _ (le_of_eq add_third),
      apply add_lt_add _ _,
      { exact covariant_add_lt_of_contravariant_add_le ℝ, },
      { exact covariant_swap_add_le_of_covariant_add_le ℝ, },
      { apply add_lt_add _ _,
        { exact covariant_add_lt_of_contravariant_add_le ℝ, },
        { exact covariant_swap_add_le_of_covariant_add_le ℝ, },
        { apply aux_6 d p m χ na hk hχ hp hε,
          any_goals { apply hx' _ _,
          simp only [set.mem_insert_iff, true_or, eq_self_iff_true, or_true], }, },
        { rw finset.smul_sum,
          convert aux_four d p m χ ε x na hk hχ hp hε _,
          simp_rw [add_comm 1 _], refl,
          { apply hx' _ _,
            simp, }, }, },
      { apply aux_five d p m χ na hk hχ hp ε hε,
        { apply hx' _ _,
          simp only [set.mem_insert_iff, true_or, eq_self_iff_true, or_true], }, },
end