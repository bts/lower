module Lower.Surface where

import Lower.Name (Bound, Name)
import Lower.Prim (PrimOp)

data Decl a
  = Decl (Bound a) (Expr a) a

data Expr a
  = LitInt Integer a
  | Var Name a
  | Lam (Bound a) (Expr a) a
  | App (Expr a) (Expr a) a
  -- TODO: switch to vector
  | PrimApp (PrimOp a) [Expr a] a -- fully applied
  | Let (Decl a) (Expr a) a