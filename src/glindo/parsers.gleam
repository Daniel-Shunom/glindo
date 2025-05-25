//// ## Primitives and Combinators
//// Parser functions are function that take some state
//// and return a function that parses a string for that
//// state.
//// 
//// All parsers are curried functions that return a 
//// function that takes in the input state. For 
//// convenience, the `run()` method can be used to build the
//// state and `run()` the function
//// 
//// Unless you are composing parsers or performing any 
//// other activity, It is better to use the `run()` method
//// with the curried function.
//// 
//// Parsers can either be run by themselves with a constructed `ParserState(a)`,
//// or called using the `run()` function which will build the `ParserState(a)` for 
//// you. The `run()` function takes in the returned parser function and the 
//// string to parse with and has the signature `run(Parser(a), String)`

import gleam/int
import gleam/io
import gleam/list
import gleam/option as opt
import gleam/string as s
import glindo/types as t

//================================================================================================
//                     PARSER FUNCTIONS
//================================================================================================

/// Parses numbers at the start of a string and returns a 
/// `Result(ParseResult(Int), String)`.
/// 
/// ## Examples
/// 
/// ```gleam
/// run(num(), "123abc")
/// // -> Ok(ParseResult(res: 123, rem: "abc", idx: 3))
/// ```
/// 
/// ```gleam
/// run(num(), "abc123")
/// // -> Error("Error: no number captured")
/// ```
pub fn num() -> t.Parser(Int) {
  t.Parser(fn(state) { num_helper([], state) })
}

/// Parses single white space " " and "\t" white-space characters
/// at the beginning of a string and returns a `Result(ParseResult(String), String)`
/// 
/// When there is no white space character, wht_spc simply returns
/// and `Ok(ParseResult(String))` with no updates to the original ParseState variables.
/// 
/// ## Examples
/// 
/// ```gleam
/// run(wht_space(), "\tstarting white-space")
/// // -> Ok(ParseResult(res: "\t", rem: "starting white-space", idx: 1))
/// ```
/// 
/// ```gleam
/// run(wht_space(), "no white-space")
/// // -> Ok(ParseResult(res: "", rem: "no white-space", idx: 0))
/// ```
pub fn wht_space() -> t.Parser(String) {
  map(mny_of(t.Parser(fn(state) { wht_spc_helper(state) })), s.concat)
}

/// Parses for the first character in a string and returns a
/// `Result(ParseResult(String), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// run(chr_grab(), "character")
/// // -> Ok(ParseResult(res: "c", rem: "haracter", idx: 1))
/// ```
/// 
/// ```gleam
/// run(chr_grab(), "")
/// // -> Error("Error: expected char, found none")
/// ```
pub fn chr_grab() -> t.Parser(String) {
  t.Parser(fn(state) { chr_grab_helper(state) })
}

/// Parses a string for the first character as a single digit and 
/// Returns a `Result(ParseResult(Int), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// run(dgt(7), "7 is a prime number")
/// // -> Ok(res: 7, rem: " is a prime number", idx: 1)
/// ```
/// 
/// ```gleam
/// run(dgt(6), "There is no 6 here")
/// // -> Error("Error: expected '6' found 'T'")
/// ```
pub fn dgt(digit: Int) -> t.Parser(Int) {
  t.Parser(fn(state) { dgt_helper(digit, state) })
}

/// Parses for the specified character as first character in a string 
/// and returns a `Result(ParseResult(String), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// run(chr_grab(c), "character")
/// // -> Ok(ParseResult(res: "c", rem: "haracter", idx: 1))
/// ```
/// 
/// ```gleam
/// run(chr(x), "dogs are cool")
/// // -> Error("Error: did not find 'x' at 'dogs are cool")
/// ```
pub fn chr(pattern: String) -> t.Parser(String) {
  char_panicker(pattern)
  t.Parser(fn(state) { chr_helper(pattern, state) })
}

/// Parses a string for a given substring at the start of the string and
/// returns a `Result(ParseResult(String), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// run(str("race"), "racecars are cool")
/// // -> Ok(ParseResult(res: "race", rem: "cars are cool", idx: 4))
/// ```
/// 
/// ```gleam
/// run(str(spoon), "grasshoppers suck")
/// // -> Error("Error: given string does not start with 'spoon'")
/// ```
pub fn str(pattern: String) -> t.Parser(String) {
  t.Parser(fn(state) { str_helper(pattern, state) })
}

/// Parses a string for a given substring at the start of the string and
/// returns a `Result(ParseResult(String), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// run(prefix_str("race"), "racecars are cool")
/// // -> Ok(ParseResult(res: "race", rem: "cars are cool", idx: 4))
/// ```
/// 
/// ```gleam
/// run(prefix_str(spoon), "grasshoppers suck")
/// // -> Error("Error: given string does not start with 'spoon'")
/// ```
pub fn prefix_str(pattern: String) -> t.Parser(String) {
  t.Parser(fn(state) { prefix_str_helper(pattern, state) })
}

/// Takes in a parser and looks ahead for the result of the successfully 
/// ran parser value and returns a `Result(ParseResult(a), String)`.
/// 
/// It is generic and can take in any `Parser(a)` kind.
/// 
/// ## Example
/// 
/// ```gleam
/// peek_fwd(str("goat cheese"))
/// |> run("goat cheese tastes good")
/// // -> Ok(ParseResult("goat cheese", "goat cheese tastes good", 0))
/// ```
/// 
/// ```gleam
/// peek_fwd(str("goat cheese"))
/// |> run("Bungee gum is somewhat rubber")
/// // -> Error("Error: given string does not start with 'rubber'")
/// ```
pub fn peek_fwd(parser: t.Parser(a)) -> t.Parser(a) {
  t.Parser(fn(state) { peek_fwd_helper(parser, state) })
}

// TODO -> write test
/// Defers construction of a parser until parse time, allowing you to write
/// recursive or mutually-recursive grammars without forward declaration errors.
/// 
/// ## Example
/// 
/// ```gleam
/// // A very simple recursive “nesting” grammar
/// let rec nested() = lazy(fn() {
///   btwn(chr("("), nested(), chr(")"))
/// })
///
/// run(nested(), "((()))")
/// // -> Ok(ParseResult(res: "()", rem: ")", idx: 4))  // can now handle recursion
/// ```
///
/// Returns a `Parser(a)` that, when run, calls your thunk to get the real parser.
pub fn lazy(thunk: fn() -> t.Parser(a)) -> t.Parser(a) {
  t.Parser(fn(state) { lazy_helper(state, thunk) })
}

/// Repeats runs a parser on a string until it "fails". `mny_of` always succeeds
/// and always returns a `ParseResult(List(a))`.
/// 
/// It is generic and can take in any parser kind.
/// 
/// ## Example
/// 
/// ```gleam
/// mny_of(chr(a))
/// |> run("aadvarks are cool")
/// // -> ParseResult(res: ["a", "a"], rem: "varks are cool", idx: 2)
/// ```
/// 
/// ```gleam
/// mny_of(chr(a))
/// |> run("bojack is a bad horse")
/// // -> ParseResult(res: [], rem: "bojack is a bad horse", idx: 0)
/// ```
pub fn mny_of(parser: t.Parser(a)) -> t.Parser(List(a)) {
  t.Parser(fn(state) { mny_helper(parser, [], state) })
}

/// This combinator is designed to combine multiple parsers into one. It
/// takes in a list of parsers of generic type `Parser(a)` and returns a parser 
/// that runs them in order. If one fails, the next successful parser is chosen 
/// to run. If no parser in the list succeeds, it returns an Error.
/// 
/// chc_of can only take in a list of parsers of the same type.
/// 
/// ## Example
/// 
/// ```gleam
/// chc_of([str("low"), chr("-"), str("hi")])
/// |> run("hi-five's for you")
/// // -> Ok(ParseResult(res: "hi", rem: "-five's for you", idx: 2))
/// ```
/// 
/// ```gleam
/// chc_of([str("low"), chr("-"), str("hi")])
/// |> run("down low too slow")
/// // -> Error("Error: no suitable parser found")
/// ```
pub fn chc_of(parserlist: List(t.Parser(a))) -> t.Parser(a) {
  t.Parser(fn(state) { chc_helper(parserlist, state) })
}

// TODO -> write test
/// Tries each parser in turn, but unlike `chc_of` then picks the one
/// that consumed the most input. If none succeed, returns an Error.
/// 
/// Useful for “longest‐match” disambiguation when two parsers both
/// succeed but one should win because it reads further.
/// 
/// ## Example
/// 
/// ```gleam
/// let p1 = str("foo")
/// let p2 = str("foobar")
/// |> chc_opt([p1, p2])
///
/// run(p, "foobarbaz")
/// // -> Ok(ParseResult(res: "foobar", rem: "baz", idx: 6))
/// ```
///
/// Returns a `Parser(a)` which on success has parsed as far as possible.
pub fn chc_opt(parserlist: List(t.Parser(a))) -> t.Parser(a) {
  t.Parser(fn(state) { chc_opt_helper(parserlist, state, []) })
}

/// Takes in a parser of type `Parser(a), runs the parser, and returns 
/// a `ParseResult(Option(a))` of the parser. opt_of always succeeds and 
/// cannot return an Error type.
/// 
/// ## Example
/// 
/// ```gleam
/// opt_of(p.num())
/// |> run("1500 SAT isn't bad lmao")
/// // -> Ok(ParseResult(res: Some(1500), rem: " SAT isn't bad lmao", idx: 4))
/// ```
/// 
/// ```gleam
/// opt_of(p.num())
/// |> run("but a 600 is crazy")
/// // -> Ok(ParseResult(res: None, rem: "but a 600 is crazy", idx: 0))
/// ```
pub fn opt_of(parser: t.Parser(a)) -> t.Parser(opt.Option(a)) {
  t.Parser(fn(state) { opt_helper(parser, state) })
}

/// This combinator is designed to transform parsers. The parser combinator
/// takes in a parser of type `Parser(a)` and a function that transforms `a` to `b`
/// to then return a parser of type `Parser(b)`. This can be used to transform one
/// function to another using the transformation function as some "bridge" for the
/// computation.
/// 
/// ## Example
/// 
/// ```gleam
/// map(num(), fn(number) { int.to_base16(number) })
/// |> run("2024 was wild ngl")
/// // -> Ok(ParseResult(res: 7E8, rem: " was wild ngl", idx: 4))
/// ```
/// 
/// ```gleam
/// map(chr_grab, fn(char) { string.to_utf_codepoints(char) })
/// |> run("2024 was wild ngl")
/// // -> Ok(ParseResult(res: 7E8, rem: " was wild ngl", idx: 4))
/// ```
pub fn map(parser: t.Parser(a), fnc: fn(a) -> b) -> t.Parser(b) {
  t.Parser(fn(state) { map_helper(parser, state, fnc) })
}

/// This combinator takes a list of parsers of the same type, runs each parser 
/// sequentially, and returns a parser that parses a string for the result of the 
/// sequential parser. If one parser in the sequence fails, the entire parser fails. 
/// The resulting parser returns a `Result(ParseResult(a), String)`
/// 
/// ## Example
/// 
/// ```gleam
/// seq_of([str(hi), chr(-), str(five)])
/// |> run("hi-five's for the good job")
/// // Ok(ParseResult(res: ["hi", "-", "five"], rem: "'s for the good job", idx: 7))
/// ```
/// 
/// ```gleam
/// seq_of([str("nuh-uh"), chr(" "), str("bro")])
/// |> run("What do you mean by that?")
/// // -> Error("Error: could not match parser sequence")
pub fn seq_of(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { seq_helper(parserlist, [], state) })
}

// TODO -> write test
/// Repeats “choice” among the given parsers zero or more times, collecting
/// each successful result into a list. Always succeeds (even if no parser
/// ever matches) and returns the list of all matches in order.
/// 
/// ## Example
/// ```gleam
/// // Parses any number of “a” or “b” in any order
/// let p = mny_chc([chr("a"), chr("b")])
///
/// run(p, "abbaacxyz")
/// // -> Ok(ParseResult(res: ["a","b","b","a","a","c"], rem: "xyz", idx: 6))
/// ```
///
/// Returns a `Parser(List(a))` with all values parsed in sequence.
pub fn mny_chc(parserlist: List(t.Parser(a))) -> t.Parser(List(a)) {
  t.Parser(fn(state) { mny_chc_helper(parserlist, [], state) })
}

/// This combinator takes in two parsers generic over type `a` and `b`. `Parser(a)` 
/// parses a string for its desired result, and `Parser(b)`, if successfull, is 
/// skipped and returns a `Ok(ParseResult(List(a)))`. This parser always succeeds 
/// and always returns a `Ok(ParseResult(List(a)))`.
/// 
/// This is generic over `a` and `b`.
/// 
/// ## Example
/// 
/// ```gleam
/// sat_pred(chr_grab, fn(chr) { chr != "," })
/// |> sep(str(","))
/// |> run("eggs, bacon, and more")
/// // -> Ok(ParseResult(res: ["eggs", " bacon", " and more"], rem: "", idx: 21))
/// ```
/// 
/// ```gleam
/// sat_pred(chr_grab, fn(chr) { chr != "," })
/// |> sep(str(","))
/// |> run("No seperator yet")
/// // -> Ok(ParseResult(res: ["No seperator yet"], rem: "", idx: 16))
/// ```
pub fn sep_by(item: t.Parser(a), sep: t.Parser(b)) -> t.Parser(List(a)) {
  t.Parser(fn(state) { sep_by_helper(item, sep, [], state) })
}

/// This combinator takes in two parsers generic over type `a` and `b` respectively. 
/// This returns a parser that runs the first parser. if successful, the result of the 
/// first parser is ignored and the second parser is run. This function returns a 
/// function of return type `Result(ParseResult(b), String)`.
/// 
/// ## Example
/// 
/// ```gleam
/// skip(str("yo"), str("gurt"))
/// |> run("yogurt, what's up dude")
/// // -> Ok(ParseResult(res: "gurt", rem: ", what's up dude", idx: 6))
/// ```
/// 
/// ```gleam
/// skip(str("yo"), str("gurt"))
/// |> run("hey gurt, what's up dude")
/// // -> Error("Error: given string does not start with 'yo'")
pub fn skip(parser1: t.Parser(a), parser2: t.Parser(b)) -> t.Parser(b) {
  bind(parser1, fn(_) { parser2 })
}

/// This generic parser-combinator takes a parser and on a successful run, takes the result
/// of that parser, feeds it into a function that takes in `a` and use it to construct a 
/// parser of type `b`.
/// 
/// ## Example
/// 
/// ```gleam
/// bind(str("Chicken"), fn(_) { chr_grab() })
/// |> run("chicken-farm")
/// // -> Ok(ParseResult(res: "-", rem: "farm", idx: 8))
/// ```
/// 
/// ```gleam
/// bind(str("Chicken"), fn(_) { chr_grab() })
/// |> run("chicken-farm")
/// // -> Ok(ParseResult(res: "-", rem: "farm", idx: 8))
/// ```
pub fn bind(parser: t.Parser(a), fnc: fn(a) -> t.Parser(b)) -> t.Parser(b) {
  t.Parser(fn(state) { bind_helper(parser, state, fnc) })
}

/// This generic combinator over type `a` takes a parser of type `Parser(a)` and a boolean 
/// function. The parser result will only be returned for values that satisfy the predicate.
///
/// ## Example
/// 
/// ```gleam
/// seq_of([chr("b"), chr("o"), chr("b")])
/// |> map(fn(list_chr){ string.concat(list_chr) })
/// |> sat_pred(fn(chr) { chr == "bob" })
/// |> run("bobbit is nice")
/// // -> Ok(ParseResult(res: "bob", rem: "bit is nice", idx: 3))
/// ```
/// 
/// ```gleam
/// sat_pred(num(), fn(num) { num < 5 })
/// |> run("6 cold cans of soda")
/// // -> Error("Error: unsatisfied predicate") 
/// ```
pub fn sat_pred(parser: t.Parser(a), fnc: fn(a) -> Bool) -> t.Parser(a) {
  t.Parser(fn(state) { sat_pred_helper(parser, state, fnc) })
}

/// This generic combinator takes in three parsers generic over type `a`, `b`, `c`, and returns 
/// a parser that separates the result of the middle parser, after the first and last parser 
/// have successfully run. This parser returns a type `Result(ParseResult(b), String)`
/// 
/// ## Example
/// 
/// ```gleam
/// sat_pred(chr_grab(), fn(chr) { chr != "{" && chr != "}" })
/// |> btwn(str("{"), str("}"))
/// |> run("{JSON}-Value")
/// // -> Ok(ParseResult("JSON", "-Value", 6))
/// ```
/// 
/// This function only fails when one of the parameter parser functions fail
/// as it is dependent solely on the input parser
pub fn btwn(fst: t.Parser(a), mid: t.Parser(b), lst: t.Parser(c)) -> t.Parser(b) {
  btwn_helper(fst, mid, lst)
}

pub fn run(fnc: t.Parser(a), str: String) -> Result(t.ParseResult(a), String) {
  let t.Parser(p_fn) = fnc
  p_fn(t.ParserState(str: str, idx: 0))
}

// TODO -> write test
/// Parses a token but skips any surrounding whitespace.  It will:
/// 1. Skip leading whitespace (`wht_space`)  
/// 2. Run your parser  
/// 3. Skip trailing whitespace (`wht_space`)  
/// and then return the parser’s result.
/// 
/// ## Example
/// ```gleam
/// let p = tok(str("let"))
/// |> bind(fn(_) { chr("=") })
///
/// run(p, "   let   =x")
/// // -> Ok(ParseResult(res: "=", rem: "x", idx: 8))
/// ```
///
/// Returns a `Parser(a)` that parses `a` with optional padding.
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

fn list_string_to_int(x: List(String)) -> Int {
  let assert Ok(number) = int.parse(s.concat(list.reverse(x)))
  number
}

/// # ``num()`` & ``dgt(int)`` helper function
/// Converts a string to an Int. 
/// ## This function is intended to be used alongside num parsers and num parsers only.
/// 
/// ## Example
/// 
/// ```gleam
/// string_to_int("247")
/// // -> 247
/// ```
pub fn string_to_int(str: String) -> Int {
  let assert Ok(number) = int.parse(str)
  number
}

/// # ``Parser(List(String))`` helper function
/// Prints out a list of strings
/// ## This function is intended to be used alongside string parsers and string
/// ## parsers only.
/// 
/// ## Example
/// 
/// ```gleam
/// string_to_int(["random", "list", "of", "strings"])
/// // -> random, list, of, strings
/// ```
pub fn print_array_string(list: List(String)) -> Nil {
  case list {
    [] -> Nil
    [str, ..rest] -> {
      io.println(str)
      print_array_string(rest)
    }
  }
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
  let invalid = "Error: given string does not start with '" <> pattern <> "'"
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

fn prefix_str_helper(
  pattern: String,
  state: t.ParserState,
) -> Result(t.ParseResult(String), String) {
  let err_msg = "Error: prefix '" <> pattern <> "' not found"
  case s.starts_with(state.str, pattern) {
    False -> err_msg |> Error
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
  let invalid =
    "Error: did not find '" <> pattern <> "' at '" <> state.str <> "'"
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
    [head, ..] -> {
      let expected = int.to_string(digit)
      let err = "Error: expected '" <> expected <> "', found '" <> head <> "'"
      case head == expected {
        False -> err |> Error
        True -> {
          let new_rem = s.drop_start(state.str, 1)
          t.ParseResult(res: digit, rem: new_rem, idx: state.idx + 1) |> Ok
        }
      }
    }
  }
}

fn num_helper(
  acc: List(String),
  state: t.ParserState,
) -> Result(t.ParseResult(Int), String) {
  case s.to_graphemes(state.str) {
    [] -> "invalid parse: empty string" |> Error
    [n, ..rest] -> {
      case list.contains(t.digits, n) {
        True ->
          num_helper(prp(acc, n), t.ParserState(s.concat(rest), state.idx + 1))
        False -> {
          case acc {
            [] -> Error("Error: no number captured")
            _ ->
              t.ParseResult(list_string_to_int(acc), state.str, state.idx)
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
        Error(_) -> "Error: could not match parser sequence" |> Error
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
    [] -> "Error: no suitable parser found" |> Error
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
    [] -> "Error: no suitable parser found" |> Error
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
      case idx == state.idx {
        True ->
          t.ParseResult(
            res: list.reverse(accumulator),
            rem: state.str,
            idx: state.idx,
          )
          |> Ok
        False -> {
          let new_acc = prp(accumulator, res)
          let new_state = t.ParserState(rem, idx)
          mny_helper(parser, new_acc, new_state)
        }
      }
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
) -> Result(t.ParseResult(a), String) {
  let err_msg = "Error: unsatisfied predicate"
  let t.Parser(p_fn) = parser
  case p_fn(state) {
    Error(e) -> Error(e)
    Ok(t.ParseResult(res, rem, idx)) ->
      case fnc(res) {
        True -> t.ParseResult(res, rem, idx) |> Ok
        False -> err_msg |> Error
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
      case result.res == " " || result.res == "\t" {
        False -> err |> Error
        True -> result |> Ok
      }
    }
  }
}
