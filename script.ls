label-font = '24px Arial'
label-padding = 24
label-gap = 24

# prepare-data function
#   convert
#   ```JSON
#   {a: {b: {}, c: {x: {}}}}
#   ```
#   into
#   ```JSON
#   [{label: "a", children: [{label: "b", children: []}, {label: "c", children: [{label: "x", children: []}]}]}]
#   ```
#   recursively
prepare-data = (input) ->
  ctx = document.query-selector \canvas .get-context \2d
  ctx.font = label-font
  convert = (input) ->
    for key, value of input
      ctx.measureText key .width
        text-width = ..width
        text-height = ..font-bounding-box-ascent + ..font-bounding-box-descent
      do
        label: key
        children: convert value
        width: text-width + 2*label-padding
        height: text-height + 2*label-padding
        text-width: text-width
        text-height: text-height
  convert input
