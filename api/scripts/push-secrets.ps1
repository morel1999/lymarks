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

$pushed = 0
$skipped = @()
foreach ($name in $wanted) {
  $value = $values[$name]
  # Une valeur laissee au placeholder (pk_test_, gsk_, AIza, postgresql://) ne vaut rien.
  $placeholder = ($null -eq $value) -or ($value.Length -lt 12)
  if ($placeholder) { $skipped += $name; continue }
  if ($DryRun) { Write-Host "[dry-run] $name ($($value.Length) caracteres)"; continue }
  $value | gh secret set $name --repo $Repo
  if ($LASTEXITCODE -ne 0) { Write-Error "gh secret set $name a echoue" }
  Write-Host "+ $name"
  $pushed += 1
}

Write-Host ""
Write-Host "$pushed secret(s) pousse(s) vers $Repo."
if ($skipped.Count -gt 0) {
  Write-Host "Non renseignes (placeholder ou absents) : $($skipped -join ', ')"
}
