'use strict';
const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

const clientOptions = {
  auth: { autoRefreshToken: false, detectSessionInUrl: false, persistSession: false },
};

function createAdminClient() {
  return createClient(config.supabaseUrl, config.supabaseServiceRoleKey, clientOptions);
}

function createPublicClient(accessToken) {
  const options = { ...clientOptions };
  if (accessToken) options.accessToken = async () => accessToken;
  return createClient(config.supabaseUrl, config.supabasePublishableKey, options);
}

function assertSupabaseConfig() {
  if (!config.supabaseUrl || !config.supabasePublishableKey || !config.supabaseServiceRoleKey) {
    throw new Error('Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, and SUPABASE_SERVICE_ROLE_KEY in backend/.env.');
  }
  try {
    new URL(config.supabaseUrl);
  } catch {
    throw new Error('SUPABASE_URL must be a valid URL.');
  }
}

module.exports = { createAdminClient, createPublicClient, assertSupabaseConfig };
