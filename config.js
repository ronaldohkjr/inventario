// Configuração do portal. Pegue os dois valores no Supabase:
// Project Settings > API > "Project URL" e "anon public" (chave pública).
// A chave "anon" pode ficar pública: quem protege os dados são as regras do banco (schema.sql).
// NUNCA coloque aqui a chave "service_role".
window.INV_CONFIG = {
  url: "COLE_AQUI_A_PROJECT_URL",      // ex.: "https://abcdefghijk.supabase.co"
  anonKey: "COLE_AQUI_A_CHAVE_ANON"
};
