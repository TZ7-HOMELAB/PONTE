import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
let client = null;
let configurationError = null;
try {
  const config = await import('./config.js');
  if (!config.SUPABASE_URL || !config.SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_URL.includes('SEU-PROJETO') || config.SUPABASE_PUBLISHABLE_KEY.includes('SUA_CHAVE')) throw new Error('Configuração incompleta.');
  client = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } });
} catch (error) { configurationError = error; }
export function getSupabase() { if (!client) throw configurationError || new Error('Configuração incompleta.'); return client; }
export function isConfigured() { return Boolean(client); }
export const configMessage = () => 'Configuração incompleta. Copie js/config.example.js para js/config.js e informe a URL e a chave pública do Supabase.';
