(* Formal Verification Properties *)
Module Safety:
  Forall modules m, m.code ≠ 0 ∧ m.storage ∩ core.storage = ∅

State Consistency:
  Always(core.storage ∩ module.storage = ∅)

Governance Invariant:
  Only governance can update modules
