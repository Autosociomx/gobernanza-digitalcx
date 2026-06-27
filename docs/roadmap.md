# Roadmap — Ecosistema Conecta X

## Estado Actual

### ConectaX Salud — v1.0 (Producción)

- [x] Frontend responsivo con formulario de síntomas
- [x] Integración con Claude API (Anthropic)
- [x] Clasificación CIE-11 de condiciones
- [x] Semáforo de urgencia (ALTA / MEDIA / BAJA)
- [x] Catálogo de 10 municipios con centros de salud reales
- [x] Serverless deploy en Netlify
- [x] Headers de seguridad HTTP configurados

---

## Próximas Versiones

### ConectaX Salud — v1.1

- [ ] Agregar los 10 municipios restantes (cobertura completa de los 20 municipios de Nayarit)
- [ ] Soporte para lenguaje indígena (cora, huichol) — traducción básica de síntomas comunes
- [ ] Botón de llamada directa al centro de salud recomendado
- [ ] Modo offline básico (caché de respuestas frecuentes con Service Worker)

### ConectaX Salud — v2.0

- [ ] Integración en tiempo real con sistemas IMSS/ISSSTE para consultar camas disponibles
- [ ] Historial de consultas anónimo por sesión (sin crear cuenta)
- [ ] Alerta de epidemia: si un código CIE-11 supera umbral de frecuencia en un municipio, notifica a Secretaría de Salud
- [ ] API pública para integración con app del gobierno de Nayarit

---

## Módulos Futuros

### ConectaX Trámites — v1.0 (2028)

Objetivo: digitalizar el 100% de los trámites municipales de mayor volumen.

**Trámites prioritarios (por frecuencia):**
- Licencia de funcionamiento comercial
- Permiso de construcción
- Registro de nacimiento
- Constancia de residencia

**Stack previsto:**
- Frontend: mismo patrón (HTML/CSS/JS vanilla)
- Backend: Netlify Functions + Supabase (base de datos de expedientes)
- Firma electrónica: integración con e.firma del SAT
- Notificaciones: WhatsApp Business API para actualizaciones de estatus

**KPI de éxito:**
- 80% de trámites iniciados digitalmente en municipios participantes
- Tiempo promedio de resolución < 5 días hábiles (vs 15–30 días actuales)

---

### ConectaX Educación — v1.0 (2030)

Objetivo: ningún estudiante nayarita pierde una beca o una oportunidad por falta de información.

**Funcionalidades:**
- Buscador de becas federales, estatales y municipales filtrado por perfil del estudiante
- Orientación vocacional con IA: ingresa intereses y habilidades, recibe sugerencias de carreras con demanda real en Nayarit
- Directorio de universidades e institutos técnicos del estado con costos, requisitos y calendario

**Fuentes de datos:**
- CONACYT / CONAHCYT (becas nacionales)
- SEP Nayarit (becas estatales)
- ANUIES (datos de universidades)

---

### ConectaX Seguridad — v1.0 (2031)

Objetivo: un canal directo entre el ciudadano y las autoridades, con trazabilidad de respuesta.

**Funcionalidades:**
- Reporte ciudadano geolocalizado (bache, alumbrado, incidente de seguridad)
- Seguimiento de reporte con número de folio
- Integración con C4 de Nayarit para incidentes de seguridad
- Dashboard público de tiempos de respuesta por municipio (transparencia)

**Consideraciones de seguridad:**
- Reportes anónimos por defecto
- Moderación automática con IA para filtrar reportes duplicados o spam
- Cifrado de extremo a extremo para reportes sensibles

---

## Infraestructura del Ecosistema (Transversal)

### Identidad Digital Ciudadana — v1.0 (2029)

Un único acceso opcional para todos los módulos:
- Login con CURP + número celular (OTP)
- Sin contraseñas que recordar
- El ciudadano controla qué datos comparte con cada módulo

### Dashboard de Gobernanza — (Interno, 2028)

Panel para funcionarios del estado:
- Métricas en tiempo real de uso por módulo y municipio
- Alertas de demanda inusual (posible epidemia, pico de trámites)
- Exportación de reportes para Congreso del Estado

---

## Notas de Versioning

Este proyecto sigue [Semantic Versioning](https://semver.org/):
- `MAJOR`: cambio incompatible en la interfaz pública o en la API
- `MINOR`: nueva funcionalidad retrocompatible
- `PATCH`: correcciones de errores

Cada módulo tiene su propia versión independiente.
