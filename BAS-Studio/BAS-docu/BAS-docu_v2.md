# BAS Implementation Documentation — JIP Milestone Aging Dashboard V4

**Version:** 2.0
**Date:** 2026-03-20
**App ID:** `com.sap.jipv4.zjipv4aging`
**OData Service:** `ZC_JIPV4_AGING_CDS` (OData V2)
**BSP App Name:** `ZJIPV4_AG_OVP`
**PRD Source:** `PRD_NewBP_JIP_V4_Versi5.md`

---

## Changelog from v1.0

| # | Change | File(s) | Description |
|---|--------|---------|-------------|
| 1 | **Card 01 chart redesign** | `ZE_JIPV4_AGING.asddlx`, `manifest.json` | Changed from `BAR` to `BAR_STACKED` with ActivityType as series dimension — now shows JIP per Plant stacked by Activity Type (USW, SER, OVH, ADD) |
| 2 | **Card 03 renamed** | `i18n.properties` | Title changed from "Aging per Plant" → "Historical Aging per Plant", subtitle → "Monthly OK / 60+ / 70+" |
| 3 | **Card 04 chart redesign** | `ZE_JIPV4_AGING.asddlx`, `manifest.json`, `i18n.properties` | Changed from simple `BAR` by ActivityType to `BAR_STACKED` with PeriodMonth + ActivityType — title → "Activity Type by Plant" |
| 4 | **Card 07 redesign** | `manifest.json`, `i18n.properties` | Changed from generic "JIP Parts Detail" table to "Total Aging Table" (Plant × Month pivot view), sorted by Plant, uses SVOpenItems filter |
| 5 | **Card 08 redesign** | `manifest.json`, `i18n.properties` | Changed from "Critical Aging Items" list card to "Aging by Activity Type" table card (Activity × Month view), sorted by ActivityType, uses SVOpenItems filter |
| 6 | **SVOpenItems added** to Card 03, Card 06 | `manifest.json` | Added `selectionAnnotationPath` to exclude GI-completed items from all chart/table cards |
| 7 | **Navigation enabled** on Card 01, Card 03, Card 06 | `manifest.json` | Added `navigation: dataPointNav` and `identificationAnnotationPath` for drill-down |
| 8 | **NEW: ZI_JIPV4_EWM_MilestoneAgg** | `ZI_JIPV4_EWM_MilestoneAgg.asddls` | Classic CDS view (SQL: `ZVIJIPEWMAGG`). Joins `/scwm/ordim_c` + `/scwm/binmat`, GROUP BY `matnr` + `procty` → 1 row per material per process type. Exposes `MaterialNumber`, `ProcessType`, `ConfirmedAt`, `WarehouseNumber`. |
| 9 | **NEW: ZI_JIPV4_WM_MilestoneAgg** | `ZI_JIPV4_WM_MilestoneAgg.asddls` | Classic CDS view (SQL: `ZVIJIPWMAGG`). Joins `ltap` + `ltak`, GROUP BY `werks` + `matnr` + `bwlvs` → 1 row per plant+material per movement type. Exposes `Plant`, `MaterialNumber`, `MovementType`, `WarehouseNumber`, `TOCreationDate`, `ConfirmationDate`. |
| 10 | **REPLACE: ZI_JIPV4_PartsComposite** | `ZI_JIPV4_PartsComposite.asddls` | Complete rewrite with separated WM/EWM architecture. 3 WM joins (919=TR, 997=RCV, 994=NPB) + 3 EWM joins (S919=TR, S997=RCV, S994=NPB) — all 1:1 via aggregated views. Milestone logic uses `PM.WarehouseNumber` to route WM vs EWM. `RecordCount` changed to `abap.dec(10,0)`. Removed `WM_TRNumber`, `EWM_WTNumber` (CDS doesn't allow `cast` inside `MAX`). |
| 11 | **UPDATE: ZC_JIPV4_AGING** | `ZC_JIPV4_AGING.asddls` | Removed `WM_TRNumber` and `EWM_WTNumber` fields (no longer in composite). |
| 12 | **UPDATE: ZI_JIPV4_GoodsMovement** | `ZI_JIPV4_GoodsMovement.asddls` | Removed `cast` on `mblnr`, added `zeile` as key, removed `cancelled = ''` filter to include all Z26 documents. |
| 13 | **UPDATE: metadata.xml** | `webapp/localService/mainService/metadata.xml` | Removed `WM_TRNumber` and `EWM_WTNumber` properties from local OData metadata mock. |
| 14 | **FIX: WorkOrderNumber filter** | `ZI_JIPV4_Reservation.asddls`, `ZI_JIPV4_WorkOrder.asddls`, `ZI_JIPV4_GoodsMovement.asddls`, `metadata.xml` | Removed `cast(aufnr as abap.char(12))` to preserve native AUFNR domain with ALPHA conversion exit → OData auto-generates `sap:display-format="NonNegative"` → filter auto-pads leading zeros (e.g. `51365300` → `000051365300`). |
| 15 | **ADD: WorkOrderNumber to filter bar** | `ZE_JIPV4_AGING.asddlx` | Added `@UI.selectionField: [{ position: 55 }]` to WorkOrderNumber — now 10 filters in global filter bar. |

---

## 1. Overview

SAP Fiori Overview Page (OVP) application for JIP Parts Milestone Aging monitoring. Displays 8 interactive dashboard cards with global filter bar. Updated to match PRD v5 business process requirements.

### Dashboard Layout (PRD v5)

```
╔══════════════════════════════╦═══════════════════════════╦══════════════════════════╗
║  CARD 01                     ║  CARD 02                  ║  CARD 03                 ║
║  Total JIP per Plant         ║  Historical JIP           ║  Historical Aging        ║
║  [BAR STACKED by Activity]   ║  [STACKED COLUMN]         ║  per Plant               ║
║                              ║  OK / 60+ / 70+           ║  [STACKED COLUMN]        ║
╠══════════════════════════════╬═══════════════════════════╬══════════════════════════╣
║  CARD 04                     ║  CARD 05                  ║  CARD 06                 ║
║  Activity Type by Plant      ║  Monthly Trend            ║  Avg Aging vs Target     ║
║  [BAR STACKED by Activity]   ║  [STACKED COLUMN]         ║  [COMBINATION bar+line]  ║
╠══════════════════════════════╩═══════════════════════════╬══════════════════════════╣
║  CARD 07                                                 ║  CARD 08                 ║
║  Total Aging Table (Plant × Month)                       ║  Aging by Activity       ║
║  [TABLE]                                                 ║  × Month [TABLE]         ║
╚══════════════════════════════════════════════════════════╩══════════════════════════╝
```

---

## 2. Files Modified (v2.0)

| File | Changes in v2.0 |
|------|-----------------|
| `webapp/manifest.json` | Card 01/03/06 added navigation+SVOpenItems; Card 07 changed to Plant×Month table; Card 08 changed to Activity×Month table |
| `webapp/i18n/i18n.properties` | Card 03/04/07/08 titles updated; Card 01/03/04/07/08 subtitles updated |
| `ZE_JIPV4_AGING.asddlx` (backend MDE) | Card 01 chart → `BAR_STACKED` with ActivityType series; Card 04 chart → `BAR_STACKED` with PeriodMonth+ActivityType |
| `webapp/annotations/annotation.xml` | No changes — 3 SVs unchanged |

---

## 3. Card Configuration Summary (v2.0)

| # | Card ID | Template | Chart Type | Selection Variant | Key Qualifier | Change |
|---|---------|----------|-----------|-------------------|---------------|--------|
| 01 | `card01_JIPPerPlant` | `charts.analytical` | **BarStacked** | SVOpenItems | `ChartJIPPerPlant` | **Chart → BAR_STACKED** |
| 02 | `card02_HistoricalJIP` | `charts.analytical` | ColumnStacked | SVOpenItems | `ChartHistoricalJIP` | — |
| 03 | `card03_AgingPerPlant` | `charts.analytical` | ColumnStacked | **SVOpenItems** | `ChartAgingPerPlant` | **+SVOpenItems, +nav** |
| 04 | `card04_ActivityBreakdown` | `charts.analytical` | **BarStacked** | SVOpenItems | `ChartActivityBreakdown` | **Chart → BAR_STACKED** |
| 05 | `card05_MonthlyTrend` | `charts.analytical` | ColumnStacked | SVOpenItems | `ChartMonthlyTrend` | — |
| 06 | `card06_AvgAging` | `charts.analytical` | Combination | **SVOpenItems** | `ChartAvgAgingWithTarget` | **+SVOpenItems, +nav** |
| 07 | `card07_AgingTable` | **`table`** | Table | **SVOpenItems** | `DefaultSort` / `LineItem` | **Redesigned** |
| 08 | `card08_ActivityAgingTable` | **`table`** | Table | **SVOpenItems** | `PVChartActivity` / `LineItem` | **Redesigned** |

---

## 4. Card Details — PRD v5 Mapping

### Card 01 — Total JIP per Plant
- **Type:** Horizontal Bar Stacked
- **X-Axis (Category):** Plant (BDI, BEK, BGL, BHT, BJM, BKI, BLP, BNT)
- **Stack (Series):** ActivityType (USW, SER, OVH, ADD)
- **Measure:** RecordCount (count of JIP parts)
- **Filter:** SVOpenItems (CurrentMilestone ≠ GI)
- **Shows:** How many JIP parts at each plant, broken by activity type

### Card 02 — Historical JIP ALL Plants
- **Type:** Stacked Column
- **X-Axis:** PeriodMonth (Jan-Dec)
- **Stack:** AgingBucket (OK=Green, 60+=Yellow, 70+=Red)
- **Measure:** RecordCount
- **Filter:** SVOpenItems
- **Shows:** Total JIP across all plants colored by aging bucket

### Card 03 — Historical Aging per Plant
- **Type:** Stacked Column
- **X-Axis:** PeriodMonth (Jan-Dec)
- **Stack:** AgingBucket (OK, 60+, 70+)
- **Measure:** RecordCount
- **Filter:** SVOpenItems + Plant filter in global filter bar
- **Shows:** Monthly aging trend for a specific plant with color buckets

### Card 04 — Activity Type by Plant
- **Type:** Horizontal Bar Stacked
- **X-Axis:** PeriodMonth (Jan-Dec)
- **Stack:** ActivityType (ADD, OVH, SER, USW, etc.)
- **Measure:** RecordCount
- **Filter:** SVOpenItems
- **Shows:** JIP parts stacked by activity type per month

### Card 05 — Monthly Trend by Activity
- **Type:** Stacked Column
- **X-Axis:** PeriodMonth (Jan-Dec)
- **Stack:** ActivityType
- **Measure:** RecordCount
- **Filter:** SVOpenItems
- **Shows:** Monthly JIP volume trend by activity type

### Card 06 — Average Aging vs Target
- **Type:** Combination (Bar + Line)
- **X-Axis:** PeriodMonth
- **Bars:** AgingRelease (actual avg aging days)
- **Line:** TargetAgingDays (target per Activity Type, default 15 days)
- **Filter:** SVOpenItems
- **Shows:** Actual aging compared against fixed target

### Card 07 — Total Aging Table
- **Type:** Table
- **View:** Plant × Month pivot format
- **Sort:** Plant ascending
- **Filter:** SVOpenItems
- **Shows:** Count of JIP parts per Plant per Month
- **Example:** BLP | Jan=50 | Feb=713 | Mar=0 | ... | Dec=338

### Card 08 — Aging by Activity Type
- **Type:** Table
- **View:** Plant + Activity Type × Month format
- **Sort:** ActivityType ascending
- **Filter:** SVOpenItems
- **Shows:** Count per Plant + Activity Type per Month
- **Example:** BLP/ADD | Jan=0 | ... | Dec=1014

---

## 5. Selection Variants (annotation.xml) — Unchanged

| Qualifier | Purpose | Filter Logic |
|-----------|---------|-------------|
| `SVOpenItems` | Exclude GI-completed parts | `CurrentMilestone ≠ 'GI'` (Exclude) |
| `SVCriticalAging` | Show only critical aging (60+/70+) | `AgingBucket ≠ 'OK'` (Exclude OK) |
| `SVEWMOnly` | Show only EWM-managed plants | `WmEwmType = 'EWM'` (Include) |

---

## 6. Global Filter Bar (9 Filters)

Defined in backend MDE `ZE_JIPV4_AGING` via `@UI.selectionField`:

| # | Filter | Field | Position |
|---|--------|-------|----------|
| 1 | Plant | Plant | 10 |
| 2 | Activity Type | ActivityType | 20 |
| 3 | Aging Bucket | AgingBucket | 30 |
| 4 | WM/EWM Type | WmEwmType | 40 |
| 5 | Warehouse Number | WarehouseNumber | 50 |
| 6 | **Work Order** | **WorkOrderNumber** | **55** |
| 7 | Current Milestone | CurrentMilestone | 60 |
| 8 | Period Year | PeriodYear | 65 |
| 9 | ABC Indicator | ABCIndicator | 70 |
| 10 | Period Month | PeriodMonth | 80 |

---

## 7. Backend MDE Chart Changes (v2.0)

### ChartJIPPerPlant (Card 01)

**Before (v1.0):**
```
chartType: #BAR
dimensions: ['Plant']
```

**After (v2.0):**
```
chartType: #BAR_STACKED
dimensions: ['Plant', 'ActivityType']
dimensionAttributes: [
  { dimension: 'Plant', role: #CATEGORY },
  { dimension: 'ActivityType', role: #SERIES }
]
```

### ChartActivityBreakdown (Card 04)

**Before (v1.0):**
```
chartType: #BAR
dimensions: ['ActivityType']
```

**After (v2.0):**
```
chartType: #BAR_STACKED
dimensions: ['PeriodMonth', 'ActivityType']
dimensionAttributes: [
  { dimension: 'PeriodMonth', role: #CATEGORY },
  { dimension: 'ActivityType', role: #SERIES }
]
```

---

## 8. Annotation Source Matrix

| Annotation | Source | File |
|-----------|--------|------|
| `@UI.chart` (6 charts) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.presentationVariant` (5 PVs) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.dataPoint` (4 DPs) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.lineItem` (20 columns) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.selectionField` (9 filters) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.headerInfo` | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.identification` | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.fieldGroup` (5 groups) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| **`@UI.selectionVariant`** (3 SVs) | **Local** | **`annotations/annotation.xml`** |

---

## 9. Milestone Flow Reference (from PRD v5)

```
PENDING → TR_REQUEST → RECEIVED → NPB → GI (completed — excluded)
```

Priority (highest wins): `GI > NPB > RECEIVED > TR_REQUEST > WM_CONFIRMED > PENDING`

### Aging Calculations

| Aging | From | To |
|-------|------|-----|
| Release | SDH Approval (ZTWOAPPR) | WO Release (AFKO-FTRMI) |
| TR/TO | TO Created / S919 Confirmed | 997 Confirmed / S997 Confirmed |
| NPB | 997 Confirmed / S997 | 994 Confirmed / S994 |
| GI | 994 Confirmed / S994 | MATDOC BUDAT (Z26) |

### Aging Buckets

| Bucket | Condition | Color | Criticality |
|--------|-----------|-------|-------------|
| OK | < 60 days | Green | 3 |
| 60+ | ≥ 60 and < 70 days | Yellow | 2 |
| 70+ | ≥ 70 days | Red | 1 |

---

## 10. Deployment Configuration

| Property | Value |
|----------|-------|
| Target | ABAP Repository (BSP) |
| Destination | `UTD030_new` |
| BSP App | `ZJIPV4_AG_OVP` |
| Package | `$TMP` |
| FLP Semantic Object | `JIPAging` |
| FLP Action | `display` |

---

## 11. Preview Commands

```bash
# Live backend data
npm run start

# Local with proxy to backend
npm run start-local

# Mock data (offline testing)
npm run start-mock

# Direct index (no FLP)
npm run start-noflp
```

---

## 12. Verification Checklist (v2.0)

### Card Rendering
- [ ] Card 01: Horizontal bar stacked by Activity Type per Plant
- [ ] Card 02: Stacked column by Aging Bucket (OK/60+/70+) per Month
- [ ] Card 03: Stacked column by Aging Bucket per Month (plant-filtered)
- [ ] Card 04: Horizontal bar stacked by Activity Type per Month
- [ ] Card 05: Stacked column by Activity Type per Month
- [ ] Card 06: Combination chart — bars (actual aging) + line (target)
- [ ] Card 07: Table sorted by Plant — shows Plant × Month counts
- [ ] Card 08: Table sorted by Activity — shows Activity × Month counts

### Filters
- [ ] Global filter bar shows 10 filters (Plant, ActivityType, AgingBucket, WmEwmType, WarehouseNumber, WorkOrderNumber, CurrentMilestone, PeriodYear, ABCIndicator, PeriodMonth)
- [ ] WorkOrderNumber filter accepts input without leading zeros (auto-padded via NonNegative)
- [ ] SVOpenItems excludes GI items from Cards 01-08
- [ ] Plant filter changes Card 03 data (per-plant view)

### Data
- [ ] AgingBucket criticality colors: Green=OK, Yellow=60+, Red=70+
- [ ] RecordCount aggregates correctly (no CONVT_OVERFLOW)
- [ ] Card 06 target line shows 15 days (flat reference line)

### Deployment

- [ ] `manifest.json` — Valid JSON, 8 cards
- [ ] Preview working in BAS
- [ ] Deployed to ABAP repository
- [ ] FLP tile functional

---

## 13. BAS IDE Troubleshooting

### Schema Validation Warning

If you see this warning in BAS:

```text
Unable to load schema from 'manifest-schema://local': No content. (severity: warning)
```

**Cause:** SAP Fiori Tools extension couldn't load its internal manifest schema for IntelliSense. This is a **BAS IDE cosmetic issue only** — it does NOT affect app runtime or deployment.

**Solutions:**
1. **Ignore it** — The app runs normally. Severity 4 = Warning, not Error.
2. **Reload BAS window** — `Ctrl+Shift+P` → `Developer: Reload Window` to restart the extension host.
3. **Continue with `npm run start`** — The dashboard will render correctly despite the warning.
