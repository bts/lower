{-# language FlexibleContexts #-}

-- | Lowers the surface syntax to ANF (Administrative Normal Form) syntax.
module Lower.ToAnf (toAnf) where

import           Control.Monad.Cont (MonadTrans(lift), ContT(runContT), mapContT)
import           Control.Monad.Gen (MonadGen, Gen, runGen)
import           Numeric.Natural (Natural)

import qualified Lower.Anf as Anf
import qualified Lower.Name as Name
import           Lower.Name (Bound(Bound), Name)
import qualified Lower.Surface as Surface

type Lower = Gen Natural

toAnf :: Surface.Expr a -> Anf.Expr a
toAnf = runGen . lowered

-- | Handles tail conversion. This is Danvy's E.
lowered :: Surface.Expr a -> Lower (Anf.Expr a)
lowered (Surface.Var nm l) =
  pure $ Anf.Return $ Anf.Var nm l
lowered (Surface.LitInt i l) =
  pure $ Anf.Return $ Anf.LitInt i l
lowered (Surface.Lam b e l) = do
  e' <- lowered e
  pure $ Anf.Return $ Anf.Lam b e' l
lowered (Surface.App e0 e1 l) =
  evalContT $ do
    v0 <- valued $ withLowered e0
    v1 <- valued $ withLowered e1
    pure $ Anf.TailCall (Anf.ApplyFun v0 v1 l)
lowered (Surface.PrimApp op es l) =
  evalContT $ do
    vs <- traverse (valued . withLowered) es
    pure $ Anf.TailCall $ Anf.ApplyPrim op vs l
lowered (Surface.Let (Surface.Decl b rhs _l1) body _l2) = do
  evalContT $ do
    bindable <- withLowered rhs
    body' <- lift $ lowered body -- tail
    pure $ Anf.Bind b bindable body' -- TODO: mark as non-synthetic

-- | Handles non-tail conversion. Danvy's E_c, *but* yielding a Bindable
-- instead of a Value. Danvy's approach works well until you introduce let into
-- the source language. If you yield values instead of bindables in the
-- presence of let, then converting a let with an app on the RHS will result in
-- a synthetic let (i.e. unassociated with a source let) being produced during
-- the processing of the RHS, with conversion of the let /itself/ either
-- producing an extraneous let, or none at all. It's important to produce an
-- ANF let during the conversion of the source let so that we can annotate ANF
-- lets per this distinction without complicating the algorithm.
withLowered
  :: Surface.Expr a
  -- ^ Input surface expression to lower.
  -> ContT (Anf.Expr a) Lower (Anf.Bindable a)
  -- ^ Lowering to ANF, which yields (i.e., can be continued by handling) an ANF value.
withLowered (Surface.Var nm l) =
  pure $ Anf.Alloc $ Anf.Var nm l
withLowered (Surface.LitInt i l) =
  pure $ Anf.Alloc $ Anf.LitInt i l
withLowered (Surface.Lam b e l) = do
  e' <- lift $ lowered e -- tail conversion
  pure $ Anf.Alloc $ Anf.Lam b e' l
withLowered (Surface.App e0 e1 l) = do
  v0 <- valued $ withLowered e0
  v1 <- valued $ withLowered e1
  pure $ Anf.Apply $ Anf.ApplyFun v0 v1 l
withLowered (Surface.PrimApp op es l) = do
  vs <- traverse (valued . withLowered) es
  pure $ Anf.Apply $ Anf.ApplyPrim op vs l
withLowered (Surface.Let (Surface.Decl b rhs _l1) body _l2) = do
  bindable <- withLowered rhs
  mapContT (fmap $ Anf.Bind b bindable)
    (withLowered body)

-- | While lowering, yield a Value instead of a Bindable
valued
  :: ContT (Anf.Expr a) Lower (Anf.Bindable a)
  -> ContT (Anf.Expr a) Lower (Anf.Value a)
valued m = do
    bindable <- m
    case bindable of
      Anf.Alloc v -> pure v
      apply@(Anf.Apply app) -> do
        let l = label app
        nm <- fresh
        mapContT (fmap $ Anf.Bind (Bound nm l) apply) -- TODO: mark as synthetic
          (pure $ Anf.Var nm l)

  where
    label :: Anf.App a -> a
    label (Anf.ApplyFun _ _ a) = a
    label (Anf.ApplyPrim _ _ a) = a

-- Defined in transformers, but not mtl.
evalContT :: (Monad m) => ContT r m r -> m r
evalContT m = runContT m pure
{-# INLINE evalContT #-}

fresh :: MonadGen Natural m => m Name
fresh = Name.mkSupply "anf"