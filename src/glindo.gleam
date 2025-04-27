import gleam/int
import gleam/io
import parsers/parser as p
import parsers/types as t

pub fn main() {
  let first = p.str("{")
  let mid = p.str("ansj")
  let last = p.str("}")
  let d1 = p.dgt(6)
  let d2 = p.dgt(8)
  let d3 = p.dgt(1)
  let sepr = p.btwn(first, mid, last)
  let _dgt_combinator = p.chc_of([d1, d2, d3])

  case p.run(sepr, "{an:7jsd789ansj 6jlsj ejesana}") {
    Error(e) -> io.println(e)
    Ok(t.ParseResult(res, _, idx)) -> {
      //p.print_array_string(res)
      io.println(res)
      io.println(int.to_string(idx))
    }
  }
}
