# iternum: the ULTIMATE!!! number library
made in roblox lua in a module script

infinity is in its number form  
undefined outputs give nan  
nan is not properly handled yet

uses iterated function notation

representation:  
{..., {a_2, b_2, ...}, {a_1, b_1, ...}, n} = ...|a_2 b_2 ...|a_1 b_1 ...|n  
evaluates right to left  
1 1|n is 2^n  
a ...|n is 1 ...| repeated a times then n  
(c 1's) 1 1|n is (c 1's) n+2|0  
(c 1's) 1 b ...|n is (c 1's) n+2 b-1 ...|0 where b > 1

normalisation:  
n is stored as normal numbers, ...|n is stored as tables  
new functions are added iff the lower one reaches 2^53  
(1 1|2^53 -> 2 1|53, 2^53 1|1 -> 1 2|1 1|53)  
function magnitudes must be ordered from greatest to least  
more than 5 functions get cut off (stored as infinity in table)  
(1 6|1 5|1 4|1 3|1 2|(1 1|53 to 2^53-1 1|2^53-1) -> 1 6|1 5|1 4|1 3|1 2|...)
