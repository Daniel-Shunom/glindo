import gleam/int
import gleam/list
import gleam/string as s
import parsers/types as t

//================================================================================================
//                     PARSER FUNCTIONS (START)
//================================================================================================
pub fn num() -> t.Parser(Int) {
  t.Parser(fn(state) { num_helper(s.to_graphemes(state.str), [], state) })
}

pub fn dgt(digit: Int) -> t.Parser(Int) {
  t.Parser(fn(state) { dgt_helper(digit, state) })
}

pub fn str(pattern: String) -> t.Parser(String) {
  t.Parser(fn(state) { str_helper(pattern, state) })
}

pub fn chc_of(parserlist: List(t.Parser(a))) -> t.Parser(a) {
  t.Parser(fn(state) { chc_helper(parserlist, state) })
}

pub fn seq_of(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { seq_helper(parserlist, [], state) })
}

pub fn opt_of(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { opt_helper(parserlist, [], state) })
}

pub fn run(fnc: t.Parser(a), str: String) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = fnc
  p_fn(t.ParserState(str: str, idx: 0))
}

//================================================================================================
//                     MEMBER FUNCTIONS (START)
//================================================================================================
fn string_to_int(x: List(String)) -> Int {
  let assert Ok(number) = int.parse(s.concat(list.reverse(x)))
  number
}

fn prp(l: List(a), m: a) -> List(a) {
  list.prepend(l, m)
}

fn idx(i: Int, l: List(String)) -> Int {
  i + s.length(s.concat(l))
}

//================================================================================================
//                     HELPER FUNCTIONS (START)
//================================================================================================
fn str_helper(
  pattern: String,
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  let invalid = "Error: did not find " <> pattern <> " in " <> state.str
  case s.starts_with(state.str, pattern) {
    False -> {
      case s.length(state.str) >= s.length(pattern) {
        False -> Error(invalid)
        True ->
          str_helper(
            pattern,
            t.ParserState(s.drop_start(state.str, 1), state.idx + 1),
          )
      }
    }
    True -> {
      let remaining = s.drop_start(state.str, s.length(pattern))
      Ok(t.ParseResult(
        res: pattern,
        rem: remaining,
        idx: state.idx + s.length(pattern),
      ))
    }
  }
}

fn dgt_helper(
  digit: Int,
  state: t.ParserState,
) -> Result(t.ParseResult(Int), String) {
  case s.to_graphemes(state.str) {
    [] ->
      Error("Unexpected end of input; expected digit " <> int.to_string(digit))
    [head, ..rest] -> {
      let expected = int.to_string(digit)
      case head == expected {
        False -> dgt_helper(digit, t.ParserState(s.concat(rest), state.idx + 1))
        True -> {
          let new_rem = s.drop_start(state.str, 1)
          Ok(t.ParseResult(res: digit, rem: new_rem, idx: state.idx + 1))
        }
      }
    }
  }
}

fn num_helper(
  list_of_graphemes: List(String),
  acc: List(String),
  state: t.ParserState,
) -> Result(t.ParseResult(Int), String) {
  case list_of_graphemes {
    [] -> Error("invalid parse: empty string")
    [n, ..rest] -> {
      case list.contains(t.digits, n) {
        True ->
          num_helper(rest, prp(acc, n), t.ParserState(state.str, state.idx + 1))
        False -> {
          case acc {
            [] -> Error("no digit captured")
            _ ->
              Ok(t.ParseResult(
                string_to_int(acc),
                state.str,
                idx(state.idx, acc),
              ))
          }
        }
      }
    }
  }
}

fn seq_helper(
  list_of_parsers: List(t.Parser(a)),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  case list_of_parsers {
    [] ->
      Ok(t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      ))
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(e) -> Error(e)
        Ok(t.ParseResult(res, rem, idx)) -> {
          let new_acc = prp(accumulator, res)
          let new_state = t.ParserState(rem, idx)
          seq_helper(rest, new_acc, new_state)
        }
      }
    }
  }
}

fn chc_helper(
  list_of_parsers: List(t.Parser(a)),
  state: t.ParserState,
) -> Result(t.ParseResult(a), String) {
  case list_of_parsers {
    [] -> Error("No suitable parser found")
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(_) -> chc_helper(rest, state)
        Ok(result) -> Ok(result)
      }
    }
  }
}

//TODO -> this function is not purely optional. Fix it
fn opt_helper(
  list_of_parsers: List(t.Parser(a)),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  case list_of_parsers {
    [] ->
      Ok(t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      ))
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(_) -> opt_helper(rest, accumulator, state)
        Ok(t.ParseResult(res, rem, idx)) -> {
          let new_acc = prp(accumulator, res)
          let new_state = t.ParserState(rem, idx)
          opt_helper(list_of_parsers, new_acc, new_state)
        }
      }
    }
  }
}
