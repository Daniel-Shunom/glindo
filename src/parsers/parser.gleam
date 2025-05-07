import gleam/int
import gleam/io
import gleam/list
import gleam/option as opt
import gleam/string as s
import parsers/types as t

//================================================================================================
//                     PARSER FUNCTIONS
//================================================================================================
pub fn num() -> t.Parser(Int) {
  t.Parser(fn(state) { num_helper(s.to_graphemes(state.str), [], state) })
}

pub fn wht_space() -> t.Parser(String) {
  map(mny_of(t.Parser(fn(state) { wht_spc_helper(state) })), s.concat)
}

pub fn chr_grab() -> t.Parser(String) {
  t.Parser(fn(state) { chr_grab_helper(state) })
}

pub fn dgt(digit: Int) -> t.Parser(Int) {
  digit_panicker(digit)
  t.Parser(fn(state) { dgt_helper(digit, state) })
}

pub fn chr(pattern: String) -> t.Parser(String) {
  char_panicker(pattern)
  t.Parser(fn(state) { chr_helper(pattern, state) })
}

pub fn str(pattern: String) -> t.Parser(String) {
  t.Parser(fn(state) { str_helper(pattern, state) })
}

pub fn prefix_str(pattern: String) -> t.Parser(String) {
  t.Parser(fn(state) { prefix_str_helper(pattern, state) })
}

pub fn peek_fwd(parser: t.Parser(a)) -> t.Parser(a) {
  t.Parser(fn(state) { peek_fwd_helper(parser, state) })
}

pub fn lazy(thunk: fn() -> t.Parser(a)) -> t.Parser(a) {
  t.Parser(fn(state) { lazy_helper(state, thunk) })
}

pub fn mny_of(parser: t.Parser(a)) -> t.Parser(List(a)) {
  t.Parser(fn(state) { mny_helper(parser, [], state) })
}

pub fn chc_of(parserlist: List(t.Parser(a))) -> t.Parser(a) {
  t.Parser(fn(state) { chc_helper(parserlist, state) })
}

pub fn chc_opt(parserlist: List(t.Parser(a))) -> t.Parser(a) {
  t.Parser(fn(state) { chc_opt_helper(parserlist, state, []) })
}

pub fn opt_of(parser: t.Parser(a)) -> t.Parser(opt.Option(a)) {
  t.Parser(fn(state) { opt_helper(parser, state) })
}

pub fn map(parser: t.Parser(a), fnc: fn(a) -> b) -> t.Parser(b) {
  t.Parser(fn(state) { map_helper(parser, state, fnc) })
}

pub fn seq_of(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { seq_helper(parserlist, [], state) })
}

pub fn mny_chc(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { mny_chc_helper(parserlist, [], state) })
}

pub fn sep_by(item: t.Parser(a), sep: t.Parser(b)) -> t.Parser(List(a)) {
  t.Parser(fn(state) { sep_by_helper(item, sep, [], state) })
}

pub fn skip(parser1: t.Parser(a), parser2: t.Parser(b)) -> t.Parser(b) {
  bind(parser1, fn(_) { parser2 })
}

pub fn bind(parser: t.Parser(a), fnc: fn(a) -> t.Parser(b)) -> t.Parser(b) {
  t.Parser(fn(state) { bind_helper(parser, state, fnc) })
}

pub fn sat_pred(parser: t.Parser(a), fnc: fn(a) -> Bool) -> t.Parser(List(a)) {
  t.Parser(fn(state) { sat_pred_helper(parser, state, fnc, []) })
}

pub fn btwn(fst: t.Parser(a), mid: t.Parser(b), lst: t.Parser(c)) -> t.Parser(b) {
  btwn_helper(fst, mid, lst)
}

pub fn run(fnc: t.Parser(a), str: String) -> Result(t.ParseResult(a), String) {
  string_panicker(str)
  let t.Parser(p_fn) = fnc
  p_fn(t.ParserState(str: str, idx: 0))
}

pub fn tok(parser: t.Parser(a)) -> t.Parser(a) {
  use _ <- bind(wht_space())
  use res <- bind(parser)
  use _ <- map(wht_space())
  res
}

//================================================================================================
//                     MEMBER FUNCTIONS
//================================================================================================
fn char_panicker(str: String) -> Nil {
  case s.length(str) != 0 {
    True -> panic as "Error: more than 1 char detected"
    False -> Nil
  }
}

fn digit_panicker(dgt: Int) -> Nil {
  case dgt > 9 {
    True -> panic as "Error: multi-digit number found"
    False -> Nil
  }
}

fn string_panicker(str: String) -> Nil {
  case s.length(str) == 0 {
    True -> panic as "Error, empty string found"
    False -> Nil
  }
}

pub fn list_string_to_int(x: List(String)) -> Int {
  let assert Ok(number) = int.parse(s.concat(list.reverse(x)))
  number
}

pub fn list_int_to_string(list: List(Int)) -> String {
  s.concat(list.map(list, int.to_string))
}

pub fn print_array_string(list: List(String)) -> Nil {
  case list {
    [] -> Nil
    [str, ..rest] -> {
      io.println(str)
      print_array_string(rest)
    }
  }
}

fn idx(i: Int, l: List(String)) -> Int {
  i + s.length(s.concat(l))
}

fn prp(l: List(a), m: a) -> List(a) {
  list.prepend(l, m)
}

//================================================================================================
//                     HELPER FUNCTIONS
//================================================================================================
fn str_helper(
  pattern: String,
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  let invalid = "Error: did not find " <> pattern <> " in " <> state.str
  case s.starts_with(state.str, pattern) {
    False -> {
      case s.length(state.str) >= s.length(pattern) {
        False -> invalid |> Error
        True ->
          str_helper(
            pattern,
            t.ParserState(s.drop_start(state.str, 1), state.idx + 1),
          )
      }
    }
    True -> {
      let remaining = s.drop_start(state.str, s.length(pattern))
      t.ParseResult(
        res: pattern,
        rem: remaining,
        idx: state.idx + s.length(pattern),
      )
      |> Ok
    }
  }
}

fn prefix_str_helper(
  pattern: String,
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  case s.starts_with(state.str, pattern) {
    False -> { "Prefix" <> pattern <> "not found" } |> Error
    True ->
      t.ParseResult(
        res: pattern,
        rem: s.drop_start(state.str, s.length(pattern)),
        idx: state.idx + s.length(pattern),
      )
      |> Ok
  }
}

fn chr_helper(
  pattern: String,
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  let more_than_one = "Error: more than one char detected"
  let invalid = "Error: did not find " <> pattern <> " in " <> state.str
  case s.length(pattern) != 1 {
    True -> more_than_one |> Error
    False -> {
      case s.starts_with(state.str, pattern) {
        False -> invalid |> Error
        True -> {
          let remaining = s.drop_start(state.str, s.length(pattern))
          t.ParseResult(
            res: pattern,
            rem: remaining,
            idx: state.idx + s.length(pattern),
          )
          |> Ok
        }
      }
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
          t.ParseResult(res: digit, rem: new_rem, idx: state.idx + 1) |> Ok
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
    [] -> "invalid parse: empty string" |> Error
    [n, ..rest] -> {
      case list.contains(t.digits, n) {
        True ->
          num_helper(rest, prp(acc, n), t.ParserState(state.str, state.idx + 1))
        False -> {
          case acc {
            [] -> Error("no digit captured")
            _ ->
              t.ParseResult(
                list_string_to_int(acc),
                state.str,
                idx(state.idx, acc),
              )
              |> Ok
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
      t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      )
      |> Ok
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
    [] -> "No suitable parser found" |> Error
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(_) -> chc_helper(rest, state)
        Ok(result) -> result |> Ok
      }
    }
  }
}

fn chc_opt_helper(
  l_o_p: List(t.Parser(a)),
  state: t.ParserState,
  p_failed: List(t.Parser(a)),
) -> Result(t.ParseResult(a), String) {
  case l_o_p {
    [] -> "No suitable parser found" |> Error
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(_) ->
          chc_opt_helper(rest, state, list.append(p_failed, [t.Parser(p_fn)]))
        Ok(t.ParseResult(res, rem, idx)) ->
          case
            chc_opt_helper(
              list.append(l_o_p, p_failed),
              t.ParserState(str: rem, idx: idx),
              p_failed,
            )
          {
            Error(_) -> Ok(t.ParseResult(res, rem, idx))
            Ok(result) -> Ok(result)
          }
      }
    }
  }
}

fn mny_chc_helper(
  list_of_parsers: List(t.Parser(a)),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  case list_of_parsers {
    [] ->
      t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      )
      |> Ok
    [t.Parser(p_fn), ..rest] -> {
      case p_fn(state) {
        Error(_) -> mny_chc_helper(rest, accumulator, state)
        Ok(t.ParseResult(res, rem, idx)) -> {
          let new_acc = prp(accumulator, res)
          let new_state = t.ParserState(rem, idx)
          mny_chc_helper(list_of_parsers, new_acc, new_state)
        }
      }
    }
  }
}

fn mny_helper(
  parser: t.Parser(a),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Ok(t.ParseResult(res, rem, idx)) -> {
      let new_acc = prp(accumulator, res)
      let new_state = t.ParserState(rem, idx)
      mny_helper(parser, new_acc, new_state)
    }
    Error(_) ->
      t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      )
      |> Ok
  }
}

fn opt_helper(
  parser: t.Parser(a),
  state: t.ParserState,
) -> Result(t.ParseResult(opt.Option(a)), String) {
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Error(_) -> t.ParseResult(opt.None, state.str, state.idx) |> Ok
    Ok(t.ParseResult(res, rem, idx)) ->
      t.ParseResult(opt.Some(res), rem, idx) |> Ok
  }
}

fn sep_by_helper(
  item: t.Parser(a),
  sep: t.Parser(b),
  accumulator: List(a),
  state: t.ParserState,
) -> Result(t.ParseResult(List(a)), String) {
  let t.Parser(itm_fn) = item
  let t.Parser(sep_fn) = sep
  case itm_fn(state) {
    Error(_) ->
      t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      )
      |> Ok
    Ok(t.ParseResult(res1, rem1, idx1)) -> {
      let new_acc = prp(accumulator, res1)
      let new_state = t.ParserState(rem1, idx1)
      case sep_fn(new_state) {
        Error(_) ->
          t.ParseResult(
            res: list.reverse(new_acc),
            rem: new_state.str,
            idx: new_state.idx,
          )
          |> Ok
        Ok(t.ParseResult(_, rem2, idx2)) -> {
          let new_state2 = t.ParserState(rem2, idx2)
          sep_by_helper(item, sep, new_acc, new_state2)
        }
      }
    }
  }
}

fn bind_helper(
  parser: t.Parser(a),
  state: t.ParserState,
  fnc: fn(a) -> t.Parser(b),
) -> Result(t.ParseResult(b), String) {
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Error(e) -> Error(e)
    Ok(t.ParseResult(res, rem, idx)) -> {
      let next_parser = fnc(res)
      let t.Parser(n_fn) = next_parser
      t.ParserState(rem, idx) |> n_fn
    }
  }
}

fn map_helper(
  parser: t.Parser(a),
  state: t.ParserState,
  fnc: fn(a) -> b,
) -> Result(t.ParseResult(b), String) {
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Error(e) -> e |> Error
    Ok(t.ParseResult(res, rem, idx)) ->
      Ok(t.ParseResult(res: fnc(res), rem: rem, idx: idx))
  }
}

fn btwn_helper(
  first: t.Parser(b),
  between: t.Parser(a),
  last: t.Parser(c),
) -> t.Parser(a) {
  use _ <- bind(first)
  use x <- bind(between)
  map(last, fn(_) { x })
}

fn peek_fwd_helper(
  parser: t.Parser(a),
  state: t.ParserState,
) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Error(e) -> e |> Error
    Ok(t.ParseResult(res, ..)) ->
      t.ParseResult(res: res, rem: state.str, idx: state.idx)
      |> Ok
  }
}

fn lazy_helper(
  state: t.ParserState,
  thunk: fn() -> t.Parser(a),
) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = thunk()
  case p_fn(state) {
    Error(e) -> e |> Error
    Ok(k) -> k |> Ok
  }
}

fn sat_pred_helper(
  parser: t.Parser(a),
  state: t.ParserState,
  fnc: fn(a) -> Bool,
  accumulator: List(a),
) -> Result(t.ParseResult(List(a)), String) {
  let t.Parser(p_fn) = parser
  case s.length(state.str) == 0 {
    True ->
      t.ParseResult(
        res: list.reverse(accumulator),
        rem: state.str,
        idx: state.idx,
      )
      |> Ok
    False -> {
      case p_fn(state) {
        Error(_) ->
          t.ParseResult(
            res: list.reverse(accumulator),
            rem: state.str,
            idx: state.idx,
          )
          |> Ok
        Ok(t.ParseResult(res, rem, idx)) -> {
          case fnc(res) {
            False ->
              t.ParseResult(
                res: list.reverse(accumulator),
                rem: state.str,
                idx: state.idx,
              )
              |> Ok
            True -> {
              let new_state = t.ParserState(str: rem, idx: idx)
              let new_acc = prp(accumulator, res)
              sat_pred_helper(parser, new_state, fnc, new_acc)
            }
          }
        }
      }
    }
  }
}

fn chr_grab_helper(
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  case s.pop_grapheme(state.str) {
    Error(_) -> Error("Error: expected char, found none")
    Ok(#(char, rest)) ->
      t.ParseResult(res: char, rem: rest, idx: state.idx + 1) |> Ok
  }
}

fn wht_spc_helper(state: t.ParserState) -> Result(t.ParseResult(String), String) {
  let err = "Error: none whitespace character detected"
  case chr_grab_helper(state) {
    Error(e) -> Error(e)
    Ok(result) -> {
      case s.trim(result.res) == "" {
        False -> err |> Error
        True -> result |> Ok
      }
    }
  }
}
