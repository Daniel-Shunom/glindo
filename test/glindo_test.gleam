import gleam/int
import gleam/list
import gleam/option as opt
import gleam/string
import gleeunit
import gleeunit/should
import glindo/parsers as p
import glindo/types as t

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn chr_grab_ok_test() {
  p.run(p.chr_grab(), "chr")
  |> should.equal(Ok(t.ParseResult("c", "hr", 1)))
}

pub fn chr_grab_error_test() {
  let msg = "Error: expected char, found none"
  p.run(p.chr_grab(), "")
  |> should.equal(Error(msg))
}

pub fn wht_spc_ok_test() {
  p.run(p.wht_space(), "  chr")
  |> should.equal(Ok(t.ParseResult("  ", "chr", 2)))
}

pub fn wht_spc_error_test() {
  p.run(p.wht_space(), "chr")
  |> should.equal(Ok(t.ParseResult("", "chr", 0)))
}

pub fn num_ok_test() {
  p.run(p.num(), "876abc123")
  |> should.equal(Ok(t.ParseResult(876, "abc123", 3)))
}

pub fn num_error_test() {
  let msg = "Error: no number captured"
  p.run(p.num(), "abc123876")
  |> should.equal(Error(msg))
}

pub fn dgt_ok_test() {
  p.run(p.dgt(6), "6 numbers")
  |> should.equal(Ok(t.ParseResult(6, " numbers", 1)))
}

pub fn dgt_error_test() {
  let err = "Error: expected '6', found 'n'"
  p.run(p.dgt(6), "number")
  |> should.equal(Error(err))
}

pub fn str_ok_test() {
  p.run(p.str("hal"), "halal")
  |> should.equal(Ok(t.ParseResult("hal", "al", 3)))
}

pub fn str_error_test() {
  let msg = "Error: given string does not start with 'hal'"
  p.run(p.str("hal"), "mashallah")
  |> should.equal(Error(msg))
}

pub fn prefix_str_ok_test() {
  p.run(p.prefix_str("tiger"), "tigerrific")
  |> should.equal(Ok(t.ParseResult("tiger", "rific", 5)))
}

pub fn prefix_str_error_test() {
  let msg = "Error: prefix 'tiger' not found"
  p.run(p.prefix_str("tiger"), "monkeyrific")
  |> should.equal(Error(msg))
}

pub fn peek_fwd_ok_test() {
  p.peek_fwd(p.str("goat cheese"))
  |> p.run("goat cheese tastes good")
  |> should.equal(
    Ok(t.ParseResult("goat cheese", "goat cheese tastes good", 0)),
  )
}

pub fn peek_fwd_error_test() {
  let msg = "Error: given string does not start with 'rubber'"
  p.peek_fwd(p.str("rubber"))
  |> p.run("Bungee gum is somewhat rubber")
  |> should.equal(Error(msg))
}

//TODO -> write a test for the 'lazy combinator'

pub fn mny_of_ok_test() {
  let arr = ["a", "a", "a"]
  p.mny_of(p.str("a"))
  |> p.run("aaa is a letter")
  |> should.equal(Ok(t.ParseResult(arr, " is a letter", 3)))
}

pub fn mny_of_error_test() {
  p.mny_of(p.str("a"))
  |> p.run("bbb is a letter")
  |> should.equal(Ok(t.ParseResult([], "bbb is a letter", 0)))
}

pub fn chc_of_ok1_test() {
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("bro, go pro")
  |> should.equal(Ok(t.ParseResult("bro", ", go pro", 3)))
}

pub fn chc_of_ok2_test() {
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("bruh, go pro")
  |> should.equal(Ok(t.ParseResult("bruh", ", go pro", 4)))
}

pub fn chc_of_error_test() {
  let msg = "Error: no suitable parser found"
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("cuzz, go pro")
  |> should.equal(Error(msg))
}

pub fn chc_opt_ok1_test() {
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("bro, go pro")
  |> should.equal(Ok(t.ParseResult("bro", ", go pro", 3)))
}

pub fn chc_opt_ok2_test() {
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("bruh, go pro")
  |> should.equal(Ok(t.ParseResult("bruh", ", go pro", 4)))
}

//TODO -> write a more comprehensize chc_opt test

pub fn chc_opt_error_test() {
  let msg = "Error: no suitable parser found"
  p.chc_of([p.str("bro"), p.str("bruh")])
  |> p.run("cuzz, go pro")
  |> should.equal(Error(msg))
}

pub fn opt_of_ok_test() {
  p.opt_of(p.str("green"))
  |> p.run("green beans rock")
  |> should.equal(Ok(t.ParseResult(opt.Some("green"), " beans rock", 5)))
}

pub fn opt_of_error_test() {
  p.opt_of(p.str("green"))
  |> p.run("brocolli sucks")
  |> should.equal(Ok(t.ParseResult(opt.None, "brocolli sucks", 0)))
}

pub fn map_ok1_test() {
  p.map(p.num(), fn(x) { int.to_string(x) })
  |> p.run("2017 has the best music")
  |> should.equal(Ok(t.ParseResult("2017", " has the best music", 4)))
}

pub fn map_ok2_test() {
  p.map(p.num(), fn(x) { int.to_base16(x) })
  |> p.run("16 has the best music")
  |> should.equal(Ok(t.ParseResult("10", " has the best music", 2)))
}

pub fn seq_of_ok_test() {
  let val = ["a", "bb", "i"]
  [p.str("a"), p.str("bb"), p.str("i")]
  |> p.seq_of()
  |> p.run("abbi just graduated")
  |> should.equal(Ok(t.ParseResult(val, " just graduated", 4)))
}

pub fn seq_of_error_test() {
  let msg = "Error: could not match parser sequence"
  [p.str("a"), p.str("bb"), p.str("i")]
  |> p.seq_of()
  |> p.run("chloe just graduated")
  |> should.equal(Error(msg))
}

pub fn sep_by_ok_test() {
  let val = ["eggs", " bacon", " cheese", " are good"]
  p.chr_grab()
  |> p.sat_pred(fn(x) { x != "," })
  |> p.map(string.concat)
  |> p.sep_by(p.str(","))
  |> p.run("eggs, bacon, cheese, are good")
  |> should.equal(Ok(t.ParseResult(val, "", 29)))
}

pub fn sep_by_error_test() {
  let str = "eggs bacon cheese are good"
  p.chr_grab()
  |> p.sat_pred(fn(x) { x != "," })
  |> p.map(string.concat)
  |> p.sep_by(p.str(","))
  |> p.run(str)
  |> should.equal(Ok(t.ParseResult([str], "", 26)))
}

pub fn skip_ok_test() {
  p.skip(p.str("race"), p.wht_space())
  |> p.run("racecars are good")
  |> should.equal(Ok(t.ParseResult("", "cars are good", 4)))
}

pub fn skip_error_test() {
  let msg = "Error: given string does not start with 'race'"
  p.skip(p.str("race"), p.wht_space())
  |> p.run("boats are cooler")
  |> should.equal(Error(msg))
}

pub fn bind_ok_test() {
  p.str("chicken")
  |> p.bind(fn(_) { p.chr_grab() })
  |> p.run("chicken-farm")
  |> should.equal(Ok(t.ParseResult("-", "farm", 8)))
}

pub fn bind_error_test() {
  let msg = "Error: given string does not start with 'Chicken'"
  p.str("Chicken")
  |> p.bind(fn(_) { p.chr_grab() })
  |> p.run("Lobster-farm")
  |> should.equal(Error(msg))
}

pub fn sat_pred_ok_test() {
  let val = ["c", "r", "y", "-"]
  p.chr_grab()
  |> p.sat_pred(fn(x) { x != "b" })
  |> p.run("cry-baby")
  |> should.equal(Ok(t.ParseResult(val, "baby", 4)))
}

pub fn sat_pred_error_test() {
  p.num()
  |> p.sat_pred(fn(x) { x != 5 })
  |> p.run("cry-baby")
  |> should.equal(Ok(t.ParseResult([], "cry-baby", 0)))
}

pub fn btwn_ok1_test() {
  let new_p =
    p.chr_grab()
    |> p.sat_pred(fn(x) { x != "{" && x != "}" })
    |> p.map(string.concat)
  p.btwn(p.str("{"), new_p, p.str("}"))
  |> p.run("{JSON} Value")
  |> should.equal(Ok(t.ParseResult("JSON", " Value", 6)))
}

pub fn btwn_ok2_test() {
  let new_p =
    p.chr_grab()
    |> p.sat_pred(fn(x) { list.contains(t.digits, x) })
    |> p.map(fn(x) { list.map(x, p.string_to_int) })
    |> p.map(fn(x) { int.sum(x) })
  p.btwn(p.prefix_str("{"), new_p, p.prefix_str("}"))
  |> p.run("{2552} Value")
  |> should.equal(Ok(t.ParseResult(14, " Value", 6)))
}
