#!/bin/bash

# Убедитесь, что вы запускаете скрипт с правами суперпользователя
if [ "$(id -u)" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт с правами суперпользователя"
    exit 1
fi

# Укажите устройство, которое вы хотите расширить (например, /dev/sda)
DEVICE="/dev/sda"
PARTITION="${DEVICE}3"  # Измените на нужный номер раздела, если необходимо

# Проверка наличия parted
if ! command -v parted &> /dev/null; then
    echo "parted не установлен. Установите его и повторите попытку."
    exit 1
fi

# Перепартиционирование с помощью parted
echo "Перепартиционирование $DEVICE..."
parted $DEVICE --script resizepart 3 100% || {
    echo "Ошибка при перепартиционировании. Проверьте устройство и номер раздела."
    exit 1
}

partprobe $DEVICE

# Проверка наличия pvresize
if ! command -v pvresize &> /dev/null; then
    echo "pvresize не установлен. Установите его и повторите попытку."
    exit 1
fi

pvresize $PARTITION || {
    echo "Ошибка при изменении размера физического тома."
    exit 1
}

# Увеличиваем логический том
echo "Увеличиваем логический том..."
if ! lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv; then
    echo "Ошибка при увеличении логического тома."
    exit 1
fi

# Расширяем файловую систему
echo "Расширяем файловую систему..."
if ! resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv; then
    echo "Ошибка при расширении файловой системы."
    exit 1
fi

# Вывод информации о логических томах
echo "Текущие логические тома:"
lvs

echo "Процесс завершен!"
