# prepare-data function
#   convert
#   ```JSON
#   {a: {b: {}, c: {x: {}}}}
#   ```
#   into
#   ```JSON
#   {label: "a", children: [{label: "b", children: []}, {label: "c", children: [{label: "x", children: []}]}]}
#   ```
#   recursively
prepare-data = (input) ->
  convert = (input) ->
    Object.entries(input).map(([key, value]) -> {
      label: key
      children: if Object.keys(value).length then convert(value) else []
    })
  convert input
