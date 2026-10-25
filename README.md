# Zynq Linux + HDMI

Ветка **main** — проверенная версия PS/DDR/VDMA + Linux framebuffer, HDMI 1280×720.

Открыть `zynq_linux.xpr` в Vivado 2018.3. Подробное учебное описание: [HDMI_LINUX_RU.md](HDMI_LINUX_RU.md).

## Локальные ветки

| Ветка | Назначение | Рабочая папка |
|---|---|---|
| main | PS, Linux и HDMI через DDR/VDMA | C:\Users\Zaxar\zynq_linux |
| pl-hdmi-test | Автономный PL-тест HDMI, без PS/DDR/VDMA в BD | C:\Users\Zaxar\zynq_linux_pl_hdmi_test |

Вторая папка — Git worktree той же истории, а не отдельный независимый репозиторий. В каждой папке открыта своя ветка. Поэтому для работы с двумя вариантами не нужно переключать main и заменять её файлы.

## Что сохранено в Git

Исходники, Block Design, ограничения, локальный IP rgb2dvi, скрипты сборки, документация и выбранные готовые файлы загрузки. Кэши Vivado, generated IP output products, рабочая область SDK и временные результаты симуляции исключены через .gitignore. Они остаются на диске и восстанавливаются инструментами при сборке. Приложения/BSP SDK создаются скриптом hdmi/tcl/build_sdk.tcl из HDF.

Для открытия и проверки из чистой копии используется `hdmi/tcl/verify_install.tcl`, для аппаратной сборки main — `hdmi/tcl/build.tcl`. При отсутствии generated products сначала откройте Block Design и выполните Generate Output Products, либо используйте скрипт подготовки, описанный в GIT_VERSIONS_RU.md.

## Просмотр истории

```powershell
git -C C:\Users\Zaxar\zynq_linux status
git -C C:\Users\Zaxar\zynq_linux branch -vv
git -C C:\Users\Zaxar\zynq_linux log --all --graph --oneline --decorate
git -C C:\Users\Zaxar\zynq_linux worktree list
```

Удалённый репозиторий не настроен. Эта фиксация создана локально; push не выполнялся.
