const SB='https://jgdbnkwhmesgjvsymgma.supabase.co';
const SK='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZGJua3dobWVzZ2p2c3ltZ21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5MjAxODUsImV4cCI6MjA5MDQ5NjE4NX0.2KUPjnJE9vhzYviho16e3afWxyQL0usSjKXf2TLV00Q';

function getSession() {
  try {
    const s = localStorage.getItem('crm_session');
    if(!s) return null;
    const sess = JSON.parse(s);
    if(sess.expires_at < Date.now()/1000) {
      localStorage.removeItem('crm_session');
      return null;
    }
    return sess;
  } catch(e) { return null; }
}

function getHeaders() {
  const sess = getSession();
  if(!sess) { window.location.href='crm_login.html'; return null; }
  return {
    'apikey': SK,
    'Authorization': `Bearer ${sess.access_token}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };
}

function checkAuth() {
  const sess = getSession();
  if(!sess) window.location.href='crm_login.html';
  return sess;
}

function logout() {
  localStorage.removeItem('crm_session');
  window.location.href='crm_login.html';
}
