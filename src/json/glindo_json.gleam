import gleam/int
import gleam/list
import gleam/string as s
import parsers/parser as p
import parsers/types as t

pub type JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(Int)
  JsonString(String)
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
      json_bool(),
      json_number(),
      json_string(),
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
  p.btwn(p.tok(p.prefix_str("\"")), inner, p.tok(p.prefix_str("\"")))
  |> p.map(fn(str) { JsonString(str) })
}

pub fn json_bool() -> t.Parser(JsonValue) {
  p.chc_of([
    p.map(p.tok(p.prefix_str("true")), fn(_) { JsonBool(True) }),
    p.map(p.tok(p.prefix_str("false")), fn(_) { JsonBool(False) }),
  ])
}

pub fn json_number() -> t.Parser(JsonValue) {
  p.tok(p.num())
  |> p.map(fn(num) { JsonNumber(num) })
}

pub fn json_null() -> t.Parser(JsonValue) {
  p.tok(p.prefix_str("null"))
  |> p.map(fn(_) { JsonNull })
}

pub fn json_object() -> t.Parser(JsonValue) {
  let key_value_pair =
    [json_string(), p.skip(p.tok(p.prefix_str(":")), json_value())]
    |> p.seq_of()
    |> p.map(fn(kvp) {
      let assert [JsonString(key), value] = kvp
      #(key, value)
    })

  let fields =
    p.sep_by(key_value_pair, p.tok(p.prefix_str(",")))
    |> p.map(fn(kval) { JsonObject(kval) })

  p.btwn(p.tok(p.prefix_str("{")), fields, p.tok(p.prefix_str("}")))
}

pub fn json_array() -> t.Parser(JsonValue) {
  let arr_elems =
    p.sep_by(json_value(), p.tok(p.prefix_str(",")))
    |> p.map(fn(j_arr) { JsonArray(j_arr) })
  p.btwn(p.tok(p.prefix_str("[")), arr_elems, p.tok(p.prefix_str("]")))
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

pub fn print_json(jval: JsonValue, level: Int) -> String {
  let pad = indent(level)
  case jval {
    JsonNull -> "null"
    JsonBool(True) -> "True"
    JsonBool(False) -> "False"
    JsonString(str) -> "'" <> str <> "'"
    JsonNumber(num) -> int.to_string(num)
    JsonArray(elems) -> {
      let inner =
        list.map(elems, fn(val) {
          indent(level + 2) <> print_json(val, level + 2)
        })
        |> s.join(",\n")
      "[\n" <> inner <> "\n" <> pad <> "]"
    }
    JsonObject(fields) -> {
      let pairs =
        fields
        |> list.map(fn(kvp) {
          let #(key, value) = kvp
          indent(level + 2)
          <> "\""
          <> key
          <> "\""
          <> " : "
          <> print_json(value, level + 2)
        })
        |> s.join(",\n")
      "{\n" <> pairs <> "\n" <> pad <> "}"
    }
  }
}

fn indent(level: Int) -> String {
  s.repeat(" ", level)
}
