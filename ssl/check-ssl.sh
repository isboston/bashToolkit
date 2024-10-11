#!/bin/bash

# Список URL для проверки
urls=(
    "https://onliner.by"
    "https://pogoda.by"
    "https://mts.by"
    "https://a1.by"
    "https://habr.com"
)

# Переменные для хранения ближайшего срока и соответствующего URL
earliest_date=""
earliest_url=""

# Проверка каждого URL
for url in "${urls[@]}"; do
    # Получаем дату истечения сертификата
    expiry_date=$(echo | openssl s_client -connect ${url#https://}:443 -servername ${url#https://} 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null)

    # Проверяем, успешно ли получена дата
    if [[ $? -ne 0 ]]; then
        echo "Не удалось получить сертификат для $url"
        continue
    fi

    # Извлекаем дату
    expiry_date=${expiry_date#*=}

    # Преобразуем дату в формат timestamp для сравнения
    expiry_timestamp=$(date -d "$expiry_date" +%s)

    # Если earliest_date пуст, или текущая дата меньше earliest_date, обновляем
    if [[ -z "$earliest_date" || "$expiry_timestamp" -lt "$earliest_date" ]]; then
        earliest_date=$expiry_timestamp
        earliest_url=$url
        earliest_expiry_date=$expiry_date  # Сохраняем дату истечения
    fi
done

# Проверяем, найден ли хотя бы один действующий сертификат
if [[ -n "$earliest_url" ]]; then
    echo "URL с ближайшим сроком истечения сертификата: $earliest_url"
    echo "Дата истечения сертификата: $earliest_expiry_date"
else
    echo "Не удалось получить данные о сертификатах для всех URL"
fi
