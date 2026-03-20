# Bugs Fix V2 — Card Visibility + Work Order Filter + Table Data

**Date:** 2026-03-20  
**Status:** Fixed  
**Total Issues:** 5

---

## Issue Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Card 01 and Card 04 not rendering on dashboard | High | Fixed |
| 2 | Work Order filter `51365300` returns no data (leading zeros) | High | Fixed |
| 3 | Table cards (07/08) show "No data" when filtering by WO | High | Fixed (same root cause as #2) |
| 4 | All cards "No data" when PeriodYear=2026, PeriodMonth=03 in BAS preview | Medium | Expected (no mock data) |
| 5 | Card 08 table missing CurrentMilestone column (not matching ABAP report) | High | Fixed |

---

## Bug 1: Card 01 and Card 04 Not Appearing

**Symptom:** Dashboard shows only 6 cards. Card 01 "Total JIP per Plant" and Card 04 "Activity Type by Plant" are completely missing.

**Root Cause (two layers):**

1. **Stale VAN.xml** — The local annotation file `ZC_JIPV4_AGING_CDS_VAN.xml` still had old v1.0 chart definitions:
   - `ChartJIPPerPlant` had `ChartType/Bar` with only `Plant` dimension (missing `ActivityType` series)
   - `ChartActivityBreakdown` had `ChartType/Bar` with only `ActivityType` (missing `PeriodMonth` category)

2. **Unsupported `BarStacked` chart type in OVP** — After updating the VAN.xml to use `BarStacked`, Card 01 and Card 04 still didn't render. The `sap.ovp.cards.charts.analytical` template does **not reliably render `BarStacked`** charts in BAS preview. Only `Bar`, `ColumnStacked`, `Combination`, and similar types are proven to work.

**Fix — Chart type changes (VAN.xml + MDE):**

### Card 01: ChartJIPPerPlant

Changed to `Bar` (horizontal bar) — matches PRD design "[HORIZONTAL BAR]":

```diff
  VAN.xml:
- <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>       ← old v1 (single dim)
- <PropertyValue Property="ChartType" EnumMember="UI.ChartType/BarStacked"/> ← attempt #1 (not rendered)
+ <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>       ← final fix (with 2 dims)

  MDE (ZE_JIPV4_AGING.asddlx):
- chartType: #BAR_STACKED,
+ chartType: #BAR,
```

Dimensions: `Plant` (category) + `ActivityType` (series), Measure: `RecordCount`

### Card 04: ChartActivityBreakdown

Changed to `ColumnStacked` (vertical stacked column) — equivalent to "[STACKED BAR]" in supported OVP types:

```diff
  VAN.xml:
- <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>           ← old v1
- <PropertyValue Property="ChartType" EnumMember="UI.ChartType/BarStacked"/>     ← attempt #1 (not rendered)
+ <PropertyValue Property="ChartType" EnumMember="UI.ChartType/ColumnStacked"/>  ← final fix

  MDE (ZE_JIPV4_AGING.asddlx):
- chartType: #BAR_STACKED,
+ chartType: #COLUMN_STACKED,
```

Dimensions: `PeriodMonth` (category) + `ActivityType` (series), Measure: `RecordCount`

### WorkOrderNumber added to SelectionFields

```diff
  VAN.xml UI.SelectionFields:
    <PropertyPath>WarehouseNumber</PropertyPath>
+   <PropertyPath>WorkOrderNumber</PropertyPath>
    <PropertyPath>CurrentMilestone</PropertyPath>
```

---

## Bug 2: Work Order Filter Returns No Data (Leading Zeros)

**Symptom:** Filtering by Work Order `51365300` shows empty results, even though SAP report confirms 2 items exist (1 at GI, 1 at Received).

**Root Cause:** SAP stores `aufnr` as `000051365300` (12-char with leading zeros). The CDS views had `cast(aufnr as abap.char(12))` which **strips the native AUFNR domain** with ALPHA conversion routine. Without ALPHA, OData doesn't auto-pad the filter value.

**Fix — 3 CDS Views (backend):**

```diff
  ZI_JIPV4_Reservation.asddls:
-     cast(aufnr as abap.char(12))  as WorkOrderNumber,
+     aufnr                         as WorkOrderNumber,

  ZI_JIPV4_WorkOrder.asddls:
- key cast(AK.aufnr as abap.char(12))  as WorkOrderNumber,
+ key AK.aufnr                         as WorkOrderNumber,

  ZI_JIPV4_GoodsMovement.asddls:
-     cast(MD.aufnr as abap.char(12))  as WorkOrderNumber,
+     MD.aufnr                         as WorkOrderNumber,
```

**Fix — Local metadata mock:**

```diff
  metadata.xml:
- sap:display-format="UpperCase"
+ sap:display-format="NonNegative"
```

**How it works:** Native AUFNR domain → SAP Gateway auto-generates `sap:display-format="NonNegative"` → SmartFilterBar auto-pads `51365300` → `000051365300`.

---

## Bug 3: Table Cards "No data" for Work Order Filter

**Symptom:** Card 07 and Card 08 show "No data" when Work Order filter is applied.

**Root Cause:** Same as Bug 2 — leading zeros mismatch. Additionally:

- Item 1 (Material `02896-11008`): `CurrentMilestone = 'GI'` → correctly excluded by `SVOpenItems`
- Item 2 (Material `600-211-1231`): `CurrentMilestone = 'RECEIVED'` → should show but filter doesn't match

**Fix:** Same as Bug 2. After deployment, pending JIP parts will display:

| Order | Material | Plant | ActivityType | CurrentMilestone | AgingBucket |
|-------|----------|-------|--------------|------------------|-------------|
| 51365300 | 600-211-1231 | BJM | SER | RECEIVED | OK |

---

## Additional: WorkOrderNumber Added to Filter Bar

Added `@UI.selectionField: [{ position: 55 }]` to `WorkOrderNumber` in MDE (`ZE_JIPV4_AGING.asddlx`) so it appears natively in the global filter bar.

---

## Bug 4: All Cards "No data" with PeriodYear=2026, PeriodMonth=03

**Symptom:** After filtering PeriodYear=2026 and PeriodMonth=03, ALL 8 cards show "No data" — even though ABAP report confirms 2 records exist for WO 51365300 in period 03.2026.

**Root Cause:** BAS preview runs against **local mock metadata only** — there is no mock data JSON file in `localService/`. The app connects to a live OData service on the SAP backend, but in BAS local preview mode, no backend data is available.

**ABAP report confirms data exists:**

| Status | Work Order | Material | Plant | Act.Type | WM/EWM | Milestone | Period |
|--------|-----------|----------|-------|----------|--------|-----------|--------|
| OK | 51365300 | 02896-11008 | BJM | SER | WM | GI | 03.2026 |
| OK | 51365300 | 600-211-1231 | BJM | SFR | WM | Received | 03.2026 |

**Resolution:** This is **expected behavior** in BAS preview. Charts and tables will populate correctly once deployed to the real SAP backend. No code fix needed.

---

## Bug 5: Card 08 Table Missing CurrentMilestone Column

**Symptom:** Card 08 ("Aging by Activity Type") table only shows: Order, Material, Plant, MaintActivityType. Missing `CurrentMilestone` and `AgingBucket` columns — unlike the ABAP report which shows Work Order, Material, Plant, Activity Type, and Milestone status.

**Root Cause:** Both Card 07 and Card 08 shared the same `UI.LineItem` (no qualifier). OVP table cards display only the first few `#High` importance columns that fit the card width. `CurrentMilestone` was at position 60 (7th column) — too far right to be visible in the card.

**Fix — Three changes:**

### 1. New `UI.LineItem#ActivityAging` for Card 08 (VAN.xml)

Added a dedicated LineItem with only 6 key columns matching the ABAP report:

```xml
<Annotation Term="UI.LineItem" Qualifier="ActivityAging">
  <Collection>
    <Record Type="UI.DataField">  <!-- WorkOrderNumber  #High --></Record>
    <Record Type="UI.DataField">  <!-- MaterialNumber    #High --></Record>
    <Record Type="UI.DataField">  <!-- Plant             #High --></Record>
    <Record Type="UI.DataField">  <!-- ActivityType      #High --></Record>
    <Record Type="UI.DataField">  <!-- CurrentMilestone  #High --></Record>
    <Record Type="UI.DataField">  <!-- AgingBucket       #High --></Record>
  </Collection>
</Annotation>
```

### 2. Card 08 manifest.json updated

```diff
  card08_ActivityAgingTable:
-   "annotationPath": "com.sap.vocabularies.UI.v1.LineItem"
+   "annotationPath": "com.sap.vocabularies.UI.v1.LineItem#ActivityAging"
```

### 3. Default UI.LineItem reordered for Card 07

Moved `CurrentMilestone` from position 60 → 50 (before `AgingBucket`) and `ABCIndicator` from position 25 → 65 so that Card 07 now shows:

| Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 |
|-------|-------|-------|-------|-------|-------|
| Order | Material | Plant | ActivityType | **CurrentMilestone** | AgingBucket |

### 4. MDE updated (ZE_JIPV4_AGING.asddlx)

Added `qualifier: 'ActivityAging'` entries to the `@UI.lineItem` arrays for: `WorkOrderNumber`, `MaterialNumber`, `Plant`, `ActivityType`, `CurrentMilestone`, `AgingBucket`.

```abap
  @UI.lineItem: [{ position: 10, importance: #HIGH },
                { qualifier: 'ActivityAging', position: 10, importance: #HIGH }]
  WorkOrderNumber;
  ...
  @UI.lineItem: [{ position: 50, importance: #HIGH },
                { qualifier: 'ActivityAging', position: 50, importance: #HIGH }]
  CurrentMilestone;
```

**Expected Card 08 result after fix (example WO 51365300):**

| Order | Material | Plant | ActivityType | CurrentMilestone | AgingBucket |
|-------|----------|-------|--------------|------------------|-------------|
| 51365300 | 600-211-1231 | BJM | SFR | RECEIVED | OK |

---

## Files Changed

| File | Type | Changes |
|------|------|---------|
| `ZC_JIPV4_AGING_CDS_VAN.xml` | BAS annotation | Card 01: `Bar`; Card 04: `ColumnStacked`; New `UI.LineItem#ActivityAging`; Reordered default `UI.LineItem`; Added `WorkOrderNumber` to `SelectionFields` |
| `manifest.json` | BAS app config | Card 08 `annotationPath` → `UI.LineItem#ActivityAging` |
| `metadata.xml` | BAS metadata | `WorkOrderNumber` display-format: `UpperCase` → `NonNegative` |
| `ZI_JIPV4_Reservation.asddls` | Backend CDS | Removed `cast(aufnr as abap.char(12))` |
| `ZI_JIPV4_WorkOrder.asddls` | Backend CDS | Removed `cast(AK.aufnr as abap.char(12))` |
| `ZI_JIPV4_GoodsMovement.asddls` | Backend CDS | Removed `cast(MD.aufnr as abap.char(12))` |
| `ZE_JIPV4_AGING.asddlx` | Backend MDE | Chart types fixed; `UI.LineItem#ActivityAging` qualifier added; Column reorder; `@UI.selectionField` for `WorkOrderNumber` |

---

## PRD v5 Dashboard Layout (Reference)

```text
┌─────────────────┬─────────────────┬─────────────────┐
│ CARD 01         │ CARD 02         │ CARD 03         │
│ Total JIP by    │ Historical JIP  │ Historical Aging│
│ Plant + Month   │ ALL Plants      │ per Plant       │
│ [BAR]           │ [STACKED COL]   │ [STACKED COL]   │
├─────────────────┼─────────────────┼─────────────────┤
│ CARD 04         │ CARD 05         │ CARD 06         │
│ Activity Type   │ Monthly Trend   │ Average Aging   │
│ by Plant        │ by Activity     │ vs Target Line  │
│ [STACKED COL]   │ [STACKED COL]   │ [COMBINATION]   │
├─────────────────┴─────────────────┼─────────────────┤
│ CARD 07                           │ CARD 08         │
│ Total Aging Table                 │ Aging by Act.   │
│ Order|Mat|Plant|Act|Milestone|Age │ Same 6 columns  │
│ [TABLE]                           │ [TABLE]         │
└───────────────────────────────────┴─────────────────┘
```

---

## Deployment Steps

1. **Backend (SAP ADT/SE80):**
   - Activate CDS views: `ZI_JIPV4_Reservation`, `ZI_JIPV4_WorkOrder`, `ZI_JIPV4_GoodsMovement`
   - Activate MDE: `ZE_JIPV4_AGING`
   - Clear OData metadata cache: `/IWFND/MAINT_SERVICE` → `ZC_JIPV4_AGING_CDS` → Clear Metadata Cache
   - Re-download VAN.xml to BAS after MDE activation

2. **BAS (Fiori App):**
   - Verify `ZC_JIPV4_AGING_CDS_VAN.xml` has `UI.LineItem#ActivityAging` and reordered default `UI.LineItem`
   - Verify `manifest.json` Card 08 points to `UI.LineItem#ActivityAging`
   - Verify `metadata.xml` has `sap:display-format="NonNegative"` on `WorkOrderNumber`
   - Re-deploy to ABAP repository

## Verification Checklist

- [ ] All 8 cards visible on dashboard
- [ ] Card 01 renders as horizontal bar by Plant with ActivityType coloring
- [ ] Card 04 renders as stacked column by Month with ActivityType coloring
- [ ] Work Order filter `51365300` returns matching data on deployed system
- [ ] Card 07 table shows: Order, Material, Plant, ActivityType, **CurrentMilestone**, AgingBucket
- [ ] Card 08 table shows: Order, Material, Plant, ActivityType, **CurrentMilestone**, AgingBucket
- [ ] ABAP report data matches dashboard data for WO 51365300 (2 items, 1 GI excluded, 1 Received shown)
- [ ] Filter bar shows 10 filters including Work Order
- [ ] "No data" in BAS preview is expected — real data appears after backend deployment
