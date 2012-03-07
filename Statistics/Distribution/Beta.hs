{-# LANGUAGE DeriveDataTypeable #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Statistics.Distribution.Beta
-- Copyright   :  (C) 2012 Edward Kmett,
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  DeriveDataTypeable
--
----------------------------------------------------------------------------
module Statistics.Distribution.Beta
  ( BetaDistribution
    -- * Constructor
  , betaDistr
    -- * Accessors
  , bdAlpha
  , bdBeta
  ) where

import Numeric.SpecFunctions
import Numeric.MathFunctions.Constants (m_NaN)
import qualified Statistics.Distribution as D
import Data.Typeable

-- | The beta distribution
data BetaDistribution = BD
 { bdAlpha :: {-# UNPACK #-} !Double
   -- ^ Alpha shape parameter
 , bdBeta  :: {-# UNPACK #-} !Double
   -- ^ Beta shape parameter
 } deriving (Eq,Read,Show,Typeable)

-- | Create beta distribution. Both shape parameters must be positive.
betaDistr :: Double             -- ^ Shape parameter alpha
          -> Double             -- ^ Shape parameter beta
          -> BetaDistribution
betaDistr a b
  | a > 0 && b > 0 = BD a b
  | otherwise      =
      error $  "Statistics.Distribution.Beta.betaDistr: "
            ++ "shape parameters must be positive. Got a = "
            ++ show a
            ++ " b = "
            ++ show b
{-# INLINE betaDistr #-}

instance D.Distribution BetaDistribution where
  cumulative (BD a b) x
    | x <= 0 = 0
    | otherwise = incompleteBeta a b x
  {-# INLINE cumulative #-}

instance D.Mean BetaDistribution where
  mean (BD a b) = a / (a + b)
  {-# INLINE mean #-}

instance D.MaybeMean BetaDistribution where
  maybeMean = Just . D.mean
  {-# INLINE maybeMean #-}

instance D.Variance BetaDistribution where
  variance (BD a b) = a*b / (apb*apb*(apb+1))
    where apb = a + b
  {-# INLINE variance #-}

instance D.MaybeVariance BetaDistribution where
  maybeVariance = Just . D.variance
  {-# INLINE maybeVariance #-}

-- invert a monotone function
invertMono :: (Double -> Double) -> Double -> Double -> Double -> Double
invertMono f l0 h0 b = go l0 h0 where
  go l h
    | h - l < epsilon = m
    | otherwise = case compare (f m) b of
      LT -> go m h
      EQ -> m
      GT -> go l m
    where m = l + (h-l)/2
          epsilon = 1e-12
{-# INLINE invertMono #-}

instance D.ContDistr BetaDistribution where
  density (BD a b) x
   | a <= 0 || b <= 0 = m_NaN
   | x <= 0 = 0
   | x >= 1 = 0
   | otherwise = exp $ (a-1)*log x + (b-1)*log (1-x) - logBeta a b
  {-# INLINE density #-}

  quantile d p
    | p == 0         = 0
    | p == 1         = 1
    | p > 0 && p < 1 = invertMono (D.cumulative d) 0 1 p
    | otherwise      =
        error $ "Statistics.Distribution.Gamma.quantile: p must be in [0,1] range. Got: "++show p
  {-# INLINE quantile #-}

-- TODO: D.ContGen for rbeta