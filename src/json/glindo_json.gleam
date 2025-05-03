import gleam/int
import gleam/list
import gleam/string as s
import parsers/parser as p
import parsers/types as t

pub type JsonValue {
  JsonBool(Bool)
  JsonNull
  JsonString(String)
  JsonNumber(Int)
  JsonArray(List(JsonValue))
  JsonObject(List(#(String, JsonValue)))
}

pub type JsonError(str) {
  JsonError(message: str)
}

pub fn json_value() -> t.Parser(JsonValue) {
  p.lazy(fn() {
    p.chc_of([
      json_null(),
      json_string(),
      json_bool(),
      json_number(),
      json_array(),
      json_object(),
    ])
  })
}

pub fn json_string() -> t.Parser(JsonValue) {
  let inner =
    p.chr_grab()
    |> p.sat_pred(fn(chr) { chr != "\"" })
    |> p.map(fn(lstr) { s.concat(lstr) })
    |> p.mny_of()
    |> p.map(fn(lstr) { s.concat(lstr) })

  p.btwn(p.tok(p.str("\"")), inner, p.tok(p.str("\"")))
  |> p.map(fn(str) { JsonString(str) })
}

pub fn json_bool() -> t.Parser(JsonValue) {
  p.chc_of([
    p.map(p.tok(p.str("true")), fn(_) { JsonBool(True) }),
    p.map(p.tok(p.str("false")), fn(_) { JsonBool(False) }),
  ])
}

pub fn json_number() -> t.Parser(JsonValue) {
  p.tok(p.num())
  |> p.map(fn(num) { JsonNumber(num) })
}

pub fn json_null() -> t.Parser(JsonValue) {
  p.tok(p.str("null"))
  |> p.map(fn(_) { JsonNull })
}

pub fn json_object() -> t.Parser(JsonValue) {
  let key_value_pair =
    p.seq_of([
      p.tok(json_string()),
      p.map(p.tok(p.str(":")), fn(x) { JsonString(x) }),
      json_value(),
    ])
    |> p.map(fn(kvp) {
      let assert [JsonString(key), _, value] = kvp
      #(key, value)
    })

  let fields =
    p.sep_by(key_value_pair, p.tok(p.str(",")))
    |> p.map(fn(kval) { JsonObject(kval) })

  p.btwn(p.tok(p.str("{")), fields, p.tok(p.str("}")))
}

pub fn json_array() -> t.Parser(JsonValue) {
  let arr_elems =
    p.sep_by(json_value(), p.tok(p.str(",")))
    |> p.map(fn(j_arr) { JsonArray(j_arr) })
  p.btwn(p.tok(p.str("[")), arr_elems, p.tok(p.str("]")))
}

pub fn parse_json(string: String) -> Result(JsonValue, String) {
  case p.run(json_value(), string) {
    Error(e) -> Error(e)
    Ok(t.ParseResult(res, rem, _)) -> {
      case rem == "" {
        True -> Ok(res)
        False -> Error("failed to parse:  " <> rem)
      }
    }
  }
}

pub fn print_json(jval: JsonValue) -> String {
  case jval {
    JsonNull -> "null"
    JsonBool(True) -> "true"
    JsonBool(False) -> "false"
    JsonString(str) -> str
    JsonNumber(num) -> int.to_string(num)
    JsonArray(elems) -> {
      let inner =
        list.map(elems, fn(val) { print_json(val) })
        |> s.join(", ")
      "[" <> inner <> "]"
    }
    JsonObject(fields) -> {
      let pairs =
        fields
        |> list.map(fn(kvp) {
          let #(key, value) = kvp
          "\"" <> key <> "\"" <> ":" <> print_json(value)
        })
        |> s.join(", ")
      "{" <> pairs <> "}"
    }
  }
}
