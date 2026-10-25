# Zynq-7020: автономный тест HDMI в PL

Ветка **`pl-hdmi-test`** выводит аппаратное тестовое изображение: восемь цветных полос, шахматный узор снизу и белую рамку. Режим **1280×720, около 59,93 Гц**. В Block Design отсутствуют PS, DDR и VDMA; изображение формируется без Linux и SDK.

[Подробное описание и проверки](HDMI_PL_ONLY_RU.md) · [Основная версия с Linux](https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi/tree/main) · [Работа с ветками](GIT_VERSIONS_RU.md)

## Схема

```mermaid
flowchart LR
    A[50 МГц] --> B[Clock Wizard]
    B --> C[Генератор AXI Stream]
    C --> D[Развёртка 1280×720]
    D --> E[rgb2dvi / TMDS]
    E --> F[HDMI]
```

Собственные Verilog-модули включены в Block Design как Module Reference. RTL и распиновка взяты из сохранённой рабочей PL-версии; минимальный BD создан отдельно. Целевой кристалл — **`xc7z020clg400-2`**, инструменты — **Vivado 2018.3**. Распиновка соответствует примеру платы `fpga_10_vga_hdmi_test`; точные контакты приведены в [описании](HDMI_PL_ONLY_RU.md) и [XDC](hdmi/constraints).

## Открыть и загрузить

```powershell
git clone --branch pl-hdmi-test https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi.git zynq_pl_hdmi_test
Set-Location zynq_pl_hdmi_test
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\prepare_from_git.tcl
```

Откройте **`zynq_linux.xpr`**. Готовый bitstream: **[hdmi_test_pattern.bit](hdmi/export/pl_only/hdmi_test_pattern.bit)**.

Для отдельного испытания выберите загрузку платы по JTAG, полностью выключите и включите питание, затем в Vivado: **Hardware Manager → Open Target → Auto Connect → Program Device**. Укажите этот bitstream. При загрузке с SD установленный там BOOT.BIN может сконфигурировать другую схему. Перед переходом к PL-тесту завершите работу Linux: его AXI-периферия в этой схеме отсутствует.

## Пересобрать и проверить

После подготовки, из папки проекта:

```powershell
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\verify_install.tcl
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\test_pattern.tcl
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\build_test_pattern.tcl
```

Результаты находятся в `hdmi/export/pl_only`. Кэши и generated products исключены из Git и восстанавливаются при подготовке.

## Результаты проверки

| Проверка | Результат |
|---|---|
| Synthesis / implementation / bitstream | Успешно, Vivado 2018.3 |
| Timing | Setup WNS **+8,702 нс**, hold WHS **+0,121 нс** |
| DRC | 0 ошибок; предупреждение ZPS7-1 о Zynq без блока PS сохранено |
| Симуляция | 4 950 000 пиксельных тактов: картинка, синхронизация, reset, backpressure |
| Чистая Git-копия | Generated products восстановлены, BD проверен; PS/DDR/VDMA отсутствуют |

**Этот минимальный bitstream после создания ветки на плату ещё не загружался.** На мониторе ранее проверялась исходная автономная картинка из архивной конфигурации. Версия с Linux в `main` отдельно подтверждена на плате.

[Манифест с SHA256](hdmi/export/pl_only/validation.json) · [Timing](hdmi/export/pl_only/timing.rpt) · [DRC](hdmi/export/pl_only/drc.rpt) · [Симуляция](hdmi/export/pl_only/simulation.txt)

## Файлы

- [HDMI_PL_ONLY_RU.md](HDMI_PL_ONLY_RU.md) — устройство, происхождение исходников и порядок проверки.
- [hdmi/rtl](hdmi/rtl) — генератор тестового потока и развёртка.
- [hdmi/tcl](hdmi/tcl) — подготовка, проверка, симуляция и сборка.
- [hdmi/ip_repo](hdmi/ip_repo) — локальный IP rgb2dvi.
- [zynq_linux.srcs](zynq_linux.srcs) — Block Design и wrapper.

В репозитории сохранена лицензия [GNU GPL v3](LICENSE); сторонние компоненты, включая rgb2dvi, сохраняют свои лицензионные уведомления.
