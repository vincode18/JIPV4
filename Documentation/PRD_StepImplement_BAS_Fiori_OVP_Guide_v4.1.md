# PRD 02: Fiori OVP Implementation — SAP Business Application Studio

## JIP Milestone Aging Dashboard V4 — Card-by-Card Development Guide

**Version 4.1 — Companion to PRD 01 (CDS Creation)**

---

## 1. Overview

| Item | Value |
|------|-------|
| **Document** | PRD 02 — Frontend (Fiori OVP via BAS) |
| **Depends On** | PRD 01 — Backend (CDS Views + OData V2 Service) |
| **App Type** | SAP Fiori Elements — Overview Page (OVP) |
| **OData Version** | V2 (via `@OData.publish: true` / SADL) |
| **OData Service** | `ZC_JIPV4_AGING_CDS` |
| **Entity Set** | `ZC_JIPV4_AGING` |
| **Development Tool** | SAP Business Application Studio (BAS) |
| **Deployment Target** | ABAP Repository (BSP) on S/4HANA |
| **Total Cards** | 8 (6 chart cards + 1 table card + 1 list card) |

---

## 2. Prerequisites

### 2.1 Backend (must be completed before starting BAS)

| # | Item | How to Verify | Status |
|---|------|--------------|--------|
| 1 | All 9 CDS views activated | Eclipse ADT → F8 on each view | [ ] |
| 2 | `ZC_JIPV4_AGING` has `@OData.publish: true` | Check annotation in CDS code | [ ] |
| 3 | `ZC_JIPV4_AGING` has `@Metadata.allowExtensions: true` | Check annotation in CDS code | [ ] |
| 4 | `ZE_JIPV4_AGING` Metadata Extension activated | Eclipse ADT → Ctrl+F3 | [ ] |
| 5 | OData service registered | `/IWFND/MAINT_SERVICE` → search `ZC_JIPV4_AGING_CDS` | [ ] |
| 6 | OData metadata works | `/IWFND/GW_CLIENT` → `GET .../ZC_JIPV4_AGING_CDS/$metadata` | [ ] |
| 7 | OData returns data | `/IWFND/GW_CLIENT` → `GET .../ZC_JIPV4_AGING?$top=10&$format=json` | [ ] |

### 2.2 BTP & BAS Setup

| # | Item | Where | Status |
|---|------|-------|--------|
| 1 | BTP Subaccount exists | SAP BTP Cockpit | [ ] |
| 2 | BAS subscription activated | BTP Cockpit → Subscriptions → SAP Business Application Studio | [ ] |
| 3 | Destination to S/4HANA configured | BTP Cockpit → Connectivity → Destinations | [ ] |
| 4 | Cloud Connector running (if on-premise) | Cloud Connector Admin UI | [ ] |

### 2.3 BTP Destination Configuration

Create destination in BTP Cockpit → Connectivity → Destinations → New Destination:

```
Name:               S4HANA_DEV
Type:               HTTP
URL:                https://<your-s4hana-host>:<port>
Proxy Type:         OnPremise
Authentication:     BasicAuthentication
User:               <SAP_USER>
Password:           <SAP_PASSWORD>

Additional Properties:
  sap-client              = 030
  WebIDEUsage             = odata_abap,dev_abap
  WebIDEEnabled           = true
  WebIDESystem            = S4DEV
  HTML5.DynamicDestination = true
```

> **Test:** In BAS, open Terminal → `curl $destinations_S4HANA_DEV/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/$metadata` should return XML.

---

## 3. Create Dev Space & Generate Project

### 3.1 Create Dev Space

1. Open BAS from BTP Cockpit
2. Click **Create Dev Space**
3. Settings:

| Field | Value |
|-------|-------|
| Name | `JIP_Dashboard_V4` |
| Type | **SAP Fiori** |
| Additional Extensions | (default) |

4. Wait for **RUNNING** status → Click to open

### 3.2 Generate OVP Project

1. **Ctrl+Shift+P** → `Fiori: Open Application Generator`
2. Walk through the wizard:

**Screen 1 — Template:**

| Field | Value |
|-------|-------|
| Template Type | SAP Fiori Elements |
| Floorplan | **Overview Page** |

**Screen 2 — Data Source:**

| Field | Value |
|-------|-------|
| Data Source | Connect to an SAP System |
| System | `S4HANA_DEV` |
| Service | `ZC_JIPV4_AGING_CDS` |

**Screen 3 — Entity:**

| Field | Value |
|-------|-------|
| OData Entity Set | `ZC_JIPV4_AGING` |
| Filter Entity | `ZC_JIPV4_AGING` |

**Screen 4 — Project Attributes:**

| Field | Value |
|-------|-------|
| Module Name | `zjipv4ovp` |
| Application Title | `JIP Milestone Aging Dashboard V4` |
| Application Namespace | `com.sap.pm.jipv4` |
| Description | `JIP Parts Milestone Aging — OVP Dashboard` |
| Minimum SAPUI5 Version | (use latest) |
| Add deployment config | Yes |
| Add FLP config | Yes |

**Screen 5 — Deployment:**

| Field | Value |
|-------|-------|
| Target | ABAP |
| Destination | `S4HANA_DEV` |
| SAPUI5 ABAP Repository | `ZJIPV4_OVP` |
| Package | Your package (or `$TMP`) |
| Transport Request | Your TR |

**Screen 6 — FLP:**

| Field | Value |
|-------|-------|
| Semantic Object | `JIPAging` |
| Action | `display` |
| Title | `JIP Milestone Aging V4` |
| Subtitle | `Parts Aging Dashboard` |

3. Click **Finish** → Wait for generation
4. Run `npm install` in Terminal

---

## 4. Project File Structure

```
zjipv4ovp/
├── webapp/
│   ├── Component.js                    ← App component (auto-generated)
│   ├── manifest.json                   ← ★ MAIN CONFIG — cards, model, FLP
│   ├── annotations/
│   │   └── annotation.xml              ← ★ LOCAL ANNOTATIONS — selection variants
│   ├── i18n/
│   │   └── i18n.properties             ← Translations
│   ├── localService/
│   │   └── metadata.xml                ← Local metadata cache
│   └── test/
│       ├── flpSandbox.html             ← FLP sandbox for testing
│       └── integration/
├── ui5.yaml                            ← Build config
├── ui5-local.yaml                      ← Local preview proxy
├── package.json                        ← Dependencies & scripts
└── xs-app.json                         ← App router (Cloud Foundry)
```

**Key files you will edit:**
1. `manifest.json` — Card definitions (Section 5–6)
2. `annotations/annotation.xml` — Selection variants (Section 7)
3. `i18n/i18n.properties` — Card titles for translation (optional)

---

## 5. manifest.json — Global Configuration

### 5.1 Data Source (auto-generated, verify)

```json
{
  "sap.app": {
    "id": "com.sap.pm.jipv4.zjipv4ovp",
    "type": "application",
    "title": "JIP Milestone Aging Dashboard V4",
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

Add/update in `sap.ovp` section:

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
      // ... cards defined in Section 6 ...
    }
  }
}
```

---

## 6. Card-by-Card Design & Configuration

### Dashboard Layout Reference

```
╔══════════════════════════════════════════════════════════════════════╗
║  [Global Filter Bar]                                                ║
╠═══════════════════╦═══════════════════╦══════════════════════════════╣
║  CARD 01          ║  CARD 02          ║  CARD 03                    ║
║  JIP per Plant    ║  Historical JIP   ║  Aging per Plant            ║
║  [BAR]            ║  [STACKED COL]    ║  [STACKED COL]              ║
╠═══════════════════╬═══════════════════╬══════════════════════════════╣
║  CARD 04          ║  CARD 05          ║  CARD 06                    ║
║  Activity Break.  ║  Monthly Trend    ║  Avg Aging                  ║
║  [BAR]            ║  [STACKED COL]    ║  [COMBINATION]              ║
╠═══════════════════╩═══════════════════╩══════════════════════════════╣
║  CARD 07                              ║  CARD 08                    ║
║  Detail Table                         ║  Critical Items List        ║
║  [TABLE]                              ║  [LIST]                     ║
╚═══════════════════════════════════════╩══════════════════════════════╝
```

---

### CARD 01: Total JIP per Plant

| Property | Value |
|----------|-------|
| **Card ID** | `card01_JIPPerPlant` |
| **Type** | Analytical Chart Card |
| **Chart** | Horizontal Bar |
| **Dimension** | Plant (X-axis) |
| **Measure** | Count of WorkOrderNumber (Y-axis) |
| **MDE Qualifier** | `ChartJIPPerPlant` |
| **PV Qualifier** | `PVChartByPlant` |
| **Purpose** | Show total JIP count per plant at a glance |
| **Interaction** | Click bar → filter dashboard by that plant |

**manifest.json:**
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

**i18n/i18n.properties:**
```
card01_title=Total JIP per Plant
```

---

### CARD 02: Historical JIP — All Plants

| Property | Value |
|----------|-------|
| **Card ID** | `card02_HistoricalJIP` |
| **Type** | Analytical Chart Card |
| **Chart** | Stacked Column |
| **Dimension 1** | PeriodMonth (X-axis / Category) |
| **Dimension 2** | AgingBucket (Series / Stack) |
| **Measure** | Count of WorkOrderNumber |
| **MDE Qualifier** | `ChartHistoricalJIP` |
| **PV Qualifier** | `PVChartHistorical` |
| **Purpose** | Show JIP trend over months with aging breakdown (OK/60+/70+) |
| **Color** | Green=OK, Yellow=60+, Red=70+ (via criticality) |

**manifest.json:**
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

**i18n:**
```
card02_title=Historical JIP - All Plants
```

---

### CARD 03: Aging per Plant (Filtered)

| Property | Value |
|----------|-------|
| **Card ID** | `card03_AgingPerPlant` |
| **Type** | Analytical Chart Card |
| **Chart** | Stacked Column |
| **Dimension 1** | PeriodMonth (X-axis) |
| **Dimension 2** | AgingBucket (Series) |
| **Measure** | Count of WorkOrderNumber |
| **MDE Qualifier** | `ChartAgingPerPlant` |
| **Purpose** | Same as Card 02 but reacts to Plant filter (plant-specific view) |
| **Behavior** | When user selects a plant in filter bar, this card shows only that plant |

**manifest.json:**
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

**i18n:**
```
card03_title=Aging per Plant
```

---

### CARD 04: Activity Type Breakdown

| Property | Value |
|----------|-------|
| **Card ID** | `card04_ActivityBreakdown` |
| **Type** | Analytical Chart Card |
| **Chart** | Horizontal Bar |
| **Dimension** | ActivityType (X-axis) |
| **Measure** | Count of WorkOrderNumber |
| **MDE Qualifier** | `ChartActivityBreakdown` |
| **PV Qualifier** | `PVChartActivity` |
| **Purpose** | Show count breakdown by activity type (INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN) |

**manifest.json:**
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

**i18n:**
```
card04_title=Activity Type Breakdown
```

---

### CARD 05: Monthly Trend by Activity

| Property | Value |
|----------|-------|
| **Card ID** | `card05_MonthlyTrend` |
| **Type** | Analytical Chart Card |
| **Chart** | Stacked Column |
| **Dimension 1** | PeriodMonth (X-axis / Category) |
| **Dimension 2** | ActivityType (Series / Stack) |
| **Measure** | Count of WorkOrderNumber |
| **MDE Qualifier** | `ChartMonthlyTrend` |
| **Purpose** | Show monthly JIP trend stacked by activity type |

**manifest.json:**
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

**i18n:**
```
card05_title=Monthly Trend by Activity
```

---

### CARD 06: Average Aging by Plant & Activity

| Property | Value |
|----------|-------|
| **Card ID** | `card06_AvgAging` |
| **Type** | Analytical Chart Card |
| **Chart** | Combination (Bar + Line) |
| **Dimension 1** | Plant (Category) |
| **Dimension 2** | ActivityType (Series) |
| **Measure** | AgingRelease (average days) |
| **MDE Qualifier** | `ChartAvgAging` |
| **Purpose** | Show average aging days per plant, broken down by activity type |

**manifest.json:**
```json
"card06_AvgAging": {
  "model": "mainService",
  "template": "sap.ovp.cards.charts.analytical",
  "settings": {
    "title": "{{card06_title}}",
    "subtitle": "Combination Chart",
    "entitySet": "ZC_JIPV4_AGING",
    "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAvgAging",
    "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#AgingRelease",
    "navigation": "dataPointNav",
    "identificationAnnotationPath": "com.sap.vocabularies.UI.v1.Identification"
  }
}
```

**i18n:**
```
card06_title=Avg Aging by Plant & Activity
```

---

### CARD 07: Detail Table (Line Items)

| Property | Value |
|----------|-------|
| **Card ID** | `card07_DetailTable` |
| **Type** | Table Card |
| **Columns** | All `@UI.lineItem` fields from MDE (20 columns) |
| **Default Sort** | Plant ASC, AgingBucket DESC, ActivityType ASC |
| **Criticality** | AgingBucket column colored by AgingCriticality |
| **MDE Source** | `@UI.lineItem` annotations |
| **PV Qualifier** | `DefaultSort` |
| **Purpose** | Full detail view of all JIP items with sortable columns |

**manifest.json:**
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

**i18n:**
```
card07_title=JIP Parts Detail
```

**Columns displayed (from MDE @UI.lineItem):**

| Pos | Field | Importance | Criticality |
|-----|-------|-----------|-------------|
| 10 | WorkOrderNumber | HIGH | — |
| 20 | MaterialNumber | HIGH | — |
| 25 | ABCIndicator | MEDIUM | — |
| 30 | Plant | HIGH | — |
| 40 | ActivityType | HIGH | — |
| 50 | AgingBucket | HIGH | AgingCriticality (Green/Yellow/Red) |
| 60 | CurrentMilestone | HIGH | — |
| 70 | WmEwmType | MEDIUM | — |
| 80 | WarehouseNumber | MEDIUM | — |
| 90 | SoldToParty | MEDIUM | — |
| 100 | AgingRelease | MEDIUM | — |
| 110-200 | Dates, Quantities, etc. | LOW | — |

---

### CARD 08: Critical Items List

| Property | Value |
|----------|-------|
| **Card ID** | `card08_CriticalList` |
| **Type** | List Card |
| **Filter** | AgingBucket ≠ OK (only 60+ and 70+ items) |
| **Columns** | WorkOrderNumber, MaterialNumber, Plant, AgingBucket, CurrentMilestone |
| **SV Qualifier** | `SVCriticalAging` |
| **Purpose** | Quick view of items requiring attention (aging 60+ days) |

**manifest.json:**
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

**i18n:**
```
card08_title=Critical Aging Items
```

---

## 7. Local Annotations — annotation.xml

Since `@UI.selectionVariant` is NOT supported in CDS MDE syntax, define them here:

### 7.1 File: `webapp/annotations/annotation.xml`

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

        <!-- SV: Open Items (Exclude GI completed) -->
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

        <!-- SV: Critical Aging (60+ and 70+ only) -->
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

        <!-- SV: EWM Plants Only -->
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

> **Why here and not in CDS MDE?** `@UI.selectionVariant` with `selectOptions/ranges` is only supported in OData vocabulary XML (local annotations), not in CDS annotation syntax. Attempting it in MDE causes: "Annotation 'UI.selectionVariant.selectOptions.name' unknown".

---

## 8. i18n — Complete Translation File

### `webapp/i18n/i18n.properties`

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
card06_title=Avg Aging by Plant & Activity
card07_title=JIP Parts Detail
card08_title=Critical Aging Items

# Card Subtitles
card01_subtitle=Count by Plant
card02_subtitle=Monthly by Aging Bucket
card03_subtitle=Monthly Aging by Plant
card04_subtitle=Count by Activity Type
card05_subtitle=Activity Type Stacked Monthly
card06_subtitle=Combination Chart
card07_subtitle=All JIP Items
card08_subtitle=60+ and 70+ Items
```

---

## 9. Run & Preview

### 9.1 Install Dependencies

```bash
cd zjipv4ovp
npm install
```

### 9.2 Preview

**Option A — Right-click:**
Right-click `webapp` → **Preview Application** → Choose `start-noflp`

**Option B — Terminal:**
```bash
npm run start
```

**Option C — FLP Sandbox:**
```bash
npm run start-local
```
Opens `test/flpSandbox.html` with the full Fiori Launchpad experience.

### 9.3 What to Verify

| Check | Expected | If Wrong |
|-------|----------|---------|
| Filter bar appears | 8 filters (Plant, ActivityType, AgingBucket, WmEwmType, WarehouseNumber, CurrentMilestone, ABCIndicator, PeriodMonth) | Check `@UI.selectionField` in MDE |
| Card 01 shows bars | Horizontal bars by Plant | Check `ChartJIPPerPlant` qualifier |
| Card 02 shows stacked | Month x AgingBucket stacked | Check `ChartHistoricalJIP` qualifier |
| Card 07 shows table | All lineItem columns visible | Check `@UI.lineItem` in MDE |
| Colors appear | Green/Yellow/Red on AgingBucket | Check `AgingCriticality` field in CDS |
| Card 08 filters | Only 60+ and 70+ items | Check `SVCriticalAging` in annotation.xml |
| Cards respond to filter | Selecting Plant filters all cards | OVP global filter behavior |

---

## 10. Deploy to ABAP Repository

### 10.1 Build

```bash
npm run build
```

### 10.2 Deploy

```bash
npm run deploy
```

Or: **Ctrl+Shift+P** → `Fiori: Deploy Application`

| Field | Value |
|-------|-------|
| Destination | `S4HANA_DEV` |
| BSP Name | `ZJIPV4_OVP` |
| Package | Your package |
| Transport | Your TR |

### 10.3 Post-Deploy (SAP GUI)

1. **`/UI5/APP_INDEX_CALCULATE`** — Refresh app index
2. **`/UI2/FLPD_CUST`** — Create catalog, tile, target mapping
3. **PFCG** — Assign catalog to role

---

## 11. Fiori Launchpad Registration

### 11.1 Create in `/UI2/FLPD_CUST`

**Catalog:**

| Field | Value |
|-------|-------|
| Catalog ID | `ZJIPV4_CAT` |
| Title | `JIP Milestone Aging V4` |

**Target Mapping:**

| Field | Value |
|-------|-------|
| Semantic Object | `JIPAging` |
| Action | `display` |
| Application Type | SAPUI5 Fiori App |
| URL | `/sap/bc/ui5_ui5/sap/zjipv4_ovp` |
| Component | `com.sap.pm.jipv4.zjipv4ovp` |

**Tile:**

| Field | Value |
|-------|-------|
| Title | `JIP Milestone Aging V4` |
| Subtitle | `Parts Aging Dashboard` |
| Icon | `sap-icon://bar-chart` |
| Semantic Object | `JIPAging` |
| Action | `display` |

### 11.2 Assign to Role (PFCG)

1. Open PFCG → Your role
2. Menu tab → Add catalog `ZJIPV4_CAT`
3. Generate profile → Save

---

## 12. Annotation Source Summary

Where each annotation type is defined:

| Annotation | Location | Why |
|-----------|----------|-----|
| `@UI.headerInfo` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.chart` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.presentationVariant` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.lineItem` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.selectionField` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.dataPoint` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.identification` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| `@UI.fieldGroup` | CDS MDE (`ZE_JIPV4_AGING`) | Supported in CDS |
| **`@UI.selectionVariant`** | **`annotation.xml`** (local) | **NOT supported in CDS MDE** |

---

## 13. Troubleshooting

| # | Issue | Cause | Fix |
|---|-------|-------|-----|
| 1 | Cards show "No data" | OData returns empty | Test in `/IWFND/GW_CLIENT` |
| 2 | Charts don't render | Qualifier mismatch | Match `chartAnnotationPath` exactly to MDE `@UI.chart` qualifier |
| 3 | Filter bar empty | MDE not activated | Activate `ZE_JIPV4_AGING` in ADT |
| 4 | No criticality colors | Missing field | Ensure `AgingCriticality` in `ZC_JIPV4_AGING` select list |
| 5 | "Service unavailable" | Destination wrong | Check BTP destination WebIDEEnabled/sap-client |
| 6 | CORS error | Proxy misconfigured | Check `ui5-local.yaml` backend section |
| 7 | Selection variant error | Used in MDE | Move to `annotation.xml` (Section 7) |
| 8 | App not in Launchpad | Index stale | Run `/UI5/APP_INDEX_CALCULATE` |
| 9 | Cards overlap/wrong size | Layout not resizable | Set `containerLayout: "resizable"` in manifest |
| 10 | Deploy fails | TR locked/missing | Check SE09 |
| 11 | Metadata errors | MDE has old cache | `/IWFND/MAINT_SERVICE` → Clear metadata cache |
| 12 | Global filter not filtering cards | Entity type mismatch | Check `globalFilterEntityType` matches |

---

## 14. Development Checklist

### Phase 1: Backend Verification
- [ ] OData service `ZC_JIPV4_AGING_CDS` registered and returning data
- [ ] MDE `ZE_JIPV4_AGING` activated with charts, lineItems, selectionFields, dataPoints
- [ ] `@Metadata.allowExtensions: true` on `ZC_JIPV4_AGING`

### Phase 2: BAS Project Setup
- [ ] BAS Dev Space running (SAP Fiori type)
- [ ] BTP Destination configured with WebIDEEnabled
- [ ] OVP project generated from template
- [ ] `npm install` completed

### Phase 3: Card Configuration
- [ ] Card 01: JIP per Plant (BAR chart) configured
- [ ] Card 02: Historical JIP (STACKED COLUMN) configured
- [ ] Card 03: Aging per Plant (STACKED COLUMN) configured
- [ ] Card 04: Activity Breakdown (BAR chart) configured
- [ ] Card 05: Monthly Trend (STACKED COLUMN) configured
- [ ] Card 06: Avg Aging (COMBINATION chart) configured
- [ ] Card 07: Detail Table (TABLE) configured
- [ ] Card 08: Critical Items (LIST) configured

### Phase 4: Annotations
- [ ] `annotation.xml` has 3 selection variants (SVOpenItems, SVCriticalAging, SVEWMOnly)
- [ ] i18n.properties has all card titles

### Phase 5: Testing
- [ ] Local preview works (`npm run start`)
- [ ] Filter bar shows 8 filters
- [ ] All 8 cards render with data
- [ ] Criticality colors: Green=OK, Yellow=60+, Red=70+
- [ ] Global filter affects all cards

### Phase 6: Deployment
- [ ] `npm run build` succeeds
- [ ] `npm run deploy` to ABAP repository
- [ ] `/UI5/APP_INDEX_CALCULATE` refreshed
- [ ] Tile visible in Fiori Launchpad
- [ ] Catalog assigned to role in PFCG
- [ ] End-to-end: Launchpad → Tile → Dashboard → Filter → Charts → Table
