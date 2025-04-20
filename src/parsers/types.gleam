pub type JsonValue {
  JsonBool(Bool)
  JsonNull
  JsonString(String)
  JsonNumber(Int)
  JsonArray(List(JsonValue))
  JsonObject(List(#(String, JsonValue)))
}

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

pub type ParseProps {
  ParseProps(char: String, ref_ct: Int)
}

pub type ParseResult(n) {
  ParseResult(res: n, rem: String, idx: Int)
}

pub type ParserState {
  ParserState(str: String, idx: Int)
}

pub type JsonError(str) {
  JsonError(message: str)
}
