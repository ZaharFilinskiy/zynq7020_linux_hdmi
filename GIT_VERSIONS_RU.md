# Ветки проекта в Git

Репозиторий: **https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi**. Адрес `origin`: `https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi.git`.

- **[main](https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi/tree/main)** — основная рабочая версия: PS + DDR + VDMA + Linux simplefb, документация и проверенные загрузочные файлы.
- **[pl-hdmi-test](https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi/tree/pl-hdmi-test)** — автономная аппаратная схема HDMI 1280×720. RTL и ограничения взяты из ZIP PL-версии, сохранённого перед интеграцией Linux. В новом минимальном BD отсутствуют PS/DDR/VDMA, `TEST_PATTERN=1`. SDK, Linux и SD для формирования картинки не требуются.

## Почему две ветки

Ветки сохраняют два разных состояния проекта с общим началом истории. `main` развивает систему Linux; `pl-hdmi-test` позволяет отдельно изучать и проверять выход HDMI с аппаратным генератором. Готовые bitstream из этих веток соответствуют разным Block Design и не взаимозаменяемы для работающей Linux-системы.

Сохранённый архив исходной PL-конфигурации остаётся отдельной резервной копией. Ветка содержит выделенную минимальную схему, заново собранную и проверенную симуляцией. Именно её сокращённый bitstream после создания ветки на плату ещё не загружался. Подробности: `HDMI_PL_ONLY_RU.md` в PL-ветке.

## Рабочие папки на исходном ПК

| Ветка | Папка |
|---|---|
| main | `C:\Users\Zaxar\zynq_linux` |
| pl-hdmi-test | `C:\Users\Zaxar\zynq_linux_pl_hdmi_test` |

Вторая папка создана через `git worktree`: у папок общая Git-база и история, но отдельные файлы и выбранные ветки. Основная папка остаётся на `main`. Можно открывать нужный `zynq_linux.xpr`, не заменяя файлы соседнего варианта. Не удаляйте основную папку вручную: PL-worktree использует её Git-базу.

## Получить проект на другом компьютере

```powershell
git clone https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi.git
Set-Location zynq7020_linux_hdmi
git worktree add ..\zynq_pl_hdmi_test pl-hdmi-test
```

Первая папка содержит main, соседняя — PL-тест. Если нужен только PL-вариант:

```powershell
git clone --branch pl-hdmi-test https://github.com/ZaharFilinskiy/zynq7020_linux_hdmi.git zynq_pl_hdmi_test
```

Одна ветка не может одновременно быть выбрана в двух worktree. При существующей PL-папке переключать основную папку на ту же ветку не нужно.

## Открыть свежую копию в Vivado

В каждой папке есть собственный `zynq_linux.xpr`. Из нужной папки сначала выполните:

```powershell
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\prepare_from_git.tcl
& 'C:\Xilinx\Vivado\2018.3\bin\vivado.bat' -mode batch -source .\hdmi\tcl\verify_install.tcl
```

Подготовка восстанавливает generated products; проверка валидирует BD и выбранный режим. Затем откройте `.xpr` в Vivado 2018.3.

Сборка main — `hdmi/tcl/build.tcl`, PL — `hdmi/tcl/build_test_pattern.tcl`. Готовые файлы main находятся в `hdmi/export` и `hdmi/linux/build`; PL-bitstream — `hdmi/export/pl_only/hdmi_test_pattern.bit` в PL-ветке. Работу с Vivado следует закончить перед переключением ветки в той же папке.

## История и состояние

Из любой папки репозитория:

```powershell
git status
git branch -vv
git remote -v
git log --all --graph --oneline --decorate
git worktree list
git diff main..pl-hdmi-test --stat
```

Обычный цикл сохранения собственных изменений:

```powershell
git diff
git add <пути_изменённых_файлов>
git commit -m "Кратко описать изменение"
git push
```

Проверяйте содержимое перед фиксацией. Upstream каждой ветки связывает её с одноимённой веткой `origin`; `git push` из соответствующей папки отправляет её новые коммиты. Обновление с GitHub: `git pull --ff-only` при чистой рабочей папке.

## Что сохранено и исключено

В Git включены RTL/XDC, Block Design, wrapper, локальный IP, скрипты и объяснения. Выбранные готовые bitstream/BOOT.BIN/HDF, ядро/DTB, отчёты и подтверждения рабочей версии сохранены намеренно. Полный образ SD и rootfs Buildroot не включены.

`.gitignore` исключает кэши Vivado, `.runs/.sim/.hw`, generated BD IP, рабочую область SDK и временные результаты. Они восстанавливаются средствами Vivado/SDK из сохранённых исходников. `.gitattributes` задаёт LF для текста и отключает преобразование бинарных файлов.

Исходный коммит GitHub с `LICENSE` сохранён в истории при объединении. Публикация выполняется обычным push, без принудительной перезаписи веток.
