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
| | Direct drive: Creality Sprite | E-steg ~424.9 (Creality-värde, kalibrera), ev. inverterad E-riktning, kortare retraction |
| | Creality V4.2.7 Silent | Val av exempelconfig |

## Kalibrerade värden

Uppdatera när något kalibreras. Värdena ska även finnas i `config/`.

| Värde | Standard | Kalibrerat | Datum | Anteckning |
|---|---|---|---|---|
| E-steg (steps/mm) | 424.9 (Sprite) | | | Kalibrera med 100 mm-test |
| X/Y/Z-steg | 80 / 80 / 400 | | | |
| Hotend PID (P/I/D) | | | | `M303 E0 S210 C8` |
| Bädd PID (P/I/D) | | | | `M303 E-1 S60 C8` |
| Z-offset | 0 | | | Probe Offset Wizard i menyn, sen `M500` |
| Probe-offset X/Y | -31.8 / -40.5 (gissning) | | | Mät, `M851 X.. Y..` |

## Uppdatera Marlin

```sh
cd Marlin && git fetch --tags && git checkout <ny-tagg> && cd ..
git add Marlin && git commit -m "Uppdatera Marlin till <ny-tagg>"
```

Jämför sedan nya exempelconfigs mot `config/` och flytta över våra ändringar.
