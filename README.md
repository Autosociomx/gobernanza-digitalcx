# Ecosistema Conecta X

**Plataforma de Gobernanza Digital para Nayarit · 2027–2033**

Conecta X es un ecosistema de servicios públicos digitales que conecta a los ciudadanos de Nayarit con el gobierno a través de inteligencia artificial, interfaces accesibles y estándares internacionales. Cada módulo resuelve un problema real del ciudadano: menos filas, menos papeleo, respuestas inmediatas.

---

## Módulos del Ecosistema

| Módulo | Estado | Descripción |
|--------|--------|-------------|
| [ConectaX Salud](./apps/salud/) | **Live** | Triaje médico digital con IA y estándar CIE-11 |
| ConectaX Trámites | Roadmap | Gestión de permisos y licencias municipales en línea |
| ConectaX Educación | Roadmap | Orientación escolar y becas para estudiantes nayaritas |
| ConectaX Seguridad | Roadmap | Reporte ciudadano de incidencias con geolocalización |

---

## ConectaX Salud — En Producción

El primer módulo del ecosistema. Permite al ciudadano describir sus síntomas en lenguaje natural y recibe en segundos:

- **Nivel de urgencia** (ALTA / MEDIA / BAJA) con semáforo visual
- **Centro de salud recomendado** según su municipio
- **Tiempo de espera estimado**
- **Código CIE-11** (estándar OMS) de la condición más probable
- **Indicación clara** de qué hacer a continuación

Conectado a las 285 unidades de salud del estado de Nayarit.

### Demo rápida

1. El ciudadano selecciona su municipio (10 municipios disponibles)
2. Describe sus síntomas en texto libre
3. La IA analiza con estándar CIE-11 y responde en < 3 segundos

```
Entrada: "Tengo fiebre de 38.5°C desde ayer y dolor de cabeza fuerte"
Salida:  { urgencia: "MEDIA", centro: "Hospital Civil de Tepic",
           espera: "25 minutos", codigo: "MG2Y", ... }
```

---

## Stack Tecnológico

```
Frontend     HTML5 · CSS3 (vanilla, sin frameworks) · JavaScript ES6+
Backend      Netlify Functions (Node.js ESM / serverless)
IA           Anthropic Claude API (claude-haiku-4-5)
Deploy       Netlify (CI/CD automático desde este repo)
Estándar     CIE-11 (Clasificación Internacional de Enfermedades, OMS)
```

### Por qué este stack

- **Sin frameworks**: el frontend carga en < 1 segundo en conexiones 3G, crítico para zonas rurales de Nayarit.
- **Serverless**: costo operativo cercano a cero para el gobierno; escala automáticamente en picos de demanda.
- **Claude API**: procesamiento de lenguaje natural en español con alta precisión clínica sin necesidad de entrenar un modelo propio.
- **CIE-11**: estándar internacional que permite interoperabilidad con sistemas del IMSS, ISSSTE y Secretaría de Salud.

---

## Arquitectura

```
Ciudadano
    │
    ▼
┌─────────────────────────────┐
│   Frontend (index.html)     │  ← HTML/CSS/JS estático en Netlify CDN
│   - Formulario de síntomas  │
│   - Resultados con semáforo │
└──────────┬──────────────────┘
           │ POST /api/triage
           ▼
┌─────────────────────────────┐
│   Netlify Function          │  ← Node.js serverless, edge deploy
│   (netlify/functions/       │
│    triage.mjs)              │
└──────────┬──────────────────┘
           │ Anthropic SDK
           ▼
┌─────────────────────────────┐
│   Claude API                │  ← Análisis CIE-11, respuesta JSON
│   claude-haiku-4-5          │
└─────────────────────────────┘
```

Más detalles en [docs/arquitectura.md](./docs/arquitectura.md).

---

## Estructura del Repositorio

```
conecta-x/
├── apps/
│   └── salud/                   # ConectaX Salud (triaje médico)
│       ├── index.html           # Frontend completo (SPA)
│       ├── netlify.toml         # Configuración de deploy
│       ├── package.json
│       └── netlify/
│           └── functions/
│               └── triage.mjs   # Serverless function con Claude API
├── docs/
│   ├── arquitectura.md          # Arquitectura técnica detallada
│   ├── vision.md                # Visión y propuesta de valor
│   └── roadmap.md               # Roadmap del ecosistema
└── .github/
    └── ISSUE_TEMPLATE/          # Templates para contribuciones
```

---

## Impacto Proyectado

| Métrica | Meta 2027–2033 |
|---------|----------------|
| Reducción en tiempos de espera hospitalaria | 50% |
| Unidades de salud conectadas | 285 |
| Municipios con cobertura digital | 20 |
| Ciudadanos con acceso a servicios en línea | 1.3 M |

---

## Despliegue Local

### Requisitos
- Node.js 18+
- Netlify CLI (`npm install -g netlify-cli`)
- API key de Anthropic

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/autosociomx/gobernanza-digitalcx.git
cd gobernanza-digitalcx/apps/salud

# 2. Instalar dependencias
npm install

# 3. Configurar API key
export ANTHROPIC_API_KEY="tu_api_key_aqui"

# 4. Levantar entorno local
netlify dev
```

La app estará disponible en `http://localhost:8888`.

---

## Visión

Conecta X es la infraestructura digital del gobierno ciudadano: un estado que responde, que escucha y que actúa. Cada módulo reduce la brecha entre el ciudadano y sus derechos.

Ver [docs/vision.md](./docs/vision.md) para la propuesta completa.

---

## Autora

**Geraldine Ponce** · Nayarit Digital 2027–2033

> Ante emergencias médicas, siempre llama al **911**.
> Este ecosistema es un complemento digital, no un sustituto de la atención médica profesional.
