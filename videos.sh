#!/bin/bash

formats=('mp4' 'mkv' 'avi' 'mov' 'flv')
filtered_videos=()

for format in "${formats[@]}"; do
    for video in *.$format *.${format^^}; do
        [[ -f "$video" ]] && filtered_videos+=("$video")
    done
done

if [[ ${#filtered_videos[@]} -eq 0 ]]; then
    echo -e "\033[31mВидеофайлы не найдены.\033[0m"
    echo -e "\033[37mТаймер запущен. Закрытие через 30 секунд...\033[0m"
    for ((i=30; i>=0; i--)); do
        printf "\r\033[31mОсталось %d секунд\033[0m " "$i"
        sleep 1
    done
    echo
    exit 0
fi

echo -e "\n\033[37mВыберите видео для нарезки:\033[0m"
for i in "${!filtered_videos[@]}"; do
    printf "\033[32m%d. %s\033[0m\n\n" "$((i + 1))" "${filtered_videos[i]}"
done

read -p "Введите номер видео: " video_index
((video_index--))

if [[ $video_index -lt 0 || $video_index -ge ${#filtered_videos[@]} ]]; then
    echo "Некорректный выбор."
    exit 1
fi

video_file="${filtered_videos[$video_index]}"
video_duration=$(ffprobe -i "$video_file" -show_entries format=duration -v quiet -of csv="p=0" | cut -d. -f1)

if [[ -z "$video_duration" ]]; then
    echo -e "\033[31mОшибка: Не удалось получить длительность видео.\033[0m"
    exit 1
fi

video_hours=$((video_duration / 3600))
video_minutes=$(((video_duration % 3600) / 60))
video_seconds=$((video_duration % 60))

clear
printf "\033[32mДлительность видео: %d ч %d м %d с\033[0m\n\n" "$video_hours" "$video_minutes" "$video_seconds"

read -p $'\033[32mВведите количество частей для нарезки: \033[0m' parts
if ! [[ "$parts" =~ ^[0-9]+$ ]]; then
    echo "Некорректное количество частей."
    exit 1
fi

echo -e "\033[32mВыберите формат для нарезки:\033[0m"
echo "1. mp4"
echo "2. mkv"
echo "3. avi"
echo "4. mov"
echo "5. flv"
read -p $'\033[32mВведите номер формата: \033[0m' format_choice

case $format_choice in
    1) output_format='mp4' ;;
    2) output_format='mkv' ;;
    3) output_format='avi' ;;
    4) output_format='mov' ;;
    5) output_format='flv' ;;
    *) echo "Некорректный выбор формата."; exit 1 ;;
esac

video_name=$(basename "$video_file" .${video_file##*.})
output_dir="video/$video_name"

if [[ -d "$output_dir" ]]; then
    mv "$output_dir" "$output_dir-old-$(date +%Y%m%d-%H%M%S)"
    echo -e "\033[33mПапка '$output_dir' переименована.\033[0m"
fi

mkdir -p "$output_dir"

segment_length=$((video_duration / parts))

ffmpeg -i "$video_file" -c copy -map 0 -segment_time "$segment_length" -f segment -reset_timestamps 1 -segment_start_number 1 "$output_dir/%d.$output_format"

echo -e "\n\033[32mНарезка завершена. Файлы находятся в '$output_dir'.\033[0m"
sleep 3
