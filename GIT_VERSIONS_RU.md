# Ветки проекта в Git

Репозиторий находится непосредственно в `C:\Users\Zaxar\zynq_linux`.

- `main`: рабочая версия PS + DDR + VDMA + Linux simplefb. Основной проект, документация и проверенные загрузочные файлы.
- `pl-hdmi-test`: отдельная автономная аппаратная схема HDMI 1280×720. Источник — RTL и ограничения из ZIP PL-версии, сохранённого перед интеграцией Linux; неиспользуемые PS/DDR/VDMA исключены из нового BD. TEST_PATTERN=1. SDK, Linux и SD не требуются для вывода теста.

Ветка PL размещена в дополнительной рабочей папке `C:\Users\Zaxar\zynq_linux_pl_hdmi_test` с помощью `git worktree`. У неё общая история и Git-база с main, но отдельные файлы и своя выбранная ветка. Основная папка остаётся на main.

## Открытие

В каждой папке есть собственный `zynq_linux.xpr`. Открывайте файл из нужной папки. Работу с Vivado лучше закончить перед переключением ветки в той же папке.

Чтобы подготовить generated products в свежей Git-копии:

```powershell
Set-Location C:\Users\Zaxar\zynq_linux
& C:\Xilinx\Vivado\2018.3\bin\vivado.bat -mode batch -source .\hdmi\tcl\prepare_from_git.tcl
```

Затем для main — `hdmi/tcl/build.tcl`, для PL — `hdmi/tcl/build_test_pattern.tcl`. Скрипт подготовки также есть в ветке PL. Готовые проверенные файлы main находятся в hdmi/export и hdmi/linux/build; готовый PL bitstream — hdmi/export/pl_only/hdmi_test_pattern.bit в PL-папке.

## Как посмотреть историю и изменения

```powershell
git -C C:\Users\Zaxar\zynq_linux status
git -C C:\Users\Zaxar\zynq_linux branch -vv
git -C C:\Users\Zaxar\zynq_linux log --all --graph --oneline --decorate
git -C C:\Users\Zaxar\zynq_linux worktree list
git -C C:\Users\Zaxar\zynq_linux diff main..pl-hdmi-test --stat
```

Одна ветка не может одновременно быть выбрана в двух worktree. Поэтому при существующей PL-папке попытка `git switch pl-hdmi-test` в основной папке будет отклонена Git. Для обычной работы достаточно пользоваться уже созданными двумя папками.

## Что исключено

.gitignore исключает кэши, каталоги .runs/.sim/.hw, generated BD IP, рабочие файлы SDK, логи инструментов вне выбранной папки проверки. Такие файлы остаются на диске. Block Design, исходники RTL/XDC, локальный IP-репозиторий и скрипты позволяют их восстановить.

Выбранные готовые bitstream/BOOT.BIN/HDF, ядро/DTB, отчёты и подтверждения рабочей версии включены намеренно. .gitattributes сохраняет бинарные файлы без преобразования переводов строк, а текст репозитория — с LF.

Удалённый сервер не добавлен; push не выполнялся.
