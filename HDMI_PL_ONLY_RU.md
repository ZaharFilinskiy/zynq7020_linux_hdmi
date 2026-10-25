# Автономное тестовое изображение HDMI: ветка pl-hdmi-test

Этот вариант использует только PL. В Block Design нет PS, DDR, AXI VDMA, GPIO управления от ARM и интерфейсов FIXED_IO/DDR. Изображение формируется аппаратно, без Linux, SDK и программ для процессора.

## Происхождение и устройство

RTL источника/развёртки, IP rgb2dvi и ограничения взяты из проверенного архива zynq_linux_PL_HDMI_20261025.zip, SHA256:

`704c9074a8174fc2ee9dd913fca5eddbfb69fda4614db574dd3b4cbaf21fef04`

В архивной версии видеовывод уже был автономным, но в BD ещё оставались неиспользуемые блоки PS/VDMA от общей разработки. В этой ветке создан отдельный минимальный BD:

```
50 MHz K17 -> Clock Wizard -> PixelClk / SerialClk
                                 |
axis_hdmi_source (TEST_PATTERN=1) -> axis_hdmi_video -> rgb2dvi -> HDMI
                                 |
reset_n M20 + MMCM locked -> синхронизация сброса
константа 1 -> HDMI enable H18
```

Входы внешнего AXI-потока источника привязаны к нулю. Они не используются при TEST_PATTERN=1. Генератор и развёртка остались Module Reference в Block Design для дальнейшего расширения.

Картинка: восемь цветных полос, шахматный узор снизу и белая двухпиксельная рамка. Режим 1280x720, около 59.93 Гц; PixelClk/SerialClk 74.166667/370.833333 МГц. Используется та же подтверждённая распиновка fpga_10_vga_hdmi_test: clock H16/H17, data0 D19/D20, data1 C20/B20, data2 B19/A20.

## Проверка этой отдельной схемы

Vivado 2018.3 выполнил synthesis, implementation и write_bitstream. Setup WNS +8.702 нс, hold WHS +0.121 нс, ошибок DRC нет. Сохранено ожидаемое предупреждение ZPS7-1 о проекте Zynq без блока PS; оно не подавлялось. Отчёты находятся в hdmi/export/pl_only.

Симуляция проверила 4 950 000 пиксельных тактов, картинку, синхронизацию, перезапуск после reset и удержание AXI-данных при backpressure. verify_install.tcl отдельно проверяет, что в BD не осталось PS/DMA и выбран TEST_PATTERN=1.

Этот минимальный bitstream собран заново. После создания Git-ветки на плату он не загружался; на мониторе ранее была проверена исходная автономная картинка из архивной конфигурации. Итоговая ветка main с Linux остаётся самостоятельной рабочей версией.

## Открытие и загрузка

Проект: C:\Users\Zaxar\zynq_linux_pl_hdmi_test\zynq_linux.xpr.

Готовый bitstream: hdmi/export/pl_only/hdmi_test_pattern.bit.

Для отдельного PL-теста выберите режим загрузки JTAG и выполните полное выключение/включение питания, затем загрузите bitstream через Vivado Hardware Manager → Open Target → Auto Connect → Program Device. Если оставить загрузку с SD, на карте сейчас находится Linux-версия main и её BOOT.BIN снова конфигурирует собственную схему. Не заменяйте работающую PL Linux-системы этой схемой во время обращения Linux к AXI-периферии.

## Повторная сборка

В PowerShell, находясь в папке этой ветки:

```powershell
& C:\Xilinx\Vivado\2018.3\bin\vivado.bat -mode batch -source .\hdmi\tcl\prepare_from_git.tcl
& C:\Xilinx\Vivado\2018.3\bin\vivado.bat -mode batch -source .\hdmi\tcl\build_test_pattern.tcl
```

Проверка исходников симуляцией: hdmi/tcl/test_pattern.tcl. Структурная проверка: hdmi/tcl/verify_install.tcl.

create_pl_only.tcl записывает рецепт первоначального создания BD из исходников и локального IP; для обычной повторной сборки уже существующего проекта используйте build_test_pattern.tcl.
