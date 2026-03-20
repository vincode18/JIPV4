# Business Process Requirement — JIP Milestone Aging Dashboard V4

**Version:** 5.0 (Clarified)  
**Date:** 2026-03-20  
**Status:** Corrected — based on Blueprint V3 Excel cross-check  
**Source:** Fix_Blueprint_Rancangan_Dashboard_JIP_V3_1.xlsx

---

## 1. Business Objective

Track **Job-In-Progress (JIP) parts** inside Work Orders to answer one question:

> **"Where is each part RIGHT NOW in the warehouse process, and how long has it been there?"**

Each Work Order (WO) has multiple reservation items (parts). Each part moves through warehouse milestones. The dashboard shows the **latest (current) milestone** of each part — not the full movement history.

---

## 2. Core Business Rule

```
ONE Work Order → MANY Parts (reservation items from RESB)
ONE Part       → ONE Current Milestone (the latest stage it has reached)
ONE Part       → ONE Row in the dashboard
```

**A part that has completed GI (Goods Issue) is no longer JIP — it is excluded from the default dashboard view.**

---

## 3. JIP Parts Milestone Flow

Parts move through these stages in order:

```
PENDING → TR_REQUEST → RECEIVED → NPB → GI (completed)
```

| Stage | Meaning | WM Source | EWM Source | Status |
|-------|---------|-----------|------------|--------|
| **PENDING** | Part reserved but not yet moved | No WM/EWM record | No EWM task | Still waiting |
| **TR_REQUEST** | Transfer Request / Transfer Order created | LTAP-TANUM exists (BWLVS 919/920) | PROCTY S919/S920 confirmed (PART-ZONE) | Parts requested from warehouse |
| **RECEIVED** | Parts received at staging area | LTAK-QDATU confirmed (BWLVS 997) | PROCTY S997 confirmed (WPSR-ZONE) | Parts arrived at staging |
| **NPB** | Sent to production (Near Production Buffer) | LTAK-QDATU confirmed (BWLVS 994) | PROCTY S994 confirmed (PROD-ZONE) | Parts at production area |
| **GI** | Goods Issue posted | MATDOC-BUDAT (BWART Z26) | MATDOC-BUDAT (BWART Z26) | **Completed — excluded from JIP** |

### Milestone Priority (highest wins)

When determining the current milestone, check in **reverse priority order** — the highest milestone found is the current position:

```
GI > NPB > RECEIVED > TR_REQUEST > WM_CONFIRMED > PENDING
```

If a part has both TR_REQUEST and RECEIVED records, it is at **RECEIVED** (the higher milestone).

---

## 4. WM vs EWM Detection

| Detection | Logic | Source Table |
|-----------|-------|-------------|
| **EWM** | Plant exists in `/SCWM/TMAPSTLOC` (has warehouse number mapping) | `/SCWM/TMAPSTLOC` |
| **WM** | Plant does NOT exist in `/SCWM/TMAPSTLOC` | Default (no mapping found) |

---

## 5. Aging Calculation (Milestone-to-Milestone)

**Aging measures how long a part stays at each stage** — calculated as the difference between TWO consecutive milestones, NOT from today minus a single date.

### 5.1 Aging Release (SDH Approval → WO Release)

This is the same for both WM and EWM:

```
Aging Release = WO Release Date (AFKO-FTRMI) − SDH Approval Date (ZTWOAPPR)
```

| Field | WM Source | EWM Source |
|-------|-----------|------------|
| From | ZTWOAPPR.APPR_DATE_LVL3 (SDH Approval) | Same |
| To | AFKO.FTRMI (Actual Release Date) | Same |
| Formula | FTRMI − SDH Date | Same |

### 5.2 Aging TR/TO (Transfer Order → Received)

| Field | WM Source | EWM Source |
|-------|-----------|------------|
| From | LTAP-ERDAT (TO Creation Date) | CONFIRMED_AT where PROCTY=S919 (PART-ZONE) |
| To | LTAK-QDATU where BWLVS=997 | CONFIRMED_AT where PROCTY=S997 (WPSR-ZONE) |
| Formula | QDATU(997) − ERDAT | CONFIRMED_AT(WPSR) − CONFIRMED_AT(PART) |

### 5.3 Aging Parts Received (same as TR/TO)

| Field | WM Source | EWM Source |
|-------|-----------|------------|
| From | LTAP-ERDAT | CONFIRMED_AT (PART-ZONE / S919) |
| To | LTAK-QDATU where BWLVS=997 | CONFIRMED_AT (WPSR-ZONE / S997) |
| Formula | QDATU(997) − ERDAT | CONFIRMED_AT(WPSR) − CONFIRMED_AT(PART) |

### 5.4 Aging NPB (Received → NPB)

| Field | WM Source | EWM Source |
|-------|-----------|------------|
| From | LTAK-QDATU where BWLVS=997 | CONFIRMED_AT (WPSR-ZONE / S997) |
| To | LTAK-QDATU where BWLVS=994 | CONFIRMED_AT (PROD-ZONE / S994) |
| Formula | QDATU(994) − QDATU(997) | CONFIRMED_AT(PROD) − CONFIRMED_AT(WPSR) |

### 5.5 Aging GI (NPB → Goods Issue)

| Field | WM Source | EWM Source |
|-------|-----------|------------|
| From | LTAK-QDATU where BWLVS=994 | CONFIRMED_AT (PROD-ZONE / S994) |
| To | MATDOC-BUDAT where BWART=Z26 | MATDOC-BUDAT where BWART=Z26 |
| Formula | BUDAT(Z26) − QDATU(994) | BUDAT(Z26) − CONFIRMED_AT(PROD) |

### 5.6 Visual Aging Flow

**WM Flow:**
```
SDH Approved → WO Released(FTRMI) → TO Created(LTAP-ERDAT) → 997 Confirmed → 994 Confirmed → GI Posted(Z26)
|←── Aging Release ──→|               |←── Aging TR/TO ───→|  |←── Aging NPB ──→|  |←─ Aging GI ─→|
                                       |←── Aging Received ─→|
```

**EWM Flow:**
```
SDH Approved → WO Released(FTRMI) → S919 PART-ZONE → S997 WPSR-ZONE → S994 PROD-ZONE → GI Posted(Z26)
|←── Aging Release ──→|              |←── Aging TR ──→|  |←── Aging NPB ──→|  |←─ Aging GI ─→|
                                      |←── Aging Recv ─→|
```

---

## 6. Aging Buckets (Overall Aging)

Overall aging is calculated from SDH Approval Date to today:

```
Overall Aging = Today − SDH Approval Date (ZTWOAPPR)
```

| Bucket | Condition | Color | Criticality |
|--------|-----------|-------|-------------|
| **OK** | Overall aging < 60 days | Green | 3 (Positive) |
| **60+** | Overall aging ≥ 60 and < 70 days | Yellow | 2 (Critical) |
| **70+** | Overall aging ≥ 70 days | Red | 1 (Negative) |

---

## 7. Data Model Rule: ONE Part = ONE Row

**Critical design rule:** The CDS view must produce exactly **one row per reservation item** (RESB record).

The current CONVT_OVERFLOW error happens because JOINs to EWM/WM tables return multiple rows per part (all historical warehouse tasks), multiplying the data. The correct approach:

- **DO:** Check if a milestone EXISTS for each part (yes/no)
- **DON'T:** Join ALL warehouse tasks/transfer orders for a material

This means:
- Split EWM join into 3 milestone-specific joins (NPB, RECEIVED, TR_REQUEST)
- Each join checks existence, not retrieves all records
- Result: 1 reservation item = 1 row with its current milestone

---

## 8. Dashboard Card Design

### 8.1 Dashboard Layout

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  Filter Bar: [Plant] [Warehouse Type WM/EWM] [Activity Type] [Year]        ║
╠════════════════════╦═══════════════════════╦═════════════════════════════════╣
║  CARD 01           ║  CARD 02              ║  CARD 03                        ║
║  Total JIP by      ║  Historical JIP ALL   ║  Historical Aging               ║
║  Plant + Month     ║  Plants (stacked)     ║  per Plant (monthly)            ║
║  [HORIZONTAL BAR]  ║  [STACKED BAR]        ║  [STACKED COLUMN]               ║
╠════════════════════╬═══════════════════════╬═════════════════════════════════╣
║  CARD 04           ║  CARD 05              ║  CARD 06                        ║
║  Activity Type     ║  Monthly Trend        ║  Average Aging                  ║
║  by Plant          ║  by Activity Type     ║  vs Target Line                 ║
║  [STACKED BAR]     ║  [STACKED COLUMN]     ║  [COMBINATION bar+line]         ║
╠════════════════════╩═══════════════════════╬═════════════════════════════════╣
║  CARD 07                                    ║  CARD 08                        ║
║  Total Aging Table (Plant × Month)          ║  Aging by Activity × Month      ║
║  [TABLE]                                    ║  [TABLE]                        ║
╚═════════════════════════════════════════════╩═════════════════════════════════╝
```

### 8.2 Card Descriptions

| Card | Title | Type | X-Axis | Y-Axis / Stack | What It Shows |
|------|-------|------|--------|-----------------|---------------|
| **01** | Total JIP per Plant | Horizontal Bar | Plant | Count of parts (NOT GI'd) per month | How many JIP parts at each plant, broken by activity type (USW, SER, OVH, ADD) |
| **02** | Historical JIP ALL Plants | Stacked Bar | All Plants | Count stacked OK / 60+ / 70+ | Total JIP across all plants, colored by aging bucket |
| **03** | Historical Aging per Plant | Stacked Column | Month (Jan-Dec) | Count stacked OK / 60+ / 70+ | Monthly aging trend for a specific plant with color buckets |
| **04** | Activity Type by Plant | Stacked Bar | Month (Jan-Dec) | Count stacked by Activity Type | JIP parts stacked by activity type (ADD, OVH, SER, USW) |
| **05** | Monthly Trend by Activity | Stacked Column | Month (Jan-Dec) | Count stacked by Activity Type | Monthly JIP count trend showing which activities contribute most |
| **06** | Average Aging vs Target | Combination (Bar + Line) | Month (Jan-Dec) | Bar = Avg Aging days, Line = Target (e.g., 15 days) | Actual aging compared against fixed target per activity type |
| **07** | Total Aging Table | Table | Plant × Month | Count per cell | Pivot table: Plant as rows, Months as columns, JIP count as values |
| **08** | Activity Aging Table | Table | Plant × Activity × Month | Count per cell | Pivot table: Plant + Activity Type as rows, Months as columns |

### 8.3 Card Details from Blueprint

**Card 01 — Total JIP per Plant (not GI'd):**
- Shows horizontal bars per month (Jan-Dec)
- Each bar stacked by Activity Type (USW, SER, OVH, ADD)
- Only counts parts where CurrentMilestone ≠ GI
- Filtered by selected Plant

**Card 02 — Historical JIP ALL Plants:**
- Stacked bar chart across all plants (BDI, BEK, BGL, BHT, BJM, BKI, BLP, BNT)
- Each plant bar stacked by aging: OK (green), 60+ (yellow), 70+ (red)
- Shows total count per plant

**Card 03 — Historical Aging per Plant:**
- Monthly stacked column for ONE specific plant (selected via filter)
- X-axis: JAN, FEB, MAR, ..., DEC
- Stacked colors: OK (green), 60+ (yellow), 70+ (red)
- Shows aging distribution trend over months

**Card 04 — Activity Breakdown by Plant:**
- Horizontal bars per month
- Stacked by activity type (ADD, OVH, SER, USW, etc.)
- Shows which activity types have the most JIP parts

**Card 05 — Monthly Trend by Activity:**
- Stacked column chart
- X-axis: JAN, FEB, ..., DEC
- Stacked by Activity Type
- Shows monthly volume of JIP parts by activity

**Card 06 — Average Aging vs Target:**
- Combination chart: bars + horizontal line
- Bars = actual average aging days per month
- Horizontal line = fixed target (e.g., 15 days)
- Target is per Activity Type (configurable via CDS CASE statement)
- Bars above line = exceeding target

**Card 07 — Total Aging Table:**
- Pivot format: Plant as row header, Months (Jan-Dec) as columns
- Cell values = count of JIP parts for that Plant × Month
- Example: BLP | Jan=50 | Feb=713 | Mar=0 | ... | Dec=338

**Card 08 — Activity Aging Table:**
- Pivot format: Plant + Activity Type (MAT) as row headers, Months as columns
- Example: BLP/ADD | Jan=0 | ... | Dec=1014
- Example: BLP/OVH | Jan=0 | ... | Dec=847

---

## 9. Filters

| Filter | Field | Values | Default |
|--------|-------|--------|---------|
| **Plant** | Plant | All Plant, JKT, MDN, BLP, BDI, etc. | All |
| **Warehouse Type** | WmEwmType | WM / EWM | All |
| **Activity Type** | ActivityType (ILART) | ADD, INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN | All |
| **Aging Bucket** | AgingBucket | OK, 60+, 70+ | All |
| **Current Milestone** | CurrentMilestone | PENDING, TR_REQUEST, RECEIVED, NPB, GI | ≠ GI (default) |
| **Period Year** | PeriodYear | 2024, 2025, 2026, ... | Current Year |
| **Period Month** | PeriodMonth | 2025-01, 2025-02, ... | All |
| **ABC Indicator** | ABCIndicator | A, B, C | All |

---

## 10. Source Tables Summary

| Business Object | Table | Key Fields Used | Purpose |
|-----------------|-------|-----------------|---------|
| Reservation Items | RESB | RSNUM, RSPOS, AUFNR, MATNR | **Driving table** — one row per part |
| Work Order Header | AUFK + AFKO + AFIH + ILOA | AUFNR, FTRMI, ILART, ABCKZ | WO info, release date, activity type, ABC |
| WO Approval | ZTWOAPPR | AUFNR, APPR_DATE_LVL3 | SDH approval date for aging start |
| Customer | VBAK | VBELN, KUNNR | Sold-to party via AUFK-KDAUF |
| WM Transfer Orders | LTAP + LTAK | TANUM, MATNR, BWLVS, QDATU | Classic WM milestones (919/997/994) |
| EWM Plant Map | /SCWM/TMAPSTLOC | PLANT, LGNUM | Detect if plant is EWM |
| EWM Product Map | /SCWM/BINMAT | MATID, MATNR | Material GUID → Material Number |
| EWM Warehouse Tasks | /SCWM/ORDIM_C | MATID, PROCTY, CONFIRMED_AT | EWM milestones (S919/S997/S994) |
| Goods Issue | MATDOC | MBLNR, RSNUM, RSPOS, BWART=Z26 | GI posting (final milestone) |

---

## 11. CDS Architecture (VDM 3-Layer)

```
Layer 1 — BASIC VIEWS (one per source table):
  ZI_JIPV4_Reservation       ← RESB (driving table)
  ZI_JIPV4_WorkOrder         ← AUFK + AFKO + AFIH + ILOA + ZTWOAPPR + VBAK
  ZI_JIPV4_TransferOrderWM   ← LTAP + LTAK
  ZI_JIPV4_GoodsMovement     ← MATDOC (BWART = Z26)
  ZI_JIPV4_EWM_ProductMap    ← /SCWM/BINMAT
  ZI_JIPV4_EWM_WarehouseTask ← /SCWM/ORDIM_C
  ZI_JIPV4_EWM_PlantMap      ← /SCWM/TMAPSTLOC

Layer 2 — COMPOSITE VIEW:
  ZI_JIPV4_PartsComposite    ← Joins all basic views
                                + WM/EWM detection
                                + Current Milestone (latest only)
                                + Aging calculations
                                + Aging Buckets

Layer 3 — CONSUMPTION VIEW:
  ZC_JIPV4_AGING             ← @OData.publish: true (OData V2)
                                + @Metadata.allowExtensions: true

METADATA EXTENSION:
  ZE_JIPV4_AGING             ← All @UI annotations (charts, filters, table)
```

---

## 12. Key Technical Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| GI Movement Type | **BWART = Z26** (custom) | Not standard 261 — confirmed in blueprint |
| Release Date | **AFKO-FTRMI** | Actual release date (not IDAT1) — confirmed in V2 blueprint |
| ABC Indicator | **ILOA-ABCKZ** via AFIH-ILOAN | Correct join path — confirmed in V2 blueprint |
| MATID Resolution | **/SCWM/BINMAT** bridge | MATID (RAW16) → MATNR via BINMAT.MATID = ORDIM_C.MATID |
| WM/EWM Detection | **/SCWM/TMAPSTLOC** | If plant exists in mapping table → EWM |
| RecordCount type | **abap.dec(10,0)** | Prevents CONVT_OVERFLOW when SADL aggregates SUM |
| OData Version | **V2 via @OData.publish** | SADL auto-publish, no manual SEGW needed |
| JOIN Strategy | **Existence-based** | Split EWM into 3 milestone joins to prevent row multiplication |

---

## 13. CONVT_OVERFLOW Fix Summary

**Problem:** JOINs to EWM/WM tables return ALL historical tasks per material, multiplying rows from 100k to 10+ billion.

**Fix:** 
1. Split single EWM join into 3 milestone-specific joins (NPB, RECEIVED, TR_REQUEST)
2. Change `RecordCount` from `cast(1 as abap.int4)` to `cast(1 as abap.dec(10,0))`
3. Add default year filter (PeriodYear = current year) in SVOpenItems selection variant

**Result:** 1 reservation item = ~1 row (not 100+ duplicates)
