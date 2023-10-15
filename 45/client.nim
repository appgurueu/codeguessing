import os
import osproc
import std/strutils
import std/streams

type
    Spot = enum Free, Ours, Theirs
    Stack = array[6, Spot]
    Board = array[7, Stack]

var board: Board
var winner: Spot = Free

proc printBoard =
    for row in countdown(5, 0):
        for col in 0..6:
            const spotChar: array[Spot, char] = ['.', 'O', 'X']
            stdout.write spotChar[board[col][row]]
        stdout.write '\n'
    stdout.flushFile()

proc invalidMove (move: uint): bool =
    move < 1 or move > 7 or board[move - 1][^1] != Free

proc inBounds (x, y: int): bool =
    x >= 0 and x < 7 and y >= 0 and y < 6

proc countDir(x, y: uint, dx, dy: int): uint =
    var count: uint = 0
    var x = int(x)
    var y = int(y)
    let expected = board[x][y]
    while true:
        x += dx
        y += dy
        if not inBounds(x, y) or board[x][y] != expected:
            break
        count += 1
    return count

proc checkWinDir (x, y: uint, dx, dy: int): bool =
    return countDir(x, y, -dx, -dy) + 1 + countDir(x, y, dx, dy) >= 4

proc checkWin (x, y: uint): bool =
    checkWinDir(x, y, 0, 1) or checkWinDir(x, y, 1, 0) or checkWinDir(x, y, 1, 1)

var moves = 0
proc makeMove (move: uint, player: Spot) =
    assert player != Free
    for y, spot in board[move]:
        if spot == Free:
            board[move][y] = player
            if checkWin(move, uint(y)):
                winner = player
            moves += 1
            break

var bot = startProcess(paramStr(1), options = {})
var botIn = bot.inputStream
var botOut = bot.outputStream
proc sendCommand (command: string) =
    botIn.writeLine command
    botIn.flush
sendCommand "s" # hoomans go first!

while true:
    printBoard()
    if winner != Free or moves == 6*7:
        break
    block:
        echo "Make a move:"
        let move = stdin.readLine.parseUInt
        if invalidMove(move):
            echo "Invalid move"
            continue
        makeMove(move - 1, Ours)
        sendCommand $move
    if winner == Free:
        var line: string
        assert botOut.readLine line
        let move = line.parseUInt
        if invalidMove(move):
            echo "Invalid move from bot"
            break # can't resume with a broken bot
        makeMove(move - 1, Theirs)
bot.terminate
bot.close

const outcome: array[Spot, string] = ["Draw", "You win!", "They win!"]
echo outcome[winner]