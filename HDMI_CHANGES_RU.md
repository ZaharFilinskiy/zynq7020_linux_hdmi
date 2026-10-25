> История предыдущего этапа. Текущая версия от 25.10.2026 выводит Linux через PS/DDR/VDMA; см. HDMI_LINUX_RU.md.

> Актуальная аппаратная конфигурация изменена 12.10.2026: см. HDMI_REFERENCE_UPDATE_RU.md. Ниже — история предыдущего этапа; прежние распиновка и параметры Linux не подходят к новой сборке.

# HDMI для zynq_linux — изменения и порядок запуска

> Обновление 12.10.2026: текущий проект переключён на автономную тестовую
> картинку, загружаемую через Vivado без SDK/Linux. Актуальная инструкция —
> `HDMI_VIVADO_TEST_RU.md`. Ниже сохранено описание предыдущего DDR/FSBL-этапа;
> оно не является инструкцией запуска текущего тестового режима.

Дата: 03.10.2026. Инструменты: Vivado 2018.3 и Xilinx SDK 2018.3.
Микросхема исходного проекта: **xc7z020clg400-2**.

## Что реализовано и что ещё нужно проверить

Добавлен аппаратный вывод 640×480, 60 Гц через HDMI-разъём, с чтением
32-битного framebuffer из DDR. Все части видеотракта находятся в
`design_1.bd`. Подготовлены FSBL, диагностическое приложение, Device Tree
fragment, настройки ядра и утилита проверки framebuffer.

**Изображение на реальном мониторе пока не проверено.** Нет восстановленной
Buildroot-сборки, конкретного ядра, исходного DTS и U-Boot. Поэтому нельзя
утверждать, что Linux уже загрузился на HDMI. Файлы Linux в этом проекте —
подготовленная интеграция, которую нужно включить в фактическую сборку.
Проверки инструментами записаны отдельно в `hdmi/VALIDATION_RU.md`.

## Почему выбрана именно эта распиновка

Пользователь подтвердил работу **Lab10_FPGA_hdmi_ip** на своей плате.
Использованы его XDC и подтверждающий отчёт `hdmi_top_io_placed.rpt`.

| Сигнал | P | N |
|---|---|---|
| TMDS clock | U18 | U19 |
| TMDS data 0 / blue | V20 | W20 |
| TMDS data 1 / green | T20 | U20 |
| TMDS data 2 / red | N20 | P20 |

Стандарт выходов — TMDS_33, банк 34. Предоставленная схема
`ZYNQ_MINI_REVB Schematic.pdf` и `hdmi_zynq_copy` имеют другую разводку.
Они **не смешиваются** с работавшим Lab10. Отдельные OUT_EN/HPD/DDC не
добавлены: их подключения для платы с распиновкой Lab10 не подтверждены.
Параметры PS, DDR, Ethernet, SD, UART и прежний GPIO T12 сохранены;
в PS дополнительно включён AXI HP0 для чтения DDR видеоконтроллером.

## Архитектура

```text
ARM / Linux writes XRGB8888 pixels to DDR 0x18000000
                         |
DDR -> PS S_AXI_HP0 <- hdmi_mem <- hdmi_vdma (MM2S, all clocks 100 MHz)
                                      |
                                AXI4-Stream Video
                                      |
                             hdmi_stream_cdc (100 -> 25.2 MHz)
                                      |
                             hdmi_video (axis_hdmi_video.v)
                                      |
                              RGB + DE + HSync + VSync
                                      |
                             hdmi_tx (Digilent rgb2dvi)
                                      |
                                 TMDS / HDMI connector

PS M_AXI_GP0 -> ps7_0_axi_periph -> old AXI GPIO @ 0x41200000
                               -> hdmi_vdma control @ 0x43000000
PS FCLK0 100 MHz -> hdmi_clocks -> pixel 25.2 MHz + serial 126 MHz
```

- `hdmi_vdma`: AXI VDMA 6.3, только MM2S, без SG, один frame store,
  64-битное чтение DDR и 32-битный поток. Строковый буфер 4096,
  пакет чтения до 16 beats. Доступ к DDR через HP0.
- `hdmi_stream_cdc`: штатный AXIS Clock Converter 1.1 с раздельными
  синхронными сбросами для 100 и 25,2 МГц. VDMA работает целиком на 100 МГц.
- `hdmi_video`: собственный Verilog Module Reference. Каждый beat —
  `0x00RRGGBB`; `TUSER` у первого пикселя кадра, `TLAST` у последнего
  пикселя строки. Счётчики задают физический растр независимо от DMA.
- `hdmi_tx`: BSD-licensed Digilent rgb2dvi 1.4 из Lab10 с сохранёнными
  заголовками лицензии. Выдаёт DVI-совместимый TMDS через HDMI-разъём.
  Звук, HDCP, EDID и автоматическое переключение видеорежимов не реализованы.
- В rgb2dvi порядок байтов **R,B,G**, поэтому собственный блок переставляет
  G/B перед передатчиком. В DDR и Linux остаётся обычный XRGB8888.

Параметры растра: 640/16/96/48 по горизонтали, 480/10/2/33 по вертикали,
отрицательные HSync/VSync. 800×525×60 = 25 200 000 пиксельных тактов/с.
Пропуск данных окрашивает остаток кадра в чёрный; следующая граница SOF
удерживается до нового экранного кадра. Это предотвращает сдвиг картинки.
Флаг `stream_error` можно подключить к ILA; до запуска VDMA он ожидаемо
установлен. Сам растр и синхронизация монитора не останавливаются.

## Карта памяти и загрузка

| Объект | Адрес / размер |
|---|---|
| Регистры VDMA | 0x43000000, окно 64 КиБ |
| Начало framebuffer | 0x18000000 (384 МиБ от начала DDR) |
| Строка | 2560 байт |
| Изображение | 640×480×4 = 0x12c000 байт |
| Зарезервированная область DDR | 0x18000000–0x181fffff, 2 МиБ |

FSBL сначала штатно настраивает PS/DDR и загружает bitstream.
В `FsblHookBeforeHandoff`, после освобождения сбросов PS/PL и level shifters,
вызывается `HdmiDisplayInit`. Она заполняет DDR цветными полосами,
сбрасывает VDMA, программирует адрес/stride/HSIZE и последним — VSIZE.
VDMA остаётся работать после передачи управления U-Boot и Linux.
Linux simplefb использует уже работающий дисплей и пишет в этот же буфер.

Кэш CPU сбрасывается в DDR перед запуском DMA; HP0 не является когерентным
с D-cache. Для пользовательских программ использовать `/dev/fb0`/mmap,
а не обычный кэшируемый указатель на физический адрес.
При ошибке инициализации FSBL сообщает о ней в UART и продолжает загрузку.
Это не защита от произвольного чужого bitstream: FSBL и bitstream должны
быть из одного комплекта, иначе AXI-доступ по неверному адресу может зависнуть.

## Файлы

| Путь относительно проекта | Назначение |
|---|---|
| `zynq_linux.xpr` | Проект Vivado с дополненным `design_1.bd` |
| `hdmi/rtl/axis_hdmi_video.v` | Потоковый приёмник и генератор растра |
| `hdmi/constraints/hdmi_lab10.xdc` | Подтверждённые HDMI-пины |
| `hdmi/ip_repo/` | rgb2dvi и описания интерфейсов из Lab10 |
| `hdmi/tcl/add_hdmi.tcl` | Добавление HDMI к чистому исходному проекту, один раз |
| `hdmi/tcl/design_1_hdmi_generated.tcl` | Полный экспорт Block Design |
| `hdmi/tcl/build.tcl` | Сборка bitstream/HDF, проверка timing |
| `hdmi/tcl/build_sdk.tcl` | Создание/обновление отдельного SDK workspace |
| `hdmi/hdmi_display.c`, `.h` | Настройка framebuffer и VDMA в FSBL |
| `hdmi/sdk_workspace/` | Новые hardware platform, BSP, FSBL и тест |
| `hdmi/export/` | Bitstream, HDF, ELF, диагностический BOOT и отчёты |
| `hdmi/tests/` | Тест видеоблока и standalone smoke test |
| `hdmi/linux/` | DTSI, фрагмент kernel config, диагностические программы |

Старый `zynq_linux.sdk` сохранён для истории. Для нового железа использовать
**`hdmi/sdk_workspace`**, иначе SDK возьмёт прежний HDF/FSBL без HDMI.
Источники `hdmi_display.c/.h` редактировать в `hdmi/`; build_sdk.tcl
копирует их в SDK-проект перед сборкой. Изменение копии только в workspace
будет перезаписано этим скриптом.

## Быстрая проверка платы без Linux

1. Сохранить существующий BOOT.BIN с SD-карты.
2. Взять `hdmi/export/BOOT_HDMI_TEST.bin` и положить на загрузочный FAT-раздел
   карты под именем `BOOT.BIN`. Это отдельный тест, Linux в нём нет.
3. Подключить монитор, выбрать SD boot как в прежнем рабочем проекте,
   подключить прежний UART и перезапустить питание платы.
4. Ожидаются восемь вертикальных полос: белая, жёлтая, голубая, зелёная,
   пурпурная, красная, синяя, чёрная. UART должен напечатать
   `HDMI: 640x480p60...` и `HDMI smoke test...`.
5. После проверки вернуть исходный BOOT.BIN либо новый комплект Linux.

## Подключение к восстановленному Buildroot

1. Восстановить **свою** плату/defconfig: стандартный ZedBoard DTS не заменяет
   настройки DDR, Ethernet PHY и SD конкретной платы. Новый HDF находится
   в `hdmi/export/design_1_wrapper.hdf`.
2. Сгенерировать/обновить аппаратный Device Tree привычным способом.
   Включить `hdmi/linux/hdmi-simplefb.dtsi` после основного DTS:
   `/include/ "hdmi-simplefb.dtsi"`.
   В Zynq DTS должна существовать метка `clkc`; при другом имени адаптировать
   phandle. Индекс 15 — FCLK0. Сохранить память 512 МиБ и настройки платы.
3. Если генератор создал узел VDMA по адресу 0x43000000, установить в нём
   `status = "disabled"`. Он принадлежит FSBL/simplefb: обычный Linux DMA
   driver не должен одновременно сбрасывать/перепрограммировать этот блок.
   Сам `simple-framebuffer` должен иметь `status = "okay"`.
4. Включить параметры из `hdmi/linux/linux-hdmi.config` в фактическом ядре.
   Проверить результат `olddefconfig`: `CONFIG_FB_SIMPLE=y`,
   `CONFIG_FRAMEBUFFER_CONSOLE=y`, `CONFIG_VT=y`, `CONFIG_VT_CONSOLE=y`.
   На новых ядрах для этого варианта отключить `CONFIG_DRM_SIMPLEDRM`.
   При наличии `CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER` добавить
   `fbcon=nodefer` для немедленного появления консоли.
5. В рабочие bootargs **добавить**, не удаляя root/serial/network:
   `console=tty0 fbcon=map:0`. Прежний serial console сохранить последним,
   например `console=tty0 console=ttyPS0,115200 fbcon=map:0`.
   Имя ttyPS и скорость взять из существующей загрузки, не угадывать.
   Сообщения до инициализации framebuffer продолжат идти только в UART.
6. Для приглашения входа на мониторе нужен getty на tty1, например строка
   BusyBox inittab: `tty1::respawn:/sbin/getty 0 tty1`. Для ввода нужна клавиатура
   и рабочая поддержка её интерфейса; наличие видеовыхода этого не обеспечивает.
7. Собрать ядро/DTB/rootfs. Скомпоновать BOOT.BIN из **нового** FSBL,
   **нового** bitstream и своего U-Boot ELF по
   `hdmi/linux/boot-hdmi.bif.example`. Пример для SDK Bootgen:
   `bootgen -arch zynq -image boot-hdmi.bif -o BOOT.BIN -w on`.
   Пример содержит `u-boot.elf`, которого в предоставленной папке нет.
8. Убедиться, что U-Boot не меняет FCLK0 с 100 МГц, не сбрасывает PL,
   не загружает старый bitstream и не пишет ядро/initrd/DTB/heap в
   0x18000000–0x181fffff. Linux reserved-memory защищает эту область
   после старта ядра; поведение конкретной версии U-Boot проверяется отдельно.
9. Загрузить и выполнить `sh check-hdmi.sh` из `hdmi/linux`.
   Должен появиться framebuffer в `/proc/fb` и `/dev/fb0`.
   Цветные полосы до ядра и отсутствие консоли после него означают,
   что нужно проверять DTS/config/bootargs/сохранение FCLK и PL.

Утилиту `fb_test.c` собирать **своим Buildroot-компилятором**, чтобы совпала libc:
`$CC -O2 -Wall -Wextra fb_test.c -o fb_test`; на плате `./fb_test /dev/fb0`.
Она проверяет формат и рисует полосы через штатный framebuffer API.
Графический рабочий стол сам по себе не появляется: для него нужен
userspace с соответствующим framebuffer backend; здесь обеспечивается
базовая консоль и доступ к пикселям.

## Повторная сборка

Из корня проекта, PowerShell:

```powershell
& C:/Xilinx/Vivado/2018.3/bin/vivado.bat -mode batch -source hdmi/tcl/build.tcl
& C:/Xilinx/SDK/2018.3/bin/xsct.bat hdmi/tcl/build_sdk.tcl
& C:/Xilinx/Vivado/2018.3/bin/vivado.bat -mode batch -source hdmi/tcl/test_video.tcl
Push-Location hdmi/export
& C:/Xilinx/SDK/2018.3/bin/bootgen.bat -arch zynq -image boot-hdmi-test.bif -o BOOT_HDMI_TEST.bin -w on
Pop-Location
```

Для SDK можно открыть `hdmi/sdk_workspace`. При переносе на другой компьютер
лучше создать workspace заново скриптом, а не переносить Eclipse `.metadata`.
`add_hdmi.tcl` не запускать на уже дополненном проекте.

## Дальнейшее подключение камеры

Предусмотрен стандартный AXI4-Stream Video. Для камеры, которая не может
останавливаться по TREADY, потребуется буферизация: камера -> S2MM -> DDR ->
MM2S -> текущий видеовыход. Добавляются согласование форматов, размеров,
скорости кадров и переключение двух/трёх буферов. Текущий один framebuffer
допускает tearing и фиксирует разрешение; это осознанное ограничение первого
этапа. Для полноценного Linux-видеоконвейера следующим этапом нужны V4L2/DRM
и передача владения DMA драйверу вместо firmware simplefb.

## Использованные материалы

- Локальный Lab10: top_pin.xdc, отчёт размещения, Digilent rgb2dvi 1.4.
- [AXI VDMA: последовательность программирования, PG020](https://docs.amd.com/r/en-US/pg020_axi_vdma/Programming-Sequence).
- [Регистры VDMA в SDK 2018.3](https://raw.githubusercontent.com/Xilinx/embeddedsw/xilinx-v2018.3/XilinxProcessorIPLib/drivers/axivdma/src/xaxivdma_hw.h).
- [Linux simple-framebuffer binding](https://kernel.googlesource.com/pub/scm/linux/kernel/git/next/linux-next/+/refs/heads/akpm-base/Documentation/devicetree/bindings/display/simple-framebuffer.yaml).
- [Linux 4.19 simplefb driver](https://raw.githubusercontent.com/torvalds/linux/v4.19/drivers/video/fbdev/simplefb.c).

