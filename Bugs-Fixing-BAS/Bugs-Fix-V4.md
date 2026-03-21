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

## Backend Activation Checklist

After updating the files, the following must be activated on the ABAP backend (ADT/Eclipse):

- [ ] `ZC_JIPV4_AGING` — CDS consumption view (for `@DefaultAggregation: #AVG`)
- [ ] `ZE_JIPV4_AGING` — MDE (for `ChartPendingByActivity` + `PVPendingByActivity`)
- [ ] Restart BAS preview + hard refresh browser (`Ctrl+Shift+R`)
