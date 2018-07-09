{-|
Module      : Data.Kore.ASTUtils.SmartConstructors
Description : Tree-based proof system, which can be
              hash-consed into a list-based one.
Copyright   : (c) Runtime Verification, 2018
License     : UIUC/NCSA
Maintainer  : phillip.harris@runtimeverification.com
Stability   : experimental
Portability : portable
-}

{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE Rank2Types             #-}
{-# LANGUAGE AllowAmbiguousTypes    #-}
{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE BangPatterns           #-}
{-# LANGUAGE LambdaCase             #-}
{-# LANGUAGE DeriveFunctor          #-}
{-# LANGUAGE DeriveFoldable         #-}
{-# LANGUAGE DeriveTraversable      #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE PatternSynonyms        #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeApplications       #-}
{-# LANGUAGE StandaloneDeriving     #-}
{-# LANGUAGE TypeSynonymInstances   #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}
{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}

module Data.Kore.ASTUtils.SmartConstructors 
( -- * Utility funcs for dealing with sorts
  getSort 
, forceSort
, flexibleSort
, isRigid
, isFlexible
, makeSortsAgree
, ensureSortAgreement
-- * Lenses -- all applicative   
, patternLens
, inputSort   -- | will have 0 or 1 inhabitants
, resultSort  -- | will have 0 or 1 inhabitants
, variable    -- | will have 0 or 1 inhabitants
, allChildren -- | will have 0+ inhabitants
-- * Pattern synonyms
, pattern And_  
, pattern App_ 
, pattern Bottom_   
, pattern Ceil_ 
, pattern DV_     
, pattern Equals_  
, pattern Exists_ 
, pattern Floor_ 
, pattern Forall_  
, pattern Iff_  
, pattern Implies_ 
, pattern In_  
, pattern Next_ 
, pattern Not_ 
, pattern Or_ 
, pattern Rewrites_ 
, pattern Top_   
, pattern Var_ 
, pattern StringLiteral_
, pattern CharLiteral_
, mkAnd
, mkApp
, mkBottom
, mkCeil
, mkDomainValue
, mkEquals
, mkExists
, mkFloor
, mkForall
, mkIff
, mkImplies
, mkIn
, mkNext 
, mkNot 
, mkOr 
, mkRewrites 
, mkTop 
, mkVar 
, mkStringLiteral 
, mkCharLiteral
)
where


import           Control.Lens
import           Control.Monad.State

import           Data.Fix
import           Data.Reflection
import           Data.Foldable


import           Data.Kore.IndexedModule.MetadataTools
import           Data.Kore.AST.Common
import           Data.Kore.AST.MLPatterns
import           Data.Kore.AST.MetaOrObject
import           Data.Kore.AST.PureML 


-- | Gets the sort of of a pattern, taking the Metadatatools implicitly
-- from the context. 
-- The smart constructors `mkAnd`, etc also require this context. 
-- Usage: give metadatatools (... computation with Given Metadatatools ..)
getSort 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level
  -> Sort level
getSort x = (getPatternResultSort (getResultSort given) $ unFix x)

-- | Placeholder sort for when we construct a new predicate
-- But we don't know yet where it's going to be attached.
-- This will probably happen often during proof routines. 
flexibleSort 
  :: MetaOrObject level 
  => Sort level
flexibleSort =
  SortVariableSort $ SortVariable 
    { getSortVariable = noLocationId "__FlexibleSort__" } --FIXME


pattern And_ 
  :: Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern App_
  :: SymbolOrAlias level
  -> [CommonPurePattern level] 
  -> CommonPurePattern level
pattern Bottom_ 
  :: Sort level 
  -> CommonPurePattern level 
pattern Ceil_
  :: Sort level
  -> Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
-- Due to the interaction of pattern synonyms and GADTS
-- I don't think I can write this type signature.
-- pattern DV_
  -- :: Sort Object
  -- -> CommonPurePattern Object 
  -- -> CommonPurePattern Object
pattern Equals_
  :: Sort level
  -> Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern Exists_
  :: Sort level
  -> Variable level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern Floor_
  :: Sort level
  -> Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern Forall_
  :: Sort level
  -> Variable level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern Iff_
  :: Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern Implies_
  :: Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
pattern In_
  :: Sort level
  -> Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
-- pattern Next_
  -- :: Sort Object
  -- -> CommonPurePattern Object 
  -- -> CommonPurePattern Object
pattern Not_
  :: Sort level
  -> CommonPurePattern level 
  -> CommonPurePattern level
pattern Or_
  :: Sort level
  -> CommonPurePattern level
  -> CommonPurePattern level
  -> CommonPurePattern level
-- pattern Rewrites_
--   :: Sort Object
--   -> CommonPurePattern Object
--   -> CommonPurePattern Object
--   -> CommonPurePattern Object

pattern Top_ 
  :: Sort level 
  -> CommonPurePattern level

pattern Var_ 
  :: Variable level 
  -> CommonPurePattern level

-- pattern StringLiteral_ 
--   :: StringLiteral 
--   -> Fix (Pattern level Variable) 

-- pattern CharLiteral_ 
--   :: CharLiteral 
--   -> CommonPurePattern Meta

-- No way to make multiline pragma?
{-# COMPLETE And_, App_, Bottom_, Ceil_, DV_, Equals_, Exists_, Floor_, Forall_, Iff_, Implies_, In_, Next_, Not_, Or_, Rewrites_, Top_, Var_, StringLiteral_, CharLiteral_ #-}

pattern And_          s2   a b = Fix (AndPattern (And s2 a b))
pattern App_ h c               = Fix (ApplicationPattern (Application h c))
pattern Bottom_       s2       = Fix (BottomPattern (Bottom s2))
pattern Ceil_      s1 s2   a   = Fix (CeilPattern (Ceil s1 s2 a))
pattern DV_           s2   a   = Fix (DomainValuePattern (DomainValue s2 a))
pattern Equals_    s1 s2   a b = Fix (EqualsPattern (Equals s1 s2 a b))
pattern Exists_       s2 v a   = Fix (ExistsPattern (Exists s2 v a))
pattern Floor_     s1 s2   a   = Fix (FloorPattern (Floor s1 s2 a))
pattern Forall_       s2 v a   = Fix (ForallPattern (Forall s2 v a))
pattern Iff_          s2   a b = Fix (IffPattern (Iff s2 a b))
pattern Implies_      s2   a b = Fix (ImpliesPattern (Implies s2 a b))
pattern In_        s1 s2   a b = Fix (InPattern (In s1 s2 a b))
pattern Next_         s2   a   = Fix (NextPattern (Next s2 a)) 
pattern Not_          s2   a   = Fix (NotPattern (Not s2 a))
pattern Or_           s2   a b = Fix (OrPattern (Or s2 a b))
pattern Rewrites_     s2   a b = Fix (RewritesPattern (Rewrites s2 a b))
pattern Top_          s2       = Fix (TopPattern (Top s2))
pattern Var_             v     = Fix (VariablePattern v)

pattern StringLiteral_ s = Fix (StringLiteralPattern s)
pattern CharLiteral_   c = Fix (CharLiteralPattern   c) 

patternLens
  :: (Applicative f, MetaOrObject level) 
  => (Sort level -> f (Sort level))
  -> (Sort level -> f (Sort level))
  -> (Variable level -> f (Variable level))
  -> (CommonPurePattern level -> f (CommonPurePattern level))
  -> (CommonPurePattern level -> f (CommonPurePattern level))
patternLens 
  i   -- input sort
  o   -- result sort
  var -- variable
  c   -- child
  = \case 
  And_       s2   a b -> And_      <$>          o s2           <*> c a <*> c b
  Bottom_    s2       -> Bottom_   <$>          o s2
  Ceil_   s1 s2   a   -> Ceil_     <$> i s1 <*> o s2           <*> c a
  DV_        s2   a   -> DV_       <$>          o s2           <*> c a
  Equals_ s1 s2   a b -> Equals_   <$> i s1 <*> o s2           <*> c a <*> c b
  Exists_    s2 v a   -> Exists_   <$>          o s2 <*> var v <*> c a
  Floor_  s1 s2   a   -> Floor_    <$> i s1 <*> o s2           <*> c a
  Forall_    s2 v a   -> Forall_   <$>          o s2 <*> var v <*> c a
  Iff_       s2   a b -> Iff_      <$>          o s2           <*> c a <*> c b
  Implies_   s2   a b -> Implies_  <$>          o s2           <*> c a <*> c b
  In_     s1 s2   a b -> In_       <$> i s1 <*> o s2           <*> c a <*> c b
  Next_      s2   a   -> Next_     <$>          o s2           <*> c a
  Not_       s2   a   -> Not_      <$>          o s2           <*> c a
  Or_        s2   a b -> Or_       <$>          o s2           <*> c a <*> c b
  Rewrites_  s2   a b -> Rewrites_ <$>          o s2           <*> c a <*> c b
  Top_       s2       -> Top_      <$>          o s2
  Var_          v     -> Var_      <$>                   var v
  StringLiteral_ s -> pure (StringLiteral_ s)
  CharLiteral_   c -> pure (CharLiteral_   c)
  App_ h children -> App_ h <$> (traverse c children)

-- | The sort of a,b in \equals(a,b), \ceil(a) etc. 
inputSort        f = patternLens f    pure pure pure 
-- | The sort returned by a top level constructor. 
-- NOTE ABOUT NOTATION:
-- In the this haskell code, this is always `s2`.
-- In the semantics.pdf documentation, the sorts are written 
-- {s1} if there is one sort parameter, and {s1, s2}
-- if there are two sort parameters. This has the effect
-- that the result sort is sometimes s1 and sometimes s2. 
-- I believe this convention is less confusing. 
-- Note that a few constructors like App, StringLiteral and Var
-- Lack a result sort. 
resultSort       f = patternLens pure f    pure pure 
-- | Points to the bound variable in Forall/Exists,
-- and also the Variable in VariablePattern
variable         f = patternLens pure pure f    pure
-- All sub-expressions which are Patterns. 
-- use partsOf allChildren to get a lens to a List. 
allChildren      f = patternLens pure pure pure f   

-- | Rigid patterns are those which have a
-- single uniquely determined sort,
-- which we can't change. 
isRigid
  :: MetaOrObject level 
  => CommonPurePattern level 
  -> Bool
isRigid p = case unFix p of 
  ApplicationPattern   _ -> True
  DomainValuePattern   _ -> True
  VariablePattern      _ -> True
  StringLiteralPattern _ -> True 
  CharLiteralPattern   _ -> True
  _ -> False


-- Flexible patterns are those which can be
-- any sort, like predicates \equals, \ceil etc. 
-- The 3rd option is a constructor whose sort
-- must match the sort of of its subexpressions:
-- \and, \or, \implies, etc. 
isFlexible
  :: MetaOrObject level 
  => CommonPurePattern level 
  -> Bool
isFlexible p = case unFix p of
  BottomPattern _ -> True 
  CeilPattern   _ -> True 
  EqualsPattern _ -> True 
  FloorPattern  _ -> True 
  InPattern     _ -> True 
  TopPattern    _ -> True 
  _ -> False

-- | Tries to modify p to have sort s.  
forceSort 
  :: (MetaOrObject level, Given (MetadataTools level))
  => Sort level 
  -> CommonPurePattern level
  -> Maybe (CommonPurePattern level)
forceSort s p 
 | isRigid    p = checkIfAlreadyCorrectSort s p 
 | isFlexible p = Just $ p & resultSort .~ s 
 | otherwise = traverseOf allChildren (forceSort s) p 

checkIfAlreadyCorrectSort
  :: (MetaOrObject level, Given (MetadataTools level))
  => Sort level 
  -> CommonPurePattern level 
  -> Maybe (CommonPurePattern level)
checkIfAlreadyCorrectSort s p
 | getSort p == s = Just p 
 | otherwise = Nothing

-- Modify all patterns in a list to have the same sort. 
makeSortsAgree
  :: (MetaOrObject level, Given (MetadataTools level))
  => [CommonPurePattern level]
  -> Maybe [CommonPurePattern level]
makeSortsAgree ps = 
  forM ps $ forceSort $ 
    case asum $ getRigidSort <$> ps of 
      Nothing -> flexibleSort
      Just a  -> a

getRigidSort 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> Maybe (Sort level)
getRigidSort p = 
  case forceSort flexibleSort p of 
    Nothing -> Just $ getSort p 
    Just _  -> Nothing



-- | Ensures that the subpatterns of a pattern match in their sorts
-- and assigns the correct sort to the top level pattern
-- i.e. converts the invalid (x : Int /\ ( x < 3 : Float)) : Bool
-- to the valid (x : Int /\ (x < 3 : Int)) : Int
ensureSortAgreement
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
ensureSortAgreement p = 
  case makeSortsAgree $ p ^. partsOf allChildren of 
    Just []    -> p & resultSort .~ flexibleSort
    Just children -> 
      p & (partsOf allChildren) .~ children 
        & resultSort .~ (getSort $ head children)
        & inputSort  .~ (getSort $ head children)
    Nothing -> error $ "Can't unify sorts of subpatterns: " ++ show p

mkAnd
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level
  -> CommonPurePattern level 
mkAnd a b = ensureSortAgreement $ And_ fixmeSort a b

mkApp
  :: (MetaOrObject level, Given (MetadataTools level))
  => SymbolOrAlias level 
  -> [CommonPurePattern level]
  -> CommonPurePattern level
mkApp h c = App_ h c 

mkBottom 
  :: MetaOrObject level
  => CommonPurePattern level 
mkBottom = Bottom_ flexibleSort 

mkCeil 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
mkCeil a = Ceil_ (getSort a) flexibleSort a

mkDomainValue
  :: (MetaOrObject Object, Given (MetadataTools Object))
  => CommonPurePattern Object 
  -> CommonPurePattern Object 
mkDomainValue a = DV_ (getSort a) a

mkEquals
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkEquals a b = ensureSortAgreement $ Equals_ fixmeSort fixmeSort a b

mkExists
  :: (MetaOrObject level, Given (MetadataTools level))
  => Variable level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkExists v a = ensureSortAgreement $ Exists_ fixmeSort v a 

mkFloor
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
mkFloor a = ensureSortAgreement $ Floor_ fixmeSort fixmeSort a 

mkForall
  :: (MetaOrObject level, Given (MetadataTools level))
  => Variable level 
  -> CommonPurePattern level 
  -> CommonPurePattern level
mkForall v a = ensureSortAgreement $ Forall_ fixmeSort v a 

mkIff
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkIff a b = ensureSortAgreement $ Iff_ fixmeSort a b 

mkImplies
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkImplies a b = ensureSortAgreement $ Implies_ fixmeSort a b 

mkIn 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkIn a b = ensureSortAgreement $ In_ fixmeSort fixmeSort a b 

mkNext
  :: (MetaOrObject Object, Given (MetadataTools Object))
  => CommonPurePattern Object 
  -> CommonPurePattern Object 
mkNext a = ensureSortAgreement $ Next_ fixmeSort a 

mkNot 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
mkNot a = ensureSortAgreement $ Not_ fixmeSort a 

mkOr 
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
  -> CommonPurePattern level 
  -> CommonPurePattern level 
mkOr a b = ensureSortAgreement $ Or_ fixmeSort a b 

mkRewrites
  :: (MetaOrObject Object, Given (MetadataTools Object))
  => CommonPurePattern Object 
  -> CommonPurePattern Object 
  -> CommonPurePattern Object
mkRewrites a b = ensureSortAgreement $ Rewrites_ fixmeSort a b 

mkTop
  :: (MetaOrObject level, Given (MetadataTools level))
  => CommonPurePattern level 
mkTop = Top_ flexibleSort

mkVar 
  :: (MetaOrObject level, Given (MetadataTools level))
  => Variable level 
  -> CommonPurePattern level 
mkVar = Var_

mkStringLiteral s = StringLiteral_ s
mkCharLiteral   c = CharLiteral_   c


--should never appear in output of 'mk' funcs
fixmeSort 
  :: MetaOrObject level 
  => Sort level
fixmeSort =
  SortVariableSort $ SortVariable 
    { getSortVariable = noLocationId "FIXME" } --FIXME
