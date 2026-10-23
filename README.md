# SILK Protocol — Vivado Project

**Static Inter-FPGA Link for Multi-FPGA SoC Prototyping**

[🇬🇧 English Version](#english-version) | [🇷🇺 Русская версия](#russian-version)

---

<a name="english-version"></a>
## 🇬🇧 English Version

### Overview

SILK (Static Inter-FPGA Link) is a high-speed communication protocol designed for transmitting signals partitioned between multiple FPGAs during hardware prototyping of complex System-on-Chip (SoC) designs.

The project provides an RTL implementation and a Vivado development environment targeting multi-FPGA systems based on AMD Xilinx Kintex-7 devices.

SILK uses high-speed GTX transceivers in RAW mode and Time-Division Multiplexing (TDM) with a static slot map. This architecture enables deterministic data transfer with predictable latency and supports cycle-accurate communication between partitioned logic blocks.

### Key Features

- **Deterministic Latency:** A fixed frame structure and static slot allocation provide predictable signal transfer timing.
- **TDM with a Static Slot Map:** Multiple logical signals are multiplexed onto a single high-speed serial link according to a predefined mapping.
- **Data Integrity:** Frames contain a 32-bit synchronization word, header, payload, and CRC-32 (ISO-HDLC) for error detection.
- **Link Initialization and Recovery:** A link-control finite-state machine (FSM) implements the `HELLO` → `SYNC_MAP` → `LINK_UP` initialization sequence and a dedicated `RECOVERY` state.
- **Multi-Channel Aggregation:** The architecture is intended to support channel bonding and phase alignment across multiple GTX lanes, subject to implementation and validation.
- **Simulation and Verification:** Testbench infrastructure supports functional verification and error-injection scenarios.

### Repository Structure

```text
SILK_Project/
├── src/                  # RTL source files (SystemVerilog)
│   ├── silk_pkg.sv       # Protocol constants and types
│   ├── silk_tx.sv        # Transmitter FSM and frame builder
│   ├── silk_rx.sv        # Receiver FSM, CRC checker, and unpacker
│   ├── silk_link_fsm.sv  # Initialization and recovery FSM
│   └── gtx_wrapper.sv    # Top-level controller connecting to GTX
├── tb/                   # Simulation testbenches
│   └── tb_silk_top.sv    # Main testbench with error injection
├── constraints/          # XDC constraints
│   └── pinout.xdc        # Pin assignments and timing constraints
├── ip/                   # Vivado IP configuration files
│   └── gtx_wizard.xci    # 7 Series Transceivers Wizard configuration
├── scripts/              # TCL build and automation scripts
└── SILK_Project.xpr      # Vivado project file
```

### Protocol Architecture

The SILK link consists of the following logical components:

1. **Transmitter:** Collects signals according to the static slot map, assembles payload data, and generates framed data for transmission.
2. **Frame Format:** Provides synchronization, header information, payload, and CRC-32 error detection.
3. **GTX Interface:** Connects the protocol logic to the high-speed serial transceiver operating in RAW mode.
4. **Receiver:** Detects frame boundaries, validates frame integrity, and extracts the received signals.
5. **Link-Control FSM:** Coordinates link initialization, synchronization, normal operation, and recovery.

The static slot map defines the relationship between logical signals and their positions in the transmitted payload. Both endpoints must use compatible mappings and frame configurations.

### Link Initialization

The nominal link initialization sequence is:

`HELLO` → `SYNC_MAP` → `LINK_UP`

- **HELLO:** Establishes initial communication between the endpoints.
- **SYNC_MAP:** Synchronizes or verifies the static signal-map configuration.
- **LINK_UP:** Indicates that the link is ready for normal data transfer.
- **RECOVERY:** Handles detected communication errors and coordinates recovery according to the implemented state-machine logic.

The exact transition conditions, timeout handling, and recovery behavior are defined by the RTL implementation.

### Data Integrity

SILK uses CRC-32 (ISO-HDLC) to detect transmission errors within protected frame data. The receiver checks the received CRC and can report invalid frames to the link-control logic.

CRC provides error detection, not error correction. Retransmission, if required, must be implemented as a separate mechanism.

### Development Environment

- **FPGA family:** AMD Xilinx 7 Series Kintex-7
- **Design language:** SystemVerilog
- **Development tool:** AMD Xilinx Vivado
- **Serial interface:** GTX transceivers in RAW mode
- **Multiplexing:** Time-Division Multiplexing with a static slot map
- **Verification:** RTL simulation with a SystemVerilog testbench

The exact Vivado version, FPGA part number, reference-clock configuration, transceiver line rate, and physical pin assignments must match the project configuration and board design.

### Getting Started

1. Open `SILK_Project.xpr` in Vivado.
2. Check that the required IP configuration files are available and compatible with the installed Vivado version.
3. Verify the target FPGA, reference-clock settings, GTX configuration, and XDC constraints.
4. Run RTL elaboration and simulation using the supplied testbench.
5. Review simulation results, including frame synchronization, CRC checking, and error-injection scenarios.
6. Generate the FPGA bitstream after resolving all synthesis, implementation, and timing issues.

Alternatively, use the TCL scripts in `scripts/` if build automation is configured.

### Verification Scope

The testbench is intended to verify protocol behavior, including:

- Frame construction and parsing.
- Synchronization and link initialization.
- Payload transmission and reception.
- CRC calculation and error detection.
- Recovery from injected communication errors.

Successful RTL simulation does not by itself establish physical-link reliability, deterministic end-to-end timing, or multi-lane alignment. These properties require additional timing analysis and hardware validation.

### Project Status

This repository describes the intended SILK architecture and project organization. Feature availability and implementation completeness must be confirmed against the actual RTL, constraints, IP configuration, and verification results.

---

<a name="russian-version"></a>
## 🇷🇺 Русская версия

### Обзор

SILK (Static Inter-FPGA Link) — высокоскоростной протокол обмена данными между несколькими ПЛИС, предназначенный для аппаратного прототипирования сложных систем на кристалле (СнК), логика которых распределена между несколькими устройствами.

Проект включает RTL-реализацию протокола и среду разработки в AMD Xilinx Vivado с ориентацией на многокристальные системы прототипирования на базе ПЛИС семейства Kintex-7.

SILK использует высокоскоростные трансиверы GTX в режиме RAW и временное мультиплексирование (Time-Division Multiplexing, TDM) со статической картой временных слотов. Такая архитектура позволяет организовать передачу данных с предсказуемой задержкой и поддерживать цикл-точное взаимодействие между блоками логики, размещёнными в разных ПЛИС.

### Основные возможности

- **Детерминированная задержка:** фиксированная структура кадров и статическое распределение слотов обеспечивают предсказуемость передачи сигналов.
- **TDM со статической картой слотов:** множество логических сигналов передаётся по одному высокоскоростному последовательному каналу в соответствии с заранее заданным отображением.
- **Контроль целостности данных:** кадр содержит 32-битное синхрослово, заголовок, полезную нагрузку и CRC-32 (ISO-HDLC) для обнаружения ошибок.
- **Инициализация и восстановление соединения:** конечный автомат управления каналом реализует последовательность `HELLO` → `SYNC_MAP` → `LINK_UP` и отдельное состояние `RECOVERY`.
- **Объединение нескольких каналов:** архитектура предусматривает возможность объединения нескольких линий GTX и выравнивания фаз при соответствующей реализации и проверке.
- **Моделирование и верификация:** тестовая инфраструктура предназначена для функциональной проверки протокола и моделирования ошибок передачи.

### Структура репозитория

```text
SILK_Project/
├── src/                  # Исходные RTL-файлы (SystemVerilog)
│   ├── silk_pkg.sv       # Константы и типы протокола
│   ├── silk_tx.sv        # Автомат передатчика и формирователь кадров
│   ├── silk_rx.sv        # Автомат приёмника, проверка CRC и распаковка
│   ├── silk_link_fsm.sv  # Автомат инициализации и восстановления канала
│   └── gtx_wrapper.sv    # Верхнеуровневый модуль интерфейса с GTX
├── tb/                   # Тестовые окружения для моделирования
│   └── tb_silk_top.sv    # Основной тестбенч с инъекцией ошибок
├── constraints/          # Файлы ограничений XDC
│   └── pinout.xdc        # Назначения выводов и ограничения тактирования
├── ip/                   # Файлы конфигурации IP Vivado
│   └── gtx_wizard.xci    # Конфигурация 7 Series Transceivers Wizard
├── scripts/              # TCL-скрипты сборки и автоматизации
└── SILK_Project.xpr      # Файл проекта Vivado
```

### Архитектура протокола

Канал SILK состоит из нескольких логических компонентов:

1. **Передатчик:** собирает значения сигналов в соответствии со статической картой слотов, формирует полезную нагрузку и упаковывает данные в кадры.
2. **Формат кадра:** обеспечивает синхронизацию, передачу заголовка, полезной нагрузки и контрольной суммы CRC-32.
3. **Интерфейс GTX:** связывает протокольную логику с высокоскоростным последовательным трансивером, работающим в режиме RAW.
4. **Приёмник:** определяет границы кадров, проверяет целостность принятых данных и восстанавливает исходные логические сигналы.
5. **Автомат управления каналом:** координирует инициализацию, синхронизацию, штатный обмен и восстановление после ошибок.

Статическая карта слотов определяет соответствие между логическими сигналами и позициями в полезной нагрузке кадра. Передающая и принимающая стороны должны использовать согласованные карты и одинаковые параметры формата кадров.

### Инициализация канала

Основная последовательность установления соединения:

`HELLO` → `SYNC_MAP` → `LINK_UP`

- **HELLO:** начальное установление взаимодействия между передающей и принимающей сторонами.
- **SYNC_MAP:** синхронизация или проверка конфигурации статической карты сигналов.
- **LINK_UP:** состояние готовности канала к штатной передаче данных.
- **RECOVERY:** обработка обнаруженных ошибок и координация восстановления соединения в соответствии с логикой реализованного автомата.

Конкретные условия переходов, обработка тайм-аутов и алгоритмы восстановления определяются RTL-реализацией.

### Контроль целостности данных

Для обнаружения ошибок передачи SILK использует CRC-32 (ISO-HDLC). Приёмник проверяет контрольную сумму кадра и может передавать информацию об ошибках в логику управления каналом.

CRC предназначена для обнаружения ошибок, а не для их исправления. Если требуется повторная передача повреждённых кадров, соответствующий механизм должен быть реализован отдельно.

### Среда разработки

- **Семейство ПЛИС:** AMD Xilinx 7 Series Kintex-7.
- **Язык описания аппаратуры:** SystemVerilog.
- **Среда разработки:** AMD Xilinx Vivado.
- **Последовательный интерфейс:** трансиверы GTX в режиме RAW.
- **Мультиплексирование:** TDM со статической картой временных слотов.
- **Верификация:** RTL-моделирование с использованием тестбенча на SystemVerilog.

Версия Vivado, точная модель ПЛИС, параметры опорного тактового сигнала, скорость последовательной передачи и назначения физических выводов должны соответствовать конфигурации проекта и используемой аппаратной платформе.

### Начало работы

1. Откройте `SILK_Project.xpr` в Vivado.
2. Убедитесь, что необходимые файлы конфигурации IP доступны и совместимы с установленной версией Vivado.
3. Проверьте целевую ПЛИС, параметры опорного тактового сигнала, конфигурацию GTX и ограничения XDC.
4. Выполните elaboration RTL и запустите моделирование с использованием предоставленного тестбенча.
5. Проверьте результаты моделирования, включая синхронизацию кадров, контроль CRC и сценарии инъекции ошибок.
6. После устранения ошибок синтеза, реализации и временного анализа выполните генерацию битового файла ПЛИС.

При настроенной автоматизации сборки можно использовать TCL-скрипты из каталога `scripts/`.

### Область верификации

Тестбенч предназначен для проверки следующих аспектов работы протокола:

- Формирование и разбор кадров.
- Синхронизация и инициализация канала.
- Передача и приём полезной нагрузки.
- Расчёт CRC и обнаружение ошибок.
- Восстановление после искусственно внесённых ошибок передачи.

Успешное RTL-моделирование само по себе не подтверждает надёжность физического канала, детерминированность сквозной задержки или корректность выравнивания нескольких линий GTX. Для подтверждения этих характеристик необходимы дополнительный временной анализ и испытания на аппаратуре.

### Статус проекта

Данный README описывает предполагаемую архитектуру SILK и организацию репозитория. Наличие и степень готовности каждой функции необходимо подтверждать по фактическому RTL-коду, ограничениям, конфигурации IP и результатам верификации.
