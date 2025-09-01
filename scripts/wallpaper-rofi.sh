#!/bin/bash

# Папка с обоями
DIR="/home/m0nica/wallpapers/"

# Временная директория для превью
CACHE_DIR="/home/m0nica/wallpaper-previews"
mkdir -p "$CACHE_DIR"

# Функция для создания превью
create_preview() {
    local img="$1"
    local filename=$(basename "$img")
    local preview_path="$CACHE_DIR/${filename%.*}_preview.png"
    
    # Создаем превью только если его еще нет
    if [ ! -f "$preview_path" ]; then
        convert "$img" -resize 100x100^ -gravity center -extent 100x100 "$preview_path" 2>/dev/null
    fi
    
    echo "$preview_path"
}

# Подготавливаем список для rofi с иконками
prepare_rofi_list() {
    while IFS= read -r wallpaper; do
        # Получаем имя файла без пути
        name=$(basename "$wallpaper")
        # Создаем превью
        preview=$(create_preview "$wallpaper")
        # Формат для rofi: текст\0icon\x1fпуть_к_иконке
        echo -en "${name}\0icon\x1f${preview}\n"
    done < <(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)
}

# Показываем rofi с превью
SELECTED=$(prepare_rofi_list | rofi \
    -dmenu \
    -i \
    -p "" \
    -theme-str 'listview { columns: 3; }' \
    -theme-str 'element { orientation: vertical; }' \
    -theme-str 'element-icon { size: 100px; }' \
    -theme-str 'element-text { horizontal-align: 0.5; }' \
    -theme-str 'window { width: 50%; }' \
    -show-icons \
    -scroll-method 0 \
    -normalize-match)

# Если ничего не выбрано — выйти
[ -z "$SELECTED" ] && exit

# Получаем полный путь к файлу
WALL="$DIR/$SELECTED"

# Проверяем существование файла
if [ ! -f "$WALL" ]; then
    notify-send "Ошибка" "Файл не найден: $WALL"
    exit 1
fi

# Сгенерировать тему от картинки
matugen image "$WALL" -m dark

# Перезапустить waybar, чтобы он обновил стили
pkill -SIGUSR2 waybar

# Применить обои с анимацией
swww img "$WALL" \
    --transition-type any \
    --transition-fps 165 \

# Создаём симлинк для hyprlock
ln -sf "$WALL" /home/m0nica/.config/hypr/simlink/current.png


# Очистка старых превью (опционально, раскомментируйте если нужно)
# find "$CACHE_DIR" -type f -mtime +7 -delete