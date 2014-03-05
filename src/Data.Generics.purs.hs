module Data.Generics where

import Prelude
import Data.Maybe
import Data.Array
import Control.Monad

data Ty
  = TyNum
  | TyStr
  | TyBool
  | TyArr Ty
  | TyObj [{ key :: String, value :: Ty }]
  | TyCon { tyCon :: String, args :: [Ty] }

instance showTy :: Show Ty where
  show TyNum = "Number"
  show TyStr = "String"
  show TyBool = "Boolean"
  show (TyArr el) = "[" ++ show el ++ "]"
  show (TyObj fs) = "{ " ++ joinWith (map (\f -> f.key ++ " :: " ++ show f.value) fs) ", " ++ " }"
  show (TyCon c) = joinWith (c.tyCon : map (\ty -> "(" ++ show ty ++ ")") c.args) " "

data Tm 
  = TmNum Number
  | TmStr String
  | TmBool Boolean
  | TmArr [Tm]
  | TmObj [{ key :: String, value :: Tm }]
  | TmCon { con :: String, values :: [Tm] }

instance showTm :: Show Tm where
  show (TmNum n) = show n
  show (TmStr s) = show s
  show (TmBool b) = show b
  show (TmArr arr) = "[" ++ joinWith (map show arr) ", " ++ "]"
  show (TmObj fs) = "{ " ++ joinWith (map (\f -> f.key ++ ": " ++ show f.value) fs) ", " ++ " }"
  show (TmCon c) = joinWith (c.con : map (\tm -> "(" ++ show tm ++ ")") c.values) " "
  
data Proxy a = Proxy

class Generic a where
  typeOf :: Proxy a -> Ty
  term :: a -> Tm
  unTerm :: Tm -> Maybe a
  
instance genericNumber :: Generic Number where
  typeOf _ = TyNum
  term = TmNum
  unTerm (TmNum n) = Just n
  unTerm _ = Nothing
  
instance genericString :: Generic String where
  typeOf _ = TyStr
  term = TmStr
  unTerm (TmStr s) = Just s
  unTerm _ = Nothing
  
instance genericBoolean :: Generic Boolean where
  typeOf _ = TyBool
  term = TmBool
  unTerm (TmBool b) = Just b
  unTerm _ = Nothing
 
elementProxy :: forall a. Proxy [a] -> Proxy a
elementProxy _ = Proxy
 
instance genericArray :: (Generic a) => Generic [a] where
  typeOf p = TyArr (typeOf (elementProxy p))
  term arr = TmArr $ map term arr
  unTerm (TmArr arr) = mapM unTerm arr
  unTerm _ = Nothing

-- |
-- Generic Show
--

gshow :: forall a. (Generic a) => a -> String
gshow a = show (term a)

-- |
-- Generic transformations
--

data GenericT = GenericT (Tm -> Tm)

runGenericT :: GenericT -> Tm -> Tm
runGenericT (GenericT f) tm = f tm

cast :: forall a b. (Generic a, Generic b) => a -> Maybe b
cast a = unTerm (term a)

mkT :: forall a. (Generic a) => (a -> a) -> GenericT
mkT f = GenericT $ \t -> fromMaybe t $ do
  a <- unTerm t
  return $ term (f a)

gmapTImpl :: GenericT -> Tm -> Tm
gmapTImpl f (TmArr arr) = TmArr $ map (runGenericT f) arr
gmapTImpl f (TmObj fs) = TmObj $ map (\p -> { key: p.key, value: runGenericT f (p.value) }) fs
gmapTImpl f (TmCon c) = TmCon { con: c.con, values: map (runGenericT f) c.values }
gmapTImpl _ other = other

gmapT :: forall a. (Generic a) => GenericT -> a -> a
gmapT f a = case unTerm (gmapTImpl f (term a)) of
  Just a -> a

everywhereImpl :: GenericT -> Tm -> Tm
everywhereImpl f (TmArr arr) = TmArr $ map (runGenericT f <<< everywhereImpl f) arr
everywhereImpl f (TmObj fs) = TmObj $ map (\p -> { key: p.key, value: runGenericT f (everywhereImpl f p.value) }) fs
everywhereImpl f (TmCon c) = TmCon { con: c.con, values: map (runGenericT f <<< everywhereImpl f) c.values }
everywhereImpl _ other = other

everywhere :: forall a. (Generic a) => GenericT -> a -> a
everywhere f a = case unTerm (everywhereImpl f (term a)) of
  Just a -> a