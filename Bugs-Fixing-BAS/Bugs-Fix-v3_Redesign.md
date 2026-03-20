# Bugs Fix V3 — Card Redesign (Corrected Card Purposes)

**Date:** 2026-03-20  
**Status:** Implemented (BAS files updated 2026-03-20)  
**Source:** User feedback on live dashboard screenshots

---

## Summary of Changes

| Card | Current Design | New Design | Files Changed |
|------|---------------|------------|---------------|
| 01 | BAR by Plant + ActivityType series | **BAR by Plant** — shows aging count per plant (default 6 plants, no filter needed) | VAN.xml, MDE |
| 02 | COLUMN_STACKED PeriodMonth × AgingBucket | **BAR_STACKED by Plant** — all plants stacked OK/60+/70+ | VAN.xml, MDE |
| 03 | COLUMN_STACKED PeriodMonth × AgingBucket | **BAR by Plant** — default 6 plants with OK/60+/70+ color | VAN.xml, MDE |
| 04 | COLUMN_STACKED PeriodMonth × ActivityType | **BAR by ActivityType** — shows USW, SER, ADD, TRS etc. count | VAN.xml, MDE |
| 05 | COLUMN_STACKED PeriodMonth × ActivityType | **COLUMN_STACKED by PeriodMonth** — 12 months (Jan-Dec) when Plant is filtered | No change needed (already correct) |
| 06 | COMBINATION AgingRelease vs TargetAgingDays | **BAR by ActivityType** — count of items still PENDING per activity | VAN.xml, MDE, manifest.json |
| 07 | Table (Aging by Activity) | **No change** — keep as is | — |
| 08 | Table (Activity × Month) | **TABLE** — Aging count per Month + Activity Type when Plant is input | No change needed (already correct) |

---

## Detailed Card Specifications

### Card 01 — Aging per Plant (Default View)

**Purpose:** When all filters are empty, show total JIP count for each plant (default top 6 plants).

| Property | Before | After |
|----------|--------|-------|
| Title | Total JIP per Plant | Aging per Plant |
| Chart Type | `#BAR` with ActivityType series | `#BAR` — Plant only (no series stacking) |
| Dimension | Plant (category) + ActivityType (series) | **Plant (category only)** |
| Measure | RecordCount | RecordCount |
| Stacking | Stacked by ActivityType | **No stacking — single bar per plant** |
| Default | Shows all plants | Shows all plants (OVP default top results) |

**MDE Chart Change:**
```abap
{
  qualifier: 'ChartJIPPerPlant',
  title: 'Aging per Plant',
  chartType: #BAR,
  dimensions: ['Plant'],
  measures: ['RecordCount'],
  dimensionAttributes: [
    { dimension: 'Plant', role: #CATEGORY }
  ],
  measureAttributes: [{
    measure: 'RecordCount',
    role: #AXIS_1,
    asDataPoint: true
  }]
}
```

**VAN.xml Change:**
```xml
<Annotation Term="UI.Chart" Qualifier="ChartJIPPerPlant">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Aging per Plant"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>
    <PropertyValue Property="Dimensions">
      <Collection>
        <PropertyPath>Plant</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="DimensionAttributes">
      <Collection>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="Plant"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Category"/>
        </Record>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="Measures">
      <Collection>
        <PropertyPath>RecordCount</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
          <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

---

### Card 02 — Historical Aging ALL Plants (OK / 60+ / 70+)

**Purpose:** Show ALL plants stacked by aging bucket (OK=green, 60+=yellow, 70+=red).

| Property | Before | After |
|----------|--------|-------|
| Title | Historical JIP - All Plants | Historical Aging - All Plants |
| Chart Type | `#COLUMN_STACKED` (PeriodMonth × AgingBucket) | `#BAR_STACKED` (Plant × AgingBucket) |
| Dimension Category | PeriodMonth | **Plant** |
| Dimension Series | AgingBucket | AgingBucket (same) |
| Measure | RecordCount | RecordCount |

**MDE Chart Change:**
```abap
{
  qualifier: 'ChartHistoricalJIP',
  title: 'Historical Aging - All Plants',
  chartType: #BAR_STACKED,
  dimensions: ['Plant', 'AgingBucket'],
  measures: ['RecordCount'],
  dimensionAttributes: [
    { dimension: 'Plant', role: #CATEGORY },
    { dimension: 'AgingBucket', role: #SERIES }
  ],
  measureAttributes: [{
    measure: 'RecordCount',
    role: #AXIS_1,
    asDataPoint: true
  }]
}
```

**VAN.xml Change:**
```xml
<Annotation Term="UI.Chart" Qualifier="ChartHistoricalJIP">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Historical Aging - All Plants"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/BarStacked"/>
    <PropertyValue Property="Dimensions">
      <Collection>
        <PropertyPath>Plant</PropertyPath>
        <PropertyPath>AgingBucket</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="DimensionAttributes">
      <Collection>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="Plant"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Category"/>
        </Record>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="AgingBucket"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Series"/>
        </Record>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="Measures">
      <Collection>
        <PropertyPath>RecordCount</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
          <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

> **Note:** `BarStacked` may not render in OVP preview (Bugs-Fix-v2 lesson). If it doesn't render, fallback to `#COLUMN_STACKED` with Plant on X-axis instead of `BarStacked`.

---

### Card 03 — Aging per Plant (Bar with OK/60+/70+ Colors)

**Purpose:** Show default 6 plants as bars colored by aging bucket.

| Property | Before | After |
|----------|--------|-------|
| Title | Historical Aging per Plant | Aging per Plant Detail |
| Chart Type | `#COLUMN_STACKED` (PeriodMonth × AgingBucket) | `#COLUMN_STACKED` (Plant × AgingBucket) |
| Dimension Category | PeriodMonth | **Plant** |
| Dimension Series | AgingBucket | AgingBucket (same) |

**MDE Chart Change:**
```abap
{
  qualifier: 'ChartAgingPerPlant',
  title: 'Aging per Plant Detail',
  chartType: #COLUMN_STACKED,
  dimensions: ['Plant', 'AgingBucket'],
  measures: ['RecordCount'],
  dimensionAttributes: [
    { dimension: 'Plant', role: #CATEGORY },
    { dimension: 'AgingBucket', role: #SERIES }
  ],
  measureAttributes: [{
    measure: 'RecordCount',
    role: #AXIS_1,
    asDataPoint: true
  }]
}
```

**VAN.xml Change:**
```xml
<Annotation Term="UI.Chart" Qualifier="ChartAgingPerPlant">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Aging per Plant Detail"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/ColumnStacked"/>
    <PropertyValue Property="Dimensions">
      <Collection>
        <PropertyPath>Plant</PropertyPath>
        <PropertyPath>AgingBucket</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="DimensionAttributes">
      <Collection>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="Plant"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Category"/>
        </Record>
        <Record Type="UI.ChartDimensionAttributeType">
          <PropertyValue Property="Dimension" PropertyPath="AgingBucket"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartDimensionRoleType/Series"/>
        </Record>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="Measures">
      <Collection>
        <PropertyPath>RecordCount</PropertyPath>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
          <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

---

### Card 04 — Activity Type Breakdown

**Purpose:** Show count per Activity Type (USW, SER, ADD, TRS, OVH, etc.) as simple bars.

| Property | Before | After |
|----------|--------|-------|
| Title | Activity Type by Plant | Activity Type Breakdown |
| Chart Type | `#COLUMN_STACKED` (PeriodMonth × ActivityType) | `#BAR` (ActivityType only) |
| Dimension | PeriodMonth (category) + ActivityType (series) | **ActivityType (category only)** |

**MDE Chart Change:**
```abap
{
  qualifier: 'ChartActivityBreakdown',
  title: 'Activity Type Breakdown',
  chartType: #BAR,
  dimensions: ['ActivityType'],
  measures: ['RecordCount'],
  dimensionAttributes: [
    { dimension: 'ActivityType', role: #CATEGORY }
  ],
  measureAttributes: [{
    measure: 'RecordCount',
    role: #AXIS_1,
    asDataPoint: true
  }]
}
```

**VAN.xml Change:**
```xml
<Annotation Term="UI.Chart" Qualifier="ChartActivityBreakdown">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Activity Type Breakdown"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>
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
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
          <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

---

### Card 05 — Monthly Trend (Jan-Dec) — NO CHANGE

**Purpose:** When Plant is filtered, shows 12 months (Jan-Dec) on X-axis, stacked by ActivityType. **Already correct — no changes needed.**

Current design: `COLUMN_STACKED` with PeriodMonth (category) + ActivityType (series). This is exactly what the user wants.

---

### Card 06 — Pending Count per Activity Type (NEW DESIGN)

**Purpose:** Show how many items are still PENDING per Activity Type. Replace the old Avg Aging vs Target chart.

| Property | Before | After |
|----------|--------|-------|
| Title | Avg Aging vs Target | Pending Items by Activity |
| Chart Type | `#COMBINATION` (bars + line) | `#BAR` (ActivityType only) |
| Dimension | PeriodMonth | **ActivityType** |
| Measure | AgingRelease + TargetAgingDays | **RecordCount** |
| Selection Variant | SVOpenItems (exclude GI) | **NEW: SVPendingOnly** (CurrentMilestone = PENDING) |

**MDE — New Chart:**
```abap
{
  qualifier: 'ChartPendingByActivity',
  title: 'Pending Items by Activity',
  chartType: #BAR,
  dimensions: ['ActivityType'],
  measures: ['RecordCount'],
  dimensionAttributes: [
    { dimension: 'ActivityType', role: #CATEGORY }
  ],
  measureAttributes: [{
    measure: 'RecordCount',
    role: #AXIS_1,
    asDataPoint: true
  }]
}
```

**MDE — New Presentation Variant:**
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

**VAN.xml — New Chart:**
```xml
<Annotation Term="UI.Chart" Qualifier="ChartPendingByActivity">
  <Record Type="UI.ChartDefinitionType">
    <PropertyValue Property="Title" String="Pending Items by Activity"/>
    <PropertyValue Property="ChartType" EnumMember="UI.ChartType/Bar"/>
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
      </Collection>
    </PropertyValue>
    <PropertyValue Property="MeasureAttributes">
      <Collection>
        <Record Type="UI.ChartMeasureAttributeType">
          <PropertyValue Property="Measure" PropertyPath="RecordCount"/>
          <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
          <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

**VAN.xml — New Presentation Variant:**
```xml
<Annotation Term="UI.PresentationVariant" Qualifier="PVPendingByActivity">
  <Record>
    <PropertyValue Property="Text" String="Pending by Activity"/>
    <PropertyValue Property="SortOrder">
      <Collection>
        <Record Type="Common.SortOrderType">
          <PropertyValue Property="Property" PropertyPath="ActivityType"/>
          <PropertyValue Property="Descending" Bool="false"/>
        </Record>
      </Collection>
    </PropertyValue>
    <PropertyValue Property="Visualizations">
      <Collection>
        <AnnotationPath>@UI.Chart#ChartPendingByActivity</AnnotationPath>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

**annotation.xml — New Selection Variant for PENDING only:**
```xml
<!-- Selection Variant: Pending Items Only -->
<Annotation Term="UI.SelectionVariant" Qualifier="SVPendingOnly">
  <Record>
    <PropertyValue Property="Text" String="{@i18n>svPendingOnlyText}"/>
    <PropertyValue Property="SelectOptions">
      <Collection>
        <Record Type="UI.SelectOptionType">
          <PropertyValue Property="PropertyName"
                         PropertyPath="CurrentMilestone"/>
          <PropertyValue Property="Ranges">
            <Collection>
              <Record Type="UI.SelectionRangeType">
                <PropertyValue Property="Sign"
                               EnumMember="UI.SelectionRangeSignType/I"/>
                <PropertyValue Property="Option"
                               EnumMember="UI.SelectionRangeOptionType/EQ"/>
                <PropertyValue Property="Low" String="PENDING"/>
              </Record>
            </Collection>
          </PropertyValue>
        </Record>
      </Collection>
    </PropertyValue>
  </Record>
</Annotation>
```

**manifest.json — Card 06 updated:**
```json
"card06_PendingByActivity": {
  "model": "mainModel",
  "template": "sap.ovp.cards.charts.analytical",
  "settings": {
    "title": "{{card06_title}}",
    "subtitle": "{{card06_subtitle}}",
    "entitySet": "ZC_JIPV4_AGING",
    "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVPendingOnly",
    "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartPendingByActivity",
    "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVPendingByActivity",
    "navigation": "dataPointNav",
    "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
  }
}
```

---

### Card 07 — Total Aging Table — NO CHANGE

Already working correctly. Keep as is.

---

### Card 08 — Aging by Month + Activity Type — NO CHANGE

Already working correctly. Shows Order, Material, Plant, MaintActivityType, CurrentMilestone when Plant is filtered.

---

## i18n Updates

```properties
# Card 01
card01_title=Aging per Plant
card01_subtitle=Total Count by Plant

# Card 02
card02_title=Historical Aging - All Plants
card02_subtitle=Stacked OK / 60+ / 70+

# Card 03
card03_title=Aging per Plant Detail
card03_subtitle=Stacked OK / 60+ / 70+

# Card 04
card04_title=Activity Type Breakdown
card04_subtitle=Count by Activity Type

# Card 05 (unchanged)
card05_title=Monthly Trend by Activity
card05_subtitle=Activity Type Stacked Monthly

# Card 06 (changed)
card06_title=Pending Items by Activity
card06_subtitle=Items Still at PENDING Stage

# Card 07 (unchanged)
card07_title=Total Aging Table
card07_subtitle=Plant x Month Count

# Card 08 (unchanged)
card08_title=Aging by Activity Type
card08_subtitle=Activity x Month Count

# New Selection Variant
svPendingOnlyText=Pending Items Only
```

---

## Updated Dashboard Layout

```
╔══════════════════════════════╦═══════════════════════════╦══════════════════════════╗
║  CARD 01                     ║  CARD 02                  ║  CARD 03                 ║
║  Aging per Plant             ║  Historical Aging         ║  Aging per Plant Detail  ║
║  [BAR - Plant only]          ║  All Plants               ║  [COLUMN STACKED]        ║
║  Shows 6 plants default      ║  [BAR STACKED]            ║  Plant x AgingBucket     ║
║                              ║  Plant x OK/60+/70+       ║  OK/60+/70+ colors       ║
╠══════════════════════════════╬═══════════════════════════╬══════════════════════════╣
║  CARD 04                     ║  CARD 05                  ║  CARD 06                 ║
║  Activity Type Breakdown     ║  Monthly Trend            ║  Pending by Activity     ║
║  [BAR - ActivityType]        ║  [STACKED COLUMN]         ║  [BAR - ActivityType]    ║
║  USW, SER, ADD, TRS etc.     ║  PeriodMonth x Activity   ║  PENDING only filter     ║
║                              ║  (when Plant filtered)     ║                          ║
╠══════════════════════════════╩═══════════════════════════╬══════════════════════════╣
║  CARD 07                                                 ║  CARD 08                 ║
║  Total Aging Table                                       ║  Aging by Activity       ║
║  [TABLE - unchanged]                                     ║  [TABLE - unchanged]     ║
╚══════════════════════════════════════════════════════════╩══════════════════════════╝
```

---

## Files to Change

| # | File | Location | Changes |
|---|------|----------|---------|
| 1 | `ZE_JIPV4_AGING.asddlx` | Backend (ADT) | Update chart definitions for Cards 01/02/03/04, add new ChartPendingByActivity + PVPendingByActivity |
| 2 | `ZC_JIPV4_AGING_CDS_VAN.xml` | BAS `webapp/localService/` | Mirror all MDE chart changes for local preview |
| 3 | `manifest.json` | BAS `webapp/` | Update Card 06 to use new chart qualifier + SVPendingOnly |
| 4 | `annotation.xml` | BAS `webapp/annotations/` | Add SVPendingOnly selection variant |
| 5 | `i18n.properties` | BAS `webapp/i18n/` | Update card titles/subtitles + add svPendingOnlyText |

---

## Implementation Steps

```
Backend:
1. Edit ZE_JIPV4_AGING.asddlx — update chart array (Cards 01/02/03/04/06)
2. Activate MDE (Ctrl+F3)
3. /IWFND/CACHE_CLEANUP

BAS:
4. Update ZC_JIPV4_AGING_CDS_VAN.xml — mirror chart changes
5. Update manifest.json — Card 06 new qualifiers
6. Update annotation.xml — add SVPendingOnly
7. Update i18n.properties — card titles
8. npm run start → test preview
9. npm run deploy
```

---

## BarStacked Fallback Note

From Bugs-Fix-v2 experience: `UI.ChartType/BarStacked` may not render in OVP cards. If Card 02 doesn't render with `BarStacked`, change to `ColumnStacked` with Plant on X-axis (vertical bars instead of horizontal). The data is the same — only the bar orientation changes.

**Fallback for Card 02:**
```diff
- EnumMember="UI.ChartType/BarStacked"
+ EnumMember="UI.ChartType/ColumnStacked"
```
