module Data.Array.Extra
  ( (!)
  , foldl1
  , inits
  )
  where

import Ellie.Prelude
import Data.Array ((:))
import Data.Array as Array
import Data.Array (unsafeIndex)
import Data.Maybe (Maybe(..))

infixl 9 unsafeIndex as !


foldl1 :: ∀ a. (a -> a -> a) -> Array a -> Maybe a
foldl1 f xs =
  let
    mf :: Maybe a -> a ->  Maybe a
    mf Nothing x = Just x
    mf (Just y) x = Just (f y x)
  in
  Array.foldl mf Nothing xs


inits :: ∀ a. Array a -> Array (Array a)
inits =
  Array.foldr (\e acc -> [] : map (e : _) acc) [ [] ]
