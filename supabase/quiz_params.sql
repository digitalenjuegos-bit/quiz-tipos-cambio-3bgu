-- ═══════════════════════════════════════════════════════════════════════
-- Quiz "Tipos de cambio" · 3BGU · Economía
-- Proyecto Supabase: iitjrrnndfxqjzkggtog
--
-- CÓMO USARLO
--   Supabase → SQL Editor → New query → pegar todo → Run
--   Es idempotente: se puede ejecutar varias veces sin romper nada.
--
-- ESTADO VERIFICADO (2026-10-15)
--   quiz_results  → ya existe (compartida con otros quizzes)  HTTP 200
--   quiz_config   → ya existe                                  HTTP 200
--   quiz_params   → NO existe (404 PGRST205)  ← esto es lo que crea este script
-- ═══════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────
-- 1) TABLA DE PARÁMETROS DEL QUIZ (panel docente)
--    exam_id  : identificador del quiz (clave primaria)
--    config   : { totalQuestions, rcCount, ccCount, timePerQuestion }
--    updated_at: última vez que el docente guardó cambios
-- ─────────────────────────────────────────────────────────────────────
create table if not exists public.quiz_params (
  exam_id    text primary key,
  config     jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────
-- 2) SEGURIDAD A NIVEL DE FILA (RLS) + permiso para la clave pública
--    La app usa la clave "publishable" (rol anon). Sin estas políticas
--    el navegador recibe 401/403 y el panel docente no guarda nada.
-- ─────────────────────────────────────────────────────────────────────
alter table public.quiz_params enable row level security;

drop policy if exists quiz_params_anon_all on public.quiz_params;
create policy quiz_params_anon_all on public.quiz_params
  for all
  to anon
  using (true)
  with check (true);

-- ─────────────────────────────────────────────────────────────────────
-- 3) FILA INICIAL DE PARÁMETROS PARA ESTE QUIZ
--    Valores por defecto de la app: 20 preguntas (7 RC + 13 CC), 90 s c/u.
--    Si ya existe, NO se sobrescribe (do nothing).
-- ─────────────────────────────────────────────────────────────────────
insert into public.quiz_params (exam_id, config)
values (
  'tipos-cambio-3bgu',
  '{"totalQuestions":20,"rcCount":7,"ccCount":13,"timePerQuestion":90}'::jsonb
)
on conflict (exam_id) do nothing;

-- ─────────────────────────────────────────────────────────────────────
-- 4) DEJAR EL QUIZ ABIERTO
--    quiz_config ya existe; esta fila asegura que el quiz no aparezca
--    cerrado para los estudiantes.
-- ─────────────────────────────────────────────────────────────────────
insert into public.quiz_config (exam_id, open)
values ('tipos-cambio-3bgu', true)
on conflict (exam_id) do update set open = true;

-- ─────────────────────────────────────────────────────────────────────
-- 5) COMPROBACIÓN (opcional): debe devolver 1 fila con los parámetros
-- ─────────────────────────────────────────────────────────────────────
-- select * from public.quiz_params where exam_id = 'tipos-cambio-3bgu';
