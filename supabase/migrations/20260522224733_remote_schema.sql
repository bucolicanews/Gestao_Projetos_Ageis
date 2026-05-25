drop extension if exists "pg_net";

alter table "public"."convites_projeto" alter column "token" set default replace((gen_random_uuid())::text, '-'::text, ''::text);

alter table "public"."papeis_usuario" enable row level security;

alter table "public"."perfis" enable row level security;


