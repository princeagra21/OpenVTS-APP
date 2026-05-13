from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / 'tools' / 'architecture_guard.py'


def test_guard_reports_metrics_and_allowlist():
    text = GUARD.read_text(encoding='utf-8')
    assert 'Architecture guard metrics:' in text
    assert 'migration_allowlist_files' in text
    assert 'repository_provider_bridge_imports' in text
    assert 'Possible sensitive logging pattern' in text
