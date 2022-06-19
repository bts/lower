module Lower.Anf where

import Lower.Name (Bound, Name)
import Lower.Prim (PrimOp)

data Expr a
  = Return (Value a)
  | Bind (Bound a) (Bindable a) (Expr a)
  | TailCall (App a)
  -- TODO: Cond goes here; only in tail position [Danvy 2002]

-- Ideally/eventually this will only contain (unboxed) literals, that can fit
-- in a machine word (i.e. not arbitrary-precision integers)
data Value a
  = Var Name a
  | LitInt Integer a
  | Lam (Bound a) (Expr a) a
  -- NOTE: possibly: | Thunk (Expr a) a

-- RHS of a (let) Bind
data Bindable a
  = Alloc (Value a)
  | Apply (App a)

data App a
  = ApplyFun (Value a) (Value a) a
  | ApplyPrim (PrimOp a) [Value a] a -- TODO: vector
  -- NOTE: possibly: | ApplyThunk (Value a) a