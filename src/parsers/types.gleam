pub type T {
  CurlyOpen
  CurlyClose
  BracketOpen
  BracketClose
  Colon
  Comma
  Str(String)
  Num(Int)
  Bool(Bool)
  Null
}

pub type Parser(a) {
  Parser(fn(ParserState) -> Result(ParseResult(a), String))
}

pub type ParseResult(n) {
  ParseResult(res: n, rem: String, idx: Int)
}

pub type ParserState {
  ParserState(str: String, idx: Int)
}

pub const digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
