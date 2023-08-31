// Simple 2048 game for the terminal

use crossterm::{
    self, cursor,
    event::{read, Event, KeyCode},
    execute, queue, terminal,
};
use rand::Rng;
use std::{
    fmt,
    io::{self, Stdout, Write},
};

#[derive(Copy, Clone, PartialEq)]
enum Move {
    Left,
    Right,
    Up,
    Down,
}

impl TryFrom<KeyCode> for Move {
    type Error = ();
    fn try_from(value: KeyCode) -> Result<Self, Self::Error> {
        match value {
            KeyCode::Left | KeyCode::Char('a') => Ok(Move::Left),
            KeyCode::Right | KeyCode::Char('d') => Ok(Move::Right),
            KeyCode::Up | KeyCode::Char('w') => Ok(Move::Up),
            KeyCode::Down | KeyCode::Char('s') => Ok(Move::Down),
            _ => Err(()),
        }
    }
}

#[derive(PartialEq, Clone)]
struct Board {
    tiles: [[u8; 4]; 4],
}

impl Board {
    fn random_tile() -> u8 {
        if rand::thread_rng().gen_range(1..=10) == 10 {
            2
        } else {
            1
        }
    }
    fn place_random_tile(&mut self) {
        loop {
            let y = rand::thread_rng().gen_range(0..4);
            let x = rand::thread_rng().gen_range(0..4);
            if self.tiles[y][x] == 0 {
                self.tiles[y][x] = Self::random_tile();
                break;
            }
        }
    }
    fn init() -> Self {
        let mut this = Self { tiles: [[0; 4]; 4] };
        this.place_random_tile();
        this.place_random_tile();
        this
    }
    fn transpose(&mut self) {
        let tiles = &mut self.tiles;
        for y in 0..tiles.len() {
            for x in 0..y {
                (tiles[y][x], tiles[x][y]) = (tiles[x][y], tiles[y][x]);
            }
        }
    }
    fn reverse_rows(&mut self) {
        for row in self.tiles.as_mut() {
            row.reverse()
        }
    }
    fn move_left(&mut self) {
        for row in self.tiles.as_mut() {
            for x in 1..4 {
                let mut nx = x;
                while nx > 0 && row[nx - 1] == 0 {
                    nx -= 1;
                }
                if nx > 0 && row[nx - 1] == row[x] {
                    row[nx - 1] += 1;
                    row[x] = 0;
                } else if nx < x {
                    row[nx] = row[x];
                    row[x] = 0;
                }
            }
        }
    }
    fn make_move(&mut self, mov: Move) {
        match mov {
            Move::Left => self.move_left(),
            Move::Right => {
                self.reverse_rows();
                self.move_left();
                self.reverse_rows();
            }
            Move::Up => {
                self.transpose();
                self.move_left();
                self.transpose();
            }
            Move::Down => {
                self.transpose();
                self.reverse_rows();
                self.move_left();
                self.reverse_rows();
                self.transpose();
            }
        }
    }
    fn valid_moves(&self) -> impl Iterator<Item = &Move> {
        [Move::Left, Move::Right, Move::Up, Move::Down]
            .iter()
            .filter(|&&mov| {
                let mut clone = self.clone();
                clone.make_move(mov);
                clone != *self
            })
    }
    fn won(&self) -> bool {
        const TILE_2048: u8 = 11;
        self.tiles.iter().flatten().any(|&t| t == TILE_2048)
    }
}

// TODO (...) the hardcoded carriage returns for raw terminal mode feel dirty.
impl fmt::Display for Board {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let sep: String = "+----".repeat(4) + "+\r\n";
        for row in self.tiles {
            f.write_str(&sep)?;
            f.write_str(
                &(String::from("|")
                    + &row
                        .map(|tile| {
                            if tile == 0 {
                                "    ".into()
                            } else {
                                format!("{:^4}", (1 << tile).to_string())
                            }
                        })
                        .join("|")
                    + "|\r\n"),
            )?;
        }
        f.write_str(&sep)?;
        Ok(())
    }
}

struct RawTerminal {
    stdout: Stdout,
}
impl RawTerminal {
    fn init() -> Result<Self, io::Error> {
        terminal::enable_raw_mode()?;
        let mut stdout = io::stdout();
        execute!(
            stdout,
            terminal::EnterAlternateScreen,
            crossterm::cursor::Hide
        )?;
        Ok(Self { stdout })
    }
    fn queue_reset(&mut self) -> Result<(), io::Error> {
        queue!(
            self.stdout,
            terminal::Clear(terminal::ClearType::FromCursorUp),
            cursor::MoveTo(0, 0)
        )
    }
    fn flush(&mut self) -> Result<(), io::Error> {
        self.stdout.flush()
    }
}
impl Drop for RawTerminal {
    fn drop(&mut self) {
        execute!(
            self.stdout,
            crossterm::cursor::Show,
            terminal::LeaveAlternateScreen
        )
        .unwrap();
        terminal::disable_raw_mode().unwrap();
    }
}

enum GameOutcome {
    Win,
    Loss,
    Quit,
}

fn play() -> Result<GameOutcome, io::Error> {
    let mut terminal = RawTerminal::init()?;
    let mut board = Board::init();
    'game: loop {
        terminal.queue_reset()?;
        print!("{board}");
        print!("arrow keys or WASD to play, q to quit");
        terminal.flush()?;
        if board.won() {
            return Ok(GameOutcome::Win);
        }
        let valid_moves: Vec<&Move> = board.valid_moves().collect();
        if valid_moves.is_empty() {
            return Ok(GameOutcome::Loss);
        }
        let mov = loop {
            match read()? {
                Event::Key(event) => {
                    if event.code == KeyCode::Char('q') {
                        return Ok(GameOutcome::Quit);
                    }
                    if let Ok(mov) = Move::try_from(event.code) {
                        if valid_moves.contains(&&mov) {
                            break mov;
                        }
                    }
                }
                Event::Resize(_, _) => {
                    continue 'game;
                }
                _ => (),
            }
        };
        board.make_move(mov);
        board.place_random_tile();
    }
}

fn main() {
    let outcome = play().unwrap();
    println!(
        "{}",
        match outcome {
            GameOutcome::Win => "You win!",
            GameOutcome::Loss => "You lose!",
            GameOutcome::Quit => "quit",
        }
    );
}
