//TODO -> add file handling prop to module
import gleam/int as i
import gleam/io
import gleam/list
import gleam/option as opt
import gleam/string as s
import parsers/parser as p
import parsers/types as t

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
    p.chc_of([
      p.sat_pred(p.chr_grab(), fn(x) { x != "\"" }),
      p.map(p.prefix_str("\"\""), fn(x) { [x] }),
    ]),
    p.tok(p.prefix_str("\"")),
  )
  |> p.map(s.concat)
  |> p.map(s.trim)
  |> p.map(fn(x) { CSVStr(x) })
}

fn csv_unquoted_string() -> t.Parser(CSVal) {
  p.chr_grab()
  |> p.sat_pred(fn(x) { x != "," && x != "\r\n" && x != "\n" })
  |> p.map(s.concat)
  |> p.map(s.trim)
  |> p.map(fn(x) { CSVStr(x) })
}

fn csv_string() -> t.Parser(CSVal) {
  [csv_quoted_string(), csv_unquoted_string()]
  |> p.chc_of()
}

fn csv_num() -> t.Parser(CSVal) {
  use num <- p.map(p.num())
  CSVInt(num)
}

fn filter_csval(val: CSVal) -> Bool {
  val != CSVStr("\r\n")
}

fn csv_record() -> t.Parser(CSVRecord) {
  [csv_string(), csv_num()]
  |> p.chc_of()
  |> p.sep_by(p.prefix_str(","))
  |> p.map(fn(x) { list.filter(x, filter_csval) })
  |> p.map(fn(rec) { Field(1, rec) })
}

fn csv() -> t.Parser(CSV) {
  csv_record()
  |> p.sep_by(
    [p.tok(p.prefix_str("\r\n")), p.tok(p.prefix_str("\n"))]
    |> p.chc_of()
    |> p.tok(),
  )
  |> p.map(fn(csv) { CSV(csv) })
}

pub fn print_csv(str: String) -> Nil {
  case p.run(csv(), str) {
    Error(err) -> err |> io.println()
    Ok(t.ParseResult(res, ..)) -> {
      format_csv(res, 1)
    }
  }
}

pub fn get_csv(str: String) -> opt.Option(CSV) {
  case p.run(csv(), str) {
    Ok(csv) -> opt.Some(csv.res)
    Error(_) -> opt.None
  }
}

pub fn query_csv(csv csv: CSV, row row: Int, column col: Int) -> Nil {
  let err = "Error: value not found"
  let CSV(csv_row) = csv
  let rec = opt.unwrap(get_nth(csv_row, row), Field(0, []))
  opt.unwrap(get_nth(rec.records, col), CSVStr(err))
  |> print_csval()
  io.println("\n\n")
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
    [] -> Nil
    [val, ..rest] -> {
      print_csval(val)
      print_list_csval(rest)
    }
  }
}

fn format_csv(csval: CSV, line: Int) -> Nil {
  case csval {
    CSV([]) -> "No more records found" |> io.println()
    CSV([Field(_, list_vals), ..list_field]) -> {
      let len = list.length(list_vals) |> i.to_string()
      io.print(i.to_string(line) <> ". |\t")
      print_list_csval(list_vals)
      io.print("\t|" <> len <> " vals\n")
      format_csv(CSV(list_field), line + 1)
    }
  }
}

fn get_nth(list: List(a), idx: Int) -> opt.Option(a) {
  case list.length(list) >= idx {
    False -> opt.None
    True ->
      case list, idx {
        [], _ -> opt.None
        [head, ..], 1 -> opt.Some(head)
        [_, ..], i if i < 1 -> opt.None
        [_, ..rest], i -> get_nth(rest, i - 1)
      }
  }
}
