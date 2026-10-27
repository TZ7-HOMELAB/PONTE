let client = null;
let configurationError = null;

// Não use top-level await aqui: a tela de login precisa ativar seus eventos imediatamente.
async function initializeClient() {
  try {
    const config = await import('./config.js');
    if (!config.SUPABASE_URL || !config.SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_URL.includes('SEU-PROJETO') || config.SUPABASE_PUBLISHABLE_KEY.includes('SUA_CHAVE')) {
      throw new Error('Configuração incompleta.');
    }
    let packageModule;
    try {
      packageModule = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm');
    } catch {
      packageModule = await import('https://esm.sh/@supabase/supabase-js@2.49.1');
    }
    client = packageModule.createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
  } catch (error) {
    configurationError = error;
  }
}

const initialization = initializeClient();

export async function waitForSupabase() {
  await initialization;
  return getSupabase();
}

export function getSupabase() {
  if (client) return client;
  throw configurationError || new Error('A conexão está sendo iniciada. Aguarde alguns segundos e tente novamente.');
}
export function isConfigured() { return configurationError === null; }
export const configMessage = () => 'Não foi possível iniciar a conexão com o Supabase. Confira js/config.js e atualize a página.';
