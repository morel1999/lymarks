# Pousse les secrets de api/.dev.vars vers les GitHub Secrets du depot, pour
# que la CI (.github/workflows/api.yml) puisse migrer, deployer et configurer
# les Workers Secrets. Ne lit que ce fichier, n'affiche aucune valeur.
#
#   powershell -File scripts/push-secrets.ps1            # depuis api/
#   powershell -File scripts/push-secrets.ps1 -DryRun    # liste les noms seulement
#
# Prerequis : gh CLI authentifie (gh auth status), droits admin sur le depot.

param(
  [string]$File = (Join-Path $PSScriptRoot "..\.dev.vars"),
  [string]$Repo = "morel1999/lymarks",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# PowerShell 5.1 : si $OutputEncoding est l'UTF-8 « avec preambule » (herite de
# certaines consoles), le pipe vers un executable natif emet un BOM (U+FEFF)
# en tete de chaque secret — invisible, et fatal pour wrangler. On impose
# l'UTF-8 sans preambule avant tout pipe vers gh.
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $File)) {
  Write-Error "Fichier introuvable : $File"
}

# Cles qui vont en CI. CLOUDFLARE_* ne sont pas dans .dev.vars (elles servent
# a wrangler, pas au Worker) : on les demande a part si absentes.
$wanted = @(
  "DATABASE_URL", "CLERK_PUBLISHABLE_KEY", "CLERK_SECRET_KEY",
  "GROQ_API_KEY", "GEMINI_API_KEY",
  "REVENUECAT_WEBHOOK_SECRET", "REVENUECAT_API_KEY",
  "CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID"
)

$values = @{}
foreach ($raw in Get-Content -Path $File -Encoding UTF8) {
  $line = $raw.Trim()
  if (-not $line -or $line.StartsWith("#")) { continue }
  $eq = $line.IndexOf("=")
  if ($eq -lt 1) { continue }
  $name = $line.Substring(0, $eq).Trim()
  $value = $line.Substring($eq + 1).Trim().Trim('"').Trim("'").TrimStart([char]0xFEFF)
  if ($wanted -contains $name) { $values[$name] = $value }
}

# Pas de pipe vers gh : sous une console en code page UTF-8, PowerShell 5.1
# prefixe l'entree standard d'un executable natif d'un BOM (U+FEFF), quel que
# soit $OutputEncoding — invisible, et wrangler refuse ensuite l'Account ID.
# On ecrit un dotenv temporaire (UTF-8 sans preambule, valeurs entre guillemets)
# que `gh secret set -f` lit directement, puis on l'efface.
$selected = @()
$skipped = @()
foreach ($name in $wanted) {
  $value = $values[$name]
  # Une valeur laissee au placeholder (pk_test_, gsk_, AIza, postgresql://) ne vaut rien.
  if (($null -eq $value) -or ($value.Length -lt 12)) { $skipped += $name; continue }
  if ($value -match '[\r\n"\\]') { Write-Error "$name contient un caractere interdit (retour a la ligne, guillemet ou antislash)" }
  $selected += $name
  if ($DryRun) { Write-Host "[dry-run] $name ($($value.Length) caracteres)" }
}

$pushed = 0
if (-not $DryRun -and $selected.Count -gt 0) {
  $tmp = Join-Path $env:TEMP ("lymarks-secrets-" + [guid]::NewGuid().ToString("N") + ".env")
  try {
    $body = ($selected | ForEach-Object { '{0}="{1}"' -f $_, $values[$_] }) -join "`n"
    [IO.File]::WriteAllText($tmp, $body + "`n", (New-Object System.Text.UTF8Encoding($false)))
    gh secret set --repo $Repo -f $tmp
    if ($LASTEXITCODE -ne 0) { Write-Error "gh secret set -f a echoue" }
    $pushed = $selected.Count
    $selected | ForEach-Object { Write-Host "+ $_" }
  } finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
  }
}

Write-Host ""
Write-Host "$pushed secret(s) pousse(s) vers $Repo."
if ($skipped.Count -gt 0) {
  Write-Host "Non renseignes (placeholder ou absents) : $($skipped -join ', ')"
}
