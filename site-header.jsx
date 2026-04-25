// 全ページ共通ヘッダー

const HEADER_COPY = {
  ja: {
    products: 'プロダクト',
    pricing: '料金',
    install: 'インストール',
    docs: 'ドキュメント',
    roadmap: 'ロードマップ',
    faq: 'FAQ',
    follow: 'フォロー',
    toggleTheme: 'テーマ切替',
  },
  en: {
    products: 'Products',
    pricing: 'Pricing',
    install: 'Install',
    docs: 'Docs',
    roadmap: 'Roadmap',
    faq: 'FAQ',
    follow: 'Follow',
    toggleTheme: 'Toggle theme',
  },
};

const HEADER_LINKS = [
  { key: 'products', href: '/#products' },
  { key: 'pricing', href: '/#pricing' },
  { key: 'install', href: '/install.html' },
  { key: 'docs', href: '/docs.html' },
  { key: 'roadmap', href: '/#roadmap' },
  { key: 'faq', href: '/#faq' },
];

function XIcon({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

function SiteHeader({ dark, setDark, lang = 'ja', setLang, active = '', showLanguage = false }) {
  const c = HEADER_COPY[lang] || HEADER_COPY.ja;
  const toggleLang = () => setLang && setLang(l => l === 'ja' ? 'en' : 'ja');

  return (
    <nav>
      <a href="/" className="nav-logo">
        <span>alforge</span><span className="dot">.</span><span className="labs">labs</span>
      </a>
      <ul className="nav-center">
        {HEADER_LINKS.map(link => (
          <li key={link.key}>
            <a href={link.href} className={active === link.key ? 'active' : ''}>{c[link.key]}</a>
          </li>
        ))}
      </ul>
      <div className="nav-right">
        <a className="nav-page-link" href="/docs.html">{c.docs}</a>
        {showLanguage && (
          <button className="lang-btn" onClick={toggleLang}>
            {lang === 'ja' ? 'EN' : 'JA'}
          </button>
        )}
        <button className="toggle-btn" onClick={() => setDark(d => !d)} title={c.toggleTheme}>
          {dark ? '☀' : '◑'}
        </button>
        <a className="follow-btn-nav" href="https://x.com/alforge_bot" target="_blank" rel="noopener">
          <XIcon size={13} />
          <span className="follow-label">{c.follow}</span>
        </a>
      </div>
    </nav>
  );
}

function renderStandaloneHeader({ active = '' } = {}) {
  const root = document.getElementById('site-header');
  if (!root) return;

  function StandaloneHeader() {
    const savedTheme = localStorage.getItem('al_theme');
    const [dark, setDark] = React.useState(savedTheme ? savedTheme === 'dark' : true);

    React.useEffect(() => {
      const theme = dark ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', theme);
      document.body.setAttribute('data-theme', theme);
      localStorage.setItem('al_theme', theme);
    }, [dark]);

    return <SiteHeader dark={dark} setDark={setDark} lang="ja" active={active} />;
  }

  ReactDOM.createRoot(root).render(<StandaloneHeader />);
}

Object.assign(window, { SiteHeader, renderStandaloneHeader });
