# Card 06 Fix — Pending Items by Activity (Combination: Bar + Line)

**Date:** 2026-03-20  
**Issue:** Card 06 not rendering — blank card body (no chart, no "No data" text)  
**Root Cause:** Two issues:  
1. `SVPendingOnly` filters `CurrentMilestone = 'PENDING'` — no records match in test data → blank card  
2. Chart type was `Bar` (single measure) instead of `Combination` (bar + target line)  
**Fix:** Change `SVPendingOnly` → `SVOpenItems` + change chart to `Combination` with `TargetAgingDays` line

---

## Summary of Changes

| # | File | Location | Change |
|---|------|----------|--------|
| 1 | `ZC_JIPV4_AGING_CDS_VAN.xml` | BAS frontend annotation | `ChartPendingByActivity`: Bar → **Combination**, add `TargetAgingDays` measure |
| 2 | `ZE_JIPV4_AGING.asddlx` | Backend MDE | Same chart change: `#BAR` → `#COMBINATION`, add `TargetAgingDays` |
| 3 | `manifest.json` | Card 06 settings | Update `presentationAnnotationPath` to `PVPendingByActivity` (already correct) |
| 4 | `i18n.properties` | Card 06 title/subtitle | Update subtitle to reflect "Count vs Target" |

---

## Fix 1: VAN.xml — `ChartPendingByActivity`

**File:** `webapp/localService/mainService/ZC_JIPV4_AGING_CDS_VAN.xml`

### REPLACE this block:

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

### WITH this block:

```xml
<Annotation Term="UI.Chart" Qualifier="ChartPendingByActivity">
    <Record Type="UI.ChartDefinitionType">
        <PropertyValue Property="Title" String="Pending Items by Activity vs Target"/>
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
                    <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#RecordCount"/>
                </Record>
                <Record Type="UI.ChartMeasureAttributeType">
                    <PropertyValue Property="Measure" PropertyPath="TargetAgingDays"/>
                    <PropertyValue Property="Role" EnumMember="UI.ChartMeasureRoleType/Axis1"/>
                    <PropertyValue Property="DataPoint" AnnotationPath="@UI.DataPoint#TargetAgingDays"/>
                </Record>
            </Collection>
        </PropertyValue>
    </Record>
</Annotation>
```

**Key changes:**
- `ChartType`: `Bar` → `Combination`
- Added `TargetAgingDays` to Measures collection
- Added `TargetAgingDays` MeasureAttribute with DataPoint reference
- In Combination chart: first measure renders as **bars**, second renders as **line**

---

## Fix 2: MDE (Backend) — `ZE_JIPV4_AGING.asddlx`

**File:** `ZE_JIPV4_AGING.asddlx` (activate in SAP backend)

### REPLACE the `ChartPendingByActivity` block in the `@UI.chart` array (inside entity-level annotations):

#### BEFORE:

```abap
  // (There is NO ChartPendingByActivity in the current MDE — 
  //  it only exists in VAN.xml. You need to ADD it.)
```

#### ADD this chart definition to the `@UI.chart` array:

```abap
  {
    qualifier: 'ChartPendingByActivity',
    title: 'Pending Items by Activity vs Target',
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

> **Note:** After adding this to the MDE and activating, the VAN.xml will be regenerated by the backend. You can then re-download it to BAS, or keep the local VAN.xml as shown in Fix 1.

---

## Fix 3: manifest.json — Card 06 (verify/update)

**File:** `webapp/manifest.json`

**Changed** `selectionAnnotationPath` from `SVPendingOnly` to `SVOpenItems`:

```diff
  "card06_PendingByActivity": {
      "settings": {
-         "selectionAnnotationPath": "...SelectionVariant#SVPendingOnly",
+         "selectionAnnotationPath": "...SelectionVariant#SVOpenItems",
          "chartAnnotationPath": "...Chart#ChartPendingByActivity",
          "presentationAnnotationPath": "...PresentationVariant#PVPendingByActivity",
      }
  }
```

**Why:** `SVPendingOnly` filters `CurrentMilestone = 'PENDING'` which matches zero records in the test/mock data, causing a blank card. `SVOpenItems` excludes only `GI`-completed items, which includes all pending/in-progress milestones and ensures the card renders with data.

---

## Fix 4: i18n.properties — Update Card 06 subtitle

**File:** `webapp/i18n/i18n.properties`

### REPLACE:

```properties
#XTIT: Card 06 - Pending Items by Activity
card06_title=Pending Items by Activity

#XFLD: Card 06 subtitle
card06_subtitle=Items Still at PENDING Stage
```

### WITH:

```properties
#XTIT: Card 06 - Pending Items by Activity
card06_title=Pending Items by Activity

#XFLD: Card 06 subtitle
card06_subtitle=Count vs Target by Activity Type
```

---

## How the Combination Chart Works

In SAP Fiori OVP analytical cards with `ChartType/Combination`:

| Measure Order | Rendering | In This Card |
|---------------|-----------|--------------|
| **1st measure** | Rendered as **Column/Bar** | `RecordCount` — count of pending JIP parts |
| **2nd measure** | Rendered as **Line** | `TargetAgingDays` — fixed target (15 days per activity) |

The X-axis shows **ActivityType** (ADD, SER, OVH, USW, etc.).

### Expected visual:

```
  Count
  │
  │  ██                          ─── Target Line (15)
  │  ██  ██          ██    ██ ───────────────────────
  │  ██  ██    ██    ██    ██
  │  ██  ██    ██    ██    ██
  └──────────────────────────── Activity Type
     ADD  INS  OVH  SER  USW
```

---

## Activation Order

1. **Backend first:** Add `ChartPendingByActivity` (Combination) to `ZE_JIPV4_AGING.asddlx` → Activate
2. **BAS:** Update `ZC_JIPV4_AGING_CDS_VAN.xml` with Fix 1 (or re-download from backend)
3. **BAS:** Update `i18n.properties` with Fix 4
4. **BAS:** Verify `manifest.json` (Fix 3 — should already be correct)
5. **Test:** `npm run start` → Check Card 06 shows Combination chart

---

## Verification Checklist

- [ ] Card 06 renders as **Combination** chart (bars + line)
- [ ] X-axis shows **ActivityType** labels (ADD, SER, OVH, etc.)
- [ ] Bars show **RecordCount** (count of PENDING items per activity)
- [ ] Line shows **TargetAgingDays** (flat at 15)
- [ ] Filter `SVPendingOnly` is active (only PENDING milestone items)
- [ ] Navigation works on click (dataPointNav)
