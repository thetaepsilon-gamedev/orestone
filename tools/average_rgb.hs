-- a tool for reading in a bunch of RGB values and then spitting out their average.
module Main where

import Data.Either.Combinators (maybeToRight)
import Text.Read (readMaybe)
import Basement.Floating (integerToFloat)



-- basic RGB data type
data RGB = RGB Float Float Float
  deriving Show
mapRGB :: (Float -> Float) -> RGB -> RGB
mapRGB f (RGB r g b) = RGB (f r) (f g) (f b)

-- read RGB tokens (just does some maybe boilerplate)
readRGB :: String -> String -> String -> Maybe RGB
readRGB rs gs bs = do
  r <- readMaybe rs
  g <- readMaybe gs
  b <- readMaybe bs
  return (RGB r g b)



-- function to handle a line of input.
msgBadParse = "# one or more of the RGB values wasn't a number."
parseLine :: String -> Either String RGB
parseLine line = case (words line) of
  [rs,gs,bs] ->
    -- try to handle the tokens, may not all be numbers.
    maybeToRight msgBadParse (readRGB rs gs bs)
  -- not enough tokens?
  list -> Left ("# not enough tokens in line, expected 3, got " ++ show (length list))



-- addition over RGB tuples
addRGB :: RGB -> RGB -> RGB
addRGB (RGB r1 g1 b1) (RGB r2 g2 b2) = RGB (r1 + r2) (g1 + g2) (b1 + b2)

-- handle final display of RGB data
display :: [RGB] -> Integer -> String
display [] _ = "# no entries? can't do anything."
display rgbs counter =
  -- we know from the above that the list must be non-empty.
  let
    total = foldr1 addRGB rgbs
    average = mapRGB (/ (integerToFloat counter)) total
  in "-> Average RGB values: " ++ show average
  


-- operate on lines of input served up from "interact", and return output lines.
-- reads in triples of RGB one at a time, building up a list of RGB triples.
-- when end-of-list or a stop indicator "." is encountered,
-- the RGB triples are averaged and printed.
readRGBLines :: [RGB] -> Integer -> [String] -> [String]
readRGBLines rgbs counter [] = [display rgbs counter]
readRGBLines rgbs counter (l:ls) = case l of
  "." -> [display rgbs counter]
  rgbl ->
    case (parseLine rgbl) of
      -- line error? continue on with rest of input lines
      Left err -> err:(readRGBLines rgbs counter ls)
      -- otherwise add it to list
      Right rgb -> readRGBLines (rgb:rgbs) (counter + 1) ls



-- COMPOSE POWAH
main :: IO ()
main = interact (unlines . ((readRGBLines [] 0) . lines))

