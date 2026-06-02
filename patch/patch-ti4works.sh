#!/usr/bin/env bash
# =============================================================================
#  patch-ti4works.sh
#  Aplica as configurações da Ti4Works no código-fonte do RustDesk clonado.
#  Execute UMA VEZ, dentro da raiz do repositório clonado.
#
#  Uso:
#    git clone --recurse-submodules https://github.com/rustdesk/rustdesk
#    cd rustdesk
#    bash /caminho/para/patch-ti4works.sh
# =============================================================================

set -euo pipefail

APP_NAME="Suporte Remoto Ti4Works"
SERVER="rustdesk.ti4works.com.br"
PUB_KEY="JSoPnMHqpwmruCKMHBJoxwCY6gx8Fu1AeequQLyW5fA="

CONFIG="libs/hbb_common/src/config.rs"

echo "======================================================"
echo "  Patch Ti4Works para RustDesk"
echo "======================================================"

# ── Verificar que estamos na raiz do repositório ───────────────────────────
if [ ! -f "$CONFIG" ]; then
  echo "❌ Arquivo $CONFIG não encontrado."
  echo "   Execute este script dentro da raiz do repositório rustdesk."
  exit 1
fi

echo "✅ Repositório encontrado."
echo ""

# ── Backup ────────────────────────────────────────────────────────────────
cp "$CONFIG" "${CONFIG}.bak"
echo "📦 Backup salvo em ${CONFIG}.bak"

# ── Detectar OS para compatibilidade do sed ────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED="sed -i ''"
else
  SED="sed -i"
fi

# ── 1. Servidor padrão (rendezvous) ───────────────────────────────────────
echo ""
echo "🔧 [1/4] Configurando servidor: $SERVER"
eval "$SED 's|rs-ny.rustdesk.com|${SERVER}|g' $CONFIG"
eval "$SED 's|rs-sg.rustdesk.com|${SERVER}|g' $CONFIG"

# ── 2. Chave pública ──────────────────────────────────────────────────────
echo "🔧 [2/4] Configurando chave pública"
eval "$SED 's|OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=|${PUB_KEY}|g' $CONFIG"

# ── 3. Nome do app ────────────────────────────────────────────────────────
echo "🔧 [3/4] Configurando nome: $APP_NAME"
eval "$SED 's|\"RustDesk\"|\"${APP_NAME}\"|g' $CONFIG"

# ── 4. Relay server (igual ao rendezvous neste caso) ─────────────────────
echo "🔧 [4/4] Configurando relay server: $SERVER"
# O relay normalmente segue o mesmo host
eval "$SED 's|rs-ny.rustdesk.com:21117|${SERVER}:21117|g' $CONFIG" 2>/dev/null || true

# ── macOS: Info.plist ─────────────────────────────────────────────────────
if [ -f "flutter/macos/Runner/Info.plist" ]; then
  echo ""
  echo "🍎 Atualizando Info.plist (macOS)..."
  /usr/libexec/PlistBuddy -c "Set :CFBundleName '${APP_NAME}'" \
    flutter/macos/Runner/Info.plist 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '${APP_NAME}'" \
    flutter/macos/Runner/Info.plist 2>/dev/null || true
  echo "   ✅ Info.plist atualizado"
fi

# ── Android: strings.xml ──────────────────────────────────────────────────
STRINGS_XML="flutter/android/app/src/main/res/values/strings.xml"
if [ -f "$STRINGS_XML" ]; then
  echo ""
  echo "🤖 Atualizando strings.xml (Android)..."
  eval "$SED 's|<string name=\"app_name\">[^<]*</string>|<string name=\"app_name\">${APP_NAME}</string>|g' $STRINGS_XML"
  echo "   ✅ strings.xml atualizado"
fi

# ── Android: AndroidManifest.xml ──────────────────────────────────────────
MANIFEST="flutter/android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  echo ""
  echo "🤖 Atualizando AndroidManifest.xml (Android)..."
  eval "$SED 's|android:label=\"[^\"]*\"|android:label=\"${APP_NAME}\"|g' $MANIFEST"
  echo "   ✅ AndroidManifest.xml atualizado"
fi

# ── Verificação final ─────────────────────────────────────────────────────
echo ""
echo "======================================================"
echo "  Verificação do patch aplicado:"
echo "======================================================"
grep -n "ti4works\|Ti4Works\|Suporte Remoto" "$CONFIG" | head -10 || true
echo ""
echo "✅ Patch concluído com sucesso!"
echo ""
echo "Próximos passos:"
echo "  Linux/macOS : python3 build.py --flutter"
echo "  Windows     : python build.py --flutter   (em PowerShell)"
echo ""
echo "Ou faça push para o GitHub e deixe o Actions compilar automaticamente."
