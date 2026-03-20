# PRD 02: Fiori OVP Implementation — SAP Business Application Studio

## JIP Milestone Aging Dashboard V4 — Card-by-Card Development Guide

**Version 4.2 — Updated: Card 06 Target Line per Activity Type**

---

## Changelog from v4.1

| Change | Description |
|--------|-------------|
| **Card 06 redesign** | Added fixed target line per Activity Type (hardcoded in CDS CASE statement) |
| **New CDS field** | `TargetAgingDays` added to `ZI_JIPV4_PartsComposite` and `ZC_JIPV4_AGING` |
| **New MDE annotation** | `@UI.dataPoint#TargetAgingDays` with `targetValue` reference for combination chart |
| **New chart qualifier** | `ChartAvgAgingWithTarget` replaces `ChartAvgAging` — uses dual measures (actual + target) |
| **Default target** | All activity types default to 15 days — customizable per ILART via CDS CASE |

---

## 1. Card 06 Target Line — Design

### 1.1 Concept

```
AVERAGE AGING BY BLP ADD
 120│
 100│                                                          ██
  80│                                                     ██
  60│
  40│                                              ██
  20│  ██  ██      ██  ██  ██  ██  ██       ██
  15│──────────────────────────────────────────────────── Target (15 days)
   0│──────────────────────────────────────────────────
     Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
```

The **target line** is a fixed horizontal reference showing the KPI target for that Activity Type. Bars above the line indicate aging is exceeding the target.

### 1.2 Target Days Configuration (Hardcoded in CDS)

| Activity Type (ILART) | Target Days | Description |
|----------------------|-------------|-------------|
| ADD | 15 | Additional work |
| INS | 15 | Inspection |
| LOG | 15 | Logistics |
| MID | 15 | Mid-range maintenance |
| NME | 15 | New maintenance equipment |
| OVH | 15 | Overhaul |
| PAP | 15 | Planned activity program |
| PPM | 15 | Planned preventive maintenance |
| SER | 15 | Service |
| TRS | 15 | Transfer/relocation |
| UIW | 15 | Unplanned immediate work |
| USN | 15 | Unscheduled |

> **To customize later:** Change the number in the CDS CASE statement for each ILART. No transport needed if using `$TMP`. For production, update and transport the CDS view.

---

## 2. CDS Changes Required

### 2.1 Add `TargetAgingDays` to Composite View

In `ZI_JIPV4_PartsComposite`, add this field in the select list (after `AgingBucket`):

```abap
      -- Target Aging Days per Activity Type (hardcoded — customize per ILART)
      case WO.ActivityType
        when 'ADD' then 15
        when 'INS' then 15
        when 'LOG' then 15
        when 'MID' then 15
        when 'NME' then 15
        when 'OVH' then 15
        when 'PAP' then 15
        when 'PPM' then 15
        when 'SER' then 15
        when 'TRS' then 15
        when 'UIW' then 15
        when 'USN' then 15
        else 15
      end                                     as TargetAgingDays,
```

### 2.2 Expose in Consumption View

In `ZC_JIPV4_AGING`, add to the select list:

```abap
      TargetAgingDays,
```

### 2.3 Full CASE Statement (Ready for Customization)

When you know the actual targets, update the CASE like this example:

```abap
      -- Example with customized targets:
      case WO.ActivityType
        when 'ADD' then 15
        when 'INS' then 10
        when 'LOG' then 20
        when 'MID' then 30
        when 'NME' then 25
        when 'OVH' then 45
        when 'PAP' then 12
        when 'PPM' then 14
        when 'SER' then 15
        when 'TRS' then 20
        when 'UIW' then 7
        when 'USN' then 10
        else 15
      end                                     as TargetAgingDays,
```

---

## 3. Metadata Extension Changes

### 3.1 Add DataPoint for Target

Add to `ZE_JIPV4_AGING` (inside the `{ }` block):

```abap
  // --- TargetAgingDays ---
  @UI.dataPoint: {
    title: 'Target Aging (Days)',
    targetValue: 'TargetAgingDays'
  }
  TargetAgingDays;
```

### 3.2 Update Chart Definition for Card 06

Replace the existing `ChartAvgAging` chart in the MDE entity-level annotations with a dual-measure chart:

```abap
  {
    qualifier: 'ChartAvgAgingWithTarget',
    title: 'Avg Aging vs Target by Plant & Activity',
    chartType: #COMBINATION,
    dimensions: ['PeriodMonth'],
    measures: ['AgingRelease', 'TargetAgingDays'],
    dimensionAttributes: [
      { dimension: 'PeriodMonth', role: #CATEGORY }
    ],
    measureAttributes: [
      {
        measure: 'AgingRelease',
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

> **How it works:** The COMBINATION chart renders `AgingRelease` as bars and `TargetAgingDays` as a line. Since `TargetAgingDays` is a constant value per Activity Type, it appears as a flat horizontal reference line across all months.

### 3.3 Add Presentation Variant for Card 06

Add to the entity-level `@UI.presentationVariant` array:

```abap
  {
    qualifier: 'PVAvgAgingTarget',
    text: 'Avg Aging vs Target',
    sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartAvgAgingWithTarget'
    }]
  }
```

---

## 4. manifest.json — Updated Card 06

### 4.1 Replace Card 06 Configuration

```json
"card06_AvgAging": {
  "model": "mainService",
  "template": "sap.ovp.cards.charts.analytical",
  "settings": {
    "title": "{{card06_title}}",
    "subtitle": "Actual vs Target by Month",
    "entitySet": "ZC_JIPV4_AGING",
    "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAvgAgingWithTarget",
    "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVAvgAgingTarget",
    "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#TargetAgingDays",
    "navigation": "dataPointNav",
    "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
  }
}
```

### 4.2 Update i18n

```properties
card06_title=Avg Aging vs Target
card06_subtitle=Actual vs Target by Month
```

---

## 5. How Card 06 Works — Visual Explanation

### 5.1 When User Selects Plant=BLP, Activity=ADD in Filter

```
AVG AGING vs TARGET — BLP / ADD
 120│
 100│                                                          ██ Actual
  80│                                                     ██     Aging
  60│                                                            (Bars)
  40│                                              ██
  20│  ██  ██      ██  ██  ██  ██  ██       ██
  15│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Target Line
   0│                                                            (15 days)
     Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec

Legend: ██ = AgingRelease (actual avg days)
        ━━ = TargetAgingDays (15 days for ADD)
```

### 5.2 When User Changes Activity=OVH (after customization to 45 days)

```
AVG AGING vs TARGET — BLP / OVH
  60│
  50│            ██       ██
  45│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Target Line
  40│  ██  ██         ██       ██  ██                        (45 days)
  30│                                   ██  ██  ██
  20│                                              ██  ██
   0│
     Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
```

The target line automatically changes based on the Activity Type selected in the filter bar — because `TargetAgingDays` is calculated from the CASE statement in CDS based on the filtered `ActivityType`.

---

## 6. Complete manifest.json — All 8 Cards

For reference, here is the complete `sap.ovp.cards` section with all 8 cards including the updated Card 06:

```json
{
  "sap.ovp": {
    "globalFilterModel": "mainService",
    "globalFilterEntityType": "ZC_JIPV4_AGINGType",
    "containerLayout": "resizable",
    "enableLiveFilter": true,
    "considerAnalyticalParameters": false,
    "cards": {

      "card01_JIPPerPlant": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card01_title}}",
          "subtitle": "Count by Plant",
          "entitySet": "ZC_JIPV4_AGING",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartJIPPerPlant",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartByPlant",
          "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#AgingBucket",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card02_HistoricalJIP": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card02_title}}",
          "subtitle": "Monthly by Aging Bucket",
          "entitySet": "ZC_JIPV4_AGING",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartHistoricalJIP",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical",
          "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#AgingBucket",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card03_AgingPerPlant": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card03_title}}",
          "subtitle": "Monthly Aging by Plant",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAgingPerPlant",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical",
          "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#AgingBucket",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card04_ActivityBreakdown": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card04_title}}",
          "subtitle": "Count by Activity Type",
          "entitySet": "ZC_JIPV4_AGING",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartActivityBreakdown",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartActivity",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card05_MonthlyTrend": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card05_title}}",
          "subtitle": "Activity Type Stacked Monthly",
          "entitySet": "ZC_JIPV4_AGING",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartMonthlyTrend",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card06_AvgAging": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "{{card06_title}}",
          "subtitle": "Actual vs Target by Month",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAvgAgingWithTarget",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVAvgAgingTarget",
          "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#TargetAgingDays",
          "navigation": "dataPointNav",
          "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
        }
      },

      "card07_DetailTable": {
        "model": "mainService",
        "template": "sap.ovp.cards.table",
        "settings": {
          "title": "{{card07_title}}",
          "subtitle": "All JIP Items",
          "entitySet": "ZC_JIPV4_AGING",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#DefaultSort",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems",
          "annotationPath": "com.sap.vocabularies.UI.v1.LineItem",
          "addODataSelect": true,
          "sortBy": "AgingBucket",
          "sortOrder": "descending"
        }
      },

      "card08_CriticalList": {
        "model": "mainService",
        "template": "sap.ovp.cards.list",
        "settings": {
          "title": "{{card08_title}}",
          "subtitle": "60+ and 70+ Items",
          "entitySet": "ZC_JIPV4_AGING",
          "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVCriticalAging",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#DefaultSort",
          "annotationPath": "com.sap.vocabularies.UI.v1.LineItem",
          "listType": "condensed",
          "sortBy": "AgingBucket",
          "sortOrder": "descending",
          "addODataSelect": true
        }
      }
    }
  }
}
```

---

## 7. Local Annotations — annotation.xml (Unchanged)

The 3 selection variants remain the same as PRD 02 v4.1 Section 7:
- `SVOpenItems` — Exclude GI completed
- `SVCriticalAging` — Only 60+ and 70+
- `SVEWMOnly` — EWM plants only

No changes needed in `annotation.xml` for the target line feature.

---

## 8. i18n — Complete Updated File

```properties
# App
appTitle=JIP Milestone Aging Dashboard V4
appDescription=JIP Parts Milestone Aging — Overview Page

# Card Titles
card01_title=Total JIP per Plant
card02_title=Historical JIP - All Plants
card03_title=Aging per Plant
card04_title=Activity Type Breakdown
card05_title=Monthly Trend by Activity
card06_title=Avg Aging vs Target
card07_title=JIP Parts Detail
card08_title=Critical Aging Items
```

---

## 9. Implementation Steps Summary

| # | Step | Where | What To Do |
|---|------|-------|------------|
| 1 | Add `TargetAgingDays` CASE | `ZI_JIPV4_PartsComposite` (Eclipse ADT) | Add CASE statement in select list |
| 2 | Expose field | `ZC_JIPV4_AGING` (Eclipse ADT) | Add `TargetAgingDays` to select list |
| 3 | Activate both views | Eclipse ADT | Ctrl+F3 on both views |
| 4 | Update MDE | `ZE_JIPV4_AGING` (Eclipse ADT) | Add `@UI.dataPoint` for TargetAgingDays, update `@UI.chart` with new qualifier |
| 5 | Activate MDE | Eclipse ADT | Ctrl+F3 |
| 6 | Clear metadata cache | `/IWFND/MAINT_SERVICE` (SAP GUI) | Clear cache for ZC_JIPV4_AGING_CDS |
| 7 | Update manifest.json | BAS | Replace Card 06 config with new qualifier |
| 8 | Update i18n | BAS | Change card06_title |
| 9 | Test locally | BAS | `npm run start` → verify Card 06 shows bars + line |
| 10 | Deploy | BAS | `npm run deploy` |

---

## 10. Future Enhancement: Z-Table Approach

If the business later wants to maintain target days without development, replace the CDS CASE statement with a Z-Table:

**Table: `ZTJIP_TARGETS`**

| Field | Type | Description |
|-------|------|-------------|
| MANDT | CLNT | Client |
| ILART | CHAR(3) | Activity Type (key) |
| TARGET_DAYS | INT4 | Target aging days |
| DESCRIPTION | CHAR(40) | Description |

**SM30 Maintenance View** for business users to update targets.

**CDS change:** Replace CASE with:
```abap
left outer join ztjip_targets as TGT
  on WO.ActivityType = TGT.ilart

-- Then in select:
coalesce(TGT.target_days, 15) as TargetAgingDays
```

This is an optional Phase 2 enhancement — the hardcoded CASE works perfectly for now.

---

## 11. Checklist

### Card 06 Target Line Implementation
- [ ] `TargetAgingDays` CASE statement added to `ZI_JIPV4_PartsComposite`
- [ ] `TargetAgingDays` exposed in `ZC_JIPV4_AGING`
- [ ] Both CDS views activated
- [ ] `@UI.dataPoint#TargetAgingDays` added to MDE
- [ ] `@UI.chart#ChartAvgAgingWithTarget` added to MDE (dual measures)
- [ ] `@UI.presentationVariant#PVAvgAgingTarget` added to MDE
- [ ] MDE activated
- [ ] Metadata cache cleared
- [ ] Card 06 in manifest.json updated with new qualifiers
- [ ] i18n updated
- [ ] Local preview: Card 06 shows bars (actual) + line (target)
- [ ] Target line changes when different Activity Type is selected in filter
- [ ] Deployed to ABAP repository

### All 8 Cards Working
- [ ] Card 01: JIP per Plant (BAR)
- [ ] Card 02: Historical JIP (STACKED COLUMN)
- [ ] Card 03: Aging per Plant (STACKED COLUMN)
- [ ] Card 04: Activity Breakdown (BAR)
- [ ] Card 05: Monthly Trend (STACKED COLUMN)
- [ ] Card 06: **Avg Aging vs Target (COMBINATION — bars + target line)**
- [ ] Card 07: Detail Table (TABLE)
- [ ] Card 08: Critical Items (LIST)