module Math.KnotTh.Links
	( module Math.KnotTh.Knotted
	, Link
	, Crossing
	, Dart
	, crossingLink
	, dartLink
	, fromList
	) where

import Data.List (intercalate)
import Data.Bits ((.&.), shiftL, shiftR, complement)
import Data.Array (Array)
import Data.Array.Unboxed (UArray)
import Data.Array.ST (STArray, STUArray, newArray_)
import Data.Array.Base (unsafeAt, unsafeWrite, unsafeRead)
import Data.Array.Unsafe (unsafeFreeze)
import Control.Monad.ST (ST, runST)
import Control.Monad (when, forM_)
import Math.Algebra.RotationDirection
import Math.KnotTh.Knotted


data Dart ct = Dart !(Link ct) {-# UNPACK #-} !Int


instance Eq (Dart ct) where
	(==) (Dart _ d1) (Dart _ d2) = (d1 == d2)


instance Ord (Dart ct) where
	compare (Dart _ d1) (Dart _ d2) = compare d1 d2


instance Show (Dart ct) where
	show d =
		let (c, p) = begin d
		in concat ["(Dart ", show (crossingIndex c), " ", show p, ")"]


data Crossing ct = Crossing !(Link ct) {-# UNPACK #-} !Int


instance Eq (Crossing ct) where
	(==) (Crossing _ c1) (Crossing _ c2) = (c1 == c2)


instance Ord (Crossing ct) where
	compare (Crossing _ c1) (Crossing _ c2) = compare c1 c2


instance Show (Crossing ct) where
	show c = concat ["(Crossing ", show (crossingIndex c), " [ ", intercalate " " $ map (show . opposite . nthIncidentDart c) [0 .. 3], " ])"]


data Link ct = Link
	{ count          :: {-# UNPACK #-} !Int
	, crossingsArray :: {-# UNPACK #-} !(UArray Int Int)
	, stateArray     :: {-# UNPACK #-} !(Array Int (CrossingState ct))
	}


instance Show (Link ct) where
	show t =
		let d = map (show . nthCrossing t) [1 .. numberOfCrossings t]
		in concat ["(Tangle ", intercalate " " d, " )"]


instance Knotted Link Crossing Dart where
	numberOfCrossings = count

	numberOfEdges l = 2 * (numberOfCrossings l)

	nthCrossing l i
		| i < 1 || i > numberOfCrossings l  = error "nthCrossing: out of bound"
		| otherwise                         = Crossing l i

	mapCrossingStates f link = runST $ do
		let n = numberOfCrossings link
		st <- newArray_ (0, n - 1) :: ST s (STArray s Int a)
		forM_ [0 .. n - 1] $ \ !i ->
			unsafeWrite st i $! f $! stateArray link `unsafeAt` i
		st' <- unsafeFreeze st
		return $! Link
			{ count          = n
			, crossingsArray = crossingsArray link
			, stateArray     = st' 
			}

	crossingOwner = crossingLink

	crossingIndex (Crossing _ c) = c

	crossingState (Crossing l c) = stateArray l `unsafeAt` (c - 1)

	nthIncidentDart (Crossing l c) i = Dart l $! ((c - 1) `shiftL` 2) + (i .&. 3)

	opposite (Dart l d) = Dart l $! crossingsArray l `unsafeAt` d

	nextCCW (Dart l d) = Dart l $! (d .&. complement 3) + ((d + 1) .&. 3)

	nextCW (Dart l d) = Dart l $! (d .&. complement 3) + ((d - 1) .&. 3)

	incidentCrossing (Dart l d) = Crossing l $! 1 + d `shiftR` 2

	dartPlace (Dart _ d) = d .&. 3

	dartOwner = dartLink

	dartArrIndex (Dart _ i) = i

	forMIncidentDarts (Crossing l c) f =
		let b = (c - 1) `shiftL` 2
		in f (Dart l b) >> f (Dart l $! b + 1) >> f (Dart l $! b + 2) >> f (Dart l $! b + 3)

	foldMIncidentDarts (Crossing l c) f s =
		let b = (c - 1) `shiftL` 2
		in f (Dart l b) s >>= f (Dart l $! b + 1) >>= f (Dart l $! b + 2) >>= f (Dart l $! b + 3)

	foldMIncidentDartsFrom dart@(Dart l i) !direction f s =
		let	d = directionSign direction
			r = i .&. complement 3
		in f dart s >>= f (Dart l $! r + ((i + d) .&. 3)) >>= f (Dart l $! r + ((i + 2 * d) .&. 3)) >>= f (Dart l $! r + ((i + 3 * d) .&. 3))


{-# INLINE crossingLink #-}
crossingLink :: Crossing ct -> Link ct
crossingLink (Crossing l _) = l


{-# INLINE dartLink #-}
dartLink :: Dart ct -> Link ct
dartLink (Dart l _) = l


fromList :: [([(Int, Int)], CrossingState ct)] -> Link ct
fromList list = runST $ do
	let n = length list
	cr <- newArray_ (0, 8 * n - 1) :: ST s (STUArray s Int Int)
	st <- newArray_ (0, n - 1) :: ST s (STArray s Int a)
	forM_ (zip list [0 ..]) $ \ ((!ns, !state), !i) -> do
		unsafeWrite st i state
		when (length ns /= 4) (fail "fromList: there must be 4 neighbours for every crossing")
		forM_ (zip ns [0 ..]) $ \ ((!c, !p), !j) -> do
			when (c < 1 || c > n || p < 0 || p > 3) (fail "fromList: out of bound")
			when (c == i + 1 && p == j) (fail "fromList: dart connected to itself")
			when (c <= i || (c == i + 1 && p < j)) $ do
				let offset = 4 * (c - 1) + p
				c' <- unsafeRead cr (2 * offset)
				p' <- unsafeRead cr (2 * offset + 1)
				when (c' /= i + 1 || p' /= j) (fail "fromList: unconsistent data")
			let offset = 4 * i + j
			unsafeWrite cr (2 * offset) c
			unsafeWrite cr (2 * offset + 1) p

	cr' <- unsafeFreeze cr
	st' <- unsafeFreeze st
	return $! Link
		{ count          = n
		, crossingsArray = cr'
		, stateArray     = st'
		}
