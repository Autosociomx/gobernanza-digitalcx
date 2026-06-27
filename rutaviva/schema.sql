-- RutaViva · Supabase schema
-- Ejecuta esto en tu proyecto de Supabase → SQL Editor

-- Tabla de posiciones en tiempo real
CREATE TABLE IF NOT EXISTS public.bus_positions (
  bus_id      text PRIMARY KEY,
  route_name  text NOT NULL,
  lat         float8 NOT NULL,
  lng         float8 NOT NULL,
  speed       int4 DEFAULT 0,
  updated_at  timestamptz DEFAULT now()
);

-- Seguridad a nivel de fila (demo: lectura y escritura públicas)
ALTER TABLE public.bus_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura pública"
  ON public.bus_positions FOR SELECT USING (true);

CREATE POLICY "Escritura pública"
  ON public.bus_positions FOR ALL USING (true) WITH CHECK (true);

-- Activar Realtime para la tabla
ALTER PUBLICATION supabase_realtime ADD TABLE public.bus_positions;

-- Limpieza automática: elimina posiciones de más de 2 horas
CREATE OR REPLACE FUNCTION public.clean_stale_buses()
RETURNS void LANGUAGE sql AS $$
  DELETE FROM public.bus_positions
  WHERE updated_at < now() - interval '2 hours';
$$;
