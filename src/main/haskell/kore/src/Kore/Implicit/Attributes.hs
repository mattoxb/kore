{-# LANGUAGE GADTs               #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-|
Module      : Kore.Implicit.Attributes
Description : Haskell definitions for the implicit constructs for attributes.
              uncheckedAttributesModule gathers all of them in a Kore morule
Copyright   : (c) Runtime Verification, 2018
License     : UIUC/NCSA
Maintainer  : virgil.serbanuta@runtimeverification.com
Stability   : experimental
Portability : POSIX
-}

module Kore.Implicit.Attributes
    ( ImplicitAttributes
    , keyOnlyAttribute
    ) where

import Data.Default

import Kore.AST.Common
import Kore.AST.Kore
import Kore.AST.MetaOrObject
import Kore.AST.PureML
import Kore.AST.PureToKore
import Kore.ASTUtils.SmartPatterns

data ImplicitAttributes =
    ImplicitAttributes
    {
    }
  deriving (Show, Eq)

instance Default ImplicitAttributes where
    def = ImplicitAttributes {}

attributeHead :: String -> SymbolOrAlias Object
attributeHead = (`groundHead` AstLocationImplicit)

keyOnlyAttribute :: String -> CommonKorePattern
keyOnlyAttribute k = patternPureToKore
    (App_ (attributeHead k) [])
