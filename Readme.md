[Code Guessing](https://cg.esolangs.gay/) submissions,
licensed under the MIT license except where otherwise noted.

Rounds:

* 38: I-expression calculator in Go.
* 39: Tree-walking BrainFlak interpreter in Scheme.
* 40: [15 puzzle solver app](https://github.com/appgurueu/15) in Dart & Flutter. Zip archive of the repo as submitted.
* 41: FALSE bytecode interpreter in Zig, FALSE self-interpreter.
* 42: 2048 in the terminal in Rust.
* 43: Spirograph drawing in Lua using LÖVE. May contain traces of tomfoolery.
* 44: Countdown solver in Python.
* 45: Connect Four bot and TUI in Nim.
* 46: Find candidate keys using Clojure.
	* Erratum: This has a bug where it finds too many candidate keys,
	  some of which are subsets of others, because I applied
	  an invalid optimization which only filters out *prefix* subsets
	  rather than implementing my originally intended approach
	  of maintaining a de-duplicated list of subsets
	  and constructing the list for the next step from it.
	  Rudimentary input using e.g. the example input
	  did unfortunately not reveal this.
* 47: Longest increasing subsequence finding in Groovy.
      I am quite proud of the algorithm I conceived here.
* 48: Finding an evenly spaced needle in a haystack in TypeScript.
* 49: A weird, minimalistic Lisp written in Racket.
* 50: Silly Markov chain in Java.
* 51: Turing Machine to find the length of a string, implemented in C.
* 52: Two infinite Thue-Morse sequence generators in Haskell.
* 53: The pinnacle of clean coding practices to validate a box drawing,
      written in PHP as appropriate.
* 54: A very basic raytracer in Go which renders a skinned Stanford bunny.
	* Note: The Stanford bunny (`bnuuy.obj`) is not licensed freely,
	  but is available for noncommercial use. See `bnuuy.obj` for details.
* 55: Deciding whether a game of Trax has concluded or not in Python.
	* Intended to be hard to guess. Deliberately left unoptimized for that reason.
