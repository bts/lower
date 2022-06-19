module Lower.Surface where

import Lower.Name (Bound, Name)
import Lower.Prim (PrimOp)

data Decl a
  = Decl (Bound a) (Expr a) a

data Value a
  -- TODO: switch to 64-bit int
  = LitInt Integer a
  | Var Name a

data Expr a
  = Val (Value a) a
  | Lam (Bound a) (Expr a) a
  | App (Expr a) (Expr a) a
  -- TODO: switch to vector
  | PrimApp (PrimOp a) [Expr a] a -- fully applied
  | Let (Decl a) (Expr a) a