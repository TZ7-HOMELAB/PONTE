import { configMessage, isConfigured } from './supabase-client.js';
export const byId = (id) => document.getElementById(id);
export function create(tag, properties = {}, text = '') { const node = document.createElement(tag); Object.entries(properties).forEach(([key, value]) => { if (key === 'className') node.className = value; else if (key.startsWith('data-')) node.setAttribute(key, value); else node[key] = value; }); if (text) node.textContent = text; return node; }
export const formatDate = (date) => date ? new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(`${date}T12:00:00`)) : 'Sem prazo';
export const todayISO = () => new Date().toISOString().slice(0, 10);
export function showMessage(message, type = 'info') { const region = byId('status-message'); if (!region) return; region.textContent = message; region.className = `status-message ${type}`; region.hidden = false; region.focus(); }
export function setLoading(button, loading, label = 'Carregando…') { if (!button) return; button.disabled = loading; button.dataset.label ||= button.textContent; button.textContent = loading ? label : button.dataset.label; }
export function emptyState(container, title, description) { container.replaceChildren(); const box = create('div', { className: 'empty-state' }); box.append(create('h3', {}, title), create('p', {}, description)); container.append(box); }
export function safeExternalLink(value) { try { const url = new URL(value); return ['https:', 'http:'].includes(url.protocol) ? url.href : null; } catch { return null; } }
export function renderConfigNotice() { if (!isConfigured()) showMessage(configMessage(), 'warning'); }
export function mountMenu() { const button = byId('menu-toggle'); const nav = byId('main-nav'); if (!button || !nav) return; button.addEventListener('click', () => { const open = button.getAttribute('aria-expanded') === 'true'; button.setAttribute('aria-expanded', String(!open)); nav.classList.toggle('is-open', !open); }); }
export function setCurrentNavigation() { document.querySelectorAll('[data-nav]').forEach((link) => { if (link.dataset.nav === document.body.dataset.page) link.setAttribute('aria-current', 'page'); }); }
