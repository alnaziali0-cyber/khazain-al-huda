import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MOBILE = ROOT / "apps" / "mobile"


USER_FACING_CONTENT_FILES = (
    MOBILE / "lib/features/content/empty_text_section_screen.dart",
    MOBILE / "lib/features/content/events_screen.dart",
    MOBILE / "lib/features/content/imams_screen.dart",
    MOBILE / "lib/features/content/ahl_al_bayt_content_screen.dart",
    MOBILE / "lib/features/content/content_screen.dart",
    MOBILE / "lib/features/content/quran_library_screen.dart",
    MOBILE / "lib/features/content/quran_text_reader_screen.dart",
    MOBILE / "lib/features/radio/audio_library_screen.dart",
    MOBILE / "lib/features/radio/radio_screen.dart",
    MOBILE / "lib/features/settings/source_catalog_screen.dart",
)


def test_content_and_audio_screens_do_not_launch_external_websites():
    for path in USER_FACING_CONTENT_FILES:
        source = path.read_text(encoding="utf-8")
        assert "launchUrl" not in source, path


def test_audio_playback_and_download_are_gated_by_public_rights_catalogue():
    reader = (
        MOBILE / "lib/features/content/quran_text_reader_screen.dart"
    ).read_text(encoding="utf-8")
    audio_screen = (
        MOBILE / "lib/features/radio/audio_library_screen.dart"
    ).read_text(encoding="utf-8")
    radio = (MOBILE / "lib/features/radio/radio_screen.dart").read_text(
        encoding="utf-8"
    )
    playback = (MOBILE / "lib/core/audio_playback_service.dart").read_text(
        encoding="utf-8"
    )
    pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")

    assert "audio_service: ^0.18.19" in pubspec
    assert "class KhazainAudioHandler extends BaseAudioHandler" in playback
    assert "appAudioPlaybackProvider" in audio_screen
    assert "appAudioPlaybackProvider" in reader
    assert "/api/v1/public/catalog/audio" in reader
    assert "playLocal(" in reader
    assert "AudioSource.file" in playback
    assert "uri.scheme != 'https'" in playback
    assert "streaming" not in reader.lower() or "rights" in reader.lower()
    assert "/api/v1/public/catalog/audio" in audio_screen
    assert "can_download" in audio_screen
    assert "download_url" in audio_screen
    assert "licensed_audio" in audio_screen
    assert "Uri.tryParse(url)?.scheme != 'https'" in audio_screen
    assert "AudioPlayer" not in radio
    assert "stream_url" not in radio


def test_quran_audio_index_lists_all_114_surahs_without_fabricating_recordings():
    manifest = json.loads(
        (MOBILE / "assets/data/quran/audio_surahs_manifest.json").read_text(encoding="utf-8")
    )
    assert manifest["total_surahs"] == 114
    assert len(manifest["items"]) == 114
    assert all(item["audio_status"] == "awaiting_verified_recording" for item in manifest["items"])


def test_external_audio_catalog_is_not_packaged_as_a_flutter_asset():
    pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
    assert "assets/data/catalogs/" not in pubspec


def test_api_content_and_source_text_is_sanitized_before_display():
    content_screen = (
        MOBILE / "lib/features/content/content_screen.dart"
    ).read_text(encoding="utf-8")
    source_screen = (
        MOBILE / "lib/features/settings/source_catalog_screen.dart"
    ).read_text(encoding="utf-8")

    assert "safeDisplayText(" in content_screen
    assert "safeDisplayText(" in source_screen


def test_support_links_and_prayer_api_connection_remain_intact():
    support = (MOBILE / "lib/features/settings/support_sheet.dart").read_text(
        encoding="utf-8"
    )
    prayer = (MOBILE / "lib/core/misr_quran_prayer_times.dart").read_text(
        encoding="utf-8"
    )

    assert "launchUrl" in support
    assert "api.misrquran.gov.eg" in prayer


def test_licensed_text_sections_are_packaged_locally_without_pdf_or_external_readers():
    visits = (
        MOBILE / "lib/features/content/ziyara_library_screen.dart"
    ).read_text(encoding="utf-8")
    local_reader = (
        MOBILE / "lib/features/content/local_text_library.dart"
    ).read_text(encoding="utf-8")
    pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
    router = (MOBILE / "lib/app/router.dart").read_text(encoding="utf-8")
    content = (
        MOBILE / "lib/features/content/content_screen.dart"
    ).read_text(encoding="utf-8")

    assert "PdfViewer" not in visits
    assert "launchUrl" not in visits
    assert "https://" not in visits
    assert "assets/data/library/" in pubspec
    assert (MOBILE / "assets/data/library/index.json").exists()
    assert "ZiyaraVolumeTextScreen" in router
    assert "LocalTextReaderScreen" in router
    assert "LocalTextLibraryScreen" in content
    assert "rootBundle.loadString" in local_reader
    assert "assets/data/library/" in local_reader


def test_local_library_has_licensed_text_in_every_added_section_and_no_quran_or_pdf():
    library = MOBILE / "assets/data/library"
    index = json.loads((library / "index.json").read_text(encoding="utf-8"))
    entries = index["items"]
    expected = {"book", "hadith", "dua", "visit", "ethics", "story"}
    counts = {category: 0 for category in expected}

    assert index["quran_included"] is False
    assert len(entries) >= 60
    for item in entries:
        category = item["category"]
        counts[category] += 1
        assert item["license_id"] in {"CC-BY-4.0", "CC-BY-SA-4.0"}
        assert item["format"] == "txt"
        assert item["offline"] is True
        assert item["content_file"].endswith(".txt")
        body_path = library / item["content_file"]
        assert body_path.exists(), item["id"]
        body = body_path.read_text(encoding="utf-8")
        assert body.strip(), item["id"]
        assert item["sha256"]
        if item["license_id"] == "CC-BY-SA-4.0":
            assert item["source_url"].startswith("https://ar.wikisource.org/")
            assert "ويكي مصدر" in item["attribution"]

    assert set(counts) == expected
    assert all(count > 0 for count in counts.values()), counts
    assert not list(library.rglob("*.pdf"))
    assert (library / "LICENSES_AR.md").exists()
    assert (library / "CATALOG_AR.md").exists()


def test_new_offline_prayer_and_hijri_assets_are_packaged_without_external_links():
    pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
    data = MOBILE / "assets/data"
    assert "assets/data/prayer_times/" in pubspec
    assert "assets/data/shia_occasions_hijri.json" in pubspec
    assert "assets/data/ahl_al_bayt_biographies.json" in pubspec
    assert len(list((data / "prayer_times").glob("*.csv"))) == 18
    occasions = json.loads((data / "shia_occasions_hijri.json").read_text(encoding="utf-8"))
    biographies = json.loads((data / "ahl_al_bayt_biographies.json").read_text(encoding="utf-8"))
    assert len(occasions) >= 1
    assert len(biographies) >= 1
    assert "http://" not in json.dumps(occasions, ensure_ascii=False)
    assert "https://" not in json.dumps(occasions, ensure_ascii=False)
    assert "http://" not in json.dumps(biographies, ensure_ascii=False)
    assert "https://" not in json.dumps(biographies, ensure_ascii=False)


def test_iraqi_prayer_tables_cover_each_city_for_the_full_published_range():
    schedule_dir = MOBILE / "assets/data/prayer_times"
    files = sorted(schedule_dir.glob("*.csv"))
    assert len(files) == 18
    total_records = 0
    expected_columns = [
        "location_id", "date", "hijri_date", "hijri_basis", "city_ar",
        "governorate_ar", "imsak", "fajr", "sunrise", "dhuhr", "asr",
        "sunset", "maghrib", "isha", "midnight",
    ]
    time_fields = ["imsak", "fajr", "sunrise", "dhuhr", "asr", "sunset", "maghrib", "isha", "midnight"]
    for path in files:
        with path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            assert reader.fieldnames == expected_columns
            rows = list(reader)
        total_records += len(rows)
        city_rows = {}
        for row in rows:
            city_rows.setdefault(row["city_ar"], []).append(row)
            for key in time_fields:
                assert re.fullmatch(r"(?:[01]\d|2[0-3]):[0-5]\d", row[key]), (path.name, row)
        for city, records in city_rows.items():
            dates = [record["date"] for record in records]
            assert len(records) == 730, (path.name, city, len(records))
            assert dates[0] == "2026-01-01" and dates[-1] == "2027-12-31"
            assert len(set(dates)) == 730
    assert total_records == 119720
