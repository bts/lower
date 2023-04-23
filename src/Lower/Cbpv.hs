module Lower.Cbpv where
import Lower.Name (Name, Bound)
import Lower.Prim (PrimOp)

-- Following:
-- 1. A tutorial on call-by-push-value (Levy): https://www.cs.bham.ac.uk/~pbl/papers/cbpvefftt.pdf
-- 2. Handlers in action (Kammar et al): https://homepages.inf.ed.ac.uk/slindley/papers/handlers.pdf
-- 3. Linear logic (Pfenning): https://www.cs.cmu.edu/~fp/courses/15816-f01/handouts/linear.pdf
-- 4. Call-by-push-value (Levy): https://www.cs.bham.ac.uk/~pbl/papers/thesisqmwphd.pdf

-- After this?
-- - try CBPV^op (New)
-- - implement CK machine for CBPV (make sure to study Fig 4. in [2])

data ValTy
  = TyInt
  | TyUnit                 -- value unit
  | TyAnd ValTy ValTy      -- value product (aka simultaneous conjunction, pair); times/tensor type; eliminated by binding
  | TyVoid                 -- impossibility (aka additive falsehood); 0 type; has no intro
  | TyOr ValTy ValTy       -- disjoint sum (aka external choice); plus type
  | TySuspended CompTy     -- suspended computation (aka U, forget)

data CompTy
  = TyImplies ValTy CompTy -- function; arrow type
  | TyTop                  -- computation unit (aka additive unit); has no eliminator
  | TyWith CompTy CompTy   -- computation product (aka alternative conjunction, internal choice); & type; eliminated by projection
  | TyProduces ValTy       -- value-returning computation (aka F, free)

-- F is left adjoint to U; Moggi's T A is U (F A)
tyT :: ValTy -> ValTy
tyT = TySuspended . TyProduces

data Value a
  = Var Name a
  | LitInt Integer a
  | Thunk (Comp a) a
  -- | Unit a
  -- | Pair (Value a) (Value a) a
  -- | InjLeft (Value a) a
  -- | InjRight (Value a) a

data Comp a
  = Produce (Value a) a -- aka "return"
  | Let (Value a) (Bound a) (Comp a) a
  | To (Comp a) (Bound a) (Comp a) a
  | Lam (Bound a) (Comp a) a -- aka "pop" (value)
  | ApplyFun (Comp a) (Value a) a -- aka "push" (value)
  | ApplyPrim (PrimOp a) [Value a] a
  | Force (Value a) a
  -- | Split (Value a) (Bound a) (Bound a) (Comp a) a
  -- | CaseZero (Value a) a
  -- | Case (Value a) (Bound a, Comp a) (Bound a, Comp a) a
  -- | EmptyChoice a
  -- | Choice (Comp a) (Comp a) a -- aka pop (tag)
  -- | ProjLeft (Comp a) a -- aka "choose left" (push tag pi_1)
  -- | ProjRight (Comp a) a -- aka "choose  right" (push tag pi_2)