import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-push-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, data: unknown) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function autorizado(req: Request) {
  const secret = Deno.env.get("PUSH_SECRET") || "";
  const headerSecret = req.headers.get("x-push-secret") || "";
  if (secret && headerSecret && headerSecret === secret) return true;

  const auth = req.headers.get("authorization") || "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  if (serviceKey && auth === `Bearer ${serviceKey}`) return true;

  return false;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }
  if (!autorizado(req)) {
    return json(401, { error: "unauthorized" });
  }

  let body: { type?: string; record?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch (_e) {
    return json(400, { error: "invalid_json" });
  }

  const record = body.record || {};
  const origemId = typeof record.id === "string" ? record.id : "";
  if (!origemId) {
    return json(400, { error: "record_id_required" });
  }

  const sb = createClient(
    Deno.env.get("SUPABASE_URL") || "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "",
  );

  const payload = {
    origem_id: origemId,
    data: (record.data as string) ?? null,
    tema: (record.tema as string) ?? null,
    texto: (record.texto as string) ?? null,
    link_youtube: (record.link_youtube as string) ?? null,
  };

  const { error } = await sb
    .from("rk_palavras")
    .upsert(payload, { onConflict: "origem_id" });

  if (error) {
    return json(500, { ok: false, error: error.message });
  }

  return json(200, { ok: true, tipo: body.type || "UPSERT", origem_id: origemId });
});
