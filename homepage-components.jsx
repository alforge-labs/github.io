// homepage-components.jsx
// Nav, Hero, Products, PerformanceChart

/* ── EQUITY CURVE DATA ── */
function genCurves() {
  let s = 137;
  const rng = () => { s = (s * 1664525 + 1013904223) & 0x7fffffff; return s / 0x7fffffff; };
  const n = 252;
  const strategy = [100], bench = [100];
  for (let i = 1; i < n; i++) {
    strategy.push(strategy[i-1] * (1 + 0.00095 + 0.014 * (rng() - 0.5)));
    bench.push(bench[i-1] * (1 + 0.00038 + 0.008 * (rng() - 0.5)));
  }
  return { strategy, bench, n };
}

function toSVGPath(data, W, H, pad = 16) {
  const minV = Math.min(...data), maxV = Math.max(...data);
  const xS = (W - pad*2) / (data.length - 1);
  const yS = (H - pad*2) / (maxV - minV);
  return data.map((v, i) =>
    `${i === 0 ? 'M' : 'L'}${(pad + i*xS).toFixed(1)},${(H - pad - (v-minV)*yS).toFixed(1)}`
  ).join(' ');
}

function toAreaPath(data, W, H, pad = 16) {
  const minV = Math.min(...data), maxV = Math.max(...data);
  const xS = (W - pad*2) / (data.length - 1);
  const yS = (H - pad*2) / (maxV - minV);
  const pts = data.map((v, i) =>
    `${(pad + i*xS).toFixed(1)},${(H - pad - (v-minV)*yS).toFixed(1)}`
  );
  return `M${pts[0]} ${pts.slice(1).map(p=>'L'+p).join(' ')} L${(W-pad).toFixed(1)},${H-pad} L${pad},${H-pad} Z`;
}

/* ── X ICON ── */
function XIcon({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

/* ── NAV ── */
function NavBar({ dark, setDark, lang, setLang, t }) {
  return (
    <nav>
      <a href="#" className="nav-logo">
        <span>alforge</span><span className="dot">.</span><span className="labs">labs</span>
      </a>
      <ul className="nav-center">
        <li><a href="#products">{t.nav.products}</a></li>
        <li><a href="#roadmap">{t.nav.roadmap}</a></li>
        <li><a href="#faq">{t.nav.faq}</a></li>
      </ul>
      <div className="nav-right">
        <button className="lang-btn" onClick={() => setLang(l => l === 'ja' ? 'en' : 'ja')}>
          {lang === 'ja' ? 'EN' : 'JA'}
        </button>
        <button className="toggle-btn" onClick={() => setDark(d => !d)} title="Toggle theme">
          {dark ? '☀' : '◑'}
        </button>
        <a className="follow-btn-nav" href="https://x.com/alforge_bot" target="_blank" rel="noopener">
          <XIcon size={13} />
          {t.nav.follow}
        </a>
      </div>
    </nav>
  );
}

/* ── HERO ── */
function Hero({ t }) {
  const c = t.hero;
  const stats = t.heroStats;
  return (
    <section className="hero">
      <div className="hero-inner">
        <div className="hero-tag"><span className="pulse"></span>{c.tag}</div>
        <h1 className="hero-h1">
          <span className="dim">{c.h1a}</span><br />
          <span className="accent">{c.h1b}</span>
        </h1>
        <p className="hero-desc">{c.desc}</p>
        <div className="hero-cta">
          <a href="https://x.com/alforge_bot" target="_blank" rel="noopener" className="btn-primary">
            <XIcon size={14} />{c.cta1}
          </a>
          <a href="#roadmap" className="btn-secondary">{c.cta2} →</a>
        </div>
        <div className="hero-stats">
          {stats.map((s, i) => (
            <div key={i} className="stat">
              <span className="stat-val">{s.accent ? <span className="accent">{s.val}</span> : s.val}</span>
              <span className="stat-lbl">{s.lbl}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── PRODUCTS ── */
function Products({ t }) {
  const c = t.products;
  const badgeClass = { beta: 'badge-beta', alpha: 'badge-alpha', dev: 'badge-dev' };
  return (
    <section className="products reveal" id="products">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p style={{ marginTop: '0.6rem', color: 'var(--text2)', fontSize: '0.92rem' }}>{c.subtitle}</p>
        <div className="products-grid" style={{ marginTop: '2.5rem' }}>
          {c.items.map(item => (
            <div
              key={item.id}
              className="product-card"
              style={{ '--card-accent': item.accent }}
            >
              <div className="card-top">
                <span className={`card-badge ${badgeClass[item.badgeType]}`}>{item.badge}</span>
                <div className="card-icon">{item.icon}</div>
              </div>
              <div>
                <div className="card-role">{item.role}</div>
                <div className="card-name" style={{ marginTop: '0.25rem' }}>
                  <span className="prefix">alpha-</span>{item.name}
                </div>
              </div>
              <p className="card-desc">{item.desc}</p>
              <div className="card-tags">
                {item.tags.map(tag => <span key={tag} className="tag">{tag}</span>)}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── PERFORMANCE CHART ── */
function PerformanceChart({ t, dark }) {
  const c = t.perf;
  const svgRef = React.useRef(null);
  const [animated, setAnimated] = React.useState(false);
  const curves = React.useMemo(() => genCurves(), []);
  const W = 900, H = 200, PAD = 16;

  const stratPath = React.useMemo(() => toSVGPath(curves.strategy, W, H, PAD), []);
  const stratArea = React.useMemo(() => toAreaPath(curves.strategy, W, H, PAD), []);
  const benchPath = React.useMemo(() => toSVGPath(curves.bench, W, H, PAD), []);

  // Measure path length for animation
  const pathRef = React.useRef(null);
  const [pathLen, setPathLen] = React.useState(2000);

  React.useEffect(() => {
    if (pathRef.current) {
      setPathLen(pathRef.current.getTotalLength());
    }
  }, []);

  React.useEffect(() => {
    if (!svgRef.current) return;
    const obs = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) { setAnimated(true); obs.disconnect(); }
    }, { threshold: 0.3 });
    obs.observe(svgRef.current);
    return () => obs.disconnect();
  }, []);

  const accentColor = dark ? '#00e49a' : '#009e70';
  const blueColor = dark ? '#5b9fff' : '#3a7ef0';

  return (
    <section className="performance reveal" id="performance">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title">{c.title}</h2>
        <div className="perf-inner" style={{ marginTop: '2.5rem' }}>
          <div className="perf-header">
            <div>
              <div className="perf-strategy">{c.strategy}</div>
              <div className="perf-period" style={{ marginTop: '0.2rem' }}>{c.period}</div>
            </div>
          </div>
          <div className="perf-stats">
            {c.stats.map((s, i) => (
              <div key={i} className="perf-stat">
                <span className={`perf-val ${s.cls}`}>{s.val}</span>
                <span className="perf-lbl">{s.label}</span>
              </div>
            ))}
          </div>
          <div className="chart-area" ref={svgRef}>
            <div className="chart-legend">
              {c.legend.map((l, i) => (
                <div key={i} className="legend-item">
                  <div className="legend-dot" style={{ background: l.color, height: i === 1 ? '1px' : '2px' }}></div>
                  {l.label}
                </div>
              ))}
            </div>
            <svg
              viewBox={`0 0 ${W} ${H}`}
              style={{ width: '100%', height: 'auto', display: 'block', overflow: 'visible' }}
              preserveAspectRatio="none"
            >
              <defs>
                <linearGradient id="stratGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={accentColor} stopOpacity="0.22" />
                  <stop offset="100%" stopColor={accentColor} stopOpacity="0" />
                </linearGradient>
                <clipPath id="chartClip">
                  <rect
                    x="0" y="0" width={animated ? W : 0} height={H}
                    style={{ transition: animated ? `width 1.6s cubic-bezier(0.22,1,0.36,1)` : 'none' }}
                  />
                </clipPath>
              </defs>
              {/* Strategy area */}
              <path d={stratArea} fill="url(#stratGrad)" clipPath="url(#chartClip)" />
              {/* Strategy line */}
              <path
                ref={pathRef}
                d={stratPath}
                fill="none"
                stroke={accentColor}
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                clipPath="url(#chartClip)"
              />
            </svg>
            <p className="chart-note">{c.note}</p>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ── EXPORT ── */
Object.assign(window, { NavBar, Hero, Products, PerformanceChart });
