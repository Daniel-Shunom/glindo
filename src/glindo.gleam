import gleam/io
import json/glindo_json as g

pub fn main() {
  let input = "{\"name\": \"Alice\", \"age\": 25, \"city\": \"New York\"}"

  case g.parse_json(input) {
    Error(error) -> {
      io.println(error)
      error
    }
    Ok(val) -> {
      io.println(g.print_json(val))
      g.print_json(val)
    }
  }
}
