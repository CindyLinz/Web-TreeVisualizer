label-font = '24px Arial'
label-height = 30
label-padding = 24
label-gap = 24

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
  ctx = document.query-selector \canvas .get-context \2d
  ctx.font = label-font
  convert = (input) ->
    Object.entries(input).map(([key, value]) ->
      text-width = ctx.measureText key .width
      do
        label: key
        children: convert value
        width: text-width + 2*label-padding
  convert input
