import gleam/int
import gleam/io
import parsers/parser as p
import parsers/types as t

pub fn main() {
  let x = p.str("tra")
  let y = p.str("nsl")
  case p.run(t.Parser(x), "translormer") {
    Ok(k) -> {
      io.println(k.res <> int.to_string(k.idx))
      case p.run(t.Parser(y), k.rem) {
        Ok(m) -> io.println(m.res <> int.to_string(m.idx))
        Error(n) -> io.println(n)
      }
    }
    Error(e) -> io.println(e)
  }
}
