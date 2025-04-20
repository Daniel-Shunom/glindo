import gleam/string
import parsers/types as t

pub fn str(
  str: String,
) -> fn(t.ParserState) -> Result(t.ParseResult(String), String) {
  fn(var: t.ParserState) {
    let invalid = "Invalid Match: " <> var.str <> " does not start with " <> str
    case string.starts_with(var.str, str) {
      True -> {
        Ok(t.ParseResult(
          res: str,
          rem: string.drop_start(var.str, string.length(str)),
          idx: var.idx + string.length(str),
        ))
      }
      False -> Error(invalid)
    }
  }
}

pub fn run(fnc: t.Parser(a), str: String) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = fnc
  p_fn(t.ParserState(str: str, idx: 0))
}
