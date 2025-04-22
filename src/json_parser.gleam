import gleam/int
import gleam/io
import gleam/string
import parsers/parser as p
import parsers/types as t

pub fn main() {
  let p1 = p.str("tra")
  let p2 = p.str("nsf")
  let p3 = p.str("orm")
  let d1 = p.dgt(6)
  let p_combinator = p.seq_of([p1, p2, p3])

  case p.run(p_combinator, "transformer") {
    Error(e) -> io.println(e)
    Ok(t.ParseResult(res, rem, idx)) -> {
      let matched = string.concat(res)
      io.println(
        "Matched so far: " <> matched <> "  (idx=" <> int.to_string(idx) <> ")",
      )
      io.println("Remaining input: " <> rem)
    }
  }

  case p.run(d1, "6Daniel 6 1jeremia34h variable90") {
    Error(e) -> io.println(e)
    Ok(t.ParseResult(res, _, _)) ->
      io.println("Matched so far: " <> int.to_string(res))
  }
}
