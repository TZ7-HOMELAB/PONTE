(() => {
  const form = document.getElementById('login-form');
  const status = document.getElementById('status-message');
  if (!form || !status) return;

  const message = (text, type = 'info') => {
    status.textContent = text;
    status.className = `status-message ${type}`;
    status.hidden = false;
    status.focus();
  };

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    const button = form.querySelector('button[type="submit"]');
    button.disabled = true;
    button.textContent = 'Entrando…';
    try {
      const config = await import('./config.js');
      if (!config.SUPABASE_URL || !config.SUPABASE_PUBLISHABLE_KEY) throw new Error('A configuração do Supabase está incompleta.');
      let supabaseModule;
      try {
        supabaseModule = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm');
      } catch {
        supabaseModule = await import('https://esm.sh/@supabase/supabase-js@2.49.1');
      }
      const supabase = supabaseModule.createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY);
      const email = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value;
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      window.location.assign('./dashboard.html');
    } catch (error) {
      message(error.message || 'Não foi possível entrar.', 'error');
    } finally {
      button.disabled = false;
      button.textContent = 'Entrar';
    }
  });
})();
