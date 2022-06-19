{-# language GeneralizedNewtypeDeriving #-}

module Lower.Name where

import qualified Control.Monad.Gen as Gen
import           Data.Functor ((<&>))
import qualified Data.String as String
import           Data.String (IsString)
import           Data.Text (Text)

newtype Name = Name Text
  deriving (IsString)

data Bound a = Bound Name a

-- Variable supply

mkSupply :: (Show e, Gen.MonadGen e m) => String -> m Name
mkSupply prefix = Gen.gen <&> \e -> String.fromString (prefix <> "##" <> show e)