''
  ---
  name: anti-slop
  description: >-
    Language-agnostic anti-slop hygiene for code in any language (TypeScript,
    JavaScript, Rust, Go, Lua, Python). Rejects low-evidence patterns: stacked
    casts, silenced type contracts, reflective dispatch where a direct call works,
    ad-hoc type-checking mid-function, mocking over real seams, and casting without
    a stated invariant. Use whenever writing, reviewing, or refactoring code, and
    when "anti-slop", "slop", "low-evidence", "avoid unknown", "no unsafe casts",
    or "type hygiene" come up. A principles skill, not a linter; per-language
    enforcement lives in the actual linter (clippy, oxlint).
  ---

  # Anti-slop

  Slop is any pattern that gets the compiler to accept a thing by discarding or faking evidence instead of making the program honest. Fix the evidence, not the syntax. These moves reduce every typed-language slop rule to a habit you can carry into any language:

  ## Principles

  1. Keep values as narrow as they actually are. Don't widen at an assignment and re-narrow at the use site.
     - TS: no `const handlers: Record<string, Handler> = { start: startHandler }` (discards the known start key; prefer inference or `satisfies Record<string, Handler>`).
     - TS: no `const user = input as object as User;` — stacked casts are the first false step.
     - Rust: no `let x: Box<dyn Any> = concrete; ... x.downcast_ref::<Concrete>()`. Carry the concrete type.

  2. No dynamic dispatch when a typed call exists.
     - TS: no `Reflect.apply(fn, owner, args)` / `Reflect.get(owner, key)`.
     - Rust: no `Any::downcast_ref` or reflection when a named method works.
     - If you can name the function, call it and let the type checker hold the contract.

  3. Parse once, at the boundary; never type-check inside the body.
     - TS: no `typeof input === "string"` checks scattered through logic; parse `unknown` into a known type at the input edge (JSON boundary, HTTP body), then the rest is typed.
     - Rust: deserialize raw bytes / a `serde_json::Value` into a concrete struct at the boundary (serde derive). Let the parser hold the evidence, not ad-hoc `.as_str()` checks.
     - Dynamic languages too: validate input in one place and return a typed/slotted result; do not re-check shape deep in the call tree.

  4. A cast must state the invariant it proved. Every cast needs a SAFETY comment naming what earlier step made it sound.
     - TS: `// SAFETY: parseUserId validated the identifier before branding it.` above `const userId = value as UserId;`
     - Rust: same, above an unavoidable `as` (never bare `transmute`) and above a `#[allow(...)]` forcing a cast.

  5. Name the contract, not the shape of the container.
     - TS: no `function save(value: object)`, no `Record<string, unknown>` for a thing with real fields, no alias that merely hides `unknown` (`type ExternalValue = unknown`).
     - Rust: no `HashMap<String, Value>` surfacing everywhere; use `#[serde(deny_unknown_fields)]` where the schema is known.
     - Lua: one named table with a boundary validator, not a `{}` any caller shapes.

  6. Real seams over mocks. Test through the actual dependency boundary (a function argument, a trait impl, an interface, an injected client), not a mocking library that fabricates an isolated copy. TS: no `vi.mock("./user-store")`. Rust: inject the trait impl rather than swizzle global state.

  7. Don't smuggle shape into names. No `UserShape`, no `recordOfUsers`. Name it what it is: `User`, `Users`.

  8. No conditional-omission hacks.
     - TS: `...(timeout !== undefined ? { timeout } : {})` spread hacks are out; build the object honestly.

  9. `unknown`/`any`/`Box<dyn Any>` is a confession, not a contract. A loose return or param means the owner never decided what the boundary carries. Acceptable only as the single catch-and-narrow point at the edge, immediately narrowed.

  ## Boundary test
  Run on every interface: input arrives as `unknown` once at the edge, is parsed into a concrete type, and is fully typed from there. If an `unknown`/`Value`/`dyn Any` survives past the first two lines of a function, the slop is there — move the parse to the boundary.

  ## Shipping checklist
  Every one of these must pass before shipping a changeset:
  - Every cast/`downcast`/unwrap has a SAFETY comment naming what proved it.
  - No value widened then re-narrowed; `unknown` is parsed exactly once.
  - No reflective/dynamic dispatch where a plain typed call exists.
  - Every `unknown`/`Value`/`Any` is handled at a boundary, never mid-function.
  - No mock fattening a seam that could take a real argument.
  - Structs/dicts/trees built by constructors, not spread-omit or empty-grow hacks.
  - Nothing is named `…Shape` or ornament-shaped.

  The skill is judgement, not machinery. If clippy, oxlint, or the borrow checker already reject a form, do not reproduce it here — keep only what a human must weigh.
''
