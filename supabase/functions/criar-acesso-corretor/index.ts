// Cria o login de um corretor por dentro do CRM.
// O cadastro público do Supabase foi desligado em 06/10 (qualquer pessoa podia
// criar conta); agora só o administrador do CRM (tabela crm_admins) cria acesso.
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const resp = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return resp(405, { erro: "Método não permitido." });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: quem } = await admin.auth.getUser(jwt);
  if (!quem?.user) return resp(401, { erro: "Sessão expirada. Entre de novo." });
  const { data: ehAdmin } = await admin.from("crm_admins").select("user_id").eq("user_id", quem.user.id).maybeSingle();
  if (!ehAdmin) return resp(403, { erro: "Só o administrador pode criar acesso." });

  let corpo: { corretor_id?: string; email?: string; senha?: string };
  try { corpo = await req.json(); } catch { return resp(400, { erro: "Dados inválidos." }); }
  const corretor_id = corpo.corretor_id;
  const email = (corpo.email || "").trim().toLowerCase();
  const senha = corpo.senha || "";
  if (!corretor_id || !email || !senha) return resp(400, { erro: "Preencha email e senha." });
  if (senha.length < 8) return resp(400, { erro: "A senha precisa ter pelo menos 8 caracteres." });

  const { data: corretor } = await admin.from("corretores").select("id,nome").eq("id", corretor_id).maybeSingle();
  if (!corretor) return resp(404, { erro: "Corretor não encontrado." });
  const { data: jaTem } = await admin.from("usuarios_corretores").select("user_id").eq("corretor_id", corretor_id).maybeSingle();
  if (jaTem) return resp(409, { erro: `${corretor.nome} já tem acesso.` });

  const { data: criado, error } = await admin.auth.admin.createUser({ email, password: senha, email_confirm: true });
  if (error || !criado?.user) {
    const jaExiste = /already|registered|exists/i.test(error?.message || "");
    return resp(400, { erro: jaExiste ? "Esse email já tem login no sistema." : "Não foi possível criar o acesso." });
  }

  const { error: erroVinculo } = await admin.from("usuarios_corretores").insert({ user_id: criado.user.id, corretor_id });
  if (erroVinculo) {
    await admin.auth.admin.deleteUser(criado.user.id);
    return resp(500, { erro: "Não foi possível vincular o acesso ao corretor." });
  }
  await admin.from("corretores").update({ email }).eq("id", corretor_id).is("email", null);

  return resp(200, { ok: true, nome: corretor.nome, email });
});
