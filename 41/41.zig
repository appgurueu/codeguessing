// FALSE bytecode compiler & VM for round 41 of code guessing (https://cg.esolangs.gay/41/).
// Written by Lars Müller. Licensed under the MIT license.
// Compile using `zig build-exe 41.zig -O ReleaseFast -fstrip -fsingle-threaded`.

const std = @import("std");

const Allocator = std.mem.Allocator;

const Op = enum(u32) {
	// 🥺
	Push,
	GetReg,
	SetReg,
	// Stack reordering
	Dup,
	Drop,
	Swap,
	Rot,
	Index,
	// Binops
	Add,
	Sub,
	Mul,
	Div,
	And,
	Or,
	Eq,
	Gt,
	// Unops
	Inv,
	Neg,
	// Control flow
	Jmp,
	Call,
	CallIf,
	Ret,
	LoopSetup,
	LoopTest,
	LoopBody,
	// I/O
	ReadByte,
	WriteByte,
	WriteInt, // technically redundant (like plenty of other instructions too) but I'm too laziggy and performance or something
	Flush,
};

// teknikhally this is a bytecode builder - 🤓
const Bytecode = struct {
	allocator: Allocator,
	words: std.ArrayList(u32),
	pub fn init(allocator: Allocator) Bytecode {
		return Bytecode{.allocator = allocator, .words = std.ArrayList(u32).init(allocator)};
	}
	pub fn deinit(self: *Bytecode) void {
		self.words.deinit();
	}
	pub fn getWords(self: *Bytecode) []u32 {
		return self.words.items;
	}
	fn emit(self: *Bytecode, op: Op) !void {
		try self.words.append(@intFromEnum(op));
	}
	fn emitToPatch(self: *Bytecode) !usize {
		try self.words.append(0xDEADBEEF);
		return self.words.items.len - 1;
	}
	fn patch(self: *Bytecode, i: usize, u: u32) void {
		self.words.items[i] = u;
	}
	fn emitPush(self: *Bytecode, u: u32) !void {
		try self.emit(.Push);
		try self.words.append(u);
	}
	fn append(self: *Bytecode, other: Bytecode) !u32 {
		const nextPos: u32 = @intCast(self.words.items.len);
		try self.words.appendSlice(other.words.items);
		return nextPos;
	}
};

// shot🔫 parser & bytecode emitter
fn Compiler(comptime R: type) type {
	return struct {
		const Self = @This();
		allocator: Allocator,
		in: R,
		b: ?u8 = null,
		bytecode: Bytecode,
		pub fn init(allocator: Allocator, in: R) Self {
			return Self{.allocator = allocator, .in = in, .bytecode = Bytecode.init(allocator)};
		}
		pub fn reset(self: *Self) void {
			self.b = null;
			self.bytecode = Bytecode.init(self.allocator);
		}
		pub fn deinit(self: *Self) void {
			self.bytecode.deinit();
		}

		fn readByte(self: *Self) !u8 {
			const b = self.b;
			if (b == null)
				return self.in.readByte();
			self.b = null;
			return b.?;
		}
		fn unreadByte(self: *Self, b: u8) void {
			self.b = b;
		}

		pub fn compileFn(self: *Self) !u32 {
			var bytecode = Bytecode.init(self.allocator);
			defer bytecode.deinit();
			while (true) {
				const b = self.readByte() catch |err| {
					if (err == error.EndOfStream) break;
					return err;
				};
				try switch (b) {
					'\t', ' ', '\n' => {},
					'{' => while (try self.readByte() != '}') {},
					'"' => while (true) {
						const quotedB = try self.readByte();
						if (quotedB == '"') break;
						try bytecode.emitPush(@as(u32, quotedB));
						try bytecode.emit(.WriteByte);
					},
					'\'' => {
						const quotedB = try self.readByte();
						try bytecode.emitPush(@as(u32, quotedB));
					},
					'0' ... '9' => {
						var u: u32 = b - '0';
						var nb: u8 = undefined;
						while (true) {
							nb = self.readByte() catch |err| {
								if (err == error.EndOfStream) break;
								return err;
							};
							if (nb < '0' or nb > '9') break;
							u = 10 * u + nb - '0';
						}
						self.unreadByte(nb);
						try bytecode.emitPush(u);
					},
					'a' ... 'z' => try bytecode.emitPush(@as(u32, b - 'a')),
					'[' => {
						try bytecode.emit(.Push);
						const i = try bytecode.emitToPatch();
						bytecode.patch(i, try self.compileFn());
						if (try self.readByte() != ']') return error.UnclosedQuote;
					},
					']' => {
						self.unreadByte(']');
						break;
					},
					'!' => bytecode.emit(.Call),
					'?' => bytecode.emit(.CallIf),
					'#' => {
						// too laziggy to relocate addresses for jumps so here you go, loops get three instructions
						for ([_]Op{.LoopSetup, .LoopTest, .LoopBody}) |op| try bytecode.emit(op);
					},
					else => try bytecode.emit(switch (b) {
						';' => .GetReg,
						':' => .SetReg,
						'$' => .Dup,
						'%' => .Drop,
						'\\' => .Swap,
						'@' => .Rot,
						'O' => .Index,
						'+' => .Add,
						'-' => .Sub,
						'/' => .Div,
						'*' => .Mul,
						'|' => .Or,
						'&' => .And,
						'=' => .Eq,
						'>' => .Gt,
						'~' => .Inv,
						'_' => .Neg,
						'^' => .ReadByte,
						',' => .WriteByte,
						'.' => .WriteInt,
						'B' => .Flush,
						else => return error.InvalidInstruction, // includes '`'
					}),
				};
			}
			try bytecode.emit(.Ret);
			return try self.bytecode.append(bytecode);
		}
		pub fn compile(self: *Self) !Bytecode {
			try self.bytecode.emit(.Push);
			const i = try self.bytecode.emitToPatch();
			try self.bytecode.emit(.Jmp);
			self.bytecode.patch(i, try self.compileFn());
			const bytecode = self.bytecode;
			self.reset();
			return bytecode;
		}
	};
}

// we skimp on error checking here (gotta go fast);
// FALSE programmers can be trusted to not ever make oopsies
// thus there is no typechecking (num/quote/char/reg etc.) here,
// no bounds checking, no stack overflow or underflow checking
// (Zig will trap the "unreachable" code though)
fn VM(comptime R: type, comptime W: type) type {
	return struct {
		const Self = @This();
		stack: std.ArrayList(u32),
		retstack: std.ArrayList(u32),
		regs: [32]u32 = undefined, // did you want zeroes? no zeroes for you.
		// i already gifted you a few registers, be grateful!
		in: R,
		out: W,
		pub fn init(allocator: Allocator, in: R, out: W) Self {
			return Self{
				.stack = std.ArrayList(u32).init(allocator),
				.retstack = std.ArrayList(u32).init(allocator),
				.in = in,
				.out = out,
			};
		}
		pub fn deinit(vm: *Self) void {
			vm.flush();
			vm.stack.deinit();
			vm.retstack.deinit();
		}
		fn pop(vm: *Self) u32 {
			return vm.stack.pop(); // what is an error?
		}
		fn push(vm: *Self, u: u32) void {
			vm.stack.append(u) catch unreachable; // gotta go fast
		}
		fn drop(vm: *Self) void {
			_ = vm.pop();
		}
		fn dup(vm: *Self) void {
			vm.push(vm.stack.getLast());
		}
		fn swap(vm: *Self) void {
			const top = vm.pop();
			const bot = vm.pop();
			vm.push(top);
			vm.push(bot);
		}
		fn rot(vm: *Self) void {
			const top = vm.pop();
			const mid = vm.pop();
			const bot = vm.pop();
			vm.push(mid);
			vm.push(top);
			vm.push(bot);
		}
		fn index(vm: *Self) void {
			const j = vm.pop();
			const i = vm.stack.items.len - j - 1;
			vm.push(vm.stack.items[i]); // what is an OOB
		}

		fn binop(vm: *Self, comptime op: fn(lhs: u32, rhs: u32) u32) void {
			const rhs = vm.pop();
			const lhs = vm.pop();
			vm.push(op(lhs, rhs));
		}
		// u32, i32, it's all the same (modular arithmetic says hi)
		fn add(lhs: u32, rhs: u32) u32 { return lhs +% rhs; }
		fn sub(lhs: u32, rhs: u32) u32 { return lhs -% rhs; }
		fn mul(lhs: u32, rhs: u32) u32 { return lhs *% rhs; }
		fn div(lhs: u32, rhs: u32) u32 { return @divTrunc(lhs, rhs); }
		fn band(lhs: u32, rhs: u32) u32 { return lhs & rhs; }
		fn bor(lhs: u32, rhs: u32) u32 { return lhs | rhs; }
		fn eq(lhs: u32, rhs: u32) u32 { return if (lhs == rhs) ~@as(u32, 0) else 0; }
		// okay *maybe* i lied and it's not quite as shrimple
		fn gt(lhs: u32, rhs: u32) u32 {
			// *portability* rules so let's write some inefficient branching code
			const sl = lhs >> 31;
			const sr = rhs >> 31;
			return if (if (sl == sr) lhs > rhs else sl < sr) ~@as(u32, 0) else 0;
		}

		fn unop(vm: *Self, comptime op: fn(i: u32) u32) void { vm.push(op(vm.pop())); }
		fn negate(i: u32) u32 { return 1 +% ~i; } // you should have recognized this!
		fn invert(i: u32) u32 { return ~i; }

		fn getReg(vm: *Self) void {
			const i = vm.pop();
			vm.push(vm.regs[@intCast(i)]); // OOBs don't happen, do they?
		}
		fn setReg(vm: *Self) void {
			const i = vm.pop();
			const v = vm.pop();
			vm.regs[@intCast(i)] = v;
		}

		fn readByte(vm: *Self) void {
			// no distinguishing EOF and other "errors" because yes
			vm.push(vm.in.readByte() catch ~@as(u32, 0));
		}
		fn _writeByte(vm: *Self, b: u8) void {
			const bs = [_]u8{b};
			// should we assert that it wrote exactly one character?
			_ = vm.out.write(bs[0..]) catch unreachable; // nah, nothing will go wrong.
		}
		fn writeByte(vm: *Self) void {
			vm._writeByte(@truncate(vm.pop()));
		}
		fn writeInt(vm: *Self) void {
			var i = vm.pop();
			const negative = i >> 31 == 1;
			if (negative) {
				vm._writeByte('-');
				i = 1 + ~i;
			}
			// maybe i should look up the library function for this
			var buf: [16]u8 = undefined;
			var j: u8 = 0;
			while (true) {
				buf[j] = @truncate(i % 10);
				j += 1;
				i = @divTrunc(i, 10);
				if (i == 0) break;
			}
			while (true) {
				j -= 1;
				vm._writeByte(buf[j] + '0');
				if (j == 0) break;
			}
		}
		fn flush(vm: *Self) void {
			vm.out.flush() catch unreachable;
		}
		
		pub fn run(vm: *Self, bytecode: []const u32) void {
			vm.retstack.append(@intCast(bytecode.len)) catch unreachable; // main func returning should end the program not pop an empty stack
			var ip: u32 = 0;
			while (ip < bytecode.len) {
				const op: Op = @enumFromInt(bytecode[ip]);
				switch (op) {
					// Control flow
					.Push => {
						vm.push(bytecode[ip + 1]); // surely this won't OOB
						ip += 2;
						continue;
					},
					.Jmp => {
						ip = vm.pop();
						continue;
					},
					.Call => {
						vm.retstack.append(ip + 1) catch unreachable;
						ip = vm.pop();
						continue;
					},
					.Ret => {
						ip = vm.retstack.pop();
						continue;
					},
					.CallIf => {
						const q = vm.pop();
						const v = vm.pop();
						if (v != 0) {
							vm.retstack.append(ip + 1) catch unreachable; // gotta go fast
							ip = q;
							continue;
						}
					},
					.LoopSetup => {
						const body = vm.pop();
						const cond = vm.pop();
						vm.retstack.append(body) catch unreachable;
						vm.retstack.append(cond) catch unreachable;
					},
					.LoopTest => {
						const cond = vm.retstack.getLast();
						vm.retstack.append(ip + 1) catch unreachable; // gotta go fast
						ip = cond;
						continue;
					},
					.LoopBody => {
						if (vm.pop() != 0) {
							const body = vm.retstack.items[vm.retstack.items.len - 2];
							vm.retstack.append(ip - 1) catch unreachable; // this is a sneaky one
							ip = body;
							continue;
						}
						// pop cond & body
						_ = vm.retstack.pop();
						_ = vm.retstack.pop();
					},
					// everything else
					.Dup => vm.dup(),
					.Drop => vm.drop(),
					.Swap => vm.swap(),
					.Rot => vm.rot(),
					.Index => vm.index(),
					.Add => vm.binop(add),
					.Sub => vm.binop(sub),
					.Mul => vm.binop(mul),
					.Div => vm.binop(div),
					.And => vm.binop(band),
					.Or => vm.binop(bor),
					.Eq => vm.binop(eq),
					.Gt => vm.binop(gt),
					.Neg => vm.unop(negate),
					.Inv => vm.unop(invert),
					.GetReg => vm.getReg(),
					.SetReg => vm.setReg(),
					.ReadByte => vm.readByte(),
					.WriteByte => vm.writeByte(),
					.WriteInt => vm.writeInt(),
					.Flush => vm.flush(),
				}
				ip += 1;
			}
		}
	};
}

pub fn main() !void {
	var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
	defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
	const gpa = general_purpose_allocator.allocator();

	var args = try std.process.argsWithAllocator(gpa);
	defer args.deinit();
	if (!args.skip()) return error.InvalidUsage;
	const path = args.next();
	if (path == null) return error.InvalidUsage;
	var file = try std.fs.cwd().openFile(path.?, .{});
	defer file.close();
	var buf = std.io.bufferedReader(file.reader());
	var in = buf.reader();

	var compiler = Compiler(@TypeOf(in)).init(gpa, in);
	defer compiler.deinit();
	var bytecode = try compiler.compile();
	defer bytecode.deinit();

	var bufStdin = std.io.bufferedReader(std.io.getStdIn().reader());
	var stdinReader = bufStdin.reader();
	var bufStdout = std.io.bufferedWriter(std.io.getStdOut().writer());
	var vm = VM(@TypeOf(stdinReader), @TypeOf(bufStdout)).init(gpa, stdinReader, bufStdout);
	defer vm.deinit();
	vm.run(bytecode.getWords());
}
