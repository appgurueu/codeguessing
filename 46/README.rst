==========================
CG 46: Find Candidate Keys
==========================

Input
=====

**Tab-Separated Values** (TSV) on standard input as Olive intended.
The escape sequences ``\t``, ``\n``, ``\r`` and ``\\`` are supported.

Example
-------

Here is the example table in TSV format::

	contest	date held	winner	winner's second name
	dog fight	oct 17 2000	discarding sabot	sabot
	cat-off	jul 01 2001	palm tree oil	tree
	rat duel	oct 05 2001	cart of iron	of
	rat duel	mar 21 2006	cart of iron	of
	shark race	mar 21 2006	linguist	NULL

Output
======

For consistency, the output is also **pseudo-TSV** that is written to standard output.

Edge cases:

* The empty set of columns is represented by an empty line.
* The empty set of candidate keys is represented by no lines being printed.

Example
-------

Here is the output for the example table::

	date held	winner's second name
	date held	winner
	contest	date held
