import gleam/int
import gleam/io
import gleam/string
import parsers/parser as p
import parsers/types as t

pub fn main() {
  let p1 = t.Parser(p.str("tra"))
  let p2 = t.Parser(p.str("nsf"))
  let p3 = t.Parser(p.str("orm"))
  let p_combinator = p.seq_of([p1, p2, p3])

  case p.run(p_combinator, "transformer") {
    Ok(t.ParseResult(res, rem, idx)) -> {
      let matched = string.concat(res)
      io.println(
        "Matched so far: " <> matched <> "  (idx=" <> int.to_string(idx) <> ")",
      )
      io.println("Remaining input: " <> rem)
    }
    Error(e) -> io.println(e)
  }
}
