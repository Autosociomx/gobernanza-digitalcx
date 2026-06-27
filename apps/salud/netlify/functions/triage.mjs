import Anthropic from "@anthropic-ai/sdk";

export default async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const { sintomas, municipio } = await req.json();

    if (!sintomas || sintomas.length < 5) {
      return new Response(
        JSON.stringify({ error: "Por favor describe tus síntomas con más detalle." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const client = new Anthropic();
    const response = await client.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 600,
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
- Otros: Centro de Salud del municipio más cercano

FORMATO DE RESPUESTA (JSON exacto):
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
        content: `Municipio: ${municipio || "Tepic, Nayarit"}\nSíntomas: ${sintomas}`
      }]
    });

    const text = response.content[0].text.trim();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("Respuesta inválida del modelo");

    const data = JSON.parse(jsonMatch[0]);

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });
  } catch (error) {
    console.error("ConectaX error:", error);
    return new Response(
      JSON.stringify({ error: "Error al procesar la consulta. Por favor intenta de nuevo." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
};

export const config = { path: "/api/triage" };
