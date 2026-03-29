# Bugs Fix V5 — Card 08 Enhancement: Add "Aging Milestone" Column

**Date:** 2026-03-27
**Status:** ✅ Completed
**Card Affected:** Card 08 — "Total Aging Parts" (`card08_ActivityAgingTable`)
**Source:** User request — show current milestone aging days in the table

---

## Summary of Change

Add a new column **"Aging Milestone"** to Card 08 that shows **days between consecutive milestones** (e.g., NPB = RCV Date → NPB Date = 6 days).

### Example from Report

| Order    | Material     | Plant | Activity Type | Milestone | Aging Milestone |
|----------|--------------|-------|---------------|-----------|-----------------|
| 51365300 | 600-211-1231 | BJM   | SER           | NPB       | 6               |

The value **6** = `NPB ConfirmationDate (26.03.2026)` − `RCV ConfirmationDate (20.03.2026)`.

---

## New Column Definition

| Property             | Value                                                                  |
|----------------------|------------------------------------------------------------------------|
| Column Label         | `Aging Milestone`                                                      |
| Field Name           | `CurrentAging`                                                         |
| Type                 | `Edm.Decimal (10, 0)` — **NOT** `(10,2)`, see error note below        |
| Logic                | Days **between consecutive milestones** (not milestone to today)       |
| Position             | After `CurrentMilestone` column                                        |
| Card 08 Column Order | Order → Material → Plant → Activity Type → Milestone → Aging Milestone |

---

## Milestone Date Logic (for `CurrentAging`)

Days between the **current milestone date** and the **previous milestone date**:

```text
GI          = dats_days_between(NPB Date, GI Date)
NPB         = dats_days_between(RCV Date, NPB Date)
RECEIVED    = dats_days_between(TR Date, RCV Date)
TR_REQUEST  = dats_days_between(Release Date, TR Date)
PENDING     = dats_days_between(Release Date, today)
```

Fallback: if the previous milestone date is null, the chain falls through to the next available date (e.g., if NPB has no RCV, it tries TR, then Release).

---

## Files to Change

### 1. `ZI_JIPV4_PartsComposite.asddls` (Backend CDS — Basic View)

Add `CurrentAging` field after `TargetAgingDays`:

```abap
-- Aging at Current Milestone: days between consecutive milestones
-- GI: NPB→GI | NPB: RCV→NPB | RCV: TR→RCV | TR: Release→TR | PENDING: Release→today
cast( case
        when GI.PostingDate is not null and WM_NPB.ConfirmationDate is not null
          then dats_days_between(WM_NPB.ConfirmationDate, GI.PostingDate)
        when GI.PostingDate is not null and WO.WOReleaseDate is not null
          then dats_days_between(WO.WOReleaseDate, GI.PostingDate)
        when WM_NPB.ConfirmationDate is not null and WM_RCV.ConfirmationDate is not null
          then dats_days_between(WM_RCV.ConfirmationDate, WM_NPB.ConfirmationDate)
        when WM_NPB.ConfirmationDate is not null and WM_TR.TOCreationDate is not null
          then dats_days_between(WM_TR.TOCreationDate, WM_NPB.ConfirmationDate)
        when WM_NPB.ConfirmationDate is not null and WO.WOReleaseDate is not null
          then dats_days_between(WO.WOReleaseDate, WM_NPB.ConfirmationDate)
        when WM_RCV.ConfirmationDate is not null and WM_TR.TOCreationDate is not null
          then dats_days_between(WM_TR.TOCreationDate, WM_RCV.ConfirmationDate)
        when WM_RCV.ConfirmationDate is not null and WO.WOReleaseDate is not null
          then dats_days_between(WO.WOReleaseDate, WM_RCV.ConfirmationDate)
        when WM_TR.TOCreationDate is not null and WO.WOReleaseDate is not null
          then dats_days_between(WO.WOReleaseDate, WM_TR.TOCreationDate)
        when WO.WOReleaseDate is not null
          then dats_days_between(WO.WOReleaseDate, $session.system_date)
        else 0
      end as abap.dec(10,0) )              as CurrentAging,
```

**Important notes:**

- **Calculation logic:** `CurrentAging` = days **between consecutive milestones** (e.g. NPB = RCV Date → NPB Date = 6 days), NOT days from milestone to today.
- Example: material `600-211-1231`, WO `51365300` — `RCV Date 20.03.2026` → `NPB Date 26.03.2026` = **6 days**.
- Use `abap.dec(10,0)` — NOT `dec(10,2)`. `dats_days_between()` returns `INT4`; casting to `dec(10,2)` triggers an intermediate CHAR conversion overflow → error `CAST from DEC to CHAR: target type length too small` (DDLS 346).
- `EWM_*.ConfirmedAt` fields are `Decimal`/timestamp type — **NOT** `abap.dats`. EWM plants fall through to WM dates or `WO.WOReleaseDate`.
- PENDING milestone (no WM dates): uses `WO.WOReleaseDate → $session.system_date` (days waiting since release).

### 2. `ZC_JIPV4_AGING.asddls` (Consumption View)

Expose the new field with SUM aggregation:

```abap
@DefaultAggregation: #SUM
CurrentAging,
```

### 3. `ZE_JIPV4_AGING.asddlx` (Backend MDE — ADT)

Added `ActivityAging` qualifier to `WorkOrderNumber` and `MaterialNumber` (they were missing).
Added `CurrentAging` field. **Removed** `PeriodMonth` and `RecordCount` from `ActivityAging`.

```abap
// --- WorkOrderNumber ---
@UI.lineItem: [{ position: 10, importance: #HIGH },
              { qualifier: 'ActivityAging', position: 10, importance: #HIGH, label: 'Order' }]

// --- MaterialNumber ---
@UI.lineItem: [{ position: 20, importance: #HIGH },
              { qualifier: 'ActivityAging', position: 15, importance: #HIGH, label: 'Material' }]

// --- CurrentAging ---
@UI.lineItem: [{ qualifier: 'ActivityAging', position: 60, importance: #HIGH, label: 'Aging Milestone' }]
@UI.dataPoint: { title: 'Aging Milestone (Days)' }
CurrentAging;
```

### 4. `webapp/localService/mainService/metadata.xml`

Added `CurrentAging` property to `ZC_JIPV4_AGINGType`:

```xml
<Property Name="CurrentAging" Type="Edm.Decimal" Precision="10" Scale="0"
          sap:label="Aging Milestone (Days)" sap:aggregation-role="measure"/>
```

> **Note:** Scale must be `0`, not `2`. This file is only used for mock mode. When proxied to the live backend, `$metadata` comes from the server.

### 5. `webapp/annotations/annotation.xml` (Local Annotation — Primary)

**Root cause of missing columns:** The OVP framework reads annotations from `annotation.xml`
for local preview. The old qualifier `AgingDetail` did not match the manifest's `ActivityAging`.

**Changes:**

- Replaced `LineItem#AgingDetail` with `LineItem#ActivityAging` (6 columns, i18n labels)
- Renamed Card 07 qualifier from `ActivityAging` → `ActivityAgingSummary` (to avoid duplicate)
- Commented out "Status" (`CurrentMilestone`) column from Card 07

```xml
<!-- Card 08: Total Aging Table — 6 columns -->
<Annotation Term="UI.LineItem" Qualifier="ActivityAging">
    <Collection>
        <!-- WorkOrderNumber, MaterialNumber, Plant, ActivityType, CurrentMilestone, CurrentAging -->
    </Collection>
</Annotation>
```

### 6. `webapp/localService/mainService/ZC_JIPV4_AGING_CDS_VAN.xml`

**Removed** `LineItem#ActivityAging` from VAN.xml — now owned by `annotation.xml` to avoid duplicate qualifier error.

### 7. `webapp/manifest.json`

- Card 07: `annotationPath` changed to `LineItem#ActivityAgingSummary`
- Card 08: Added `"addODataSelect": true` to force `$select` of `CurrentAging`

### 8. `webapp/i18n/i18n.properties`

Added missing i18n keys:

```properties
col_order=Order
col_material=Material
col_milestone=Milestone
col_agingMilestone=Aging Milestone
```

---

## Errors Encountered & Fixed

### Error 1: CAST from DEC to CHAR — target type length too small (DDLS 346)

- **Cause:** `cast(... as abap.dec(10,2))` — `dats_days_between()` returns INT4; casting to dec with scale triggers intermediate CHAR conversion overflow.
- **Fix:** Changed to `abap.dec(10,0)`.

### Error 2: Column CurrentAging is unknown

- **Cause:** `ZC_JIPV4_AGING` activated before `ZI_JIPV4_PartsComposite`.
- **Fix:** Activate composite view first, then consumption view.

### Error 3: Duplicate qualifier "UI.LineItem"

- **Cause:** Both `annotation.xml` Card 07 and Card 08 used qualifier `ActivityAging`. Also `VAN.xml` had a copy.
- **Fix:** Renamed Card 07 to `ActivityAgingSummary`; removed `ActivityAging` from VAN.xml.

### Error 4: Missing i18n keys

- **Cause:** Hardcoded label strings in `annotation.xml` instead of `{@i18n>...}` references.
- **Fix:** Added `col_order`, `col_material`, `col_milestone`, `col_agingMilestone` to `i18n.properties`.

### Error 5: Column value blank on dashboard (header visible)

- **Cause:** Backend OData gateway serving old `$metadata` without `CurrentAging`.
- **Fix:** Run `/IWFND/CACHE_CLEANUP` + `/IWBEP/CACHE_CLEANUP` on the backend.

---

## Verification Checklist

- [x] `CurrentAging` field appears in Card 08 table after `CurrentMilestone`
- [x] Value matches the report (NPB = 6 days for WO 51365300 / material 600-211-1231)
- [x] Column label shows "Aging Milestone"
- [x] Backend activation: `ZI_JIPV4_PartsComposite` → `ZC_JIPV4_AGING` → `ZE_JIPV4_AGING`
- [x] `/IWFND/CACHE_CLEANUP` + `/IWBEP/CACHE_CLEANUP` run
- [x] BAS preview (`npm run start`) shows correct value
- [x] Card 07 "Status" column removed (commented out)

---

## Implementation Order (Backend → Frontend)

1. **ADT:** Add `CurrentAging` CASE logic to `ZI_JIPV4_PartsComposite.asddls` → Activate
2. **ADT:** Add `CurrentAging` to `ZC_JIPV4_AGING.asddls` → Activate
3. **ADT:** Update `ZE_JIPV4_AGING.asddlx` MDE annotations → Activate
4. **SAP:** `/IWFND/CACHE_CLEANUP` + `/IWBEP/CACHE_CLEANUP`
5. **BAS:** Update `metadata.xml` — add `CurrentAging` property (Scale=0)
6. **BAS:** Update `annotation.xml` — add `LineItem#ActivityAging` with 6 columns + i18n
7. **BAS:** Remove `LineItem#ActivityAging` from `VAN.xml` (avoid duplicate)
8. **BAS:** Update `manifest.json` — Card 07 qualifier rename, Card 08 `addODataSelect`
9. **BAS:** Add i18n keys to `i18n.properties`
10. **BAS:** `npm run start` → verify Card 08 shows 6 columns, Card 07 has no "Status"
