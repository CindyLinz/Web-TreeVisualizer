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
        h: text-height + label-padding/2
        text-width: text-width
        text-height: text-height
        x: x
        y: 0
  convert input, 10

swing-up = (node, boundary, pre-init=void, lightly=no) !->
  x2 = node.x + node.w
  while boundary.1 <= node.x
    boundary.shift!
    boundary.shift!
  y-boundary = boundary.0
  while boundary.1 < x2
    y-boundary >?= boundary.2
    boundary.shift!
    boundary.shift!
  node.y = y-boundary + label-gap/2 + node.h/2
  if pre-init != void
    node.y >?= pre-init
  for c, i in node.children
    swing-up c, boundary, if i == node.children.length-1 then node.y else void
    if i == 0
      node.y >?= c.y
    boundary = lower-boundary c, boundary

swing-down = (node, boundary, pre-init=void, lightly=no) !->
  x2 = node.x + node.w
  while boundary.1 <= node.x
    boundary.shift!
    boundary.shift!
  y-boundary = boundary.0
  while boundary.1 < x2
    y-boundary <?= boundary.2
    boundary.shift!
    boundary.shift!
  node.y = y-boundary - label-gap/2 - node.h/2
  if pre-init != void
    node.y <?= pre-init
  node.children.reverse!
  for c, i in node.children
    swing-down c, boundary, if i == node.children.length-1 then node.y else void
    if i == 0
      node.y <?= c.y
    boundary = upper-boundary c, boundary
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

draw-node = (node, ctx) !->
  ctx.begin-path!
  ctx.round-rect node.x, node.y - node.h/2, node.w, node.h, label-gap/2
  ctx.fill-style = \#fff
  ctx.fill!
  ctx.stroke!
  ctx.fill-style = \#000
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
  swing-up dummy-root, [0, 1e300]
  dummy-root.y = forest[*-1].y
  bottom-boundary = lower-boundary dummy-root, [0, 1e300]
  for i from 0 til bottom-boundary.length by 2
    bottom-boundary[i] += label-gap
  swing-down dummy-root, bottom-boundary

  box = get-forest-boundary forest
  shift-forest forest, box

  canvas.width = box.right - box.left + 2 * label-gap
  canvas.height = box.bottom - box.top + 2 * label-gap
  ctx.fill-style = \#ffc
  ctx.fill-rect 0, 0, canvas.width, canvas.height
  ctx.font = label-font
  ctx.text-baseline = \middle
  ctx.stroke-style = \#000
  draw-forest forest, ctx

get-forest-boundary = (forest) ->
  left = 1e300
  right = -1e300
  top = 1e300
  bottom = -1e300
  for node in forest
    {left: l, right: r, top: t, bottom: b} = get-forest-boundary node.children
    left <?= l <? node.x
    right >?= r >? node.x + node.w
    top <?= t <? node.y - node.h/2
    bottom >?= b >? node.y + node.h/2
  {left, right, top, bottom}

shift-forest = (forest, box) !->
  for node in forest
    node.x -= box.left - label-gap
    node.y -= box.top - label-gap
    shift-forest node.children, box

document.query-selector \textarea .add-event-listener \input, (ev) !->
  forest = JSON.parse ev.target.value
  draw forest

draw JSON.parse document.query-selector(\textarea).value
