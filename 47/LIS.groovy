/*
    Efficient longest increasing subsequence finding.
    Written for Code Guessing Round 47 (https://cg.esolangs.gay/47/).
    Input: Sequence of integers delimited by spacing, ex.: 4 5 2 6 3 5
    Output: Subsequence in the same format, ex.: 4 5 6

    Code may contain minor inconsistencies;
    the author was initially trying to conceal their style (this was for code guessing, after all)
    but then effectively backpedaled on that too.

    The author recommends using at least a gigabyte of IDE bloat to have a half-decent Groovy experience.
 */

class BigIntTree implements Iterable<Iterable<Integer>> {
    class Node {
        List<Integer> is
        Node left, right
    }
    Node root

    void set(BigInteger k, int i) {
        Node node = root ?= new Node()
        for (int j = k.bitLength() - 1; j > -1; --j)
            node = k.testBit(j) ? (node.right ?= new Node()) : (node.left ?= new Node())
        (node.is ?= []).add(i)
    }
    // Breadth-first traversal of the tree gives lets us traverse the keys in sorted order
    // in linear time in the total number of digits in the input
    @Override
    Iterator<Iterable<Integer>> iterator() {
        List<Node> lvl = root == null ? [] : [root]
        int i = 0
        return new Iterator<Iterable<Integer>>() {
            @Override
            boolean hasNext() {
                return !lvl.isEmpty()
            }

            @Override
            Iterable<Integer> next() {
                List<Integer> vs
                do {
                    vs = lvl.get(i).is
                    if (++i >= lvl.size()) {
                        List<Node> nlvl = []
                        for (nd in lvl) {
                            if (nd.left != null) nlvl.add(nd.left)
                            if (nd.right != null) nlvl.add(nd.right)
                        }
                        lvl = nlvl
                        i = 0
                    }
                } while (vs == null)
                return vs
            }
        }
    }
}

class Subseq {
    class Node {
        int i
        Node prev

        Node(int i, Node prev) {
            this.i = i
            this.prev = prev
        }
    }
    int len
    Node root
    static Subseq EMPTY = new Subseq()

    Subseq() {}

    Subseq(Subseq p, int i) {
        len = (p == null ? 0 : p.len) + 1
        root = new Node(i, p.root)
    }

    BigInteger[] apply(BigInteger[] seq) {
        def res = new BigInteger[len]
        def node = this.root
        for (def i = len - 1; i > -1; i--) {
            res[i] = seq[node.i]
            node = node.prev
        }
        return res
    }
}

class SegmentTree {
    class Node {
        Subseq subseq = Subseq.EMPTY
        Node left, right

        Node(int n) {
            assert (n > 0)
            if (n == 1) return
            def mid = n >> 1
            left = new Node(mid)
            right = new Node(n - mid)
        }
        // Get best subseq s with max(s) <= n
        Subseq get(int w, int n) {
            assert n <= w
            if (w == n)
                return subseq
            def mid = w >> 1
            if (n <= mid)
                return left.get(mid, n)
            def ssl = left.subseq
            def ssr = right.get(w - mid, n - mid)
            return (ssr.len > ssl.len) ? ssr : ssl
        }
        // Set new best subseq s for max(s) <= n
        void set(int w, int n, Subseq ss) {
            assert n <= w
            if (w == n) {
                if (ss.len > subseq.len)
                    subseq = ss
                return
            }
            if (ss.len > subseq.len)
                subseq = ss
            def mid = w >> 1
            if (n <= mid) {
                left.set(mid, n, ss)
                return
            }
            // Note: We can't install this for left, since left has a stricter bound
            right.set(w - mid, n - mid, ss)
        }
    }
    Node root
    int n

    SegmentTree(int n) {
        root = new Node(this.n = n)
    }

    Subseq get(int n) {
        return root.get(this.n, n)
    }

    Subseq set(int n, Subseq ss) {
        return root.set(this.n, n, ss)
    }
}

static BigInteger[] solve(BigInteger[] seq) {
    if (seq.length == 0) return new BigInteger[0]
    def t = new BigIntTree()
    for (int i = 0; i < seq.length; ++i)
        t.set(seq[i], i)
    // Remove gaps in the ordering.
    // This is important for achieving good time complexity.
    int o = 0
    def ordinals = new int[seq.length]
    for (is in t) {
        ++o
        for (i in is)
            ordinals[i] = o
    }
    // Do the "greedy" / "dynamic programming" solving
    // using a segment tree of best subsequences for upper bounds of the last element.
    def st = new SegmentTree(o)
    for (int i = 0; i < ordinals.length; ++i) {
        def n = ordinals[i]
        def ss = n == 1 ? Subseq.EMPTY : st.get(n - 1)
        st.set(n, new Subseq(ss, i))
    }
    return st.get(o).apply(seq)
}

static BigInteger[] read() {
    def sc = new Scanner(System.in)
    List<BigInteger> s = []
    while (sc.hasNext())
        s << new BigInteger(sc.next())
    return s.toArray(new BigInteger[s.size()])
}

static void write(BigInteger[] subseq) {
    print(subseq[0])
    for (int i = 1; i < subseq.length; i++) {
        print(" ")
        print(subseq[i])
    }
    println()
}

static void main(String[] args) {
    write(solve(read()))
}

/*
    Runtime analysis:

    Let the input be a sequence of n numbers encoded in some base
    (say, binary, or decimal, with at least one digit per number), delimited by some delimiter.
    Then the length of the input is O(m), where m is the total count of digits in the input (in any fixed base).
    Constructing the prefix tree to sort the numbers is O(m) then,
    as is traversing the prefix tree in level-order (breadth-first, left to right);
    replacing numbers with their ordinals is O(m) as well
    (incrementing the ordinal o would be amortized constant time even if o were a bigint).

    For each distinct ordinal, there needs to be a distinct number in the input.
    To encode k distinct numbers, you need Θ(log(k)) bits (on average) for each number.
    This implies an input length of Θ(n log(k)) (in bits, bytes, characters, whatever, as long as it's fixed size).
    (This also imposes an upper bound of O(log n) on the length of each ordinal in bits,
    which is why this implementation elects to represent ordinals as "just integers":
    larger sequences couldn't be represented using Java data structures anyways.)

    The next step maintains a "segment tree" which maps maxima to longest subsequences
    using only elements encountered so far (a prefix of the sequence).
    Since the largest value is the largest ordinal, this segment tree has depth log(k).
    For each element in the sequence, one get and set operation are issued.
    Since these operations can both easily be seen (*) to be O(log(k)),
    we obtain O(n log(k)), which is true linear time in the input size (in bits, not in integer registers).

    (*) For a simplified analysis, assume a perfect binary segment tree (that is, k is a power of two).
    We presume big integers (which this implementation does not use for aforementioned reasons,
    but which are nevertheless relevant for runtime analysis).
    Then the comparison `w == n` would not be constant time,
    but for each bit it has to compare, it saves having to dive a layer deeper, so it is fine.
    Since we split perfectly in the middle, `n <= mid` would only have to look at the most significant bit.
    `w - mid` / `n - mid` effectively just removes that most significant bit, thus is also constant time.

    A proof of correctness will be supplied when the author finds the time and motivation.
    For now, you will have to take the author's "trust me bro" for it.

    Exercises left to the reader:

    * Test this thoroughly to convince yourself of the correctness.
    * Constant-factor optimization of the binary tree / prefix tree:
      "Compress" long paths of multiple bits (trie -> patricia tree)
    * Constant-factor optimization of the segment tree:
      Store it in an array, avoids many heap allocations, improves cache locality.
    * Rewrite this in a "better" programming language.
 */
