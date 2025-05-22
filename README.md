# Glindo

[![Package Version](https://img.shields.io/hexpm/v/glindo)](https://hex.pm/packages/glindo)  
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glindo/)

Glindo is a **functional parser-combinator** library for Gleam that makes it easy to build powerful, composable parsers for context-free grammars: JSON, CSV, small DSLs, YAML, and more. Glindo uses familiar FP abstractions—functors, monads, lazy evaluation—to thread parsing state and errors in a purely functional way.

---

## 🔑 Key Features

- **Core Combinators**  
  - `map`, `bind` (monadic sequencing)  
  - `seq_of` (sequence), `chc_of` (choice), `chc_opt` (greedy choice)  
  - `mny_of`, `mny_chc` (zero-or-more repetition)  
  - `opt_of` (optional), `sep_by` (separated lists), `btwn` (between), `peek_fwd`, `lazy`, `tok` (token with whitespace)

- **Rich Type Safety**  
  - `Parser(a)` wraps `fn(ParserState) -> Result(ParseResult(a), String)`  
  - `ParseResult(a)` bundles `(res, rem, idx)`  
  - `ParserState(str, idx)` tracks the remaining input & position  

- **Out-of-the-box Grammars**  
  - **JSON**: full support for `null`, `boolean`, `number`, `string`, `array`, `object`  
  - **CSV**: handles quoted strings (with `""` escapes), unquoted fields, line breaks, and trimming  

- **Pure-FP Style**  
  - No mutable state—everything is threaded through combinators  
  - Lazy parsing for recursive grammars  
  - Distinct error messages  

---

## 📦 Installation

```sh
gleam add glindo
```

# In your gleam.toml
[dependencies]
glindo = ">= 1.0.0"


## 🚀 Quick Start

```gleam
import glindo/parser
import glindo/types
import glindo/csv   
import glindo/json

pub fn main() {
  // Parse CSV
  let csv_text = "name,age\nAlice,30\nBob,25"
  case P.run(glindo.csv(), csv_text) {
    Ok(T.ParseResult(csv, _, _)) ->
      io.println("Parsed CSV: \(inspect(csv))")
    Error(err) ->
      io.println("CSV parse error: \(err)")
  }

  // Parse JSON
  let json_text = "{\"foo\": [1, 2, 3], \"bar\": true}"
  case glindo.parse_json(json_text) {
    Ok(value) ->
      io.println("Parsed JSON: \(inspect(value))")
    Error(err) ->
      io.println("JSON parse error: \(err)")
  }
}
```

## 📚 Core API Overview

| Combinator       | Type Signature                                                                         | Description                                                  |
| ---------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `map`            | `(Parser(a), fn(a) -> b) -> Parser(b)`                                                 | Transform parsed result                                     |
| `bind`           | `(Parser(a), fn(a) -> Parser(b)) -> Parser(b)`                                         | Sequence two parsers                                         |
| `seq_of`         | `List(Parser(a)) -> Parser(List(a))`                                                   | Run parsers in order; fail if any fails                      |
| `chc_of`         | `List(Parser(a)) -> Parser(a)`                                                         | Try parsers until one succeeds                               |
| `chc_opt`        | `List(Parser(a)) -> Parser(a)`                                                         | Greedy choice: pick the one that consumes the most input     |
| `mny_of`         | `Parser(a) -> Parser(List(a))`                                                         | Zero-or-more repetition                                      |
| `mny_chc`        | `List(Parser(a)) -> Parser(List(a))`                                                   | Zero-or-more choice                                          |
| `opt_of`         | `Parser(a) -> Parser(Option(a))`                                                       | Optional parser                                              |
| `sep_by`         | `(Parser(a), Parser(b)) -> Parser(List(a))`                                            | Parse a list separated by a delimiter                        |
| `btwn`           | `(Parser(a), Parser(b), Parser(c)) -> Parser(b)`                                       | Between two delimiters                                       |
| `peek_fwd`       | `Parser(a) -> Parser(a)`                                                               | Look ahead without consuming input                           |
| `lazy`           | `(fn() -> Parser(a)) -> Parser(a)`                                                     | Deferred parser for recursion                                |
| `tok`            | `Parser(a) -> Parser(a)`                                                               | Skip leading/trailing whitespace around a parser             |

See the [HexDocs API Reference](https://hexdocs.pm/glindo/) for full details and examples.


## 🛠️ Development
Glindo is under active development. To run tests and play with the library locally:

```sh
git clone https://github.com/daniel-shunom/glindo.git
cd glindo
gleam run     # Run examples or REPL
gleam test    # Execute the test suite
```
## 🤝 Contributing

1. Fork the repository  
2. Create a feature branch (`git checkout -b my-feature`)  
3. Write tests for new functionality  
4. Submit a pull request  

Please follow the Gleam style guide and include documentation comments for any new public API.


# 📄 License
This project is released under the [Apache License](https://opensource.org/license/mit).
Feel free to use, modify, and distribute as you see fit.


## 📞 Contact Information

If you’d like to reach out, feel free to connect via:

- **Email**: [danilshunom2@gmail.com](mailto:danielshunom2@gmail.com)
- **LinkedIn**: [LinkedIn Profile](https://www.linkedin.com/in/daniel-jeremiah-177416245)
- **GitHub**: [GitHub Profile](https://github.com/daniel-shunom)
- **Twitter**: [@shunom1](https://twitter.com/shunom1)
- **Website**: [danielshunom.com](https://danielshunom.vercel.app)
