-- Data contoh untuk uji coba (opsional). Semua nama dan nomor fiktif.
-- Dipasang dengan: sudo bash install-postgres.sh --with-sample
SET search_path = layanan, public;

INSERT INTO pemohon (id, nik, full_name, holder_did) VALUES
  (1042, '0000000000000001', 'User Uji', 'did:key:holder-1042')
ON CONFLICT (nik) DO NOTHING;

INSERT INTO pengajuan_skck (id, pemohon_id, registration_number, status, submitted_at, purpose, print_location, classification, application_path)
VALUES ('01K7QDR1B8NFD6ZF886SNS9D44', 1042, 'SKCK-TEST-1', 'completed', '2026-11-23T02:00:00Z', 'Pekerjaan', 'Polres Contoh', 'DALAM NEGERI', '/skck/tes-final.pdf')
ON CONFLICT (id) DO NOTHING;

INSERT INTO pengajuan_izin_keramaian (id, pemohon_id, registration_number, status, submitted_at, activity_name, activity_type_name, requested_review_date)
VALUES (73, 1042, 'IK-TEST-1', 'schedule_confirmed', '2026-11-23T01:00:00Z', 'Pertemuan warga', 'Pertemuan', '2026-11-26')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('layanan.pengajuan_izin_keramaian','id'), GREATEST(73, (SELECT max(id) FROM pengajuan_izin_keramaian)));
SELECT setval(pg_get_serial_sequence('layanan.pemohon','id'), GREATEST(1042, (SELECT max(id) FROM pemohon)));

INSERT INTO vc_status_list (url) VALUES ('https://polri.go.id/status/skck/1') ON CONFLICT (url) DO NOTHING;
