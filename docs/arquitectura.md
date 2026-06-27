# Arquitectura Técnica — Conecta X

## Principio General

Conecta X utiliza una arquitectura **JAMstack** (JavaScript, APIs, Markup): el frontend es HTML/CSS/JS estático servido desde un CDN global, y la lógica de negocio vive en funciones serverless que se invocan solo cuando el ciudadano las necesita.

Esta decisión no es estética: es la única arquitectura que permite operar a costo casi cero, escalar sin límite y mantener latencias bajas desde cualquier punto de Nayarit.

---

## ConectaX Salud — Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                        CIUDADANO                                │
│              (celular, tableta o computadora)                   │
└─────────────────────────┬───────────────────────────────────────┘
                          │  1. Abre la app en el navegador
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NETLIFY CDN (Edge)                            │
│              apps/salud/index.html                              │
│                                                                 │
│  • Formulario: municipio + síntomas                             │
│  • Diseño responsivo (mobile-first)                             │
│  • Sin frameworks (Vanilla JS/CSS)                              │
│  • Carga < 1s en 3G                                             │
└─────────────────────────┬───────────────────────────────────────┘
                          │  2. POST /api/triage
                          │     { sintomas, municipio }
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              NETLIFY FUNCTION (Serverless)                       │
│         apps/salud/netlify/functions/triage.mjs                 │
│                                                                 │
│  • Runtime: Node.js ESM                                         │
│  • Valida longitud mínima de síntomas (≥ 5 chars)               │
│  • Construye prompt con contexto de municipio                   │
│  • Llama a Anthropic SDK                                        │
│  • Parsea respuesta JSON del modelo                             │
│  • Headers CORS configurados                                    │
└─────────────────────────┬───────────────────────────────────────┘
                          │  3. Anthropic SDK → Claude API
                          │     model: claude-haiku-4-5
                          │     max_tokens: 600
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANTHROPIC CLAUDE API                          │
│                                                                 │
│  System prompt:                                                 │
│  • Rol: asistente de triaje médico de Nayarit                   │
│  • Estándar: CIE-11 (OMS)                                       │
│  • Catálogo de centros de salud por municipio                   │
│  • Restricción: solo JSON válido como respuesta                 │
│                                                                 │
│  Respuesta JSON:                                                │
│  {                                                              │
│    nivel_urgencia, emoji, tiempo_espera,                        │
│    centro_salud, indicacion,                                    │
│    codigo_cie11, descripcion_cie11                              │
│  }                                                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │  4. Respuesta al frontend
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FRONTEND (resultado)                           │
│                                                                 │
│  • Semáforo visual: 🔴 ALTA / 🟡 MEDIA / 🟢 BAJA               │
│  • Centro de salud recomendado                                  │
│  • Tiempo de espera estimado                                    │
│  • Código e descripción CIE-11                                  │
│  • Indicación empática en lenguaje ciudadano                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Decisiones de Diseño

### Por qué Netlify Functions y no un servidor propio

| Opción | Costo mensual | Mantenimiento | Escalabilidad |
|--------|---------------|---------------|---------------|
| Servidor VPS propio | $20–$100 USD | Alto (sysadmin, parches, backups) | Manual |
| Netlify Functions | $0 (tier gratuito hasta 125k invocaciones/mes) | Cero | Automática |

Para un gobierno estatal que recibe tráfico variable (picos en temporadas de gripe o dengue), el modelo serverless es la única opción sensata.

### Por qué `claude-haiku-4-5` y no un modelo más grande

- **Latencia**: Haiku responde en ~1 segundo. Opus o Sonnet pueden tardar 3–5 segundos, inaceptable en una interfaz ciudadana.
- **Costo**: Haiku cuesta ~40× menos que Opus por token. A escala de miles de consultas diarias, esto es determinante.
- **Calidad suficiente**: Para triaje orientativo (no diagnóstico clínico), Haiku tiene la capacidad necesaria cuando el system prompt está bien diseñado.

### Por qué vanilla HTML/CSS/JS

- React, Vue o Next.js añaden 100–500 KB de JavaScript que el navegador debe descargar, parsear y ejecutar.
- En zonas rurales de Nayarit con señal débil, eso significa 3–10 segundos adicionales de carga.
- La app actual carga completa en < 50 KB.

### Por qué CIE-11 y no CIE-10

CIE-11 es el estándar actual de la OMS (vigente desde 2022). Su adopción en México está en proceso, pero diseñar con CIE-11 desde el inicio garantiza:
- Interoperabilidad futura con el sistema nacional de salud
- Mejor granularidad en condiciones mentales y enfermedades crónicas
- Alineación con sistemas del IMSS que están migrando al estándar

---

## Seguridad

- **Headers HTTP**: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff` configurados en `netlify.toml`.
- **API key**: `ANTHROPIC_API_KEY` se configura como variable de entorno en Netlify, nunca en el código fuente.
- **Sin autenticación de usuario**: la app es anónima por diseño. No se almacena ningún dato personal ni historial clínico.
- **CORS**: configurado explícitamente en la función, solo acepta el origen del propio sitio en producción.

---

## Variables de Entorno

| Variable | Descripción | Dónde configurar |
|----------|-------------|------------------|
| `ANTHROPIC_API_KEY` | API key de Anthropic para Claude | Netlify → Site settings → Environment variables |

---

## Deploy

El deploy es automático desde este repositorio vía Netlify CI/CD:

1. Push a `main` → Netlify detecta cambios en `apps/salud/`
2. Build: publica el directorio `apps/salud/` como sitio estático
3. Functions: empaqueta `netlify/functions/*.mjs` con esbuild
4. Deploy: distribución global en CDN de Netlify (< 30 segundos total)
