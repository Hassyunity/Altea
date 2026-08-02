// ALTEA herself — a character built from geometry, not a photograph.
//
// The body is a stack of cross-sections (like scan slices) whose radii follow
// a feminine profile. Each section is drawn as a ring in 3D and the rings are
// stitched together lengthwise, so she reads as a surface rather than a cloud.
// The face is drawn as real features: almond eyes that blink, brows, a nose
// line and lips that open on every word she pronounces.

const TAU = Math.PI * 2

// [y, halfWidth, halfDepth] — the silhouette, head at the top, feet at y = 0.52
const TORSO = [
  [-0.720, 0.042, 0.042],
  [-0.690, 0.075, 0.055],
  [-0.655, 0.150, 0.070],
  [-0.620, 0.148, 0.082],
  [-0.575, 0.132, 0.094],
  [-0.530, 0.113, 0.080],
  [-0.480, 0.098, 0.068],
  [-0.430, 0.092, 0.064],
  [-0.380, 0.101, 0.070],
  [-0.320, 0.124, 0.080],
  [-0.270, 0.132, 0.084],
  [-0.230, 0.124, 0.080]
]

const LEG = [
  [-0.215, 0.068, 0.068],
  [-0.120, 0.062, 0.064],
  [-0.010, 0.052, 0.055],
  [ 0.100, 0.043, 0.045],
  [ 0.160, 0.038, 0.042],
  [ 0.260, 0.034, 0.038],
  [ 0.360, 0.026, 0.030],
  [ 0.440, 0.020, 0.023],
  [ 0.490, 0.019, 0.022]
]

const ARM = [
  [-0.650, 0.046, 0.046],
  [-0.560, 0.040, 0.040],
  [-0.460, 0.034, 0.034],
  [-0.420, 0.031, 0.031],
  [-0.330, 0.027, 0.027],
  [-0.230, 0.024, 0.024],
  [-0.170, 0.022, 0.022],
  [-0.120, 0.026, 0.020]
]

const HEAD = { y: -0.845, rx: 0.082, ry: 0.108, rz: 0.088 }

// arms hang slightly away from the body, and the legs sit under the hips
const ARM_X = 0.175
const ARM_DRIFT = 0.055
const LEG_X = 0.062

export class AlteaFigure {
  constructor(canvas, { points = 900, showFace = true, lineAlpha = 0.32 } = {}) {
    this.canvas = canvas
    this.ctx = canvas.getContext("2d")
    this.showFace = showFace
    this.lineAlpha = lineAlpha
    this.energy = 0
    this.time = 0
    this.running = false

    // ring resolution scales with the size we were asked for
    this.segments = points > 900 ? 26 : points > 400 ? 18 : 12
    this.surfaces = this.#buildSurfaces()
    this.hair = this.#buildHair()
    this.sparks = this.#buildSparks(Math.round(points / 6))
    this.#readColour()
  }

  start() {
    if (this.running) return
    this.running = true
    this.last = performance.now()
    this.#resize()
    this.frame = requestAnimationFrame(this.#tick)
  }

  stop() {
    this.running = false
    cancelAnimationFrame(this.frame)
  }

  drawOnce() {
    if (this.#resize() || this.w) this.#draw()
  }

  setEnergy(value) {
    this.energy = value
  }

  refresh() {
    this.#readColour()
    this.#resize()
  }

  // --- geometry ----------------------------------------------------------

  #buildSurfaces() {
    const list = []

    list.push({ sections: TORSO.map(([y, rx, rz]) => ({ x: 0, y, z: 0, rx, rz })) })

    for (const side of [-1, 1]) {
      // legs converge slightly towards the ankles
      list.push({
        sections: LEG.map(([y, rx, rz], i) => ({
          x: side * (LEG_X - i * 0.002),
          y,
          z: 0.004,
          rx,
          rz
        }))
      })

      // arms drift outward from shoulder to wrist
      list.push({
        sections: ARM.map(([y, rx, rz], i) => ({
          x: side * (ARM_X + (i / (ARM.length - 1)) * ARM_DRIFT),
          y,
          z: 0.012,
          rx,
          rz
        }))
      })
    }

    // The head is kept sparse and dim: the face has to read through it.
    const headRings = []
    for (let i = 0; i <= 6; i += 1) {
      const phi = (i / 6) * Math.PI
      headRings.push({
        x: 0,
        y: HEAD.y - Math.cos(phi) * HEAD.ry,
        z: 0,
        rx: Math.sin(phi) * HEAD.rx,
        rz: Math.sin(phi) * HEAD.rz
      })
    }
    list.push({ sections: headRings, dim: 0.45, stitch: false })

    return list
  }

  // Strands running from the scalp down past the shoulders.
  #buildHair() {
    const strands = []
    const count = 30

    for (let i = 0; i < count; i += 1) {
      const a = (i / count) * TAU
      // front of the head is negative z — leave it bare so the face shows
      if (Math.cos(a) < -0.45) continue

      const back = 0.55 + 0.45 * Math.cos(a)
      const startX = Math.sin(a) * HEAD.rx * 1.02
      const startZ = Math.cos(a) * HEAD.rz * 1.02
      const length = 0.18 + back * 0.18 + Math.random() * 0.05

      strands.push({
        x: startX,
        z: startZ,
        y: HEAD.y - HEAD.ry * (0.35 + Math.random() * 0.5),
        length,
        flare: 0.5 + Math.random() * 0.9,
        phase: Math.random() * TAU,
        alpha: 0.35 + Math.random() * 0.4
      })
    }

    return strands
  }

  // A few motes drifting inside her volume, for the nanotech feel.
  #buildSparks(count) {
    return Array.from({ length: count }, () => ({
      x: (Math.random() - 0.5) * 0.34,
      y: -0.86 + Math.random() * 1.36,
      z: (Math.random() - 0.5) * 0.18,
      s: 0.5 + Math.random() * 1.2,
      p: Math.random() * TAU
    }))
  }

  // --- rendering ---------------------------------------------------------

  #readColour() {
    const styles = getComputedStyle(this.canvas)
    this.accent = styles.getPropertyValue("--accent").trim() || "#3fe0ff"
    this.rgb = this.#toRgb(this.accent)
  }

  #toRgb(colour) {
    const probe = document.createElement("canvas").getContext("2d")
    probe.fillStyle = colour
    const hex = probe.fillStyle
    if (hex.startsWith("#")) return [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16))
    const parts = hex.match(/\d+/g)
    return parts ? parts.slice(0, 3).map(Number) : [63, 224, 255]
  }

  #resize() {
    const rect = this.canvas.getBoundingClientRect()
    if (rect.width < 1 || rect.height < 1) return false

    const ratio = Math.min(window.devicePixelRatio || 1, 2)
    this.canvas.width = Math.round(rect.width * ratio)
    this.canvas.height = Math.round(rect.height * ratio)
    this.ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
    this.w = rect.width
    this.h = rect.height
    // she spans roughly y -0.95 … 0.52, so this fills most of the frame
    this.scale = this.h * 0.53
    this.cx = this.w / 2
    this.cy = this.h / 2 + this.h * 0.11
    return true
  }

  #tick = (now) => {
    if (!this.running) return

    this.last = now
    this.time = now / 1000

    const rect = this.canvas.getBoundingClientRect()
    if (!this.w || Math.abs(rect.width - this.w) > 1 || Math.abs(rect.height - this.h) > 1) this.#resize()
    if (this.w) this.#draw()

    this.frame = requestAnimationFrame(this.#tick)
  }

  #project(x, y, z) {
    const rx = x * this.cos - z * this.sin
    const rz = x * this.sin + z * this.cos
    const depth = 2.0 / (2.0 + rz)
    return {
      sx: this.cx + rx * this.scale * depth,
      sy: this.cy + y * this.scale * depth,
      depth,
      rz
    }
  }

  #draw() {
    const { ctx } = this
    ctx.clearRect(0, 0, this.w, this.h)
    ctx.globalCompositeOperation = "lighter"

    const t = this.time
    const e = this.energy

    // she turns slowly, with a second slower sway so it never loops visibly
    this.angle = Math.sin(t * 0.15) * 0.62 + Math.sin(t * 0.061) * 0.22
    this.sin = Math.sin(this.angle)
    this.cos = Math.cos(this.angle)
    this.breath = Math.sin(t * 1.05) * 0.005
    this.rgbStr = this.rgb.join(",")

    // a bright band sweeping up her, the signature of a scan
    this.scanY = ((t * 0.22) % 1.6) - 0.95

    for (const surface of this.surfaces) this.#drawSurface(surface, e)
    this.#drawHair(t, e)
    if (this.showFace) this.#drawFace(t, e)
    this.#drawSparks(t, e)

    ctx.globalCompositeOperation = "source-over"
  }

  // One surface: its rings, plus the lines stitching ring to ring.
  #drawSurface(surface, e) {
    const { ctx } = this
    const seg = this.segments
    const dim = surface.dim ?? 1
    const rings = []

    for (const section of surface.sections) {
      const vertices = []
      for (let i = 0; i < seg; i += 1) {
        const a = (i / seg) * TAU
        const ca = Math.cos(a)
        const sa = Math.sin(a)

        const point = this.#project(
          section.x + ca * section.rx,
          section.y + this.breath,
          section.z + sa * section.rz
        )

        // rim lighting: brightest where the surface turns away from us
        const nz = ca * this.sin + sa * this.cos
        point.rim = 1 - Math.abs(nz)
        point.front = nz < 0
        vertices.push(point)
      }
      rings.push({ vertices, y: section.y })
    }

    ctx.lineWidth = 1

    // rings
    for (const ring of rings) {
      const glow = this.#scanGlow(ring.y)
      for (let i = 0; i < seg; i += 1) {
        const a = ring.vertices[i]
        const b = ring.vertices[(i + 1) % seg]
        const alpha = this.#alpha(a, e, glow) * dim
        if (alpha < 0.012) continue

        ctx.strokeStyle = `rgba(${this.rgbStr},${alpha})`
        ctx.beginPath()
        ctx.moveTo(a.sx, a.sy)
        ctx.lineTo(b.sx, b.sy)
        ctx.stroke()
      }
    }

    // lengthwise stitching, every other vertex to keep it light
    if (surface.stitch === false) return
    const step = seg > 16 ? 2 : 1
    for (let r = 0; r < rings.length - 1; r += 1) {
      const glow = this.#scanGlow((rings[r].y + rings[r + 1].y) / 2)
      for (let i = 0; i < seg; i += step) {
        const a = rings[r].vertices[i]
        const b = rings[r + 1].vertices[i]
        const alpha = this.#alpha(a, e, glow) * 0.7
        if (alpha < 0.012) continue

        ctx.strokeStyle = `rgba(${this.rgbStr},${alpha})`
        ctx.beginPath()
        ctx.moveTo(a.sx, a.sy)
        ctx.lineTo(b.sx, b.sy)
        ctx.stroke()
      }
    }
  }

  #alpha(point, e, glow) {
    const facing = point.front ? 1 : 0.32
    const rim = 0.28 + 0.72 * point.rim
    return Math.min(1, (this.lineAlpha + e * 0.3) * facing * rim * point.depth * 1.35 * glow)
  }

  // Brightness bump where the scan band currently is.
  #scanGlow(y) {
    const d = Math.abs(y - this.scanY)
    return d < 0.12 ? 1 + (1 - d / 0.12) * 1.5 : 1
  }

  #drawHair(t, e) {
    const { ctx } = this
    ctx.lineWidth = 1

    for (const strand of this.hair) {
      const sway = Math.sin(t * 0.9 + strand.phase) * 0.012 + e * 0.012 * Math.sin(t * 6 + strand.phase)
      const steps = 7
      let previous = null

      for (let i = 0; i <= steps; i += 1) {
        const k = i / steps
        // strands fall, drift outward and swing at the tip
        const point = this.#project(
          strand.x * (1 + k * 0.55 * strand.flare) + sway * k * k,
          strand.y + k * strand.length + this.breath,
          strand.z * (1 + k * 0.5) - sway * k * k * 0.4
        )

        if (previous) {
          // Nothing occludes anything in additive drawing, so strands behind
          // her head are dimmed by hand — otherwise they veil the face.
          const behind = point.rz > 0 ? 0.28 : 1
          const alpha = strand.alpha * behind * (1 - k * 0.55) * point.depth * (0.7 + e * 0.5)
          ctx.strokeStyle = `rgba(${this.rgbStr},${Math.min(1, alpha)})`
          ctx.beginPath()
          ctx.moveTo(previous.sx, previous.sy)
          ctx.lineTo(point.sx, point.sy)
          ctx.stroke()
        }
        previous = point
      }
    }
  }

  // --- the face ----------------------------------------------------------

  #drawFace(t, e) {
    // only readable when she is turned towards us
    const facing = this.cos
    if (facing < 0.18) return

    const { ctx } = this
    const fade = Math.min(1, (facing - 0.18) / 0.35)
    const y0 = HEAD.y + this.breath
    const z = -HEAD.rz * 0.86

    // a slow blink every few seconds
    const cycle = (t % 4.6) / 4.6
    const blink = cycle > 0.965 ? Math.abs(Math.cos((cycle - 0.965) / 0.035 * Math.PI)) : 1

    const stroke = (pts, alpha, width = 1) => {
      ctx.lineWidth = width
      ctx.strokeStyle = `rgba(${this.rgbStr},${Math.min(1, alpha * fade)})`
      ctx.beginPath()
      pts.forEach((p, i) => {
        const q = this.#project(p[0], y0 + p[1], z + (p[2] || 0))
        if (i === 0) ctx.moveTo(q.sx, q.sy)
        else ctx.lineTo(q.sx, q.sy)
      })
      ctx.stroke()
    }

    for (const side of [-1, 1]) {
      const ex = side * 0.032

      // almond eye: upper and lower lids meeting at the corners
      const lid = (curve, height) =>
        Array.from({ length: 11 }, (_, i) => {
          const k = i / 10
          const x = ex + (k - 0.5) * 0.046
          return [x, -0.012 + curve * height * Math.sin(k * Math.PI), 0]
        })

      stroke(lid(-1, 0.016 * blink), 0.85, 1.2)
      stroke(lid(1, 0.010 * blink), 0.7, 1.1)

      // iris and pupil
      if (blink > 0.35) {
        const ring = (r, alpha) =>
          stroke(
            Array.from({ length: 13 }, (_, i) => {
              const a = (i / 12) * TAU
              return [ex + Math.cos(a) * r, -0.012 + Math.sin(a) * r * blink, 0.004]
            }),
            alpha,
            1
          )
        ring(0.0105, 0.9)
        ring(0.0045, 1)
      }

      // brow, lifted a touch while she speaks
      stroke(
        Array.from({ length: 9 }, (_, i) => {
          const k = i / 8
          const x = ex + (k - 0.5) * 0.056
          return [x, -0.044 - Math.sin(k * Math.PI) * 0.008 - e * 0.004, 0]
        }),
        0.55,
        1.1
      )
    }

    // nose: bridge and base
    stroke([[0.004, -0.012, 0.006], [0.006, 0.014, 0.012], [-0.002, 0.020, 0.010]], 0.4)
    stroke([[-0.012, 0.021, 0.006], [0, 0.024, 0.010], [0.012, 0.021, 0.006]], 0.35)

    // lips: the gap between them is her voice
    const open = 0.003 + e * 0.020
    const lipWidth = 0.019 + e * 0.003
    const lipCurve = (dir, height) =>
      Array.from({ length: 13 }, (_, i) => {
        const k = i / 12
        return [
          (k - 0.5) * lipWidth * 2,
          0.050 + dir * (open / 2 + height * Math.sin(k * Math.PI)),
          0.004
        ]
      })

    stroke(lipCurve(-1, 0.009), 0.9, 1.3)
    stroke(lipCurve(1, 0.012 + e * 0.006), 0.9, 1.3)

    // the mouth interior darkens as it opens — drawn as a filled shape
    if (open > 0.009) {
      ctx.fillStyle = `rgba(${this.rgbStr},${Math.min(0.5, e * 0.5) * fade})`
      ctx.beginPath()
      const rim = [...lipCurve(-1, 0.002), ...lipCurve(1, 0.004).reverse()]
      rim.forEach((p, i) => {
        const q = this.#project(p[0], y0 + p[1], z + 0.004)
        if (i === 0) ctx.moveTo(q.sx, q.sy)
        else ctx.lineTo(q.sx, q.sy)
      })
      ctx.closePath()
      ctx.fill()
    }

    // jawline, to give the head a shape rather than an outline
    stroke(
      Array.from({ length: 15 }, (_, i) => {
        const k = i / 14
        const a = Math.PI * (0.15 + k * 0.7)
        return [Math.cos(a) * -0.070, 0.030 + Math.sin(a) * 0.058, 0.02]
      }),
      0.3
    )
  }

  #drawSparks(t, e) {
    const { ctx } = this

    for (const spark of this.sparks) {
      const drift = Math.sin(t * 0.7 + spark.p) * 0.01
      const point = this.#project(spark.x + drift, spark.y + this.breath, spark.z)
      const alpha = (0.12 + e * 0.35) * point.depth * this.#scanGlow(spark.y)

      ctx.fillStyle = `rgba(${this.rgbStr},${Math.min(1, alpha)})`
      ctx.beginPath()
      ctx.arc(point.sx, point.sy, spark.s * point.depth, 0, TAU)
      ctx.fill()
    }
  }
}
