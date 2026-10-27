let client = null;
let configurationError = null;

try {
  // Import dinâmico: se o CDN estiver indisponível, a página ainda mostra uma mensagem
  // e não deixa o formulário enviar/recarregar sem feedback.
  let packageModule;
  try {
    packageModule = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm');
  } catch {
    packageModule = await import('https://esm.sh/@supabase/supabase-js@2.49.1');
  }
  const { createClient } = packageModule;
  const config = await import('./config.js');
  if (!config.SUPABASE_URL || !config.SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_URL.includes('SEU-PROJETO') || config.SUPABASE_PUBLISHABLE_KEY.includes('SUA_CHAVE')) {
    throw new Error('Configuração incompleta.');
  }
  client = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
} catch (error) {
  configurationError = error;
}

export function getSupabase() {
  if (!client) throw configurationError || new Error('Configuração incompleta.');
  return client;
}
export function isConfigured() { return Boolean(client); }
export const configMessage = () => 'Não foi possível iniciar a conexão com o Supabase. Confira js/config.js e atualize a página.';
