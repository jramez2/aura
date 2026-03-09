import './style.css';
import { createIcons, LayoutDashboard, Wallet, ReceiptText, User, LogOut, Menu, X, Plus, ChevronRight, ChevronDown, Edit2, TrendingUp, TrendingDown, Bell, Search, DollarSign, Calendar, PieChart, Save, Trash2, RefreshCw, Sun, Moon, Banknote, CreditCard, Scale, AlertTriangle, FolderPlus, Tag, BarChart3 } from 'lucide';
import { Chart } from 'chart.js/auto';
import * as XLSX from 'xlsx';

// --- State Management ---
const state = {
  user: JSON.parse(localStorage.getItem('aura_user')) || null,
  isSidebarOpen: window.innerWidth > 1024,
  currentRoute: '/',
  token: localStorage.getItem('aura_token') || null,
  data: {
    gastos: [],
    presupuestos: [],
    categorias: [],       // lista plana de categorías (sin depender del mes)
    annualData: null,     // consolidado anual
    stats: { balance: 0, presupuesto: 0, gastosMes: 0 },
    lastFetched: null
  },
  isLoading: false,
  expandedSection: null,
  activeModal: null,
  selectedMonth: new Date().getMonth() + 1,
  selectedYear: new Date().getFullYear(),
  selectedMonthExpenses: new Date().getMonth() + 1,
  selectedYearExpenses: new Date().getFullYear(),
  selectedAnnualYear: new Date().getFullYear(),
  filters: {
    search: '',
    category: '',
    date: '',
    minAmount: '',
    maxAmount: ''
  },
  theme: localStorage.getItem('aura_theme') || 'dark'
};

const API_BASE_URL = 'https://adminnube.com/aura/api/v1';

const BASE_PATH = '/aura';

// --- Utilities ---
const navigate = (path) => {
  state.currentRoute = path;
  if (window.innerWidth <= 1024) {
    state.isSidebarOpen = false;
  }
  const fullPath = path === '/' ? BASE_PATH + '/' : BASE_PATH + path;
  window.history.pushState({}, '', fullPath);
  render();
};

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(amount || 0);
};

const getMonthName = (m) => {
  const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  return months[m - 1];
};

// --- API Service (Basic) ---
const api = {
  async fetch(endpoint, options = {}) {
    state.isLoading = true;
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${state.token}`,
          ...options.headers,
        },
      });

      const result = await response.json();
      if (!response.ok) throw new Error(result.message || 'Error en la petición');
      return result;
    } catch (err) {
      showToast(err.message, 'error');
      throw err;
    } finally {
      state.isLoading = false;
    }
  },

  async login(email, password) {
    const result = await this.fetch('/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
    if (result.status === 'success') {
      state.token = result.data.token;
      state.user = result.data.user;
      localStorage.setItem('aura_token', state.token);
      localStorage.setItem('aura_user', JSON.stringify(state.user));
      navigate('/dashboard');
    }
  },

  async register(nombre, email, password) {
    const result = await this.fetch('/registro', {
      method: 'POST',
      body: JSON.stringify({ nombre, email, password })
    });
    if (result.status === 'success') {
      showToast('Registro exitoso. Inicia sesión.', 'success');
      navigate('/login');
    }
  }
};

const showToast = (message, type = 'info') => {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerText = message;
  document.body.appendChild(toast);
  setTimeout(() => {
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }, 100);
};

// --- UI Components ---

const Logo = (size = 32) => `
  <div class="logo-container" style="gap: 12px; margin-bottom: 0;">
    <svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none">
      <rect width="64" height="64" rx="16" fill="url(#logoGrad)"/>
      <path d="M32 12C20.9543 12 12 20.9543 12 32C12 43.0457 20.9543 52 32 52C43.0457 52 52 43.0457 52 32C52 20.9543 43.0457 12 32 12ZM32 18C39.732 18 46 24.268 46 32C46 39.732 39.732 46 32 46C24.268 46 18 39.732 18 32C18 24.268 24.268 18 32 18ZM32 24C36.4183 24 40 27.5817 40 32C40 36.4183 36.4183 40 32 40C27.5817 40 24 36.4183 24 32C24 27.5817 27.5817 24 32 24Z" fill="white"/>
      <defs>
        <linearGradient id="logoGrad" x1="0" y1="0" x2="64" y2="64" gradientUnits="userSpaceOnUse">
          <stop stop-color="#3B82F6"/><stop offset="1" stop-color="#06B6D4"/>
        </linearGradient>
      </defs>
    </svg>
    <span class="logo-text" style="font-size: ${size * 0.75}px">Aura</span>
  </div>
`;

const LandingPage = () => `
  <div class="view-container">
    <nav class="landing-navbar">
      ${Logo(36)}
      <div style="display: flex; gap: 1rem;">
        <button class="btn btn-outline" id="btn-login" style="padding: 0.5rem 1.25rem; font-size: 0.9rem;">Entrar</button>
        <button class="btn btn-primary" id="btn-register" style="padding: 0.5rem 1.25rem; font-size: 0.9rem;">Registrarse</button>
      </div>
    </nav>
    <main class="landing-hero">
      <div class="hero-glow"></div>
      <div class="hero-badge">Aura Fintech • Inteligencia Financiera</div>
      <h1 class="hero-title">Domina tus Finanzas con Aura</h1>
      <p class="hero-subtitle">La plataforma definitiva para gestionar presupuestos, registrar gastos y tomar decisiones financieras inteligentes con simplicidad y potencia.</p>
      <div class="hero-actions">
        <button class="btn btn-primary" id="btn-cta" style="padding: 1rem 2rem; font-size: 1.1rem;">Comenzar ahora <i data-lucide="chevron-right"></i></button>

      </div>
    </main>
  </div>
`;

const AuthPage = (type) => {
  const titles = {
    login: { title: 'Bienvenido de nuevo', subtitle: 'Ingresa tus credenciales para continuar', btn: 'Entrar', footer: "¿No tienes una cuenta? <a href='#' id='link-register' class='auth-link'>Regístrate</a>" },
    register: { title: 'Crea tu cuenta', subtitle: 'Comienza gratis hoy mismo por 14 días', btn: 'Crear cuenta', footer: "¿Ya tienes cuenta? <a href='#' id='link-login' class='auth-link'>Inicia sesión</a>" },
    recover: { title: 'Recuperar contraseña', subtitle: 'Enviaremos un enlace a tu correo', btn: 'Enviar enlace', footer: "<a href='#' id='link-login-back' class='auth-link'>Volver al inicio de sesión</a>" }
  };
  const config = titles[type];

  return `
  <div class="auth-wrapper">
    <div class="auth-card">
      <div class="auth-header">
        ${Logo(40)}
        <h2 class="auth-title">${config.title}</h2>
        <p class="auth-subtitle">${config.subtitle}</p>
      </div>
      <form id="auth-form">
        ${type === 'register' ? `
          <div class="form-group">
            <label class="form-label">Nombre Completo</label>
            <input type="text" class="form-input" placeholder="Juan Pérez" required>
          </div>
        ` : ''}
        <div class="form-group">
          <label class="form-label">Correo Electrónico</label>
          <input type="email" class="form-input" placeholder="email@ejemplo.com" required>
        </div>
        ${type !== 'recover' ? `
          <div class="form-group">
            <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
               <label class="form-label" style="margin-bottom: 0;">Contraseña</label>
               ${type === 'login' ? `<a href="#" id="link-recover" class="auth-link" style="font-size: 0.75rem;">¿Olvidaste tu contraseña?</a>` : ''}
            </div>
            <input type="password" class="form-input" placeholder="••••••••" required>
          </div>
        ` : ''}
        <button type="submit" class="btn btn-primary" style="margin-top: 1rem;">${config.btn}</button>
      </form>
      <div class="auth-footer">${config.footer}</div>
    </div>
  </div>
  `;
};

const Sidebar = () => `
  <aside class="sidebar ${state.isSidebarOpen ? 'open' : ''}">
    <div class="sidebar-header">
      ${Logo(28)}
    </div>
    <nav class="sidebar-nav">
      <a href="/dashboard" class="nav-item ${state.currentRoute === '/dashboard' ? 'active' : ''}" data-route="/dashboard">
        <i data-lucide="layout-dashboard" size="20"></i> Dashboard
      </a>
      <a href="/budget" class="nav-item ${state.currentRoute === '/budget' ? 'active' : ''}" data-route="/budget">
        <i data-lucide="wallet" size="20"></i> Presupuesto
      </a>
      <a href="/expenses" class="nav-item ${state.currentRoute === '/expenses' ? 'active' : ''}" data-route="/expenses">
        <i data-lucide="receipt-text" size="20"></i> Gastos
      </a>
      <a href="/annual" class="nav-item ${state.currentRoute === '/annual' ? 'active' : ''}" data-route="/annual">
        <i data-lucide="bar-chart-3" size="20"></i> Consolidado Anual
      </a>
      <a href="/profile" class="nav-item ${state.currentRoute === '/profile' ? 'active' : ''}" data-route="/profile">
        <i data-lucide="user" size="20"></i> Perfil
      </a>
    </nav>
    <div class="sidebar-footer">
      <a href="/" class="nav-item" id="btn-logout">
        <i data-lucide="log-out" size="20"></i> Cerrar Sesión
      </a>
    </div>
  </aside>
`;

const Header = () => `
  <header class="header">
    <div style="display: flex; align-items: center; gap: 1rem;">
      <button class="hamburger" id="sidebar-toggle" style="z-index: 101;">
        <i data-lucide="${state.isSidebarOpen ? 'x' : 'menu'}" style="width: 24px; height: 24px;"></i>
      </button>
    </div>
    <div style="display: flex; align-items: center; gap: 1rem;">
      <div id="theme-toggle" class="theme-btn" style="cursor: pointer; color: var(--text-muted); display: flex; align-items: center; justify-content: center; width: 40px; height: 40px; border-radius: 12px; background: var(--surface); transition: var(--transition); border: 1px solid var(--border);" onclick="toggleTheme()">
        <i data-lucide="${state.theme === 'dark' ? 'sun' : 'moon'}" size="20"></i>
      </div>
      <div style="position: relative; cursor: pointer; color: var(--text-muted); display: flex; align-items: center;">
        <i data-lucide="bell" size="22"></i>
        <span style="position: absolute; top: -2px; right: -2px; background: var(--error); width: 8px; height: 8px; border-radius: 50%; border: 2px solid var(--bg-paper);"></span>
      </div>
      <div style="display: flex; align-items: center; gap: 0.75rem;">
        <div style="text-align: right; display: none; @media(min-width: 640px){ display: block; }">
           <div style="font-size: 0.875rem; font-weight: 600;">${state.user?.nombre || 'Usuario'}</div>
           <div style="font-size: 0.75rem; color: var(--text-muted);">Plan Personal</div>
        </div>
        <img src="https://ui-avatars.com/api/?name=${encodeURIComponent(state.user?.nombre || 'U')}&background=3b82f6&color=fff" style="width: 40px; height: 40px; border-radius: 12px; border: 2px solid var(--border);" />
      </div>
    </div>
  </header>
`;

const Loader = () => state.isLoading ? `
  <div style="position: fixed; top: 0; right: 0; padding: 1rem; z-index: 2000;">
    <div class="spinner" style="width: 24px; height: 24px;"></div>
  </div>
` : '';


const DashboardView = () => `
  <div class="view-container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
      <div>
        <h2 style="font-family: var(--font-heading); font-size: 1.75rem; font-weight: 700;">Resumen Financiero</h2>
        <p style="color: var(--text-muted);">Bienvenido, esto es lo que está pasando hoy.</p>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-header">
          <span>Balance Total</span>
          <i data-lucide="trending-up" style="color: var(--success);"></i>
        </div>
        <div class="stat-value">${formatCurrency(state.data.stats.balance || 0)}</div>
        <div class="stat-label">Estado actual</div>
      </div>
      <div class="stat-card">
        <div class="stat-header">
          <span>Presupuesto</span>
          <i data-lucide="pie-chart" style="color: var(--primary);"></i>
        </div>
        <div class="stat-value">${formatCurrency(state.data.stats.presupuesto || 0)}</div>
        <div class="stat-label">Límite mensual</div>
      </div>
      <div class="stat-card">
        <div class="stat-header">
          <span>Gastos Mes</span>
          <i data-lucide="trending-down" style="color: var(--error);"></i>
        </div>
        <div class="stat-value">${formatCurrency(state.data.stats.gastosMes || 0)}</div>
        <div class="stat-label text-error">Total acumulado</div>
      </div>
    </div>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 1.5rem;">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Gastos por Categoría</h3>
        </div>
        <div class="card-body">
          <div style="height: 250px;"><canvas id="expenses-chart"></canvas></div>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Últimos Movimientos</h3>
          <button class="btn btn-outline" style="width: auto; font-size: 0.75rem; padding: 0.25rem 0.75rem;" data-route="/expenses">Ver todo</button>
        </div>
        <div class="card-body" style="padding: 0;">
          <table style="width:100%;">
            <thead>
              <tr><th>Concepto</th><th>Fecha</th><th>Monto</th></tr>
            </thead>
            <tbody>
              ${state.data.gastos.slice(0, 5).map(g => `
                <tr>
                  <td>${g.Descripcion || g.CategoriaNombre}</td>
                  <td style="color: var(--text-muted);">${new Date(g.FechaGasto).toLocaleDateString()}</td>
                  <td style="font-weight: 600;">${formatCurrency(g.Monto)}</td>
                </tr>
              `).join('')}
              ${state.data.gastos.length === 0 ? '<tr><td colspan="3" style="text-align:center; padding: 2rem; color: var(--text-muted);">No hay gastos registrados</td></tr>' : ''}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
`;


const BudgetView = () => {
  const { presupuesto, gastosMes, balance } = state.data.stats;

  return `
  <div class="view-container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem;">
      <div>
        <h2 style="font-family: var(--font-heading); font-size: 1.75rem; font-weight: 700;">Presupuesto Mensual</h2>
        <p style="color: var(--text-muted);">Gestiona tus límites de gasto por categoría.</p>
      </div>
      
      <div style="display: flex; gap: 0.75rem; align-items: center; flex-wrap: wrap;">
        <button class="btn btn-primary" style="width: auto; padding: 0.5rem 1rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;" onclick="openNewSectionModal()">
          <i data-lucide="folder-plus" style="width: 16px;"></i> Nueva Sección
        </button>
        <div style="display: flex; gap: 0.75rem; background: var(--bg-card); padding: 0.5rem; border-radius: 12px; border: 1px solid var(--border);">
          <select class="btn" id="select-month" style="width: auto; background: none; border: none; padding: 0.25rem 0.5rem;" onchange="changePeriod()">
            ${[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map(m => `
              <option value="${m}" ${state.selectedMonth === m ? 'selected' : ''}>${getMonthName(m)}</option>
            `).join('')}
          </select>
          <select class="btn" id="select-year" style="width: auto; background: none; border: none; padding: 0.25rem 0.5rem;" onchange="changePeriod()">
            ${[2024, 2025, 2026].map(y => `
              <option value="${y}" ${state.selectedYear === y ? 'selected' : ''}>${y}</option>
            `).join('')}
          </select>
        </div>
      </div>
    </div>

    <!-- Global Stats Widget -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
      <div class="card" style="padding: 1.25rem; border-left: 4px solid var(--primary); position: relative; overflow: hidden;">
        <div style="position: absolute; top: 1rem; right: 1rem; color: var(--primary); opacity: 0.15;">
          <i data-lucide="banknote" style="width: 48px; height: 48px;"></i>
        </div>
        <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); margin-bottom: 0.5rem; letter-spacing: 0.05em; position: relative; z-index: 1;">Presupuesto Total</div>
        <div style="font-size: 1.5rem; font-weight: 700; position: relative; z-index: 1;">${formatCurrency(presupuesto)}</div>
      </div>
      <div class="card" style="padding: 1.25rem; border-left: 4px solid var(--secondary); position: relative; overflow: hidden;">
        <div style="position: absolute; top: 1rem; right: 1rem; color: var(--secondary); opacity: 0.15;">
          <i data-lucide="credit-card" style="width: 48px; height: 48px;"></i>
        </div>
        <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); margin-bottom: 0.5rem; letter-spacing: 0.05em; position: relative; z-index: 1;">Gastado Real</div>
        <div style="font-size: 1.5rem; font-weight: 700; position: relative; z-index: 1;">${formatCurrency(gastosMes)}</div>
      </div>
      <div class="card" style="padding: 1.25rem; border-left: 4px solid ${balance >= 0 ? 'var(--success)' : 'var(--error)'}; position: relative; overflow: hidden;">
        <div style="position: absolute; top: 1rem; right: 1rem; color: ${balance >= 0 ? 'var(--success)' : 'var(--error)'}; opacity: 0.15;">
          <i data-lucide="scale" style="width: 48px; height: 48px;"></i>
        </div>
        <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); margin-bottom: 0.5rem; letter-spacing: 0.05em; position: relative; z-index: 1;">Diferencia</div>
        <div style="font-size: 1.5rem; font-weight: 700; color: ${balance >= 0 ? 'var(--success)' : 'var(--error)'}; position: relative; z-index: 1;">
          ${balance >= 0 ? '+' : ''}${formatCurrency(balance)}
        </div>
      </div>
    </div>
    
    <div style="display: flex; flex-direction: column; gap: 1rem;">
      ${state.data.presupuestos.map((sec, idx) => {
    const secPresupuesto = sec.Items.reduce((sum, item) => sum + parseFloat(item.MontoPresupuestado || 0), 0);
    const secReal = sec.Items.reduce((sum, item) => sum + parseFloat(item.MontoReal || 0), 0);
    const pct = secPresupuesto > 0 ? (secReal / secPresupuesto) * 100 : 0;
    const isExpanded = state.expandedSection === idx;

    return `
          <div class="card" style="overflow: hidden;">
            <div class="card-header" style="cursor: pointer; padding: 1.25rem;" onclick="toggleSection(${idx})">
              <div style="flex: 1;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem;">
                   <div style="display: flex; align-items: center; gap: 0.75rem;">
                      <i data-lucide="${isExpanded ? 'chevron-down' : 'chevron-right'}" style="color: var(--text-muted); width: 18px;"></i>
                      <h3 class="card-title" style="margin: 0;">${sec.Seccion}</h3>
                   </div>
                   <div style="display: flex; align-items: center; gap: 0.75rem;">
                      <div style="text-align: right;">
                        <div style="font-size: 0.875rem; font-weight: 600;">${formatCurrency(secReal)} / <span style="color: var(--primary);">${formatCurrency(secPresupuesto)}</span></div>
                        <div style="font-size: 0.7rem; color: var(--text-muted);">${pct.toFixed(1)}% utilizado</div>
                      </div>
                      <button class="btn btn-outline" title="Añadir subcategoría" style="width: auto; padding: 0.3rem 0.5rem; border-color: var(--primary); color: var(--primary);" onclick="event.stopPropagation(); openNewSubcategoryModal('${sec.SeccionId}', '${sec.Seccion.replace(/'/g, "\'")}')">
                        <i data-lucide="plus" style="width: 14px;"></i>
                      </button>
                      ${!sec.EsSistema ? `<button class="btn btn-outline" title="Eliminar sección" style="width: auto; padding: 0.3rem 0.5rem; border-color: var(--error); color: var(--error);" onclick="event.stopPropagation(); openDeleteCategoryModal('${sec.SeccionId}', '${sec.Seccion.replace(/'/g, "\'")}', true)">
                        <i data-lucide="trash-2" style="width: 14px;"></i>
                      </button>` : ''}
                   </div>
                </div>
                <div style="height: 6px; background: var(--bg-card); border-radius: 100px; overflow: hidden;">
                  <div style="width: ${Math.min(pct, 100)}%; height: 100%; background: ${pct > 100 ? 'var(--error)' : 'linear-gradient(to right, var(--primary), var(--secondary))'}; border-radius: 100px;"></div>
                </div>
              </div>
            </div>
            
            ${isExpanded ? `
              <div style="background: rgba(0,0,0,0.2); border-top: 1px solid var(--border); padding: 1rem;">
                <table style="width: 100%; border-collapse: separate; border-spacing: 0 0.5rem;">
                  <thead style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">
                    <tr>
                      <th style="text-align: left; padding: 0.5rem;">Categoría</th>
                      <th style="text-align: right; padding: 0.5rem;">Presupuesto</th>
                      <th style="text-align: right; padding: 0.5rem;">Real</th>
                      <th style="text-align: center; padding: 0.5rem;">Acción</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${sec.Items.map(item => `
                      <tr style="background: var(--bg-paper); border-radius: 8px;">
                        <td style="padding: 0.75rem; font-size: 0.875rem; border-top-left-radius: 8px; border-bottom-left-radius: 8px;">${item.Categoria}</td>
                        <td style="padding: 0.75rem; text-align: right; font-weight: 600; color: var(--primary);">
                          ${formatCurrency(item.MontoPresupuestado)}
                        </td>
                        <td style="padding: 0.75rem; text-align: right; font-size: 0.875rem;">${formatCurrency(item.MontoReal)}</td>
                        <td style="padding: 0.75rem; text-align: center; border-top-right-radius: 8px; border-bottom-right-radius: 8px;">
                          <div style="display: flex; gap: 0.4rem; justify-content: center;">
                            <button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem; font-size: 0.75rem;" 
                                    onclick="editBudget('${item.CategoriaGastoId}', '${item.Categoria}', ${item.MontoPresupuestado})">
                              <i data-lucide="edit-2" style="width: 14px;"></i>
                            </button>
                            ${!item.EsSistema ? `<button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem; font-size: 0.75rem; border-color: var(--error); color: var(--error);" 
                                    onclick="openDeleteCategoryModal('${item.CategoriaGastoId}', '${item.Categoria.replace(/'/g, "\'")}', false)">
                              <i data-lucide="trash-2" style="width: 14px;"></i>
                            </button>` : ''}
                          </div>
                        </td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            ` : ''}
          </div>
        `;
  }).join('')}
    </div>
  </div>
`;
};

// Helper Globales para UI de Presupuesto
window.toggleSection = (idx) => {
  state.expandedSection = state.expandedSection === idx ? null : idx;
  render();
};

window.editBudget = (catId, name, current) => {
  state.activeModal = {
    type: 'edit-budget',
    data: { id: catId, name, current }
  };
  render();
};

window.changePeriod = (type = 'budget') => {
  if (type === 'expenses') {
    state.selectedMonthExpenses = parseInt(document.getElementById('select-month-exp').value);
    state.selectedYearExpenses = parseInt(document.getElementById('select-year-exp').value);
    fetchExpensesData();
  } else {
    state.selectedMonth = parseInt(document.getElementById('select-month').value);
    state.selectedYear = parseInt(document.getElementById('select-year').value);
    fetchBudgetData();
  }
};

const saveBudget = async (catId, amount) => {
  try {
    await api.fetch('/presupuestos/capturar', {
      method: 'POST',
      body: JSON.stringify({
        categoria_id: catId,
        monto: amount,
        anio: state.selectedYear,
        mes: state.selectedMonth
      })
    });
    showToast('Presupuesto actualizado', 'success');
    fetchData();
  } catch (err) {
    console.error(err);
  }
};

// ── Gestión de Categorías / Secciones ──────────────────────────────

window.openNewSectionModal = () => {
  state.activeModal = { type: 'new-section', data: {} };
  render();
};

window.openNewSubcategoryModal = (seccionId, seccionNombre) => {
  state.activeModal = { type: 'new-subcategory', data: { seccionId, seccionNombre } };
  render();
};

window.openDeleteCategoryModal = (id, nombre, isSection) => {
  state.activeModal = { type: 'delete-category', data: { id, nombre, isSection } };
  render();
};

window.confirmNewSection = async () => {
  const nombre = document.getElementById('modal-section-name')?.value?.trim();
  if (!nombre) { showToast('El nombre es requerido', 'error'); return; }
  try {
    await api.fetch('/categorias', {
      method: 'POST',
      body: JSON.stringify({ nombre, icono: 'folder' })
    });
    showToast(`Sección "${nombre}" creada`, 'success');
    closeModal();
    await fetchCategorias();
    fetchBudgetData();
  } catch (err) {
    console.error(err);
  }
};

window.confirmNewSubcategory = async () => {
  const nombre = document.getElementById('modal-subcat-name')?.value?.trim();
  if (!nombre) { showToast('El nombre es requerido', 'error'); return; }
  const { seccionId } = state.activeModal.data;
  try {
    await api.fetch('/categorias', {
      method: 'POST',
      body: JSON.stringify({ nombre, icono: 'tag', categoria_padre_id: seccionId })
    });
    showToast(`Subcategoría "${nombre}" creada`, 'success');
    closeModal();
    await fetchCategorias();
    fetchBudgetData();
  } catch (err) {
    console.error(err);
  }
};

window.confirmDeleteCategory = async () => {
  const { id, nombre } = state.activeModal.data;
  try {
    await api.fetch('/categorias/eliminar', {
      method: 'POST',
      body: JSON.stringify({ id })
    });
    showToast(`"${nombre}" eliminado`, 'success');
    closeModal();
    await fetchCategorias();
    fetchBudgetData();
  } catch (err) {
    console.error(err);
  }
};

window.deleteExpense = (id) => {
  state.activeModal = { type: 'delete-confirm', data: { id } };
  render();
};

window.confirmDeleteExpense = async () => {
  const { id } = state.activeModal.data;
  try {
    await api.fetch(`/gastos/eliminar`, {
      method: 'POST',
      body: JSON.stringify({ gasto_id: id })
    });
    showToast('Gasto eliminado', 'success');
    closeModal();
    fetchData();
  } catch (err) {
    console.error(err);
  }
};

window.openNewExpenseModal = () => {
  state.activeModal = { type: 'new-expense', data: {} };
  render();
};

window.editExpense = (gasto) => {
  state.activeModal = { type: 'edit-expense', data: gasto };
  render();
};

window.updateExpenseFilter = (key, value) => {
  state.filters[key] = value;
  refreshExpensesList();
};

window.clearExpenseFilters = () => {
  state.filters = { search: '', category: '', date: '', minAmount: '', maxAmount: '' };
  
  // Actualizar selectores a mes actual si se desea, o solo filtros de búsqueda
  // El usuario pidió selector de mes, así que Limpiar solo limpia filtros de búsqueda/fecha/monto
  const searchInput = document.getElementById('filter-search');
  const catSelect = document.getElementById('filter-category');
  const dateInput = document.getElementById('filter-date');
  const minInput = document.getElementById('filter-min');
  const maxInput = document.getElementById('filter-max');

  if (searchInput) searchInput.value = '';
  if (catSelect) catSelect.value = '';
  if (dateInput) dateInput.value = '';
  if (minInput) minInput.value = '';
  if (maxInput) maxInput.value = '';

  refreshExpensesList();
};

const refreshExpensesList = () => {
  const tbody = document.getElementById('expenses-tbody');
  const countLabel = document.getElementById('expenses-results-count');
  if (!tbody) return;

  const filteredGastos = state.data.gastos.filter(g => {
    const matchesSearch = !state.filters.search || g.Descripcion?.toLowerCase().includes(state.filters.search.toLowerCase());
    const matchesCategory = !state.filters.category || g.CategoriaGastoId == state.filters.category;
    const matchesDate = !state.filters.date || g.FechaGasto.startsWith(state.filters.date);
    const amount = parseFloat(g.Monto || 0);
    const matchesMin = !state.filters.minAmount || amount >= parseFloat(state.filters.minAmount);
    const matchesMax = !state.filters.maxAmount || amount <= parseFloat(state.filters.maxAmount);
    return matchesSearch && matchesCategory && matchesDate && matchesMin && matchesMax;
  });

  if (countLabel) {
    countLabel.innerHTML = `Resultados para: <b>${getMonthName(state.selectedMonthExpenses)} ${state.selectedYearExpenses}</b> (${filteredGastos.length} registros)`;
  }

  tbody.innerHTML = filteredGastos.map(row => `
    <tr>
      <td style="color: var(--text-muted); font-size: 0.8rem;">${new Date(row.FechaGasto).toLocaleDateString()}</td>
      <td style="font-weight: 600;">${row.Descripcion || 'Sin descripción'}</td>
      <td><span style="background: var(--bg-card); padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.75rem; color: var(--primary); border: 1px solid var(--border);">${row.CategoriaNombre}</span></td>
      <td style="font-weight: 700; text-align: right; color: var(--text-main);">${formatCurrency(row.Monto)}</td>
      <td style="text-align: center;">
        <div style="display: flex; gap: 0.5rem; justify-content: center;">
          <button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem;" onclick='editExpense(${JSON.stringify(row)})'>
            <i data-lucide="edit-2" style="width: 14px;"></i>
          </button>
          <button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem; color: var(--error);" onclick="deleteExpense(${row.GastoId})">
            <i data-lucide="trash-2" style="width: 14px;"></i>
          </button>
        </div>
      </td>
    </tr>
  `).join('');

  if (filteredGastos.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding: 3rem; color: var(--text-muted); font-style: italic;">No se encontraron gastos con estos criterios.</td></tr>';
  }

  createIcons({ icons });
};

const ExpensesView = () => {
  const allCategories = [];
  state.data.presupuestos.forEach(sec => {
    sec.Items.forEach(item => {
      if (!allCategories.find(c => c.CategoriaGastoId === item.CategoriaGastoId)) {
        allCategories.push(item);
      }
    });
  });

  const filteredGastos = state.data.gastos.filter(g => {
    const matchesSearch = !state.filters.search || g.Descripcion?.toLowerCase().includes(state.filters.search.toLowerCase());
    const matchesCategory = !state.filters.category || g.CategoriaGastoId == state.filters.category;
    const matchesDate = !state.filters.date || g.FechaGasto.startsWith(state.filters.date);
    const amount = parseFloat(g.Monto || 0);
    const matchesMin = !state.filters.minAmount || amount >= parseFloat(state.filters.minAmount);
    const matchesMax = !state.filters.maxAmount || amount <= parseFloat(state.filters.maxAmount);
    return matchesSearch && matchesCategory && matchesDate && matchesMin && matchesMax;
  });

  return `
  <div class="view-container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem;">
      <div>
        <h2 style="font-family: var(--font-heading); font-size: 1.75rem; font-weight: 700;">Histórico de Gastos</h2>
        <p style="color: var(--text-muted);">Consulta y gestiona todos tus movimientos del mes.</p>
      </div>

      <div style="display: flex; gap: 1rem; align-items: center;">
        <div style="display: flex; gap: 0.5rem; background: var(--bg-card); padding: 0.4rem; border-radius: 12px; border: 1px solid var(--border);">
          <select id="select-month-exp" class="btn" style="width: auto; background: none; border: none; padding: 0.25rem 0.5rem;" onchange="changePeriod('expenses')">
            ${[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map(m => `
              <option value="${m}" ${state.selectedMonthExpenses === m ? 'selected' : ''}>${getMonthName(m)}</option>
            `).join('')}
          </select>
          <select id="select-year-exp" class="btn" style="width: auto; background: none; border: none; padding: 0.25rem 0.5rem;" onchange="changePeriod('expenses')">
            ${[2024, 2025, 2026].map(y => `
              <option value="${y}" ${state.selectedYearExpenses === y ? 'selected' : ''}>${y}</option>
            `).join('')}
          </select>
        </div>
        <button class="btn btn-primary" style="width: auto;" onclick="openNewExpenseModal()">
          <i data-lucide="plus"></i> Nuevo Gasto
        </button>
      </div>
    </div>
    
    <div class="card" style="margin-bottom: 2rem;">
      <div class="card-body" style="padding: 1.25rem;">
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; align-items: end;">
          <div>
            <label class="form-label">Buscar descripción</label>
            <div style="position: relative;">
               <i data-lucide="search" style="position: absolute; left: 12px; top: 50%; transform: translateY(-50%); width: 16px; color: var(--text-muted); pointer-events: none;"></i>
               <input type="text" id="filter-search" class="form-input" style="padding-left: 2.5rem;" placeholder="Ej. Soriana..." value="${state.filters.search}" oninput="updateExpenseFilter('search', this.value)">
            </div>
          </div>
          <div>
            <label class="form-label">Categoría</label>
            <select id="filter-category" class="form-input" onchange="updateExpenseFilter('category', this.value)" style="appearance: auto;">
              <option value="">Todas</option>
              ${state.data.presupuestos.map(sec => `
                <optgroup label="${sec.Seccion}">
                  ${sec.Items.map(cat => `
                    <option value="${cat.CategoriaGastoId}" ${state.filters.category == cat.CategoriaGastoId ? 'selected' : ''}>${cat.Categoria}</option>
                  `).join('')}
                </optgroup>
              `).join('')}
            </select>
          </div>
          <div>
            <label class="form-label">Fecha</label>
            <input type="date" id="filter-date" class="form-input" value="${state.filters.date}" onchange="updateExpenseFilter('date', this.value)">
          </div>
          <div>
            <label class="form-label">Monto (Min/Max)</label>
            <div style="display: flex; gap: 0.5rem; align-items: center;">
              <input type="number" id="filter-min" class="form-input" placeholder="Min" value="${state.filters.minAmount}" oninput="updateExpenseFilter('minAmount', this.value)" style="padding: 0.5rem;">
              <input type="number" id="filter-max" class="form-input" placeholder="Max" value="${state.filters.maxAmount}" oninput="updateExpenseFilter('maxAmount', this.value)" style="padding: 0.5rem;">
            </div>
          </div>
          <div style="display: flex; gap: 0.5rem;">
             <button class="btn btn-outline" style="flex: 1;" onclick="clearExpenseFilters()">
               Limpiar
             </button>
             <button class="btn btn-outline" style="width: auto; padding: 0.75rem;" onclick="fetchExpensesData()">
               <i data-lucide="refresh-cw" style="width:18px;"></i>
             </button>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header" style="background: var(--surface);">
         <div style="display:flex; justify-content: space-between; width: 100%; align-items: center;">
            <div id="expenses-results-count" style="font-size: 0.875rem; color: var(--text-muted);">Resultados para: <b>${getMonthName(state.selectedMonthExpenses)} ${state.selectedYearExpenses}</b> (${filteredGastos.length} registros)</div>
         </div>
      </div>
      <div class="card-body" style="padding: 0;">
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Descripción</th>
                <th>Categoría</th>
                <th style="text-align: right;">Monto</th>
                <th style="text-align: center;">Acciones</th>
              </tr>
            </thead>
            <tbody id="expenses-tbody">
              ${filteredGastos.map(row => `
                <tr>
                  <td style="color: var(--text-muted); font-size: 0.8rem;">${new Date(row.FechaGasto).toLocaleDateString()}</td>
                  <td style="font-weight: 600;">${row.Descripcion || 'Sin descripción'}</td>
                  <td><span style="background: var(--bg-card); padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.75rem; color: var(--primary); border: 1px solid var(--border);">${row.CategoriaNombre}</span></td>
                  <td style="font-weight: 700; text-align: right; color: var(--text-main);">${formatCurrency(row.Monto)}</td>
                  <td style="text-align: center;">
                    <div style="display: flex; gap: 0.5rem; justify-content: center;">
                      <button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem;" onclick='editExpense(${JSON.stringify(row)})'>
                        <i data-lucide="edit-2" style="width: 14px;"></i>
                      </button>
                      <button class="btn btn-outline" style="width: auto; padding: 0.25rem 0.5rem; color: var(--error);" onclick="deleteExpense(${row.GastoId})">
                        <i data-lucide="trash-2" style="width: 14px;"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              `).join('')}
              ${filteredGastos.length === 0 ? '<tr><td colspan="5" style="text-align:center; padding: 3rem; color: var(--text-muted); font-style: italic;">No se encontraron gastos con estos criterios.</td></tr>' : ''}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
  `;
};


window.updateProfileName = async () => {
  const nombre = document.getElementById('profile-name-input').value;
  try {
    const result = await api.fetch('/usuario/perfil', {
      method: 'POST',
      body: JSON.stringify({ nombre })
    });
    if (result.status === 'success') {
      state.user.nombre = nombre;
      localStorage.setItem('aura_user', JSON.stringify(state.user));
      showToast('Nombre actualizado correctamente', 'success');
      render();
    }
  } catch (err) {
    console.error(err);
  }
};

window.updateProfilePassword = async () => {
  const currentPassword = document.getElementById('profile-curr-pass').value;
  const newPassword = document.getElementById('profile-new-pass').value;
  const confirmPassword = document.getElementById('profile-confirm-pass').value;

  if (newPassword !== confirmPassword) {
    showToast('Las contraseñas no coinciden', 'error');
    return;
  }

  if (newPassword.length < 6) {
    showToast('La nueva contraseña debe tener al menos 6 caracteres', 'error');
    return;
  }

  try {
    const result = await api.fetch('/usuario/password', {
      method: 'POST',
      body: JSON.stringify({ currentPassword, newPassword })
    });
    if (result.status === 'success') {
      showToast('Contraseña actualizada con éxito', 'success');
      document.getElementById('profile-password-form').reset();
    }
  } catch (err) {
    console.error(err);
  }
};

const ProfileView = () => `
  <div class="view-container">
    <div style="margin-bottom: 2rem;">
      <h2 style="font-family: var(--font-heading); font-size: 1.75rem; font-weight: 700;">Mi Perfil</h2>
      <p style="color: var(--text-muted);">Gestiona tus datos personales y configuración de cuenta.</p>
    </div>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 2rem;">
      <!-- Información General -->
      <div class="card">
        <div class="card-header"><h3 class="card-title">Información General</h3></div>
        <div class="card-body">
          <div style="text-align: center; margin-bottom: 2rem;">
            <img src="https://ui-avatars.com/api/?name=${encodeURIComponent(state.user?.nombre || 'U')}&background=3b82f6&color=fff&size=128" style="width: 100px; height: 100px; border-radius: 25px; margin-bottom: 1rem; border: 3px solid var(--border);" />
            <p style="color: var(--text-muted); font-size: 0.875rem;">${state.user?.email}</p>
          </div>
          <form id="profile-general-form" onsubmit="event.preventDefault(); window.updateProfileName()">
            <div class="form-group" style="margin-bottom: 1.5rem;">
              <label class="form-label">Nombre para mostrar</label>
              <input type="text" id="profile-name-input" class="form-input" value="${state.user?.nombre}" required>
            </div>
            <div style="display: flex; justify-content: flex-end;">
              <button type="submit" class="btn btn-primary" style="width: auto;">Actualizar Nombre</button>
            </div>
          </form>
        </div>
      </div>

      <!-- Seguridad -->
      <div class="card">
         <div class="card-header"><h3 class="card-title">Seguridad y Acceso</h3></div>
         <div class="card-body">
            <form id="profile-password-form" onsubmit="event.preventDefault(); window.updateProfilePassword()">
              <div class="form-group" style="margin-bottom: 1.25rem;">
                <label class="form-label">Contraseña Actual</label>
                <input type="password" id="profile-curr-pass" class="form-input" placeholder="••••••••" required>
              </div>
              <div class="form-group" style="margin-bottom: 1.25rem;">
                <label class="form-label">Nueva Contraseña</label>
                <input type="password" id="profile-new-pass" class="form-input" placeholder="Min. 6 caracteres" required>
              </div>
              <div class="form-group" style="margin-bottom: 1.5rem;">
                <label class="form-label">Confirmar Nueva Contraseña</label>
                <input type="password" id="profile-confirm-pass" class="form-input" placeholder="••••••••" required>
              </div>
              <div style="display: flex; justify-content: flex-end;">
                 <button type="submit" class="btn btn-outline" style="width: auto; border-color: var(--primary); color: var(--primary);">Cambiar Contraseña</button>
              </div>
            </form>
         </div>
      </div>
    </div>
  </div>
`;

// ── Consolidado Anual ─────────────────────────────────────────────

const fmtMoney = (n) => {
  const v = parseFloat(n) || 0;
  if (v === 0) return '<span style="color:var(--text-muted);">—</span>';
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(v);
};

const fmtDif = (n) => {
  const v = parseFloat(n) || 0;
  if (v === 0) return '<span style="color:var(--text-muted);">—</span>';
  const color = v >= 0 ? 'var(--success)' : 'var(--error)';
  const sign = v > 0 ? '+' : '';
  return `<span style="color:${color}; font-weight:600;">${sign}${new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(v)}</span>`;
};

const AnnualView = () => {
  const report  = state.data.annualData;
  const months  = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  const MESES   = [1,2,3,4,5,6,7,8,9,10,11,12];

  // ── Celdas de cabecera por mes (colspan 3) ──
  const mesHeaders = MESES.map(m => `
    <th colspan="3" style="text-align:center; background:var(--bg-card); padding:0.5rem 0.25rem; font-size:0.7rem; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; color:var(--primary); border-bottom:2px solid var(--primary); white-space:nowrap;">
      ${months[m-1]}
    </th>`).join('');

  const subHeaders = MESES.map(() => `
    <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:var(--bg-card); white-space:nowrap;">Pres.</th>
    <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:var(--bg-card); white-space:nowrap;">Real</th>
    <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:var(--bg-card); white-space:nowrap;">Dif.</th>`).join('');

  let bodyRows   = '';
  const grandTotal = { P: {}, R: {} };
  MESES.forEach(m => { grandTotal.P[m] = 0; grandTotal.R[m] = 0; });

  if (report) {
    report.data.forEach(sec => {
      // ── Fila de sección ──
      const secCells = MESES.map(m => {
        const p = sec.Totales[m]?.P ?? 0;
        const r = sec.Totales[m]?.R ?? 0;
        const d = p - r;
        grandTotal.P[m] += p;
        grandTotal.R[m] += r;
        return `<td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem; font-weight:700;">${fmtMoney(p)}</td>
                <td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem; font-weight:700;">${fmtMoney(r)}</td>
                <td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem;">${fmtDif(d)}</td>`;
      }).join('');

      const secTotalP = MESES.reduce((s,m) => s + (sec.Totales[m]?.P ?? 0), 0);
      const secTotalR = MESES.reduce((s,m) => s + (sec.Totales[m]?.R ?? 0), 0);

      bodyRows += `
        <tr style="background:var(--bg-card);">
          <td style="padding:0.6rem 0.75rem; font-size:0.8rem; font-weight:700; text-transform:uppercase; color:var(--text-main); white-space:nowrap; position:sticky; left:0; background:var(--bg-card); z-index:2; border-right:2px solid var(--border); min-width:180px; max-width:220px;">
            ${sec.Nombre}
          </td>
          ${secCells}
          <td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem; font-weight:700; background:var(--bg-card);">${fmtMoney(secTotalP)}</td>
          <td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem; font-weight:700; background:var(--bg-card);">${fmtMoney(secTotalR)}</td>
          <td style="text-align:right; padding:0.5rem 0.4rem; font-size:0.72rem; background:var(--bg-card);">${fmtDif(secTotalP - secTotalR)}</td>
        </tr>`;

      // ── Filas de subcategorías ──
      sec.Categorias.forEach(cat => {
        const catCells = MESES.map(m => {
          const p = cat.Meses[m]?.P ?? 0;
          const r = cat.Meses[m]?.R ?? 0;
          const d = cat.Meses[m]?.D ?? (p - r);
          return `<td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtMoney(p)}</td>
                  <td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtMoney(r)}</td>
                  <td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtDif(d)}</td>`;
        }).join('');

        const catTotalP = MESES.reduce((s,m) => s + (cat.Meses[m]?.P ?? 0), 0);
        const catTotalR = MESES.reduce((s,m) => s + (cat.Meses[m]?.R ?? 0), 0);

        bodyRows += `
          <tr style="border-bottom:1px solid var(--border);">
            <td style="padding:0.4rem 0.75rem 0.4rem 1.5rem; font-size:0.75rem; color:var(--text-main); white-space:nowrap; position:sticky; left:0; background:var(--bg-paper); z-index:2; border-right:2px solid var(--border); min-width:180px; max-width:220px; overflow:hidden; text-overflow:ellipsis;">
              ${cat.Nombre}
            </td>
            ${catCells}
            <td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtMoney(catTotalP)}</td>
            <td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtMoney(catTotalR)}</td>
            <td style="text-align:right; padding:0.4rem 0.4rem; font-size:0.71rem;">${fmtDif(catTotalP - catTotalR)}</td>
          </tr>`;
      });
    });
  }

  // ── Fila TOTAL global ──
  const grandTotalCells = MESES.map(m => {
    const p = grandTotal.P[m] || 0;
    const r = grandTotal.R[m] || 0;
    return `<td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem; font-weight:700;">${fmtMoney(p)}</td>
            <td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem; font-weight:700;">${fmtMoney(r)}</td>
            <td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem;">${fmtDif(p - r)}</td>`;
  }).join('');
  const gtP = MESES.reduce((s,m) => s + (grandTotal.P[m] || 0), 0);
  const gtR = MESES.reduce((s,m) => s + (grandTotal.R[m] || 0), 0);

  return `
  <div class="view-container">
    <!-- Cabecera -->
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.5rem; flex-wrap:wrap; gap:1rem;">
      <div>
        <h2 style="font-family:var(--font-heading); font-size:1.75rem; font-weight:700;">Consolidado Anual</h2>
        <p style="color:var(--text-muted);">Presupuesto vs. gasto real de todas las categorías por mes.</p>
      </div>
      <div style="display:flex; align-items:center; gap:0.75rem;">
        <select id="select-annual-year" class="btn" style="width:auto; padding:0.5rem 1rem; font-size:0.9rem;" onchange="changeAnnualYear()">
          ${[2023,2024,2025,2026,2027].map(y => `
            <option value="${y}" ${state.selectedAnnualYear === y ? 'selected' : ''}>${y}</option>
          `).join('')}
        </select>
        <button class="btn btn-primary" style="width:auto; padding:0.5rem 0.75rem;" onclick="fetchAnnualData()">
          <i data-lucide="refresh-cw" style="width:16px;"></i>
        </button>
        <button class="btn btn-outline" style="width:auto; padding:0.5rem 1rem; display:flex; align-items:center; gap:0.5rem; border-color:var(--success); color:var(--success);" ${!report ? 'disabled' : ''} onclick="exportAnnualToExcel()">
          <i data-lucide="download" style="width:16px;"></i> Excel
        </button>
      </div>
    </div>

    ${!report ? `
      <div class="card" style="padding:4rem; text-align:center; color:var(--text-muted);">
        <i data-lucide="bar-chart-3" style="width:48px; height:48px; opacity:0.3; margin-bottom:1rem;"></i>
        <p>Cargando consolidado anual…</p>
      </div>
    ` : `
    <!-- Leyenda -->
    <div style="display:flex; gap:1.5rem; margin-bottom:1rem; flex-wrap:wrap;">
      <span style="font-size:0.75rem; color:var(--text-muted); display:flex; align-items:center; gap:0.4rem;">
        <span style="display:inline-block; width:10px; height:10px; background:var(--primary); border-radius:2px;"></span> Presupuesto
      </span>
      <span style="font-size:0.75rem; color:var(--text-muted); display:flex; align-items:center; gap:0.4rem;">
        <span style="display:inline-block; width:10px; height:10px; background:var(--secondary); border-radius:2px;"></span> Real
      </span>
      <span style="font-size:0.75rem; color:var(--text-muted); display:flex; align-items:center; gap:0.4rem;">
        <span style="display:inline-block; width:10px; height:10px; background:var(--success); border-radius:2px;"></span> Diferencia (positivo = ahorro)
      </span>
    </div>

    <!-- Tabla principal -->
    <div class="card" style="padding:0; overflow:hidden;">
      <div style="overflow-x:auto; -webkit-overflow-scrolling:touch;">
        <table style="width:max-content; min-width:100%; border-collapse:collapse; font-size:0.8rem;">
          <thead>
            <tr>
              <th rowspan="2" style="text-align:left; padding:0.6rem 0.75rem; background:var(--bg-card); position:sticky; left:0; z-index:5; border-right:2px solid var(--border); border-bottom:1px solid var(--border); min-width:180px; font-size:0.75rem; text-transform:uppercase; color:var(--text-muted);">
                Categoría
              </th>
              ${mesHeaders}
              <th colspan="3" style="text-align:center; background:rgba(59,130,246,0.15); padding:0.5rem 0.25rem; font-size:0.7rem; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; color:var(--primary); border-bottom:2px solid var(--primary); white-space:nowrap;">
                TOTAL ANUAL
              </th>
            </tr>
            <tr>
              ${subHeaders}
              <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:rgba(59,130,246,0.1); white-space:nowrap;">Pres.</th>
              <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:rgba(59,130,246,0.1); white-space:nowrap;">Real</th>
              <th style="padding:0.35rem 0.4rem; font-size:0.62rem; color:var(--text-muted); text-transform:uppercase; text-align:right; background:rgba(59,130,246,0.1); white-space:nowrap;">Dif.</th>
            </tr>
          </thead>
          <tbody>
            ${bodyRows}
          </tbody>
          <tfoot>
            <tr style="background:var(--primary); color:white;">
              <td style="padding:0.65rem 0.75rem; font-size:0.82rem; font-weight:700; text-transform:uppercase; position:sticky; left:0; background:var(--primary); z-index:2; border-right:2px solid rgba(255,255,255,0.2); white-space:nowrap;">
                TOTAL GENERAL
              </td>
              ${grandTotalCells}
              <td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem; font-weight:700;">${fmtMoney(gtP)}</td>
              <td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem; font-weight:700;">${fmtMoney(gtR)}</td>
              <td style="text-align:right; padding:0.6rem 0.4rem; font-size:0.75rem; font-weight:700;">${fmtDif(gtP - gtR)}</td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
    `}
  </div>
`;
};

window.changeAnnualYear = () => {
  state.selectedAnnualYear = parseInt(document.getElementById('select-annual-year').value);
  state.data.annualData = null;
  fetchAnnualData();
};

window.exportAnnualToExcel = () => {
  const report = state.data.annualData;
  if (!report) return;

  const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  const MESES  = [1,2,3,4,5,6,7,8,9,10,11,12];

  // ── Cabeceras ──────────────────────────────────────────────────
  const headerRow1 = ['Categoría'];
  const headerRow2 = [''];
  MESES.forEach(m => {
    headerRow1.push(months[m-1], '', '');
    headerRow2.push('Presupuesto', 'Real', 'Diferencia');
  });
  headerRow1.push('Total Anual', '', '');
  headerRow2.push('Presupuesto', 'Real', 'Diferencia');

  const totalCols = 1 + 12 * 3 + 3; // categoría + 12 meses×3 + total anual×3
  const titleRow   = [`CONSOLIDADO DE PRESUPUESTO Y GASTOS MENSUAL - ${state.selectedAnnualYear}`];

  const rows = [titleRow, headerRow1, headerRow2];
  const grandTotal = { P:{}, R:{} };
  MESES.forEach(m => { grandTotal.P[m] = 0; grandTotal.R[m] = 0; });

  report.data.forEach(sec => {
    // Fila de sección (totales)
    const secRow = [sec.Nombre.toUpperCase()];
    MESES.forEach(m => {
      const p = sec.Totales[m]?.P ?? 0;
      const r = sec.Totales[m]?.R ?? 0;
      grandTotal.P[m] += p;
      grandTotal.R[m] += r;
      secRow.push(p, r, p - r);
    });
    const secTotP = MESES.reduce((s,m) => s + (sec.Totales[m]?.P ?? 0), 0);
    const secTotR = MESES.reduce((s,m) => s + (sec.Totales[m]?.R ?? 0), 0);
    secRow.push(secTotP, secTotR, secTotP - secTotR);
    rows.push(secRow);

    // Filas de subcategorías
    sec.Categorias.forEach(cat => {
      const catRow = ['  ' + cat.Nombre];
      MESES.forEach(m => {
        const p = cat.Meses[m]?.P ?? 0;
        const r = cat.Meses[m]?.R ?? 0;
        catRow.push(p, r, cat.Meses[m]?.D ?? (p - r));
      });
      const catTotP = MESES.reduce((s,m) => s + (cat.Meses[m]?.P ?? 0), 0);
      const catTotR = MESES.reduce((s,m) => s + (cat.Meses[m]?.R ?? 0), 0);
      catRow.push(catTotP, catTotR, catTotP - catTotR);
      rows.push(catRow);
    });
  });

  // Fila de totales globales
  const totRow = ['TOTAL GENERAL'];
  MESES.forEach(m => {
    const p = grandTotal.P[m] || 0;
    const r = grandTotal.R[m] || 0;
    totRow.push(p, r, p - r);
  });
  const gtP = MESES.reduce((s,m) => s + (grandTotal.P[m] || 0), 0);
  const gtR = MESES.reduce((s,m) => s + (grandTotal.R[m] || 0), 0);
  totRow.push(gtP, gtR, gtP - gtR);
  rows.push(totRow);

  // ── Crear libro XLSX ───────────────────────────────────────────
  const ws = XLSX.utils.aoa_to_sheet(rows);

  // Combinar celdas: fila título + cabeceras de mes (ahora en fila 1)
  const merges = [
    { s:{r:0,c:0}, e:{r:0,c:totalCols-1} }   // título span total
  ];
  let col = 1; // columna B en base 0
  for (let i = 0; i < 12; i++) {
    merges.push({ s:{r:1,c:col}, e:{r:1,c:col+2} }); // mes en fila 1
    col += 3;
  }
  merges.push({ s:{r:1,c:col}, e:{r:1,c:col+2} }); // Total Anual
  ws['!merges'] = merges;

  // Anchos de columna
  const wscols = [{ wch: 28 }]; // categoría
  for (let i = 0; i < 13 * 3; i++) wscols.push({ wch: 13 });
  ws['!cols'] = wscols;

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, `Consolidado ${state.selectedAnnualYear}`);
  XLSX.writeFile(wb, `AuraFin_Consolidado_${state.selectedAnnualYear}.xlsx`);
  showToast('Archivo Excel descargado', 'success');
};

const fetchAnnualData = async () => {
  if (!state.token) return;
  try {
    const params = `?anio=${state.selectedAnnualYear}&mes_inicio=1&mes_fin=12`;
    const result = await api.fetch(`/reportes/consolidado${params}`);
    state.data.annualData = result.data || null;
    render();
  } catch (err) { console.error('fetchAnnualData:', err); }
};

const Modal = () => {
  if (!state.activeModal) return '';

  const { type, data } = state.activeModal;
  const isEditingExpense = type === 'edit-expense';
  const isNewExpense = type === 'new-expense';
  const isDeleteConfirm = type === 'delete-confirm';

  let modalTitle = '';
  let modalBody = '';
  let modalFooter = '';

  if (isDeleteConfirm) {
    modalTitle = `
      <i data-lucide="alert-triangle" style="color: var(--error); width: 24px;"></i> 
      Eliminar Gasto
    `;
    modalBody = `
      <div style="text-align: center; padding: 1rem 0;">
        <p style="font-size: 1.125rem; font-weight: 500; margin-bottom: 0.5rem;">¿Estás seguro de eliminar este registro?</p>
        <p style="color: var(--text-muted); font-size: 0.875rem;">Esta acción no se puede deshacer de forma directa y afectará tus reportes del mes.</p>
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn" style="width:auto; background: var(--error); color: white;" onclick="confirmDeleteExpense()">
        <i data-lucide="trash-2" style="width:16px;"></i> ELIMINAR AHORA
      </button>
    `;
  } else if (type === 'edit-budget') {
    modalTitle = 'Ajustar Presupuesto';
    modalBody = `
      <p style="color:var(--text-muted); font-size:0.875rem; margin-bottom:1.25rem;">Establece el límite mensual para <b>${data.name}</b></p>
      <div style="margin-bottom:1.5rem;">
        <label style="display:block; font-size:0.75rem; color:var(--text-muted); margin-bottom:0.5rem;">Monto Mensual ($)</label>
        <input type="number" id="modal-input-amount" class="form-input" style="font-size:1.25rem; height:50px;" value="${data.current}" autofocus>
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn btn-primary" style="width:auto;" onclick="confirmModalAction()">
        <i data-lucide="save" style="width:16px;"></i> Guardar
      </button>
    `;
  } else if (type === 'new-section') {
    modalTitle = `<i data-lucide="folder-plus" style="width:22px; color: var(--primary);"></i> Nueva Sección`;
    modalBody = `
      <div style="display: flex; flex-direction: column; gap: 1.25rem;">
        <div>
          <label class="form-label">Nombre de la Sección</label>
          <input type="text" id="modal-section-name" class="form-input" placeholder="Ej. Hogar, Educación, Salud..." autofocus>
        </div>
        <p style="color: var(--text-muted); font-size: 0.8rem;">Las secciones agrupan tus subcategorías de gasto. Podrás añadir subcategorías después de crearla.</p>
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn btn-primary" style="width:auto;" onclick="confirmNewSection()">
        <i data-lucide="save" style="width:16px;"></i> Crear Sección
      </button>
    `;
  } else if (type === 'new-subcategory') {
    modalTitle = `<i data-lucide="tag" style="width:22px; color: var(--secondary);"></i> Nueva Subcategoría`;
    modalBody = `
      <div style="display: flex; flex-direction: column; gap: 1.25rem;">
        <div>
          <label class="form-label">Sección padre</label>
          <input type="text" class="form-input" value="${data.seccionNombre}" disabled style="opacity: 0.7;">
        </div>
        <div>
          <label class="form-label">Nombre de la Subcategoría</label>
          <input type="text" id="modal-subcat-name" class="form-input" placeholder="Ej. Supermercado, Netflix, Gimnasio..." autofocus>
        </div>
        <p style="color: var(--text-muted); font-size: 0.8rem;">Se inicializará automáticamente con presupuesto $0 para el mes actual.</p>
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn btn-primary" style="width:auto;" onclick="confirmNewSubcategory()">
        <i data-lucide="save" style="width:16px;"></i> Crear Subcategoría
      </button>
    `;
  } else if (type === 'delete-category') {
    const isSection = data.isSection;
    modalTitle = `<i data-lucide="alert-triangle" style="color: var(--error); width: 24px;"></i> Eliminar ${isSection ? 'Sección' : 'Subcategoría'}`;
    modalBody = `
      <div style="text-align: center; padding: 1rem 0;">
        <p style="font-size: 1.05rem; font-weight: 500; margin-bottom: 0.75rem;">¿Eliminar <b>"${data.nombre}"</b>?</p>
        ${isSection
          ? `<p style="color: var(--text-muted); font-size: 0.875rem;">Solo puedes eliminar la sección si no tiene subcategorías asociadas.</p>`
          : `<p style="color: var(--text-muted); font-size: 0.875rem;">Solo se puede eliminar si no tiene gastos registrados. Se eliminará también su presupuesto asignado.</p>`
        }
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn" style="width:auto; background: var(--error); color: white;" onclick="confirmDeleteCategory()">
        <i data-lucide="trash-2" style="width:16px;"></i> Eliminar
      </button>
    `;
  } else if (isNewExpense || isEditingExpense) {
    modalTitle = isEditingExpense ? 'Editar Gasto' : 'Nuevo Gasto';
    modalBody = `
      <div style="display: flex; flex-direction: column; gap: 1.25rem;">
        <div>
          <label class="form-label">Descripción</label>
          <input type="text" id="expense-desc" class="form-input" placeholder="Ej. Supermercado, Gasolina..." value="${data.Descripcion || ''}">
        </div>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
          <div>
            <label class="form-label">Monto ($)</label>
            <input type="number" id="expense-amount" class="form-input" placeholder="0.00" value="${data.Monto || ''}">
          </div>
          <div>
            <label class="form-label">Fecha</label>
            <input type="date" id="expense-date" class="form-input" value="${data.FechaGasto ? data.FechaGasto.substring(0, 10) : new Date().toISOString().substring(0, 10)}">
          </div>
        </div>
        <div>
          <label class="form-label">Categoría</label>
          <select id="expense-category" class="form-input" style="appearance: auto;">
            <option value="">Seleccionar categoría...</option>
            ${(() => {
              // Agrupar categorias planas por padre (independiente del mes seleccionado)
              const padres = state.data.categorias.filter(c => !c.CategoriaPadreId);
              const hijos  = state.data.categorias.filter(c =>  c.CategoriaPadreId);
              if (padres.length === 0) {
                // Fallback: usar presupuestos si categorias aún no se han cargado
                return state.data.presupuestos.map(sec =>
                  `<optgroup label="${sec.Seccion}">
                    ${sec.Items.map(cat =>
                      `<option value="${cat.CategoriaGastoId}" ${data.CategoriaGastoId == cat.CategoriaGastoId ? 'selected' : ''}>${cat.Categoria}</option>`
                    ).join('')}
                  </optgroup>`
                ).join('');
              }
              return padres.sort((a,b) => a.Nombre.localeCompare(b.Nombre)).map(padre => {
                const subcats = hijos.filter(h => h.CategoriaPadreId == padre.CategoriaGastoId)
                                     .sort((a,b) => a.Nombre.localeCompare(b.Nombre));
                if (subcats.length === 0) return '';
                return `<optgroup label="${padre.Nombre}">
                  ${subcats.map(cat =>
                    `<option value="${cat.CategoriaGastoId}" ${data.CategoriaGastoId == cat.CategoriaGastoId ? 'selected' : ''}>${cat.Nombre}</option>`
                  ).join('')}
                </optgroup>`;
              }).join('');
            })()}
          </select>
        </div>
      </div>
    `;
    modalFooter = `
      <button class="btn btn-outline" style="width:auto;" onclick="closeModal()">Cancelar</button>
      <button class="btn btn-primary" style="width:auto;" onclick="confirmModalAction()">
        <i data-lucide="save" style="width:16px;"></i> ${isEditingExpense ? 'Actualizar' : 'Guardar'}
      </button>
    `;
  }

  return `
    <div class="modal-overlay" onclick="closeModal()">
      <div class="modal-content" onclick="event.stopPropagation()">
        <div class="modal-header">
          <h3 style="margin:0; display: flex; align-items: center; gap: 0.5rem;">${modalTitle}</h3>
          <button class="btn btn-outline" style="width:auto; padding:0.25rem; border:none;" onclick="closeModal()">
            <i data-lucide="x" style="width:18px;"></i>
          </button>
        </div>
        <div class="modal-body">${modalBody}</div>
        <div class="modal-footer">${modalFooter}</div>
      </div>
    </div>
  `;
};

window.closeModal = () => {
  state.activeModal = null;
  render();
};

window.confirmModalAction = async () => {
  const { type, data } = state.activeModal;

  if (type === 'edit-budget') {
    const amount = document.getElementById('modal-input-amount').value;
    if (amount !== '' && !isNaN(amount)) {
      await saveBudget(data.id, parseFloat(amount));
      closeModal();
    }
  } else if (type === 'new-expense' || type === 'edit-expense') {
    const desc = document.getElementById('expense-desc').value;
    const amount = document.getElementById('expense-amount').value;
    const date = document.getElementById('expense-date').value;
    const catId = document.getElementById('expense-category').value;

    if (!amount || !catId) {
      showToast('Monto y Categoría son obligatorios', 'error');
      return;
    }

    try {
      const payload = {
        monto: parseFloat(amount),
        categoria_id: catId,
        descripcion: desc,
        fecha: date
      };

      if (type === 'edit-expense') {
        const updatePayload = {
          gasto_id: data.GastoId,
          ...payload
        };
        await api.fetch(`/gastos/actualizar`, {
          method: 'POST',
          body: JSON.stringify(updatePayload)
        });
        showToast('Gasto actualizado', 'success');
      } else {
        await api.fetch('/gastos', {
          method: 'POST',
          body: JSON.stringify(payload)
        });
        showToast('Gasto registrado con éxito', 'success');
      }

      closeModal();
      fetchData();
    } catch (err) {
      console.error(err);
      showToast('Error al procesar el gasto', 'error');
    }
  }
};

// --- Main Layout Wrapper ---
const AppLayout = (content) => `
  <div class="dashboard-layout">
    ${Sidebar()}
    ${state.isSidebarOpen && window.innerWidth <= 1024 ? `<div class="sidebar-overlay" onclick="window.toggleSidebar()"></div>` : ''}
    <div class="main-content">
      ${Header()}
      ${Loader()}
      <main class="content-body">
        ${content}
      </main>
    </div>
    ${Modal()}
  </div>
`;

window.toggleSidebar = () => {
  state.isSidebarOpen = !state.isSidebarOpen;
  render();
};

// --- Fetching Logic ---


// --- Fetching Logic ---
const fetchExpensesData = async () => {
  if (!state.token) return;
  try {
    const params = `?anio=${state.selectedYearExpenses}&mes=${state.selectedMonthExpenses.toString().padStart(2, '0')}`;
    // También recargamos categorias si aún no se han cargado
    const fetches = [api.fetch(`/gastos${params}`)];
    if (state.data.categorias.length === 0) fetches.push(api.fetch('/categorias'));
    const [gastos, cats] = await Promise.all(fetches);
    state.data.gastos = gastos.data || [];
    if (cats) state.data.categorias = cats.data || [];
    render();
  } catch (err) { console.error(err); }
};

const fetchBudgetData = async () => {
  if (!state.token) return;
  try {
    const params = `?anio=${state.selectedYear}&mes=${state.selectedMonth.toString().padStart(2, '0')}`;
    const comp = await api.fetch(`/presupuestos/comparativo${params}`);
    state.data.presupuestos = comp.data || [];
    
    // Recalcular stats para presupuesto (independiente de gastos mostrados en modulo Gastos)
    // El Dashboard usa stats basadas en el periodo de Presupuesto
    const totalGasto = state.data.gastos.reduce((sum, g) => {
      const gDate = new Date(g.FechaGasto);
      if (gDate.getFullYear() === state.selectedYear && (gDate.getMonth() + 1) === state.selectedMonth) {
        return sum + parseFloat(g.Monto || 0);
      }
      return sum;
    }, 0);

    const totalPresupuesto = state.data.presupuestos.reduce((sum, sec) => {
      const secTotal = sec.Items.reduce((s, item) => s + parseFloat(item.MontoPresupuestado || 0), 0);
      return sum + secTotal;
    }, 0);
    
    state.data.stats = {
      balance: totalPresupuesto - totalGasto,
      presupuesto: totalPresupuesto,
      gastosMes: totalGasto
    };
    render();
  } catch (err) { console.error(err); }
};

const fetchCategorias = async () => {
  if (!state.token) return;
  try {
    const result = await api.fetch('/categorias');
    state.data.categorias = result.data || [];
  } catch (err) { console.error('fetchCategorias:', err); }
};

const fetchData = async () => {
  if (!state.token) return;
  try {
    const paramsExp = `?anio=${state.selectedYearExpenses}&mes=${state.selectedMonthExpenses.toString().padStart(2, '0')}`;
    const paramsBud = `?anio=${state.selectedYear}&mes=${state.selectedMonth.toString().padStart(2, '0')}`;
    
    const [gastos, comp, cats] = await Promise.all([
      api.fetch(`/gastos${paramsExp}`),
      api.fetch(`/presupuestos/comparativo${paramsBud}`),
      api.fetch('/categorias')
    ]);
    
    state.data.gastos = gastos.data || [];
    state.data.presupuestos = comp.data || [];
    state.data.categorias = cats.data || [];
    
    // Stats para Dashboard (usa el periodo de presupuesto por defecto)
    const totalGastoForDashboard = state.data.gastos.reduce((sum, g) => {
       const gDate = new Date(g.FechaGasto);
       if (gDate.getFullYear() === state.selectedYear && (gDate.getMonth() + 1) === state.selectedMonth) {
         return sum + parseFloat(g.Monto || 0);
       }
       return sum;
    }, 0);

    const totalPresupuesto = state.data.presupuestos.reduce((sum, sec) => {
      const secTotal = sec.Items.reduce((s, item) => s + parseFloat(item.MontoPresupuestado || 0), 0);
      return sum + secTotal;
    }, 0);
    
    state.data.stats = {
      balance: totalPresupuesto - totalGastoForDashboard,
      presupuesto: totalPresupuesto,
      gastosMes: totalGastoForDashboard
    };
    
    state.data.lastFetched = new Date();
    render();
  } catch (err) {
    console.error('Data fetch error:', err);
  }
};


// --- Router and Rendering Logic ---

const render = () => {
  document.documentElement.setAttribute('data-theme', state.theme);
  const app = document.getElementById('app');
  // Normalize path by removing base path for internal routing
  let path = window.location.pathname;
  if (path.startsWith(BASE_PATH)) {
    path = path.substring(BASE_PATH.length);
  }
  if (path === '') path = '/';

  state.currentRoute = path;

  // Simple Routing Logic
  if (path === '/') {
    app.innerHTML = LandingPage();
  } else if (path === '/login') {
    app.innerHTML = AuthPage('login');
  } else if (path === '/register') {
    app.innerHTML = AuthPage('register');
  } else if (path === '/recover') {
    app.innerHTML = AuthPage('recover');
  } else if (['/dashboard', '/budget', '/expenses', '/profile', '/annual'].includes(path)) {
    if (!state.token) {
      navigate('/login');
      return;
    }

    // Fetch data if none or stale (simple cache)
    if (!state.isLoading && (!state.data.lastFetched || (new Date() - state.data.lastFetched > 300000))) {
      fetchData();
    }

    // These views require Layout
    let view = '';
    if (path === '/dashboard') view = DashboardView();
    if (path === '/budget') view = BudgetView();
    if (path === '/expenses') view = ExpensesView();
    if (path === '/profile') view = ProfileView();
    if (path === '/annual') view = AnnualView();

    app.innerHTML = AppLayout(view);

    // Init specific logic (like Charts) after mounting
    if (path === '/dashboard') initDashboardCharts();
    if (path === '/annual' && !state.data.annualData) fetchAnnualData();
  } else {
    app.innerHTML = `<div class="view-container" style="text-align:center; padding-top: 100px;">
      <h1 style="font-size: 4rem; color: var(--primary);">404</h1>
      <p>Página no encontrada: ${path}</p>
      <button class="btn btn-primary" onclick="navigate('/')" style="width:auto; margin: 2rem auto;">Volver al inicio</button>
    </div>`;
  }

  // Definir solo los iconos que usamos para optimizar el bundle
  const requiredIcons = { 
    LayoutDashboard, Wallet, ReceiptText, User, LogOut, Menu, X, Plus, 
    ChevronRight, ChevronDown, Edit2, TrendingUp, TrendingDown, Bell, 
    Search, DollarSign, Calendar, PieChart, Save, Trash2, RefreshCw, 
    Sun, Moon, Banknote, CreditCard, Scale, AlertTriangle, FolderPlus, Tag, BarChart3
  };

  setupEventListeners();
  createIcons({ icons: requiredIcons });
};

const setupEventListeners = () => {
  // Global clicks for SPA navigation
  document.querySelectorAll('[data-route]').forEach(el => {
    el.onclick = (e) => {
      e.preventDefault();
      navigate(el.getAttribute('data-route'));
    };
  });

  // Landing actions
  const btnLogin = document.getElementById('btn-login');
  if (btnLogin) btnLogin.onclick = () => navigate('/login');

  const btnRegister = document.getElementById('btn-register');
  if (btnRegister) btnRegister.onclick = () => navigate('/register');

  const btnCta = document.getElementById('btn-cta');
  if (btnCta) btnCta.onclick = () => navigate('/register');

  // Auth Links
  const linkReg = document.getElementById('link-register');
  if (linkReg) linkReg.onclick = (e) => { e.preventDefault(); navigate('/register'); };

  const linkLog = document.getElementById('link-login');
  if (linkLog) linkLog.onclick = (e) => { e.preventDefault(); navigate('/login'); };

  const linkLogBack = document.getElementById('link-login-back');
  if (linkLogBack) linkLogBack.onclick = (e) => { e.preventDefault(); navigate('/login'); };

  const linkRec = document.getElementById('link-recover');
  if (linkRec) linkRec.onclick = (e) => { e.preventDefault(); navigate('/recover'); };

  // Sidebar Toggle
  const sidebarBtn = document.getElementById('sidebar-toggle');
  if (sidebarBtn) sidebarBtn.onclick = () => window.toggleSidebar();

  // Auth Form Submit (Login/Reg)
  const authForm = document.getElementById('auth-form');
  if (authForm) {
    authForm.onsubmit = async (e) => {
      e.preventDefault();
      const email = authForm.querySelector('input[type="email"]').value;
      const pass = authForm.querySelector('input[type="password"]')?.value;
      const nameInput = authForm.querySelector('input[type="text"]');

      if (state.currentRoute === '/register') {
        await api.register(nameInput.value, email, pass);
      } else if (state.currentRoute === '/login') {
        await api.login(email, pass);
      }
    };
  }

  // Logout
  const btnLogout = document.getElementById('btn-logout');
  if (btnLogout) {
    btnLogout.onclick = (e) => {
      e.preventDefault();
      state.token = null;
      state.user = null;
      state.data.lastFetched = null;
      localStorage.removeItem('aura_token');
      localStorage.removeItem('aura_user');
      navigate('/');
    };
  }
};

const initDashboardCharts = () => {
  const ctx = document.getElementById('expenses-chart');
  if (!ctx || state.data.gastos.length === 0) return;

  // Agrupar gastos por categoría
  const cats = {};
  state.data.gastos.forEach(g => {
    cats[g.CategoriaNombre] = (cats[g.CategoriaNombre] || 0) + parseFloat(g.Monto);
  });

  const labels = Object.keys(cats);
  const chartData = Object.values(cats);

  new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: labels,
      datasets: [{
        data: chartData,
        backgroundColor: ['#3b82f6', '#06b6d4', '#8b5cf6', '#10b981', '#f59e0b', '#f43f5e', '#ec4899'],
        borderWidth: 0,
        hoverOffset: 15
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right',
          labels: { color: '#94a3b8', font: { family: 'Inter', size: 12 }, padding: 20 }
        }
      },
      cutout: '70%'
    }
  });
};

// --- Initialization ---
window.onpopstate = () => {
  state.currentRoute = window.location.pathname;
  render();
};

// Sync route on load (handle subpaths if configured on server)
state.currentRoute = window.location.pathname;
// --- Theme Management ---
window.toggleTheme = () => {
  state.theme = state.theme === 'dark' ? 'light' : 'dark';
  localStorage.setItem('aura_theme', state.theme);
  render();
};

render();
