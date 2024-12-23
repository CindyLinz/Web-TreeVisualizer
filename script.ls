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
  convert = (input, x) ->
    for key, value of input
      ctx.measureText key .width
        text-width = ..width
        text-height = ..font-bounding-box-ascent + ..font-bounding-box-descent
        width = text-width + 2*label-padding
      do
        label: key
        children: convert value, x + width + label-gap
        w: width
        h: text-height + 2*label-padding
        text-width: text-width
        text-height: text-height
        x: x
        y: 0
  convert input, 0

upper-boundary = (node) ->
  out = []
  while node
    out.push node.y - node.h/2
    out.push node.x + node.w
    node = node.children.0
  out

lower-boundary = (node) ->
  out = []
  loop
    out.push node.y + node.h/2
    out.push node.x + node.w
    if node.children.length
      node = node.children[*-1]
    else
      return out
