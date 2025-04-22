import gleam/list
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

fn helper(
  list_of_parsers: List(t.Parser(a)),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  case list_of_parsers {
    [] -> Ok(t.ParseResult(res: accumulator, rem: state.str, idx: state.idx))
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(e) -> Error(e)
        Ok(t.ParseResult(res, rem, idx)) -> {
          let new_acc = list.append(accumulator, [res])
          let new_state = t.ParserState(rem, idx)
          helper(rest, new_acc, new_state)
        }
      }
    }
  }
}

pub fn seq_of(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { helper(parserlist, [], state) })
}

pub fn run(fnc: t.Parser(a), str: String) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = fnc
  p_fn(t.ParserState(str: str, idx: 0))
}
