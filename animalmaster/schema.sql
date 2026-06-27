-- ═══════════════════════════════════════════════════════════
-- Animal Master · Las 7 Especies — Schema Supabase
-- Gobernanza Digital Nayarit 2026
-- ═══════════════════════════════════════════════════════════

-- Tabla principal de animales
CREATE TABLE IF NOT EXISTS animales (
  id           TEXT PRIMARY KEY,              -- Ej: BV-001, PC-003
  nombre       TEXT NOT NULL,
  especie      TEXT NOT NULL CHECK (especie IN ('bovino','porcino','ovino','caprino','equino','aviar','apicola')),
  raza         TEXT,
  edad         INTEGER,                        -- En años
  peso         NUMERIC(8,2),                  -- Kg
  produccion   NUMERIC(10,2),                 -- Leche(L), ganancia(g), huevos(ud), miel(kg), condición(/5)
  score        INTEGER DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  categoria    TEXT GENERATED ALWAYS AS (
    CASE
      WHEN score >= 80 THEN 'oro'
      WHEN score >= 50 THEN 'plata'
      ELSE 'regular'
    END
  ) STORED,
  lote         TEXT,                           -- Lote o grupo al que pertenece
  activo       BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Eventos de salud (vacunas, tratamientos, partos, etc.)
CREATE TABLE IF NOT EXISTS eventos_salud (
  id           BIGSERIAL PRIMARY KEY,
  animal_id    TEXT REFERENCES animales(id) ON DELETE CASCADE,
  tipo         TEXT NOT NULL CHECK (tipo IN ('vacuna','tratamiento','parto','pesaje','esquila','otro')),
  descripcion  TEXT NOT NULL,
  fecha        DATE NOT NULL DEFAULT CURRENT_DATE,
  veterinario  TEXT,
  costo        NUMERIC(10,2),
  notas        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Calendario de vacunas futuras (alertas)
CREATE TABLE IF NOT EXISTS vacunas_programadas (
  id           BIGSERIAL PRIMARY KEY,
  especie      TEXT NOT NULL,
  lote         TEXT,
  vacuna       TEXT NOT NULL,
  fecha_prog   DATE NOT NULL,
  animales_cnt INTEGER,
  aplicada     BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Historial de scores (permite graficar evolución Oro Puro)
CREATE TABLE IF NOT EXISTS score_historial (
  id           BIGSERIAL PRIMARY KEY,
  animal_id    TEXT REFERENCES animales(id) ON DELETE CASCADE,
  score        INTEGER NOT NULL,
  produccion   NUMERIC(10,2),
  peso         NUMERIC(8,2),
  fecha        DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Cruces / reproducción recomendada
CREATE TABLE IF NOT EXISTS cruces (
  id           BIGSERIAL PRIMARY KEY,
  macho_id     TEXT REFERENCES animales(id),
  hembra_id    TEXT REFERENCES animales(id),
  fecha_prog   DATE,
  fecha_real   DATE,
  exitoso      BOOLEAN,
  crias        INTEGER DEFAULT 0,
  notas        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── ÍNDICES ──
CREATE INDEX IF NOT EXISTS idx_animales_especie  ON animales(especie);
CREATE INDEX IF NOT EXISTS idx_animales_score    ON animales(score DESC);
CREATE INDEX IF NOT EXISTS idx_animales_categoria ON animales(categoria);
CREATE INDEX IF NOT EXISTS idx_eventos_animal    ON eventos_salud(animal_id);
CREATE INDEX IF NOT EXISTS idx_eventos_fecha     ON eventos_salud(fecha DESC);

-- ── ROW LEVEL SECURITY ──
ALTER TABLE animales           ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_salud      ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacunas_programadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_historial    ENABLE ROW LEVEL SECURITY;
ALTER TABLE cruces             ENABLE ROW LEVEL SECURITY;

-- Lectura pública (demo y modo conectado)
CREATE POLICY "read_animales"    ON animales            FOR SELECT USING (true);
CREATE POLICY "read_eventos"     ON eventos_salud       FOR SELECT USING (true);
CREATE POLICY "read_vacunas"     ON vacunas_programadas FOR SELECT USING (true);
CREATE POLICY "read_score"       ON score_historial     FOR SELECT USING (true);
CREATE POLICY "read_cruces"      ON cruces              FOR SELECT USING (true);

-- Escritura para usuarios autenticados
CREATE POLICY "write_animales"   ON animales            FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "write_eventos"    ON eventos_salud       FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "write_vacunas"    ON vacunas_programadas FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "write_score"      ON score_historial     FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "write_cruces"     ON cruces              FOR ALL USING (auth.role() = 'authenticated');

-- ── DATOS DEMO INICIALES ──
INSERT INTO animales (id, nombre, especie, raza, edad, peso, produccion, score, lote) VALUES
  ('BV-001','La Consentida','bovino', 'Holstein',    5, 680, 24.0, 94, 'Norte'),
  ('BV-002','Manchada',     'bovino', 'Suizo',       4, 620, 19.2, 83, 'Norte'),
  ('BV-003','Pinta',        'bovino', 'Cebú',        6, 580, 15.8, 62, 'Sur'),
  ('BV-004','Negra Linda',  'bovino', 'Holstein',    3, 560, 20.1, 80, 'Norte'),
  ('PC-001','Gordita',      'porcino','Yorkshire',   2, 118, 860,  91, 'Corral A'),
  ('PC-002','Negra Reina',  'porcino','Duroc',       3, 105, 810,  85, 'Corral A'),
  ('PC-003','Rosada',       'porcino','Landrace',    2, 96,  775,  70, 'Corral B'),
  ('OV-001','Perla',        'ovino',  'Rambouillet', 3, 54,  4.1,  89, 'Pradera 1'),
  ('OV-002','Flor',         'ovino',  'Merino',      4, 51,  3.8,  82, 'Pradera 1'),
  ('OV-003','Luna',         'ovino',  'Pelibuey',    2, 44,  2.9,  58, 'Pradera 2'),
  ('CP-001','Lunares',      'caprino','Nubia',       4, 46,  3.1,  88, 'Cerro'),
  ('CP-002','Blanquita',    'caprino','Saanen',      3, 42,  2.6,  75, 'Cerro'),
  ('CP-007','Flaca',        'caprino','Criolla',     5, 28,  1.2,  21, 'Cerro'),
  ('EQ-001','Trueno',       'equino', 'Cuarto Milla',6, 480, 4.8,  92, 'Caballeriza'),
  ('EQ-002','Estrella',     'equino', 'Azteca',      4, 440, 4.5,  85, 'Caballeriza'),
  ('EQ-003','Palomo',       'equino', 'Criollo',     8, 380, 3.6,  55, 'Pastura'),
  ('AV-001','Lote Rojo A',  'aviar',  'Leghorn',     1, 1.9, 340,  90, 'Gallinero 1'),
  ('AV-002','Lote Café B',  'aviar',  'Rhode Island',2, 2.2, 315,  81, 'Gallinero 2'),
  ('AV-003','Lote Negro C', 'aviar',  'Plymouth',    2, 2.4, 268,  52, 'Gallinero 3'),
  ('AP-001','Colmena Rey A','apicola','Italiana',    3, 22,  26.5, 93, 'Apiario Norte'),
  ('AP-002','Colmena Sol B','apicola','Carniola',    2, 20,  22.0, 84, 'Apiario Norte'),
  ('AP-003','Colmena Luna C','apicola','Italiana',   1, 16,  14.0, 60, 'Apiario Sur'),
  ('AP-005','Colmena AM-05','apicola','Africanizada',2, 18,  12.0, 42, 'Apiario Sur')
ON CONFLICT (id) DO NOTHING;

-- ── FUNCIÓN: recalcular score ──
-- Llámala mensualmente: SELECT recalcular_scores();
CREATE OR REPLACE FUNCTION recalcular_scores()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  promedios RECORD;
  a         RECORD;
  new_score INTEGER;
BEGIN
  -- Por cada especie calcula el promedio de produccion
  FOR a IN SELECT * FROM animales WHERE activo = TRUE LOOP
    SELECT AVG(produccion) INTO promedios FROM animales
    WHERE especie = a.especie AND activo = TRUE;

    IF promedios.avg > 0 THEN
      new_score := LEAST(100, GREATEST(0, ROUND((a.produccion / promedios.avg) * 70 + (a.peso / 100) * 15)));
    ELSE
      new_score := 50;
    END IF;

    UPDATE animales SET score = new_score, updated_at = NOW() WHERE id = a.id;
    INSERT INTO score_historial (animal_id, score, produccion, peso) VALUES (a.id, new_score, a.produccion, a.peso);
  END LOOP;
END;
$$;
