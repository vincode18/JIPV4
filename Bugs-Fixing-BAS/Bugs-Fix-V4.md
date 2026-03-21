# Bugs Fix V4 — Card 06 "Pending Items by Activity" (Combination Chart)

**Date:** 2026-03-21  
**Status:** Implemented & Pushed to GitHub  
**Commit:** `14044d7` on `main` branch  
**Repo:** https://github.com/vincode18/JIPV4/tree/main

---

## Summary

Card 06 ("Pending Items by Activity") was showing a **blank content area** — no chart rendered despite having a valid card header. After extensive debugging, the root cause was identified and fixed across multiple layers (CDS, MDE, metadata, local annotations, manifest).

### Final Result

| Property | Value |
|----------|-------|
| Card Title | Pending Items by Activity |
| Chart Type | `#COMBINATION` (bars + line) |
| X-Axis (Dimension) | `ActivityType` (USW, MID, LOG, ADD, GPS, SER, OVH, etc.) |
| Bars (1st Measure) | `RecordCount` — count of pending parts per activity |
| Line (2nd Measure) | `TargetAgingDays` — fixed horizontal line at **15** for all activity types |
| Selection Variant | `SVOpenItems` (excludes GI-completed items) |

---

## Root Causes Found

### 1. Chart/PV Not in Backend MDE (PRIMARY)

**Problem:** `ChartPendingByActivity` and `PVPendingByActivity` only existed in the **local** `ZC_JIPV4_AGING_CDS_VAN.xml` file. When running against the live SAP backend, the OVP framework fetches annotations from the **backend MDE** (`ZE_JIPV4_AGING.asddlx`). Since those qualifiers didn't exist in the MDE, the card had no chart definition to render.

**Fix:** Added `ChartPendingByActivity` and `PVPendingByActivity` to `ZE_JIPV4_AGING.asddlx`.

### 2. Missing Aggregation Annotations in metadata.xml

**Problem:** `metadata.xml` was missing `sap:aggregation-role` annotations on measure and dimension properties, and `sap:semantics="aggregate"` on the EntitySet. OVP analytical cards require these to identify which properties are measures vs dimensions.

**Fix:** Added:
- `sap:aggregation-role="measure"` to `RecordCount`, `TargetAgingDays`, `AgingRelease`
- `sap:aggregation-role="dimension"` to `ActivityType`, `Plant`, `CurrentMilestone`, `AgingBucket`, `PeriodMonth`
- `sap:semantics="aggregate"` to the `ZC_JIPV4_AGING` EntitySet

### 3. TargetAgingDays Showing SUM Instead of Fixed 15

**Problem:** `TargetAgingDays` was annotated with `@DefaultAggregation: #SUM` in the CDS view. Since each row has `TargetAgingDays = 15`, grouping by ActivityType caused SUM (e.g., 378 rows x 15 = 5,670 instead of 15).

**Fix:** Changed to `@DefaultAggregation: #AVG` in `ZC_JIPV4_AGING.asddls`. Since every row is 15, `AVG(15, 15, 15, ...) = 15`.

### 4. Missing CDS Analytics Annotations

**Problem:** `ZC_JIPV4_AGING` consumption CDS view was missing `@Analytics.dataCategory: #CUBE` and `@DefaultAggregation` annotations, causing `RecordCount` to always show 1.

**Fix:** Added `@Analytics.dataCategory: #CUBE` at view level, `@DefaultAggregation: #SUM` on `RecordCount`, `@DefaultAggregation: #AVG` on `TargetAgingDays`.

---

## Files Changed

| File | Change |
|------|--------|
| `CDS-Views/ZE_JIPV4_AGING.asddlx` | Added `ChartPendingByActivity` (Combination) + `PVPendingByActivity` to MDE |
| `CDS-Views/ZC_JIPV4_AGING.asddls` | `@Analytics.dataCategory: #CUBE`, `@DefaultAggregation: #AVG` on TargetAgingDays |
| `webapp/localService/mainService/ZC_JIPV4_AGING_CDS_VAN.xml` | Card 06 Combination chart: RecordCount (bars) + TargetAgingDays (line) |
| `webapp/localService/mainService/metadata.xml` | `sap:aggregation-role` annotations + `sap:semantics="aggregate"` |
| `webapp/manifest.json` | Card 06 config: SVOpenItems, ChartPendingByActivity, PVPendingByActivity |
| `webapp/i18n/i18n.properties` | Card 06 title/subtitle labels |

---

## Detailed Code Changes

### MDE — ZE_JIPV4_AGING.asddlx

**New Chart:**
```abap
{
  qualifier: 'ChartPendingByActivity',
  title: 'Pending Items by Activity',
  chartType: #COMBINATION,
  dimensions: ['ActivityType'],
  measures: ['RecordCount', 'TargetAgingDays'],
  dimensionAttributes: [
    { dimension: 'ActivityType', role: #CATEGORY }
  ],
  measureAttributes: [
    {
      measure: 'RecordCount',
      role: #AXIS_1,
      asDataPoint: true
    },
    {
      measure: 'TargetAgingDays',
      role: #AXIS_1,
      asDataPoint: true
    }
  ]
}
```

**New PresentationVariant:**
```abap
{
  qualifier: 'PVPendingByActivity',
  text: 'Pending by Activity',
  sortOrder: [{ by: 'ActivityType', direction: #ASC }],
  visualizations: [{
    type: #AS_CHART,
    qualifier: 'ChartPendingByActivity'
  }]
}
```

### CDS — ZC_JIPV4_AGING.asddls

```abap
@Analytics.dataCategory: #CUBE

-- RecordCount: SUM (count of parts)
@DefaultAggregation: #SUM
RecordCount,

-- TargetAgingDays: AVG (fixed at 15 per activity)
@DefaultAggregation: #AVG
TargetAgingDays,
```

### Local Annotation — ZC_JIPV4_AGING_CDS_VAN.xml

```xml
<Annotation Term="UI.Chart" Qualifier="ChartPendingByActivity">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Pending Items by Activity"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Combination"/>
    <PropertyValue Property="Dimensions">
      <Collection>
        <PropertyPath>ActivityType</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="DimensionAttributes">
      <Collection>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="ActivityType"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Category"/>
        </Record>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="Measures">
      <Collection>
        <PropertyPath>RecordCount</PropertyPath>
        <PropertyPath>TargetAgingDays</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
        </Record>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="TargetAgingDays"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

### manifest.json — Card 06 Config

```json
"card06_PendingByActivity": {
  "model": "mainModel",
  "template": "sap.ovp.cards.charts.analytical",
  "settings": {
    "title": "{{card06_title}}",
    "subtitle": "{{card06_subtitle}}",
    "entitySet": "ZC_JIPV4_AGING",
    "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
    "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartPendingByActivity",
    "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVPendingByActivity"
  }
}
```

---

## Key Learnings

1. **Backend MDE takes priority:** When running against a live SAP OData service, annotations from the backend MDE override local annotation files. Chart/PV qualifiers MUST exist in the MDE.
2. **Combination chart measure order matters:** In OVP Combination charts, the 1st measure renders as **bars**, the 2nd measure renders as a **line**.
3. **`@DefaultAggregation: #AVG`** is the correct aggregation for fixed/constant values (like TargetAgingDays = 15) to prevent SUM inflation.
4. **`sap:aggregation-role`** annotations in metadata.xml are mandatory for OVP analytical cards to identify measures vs dimensions.
5. **Both measures on `Axis1`:** In working Combination charts, both measures should use `#AXIS_1` (not Axis1/Axis2 split).

---

## Bug Fix: Card 08 — "Total Aging Table" (Activity Aging Summary)

**Date:** 2026-03-21  
**Problem:** Card 08 displayed "No data" or showed irrelevant item-level detail columns (Order, Material). Users needed a summary view showing pending item counts per Period, Plant, Activity Type, and Status.

### Root Cause

Card 08 used `PVChartActivity` (a chart-oriented PresentationVariant) instead of a table-specific PV. The `LineItem#ActivityAging` columns showed individual work order details (WorkOrderNumber, MaterialNumber) instead of summary-oriented fields.

### Fix Applied

**Redesigned `LineItem#ActivityAging` columns:**

| Position | Field | Label | Purpose |
|----------|-------|-------|---------|
| 10 | PeriodMonth | Period | Month period (e.g., 2025-10) |
| 20 | Plant | Plant | Plant code (JKT, BJM, etc.) |
| 30 | ActivityType | Activity | Activity type (USW, MID, ADD, etc.) |
| 40 | CurrentMilestone | Status | Milestone status (PENDING, TR_REQUEST, etc.) |
| 50 | RecordCount | Items | Count of pending items |

**Removed from `LineItem#ActivityAging`:** WorkOrderNumber, MaterialNumber, AgingBucket (item-level detail not useful for summary)

**New PresentationVariant `PVActivityAgingTable`:**
- Sorts by PeriodMonth descending (newest first), then ActivityType ascending
- Links to `@UI.LineItem#ActivityAging`

**manifest.json Card 08 update:**
- Changed `presentationAnnotationPath` from `PVChartActivity` to `PVActivityAgingTable`
- Changed `sortBy` from `ActivityType` to `PeriodMonth` descending

### Files Changed

| File | Change |
|------|--------|
| `ZC_JIPV4_AGING_CDS_VAN.xml` | Redesigned `LineItem#ActivityAging` columns + added `PVActivityAgingTable` |
| `ZE_JIPV4_AGING.asddlx` | Updated field annotations for `ActivityAging` + added `PVActivityAgingTable` |
| `manifest.json` | Card 08 uses `PVActivityAgingTable`, sorts by PeriodMonth desc |

### MDE Changes (ZE_JIPV4_AGING.asddlx)

**New PresentationVariant:**

```abap
{
  qualifier: 'PVActivityAgingTable',
  text: 'Activity Aging Summary',
  sortOrder: [
    { by: 'PeriodMonth', direction: #DESC },
    { by: 'ActivityType', direction: #ASC }
  ],
  visualizations: [{
    type: #AS_LINEITEM,
    qualifier: 'ActivityAging'
  }]
}
```

**Updated field annotations (ActivityAging qualifier):**

```abap
// PeriodMonth — added to ActivityAging at position 10
@UI.lineItem: [{ position: 200, importance: #LOW },
              { qualifier: 'ActivityAging', position: 10, importance: #HIGH }]

// Plant — position changed to 20 in ActivityAging
// ActivityType — position changed to 30 in ActivityAging
// CurrentMilestone — position changed to 40 in ActivityAging

// RecordCount — added to ActivityAging at position 50
@UI.lineItem: [{ qualifier: 'ActivityAging', position: 50, importance: #HIGH, label: 'Items' }]

// Removed from ActivityAging: WorkOrderNumber, MaterialNumber, AgingBucket
```

### VAN.xml — LineItem#ActivityAging

```xml
<Annotation Term="UI.LineItem" Qualifier="ActivityAging">
  <Collection>
    <Record Type="UI.DataField">
      <PropertyValue Property="Value" Path="PeriodMonth"/>
      <PropertyValue Property="Label" String="Period"/>
      <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
    </Record>
    <Record Type="UI.DataField">
      <PropertyValue Property="Value" Path="Plant"/>
      <PropertyValue Property="Label" String="Plant"/>
      <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
    </Record>
    <Record Type="UI.DataField">
      <PropertyValue Property="Value" Path="ActivityType"/>
      <PropertyValue Property="Label" String="Activity"/>
      <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
    </Record>
    <Record Type="UI.DataField">
      <PropertyValue Property="Value" Path="CurrentMilestone"/>
      <PropertyValue Property="Label" String="Status"/>
      <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
    </Record>
    <Record Type="UI.DataField">
      <PropertyValue Property="Value" Path="RecordCount"/>
      <PropertyValue Property="Label" String="Items"/>
      <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
    </Record>
  </Collection>
</Annotation>
```

### manifest.json — Card 08

**Note:** Removed `presentationAnnotationPath` — OVP table cards resolve `LineItem` directly from `annotationPath`, not from the PV's Visualizations. Using a PV here caused "No data". Card 07 works without a PV, so follow the same proven pattern.

```json
"card08_ActivityAgingTable": {
  "model": "mainModel",
  "template": "sap.ovp.cards.table",
  "settings": {
    "title": "{{card08_title}}",
    "subtitle": "{{card08_subtitle}}",
    "entitySet": "ZC_JIPV4_AGING",
    "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
    "annotationPath": "com.sap.vocabularies.UI.v1.LineItem#ActivityAging",
    "sortBy": "PeriodMonth",
    "sortOrder": "descending",
    "addODataSelect": true
  }
}
```

### User Experience

When user filters by Plant (e.g., JKT) and PeriodMonth (e.g., 2025-10), Card 08 shows:

| Period | Plant | Activity | Status | Items |
|--------|-------|----------|--------|-------|
| 2025-10 | JKT | MID | PENDING | 15 |
| 2025-10 | JKT | USW | TR_REQUEST | 8 |
| 2025-10 | JKT | ADD | PENDING | 3 |

---

---

# Bug Fix #3 — Card 08 "Total Aging Table" Shows "No data" (Detail View)

- **Date:** 2026-03-22
- **Card:** Card 08 — Total Aging Table
- **Symptom:** Card 08 shows column headers (Order, Material, Plant, MaintActivityType) but displays "No data" — no rows are returned.
- **Status:** FIXED

## Root Cause Analysis

### 1. Analytical Entity Set (`sap:semantics="aggregate"`)

The OData EntitySet `ZC_JIPV4_AGING` is defined with `sap:semantics="aggregate"` in `metadata.xml`. This means the OData service treats it as an **analytical query** — it automatically applies `GROUP BY` on dimension fields and aggregates measure fields.

**Critical rule:** In an analytical entity set, OData can **only fetch fields** that have `sap:aggregation-role="dimension"` or `sap:aggregation-role="measure"`. Fields without this annotation are invisible to the OData query and cannot be selected.

### 2. Missing Dimension Annotations

`WorkOrderNumber` and `MaterialNumber` did **NOT** have `sap:aggregation-role="dimension"` in `metadata.xml`:

```xml
<!-- BEFORE (broken) — no aggregation-role -->
<Property Name="WorkOrderNumber" Type="Edm.String" MaxLength="12" sap:label="Order"/>
<Property Name="MaterialNumber" Type="Edm.String" MaxLength="40" sap:label="Material"/>
```

Meanwhile, fields like `Plant`, `ActivityType`, `CurrentMilestone` already had `sap:aggregation-role="dimension"` — which is why Card 07 (Aging by Activity Type) worked fine using those fields.

### 3. CDS View `@DefaultAggregation: #NONE`

In the backend CDS view `ZC_JIPV4_AGING.asddls`, these fields had `@DefaultAggregation: #NONE`:

```abap
@DefaultAggregation: #NONE
WorkOrderNumber,
@DefaultAggregation: #NONE
MaterialNumber,
```

In a `@Analytics.dataCategory: #CUBE` view, `@DefaultAggregation: #NONE` tells the OData framework to **exclude** these fields from analytical queries. The OData service then generates metadata **without** `sap:aggregation-role`, making them unfetchable.

### 4. Two Table Cards on Same Entity Set

Having two `sap.ovp.cards.table` cards pointing to the same EntitySet requires each card to use a **unique `LineItem` qualifier**. Using the default (unqualified) `LineItem` on the second card caused conflicts. Both cards must use distinct qualified LineItems.

## Applied Fix

### Step 1: metadata.xml — Add Dimension Role

Added `sap:aggregation-role="dimension"` to `WorkOrderNumber` and `MaterialNumber`:

```xml
<!-- AFTER (fixed) — dimension role added -->
<Property Name="WorkOrderNumber" Type="Edm.String" MaxLength="12"
          sap:display-format="NonNegative" sap:label="Order"
          sap:quickinfo="Order Number"
          sap:aggregation-role="dimension"/>

<Property Name="MaterialNumber" Type="Edm.String" MaxLength="40"
          sap:display-format="UpperCase" sap:label="Material"
          sap:quickinfo="Material Number"
          sap:aggregation-role="dimension"/>
```

> **Why this works:** Once these fields have `sap:aggregation-role="dimension"`, the OData analytical query includes them in `$select` and `GROUP BY`, allowing the table card to fetch and display the data.

### Step 2: CDS View — Remove `@DefaultAggregation: #NONE`

Removed `@DefaultAggregation: #NONE` from `WorkOrderNumber` and `MaterialNumber` in `ZC_JIPV4_AGING.asddls`:

```abap
-- BEFORE
@DefaultAggregation: #NONE
WorkOrderNumber,
@DefaultAggregation: #NONE
MaterialNumber,

-- AFTER (no annotation = treated as dimension in #CUBE view)
WorkOrderNumber,
MaterialNumber,
```

> **Why:** In a `@Analytics.dataCategory: #CUBE` view, fields without `@DefaultAggregation` are treated as dimensions by default. Removing `#NONE` allows the OData service to expose them with `sap:aggregation-role="dimension"` in the live system metadata.

### Step 3: annotation.xml — New LineItem#AgingDetail Qualifier

Created a new `LineItem#AgingDetail` qualifier for Card 08 in `annotation.xml` (local override, highest priority):

```xml
<!-- Card 08: Total Aging Table — Detail view -->
<Annotation Term="UI.LineItem" Qualifier="AgingDetail">
    <Collection>
        <Record Type="UI.DataField">
            <PropertyValue Property="Value" Path="WorkOrderNumber"/>
            <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
        </Record>
        <Record Type="UI.DataField">
            <PropertyValue Property="Value" Path="MaterialNumber"/>
            <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
        </Record>
        <Record Type="UI.DataField">
            <PropertyValue Property="Value" Path="Plant"/>
            <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
        </Record>
        <Record Type="UI.DataField">
            <PropertyValue Property="Value" Path="ActivityType"/>
            <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
        </Record>
        <Record Type="UI.DataField">
            <PropertyValue Property="Value" Path="CurrentMilestone"/>
            <Annotation Term="UI.Importance" EnumMember="UI.ImportanceType/High"/>
        </Record>
    </Collection>
</Annotation>
```

### Step 4: manifest.json — Card 08 Configuration

Updated Card 08 to use the new `LineItem#AgingDetail` qualifier and removed `addODataSelect`:

```json
"card08_ActivityAgingTable": {
  "model": "mainModel",
  "template": "sap.ovp.cards.table",
  "settings": {
    "title": "{{card08_title}}",
    "subtitle": "{{card08_subtitle}}",
    "entitySet": "ZC_JIPV4_AGING",
    "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
    "annotationPath": "com.sap.vocabularies.UI.v1.LineItem#AgingDetail",
    "sortBy": "Plant",
    "sortOrder": "ascending"
  }
}
```

### Step 5: Card 07 / Card 08 Swap

Swapped the annotation assignments so each card shows the correct content:

| Card | Title | Qualifier | Columns |
|------|-------|-----------|---------|
| Card 07 | Aging by Activity Type | `LineItem#ActivityAging` | Period, Plant, Activity, Status, Items |
| Card 08 | Total Aging Table | `LineItem#AgingDetail` | Order, Material, Plant, ActivityType, Status |

## Changed Files Summary

| File | Change |
|------|--------|
| `metadata.xml` | Added `sap:aggregation-role="dimension"` to `WorkOrderNumber`, `MaterialNumber` |
| `ZC_JIPV4_AGING.asddls` | Removed `@DefaultAggregation: #NONE` from `WorkOrderNumber`, `MaterialNumber` |
| `annotation.xml` | Added `LineItem#AgingDetail` qualifier with 5 detail columns |
| `manifest.json` | Card 08 uses `LineItem#AgingDetail`, removed `addODataSelect` |
| `i18n.properties` | Swapped Card 07/08 titles and subtitles |

## Key Lesson Learned

> In SAP CDS views with `@Analytics.dataCategory: #CUBE` and OData `sap:semantics="aggregate"`, **every field** that needs to appear in a Fiori OVP table card **must** have an aggregation role:
> - **Dimension fields** (text/ID): leave without `@DefaultAggregation` or use `@DefaultAggregation: #NOP` — do NOT use `#NONE`
> - **Measure fields** (numbers to aggregate): use `@DefaultAggregation: #SUM`, `#AVG`, etc.
> - Fields with `@DefaultAggregation: #NONE` are **excluded** from analytical OData queries and will cause "No data" on cards that reference them.

## User Experience (After Fix)

Card 08 "Total Aging Table" now shows detail rows:

| Order | Material | Plant | MaintActivityType | Status |
|-------|----------|-------|-------------------|--------|
| 51366942 | 01010-80835 | JKT | MID | PENDING |
| 51366944 | 06300-23130 | JKT | MID | PENDING |
| 51366944 | 1496559 | JKT | MID | TR_REQUEST |
| 51366944 | 01010-80835 | JKT | MID | PENDING |
| 51366944 | 195-30-07110 | JKT | MID | PENDING |

---

## Backend Activation Checklist

After updating the files, the following must be activated on the ABAP backend (ADT/Eclipse):

- [ ] `ZC_JIPV4_AGING` — CDS consumption view (removed `@DefaultAggregation: #NONE` from WorkOrderNumber, MaterialNumber)
- [ ] `ZE_JIPV4_AGING` — MDE (for Card 06 + Card 08 annotation changes)
- [ ] Regenerate metadata on live system to confirm `sap:aggregation-role="dimension"` appears for WorkOrderNumber and MaterialNumber
- [ ] Restart BAS preview + hard refresh browser (`Ctrl+Shift+R`)
