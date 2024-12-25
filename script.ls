label-text-height = 24
label-font = "#{label-text-height}px Arial"
label-padding = 24
label-gap = 24
#low-bound = void

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
      ctx.measureText key
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
  convert input, 10

swing-up = (node, boundary-up, boundary-down, pre-init=void, lightly=no) !->
  x2 = node.x + node.w
  while boundary-up.1 <= node.x
    boundary-up.shift!
    boundary-up.shift!
  y-boundary = boundary-up.0
  while boundary-up.1 < x2
    y-boundary >?= boundary-up.2
    boundary-up.shift!
    boundary-up.shift!
  node.y = y-boundary + label-gap + node.h/2
  if pre-init != void
    node.y >?= pre-init
  for c, i in node.children
    swing-up c, boundary-up, boundary-down, if i == node.children.length-1 then node.y else void
    if i == 0
      node.y >?= c.y
    else
      void # swing-down node.children[i-1], boundary-up, upper-boundary(c, boundary-down), void
    boundary-up = lower-boundary c, boundary-up

swing-down = (node, boundary-up, boundary-down, pre-init=void, lightly=no) !->
  x2 = node.x + node.w
  while boundary-down.1 <= node.x
    boundary-down.shift!
    boundary-down.shift!
  y-boundary = boundary-down.0
  while boundary-down.1 < x2
    y-boundary <?= boundary-down.2
    boundary-down.shift!
    boundary-down.shift!
  node.y = y-boundary - label-gap - node.h/2
  if pre-init != void
    node.y <?= pre-init
  node.children.reverse!
  for c, i in node.children
    swing-down c, boundary-up, boundary-down, if i == node.children.length-1 then node.y else void
    if i == 0
      node.y <?= c.y
    else
      void # swing-up node.children[*-i], lower-boundary(c, boundary-up), boundary-down, void
    boundary-down = upper-boundary c, boundary-down
  node.children.reverse!

upper-boundary = (node, boundary) ->
  node.children.reverse!
  for c in node.children
    boundary = upper-boundary c, boundary
  r = node.x + node.w
  while boundary.1 <= r
    boundary.shift!
    boundary.shift!
  boundary.unshift node.y - node.h/2, r
  node.children.reverse!
  boundary

lower-boundary = (node, boundary) ->
  for c in node.children
    boundary = lower-boundary c, boundary
  r = node.x + node.w
  while boundary.1 <= r
    boundary.shift!
    boundary.shift!
  boundary.unshift node.y + node.h/2, r
  boundary

# node-count: count how many keys in the whole object
#   node-count({a: {}}) = 1
#   node-count({a: {b: {}, c: {}}}) = 3
#   node-count({a: {b: {}, c: {}}, x: {}}) = 4
node-count = (data) ->
  count = Object.keys(data).length
  for key, value of data
    if typeof! value == 'Object'
      count += node-count(value)
  count

draw-node = (node, ctx) !->
  ctx.begin-path!
  ctx.round-rect node.x, node.y - node.h/2, node.w, node.h, label-gap/2
  ctx.stroke!
  ctx.fill-text node.label, node.x + label-padding, node.y

draw-boundary = (boundary, color, ctx) !->
  stroke-style = ctx.stroke-style
  ctx.begin-path!
  ctx.stroke-style = color
  ctx.move-to 0, boundary.0
  for i from 1 til boundary.length by 2
    ctx.line-to boundary[i], boundary[i-1]
    if i+1 < boundary.length
      ctx.line-to boundary[i], boundary[i+1]
  ctx.stroke!
  ctx.stroke-style = stroke-style

draw-forest = (forest, ctx) !->
  ctx.begin-path!
  ctx.move-to forest.0.x - label-gap/2, forest.0.y
  ctx.line-to forest.0.x - label-gap/2, forest[*-1].y
  ctx.stroke!
  for elem in forest
    ctx.begin-path!
    ctx.move-to elem.x - label-gap/2, elem.y
    ctx.line-to elem.x, elem.y
    ctx.stroke!
    if elem.children.length
      ctx.begin-path!
      ctx.move-to elem.x + elem.w, elem.y
      ctx.line-to elem.x + elem.w + label-gap/2, elem.y
      ctx.stroke!
      draw-forest elem.children, ctx
    draw-node elem, ctx

draw = (forest) !->
  canvas = document.query-selector \canvas
  ctx = canvas.get-context \2d
  ctx.font = label-font
  ctx.text-baseline = 'middle'
  ctx.stroke-style = '#000'

  forest = prepare-data forest
  ctx.measureText \ROOT
    root-text-width = ..width
    root-text-height = ..font-bounding-box-ascent + ..font-bounding-box-descent
    root-width = root-text-width + 2*label-gap
  dummy-root = do
    label: \ROOT
    children: forest
    h: root-text-height + 2*label-gap
    w: root-width
    x: 0 - root-width - label-gap
    y: 0
  window.root = dummy-root
  #low-bound := safe-height forest
  #debugger
  swing-up dummy-root, [0, 1e300], [safe-height(forest), 1e300]
  dummy-root.y = forest[*-1].y
  bottom-boundary = lower-boundary dummy-root, [0, 1e300]
  for i from 0 til bottom-boundary.length by 2
    bottom-boundary[i] += label-gap
  #draw-boundary bottom-boundary, \#f00, ctx
  swing-down dummy-root, [0, 1e300], bottom-boundary

  canvas.width = canvas.width
  ctx.font = label-font
  ctx.text-baseline = 'middle'
  ctx.stroke-style = '#000'
  draw-forest forest, ctx

# sum up all nodes' h value
safe-height = (forest) ->
  height = 0
  for elem in forest
    height += elem.h
    height += safe-height elem.children
  height

document.query-selector \textarea .add-event-listener \input, (ev) !->
  forest = JSON.parse ev.target.value
  draw forest

draw JSON.parse document.query-selector(\textarea).value
