# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test,priv}/**/*.{ex,exs}"],
  locals_without_parens: [
    # API.Perm DSL
    action: :*,
    allow: :*,
    deny: :*
  ]
]
