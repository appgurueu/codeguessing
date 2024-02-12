import Data.Bits (popCount, (.&.))
import Data.Function (on)
naive = [0] ++ go [0] where go seq = let inv = map (1-) seq in inv ++ go (seq ++ inv)
parity = go (0 :: Integer) where go i = popCount i .&. 1 : go (succ i)
main = if ((==) `on` take 1000) naive parity then putStrLn "Test passed" else error "Test failed"
-- 🥱
