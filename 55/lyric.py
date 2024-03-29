from sys import stdin

L = tuple(map(str.rstrip, stdin.readlines()))

M = {
    '+' : ((1, 0),
           (0, 1)),
    '/' : ((0,-1),
           (-1,0)),
    '\\': ((0, 1),
           (1, 0)),
}



W, H = S = max(map(len, L)), len(L)

def I(p):
    x, y = p
    return y in range(H) and x in range(len(L[y])) and L[y][x] in M

def D(v, w):
    return sum(x * y for x, y in zip(v, w))

def F(p, v):
    x, y = p
    m = M[L[y][x]]
    w = tuple(map(lambda r: D(r, v), m))
    return (x + w[0], y + w[1]), w

def P(p, v):
    o = p
    while I(p):
        p, v = F(p, v)
    if abs(D(o, v) - D(p, v)) >= abs(D(S, v)) >= 8:
        exit(1)

for x in range(W):
    P((x, 0), (0, 1))
    P((x, H-1), (0, -1))

for y in range(H):
    P((0, y), (1, 0))
    P((W-1, y), (-1, 0))

def C(p):
    for v in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        q = set()
        while I(p):
            q.add(p)
            p, v = F(p, v)
            if p in q:
                exit(1)

for y, l in enumerate(L):
    for x in range(len(l)):
        C((x, y))
