#!/bin/bash
# Пересобирает и публикует превью kane-korso-pitomnik-seo на GitHub Pages.
# Источник правды - эта папка (production-пути); скрипт её НЕ меняет.
# Публикуется только временная копия с path-prefix для /kane-korso-pitomnik-seo/.
#
# Использование:
#   1) Сохранить свежий GitHub classic PAT (scope: repo) в /tmp/gh_token.txt
#      (или экспортировать переменную окружения GH_TOKEN перед запуском).
#   2) bash tools/deploy-preview.sh
#
# Токен создаётся на https://github.com/settings/tokens -> Generate new token (classic) -> repo.
# Публикуется на: https://alex-369432.github.io/kane-korso-pitomnik-seo/
set -e

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="/tmp/pages_build"
REPO="Alex-369432/kane-korso-pitomnik-seo"

if [ -n "$GH_TOKEN" ]; then
  TOKEN="$GH_TOKEN"
elif [ -f /tmp/gh_token.txt ]; then
  TOKEN=$(cat /tmp/gh_token.txt)
else
  echo "Нет токена. Сохраните его в /tmp/gh_token.txt или экспортируйте GH_TOKEN." >&2
  exit 1
fi

rm -rf "$BUILD"
git clone -q "https://${TOKEN}@github.com/${REPO}.git" "$BUILD"

# Очищаем в build всё, кроме .git, затем копируем свежее содержимое SRC
# (без .git, без служебной папки tools/ и без временных скриншотов из чата)
find "$BUILD" -mindepth 1 -maxdepth 1 -not -name ".git" -exec rm -rf {} +
tar -C "$SRC" --exclude=".git" --exclude="tools" --exclude="photo_*_y.jpg" --exclude="photo_*_w.jpg" -cf - . | tar -C "$BUILD" -xf -

cd "$BUILD"
find . -name "*.html" -exec sed -i -E 's#(href|src)="/([^"h])#\1="/kane-korso-pitomnik-seo/\2#g' {} \;
find . -name "*.html" -exec sed -i -E 's#href="/"#href="/kane-korso-pitomnik-seo/"#g' {} \;

# Кэш-бастинг: чтобы браузеры (особенно мобильные) не показывали старый CSS/JS после обновления
V=$(date '+%s')
find . -name "*.html" -exec sed -i -E "s#(style\.css|main\.js)\"#\1?v=${V}\"#g" {} \;

git add -A
if git diff --cached --quiet; then
  echo "Нет изменений для публикации."
  exit 0
fi
git -c user.email="preview@local" -c user.name="Site Preview" commit -q -m "Обновление превью $(date '+%Y-%m-%d %H:%M')"
git push -q origin main
echo "Опубликовано: https://alex-369432.github.io/kane-korso-pitomnik-seo/"
