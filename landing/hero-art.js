/**
 * Kairo Landing Page — "Amber Neural Pulse"
 * Generative art animation for the hero section.
 *
 * Architecture:
 *   - Proper Perlin noise (permutation-table based) for smooth organic motion
 *   - Multi-layered flow field: macro drift + local swirls + micro perturbations
 *   - Particle system with amber/orange hues, alpha pulsing, edge wrapping
 *   - Connection graph: nearby particles form glowing edges (amber → orange gradient)
 *   - Mouse/touch repulsion for interactivity
 *   - prefers-reduced-motion: renders one static frame and stops
 *   - Mobile: reduced particle count + 30 fps cap
 *
 * No external dependencies — pure vanilla JS Canvas API.
 */
(function () {
  "use strict";

  // ---------------------------------------------------------------------------
  // Canvas setup
  // ---------------------------------------------------------------------------
  const canvas = document.getElementById("hero-canvas");
  if (!canvas) {
    return;
  }

  const ctx = canvas.getContext("2d");

  // ---------------------------------------------------------------------------
  // Perlin Noise (classic 2-D, permutation table)
  // ---------------------------------------------------------------------------
  class PerlinNoise {
    constructor(seed) {
      this._perm = new Uint8Array(512);
      const p = new Uint8Array(256);
      for (let i = 0; i < 256; i++) {
        p[i] = i;
      }

      // Seeded shuffle (Knuth / Fisher-Yates)
      let s = seed >>> 0 || 12345;
      for (let i = 255; i > 0; i--) {
        s = (s * 1664525 + 1013904223) >>> 0;
        const j = s % (i + 1);
        const tmp = p[i];
        p[i] = p[j];
        p[j] = tmp;
      }
      for (let i = 0; i < 512; i++) {
        this._perm[i] = p[i & 255];
      }
    }

    _fade(t) {
      return t * t * t * (t * (t * 6 - 15) + 10);
    }
    _lerp(a, b, t) {
      return a + t * (b - a);
    }
    _grad(hash, x, y) {
      const h = hash & 3;
      const u = h < 2 ? x : y;
      const v = h < 2 ? y : x;
      return (h & 1 ? -u : u) + (h & 2 ? -v : v);
    }

    /** Returns value in [-1, 1] */
    noise(x, y) {
      const X = Math.floor(x) & 255;
      const Y = Math.floor(y) & 255;
      x -= Math.floor(x);
      y -= Math.floor(y);
      const u = this._fade(x);
      const v = this._fade(y);
      const p = this._perm;
      const a = p[X] + Y;
      const aa = p[a];
      const ab = p[a + 1];
      const b = p[X + 1] + Y;
      const ba = p[b];
      const bb = p[b + 1];
      return this._lerp(
        this._lerp(this._grad(p[aa], x, y), this._grad(p[ba], x - 1, y), u),
        this._lerp(this._grad(p[ab], x, y - 1), this._grad(p[bb], x - 1, y - 1), u),
        v,
      );
    }

    /** Layered octaves for richer texture */
    octave(x, y, octaves, persistence) {
      let val = 0,
        amp = 1,
        max = 0,
        freq = 1;
      for (let o = 0; o < octaves; o++) {
        val += this.noise(x * freq, y * freq) * amp;
        max += amp;
        amp *= persistence;
        freq *= 2;
      }
      return val / max;
    }
  }

  // ---------------------------------------------------------------------------
  // Constants & config (derived after sizing)
  // ---------------------------------------------------------------------------
  const isMobile = window.innerWidth < 768;

  const PARTICLE_COUNT = isMobile ? 40 : 110;
  const CONNECTION_DIST = isMobile ? 80 : 130;
  const FLOW_SCALE = 0.0018; // spatial zoom into the noise field
  const FLOW_SPEED = 0.00035; // how fast the field evolves in time
  const PARTICLE_SPEED = 0.65; // px/frame speed cap
  const PARTICLE_ALPHA_MIN = 0.28;
  const PARTICLE_ALPHA_MAX = 0.88;
  const LINE_ALPHA_MAX = 0.38;
  const TRAIL_ALPHA = 0.14; // background fade (lower = longer trails)
  const AMBIENT_BG = "rgba(10, 15, 30, " + TRAIL_ALPHA + ")";

  // Color palette — amber & orange family
  const COLORS = ["#f59e0b", "#f59e0b", "#f59e0b", "#f97316", "#fb923c", "#fbbf24"];

  // ---------------------------------------------------------------------------
  // Noise instance
  // ---------------------------------------------------------------------------
  const perlin = new PerlinNoise(42);

  /**
   * Multi-layer flow-field angle at (x, y, t).
   * Macro scale: cardinal drift (subconscious).
   * Mid scale: local swirls (conscious processing).
   * Micro: individual personality perturbation.
   */
  function flowAngle(x, y, t) {
    const macro = perlin.octave(x * FLOW_SCALE + t * 0.12, y * FLOW_SCALE + t * 0.09, 2, 0.5);
    const mid = perlin.octave(
      x * FLOW_SCALE * 3.5 + t * 0.22 + 100,
      y * FLOW_SCALE * 3.5 + t * 0.18 + 100,
      2,
      0.5,
    );
    const micro = perlin.noise(
      x * FLOW_SCALE * 9 + t * 0.45 + 200,
      y * FLOW_SCALE * 9 + t * 0.38 + 200,
    );
    return (macro * 0.55 + mid * 0.33 + micro * 0.12) * Math.PI * 4;
  }

  // ---------------------------------------------------------------------------
  // Mouse / touch state
  // ---------------------------------------------------------------------------
  const mouse = { x: null, y: null };

  function attachPointerListeners(target) {
    target.addEventListener("mousemove", (e) => {
      const r = canvas.getBoundingClientRect();
      mouse.x = e.clientX - r.left;
      mouse.y = e.clientY - r.top;
    });
    target.addEventListener("mouseleave", () => {
      mouse.x = null;
      mouse.y = null;
    });
    target.addEventListener(
      "touchmove",
      (e) => {
        const touch = e.touches[0];
        const r = canvas.getBoundingClientRect();
        mouse.x = touch.clientX - r.left;
        mouse.y = touch.clientY - r.top;
      },
      { passive: true },
    );
    target.addEventListener("touchend", () => {
      mouse.x = null;
      mouse.y = null;
    });
  }

  const pointerTarget = canvas.parentElement || canvas;
  attachPointerListeners(pointerTarget);

  // ---------------------------------------------------------------------------
  // Canvas resize
  // ---------------------------------------------------------------------------
  function resize() {
    const parent = canvas.parentElement;
    canvas.width = (parent ? parent.offsetWidth : 0) || window.innerWidth;
    canvas.height = (parent ? parent.offsetHeight : 0) || window.innerHeight;
  }
  resize();

  // ---------------------------------------------------------------------------
  // Particle class
  // ---------------------------------------------------------------------------
  class Particle {
    constructor() {
      this._init(true);
    }

    _init(randomAge) {
      this.x = Math.random() * canvas.width;
      this.y = Math.random() * canvas.height;
      this.vx = (Math.random() - 0.5) * 0.4;
      this.vy = (Math.random() - 0.5) * 0.4;
      this.size = Math.random() * 1.8 + 0.8; // 0.8–2.6 px
      this.color = COLORS[Math.floor(Math.random() * COLORS.length)];
      this.age = randomAge ? Math.random() * 1000 : 0;
      this.life = randomAge ? Math.floor(Math.random() * 400) : 0;
      this.maxLife = 320 + Math.random() * 220;
      this.pulseMag = Math.random() * 0.3 + 0.7; // individual brightness depth
      this.alpha = PARTICLE_ALPHA_MIN;
    }

    respawn() {
      this._init(false);
      // Respawn at a random edge to maintain density without teleport pop
      const side = Math.floor(Math.random() * 4);
      if (side === 0) {
        this.x = Math.random() * canvas.width;
        this.y = -5;
      } else if (side === 1) {
        this.x = canvas.width + 5;
        this.y = Math.random() * canvas.height;
      } else if (side === 2) {
        this.x = Math.random() * canvas.width;
        this.y = canvas.height + 5;
      } else {
        this.x = -5;
        this.y = Math.random() * canvas.height;
      }
    }

    update(t) {
      this.life++;
      if (this.life > this.maxLife) {
        this.respawn();
        return;
      }

      // Flow field force (layered Perlin)
      const angle = flowAngle(this.x, this.y, t);
      this.vx += Math.cos(angle) * 0.09;
      this.vy += Math.sin(angle) * 0.09;

      // Mouse repulsion (gentle, 100 px radius)
      if (mouse.x !== null) {
        const dx = this.x - mouse.x;
        const dy = this.y - mouse.y;
        const d2 = dx * dx + dy * dy;
        if (d2 < 10000 && d2 > 0.01) {
          // 100px^2
          const d = Math.sqrt(d2);
          const f = (100 - d) * 0.0025;
          this.vx += (dx / d) * f;
          this.vy += (dy / d) * f;
        }
      }

      // Speed cap
      const spd = Math.sqrt(this.vx * this.vx + this.vy * this.vy);
      if (spd > PARTICLE_SPEED) {
        this.vx = (this.vx / spd) * PARTICLE_SPEED;
        this.vy = (this.vy / spd) * PARTICLE_SPEED;
      }

      // Friction
      this.vx *= 0.965;
      this.vy *= 0.965;

      this.x += this.vx;
      this.y += this.vy;

      // Wrap around canvas edges
      if (this.x < -10) {
        this.x = canvas.width + 10;
      } else if (this.x > canvas.width + 10) {
        this.x = -10;
      }
      if (this.y < -10) {
        this.y = canvas.height + 10;
      } else if (this.y > canvas.height + 10) {
        this.y = -10;
      }

      // Alpha pulse: life fade-in/out envelope × personal pulse
      const lifeRatio = this.life / this.maxLife;
      const envelope =
        lifeRatio < 0.1 ? lifeRatio / 0.1 : lifeRatio > 0.85 ? (1 - lifeRatio) / 0.15 : 1.0;
      const pulse = Math.sin(this.age * 0.048 + t * 2.2) * 0.5 + 0.5;
      this.alpha =
        (PARTICLE_ALPHA_MIN + pulse * (PARTICLE_ALPHA_MAX - PARTICLE_ALPHA_MIN) * this.pulseMag) *
        envelope;

      this.age++;
    }

    draw(ctx) {
      ctx.save();
      ctx.globalAlpha = Math.max(0, Math.min(1, this.alpha));
      ctx.fillStyle = this.color;
      // Small radial glow
      ctx.shadowColor = this.color;
      ctx.shadowBlur = this.size * 2.5;
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // Connection drawing
  // ---------------------------------------------------------------------------
  function drawConnections(particles) {
    const n = particles.length;
    for (let i = 0; i < n; i++) {
      const pi = particles[i];
      for (let j = i + 1; j < n; j++) {
        const pj = particles[j];
        const dx = pi.x - pj.x;
        const dy = pi.y - pj.y;
        const d2 = dx * dx + dy * dy;
        if (d2 < CONNECTION_DIST * CONNECTION_DIST) {
          const d = Math.sqrt(d2);
          const t = 1 - d / CONNECTION_DIST; // 0→1 as distance → 0
          // Combine particle alphas with distance falloff for organic feel
          const alpha =
            (t * t * LINE_ALPHA_MAX * Math.min(pi.alpha, pj.alpha)) / PARTICLE_ALPHA_MAX;
          if (alpha < 0.005) {
            continue;
          }

          const grad = ctx.createLinearGradient(pi.x, pi.y, pj.x, pj.y);
          grad.addColorStop(0, pi.color);
          grad.addColorStop(1, pj.color);

          ctx.save();
          ctx.globalAlpha = alpha;
          ctx.strokeStyle = grad;
          ctx.lineWidth = 0.55 + t * 0.45; // slightly thicker for close pairs
          ctx.shadowColor = "#f59e0b";
          ctx.shadowBlur = 2;
          ctx.beginPath();
          ctx.moveTo(pi.x, pi.y);
          ctx.lineTo(pj.x, pj.y);
          ctx.stroke();
          ctx.restore();
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Static frame (prefers-reduced-motion fallback)
  // ---------------------------------------------------------------------------
  function drawStaticFrame() {
    ctx.fillStyle = "#0a0f1e";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Place 60 particles deterministically
    const pts = [];
    const lcg = (function () {
      let s = 9973;
      return function () {
        s = (s * 1664525 + 1013904223) >>> 0;
        return s / 0xffffffff;
      };
    })();

    for (let i = 0; i < 60; i++) {
      pts.push({
        x: lcg() * canvas.width,
        y: lcg() * canvas.height,
        size: lcg() * 1.8 + 0.8,
        color: COLORS[Math.floor(lcg() * COLORS.length)],
        alpha: 0.55,
      });
    }

    // Draw 15 connections among the first 20 points
    for (let i = 0; i < 20; i++) {
      for (let j = i + 1; j < 20; j++) {
        const dx = pts[i].x - pts[j].x;
        const dy = pts[i].y - pts[j].y;
        const d = Math.sqrt(dx * dx + dy * dy);
        if (d < CONNECTION_DIST) {
          ctx.save();
          ctx.globalAlpha = (1 - d / CONNECTION_DIST) * 0.3;
          ctx.strokeStyle = "#f59e0b";
          ctx.lineWidth = 0.5;
          ctx.beginPath();
          ctx.moveTo(pts[i].x, pts[i].y);
          ctx.lineTo(pts[j].x, pts[j].y);
          ctx.stroke();
          ctx.restore();
        }
      }
    }

    // Draw dots
    pts.forEach((p) => {
      ctx.save();
      ctx.globalAlpha = p.alpha;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });
  }

  // ---------------------------------------------------------------------------
  // Reduced-motion guard
  // ---------------------------------------------------------------------------
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (prefersReducedMotion) {
    drawStaticFrame();
    return;
  }

  // ---------------------------------------------------------------------------
  // Particle pool
  // ---------------------------------------------------------------------------
  const particles = [];
  for (let i = 0; i < PARTICLE_COUNT; i++) {
    particles.push(new Particle());
  }

  // Respawn particles when the canvas is resized
  window.addEventListener("resize", () => {
    resize();
    particles.forEach((p) => {
      p.x = Math.random() * canvas.width;
      p.y = Math.random() * canvas.height;
      p.life = 0;
    });
  });

  // ---------------------------------------------------------------------------
  // Initial fill so trails don't bleed from a blank canvas
  // ---------------------------------------------------------------------------
  ctx.fillStyle = "#0a0f1e";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // ---------------------------------------------------------------------------
  // Animation loop
  // ---------------------------------------------------------------------------
  let t = 0;
  let animId = null;
  let lastFrameTime = 0;
  const MOBILE_FRAME_MS = 33; // ~30 fps

  function animate(now) {
    // Mobile frame-rate cap
    if (isMobile && now - lastFrameTime < MOBILE_FRAME_MS) {
      animId = requestAnimationFrame(animate);
      return;
    }
    lastFrameTime = now;

    // Trail: semi-transparent fill creates motion blur / persistence effect
    ctx.fillStyle = AMBIENT_BG;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Update all particles
    particles.forEach((p) => p.update(t));

    // Connections drawn below particles
    drawConnections(particles);

    // Particles on top
    particles.forEach((p) => p.draw(ctx));

    t += FLOW_SPEED;

    animId = requestAnimationFrame(animate);
  }

  animId = requestAnimationFrame(animate);

  // ---------------------------------------------------------------------------
  // Page visibility API — pause when tab is hidden to save CPU/GPU
  // ---------------------------------------------------------------------------
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      if (animId !== null) {
        cancelAnimationFrame(animId);
        animId = null;
      }
    } else {
      if (animId === null) {
        animId = requestAnimationFrame(animate);
      }
    }
  });
})();
