import Anthropic from "@anthropic-ai/sdk";

const MUNICIPIOS_VALIDOS = new Set([
  "Tepic", "Bahía de Banderas", "Compostela", "Santiago Ixcuintla",
  "Tuxpan", "Acaponeta", "Ruíz", "Ixtlán del Río", "Rosamorada", "El Nayar"
]);

const NIVEL_URGENCIA_VALIDO = new Set(["ALTA", "MEDIA", "BAJA"]);

const SINTOMAS_MAX_CHARS = 2000;

const client = new Anthropic();

export default async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Restricción CORS: solo el mismo origen en producción
  const origin = req.headers.get("origin") || "";
  const allowedOrigin = process.env.ALLOWED_ORIGIN || origin;

  const corsHeaders = {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Cuerpo de la solicitud inválido." }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }

  const { sintomas, municipio } = body;

  // Validación de síntomas
  if (!sintomas || typeof sintomas !== "string" || sintomas.trim().length < 5) {
    return new Response(
      JSON.stringify({ error: "Por favor describe tus síntomas con más detalle." }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }

  if (sintomas.length > SINTOMAS_MAX_CHARS) {
    return new Response(
      JSON.stringify({ error: `Los síntomas no pueden superar ${SINTOMAS_MAX_CHARS} caracteres.` }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }

  // Validación de municipio contra lista cerrada
  const municipioSeguro = MUNICIPIOS_VALIDOS.has(municipio) ? municipio : "Tepic";

  // Sanitización básica: elimina caracteres de control y secuencias de escape de prompt
  const sintomasSeguro = sintomas
    .replace(/[\x00-\x1F\x7F]/g, " ")
    .trim();

  try {
    // Timeout explícito de 10 segundos sobre el SDK
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("TIMEOUT")), 10_000)
    );

    const apiPromise = client.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 700,
      system: `Eres ConectaX, el asistente de triaje médico digital del Estado de Nayarit, México.
Tu función es orientar al ciudadano según sus síntomas usando el estándar CIE-11.

REGLAS:
- Responde ÚNICAMENTE con JSON válido, sin texto adicional antes o después
- No diagnostiques enfermedades, solo orienta sobre urgencia y centro de salud
- Usa centros de salud reales de Nayarit según el municipio indicado
- Sé empático, claro y breve

CENTROS DE SALUD POR MUNICIPIO:
- Tepic: Hospital Civil de Tepic, Hospital General de Zona IMSS No. 1, ISSSTE Tepic
- Bahía de Banderas: Hospital General Bahía de Banderas
- Compostela: Hospital Básico Compostela
- Santiago Ixcuintla: Hospital Básico Santiago Ixcuintla
- Tuxpan: Centro de Salud Tuxpan
- Acaponeta: Hospital Básico Acaponeta
- Ruíz: Centro de Salud Ruíz
- Ixtlán del Río: Centro de Salud Ixtlán del Río
- Rosamorada: Centro de Salud Rosamorada
- El Nayar: Centro de Salud El Nayar

FORMATO DE RESPUESTA (JSON exacto, sin texto fuera del JSON):
{
  "nivel_urgencia": "ALTA o MEDIA o BAJA",
  "emoji": "🔴 o 🟡 o 🟢",
  "tiempo_espera": "estimado ejemplo: 15 minutos",
  "centro_salud": "nombre del centro de salud recomendado",
  "indicacion": "instrucción clara y empática, máximo 2 oraciones",
  "codigo_cie11": "código CIE-11 más probable",
  "descripcion_cie11": "nombre de la condición en español según CIE-11"
}`,
      messages: [{
        role: "user",
        content: `Municipio: ${municipioSeguro}, Nayarit\nSíntomas: ${sintomasSeguro}`
      }]
    });

    const apiResponse = await Promise.race([apiPromise, timeoutPromise]);

    const text = apiResponse.content[0]?.text?.trim() ?? "";

    // Regex no-greedy para extraer solo el primer objeto JSON completo
    const jsonMatch = text.match(/\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}/);
    if (!jsonMatch) throw new Error("INVALID_JSON");

    const data = JSON.parse(jsonMatch[0]);

    // Validación de esquema: forzar valores seguros si el modelo devuelve basura
    const safeData = {
      nivel_urgencia: NIVEL_URGENCIA_VALIDO.has(data.nivel_urgencia) ? data.nivel_urgencia : "MEDIA",
      emoji: ["🔴", "🟡", "🟢"].includes(data.emoji) ? data.emoji : "🟡",
      tiempo_espera: typeof data.tiempo_espera === "string" ? data.tiempo_espera : "N/D",
      centro_salud: typeof data.centro_salud === "string" ? data.centro_salud : "Centro de Salud más cercano",
      indicacion: typeof data.indicacion === "string" ? data.indicacion : "Acuda al centro de salud de su municipio.",
      codigo_cie11: typeof data.codigo_cie11 === "string" ? data.codigo_cie11 : "En análisis",
      descripcion_cie11: typeof data.descripcion_cie11 === "string" ? data.descripcion_cie11 : "",
    };

    return new Response(JSON.stringify(safeData), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders }
    });

  } catch (error) {
    const isTimeout = error.message === "TIMEOUT";
    const isRateLimit = error.status === 429;

    console.error("ConectaX triage error", {
      type: isTimeout ? "timeout" : isRateLimit ? "rate_limit" : "unknown",
      message: error.message,
    });

    if (isTimeout) {
      return new Response(
        JSON.stringify({ error: "El servicio tardó demasiado. Por favor intenta de nuevo." }),
        { status: 504, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (isRateLimit) {
      return new Response(
        JSON.stringify({ error: "Servicio temporalmente ocupado. Intenta en unos segundos." }),
        { status: 503, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Error al procesar la consulta. Por favor intenta de nuevo." }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
};

export const config = { path: "/api/triage" };
