const SB='https://jgdbnkwhmesgjvsymgma.supabase.co';
const SK='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZGJua3dobWVzZ2p2c3ltZ21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5MjAxODUsImV4cCI6MjA5MDQ5NjE4NX0.2KUPjnJE9vhzYviho16e3afWxyQL0usSjKXf2TLV00Q';

async function refreshSession() {
  try {
    const s = localStorage.getItem('crm_session');
    if (!s) return null;
    const sess = JSON.parse(s);
    if (!sess.refresh_token) return null;
    const res = await fetch(`${SB}/auth/v1/token?grant_type=refresh_token`, {
      method: 'POST',
      headers: { 'apikey': SK, 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: sess.refresh_token })
    });
    const data = await res.json();
    if (data.access_token) {
      localStorage.setItem('crm_session', JSON.stringify({
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_at: data.expires_at
      }));
      return data.access_token;
    }
    return null;
  } catch(e) { return null; }
}

async function getSession() {
  try {
    const s = localStorage.getItem('crm_session');
    if (!s) return null;
    const sess = JSON.parse(s);
    if (sess.expires_at > Date.now()/1000 + 60) return sess;
    const newToken = await refreshSession();
    if (newToken) {
      return JSON.parse(localStorage.getItem('crm_session'));
    }
    localStorage.removeItem('crm_session');
    return null;
  } catch(e) { return null; }
}

async function getHeaders() {
  const sess = await getSession();
  if (!sess) { window.location.href='index.html'; return null; }
  return {
    'apikey': SK,
    'Authorization': `Bearer ${sess.access_token}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };
}

async function checkAuth() {
  const sess = await getSession();
  if (!sess) window.location.href = 'index.html';
  return sess;
}

async function getCorretorLogado() {
  try {
    const sess = await getSession();
    if (!sess) return null;

    // Extrai o user_id do token JWT
    const payload = JSON.parse(atob(sess.access_token.split('.')[1]));
    const userId = payload.sub;

    const res = await fetch(`${SB}/rest/v1/usuarios_corretores?user_id=eq.${userId}&select=corretor_id`, {
      headers: {
        'apikey': SK,
        'Authorization': `Bearer ${sess.access_token}`,
        'Content-Type': 'application/json'
      }
    });
    const data = await res.json();
    return data?.[0]?.corretor_id || null;
  } catch(e) {
    return null;
  }
}

function logout() {
  localStorage.removeItem('crm_session');
  window.location.href = 'index.html';
}
