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

swing-up = (node, boundary, pre-init) !->
  y-boundary = boundary.0
  if pre-init != void
    y-boundary >?= pre-init
  x2 = node.x + node.w
  while boundary.1 < x2
    y-boundary >?= boundary.2
    boundary.shift!
    boundary.shift!
  node.y = y-boundary + label-gap + node.h/2
  for c, i in node.children
    swing-up c, boundary, if i == node.children.length-1 then node.y - node.children.0.h/2 else void
    if i == 0
      node.y >?= c.y
    else
      swing-down node.children[i-1], upper-boundary(c), void
    boundary = lower-boundary c

swing-down = (node, boundary, pre-init) !->
  y-boundary = boundary.0
  if pre-init != void
    y-boundary <?= pre-init
  x2 = node.x + node.w
  while boundary.1 < x2
    y-boundary <?= boundary.2
    boundary.shift!
    boundary.shift!
  node.y = y-boundary - label-gap - node.h/2
  for c, i in node.children.reverse!
    swing-down c, boundary, if i == node.children.length-1 then node.y + node.children.0.h/2 else void
    if i == 0
      node.y <?= c.y
    else
      swing-up node.children[*-i], lower-boundary(c), void
    boundary = upper-boundary c

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
