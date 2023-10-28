package main

import (
	"os"
	"fmt"
	"bufio"
)

func pop[T any](slice []T) ([]T, T) {
	return slice[:len(slice)-1], slice[len(slice) - 1]
}

func apply(op byte, a, b int32) int32 {
	switch op {
		case '+': return a + b
		case '-': return a - b
		case '*': return a * b
		case '/': return a / b
	}
	panic("invalid op")
}

func main() {
	var operands []int32
	var ops []byte
	var precedences []uint // higher is lower
	var eval func() int32
	eval = func() int32 {
		if len(operands) == 0 {
			panic("no operands")
		}
		if len(ops) == len(operands) {
			panic("too few operands")
		}
		for {
			if len(ops) == 0 {
				res := operands[0]
				operands = nil
				return res
			}
			var topOp byte
			var topPrec uint
			var lhs, rhs int32
			ops, topOp = pop(ops)
			precedences, topPrec = pop(precedences)
			operands, rhs = pop(operands)
			if len(ops) > 0 {
				botPrec := precedences[len(precedences) - 1]
				if botPrec <= topPrec {
					return apply(topOp, eval(), rhs)
				}
			}
			operands, lhs = pop(operands)
			operands = append(operands, apply(topOp, lhs, rhs))
		}
	}
	stdin := bufio.NewReader(os.Stdin)
	countSpaces := func() (spaces uint) {
		for {
			c, _ := stdin.ReadByte()
			if c != ' ' {
				break
			}
			spaces++
		}
		stdin.UnreadByte()
		return
	}
	for {
		leadingSpaces := countSpaces()
		c, err := stdin.ReadByte()
		if c == '\n' || err != nil {
			fmt.Println(eval())
		}
		if err != nil {
			return
		}
		if c >= '0' && c <= '9' {
			if len(operands) > len(ops) {
				panic("too many operands")
			}
			operand := int32(c - '0')
			for {
				c, _ := stdin.ReadByte()
				if c < '0' || c > '9' {
					break
				}
				operand = 10 * operand + int32(c - '0')
			}
			stdin.UnreadByte()
			operands = append(operands, operand)
		} else if c == '+' || c == '-' || c == '*' || c == '/' {
			if len(operands) < len(ops) {
				panic("no operand")
			}
			trailingSpaces := countSpaces()
			var precedence uint
			if trailingSpaces > leadingSpaces {
				precedence = trailingSpaces
			} else {
				precedence = leadingSpaces
			}
			precedences = append(precedences, precedence)
			ops = append(ops, c)
		}
	}
}
