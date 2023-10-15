import std/bitops
import std/strutils
import std/options

type
    X = range[0'u8..6'u8]
    Y = range[0'u8..5'u8]
    Stack = set[Y]
    Mask = array[X, Stack]
    Board = tuple[ours: Mask, theirs: Mask]

type RowBitset = range[0'u8..127'u8]

proc winRowUtil (row: RowBitset): bool =
    (row and 0b0001111) == 0b0001111 or
    (row and 0b0011110) == 0b0011110 or
    (row and 0b0111100) == 0b0111100 or
    (row and 0b1111000) == 0b1111000

var winRows: set[RowBitset]
for i in RowBitset(0)..127'u8:
    if winRowUtil(i):
        winRows.incl i

proc winRow (row: RowBitset): bool =
    row in winRows

proc row (m: Mask, y: Y): RowBitset =
    for x in X(0)..6:
        if y in m[x]:
            result = result or (1'u8 shl x)

proc ascDiag (m: Mask, x: X, y: Y): RowBitset =
    var j = 0'u8
    for i in -int8(x.min(y))..int8((6-x).min(5-y)):
        if Y(int8(y) + i) in m[X(int8(x) + i)]:
            result = result or (1'u8 shl j)
        j += 1

proc descDiag (m: Mask, x: X, y: Y): RowBitset =
    var j = 0'u8
    for i in -int8((6-x).min(y))..int8(x.min(5-y)):
        if Y(int8(y) + i) in m[X(int8(x) - i)]:
            result = result or (1'u8 shl j)
        j += 1

proc winMove (m: Mask, x: X, y: Y): bool =
    winRow(cast[RowBitset](m[x])) or
    winRow(m.row(y)) or
    winRow(m.descDiag(x, y)) or
    winRow(m.ascDiag(x, y))

proc top (board: Board, x: X): Option[Y] =
    let used = cast[uint8](board.ours[x] + board.theirs[x])
    if used == 0:
        return Y(0).some
    let y = 8 - used.countLeadingZeroBits
    if y > 5:
        return Y.none
    return Y(y).some

#[
import std/unittest
suite "bot":
    test "winRow":
        check(winRow 0b1111000)
        check(winRow 0b0111100)
        check(winRow 0b0011110)
        check(winRow 0b0001111)
        check(not winRow 0b0001101)
    let m: Mask = [
        {1, 2, 3},
        {0, 3},
        {1, 2},
        {0, 1},
        {0, 4},
        {3, 4, 5},
        {1, 2, 3},
    ]
    test "row":
        check(m.row(0) == 0b0011010)
        check(m.row(1) == 0b1001101)
    test "ascDiag":
        check(m.ascDiag(1, 1) == 0b110100)
    test "descDiag":
        check(m.descDiag(1, 1) == 0b100)
    test "winMove":
        let m: Mask = [{1, 2, 3, 4}, {}, {}, {}, {}, {}, {}]
        check(m.winMove(0, 4))
    test "top":
        check((ours: m, theirs: m).top(5) == none(Y))
        check((ours: m, theirs: m).top(1) == some(Y(4)))
]#

proc applyMove (board: var Board, x: X, ours: bool) =
    let y = board.top(x).get
    if ours:
        board.ours[x].incl y
    else:
        board.theirs[x].incl y

proc maximize (board: Board, depth: uint8): tuple[score: float, move: X] =
    if depth > 7:
        return
    result.score = -1
    var foundValidMove = false
    for x in X(0)..6:
        let top = board.top(x)
        if top.isNone:
            continue
        let y = top.unsafeGet
        foundValidMove = true
        # Pick a valid move, even if it may seem futile.
        if result.score == -1:
            result.move = x
        var ours = board.ours
        ours[x].incl y
        if ours.winMove(x, y):
            return (score: 1, move: x)
        let min = -(ours: board.theirs, theirs: ours).maximize(depth + 1).score
        # Indirect win forcable?
        if min == 1:
            return (score: 1, move: x)
        if min > result.score:
            result.score = min
            result.move = x
    # Returns an invalid move value (0) but meh
    if not foundValidMove:
        result.score = 0
        

var board: Board

proc makeMove () =
    let move = board.maximize(0).move
    board.applyMove(move, true)
    echo $(move + 1)

let line = stdin.readLine
if line == "f":
    makeMove()
else:
    assert line == "s"

while true:
    let move = stdin.readLine.parseUInt()
    assert move >= 1 and move <= 7
    board.applyMove(X(move - 1), false)
    makeMove()