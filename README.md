# Ender 3 Pro – Marlin-firmware

Min Marlin-konfiguration för en Creality Ender 3 Pro.

## Struktur

| Sökväg | Innehåll |
|---|---|
| `Marlin/` | Marlin som git-submodul, låst på en release-tagg (se nedan) |
| `config/` | Våra `Configuration.h`, `Configuration_adv.h` m.fl. |
| `scripts/apply-config.sh` | Kopierar `config/` in i `Marlin/Marlin/` inför bygge |

Arbetssätt: första commiten i `config/` är **orörda** exempelfiler från
[MarlinFirmware/Configurations](https://github.com/MarlinFirmware/Configurations).
Varje ändring görs sedan som en egen commit, så att `git log -p config/`
visar exakt vad som skiljer sig från standard.

## Bygga

```sh
git clone --recursive git@github.com:Woblin/ender-3-pro-firmware.git
cd ender-3-pro-firmware
./scripts/apply-config.sh
cd Marlin
pio run -e STM32F103RE_creality
```

GitHub Actions bygger firmware vid varje push och PR. Den färdiga `.bin`-filen
kan laddas ner under fliken **Actions** → körningen → **Artifacts**.

Vid lokalt bygge hamnar firmwarefilen i `Marlin/.pio/build/<env>/` och kopieras till SD-kortet.
Tips: byt namn på `.bin`-filen till något nytt varje gång, annars kan
4.2.x-korten hoppa över uppdateringen.

## Skrivaren

| | |
|---|---|
| Marlin-version | 2.1.2.10 |
| Exempelconfig | `Creality/Ender-3 Pro/CrealityV427` (release-2.1.2.10) |
| Moderkort | Creality V4.2.7 "Silent", TMC2225 |
| PlatformIO-env | `STM32F103RE_creality` |
| Display | Standard (CR10_STOCKDISPLAY) |

### Uppgraderingar

| Datum | Uppgradering | Påverkar config |
|---|---|---|
| | BLTouch (5-pinsporten) | Probe som Z-endstop, bilinjär 5x5-nivellering |
| | Glasbädd | Inget i firmware, Z-offset ställs in med BLTouch |
| | Direct drive: Creality Sprite | E-steg 424.9, ev. kortare retraction |
| | Creality V4.2.7 Silent | Val av exempelconfig |

## Påslagna features utöver exempelconfigen

| Feature | Varför |
|---|---|
| BLTouch, bilinjär 5x5, Z_SAFE_HOMING | Automatisk nivellering (visas i OctoPrint Bed Level Visualizer) |
| PROBE_OFFSET_WIZARD, BABYSTEP_ZPROBE_OFFSET | Ställa Z-offset från displayen |
| EMERGENCY_PARSER | Nödstopp och avbrott från OctoPrint verkställs direkt |
| HOST_ACTION_COMMANDS, HOST_PROMPT_SUPPORT | Paus/fortsätt och dialoger synkas med OctoPrint |
| ADVANCED_OK, BUFSIZE 8 | Jämnare strömning över USB |
| ADVANCED_PAUSE_FEATURE, PARK_HEAD_ON_PAUSE, FILAMENT_LOAD_UNLOAD_GCODES | M600 filamentbyte, M125, M701/M702 |
| PIDTEMPBED | Stabil bäddtemperatur (glasbädd) |
| PREHEAT_BEFORE_LEVELING | Bädden 60 °C innan G29 |
| ARC_SUPPORT (standard) | För OctoPrint-pluginet Arc Welder |
| INPUT_SHAPING_X/Y (X 65 Hz, Y 41 Hz) | Mindre ringning, som gör högre acceleration möjlig. Omkalibrera med `M593 X F.. ` / `M593 Y F..` |
| LIN_ADVANCE (K=0 = av) | Skarpare hörn. Kalibrera med `M900 K..` |

### Kalibreringsordning efter flash

1. `M502` och sedan `M500` (nollställ EEPROM till firmwarens värden)
2. Kontrollera extruderns riktning, BLTouch (`M280 P0 S120` självtest) och homing
3. E-steg (`M92 E..`), PID hotend (`M303 E0 S210 C8`), PID bädd (`M303 E-1 S60 C8`)
4. Z-offset med Probe Offset Wizard, mesh med `G29`, spara med `M500`
5. Input shaping: Orcas frekvenstest, sätt `M593 X F.. ` och `M593 Y F..` (gjort, se nedan)
6. Linear advance: K-faktortest, sätt `M900 K..`

## Värden från gamla builden (Marlin 2.1.2.4, M503)

Stod bara i skrivarens EEPROM och har lagts in i `config/`: probe-offset
X -32 / Y -40.5 / Z -4.94, max matning Z 10 / E 60, max acceleration
X/Y 800 / Z 500, retract-acceleration 1000. Bäddnätet (3x3) sparades inte
eftersom det mäts om med 5x5 och normalt är flackt (±0,1 mm).

## Kalibrerade värden

Uppdatera när något kalibreras. Värdena ska även finnas i `config/`.

| Värde | Standard | Kalibrerat | Datum | Anteckning |
|---|---|---|---|---|
| E-steg (steps/mm) | 424.9 (Sprite) | 424.9 | 2026-11-16 | Samma som Creality-värdet, ej egen kalibrering. Gör 100 mm-test |
| X/Y/Z-steg | 80 / 80 / 400 | | | |
| Hotend PID (P/I/D) | 21.73 / 1.54 / 76.55 | 16.77 / 1.44 / 48.98 | 2026-11-17 | `M303 E0 S210 C8 U1`, 210 °C |
| Bädd PID (P/I/D) | 10 / 0.023 / 305.4 | 206.06 / 35.29 / 802.28 | 2026-11-17 | `M303 E-1 S60 C8 U1`, 60 °C. PIDTEMPBED var av i gamla builden |
| Z-offset (BLTouch) | 0 | -4.94 | 2026-11-16 | Från M503 på gamla builden (`M851 Z`) |
| Probe-offset X/Y | -32 / -40.5 | | 2026-11-16 | Från gamla builden (2.1.2.4) |
| Input shaping X/Y | av | 65 Hz / 41 Hz (zeta 0.15) | 2026-11-17 | Orcas Calibration → Input Shaping → Frequency test |
| Acceleration X/Y (max) | 500 / 800 | 3000 | 2026-11-17 | `DEFAULT_MAX_ACCELERATION`. Testat med 20 mm-kub: 1500 och 2500 mm/s² gav rena hörn |
| Acceleration print/travel | 500 / 500 | 2500 / 2500 | 2026-11-17 | `DEFAULT_ACCELERATION` och `DEFAULT_TRAVEL_ACCELERATION` |

## OrcaSlicer-inställningar som hör ihop med firmwaren

- G-code-flavor: **Marlin 2** (krävs för input shaping-testet)
- Maskinens max acceleration X/Y och extruding: **3000**, junction deviation **0.08** (samma som firmwaren)
- Acceleration i processen: 2500 (första lagret 300). Orca stryper processens värden till maskinens max
- Start-G-code: `G28` följt av `M420 S1` (ladda sparat nät i stället för `G29` varje print)
- Z-hop 0 (direktdrift). Kontrollera att objekt inte har egna inställningar som överstyr profilen (Objects-fliken)
- Avaktivera "Slow printing down for better layer cooling" vid tester på små modeller, annars går väggarna på 10–20 mm/s
- Verifierad riktig modell (Rune Obelisk, 2026-11-18): acceleration 2500, yttervägg 100, innerväggar/solid infill 150 mm/s, topp 100, flödestak 12, 2 väggar. Resultat: perfekt utskrift, 22 min
- Yttervägg: **100 mm/s** är verifierad ren (20 mm-kub, acceleration 2500, ca 8 mm³/s). Max volumetric speed: **12 mm³/s**
- Flödestest (Orca, 2026-11-17): tornet föll vid ca 18 mm³/s, men 20 mm-kuber på 150 mm/s (ca 12 mm³/s) fick ändå underextruderade partier mitt på sidorna. Tornet och kuben säger alltså olika och orsaken är inte utredd. Tills vidare gäller 100 mm/s och tak 12. Möjligt nästa test: 230 °C på samma kub. För mer fart: större lagerhöjd i stället för högre hastighet
- Bäddnät: bygg det **förvärmt** (`M104 S120`, `M140 S60`, `M109 S120`, `M190 S60`, `G28`, `G29`) och kontrollera att värdena ligger nära 0 innan `M500`. Två G29-körningar efter kall start gav +4,5 mm i hela nätet (orsak okänd). `G30` kräver `G28` före varje körning, annars "Z Probe Past Bed"

## Uppdatera Marlin

```sh
cd Marlin && git fetch --tags && git checkout <ny-tagg> && cd ..
git add Marlin && git commit -m "Uppdatera Marlin till <ny-tagg>"
```

Jämför sedan nya exempelconfigs mot `config/` och flytta över våra ändringar.
