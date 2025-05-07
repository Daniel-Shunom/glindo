import gleam/int as i
import gleam/io
import gleam/list
import gleam/string as s
import parsers/parser as p
import parsers/types as t

//import simplifile as fs

pub type CSVal {
  CSVInt(Int)
  CSVStr(String)
  CSVBool(Bool)
}

pub type CSVRecord {
  Field(line: Int, records: List(CSVal))
}

pub type CSV {
  CSV(value: List(CSVRecord))
}

fn csv_quoted_string() -> t.Parser(CSVal) {
  p.btwn(
    p.tok(p.prefix_str("\"")),
    p.sat_pred(p.chr_grab(), fn(x) { x != "\"" && x != "\n" && x != "\r" }),
    p.tok(p.prefix_str("\"")),
  )
  |> p.map(s.concat)
  |> p.map(fn(x) { CSVStr(x) })
}

fn csv_unquoted_string() -> t.Parser(CSVal) {
  p.chr_grab()
  |> p.sat_pred(fn(x) { x != "," && x != "\n" && x != "\r" })
  |> p.map(s.concat)
  |> p.map(fn(x) { CSVStr(x) })
}

pub fn csv_string() -> t.Parser(CSVal) {
  [csv_quoted_string(), csv_unquoted_string()]
  |> p.chc_of()
}

pub fn csv_num() -> t.Parser(CSVal) {
  use num <- p.map(p.num())
  CSVInt(num)
}

pub fn csv_record() -> t.Parser(CSVRecord) {
  [csv_string(), csv_num()]
  |> p.chc_of()
  |> p.sep_by(p.prefix_str(","))
  |> p.map(fn(rec) { Field(1, rec) })
}

//TODO -> Currently parses  only one record
pub fn csv() -> t.Parser(CSV) {
  csv_record()
  |> p.sep_by(
    [p.tok(p.prefix_str("\r\n")), p.tok(p.prefix_str("\n"))]
    |> p.chc_of()
    |> p.tok(),
  )
  |> p.map(fn(csv) { CSV(csv) })
}

pub fn parse_csv(str: String) -> Nil {
  case p.run(csv(), str) {
    Error(err) -> err |> io.println()
    Ok(t.ParseResult(res, ..)) -> {
      format_csv(res)
    }
  }
}

fn print_csval(val: CSVal) -> Nil {
  case val {
    CSVStr(str) -> io.print("(" <> str <> ")" <> ",\t")
    CSVBool(_) -> io.print("bool")
    CSVInt(x) -> io.print(i.to_string(x))
  }
}

fn print_list_csval(lval: List(CSVal)) -> Nil {
  case lval {
    [] -> "\nNo csv values found" |> io.println()
    [val, ..rest] -> {
      print_csval(val)
      print_list_csval(rest)
    }
  }
}

pub fn format_csv(csval: CSV) -> Nil {
  case csval {
    CSV([]) -> "No records found" |> io.println()
    CSV([Field(_, list_vals), ..list_field]) -> {
      let CSV(k) = csval
      print_list_csval(list_vals)
      io.print("No. of fields: " <> i.to_string(list.length(k)) <> "\n")
      format_csv(CSV(list_field))
    }
  }
}
