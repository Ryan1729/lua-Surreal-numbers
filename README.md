#Surreal numbers
===================

A quick implementation of John H.Conway's surreal numbers in Lua. See [here](http://en.wikipedia.org/wiki/Surreal_numbers) for information on Surreal numbers themselves.

This module implements 

- Creation of Surreal Numbers
- Comparison
- Numericity testing
- Addition
- Negation
- Subtraction
- Multiplication

#TODO

- Optimize Multiplication (we only need to calculate things once!)
- Stabilize multiplication: Any given number which will equal two ( i.e. { { {|} | } | } ) , when multiplied by itself or another representaion of two, should always return the same representaion of four
- Add pretty printing function for the numbers. The to_string print function found [here](http://lua-users.org/wiki/TableSerialization) is passable for now.
- Maybe implement ω in some form?
- Given a form for ω, division become feasible


