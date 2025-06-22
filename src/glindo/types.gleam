/// The `Parser` type is a higher‐order endofunctor (`* → *`) that
/// represents a parsing computation producing a value of type `a`.
///
/// As a **functor**, you can map over its result:
/// ```gleam
/// map(p: Parser(a), fn: fn(a) -> b) -> Parser(b)
/// ```
///
/// As a **monad**, you can sequence parsers with `bind` (also called `flatMap`)
/// and inject pure values with a `pure`/`return`–style combinator:
/// ```gleam
/// bind(p: Parser(a), fn: fn(a) -> Parser(b)) -> Parser(b)
/// ```
///
/// Internally, `Parser(a)` wraps a function from `ParserState` to
/// `Result(ParseResult(a), String)`, where an `Error(String)` signals
/// parse failure.
///
/// ## Laws
/// - **Identity**: `bind(p, pure) ≡ p`
/// - **Associativity**: `bind(bind(p, f), g) ≡ bind(p, \x -> bind(f(x), g))`
///
/// **So really** a `Parser(a)` is just a function that takes some text
/// and either returns a value of type `a` along with the leftover text
/// or fails with an error message.
pub type Parser(a) {
  Parser(fn(ParserState) -> Result(ParseResult(a), String))
}

/// The result of a successful parse, parameterized by the parsed value type `n`.
///
/// - `res` is the parsed value of type `n`.
/// - `rem` is the remaining unconsumed input string.
/// - `idx` is the absolute position (character count) reached in the original input.
///
/// As a **functor** in `n`, you can `map` over the `res` field to transform it:
/// ```gleam
/// map_result(fn: fn(n) -> m, ParseResult(res, rem, idx)) -> ParseResult(m, rem, idx)
/// ```
///
/// **In essence**, a `ParseResult` is just a bundle of:
/// 1. The thing you parsed (`res`),  
/// 2. What’s left to parse (`rem`),  
/// 3. How far you got (`idx`).
pub type ParseResult(n) {
  ParseResult(
    /// The parsed value
    res: n,
    /// Unparsed remainder of the input
    rem: String,
    /// Index in the original input after consuming `res`
    idx: Int,
  )
}

pub type ParseError(t, m) {
  ParseError(
    token: t,
    line: Int,
    column: Int, 
    messaage: m,
  )
}

/// The parsing state threaded through the `Parser` monad.
///
/// - `str` holds the yet‐to‐be‐consumed portion of the input.
/// - `idx` tracks how many characters have already been consumed.
///
/// This mirrors the typical **State** monad’s `state` type, allowing
/// parsers to inspect and update a shared context.
///
/// **Simplified:** `ParserState` just keeps track of:
/// - The slice of text you haven’t looked at yet, and  
/// - The position you’re at in the overall input.
pub type ParserState {
  ParserState(
    /// Remaining input
    str: String,
    /// Number of characters consumed so far
    idx: Int,
  )
}

/// A simple list of all single‐digit characters, used by numeric parsers
/// (`num`, `dgt`) to recognize valid digit tokens.
///
/// As a constant functor in the element type, it can be used wherever
/// a fixed set of choices is needed.
///
/// **Essentially**, just the characters `"0"` through `"9"` collected
/// in a list for easy digit‐checking.
pub const digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
