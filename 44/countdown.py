#programmer time (MY TIME) is worth MOAR than cpu time!!!!!!
import argparse
from collections import Counter
from itertools import permutations,product
class Param:
	n=1
	def eval(it): return next(it)
class Expr:
	def __init__(self,l,op,r):
		self.l,self.op,self.r,self.n=l,op,r,l.n+r.n
	def eval(self,it):
		l,r=self.l.eval(it),self.r.eval(it)
		match self.op:
			case '+': return l+r
			case '*': return l*r
			case '-': return float('nan') if l<r else l-r
			case '/': return float('nan') if not r or l%r else l/r
class Bag:
	def __init__(self,s):
		self.ops=Counter()
		self.digits=Counter()
		for c in s:
			if c in '+-*/':
				self.ops.update((c,))
			elif (d:=ord(c)-ord('0')) in range(10):
				self.digits.update((d,))
			else:
				raise ValueError('invalid string')
	def _exprs(ops):
		yield Param
		if not any(ops.values()): return
		nz=[o for o in ops if ops[o]]
		if sum(1 for _ in nz)==1 and (op:=nz[0]) in '+*':
			e=Param
			for _ in range(ops[op]):
				yield (e:=Expr(e,op,Param))
			return
		for op in ops:
			ops[op]-=1
			for splt in product(*(range(ops[o]+1) for o in ops)):
				for l,r in product(Bag._exprs({o:n for n,o in zip(splt,ops)}),Bag._exprs({o:ops[o]-n for n,o in zip(splt,ops)})):
					yield Expr(l,op,r)
			ops[op]+=1
	def exprs(self): return Bag._exprs(self.ops)
	def params(self,n): return permutations(self.digits,r=n)
	def solve(self,num): return min((expr.eval(iter(params)) for expr in self.exprs() for params in self.params(expr.n)),key=lambda x:abs(num-x))
if __name__=='__main__':
	parser=argparse.ArgumentParser()
	parser.add_argument('bag')
	parser.add_argument('num')
	args=parser.parse_args()
	print(Bag(args.bag).solve(int(args.num)))