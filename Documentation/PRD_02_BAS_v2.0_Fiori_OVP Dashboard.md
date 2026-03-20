# PRD 02 BAS v2.0: Fiori OVP Implementation Guide

## JIP Milestone Aging Dashboard V4 — Full Development Guide

**Version 2.0 (BAS) — Consolidated & Implementation-Tested**

---

## 1. Overview

| Item | Value |
|------|-------|
| **Document** | PRD 02 BAS v2.0 — Frontend (Fiori OVP) |
| **Depends On** | PRD 01 v4.1 — Backend (CDS Views + MDE + OData V2) |
| **App Type** | SAP Fiori Elements — Overview Page (OVP) |
| **OData Version** | V2 (SADL via `@OData.publish: true`) |
| **OData Service** | `ZC_JIPV4_AGING_CDS` |
| **Entity Set** | `ZC_JIPV4_AGING` |
| **Dev Tool** | SAP Business Application Studio (BAS) |
| **Deploy Target** | ABAP Repository (BSP) on S/4HANA on-premise |
| **Total Cards** | 8 (6 analytical charts + 1 table + 1 list) |
| **S/4HANA Version** | On-premise |

### 1.1 Implementation Lessons Applied in This Version

| # | Lesson | Impact |
|---|--------|--------|
| 1 | `MSEG` is compatibility view on S/4HANA — use `MATDOC` | GI view source changed |
| 2 | `CAST` on RAW type not supported in CDS | BINMAT bridge pattern used |
| 3 | `@UI.selectionVariant` not supported in CDS MDE | Defined in `annotation.xml` |
| 4 | `targetValue` in `@UI.dataPoint` requires literal decimal, not field path | Removed from MDE, target rendered via dual-measure chart |
| 5 | `MATDOC.CANCELLED = 'X'` must be filtered out | Added `cancelled = ''` |
| 6 | `ZEILE` → `MBLPO`, `BUDAT_MKPF` → `BUDAT` in MATDOC | Field names mapped |

---

## 2. Prerequisites

### 2.1 Backend Checklist (Must Complete Before BAS)

| # | Item | Verify | Status |
|---|------|--------|--------|
| 1 | 9 CDS views activated | Eclipse ADT → F8 each view | [ ] |
| 2 | `ZC_JIPV4_AGING` has `@OData.publish: true` | Check CDS source | [ ] |
| 3 | `ZC_JIPV4_AGING` has `@Metadata.allowExtensions: true` | Check CDS source | [ ] |
| 4 | `TargetAgingDays` field in `ZI_JIPV4_PartsComposite` + `ZC_JIPV4_AGING` | F8 → verify column exists | [ ] |
| 5 | `ZE_JIPV4_AGING` MDE activated (no `targetValue` on TargetAgingDays) | ADT → Ctrl+F3 | [ ] |
| 6 | OData registered | `/IWFND/MAINT_SERVICE` → `ZC_JIPV4_AGING_CDS` | [ ] |
| 7 | OData metadata | `/IWFND/GW_CLIENT` → `$metadata` returns XML | [ ] |
| 8 | OData data | `/IWFND/GW_CLIENT` → `$top=10&$format=json` returns rows | [ ] |

### 2.2 BTP & BAS Setup

| # | Item | Where | Status |
|---|------|-------|--------|
| 1 | BTP Subaccount | SAP BTP Cockpit | [ ] |
| 2 | BAS subscription | BTP → Subscriptions → Business Application Studio | [ ] |
| 3 | Destination to S/4HANA | BTP → Connectivity → Destinations | [ ] |
| 4 | Cloud Connector (if on-prem) | Cloud Connector Admin UI | [ ] |

### 2.3 BTP Destination

```
Name:               S4HANA_DEV
Type:               HTTP
URL:                https://<your-s4hana-host>:<port>
Proxy Type:         OnPremise
Authentication:     BasicAuthentication
User:               <SAP_USER>
Password:           <SAP_PASSWORD>

Additional Properties:
  sap-client                = 030
  WebIDEUsage               = odata_abap,dev_abap
  WebIDEEnabled             = true
  WebIDESystem              = S4DEV
  HTML5.DynamicDestination  = true
```

---

## 3. Create Dev Space & Generate Project

### 3.1 Dev Space

1. Open BAS from BTP Cockpit
2. **Create Dev Space** → Name: `JIP_Dashboard_V4` → Type: **SAP Fiori**
3. Wait for RUNNING → Click to open

### 3.2 Generate OVP Project

**Ctrl+Shift+P** → `Fiori: Open Application Generator`

| Wizard Screen | Field | Value |
|--------------|-------|-------|
| **1. Template** | Template Type | SAP Fiori Elements |
| | Floorplan | **Overview Page** |
| **2. Data Source** | Source | Connect to an SAP System |
| | System | `S4HANA_DEV` |
| | Service | `ZC_JIPV4_AGING_CDS` |
| **3. Entity** | Entity Set | `ZC_JIPV4_AGING` |
| | Filter Entity | `ZC_JIPV4_AGING` |
| **4. Project** | Module Name | `zjipv4ovp` |
| | Title | `JIP Milestone Aging Dashboard V4` |
| | Namespace | `com.sap.pm.jipv4` |
| | Description | `JIP Parts Milestone Aging — OVP Dashboard` |
| | SAPUI5 Version | (latest) |
| | Add deployment | Yes |
| | Add FLP config | Yes |
| **5. Deploy** | Target | ABAP |
| | Destination | `S4HANA_DEV` |
| | BSP Name | `ZJIPV4_OVP` |
| | Package | Your package / `$TMP` |
| | Transport | Your TR |
| **6. FLP** | Semantic Object | `JIPAging` |
| | Action | `display` |
| | Title | `JIP Milestone Aging V4` |
| | Subtitle | `Parts Aging Dashboard` |

After generation:
```bash
cd zjipv4ovp
npm install
```

---

## 4. Project Structure

```
zjipv4ovp/
├── webapp/
│   ├── Component.js                    ← Auto-generated (don't edit)
│   ├── manifest.json                   ← ★ MAIN CONFIG — all cards here
│   ├── annotations/
│   │   └── annotation.xml              ← ★ LOCAL ANNOTATIONS — selection variants
│   ├── i18n/
│   │   └── i18n.properties             ← Card titles & translations
│   ├── localService/
│   │   └── metadata.xml                ← Local metadata for mock
│   └── test/
│       └── flpSandbox.html             ← FLP sandbox preview
├── ui5.yaml                            ← Build config
├── ui5-local.yaml                      ← Local preview proxy
├── package.json                        ← Scripts: start, build, deploy
└── xs-app.json                         ← App router (CF)
```

**Files you edit:** `manifest.json` (cards), `annotation.xml` (selection variants), `i18n.properties` (titles)

---

## 5. manifest.json — Data Source & Global Settings

### 5.1 Data Source (verify after generation)

```json
{
  "sap.app": {
    "id": "com.sap.pm.jipv4.zjipv4ovp",
    "type": "application",
    "title": "{{appTitle}}",
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/",
        "type": "OData",
        "settings": {
          "odataVersion": "2.0",
          "annotations": ["annotation0"],
          "localUri": "localService/metadata.xml"
        }
      },
      "annotation0": {
        "uri": "/sap/opu/odata/IWFND/CATALOGSERVICE;v=2/Annotations(TechnicalName='ZC_JIPV4_AGING_CDS',Version='0001')/$value/",
        "type": "ODataAnnotation",
        "settings": {
          "localUri": "annotations/annotation.xml"
        }
      }
    }
  }
}
```

### 5.2 OVP Global Settings

```json
{
  "sap.ovp": {
    "globalFilterModel": "mainService",
    "globalFilterEntityType": "ZC_JIPV4_AGINGType",
    "containerLayout": "resizable",
    "enableLiveFilter": true,
    "considerAnalyticalParameters": false,
    "showDateInRelativeFormat": false,
    "cards": {
    }
  }
}
```

---

## 6. Card-by-Card Design & manifest.json Configuration

### Dashboard Layout

```
╔══════════════════════════════════════════════════════════════════════╗
║  [Global Filter Bar]                                                ║
║  Plant | Activity Type | Aging Bucket | WM/EWM | LGNUM | Milestone ║
╠═══════════════════╦═══════════════════╦══════════════════════════════╣
║  CARD 01          ║  CARD 02          ║  CARD 03                    ║
║  JIP per Plant    ║  Historical JIP   ║  Aging per Plant            ║
║  [BAR]            ║  [STACKED COL]    ║  [STACKED COL]              ║
╠═══════════════════╬═══════════════════╬══════════════════════════════╣
║  CARD 04          ║  CARD 05          ║  CARD 06                    ║
║  Activity Break.  ║  Monthly Trend    ║  Avg Aging vs Target        ║
║  [BAR]            ║  [STACKED COL]    ║  [COMBINATION bar+line]     ║
╠═══════════════════╩═══════════════════╩══════════════════════════════╣
║  CARD 07                              ║  CARD 08                    ║
║  Detail Table                         ║  Critical Items List        ║
║  [TABLE]                              ║  [LIST — 60+/70+ only]      ║
╚═══════════════════════════════════════╩══════════════════════════════╝
```

---

### CARD 01: Total JIP per Plant

| Property | Value |
|----------|-------|
| Card ID | `card01_JIPPerPlant` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Horizontal Bar (`#BAR`) |
| Dimension | Plant (Category) |
| Measure | WorkOrderNumber (Count) |
| MDE Chart | `ChartJIPPerPlant` |
| MDE PV | `PVChartByPlant` |
| Purpose | Total JIP count per plant at a glance |
| Interaction | Click bar → global filter updates to that plant |

```json
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
}
```

---

### CARD 02: Historical JIP — All Plants

| Property | Value |
|----------|-------|
| Card ID | `card02_HistoricalJIP` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Stacked Column (`#COLUMN_STACKED`) |
| Dimension 1 | PeriodMonth (Category / X-axis) |
| Dimension 2 | AgingBucket (Series / Stack color) |
| Measure | WorkOrderNumber (Count) |
| MDE Chart | `ChartHistoricalJIP` |
| MDE PV | `PVChartHistorical` |
| Purpose | Monthly JIP trend with aging breakdown (Green=OK, Yellow=60+, Red=70+) |

```json
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
}
```

---

### CARD 03: Aging per Plant (Filtered)

| Property | Value |
|----------|-------|
| Card ID | `card03_AgingPerPlant` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Stacked Column (`#COLUMN_STACKED`) |
| Dimensions | PeriodMonth (Category) + AgingBucket (Series) |
| Measure | WorkOrderNumber (Count) |
| MDE Chart | `ChartAgingPerPlant` |
| Purpose | Same as Card 02 but plant-specific (reacts to Plant filter selection) |

```json
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
}
```

---

### CARD 04: Activity Type Breakdown

| Property | Value |
|----------|-------|
| Card ID | `card04_ActivityBreakdown` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Horizontal Bar (`#BAR`) |
| Dimension | ActivityType (Category) |
| Measure | WorkOrderNumber (Count) |
| MDE Chart | `ChartActivityBreakdown` |
| MDE PV | `PVChartActivity` |
| Purpose | Count breakdown across all 11 activity types (INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN) |

```json
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
}
```

---

### CARD 05: Monthly Trend by Activity

| Property | Value |
|----------|-------|
| Card ID | `card05_MonthlyTrend` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Stacked Column (`#COLUMN_STACKED`) |
| Dimension 1 | PeriodMonth (Category) |
| Dimension 2 | ActivityType (Series / Stack) |
| Measure | WorkOrderNumber (Count) |
| MDE Chart | `ChartMonthlyTrend` |
| Purpose | Monthly JIP count stacked by activity type |

```json
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
}
```

---

### CARD 06: Average Aging vs Target (★ Updated with Target Line)

| Property | Value |
|----------|-------|
| Card ID | `card06_AvgAging` |
| Template | `sap.ovp.cards.charts.analytical` |
| Chart Type | Combination (`#COMBINATION`) — bars + line |
| Dimension | PeriodMonth (Category) |
| Measure 1 | AgingRelease (bars — actual avg aging days) |
| Measure 2 | TargetAgingDays (line — fixed KPI target per ILART) |
| MDE Chart | `ChartAvgAgingWithTarget` |
| MDE PV | `PVAvgAgingTarget` |
| Purpose | Compare actual aging against target. Bars above line = exceeding target. |

**How Target Line Works:**
```
AVG AGING vs TARGET — BLP / ADD
 120│
 100│                                                          ██ Actual
  80│                                                     ██     (Bars)
  60│
  40│                                              ██
  20│  ██  ██      ██  ██  ██  ██  ██       ██
  15│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Target
   0│                                                     (Line)
     Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
```

**Target is dynamic per Activity Type** — when user changes Activity filter, `TargetAgingDays` changes automatically because it's a CDS CASE statement per ILART.

**Current target configuration (all default 15, customize in CDS later):**

| ILART | Target | ILART | Target | ILART | Target |
|-------|--------|-------|--------|-------|--------|
| ADD | 15 | MID | 15 | PPM | 15 |
| INS | 15 | NME | 15 | SER | 15 |
| LOG | 15 | OVH | 15 | TRS | 15 |
| | | PAP | 15 | UIW | 15 |
| | | | | USN | 15 |

> **To customize:** Update `ZI_JIPV4_PartsComposite` CASE statement — e.g., `when 'OVH' then 45`

**manifest.json:**
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

**MDE `@UI.dataPoint` for TargetAgingDays (NO `targetValue` — causes DecimalFloat error):**
```abap
  @UI.dataPoint: {
    title: 'Target Aging (Days)'
  }
  TargetAgingDays;
```

> **Implementation Note:** `targetValue` in `@UI.dataPoint` only accepts literal decimal values, not field references. The target line renders through the dual-measure `#COMBINATION` chart which draws `TargetAgingDays` as a line alongside `AgingRelease` as bars.

---

### CARD 07: Detail Table (Line Items)

| Property | Value |
|----------|-------|
| Card ID | `card07_DetailTable` |
| Template | `sap.ovp.cards.table` |
| Columns | All 20 `@UI.lineItem` fields from MDE |
| Default Sort | Plant ASC → AgingBucket DESC → ActivityType ASC |
| Criticality | AgingBucket colored Green/Yellow/Red |
| MDE PV | `DefaultSort` |
| SV | `SVOpenItems` (exclude GI completed) |

```json
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
}
```

**Columns (from MDE `@UI.lineItem`):**

| Pos | Field | Importance | Criticality |
|-----|-------|-----------|-------------|
| 10 | WorkOrderNumber | HIGH | — |
| 20 | MaterialNumber | HIGH | — |
| 25 | ABCIndicator | MEDIUM | — |
| 30 | Plant | HIGH | — |
| 40 | ActivityType | HIGH | — |
| 50 | AgingBucket | HIGH | AgingCriticality (G/Y/R) |
| 60 | CurrentMilestone | HIGH | — |
| 70 | WmEwmType | MEDIUM | — |
| 80 | WarehouseNumber | MEDIUM | — |
| 90 | SoldToParty | MEDIUM | — |
| 100 | AgingRelease | MEDIUM | — |
| 110 | QtyAvailCheck | MEDIUM | — |
| 120 | QtyWithdrawn | MEDIUM | — |
| 130-200 | Dates, GI Number, Period | LOW | — |

---

### CARD 08: Critical Items List

| Property | Value |
|----------|-------|
| Card ID | `card08_CriticalList` |
| Template | `sap.ovp.cards.list` |
| Filter | AgingBucket ≠ OK (only 60+ and 70+) |
| SV | `SVCriticalAging` |
| Purpose | Quick attention list for items exceeding aging threshold |

```json
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
```

---

## 7. annotation.xml — Selection Variants

`@UI.selectionVariant` is **NOT supported in CDS MDE syntax** (causes "selectOptions.name unknown" error). Define in local annotations instead.

### File: `webapp/annotations/annotation.xml`

```xml
<edmx:Edmx xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx" Version="4.0">
  <edmx:Reference Uri="/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/$metadata">
    <edmx:Include Namespace="cds_zjipv4aging" Alias="SAP"/>
  </edmx:Reference>
  <edmx:Reference Uri="https://sap.github.io/odata-vocabularies/vocabularies/UI.xml">
    <edmx:Include Namespace="com.sap.vocabularies.UI.v1" Alias="UI"/>
  </edmx:Reference>

  <edmx:DataServices>
    <Schema xmlns="http://docs.oasis-open.org/odata/ns/edm"
            Namespace="local.annotation">

      <Annotations Target="SAP.ZC_JIPV4_AGINGType">

        <!-- SVOpenItems: Exclude GI completed -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVOpenItems">
          <Record>
            <PropertyValue Property="Text" String="Open Items (Exclude GI)"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="CurrentMilestone"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/E"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="GI"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

        <!-- SVCriticalAging: Only 60+ and 70+ -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVCriticalAging">
          <Record>
            <PropertyValue Property="Text" String="Critical Aging (60+ and 70+)"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="AgingBucket"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/E"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="OK"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

        <!-- SVEWMOnly: EWM plants only -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVEWMOnly">
          <Record>
            <PropertyValue Property="Text" String="EWM Plants Only"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="WmEwmType"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/I"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="EWM"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

      </Annotations>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
```

---

## 8. Corrected MDE Reference (ZE_JIPV4_AGING)

For reference, here is the **tested and corrected** MDE with all implementation fixes applied:

```abap
@Metadata.layer: #CUSTOMER

@UI.headerInfo: {
  typeName: 'JIP Part',
  typeNamePlural: 'JIP Parts Aging',
  title: { type: #STANDARD, value: 'WorkOrderNumber' },
  description: { type: #STANDARD, value: 'MaterialNumber' }
}

@UI.chart: [
  { qualifier: 'ChartJIPPerPlant', title: 'Total JIP per Plant', chartType: #BAR,
    dimensions: ['Plant'], measures: ['WorkOrderNumber'],
    dimensionAttributes: [{ dimension: 'Plant', role: #CATEGORY }],
    measureAttributes: [{ measure: 'WorkOrderNumber', role: #AXIS_1, asDataPoint: true }] },

  { qualifier: 'ChartHistoricalJIP', title: 'Historical JIP - All Plants', chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'AgingBucket'], measures: ['WorkOrderNumber'],
    dimensionAttributes: [{ dimension: 'PeriodMonth', role: #CATEGORY }, { dimension: 'AgingBucket', role: #SERIES }],
    measureAttributes: [{ measure: 'WorkOrderNumber', role: #AXIS_1, asDataPoint: true }] },

  { qualifier: 'ChartAgingPerPlant', title: 'Aging per Plant', chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'AgingBucket'], measures: ['WorkOrderNumber'],
    dimensionAttributes: [{ dimension: 'PeriodMonth', role: #CATEGORY }, { dimension: 'AgingBucket', role: #SERIES }],
    measureAttributes: [{ measure: 'WorkOrderNumber', role: #AXIS_1, asDataPoint: true }] },

  { qualifier: 'ChartActivityBreakdown', title: 'Activity Type Breakdown', chartType: #BAR,
    dimensions: ['ActivityType'], measures: ['WorkOrderNumber'],
    dimensionAttributes: [{ dimension: 'ActivityType', role: #CATEGORY }],
    measureAttributes: [{ measure: 'WorkOrderNumber', role: #AXIS_1, asDataPoint: true }] },

  { qualifier: 'ChartMonthlyTrend', title: 'Monthly Trend by Activity', chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'ActivityType'], measures: ['WorkOrderNumber'],
    dimensionAttributes: [{ dimension: 'PeriodMonth', role: #CATEGORY }, { dimension: 'ActivityType', role: #SERIES }],
    measureAttributes: [{ measure: 'WorkOrderNumber', role: #AXIS_1, asDataPoint: true }] },

  { qualifier: 'ChartAvgAgingWithTarget', title: 'Avg Aging vs Target', chartType: #COMBINATION,
    dimensions: ['PeriodMonth'], measures: ['AgingRelease', 'TargetAgingDays'],
    dimensionAttributes: [{ dimension: 'PeriodMonth', role: #CATEGORY }],
    measureAttributes: [
      { measure: 'AgingRelease', role: #AXIS_1, asDataPoint: true },
      { measure: 'TargetAgingDays', role: #AXIS_1, asDataPoint: true }
    ] }
]

@UI.presentationVariant: [
  { qualifier: 'DefaultSort', text: 'Default',
    sortOrder: [{ by: 'Plant', direction: #ASC }, { by: 'AgingBucket', direction: #DESC }, { by: 'ActivityType', direction: #ASC }],
    visualizations: [{ type: #AS_LINEITEM }] },
  { qualifier: 'PVChartByPlant', text: 'By Plant',
    sortOrder: [{ by: 'Plant', direction: #ASC }],
    visualizations: [{ type: #AS_CHART, qualifier: 'ChartJIPPerPlant' }] },
  { qualifier: 'PVChartHistorical', text: 'Historical',
    sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
    visualizations: [{ type: #AS_CHART, qualifier: 'ChartHistoricalJIP' }] },
  { qualifier: 'PVChartActivity', text: 'By Activity',
    sortOrder: [{ by: 'ActivityType', direction: #ASC }],
    visualizations: [{ type: #AS_CHART, qualifier: 'ChartActivityBreakdown' }] },
  { qualifier: 'PVAvgAgingTarget', text: 'Avg Aging vs Target',
    sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
    visualizations: [{ type: #AS_CHART, qualifier: 'ChartAvgAgingWithTarget' }] }
]

// Selection Variants: defined in Fiori annotation.xml (not supported in CDS MDE syntax)

annotate view ZC_JIPV4_AGING with
{
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 10, label: 'Work Order' }]
  WorkOrderNumber;

  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  @UI.identification: [{ position: 20 }]
  MaterialNumber;

  @UI.lineItem: [{ position: 25, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 70 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 40, label: 'ABC Indicator' }]
  ABCIndicator;

  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  @UI.selectionField: [{ position: 10 }]
  @UI.identification: [{ position: 30 }]
  Plant;

  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @UI.selectionField: [{ position: 20 }]
  @UI.identification: [{ position: 40 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 30, label: 'Activity Type' }]
  ActivityType;

  @UI.lineItem: [{ position: 50, importance: #HIGH, criticality: 'AgingCriticality' }]
  @UI.selectionField: [{ position: 30 }]
  @UI.identification: [{ position: 50, criticality: 'AgingCriticality' }]
  @UI.dataPoint: { title: 'Aging Bucket', criticality: 'AgingCriticality' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 50, label: 'Aging Bucket', criticality: 'AgingCriticality' }]
  AgingBucket;

  @UI.lineItem: [{ position: 60, importance: #HIGH }]
  @UI.selectionField: [{ position: 60 }]
  @UI.dataPoint: { title: 'Current Milestone' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 30, label: 'Current Milestone' }]
  CurrentMilestone;

  @UI.lineItem: [{ position: 70, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 40 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 10, label: 'WM/EWM Type' }]
  WmEwmType;

  @UI.lineItem: [{ position: 80, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 50 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 20, label: 'Warehouse Number' }]
  WarehouseNumber;

  @UI.lineItem: [{ position: 90, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpCustomer', position: 10, label: 'Sold To Party' }]
  SoldToParty;

  @UI.lineItem: [{ position: 100, importance: #MEDIUM }]
  @UI.dataPoint: { title: 'Aging Release (Days)', criticality: 'AgingCriticality' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 40, label: 'Aging Release (Days)' }]
  AgingRelease;

  @UI.lineItem: [{ position: 110, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 10, label: 'Qty Avail Check' }]
  QtyAvailCheck;

  @UI.lineItem: [{ position: 120, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 20, label: 'Qty Withdrawn (GI)' }]
  QtyWithdrawn;

  @UI.lineItem: [{ position: 130, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 10, label: 'SDH Approval' }]
  SDHApprovalDate;

  @UI.lineItem: [{ position: 140, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 20, label: 'Release Date (FTRMI)' }]
  ReleaseDate;

  @UI.lineItem: [{ position: 150, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 30, label: 'TR Date (WM)' }]
  WM_TRDate;

  @UI.lineItem: [{ position: 160, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 40, label: 'Received Date (WM)' }]
  WM_ReceivedDate;

  @UI.lineItem: [{ position: 170, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 50, label: 'Confirmed At (EWM)' }]
  EWM_ConfirmedAt;

  @UI.lineItem: [{ position: 180, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 60, label: 'GI Date' }]
  GIDate;

  @UI.lineItem: [{ position: 190, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 70, label: 'GI Number' }]
  GINumber;

  @UI.lineItem: [{ position: 200, importance: #LOW }]
  @UI.selectionField: [{ position: 80 }]
  PeriodMonth;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 20, label: 'Order Type' }]
  OrderType;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 50, label: 'WO Creation Date' }]
  WOCreationDate;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 60, label: 'Equipment' }]
  EquipmentNumber;

  // TargetAgingDays — NO targetValue (causes DecimalFloat error)
  @UI.dataPoint: { title: 'Target Aging (Days)' }
  TargetAgingDays;
}
```

---

## 9. i18n — Complete File

### `webapp/i18n/i18n.properties`

```properties
# App
appTitle=JIP Milestone Aging Dashboard V4
appDescription=JIP Parts Milestone Aging — Overview Page

# Cards
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

## 10. Run, Test & Deploy

### 10.1 Run
```bash
npm run start
```

### 10.2 Verification Matrix

| Card | What to Check | Expected |
|------|--------------|----------|
| Filter bar | 8 filter fields | Plant, ActivityType, AgingBucket, WmEwmType, WarehouseNumber, CurrentMilestone, ABCIndicator, PeriodMonth |
| Card 01 | Horizontal bars | One bar per plant with count |
| Card 02 | Stacked columns | Months on X, stacked OK/60+/70+ |
| Card 03 | Stacked columns | Same as 02 but filters by selected plant |
| Card 04 | Horizontal bars | One bar per activity type |
| Card 05 | Stacked columns | Months on X, stacked by activity |
| Card 06 | Bars + flat line | Bars = actual aging, Line = target (15 days default) |
| Card 07 | Data table | 20 columns, sorted by AgingBucket DESC |
| Card 08 | Condensed list | Only 60+ and 70+ items shown |
| Colors | Criticality | Green=OK, Yellow=60+, Red=70+ |
| Filter interaction | Global filter | All cards react to filter changes |

### 10.3 Deploy
```bash
npm run build
npm run deploy
```

### 10.4 Post-Deploy (SAP GUI)

| # | Transaction | Action |
|---|------------|--------|
| 1 | `/UI5/APP_INDEX_CALCULATE` | Refresh app index |
| 2 | `/UI2/FLPD_CUST` | Create catalog `ZJIPV4_CAT`, target mapping (Semantic: `JIPAging`, Action: `display`), tile |
| 3 | PFCG | Assign catalog to role |

---

## 11. Annotation Location Summary

| Annotation | Where | Why |
|-----------|-------|-----|
| `@UI.headerInfo` | CDS MDE | Supported |
| `@UI.chart` (6 charts) | CDS MDE | Supported |
| `@UI.presentationVariant` (5 PVs) | CDS MDE | Supported |
| `@UI.lineItem` (20 cols) | CDS MDE | Supported |
| `@UI.selectionField` (8 filters) | CDS MDE | Supported |
| `@UI.dataPoint` (3 DPs) | CDS MDE | Supported — but NO `targetValue` with field ref |
| `@UI.identification` | CDS MDE | Supported |
| `@UI.fieldGroup` (5 groups) | CDS MDE | Supported |
| **`@UI.selectionVariant`** (3 SVs) | **annotation.xml** | **NOT supported in CDS MDE** |

---

## 12. Troubleshooting

| # | Issue | Cause | Fix |
|---|-------|-------|-----|
| 1 | No data in cards | OData empty | Test `/IWFND/GW_CLIENT` |
| 2 | Charts blank | Qualifier mismatch | Match `chartAnnotationPath` to MDE exactly |
| 3 | No filter bar | MDE not active | Activate `ZE_JIPV4_AGING` |
| 4 | No colors | Missing field | `AgingCriticality` must be in CDS select |
| 5 | Service unavailable | Destination wrong | Check BTP destination props |
| 6 | CORS error | Proxy wrong | Check `ui5-local.yaml` |
| 7 | SV error in MDE | CDS doesn't support it | Use `annotation.xml` |
| 8 | `targetValue` DecimalFloat error | Field ref not allowed | Remove `targetValue`, use dual-measure chart |
| 9 | MSEG returns empty | S/4HANA compat view | Use `MATDOC` table |
| 10 | CAST RAW error | Not supported in CDS | Use BINMAT bridge pattern |
| 11 | App not in Launchpad | Index stale | `/UI5/APP_INDEX_CALCULATE` |
| 12 | Cards overlap | Layout wrong | `containerLayout: "resizable"` |

---

## 13. Complete Checklist

### Backend Verified
- [ ] 9 CDS views activated (F8 returns data)
- [ ] `TargetAgingDays` field exists in CDS
- [ ] `@Metadata.allowExtensions: true` on consumption view
- [ ] MDE activated (no `targetValue` on TargetAgingDays)
- [ ] OData registered and returning data

### BAS Project
- [ ] Dev Space running
- [ ] Destination configured
- [ ] OVP project generated
- [ ] `npm install` done

### Cards Configured
- [ ] Card 01: JIP per Plant (BAR)
- [ ] Card 02: Historical JIP (STACKED COLUMN)
- [ ] Card 03: Aging per Plant (STACKED COLUMN)
- [ ] Card 04: Activity Breakdown (BAR)
- [ ] Card 05: Monthly Trend (STACKED COLUMN)
- [ ] Card 06: Avg Aging vs Target (COMBINATION — bars + target line)
- [ ] Card 07: Detail Table (TABLE)
- [ ] Card 08: Critical Items (LIST)

### Annotations
- [ ] `annotation.xml` has 3 SVs (OpenItems, CriticalAging, EWMOnly)
- [ ] i18n has all card titles

### Testing
- [ ] Local preview works
- [ ] 8 filters visible
- [ ] 8 cards render with data
- [ ] Colors: Green=OK, Yellow=60+, Red=70+
- [ ] Card 06 shows bars + target line
- [ ] Target line changes with Activity Type filter
- [ ] Global filter affects all cards

### Deployed
- [ ] Build success
- [ ] Deploy to ABAP repository
- [ ] App index refreshed
- [ ] Tile in Launchpad
- [ ] Role assigned in PFCG
- [ ] End-to-end: Launchpad → Tile → Dashboard → Filter → All cards work

---

## 14. Version History

| Version | Date | Changes |
|---------|------|---------|
| BAS 1.0 | 2026-03 | Initial OVP guide with 7 cards |
| BAS 1.1 | 2026-03 | Card-by-card detail, annotation.xml for SVs |
| BAS 1.2 | 2026-03 | Card 06 target line, TargetAgingDays field |
| **BAS 2.0** | **2026-03** | **Full consolidation. All implementation fixes: (1) targetValue DecimalFloat error fixed. (2) Corrected MDE included. (3) MATDOC/BINMAT bridge notes. (4) Card 08 added (Critical List). (5) annotation.xml with SVs. (6) Complete manifest.json for all 8 cards. (7) 12-item troubleshooting. (8) 30-item checklist across 5 phases.** |
