// homepage-components.jsx
// Nav, Hero, Products, PerformanceChart

/* ── PERF CHART HELPERS ── */
const CHART = {
  W: 480, H: 165,
  PAD: { l: 50, r: 10, t: 18, b: 22 },
  Y_MIN: 75, Y_MAX: 212,
};

function chartX(i, n) {
  return CHART.PAD.l + (i / (n - 1)) * (CHART.W - CHART.PAD.l - CHART.PAD.r);
}
function chartY(v) {
  const norm = Math.max(0, Math.min(1, (v - CHART.Y_MIN) / (CHART.Y_MAX - CHART.Y_MIN)));
  return CHART.PAD.t + (1 - norm) * (CHART.H - CHART.PAD.t - CHART.PAD.b);
}
function toPoints(arr) {
  return arr.map((v, i) => `${chartX(i, arr.length).toFixed(1)},${chartY(v).toFixed(1)}`).join(' ');
}
function toFillPoints(arr) {
  const n = arr.length;
  const bottom = (CHART.H - CHART.PAD.b + 5).toFixed(1);
  return toPoints(arr) + ` ${chartX(n - 1, n).toFixed(1)},${bottom} ${CHART.PAD.l},${bottom}`;
}

/* ── NAV ── */
function NavBar({ dark, setDark, lang, setLang }) {
  return <SiteHeader dark={dark} setDark={setDark} lang={lang} setLang={setLang} showLanguage={true} />;
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
          <a href="#pricing" className="btn-primary">
            {c.cta1}
          </a>
          <a href="#pricing" className="btn-secondary">{c.cta2} →</a>
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
  const ec = window.EQUITY_CURVE;
  if (!ec) return null;
  const accentColor = dark ? '#00e49a' : '#009e70';
  const blueColor   = dark ? '#5b9fff' : '#3a7ef0';
  const amberColor  = dark ? '#f5a623' : '#d97706';

  const gridLines = [
    { v: 200, label: '+100%' },
    { v: 170, label: '+70%'  },
    { v: 140, label: '+40%'  },
    { v: 110, label: '+10%'  },
    { v: 80,  label: '-20%'  },
  ];

  return (
    <section className="performance reveal" id="performance">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title">{c.title}</h2>
        <div className="perf-inner" style={{ marginTop: '2.5rem' }}>

          {/* Header */}
          <div className="perf-header">
            <div>
              <div className="perf-strategy">{c.strategy}</div>
              <div className="perf-period" style={{ marginTop: '0.2rem' }}>{c.period}</div>
            </div>
          </div>

          {/* Stats row */}
          <div className="perf-stats">
            {c.stats.map((s, i) => (
              <div key={i} className="perf-stat">
                <span className={`perf-val ${s.cls}`}>{s.val}</span>
                <span className="perf-lbl">{s.label}</span>
              </div>
            ))}
          </div>

          {/* Chart area */}
          <div className="chart-area">
            {/* Legend */}
            <div className="chart-legend">
              <div className="legend-item">
                <div className="legend-dot" style={{ background: accentColor, height: '2px' }}></div>
                {c.legend[0].label}
              </div>
              <div className="legend-item">
                <div className="legend-dot" style={{ background: blueColor, height: '1px', borderTop: `1px dashed ${blueColor}` }}></div>
                {c.legend[1].label}
              </div>
              <div className="legend-item">
                <div className="legend-dot" style={{ background: amberColor, height: '1px', borderTop: `1px dashed ${amberColor}` }}></div>
                {c.legend[2].label}
              </div>
            </div>

            {/* SVG chart */}
            <svg
              viewBox={`0 0 ${CHART.W} ${CHART.H}`}
              style={{ width: '100%', display: 'block', background: 'var(--bg2)', borderRadius: 'var(--r)' }}
              preserveAspectRatio="none"
            >
              {/* Grid lines */}
              {gridLines.map(({ v, label }) => {
                const y = chartY(v).toFixed(1);
                return (
                  <g key={v}>
                    <line x1={CHART.PAD.l} y1={y} x2={CHART.W - CHART.PAD.r} y2={y} stroke="var(--border)" strokeWidth="1" />
                    <text x={CHART.PAD.l - 4} y={y} fill="var(--text3)" fontSize="8" fontFamily="var(--mono)" textAnchor="end" dominantBaseline="middle">{label}</text>
                  </g>
                );
              })}

              {/* Baseline at 0% (value=100) */}
              <line
                x1={CHART.PAD.l} y1={chartY(100).toFixed(1)}
                x2={CHART.W - CHART.PAD.r} y2={chartY(100).toFixed(1)}
                stroke="var(--text3)" strokeWidth="0.5" strokeDasharray="2,2"
              />

              {/* X-axis year labels */}
              {ec.yearLabels.map((yr, i) => {
                const x = chartX(ec.yearIndices[i], ec.cl.length);
                return (
                  <text key={yr} x={x.toFixed(1)} y={(CHART.H - 4).toFixed(1)} fill="var(--text3)" fontSize="8" fontFamily="var(--mono)" textAnchor="middle">{yr}</text>
                );
              })}

              {/* QQQ B&H (rendered first = behind) */}
              <polyline
                points={toPoints(ec.qqq)}
                fill="none" stroke={amberColor} strokeWidth="1.2" strokeDasharray="4,3" opacity="0.7"
              />

              {/* SPY B&H */}
              <polyline
                points={toPoints(ec.spy)}
                fill="none" stroke={blueColor} strokeWidth="1.2" strokeDasharray="5,4" opacity="0.85"
              />

              {/* CL strategy fill */}
              <polygon
                points={toFillPoints(ec.cl)}
                fill={accentColor} fillOpacity="0.06"
              />

              {/* CL strategy line (rendered last = on top) */}
              <polyline
                points={toPoints(ec.cl)}
                fill="none" stroke={accentColor} strokeWidth="2.5"
              />
            </svg>

            {/* Benchmark comparison table */}
            <div style={{ marginTop: '0.75rem', background: 'var(--bg2)', borderRadius: 'var(--r)', padding: '0.75rem 1rem' }}>
              <div style={{ fontFamily: 'var(--mono)', fontSize: '0.62rem', color: 'var(--text3)', marginBottom: '0.45rem', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                {c.bench.label}
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '0.3rem', fontFamily: 'var(--mono)', fontSize: '0.68rem' }}>
                {c.bench.headers.map((h, i) => (
                  <div key={i} style={{ color: i === 0 ? 'transparent' : i === 1 ? blueColor : i === 2 ? amberColor : accentColor }}>{h}</div>
                ))}
                {c.bench.rows.map((row, ri) => (
                  <React.Fragment key={ri}>
                    <div style={{ color: 'var(--text2)' }}>{row.metric}</div>
                    <div style={{ color: blueColor }}>{row.spy}</div>
                    <div style={{ color: amberColor }}>{row.qqq}</div>
                    <div style={{ color: accentColor, fontWeight: row.stratWin ? '600' : '400' }}>
                      {row.strat}{row.stratWin ? ' ✓' : ''}
                    </div>
                  </React.Fragment>
                ))}
              </div>
            </div>

            <p className="chart-note">{c.note}</p>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ── PRICING ── */
function Pricing({ t }) {
  const c = t.pricing;
  return (
    <section className="pricing reveal" id="pricing">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p style={{ marginTop: '0.6rem', color: 'var(--text2)', fontSize: '0.92rem' }}>{c.subtitle}</p>
        <div className="pricing-grid" style={{ marginTop: '2.5rem' }}>
          {c.plans.map((plan, i) => (
            <div key={i} className={`pricing-card${plan.featured ? ' featured' : ''}`}>
              <div className="pricing-card-top">
                <div className="pricing-plan">{plan.name}</div>
                {plan.badge && <span className="pricing-badge">{plan.badge}</span>}
              </div>
              <div className="pricing-price">
                <span className="price-amount">{plan.price}</span>
                <span className="price-period">{plan.period}</span>
              </div>
              <p className="pricing-desc">{plan.desc}</p>
              <ul className="pricing-features">
                {plan.features.map((f, j) => (
                  <li key={j} className="pricing-feature">
                    <span className="feature-check">✓</span>
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="#roadmap"
                className={plan.featured ? 'btn-primary' : 'btn-secondary'}
                style={{ justifyContent: 'center', marginTop: 'auto', flexDirection: 'column', gap: '2px' }}
              >
                <s>{c.buyNow}</s>
                <span style={{ fontSize: '0.85em', fontWeight: 400 }}>{c.comingSummer}</span>
              </a>
            </div>
          ))}
        </div>
        <p className="pricing-note">{c.note}</p>
      </div>
    </section>
  );
}

/* ── USE CASES ── */
function UseCases({ t }) {
  const c = t.usecases;
  return (
    <section className="usecases reveal" id="usecases">
      <div className="usecases-inner">
        <div className="usecases-header">
          <div className="sec-label">{c.label}</div>
          <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
          <p className="usecases-subtitle">{c.subtitle}</p>
        </div>
        <div className="usecases-grid">
          {c.items.map((item, i) => (
            <div
              key={i}
              className="usecase-card"
              style={{ '--card-accent': item.accent }}
            >
              <div className="usecase-icon">{item.icon}</div>
              <span className="usecase-badge">{item.label}</span>
              <div className="usecase-title">{item.title}</div>
              <p className="usecase-desc">{item.desc}</p>
              <div className="usecase-tags">
                {item.tags.map((tag, j) => (
                  <span key={j} className="tag">{tag}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── EXPORT ── */
Object.assign(window, { NavBar, Hero, Products, PerformanceChart, Pricing, UseCases });
