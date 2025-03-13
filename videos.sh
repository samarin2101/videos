#!/bin/bash

# Делаем скрипт исполняемым
chmod +x "$0"

# Открытие терминала в зависимости от рабочего окружения
case "$XDG_CURRENT_DESKTOP" in
    "GNOME" | "Cinnamon") terminal="gnome-terminal --" ;;
    "KDE") terminal="konsole -e" ;;  # Используем -e для исполнения
    "XFCE") terminal="xfce4-terminal --hold -e" ;;
    "MATE") terminal="mate-terminal --hold -e" ;;
    *) terminal="xterm -hold -e" ;;
esac

# Запуск скрипта в терминале
$terminal bash -c "
    # Проверка на видеофайлы
    formats=('mp4' 'mkv' 'avi' 'mov' 'flv')
    filtered_videos=()

    for format in \"\${formats[@]}\"; do
        for video in *.\$format *.\${format^^}; do
            [[ -f \"\$video\" ]] && filtered_videos+=(\"\$video\")
        done
    done

    if [[ \${#filtered_videos[@]} -eq 0 ]]; then
        printf '\033[31mВидеофайлы не найдены.\033[0m\n'
        printf '\033[37mТаймер запущен. Закрытие через 30 секунд...\033[0m\n'
        for ((i=30; i>=0; i--)); do
            printf '\r\033[31mОсталось %d секунд\033[0m ' \"\$i\"
            sleep 1
        done
        printf '\n'
        exit 0  # Закрытие терминала после окончания
    fi

    video_file=\"\${filtered_videos[0]}\"
    video_duration=\$(ffprobe -i \"\$video_file\" -show_entries format=duration -v quiet -of csv=\"p=0\" | cut -d. -f1)

    if [[ -z \"\$video_duration\" ]]; then
        printf '\033[31mОшибка: Не удалось получить длительность видео.\033[0m\n'
        exit 1
    fi

    video_hours=\$((video_duration / 3600))
    video_minutes=\$(((video_duration % 3600) / 60))
    video_seconds=\$((video_duration % 60))

    clear
    printf '\033[32mДлительность видео: %d ч %d м %d с\033[0m\n' \"\$video_hours\" \"\$video_minutes\" \"\$video_seconds\"
    printf '\n'
    printf '\033[37mВыберите видео для нарезки:\033[0m\n'
    printf '\n'

    for i in \"\${!filtered_videos[@]}\"; do
        printf '\033[32m%d. %s\033[0m\n' \"\$((i + 1))\" \"\${filtered_videos[i]}\"
        printf '\n'
    done

    printf 'Введите номер видео: '
    read -r video_index
    ((video_index--))

    if [[ \$video_index -lt 0 || \$video_index -ge \${#filtered_videos[@]} ]]; then
        printf 'Некорректный выбор.\n'
        exit 1
    fi

    video_file=\"\${filtered_videos[\$video_index]}\"

    clear
    printf '\033[32mВведите количество частей для нарезки: \033[0m'
    read -r parts

    if ! [[ \"\$parts\" =~ ^[0-9]+$ ]]; then
        printf 'Некорректное количество частей.\n'
        exit 1
    fi

    clear
    printf '\033[32mВыберите формат для нарезки:\033[0m\n'
    printf '1. mp4\n'
    printf '2. mkv\n'
    printf '3. avi\n'
    printf '4. mov\n'
    printf '5. flv\n'
    printf '\033[32mВведите номер формата: \033[0m'
    read -r format_choice

    case \$format_choice in
        1) output_format='mp4' ;;
        2) output_format='mkv' ;;
        3) output_format='avi' ;;
        4) output_format='mov' ;;
        5) output_format='flv' ;;
        *) printf 'Некорректный выбор формата.\n'; exit 1 ;;
    esac

    video_name=\$(basename \"\$video_file\" .\${video_file##*.})
    output_dir=\"videos/\$video_name\"
    mkdir -p \"\$output_dir\"

    ffmpeg -i \"\$video_file\" -c copy -map 0 -segment_time \"\$((video_duration / parts))\" -f segment -reset_timestamps 1 -segment_start_number 1 \"\$output_dir/%d.\$output_format\"

    printf 'Нарезка завершена.\n'
    sleep 3  # Задержка в 3 секунды перед закрытием терминала
    exit 0  # Закрытие терминала после выполнения скрипта
"
