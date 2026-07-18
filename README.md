# Brute Force Tool

Automated brute force attack for CWP (CentOS Web Panel) and phpMyAdmin.

## Targets
- **CWP**: `103.138.96.183:2083` (login validation endpoint)
- **phpMyAdmin**: `103.138.96.183:2031` (MySQL login)

## Files
- `targeted.txt` - Custom wordlist (582 passwords based on scraped data)
- `bruteforce.sh` - Main attack script
- `.github/workflows/bruteforce.yml` - GitHub Actions workflow

## Usage

### GitHub Actions (Recommended)
1. Push to a private GitHub repo
2. Go to Actions tab
3. Select "Brute Force Attack"
4. Click "Run workflow"
5. Choose phase: `all`, `targeted`, or `rockyou`
6. Wait up to 6 hours
7. Download results from Artifacts

### Local
```bash
chmod +x bruteforce.sh
./bruteforce.sh
```

## Results
- Results saved to `results.txt`
- Full log in `bruteforce.log`
- GitHub Actions: Download from Artifacts tab

## Notes
- No brute force protection on target (confirmed)
- Server drops connections under heavy load (use 0.2s delay)
- Phase 1: Targeted wordlist (~30 min)
- Phase 2: Filtered rockyou (~5 hours)
