-- =============================================================
-- reservations 테이블 RLS 정책
-- Supabase 대시보드 > SQL Editor 에 붙여넣어 실행한다.
--
-- 권한 표 (✅ 하나당 정책 1개)
--   역할               INSERT  SELECT  UPDATE  DELETE
--   anon(참가자)          ✅      ❌      ❌      ❌
--   authenticated(관리)   —       ✅      ✅      ✅
--   ※ ❌ 칸은 "정책을 만들지 않는 것"으로 자동 차단된다.
-- =============================================================

-- -------------------------------------------------------------
-- 0) RLS 활성화
--    이걸 켜야 "정책이 없는 모든 동작이 자동 차단"된다.
--    (RLS가 꺼져 있으면 anon이 전체를 읽을 수 있으니 반드시 켠다.)
-- -------------------------------------------------------------
alter table public.reservations enable row level security;

-- 재실행해도 오류 없도록 기존 동일 정책이 있으면 먼저 지운다
drop policy if exists "anon_insert"          on public.reservations;
drop policy if exists "authenticated_select" on public.reservations;
drop policy if exists "authenticated_update" on public.reservations;
drop policy if exists "authenticated_delete" on public.reservations;

-- -------------------------------------------------------------
-- [✅ 1] anon_insert : 참가자는 예약 신청(INSERT)만 가능
--   with check (status = '대기') 로 상태 위조를 막는다.
--   → 참가자가 status를 '승인'으로 넣어 보내도 이 조건에서 거부된다.
--   (status 컬럼 기본값이 '대기'이므로, 보내지 않으면 자동으로 '대기'가 된다.)
-- -------------------------------------------------------------
create policy "anon_insert"
  on public.reservations
  for insert
  to anon
  with check (status = '대기');

-- -------------------------------------------------------------
-- [✅ 2] authenticated_select : 로그인한 관리자는 전체 예약 조회
-- -------------------------------------------------------------
create policy "authenticated_select"
  on public.reservations
  for select
  to authenticated
  using (true);

-- -------------------------------------------------------------
-- [✅ 3] authenticated_update : 관리자는 승인(상태 변경) 처리
--   with check 로 변경 후 status 값도 허용 범위('대기'/'승인')로 제한한다.
-- -------------------------------------------------------------
create policy "authenticated_update"
  on public.reservations
  for update
  to authenticated
  using (true)
  with check (status in ('대기', '승인'));

-- -------------------------------------------------------------
-- [✅ 4] authenticated_delete : 관리자는 취소/중복 예약 삭제
-- -------------------------------------------------------------
create policy "authenticated_delete"
  on public.reservations
  for delete
  to authenticated
  using (true);

-- -------------------------------------------------------------
-- 확인용) 현재 걸린 정책 목록 보기
-- -------------------------------------------------------------
-- select policyname, cmd, roles
-- from pg_policies
-- where tablename = 'reservations';
