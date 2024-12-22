# prepare-data function
#   convert
#   ```JSON
#   {a: {b: {}, c: {x: {}}}}
#   ```
#   into
#   ```JSON
#   {label: "a", children: [{label: "b", children: []}, {label: "c", children: [{label: "x", children: []}]}]}
#   ```
prepare-data = (input) ->
  output = {}
  {{{}}}
  output
