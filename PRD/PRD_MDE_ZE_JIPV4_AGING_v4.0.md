# PRD: Metadata Extension — JIP Milestone Aging Dashboard V4

## ZE_JIPV4_AGING (Metadata Extension for ZC_JIPV4_AGING)

**Version 4.0 — Companion to PRD JIP Milestone Aging Dashboard V4**

---

## 1. Purpose

The Metadata Extension (MDE) separates all UI annotations from the CDS Consumption View `ZC_JIPV4_AGING`. This provides:

| Benefit | Explanation |
|---------|-------------|
| **Faster OData metadata load** | SADL caches annotation layer independently from CDS view definition |
| **No CDS reactivation** | Changing dashboard layout, columns, charts only touches MDE — no need to reactivate CDS view or regenerate OData service |
| **Clean separation** | CDS view handles data logic; MDE handles presentation logic |
| **Easier maintenance** | Dashboard team can modify UI without touching data layer |
| **Transport independence** | MDE and CDS can be transported separately |

---

## 2. Annotation Types Included

| # | Annotation | Purpose | Used For |
|---|-----------|---------|----------|
| 1 | `@UI.headerInfo` | Entity title and description in object pages | Page header when drilling into a record |
| 2 | `@UI.selectionField` | Filter bar fields | Plant, Activity Type, Aging Bucket, WM/EWM, Warehouse, Milestone, ABC |
| 3 | `@UI.lineItem` | Columns in the detail table | All visible columns with position and criticality |
| 4 | `@UI.chart` | Chart card definitions for OVP | 6 chart cards (bar, stacked column, donut, combination) |
| 5 | `@UI.dataPoint` | KPI values with criticality coloring | Aging bucket color (green/yellow/red), count KPIs |
| 6 | `@UI.presentationVariant` | Default sort order | Sort by Plant, then AgingBucket descending |
| 7 | `@UI.selectionVariant` | Default filter presets | Pre-filter for "open items" (exclude GI completed) |
| 8 | `@UI.identification` | Object page field grouping | Detail view when user clicks a row |
| 9 | `@UI.fieldGroup` | Grouped fields in object page sections | WO Info, Milestone Dates, Quantities, Customer |

---

## 3. Metadata Extension Code

```abap
@Metadata.layer: #CUSTOMER

annotate view ZC_JIPV4_AGING with

{
  // =====================================================================
  // HEADER INFO — Entity title bar
  // =====================================================================
  @UI.headerInfo: {
    typeName: 'JIP Part',
    typeNamePlural: 'JIP Parts Aging',
    title: { type: #STANDARD, value: 'WorkOrderNumber' },
    description: { type: #STANDARD, value: 'MaterialNumber' }
  }

  // =====================================================================
  // SELECTION FIELDS — Filter Bar (top of dashboard)
  // =====================================================================
  @UI.selectionField: [{ position: 10 }]
  Plant;

  @UI.selectionField: [{ position: 20 }]
  ActivityType;

  @UI.selectionField: [{ position: 30 }]
  AgingBucket;

  @UI.selectionField: [{ position: 40 }]
  WmEwmType;

  @UI.selectionField: [{ position: 50 }]
  WarehouseNumber;

  @UI.selectionField: [{ position: 60 }]
  CurrentMilestone;

  @UI.selectionField: [{ position: 70 }]
  ABCIndicator;

  @UI.selectionField: [{ position: 80 }]
  PeriodMonth;

  // =====================================================================
  // LINE ITEM — Detail Table Columns
  // =====================================================================
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  WorkOrderNumber;

  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  MaterialNumber;

  @UI.lineItem: [{ position: 25, importance: #MEDIUM }]
  ABCIndicator;

  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  Plant;

  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  ActivityType;

  @UI.lineItem: [{ position: 50, importance: #HIGH, criticality: 'AgingCriticality' }]
  AgingBucket;

  @UI.lineItem: [{ position: 60, importance: #HIGH }]
  CurrentMilestone;

  @UI.lineItem: [{ position: 70, importance: #MEDIUM }]
  WmEwmType;

  @UI.lineItem: [{ position: 80, importance: #MEDIUM }]
  WarehouseNumber;

  @UI.lineItem: [{ position: 90, importance: #MEDIUM }]
  SoldToParty;

  @UI.lineItem: [{ position: 95, importance: #LOW }]
  CustomerReference;

  @UI.lineItem: [{ position: 100, importance: #MEDIUM }]
  AgingRelease;

  @UI.lineItem: [{ position: 110, importance: #MEDIUM }]
  QtyAvailCheck;

  @UI.lineItem: [{ position: 120, importance: #MEDIUM }]
  QtyWithdrawn;

  @UI.lineItem: [{ position: 130, importance: #LOW }]
  SDHApprovalDate;

  @UI.lineItem: [{ position: 140, importance: #LOW }]
  ReleaseDate;

  @UI.lineItem: [{ position: 150, importance: #LOW }]
  WM_TRDate;

  @UI.lineItem: [{ position: 160, importance: #LOW }]
  WM_ReceivedDate;

  @UI.lineItem: [{ position: 170, importance: #LOW }]
  EWM_ConfirmedAt;

  @UI.lineItem: [{ position: 180, importance: #LOW }]
  GIDate;

  @UI.lineItem: [{ position: 190, importance: #LOW }]
  GINumber;

  @UI.lineItem: [{ position: 200, importance: #LOW }]
  PeriodMonth;

  // =====================================================================
  // DATA POINTS — KPI values with criticality
  // =====================================================================
  @UI.dataPoint: {
    title: 'Aging Bucket',
    criticality: 'AgingCriticality'
  }
  AgingBucket;

  @UI.dataPoint: {
    title: 'Aging Release (Days)',
    criticality: 'AgingCriticality'
  }
  AgingRelease;

  @UI.dataPoint: {
    title: 'Current Milestone'
  }
  CurrentMilestone;

  // =====================================================================
  // CHART DEFINITIONS — OVP Chart Cards
  // =====================================================================

  // --- CARD 1: Total JIP per Plant (Horizontal Bar) ---
  @UI.chart: [{
    qualifier: 'ChartJIPPerPlant',
    title: 'Total JIP per Plant',
    chartType: #BAR,
    dimensions: ['Plant'],
    measures: ['WorkOrderNumber'],
    dimensionAttributes: [{
      dimension: 'Plant',
      role: #CATEGORY
    }],
    measureAttributes: [{
      measure: 'WorkOrderNumber',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // --- CARD 2: Historical JIP ALL Plants (Stacked Column by Aging Bucket) ---
  @UI.chart: [{
    qualifier: 'ChartHistoricalJIP',
    title: 'Historical JIP - All Plants',
    chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'AgingBucket'],
    measures: ['WorkOrderNumber'],
    dimensionAttributes: [
      { dimension: 'PeriodMonth', role: #CATEGORY },
      { dimension: 'AgingBucket', role: #SERIES }
    ],
    measureAttributes: [{
      measure: 'WorkOrderNumber',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // --- CARD 3: Historical Aging per Plant (Stacked Column) ---
  @UI.chart: [{
    qualifier: 'ChartAgingPerPlant',
    title: 'Aging per Plant',
    chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'AgingBucket'],
    measures: ['WorkOrderNumber'],
    dimensionAttributes: [
      { dimension: 'PeriodMonth', role: #CATEGORY },
      { dimension: 'AgingBucket', role: #SERIES }
    ],
    measureAttributes: [{
      measure: 'WorkOrderNumber',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // --- CARD 4: Activity Breakdown (Horizontal Bar) ---
  @UI.chart: [{
    qualifier: 'ChartActivityBreakdown',
    title: 'Activity Type Breakdown',
    chartType: #BAR,
    dimensions: ['ActivityType'],
    measures: ['WorkOrderNumber'],
    dimensionAttributes: [{
      dimension: 'ActivityType',
      role: #CATEGORY
    }],
    measureAttributes: [{
      measure: 'WorkOrderNumber',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // --- CARD 5: Monthly Trend by Activity Type (Stacked Column) ---
  @UI.chart: [{
    qualifier: 'ChartMonthlyTrend',
    title: 'Monthly Trend by Activity',
    chartType: #COLUMN_STACKED,
    dimensions: ['PeriodMonth', 'ActivityType'],
    measures: ['WorkOrderNumber'],
    dimensionAttributes: [
      { dimension: 'PeriodMonth', role: #CATEGORY },
      { dimension: 'ActivityType', role: #SERIES }
    ],
    measureAttributes: [{
      measure: 'WorkOrderNumber',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // --- CARD 6: Average Aging by Plant + Activity (Combination) ---
  @UI.chart: [{
    qualifier: 'ChartAvgAging',
    title: 'Average Aging by Plant & Activity',
    chartType: #COMBINATION,
    dimensions: ['Plant', 'ActivityType'],
    measures: ['AgingRelease'],
    dimensionAttributes: [
      { dimension: 'Plant', role: #CATEGORY },
      { dimension: 'ActivityType', role: #SERIES }
    ],
    measureAttributes: [{
      measure: 'AgingRelease',
      role: #AXIS_1,
      asDataPoint: true
    }]
  }]

  // =====================================================================
  // PRESENTATION VARIANT — Default Sort Order
  // =====================================================================
  @UI.presentationVariant: [{
    qualifier: 'DefaultSort',
    text: 'Default',
    sortOrder: [
      { by: 'Plant', direction: #ASC },
      { by: 'AgingBucket', direction: #DESC },
      { by: 'ActivityType', direction: #ASC }
    ],
    visualizations: [{
      type: #AS_LINEITEM
    }]
  }]

  // --- Presentation Variant for Chart Cards ---
  @UI.presentationVariant: [{
    qualifier: 'PVChartByPlant',
    text: 'By Plant',
    sortOrder: [{ by: 'Plant', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartJIPPerPlant'
    }]
  }]

  @UI.presentationVariant: [{
    qualifier: 'PVChartHistorical',
    text: 'Historical',
    sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartHistoricalJIP'
    }]
  }]

  @UI.presentationVariant: [{
    qualifier: 'PVChartActivity',
    text: 'By Activity',
    sortOrder: [{ by: 'ActivityType', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartActivityBreakdown'
    }]
  }]

  // =====================================================================
  // SELECTION VARIANT — Default Filter Presets
  // =====================================================================
  @UI.selectionVariant: [{
    qualifier: 'SVOpenItems',
    text: 'Open Items (Exclude GI Completed)',
    filterConditions: [{
      property: 'CurrentMilestone',
      option: #NE,
      low: 'GI'
    }]
  }]

  @UI.selectionVariant: [{
    qualifier: 'SVCriticalAging',
    text: 'Critical Aging (60+ and 70+)',
    filterConditions: [{
      property: 'AgingBucket',
      option: #NE,
      low: 'OK'
    }]
  }]

  @UI.selectionVariant: [{
    qualifier: 'SVEWMOnly',
    text: 'EWM Plants Only',
    filterConditions: [{
      property: 'WmEwmType',
      option: #EQ,
      low: 'EWM'
    }]
  }]

  // =====================================================================
  // IDENTIFICATION — Object Page (drill-down detail)
  // =====================================================================
  @UI.identification: [{ position: 10 }]
  WorkOrderNumber;

  @UI.identification: [{ position: 20 }]
  MaterialNumber;

  @UI.identification: [{ position: 30 }]
  Plant;

  @UI.identification: [{ position: 40 }]
  ActivityType;

  @UI.identification: [{ position: 50, criticality: 'AgingCriticality' }]
  AgingBucket;

  // =====================================================================
  // FIELD GROUPS — Object Page Sections
  // =====================================================================

  // --- Group: Work Order Info ---
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 10, label: 'Work Order' }]
  WorkOrderNumber;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 20, label: 'Order Type' }]
  OrderType;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 30, label: 'Activity Type' }]
  ActivityType;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 40, label: 'ABC Indicator' }]
  ABCIndicator;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 50, label: 'WO Creation Date' }]
  WOCreationDate;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 60, label: 'Equipment' }]
  EquipmentNumber;

  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 70, label: 'Equipment Sort' }]
  EquipmentSortField;

  // --- Group: Milestone Dates ---
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 10, label: 'SDH Approval' }]
  SDHApprovalDate;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 20, label: 'Release Date (FTRMI)' }]
  ReleaseDate;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 30, label: 'TR Date (WM)' }]
  WM_TRDate;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 40, label: 'Received Date (WM)' }]
  WM_ReceivedDate;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 50, label: 'Confirmed At (EWM)' }]
  EWM_ConfirmedAt;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 60, label: 'GI Date' }]
  GIDate;

  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 70, label: 'GI Number' }]
  GINumber;

  // --- Group: Quantities ---
  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 10, label: 'Qty Avail Check' }]
  QtyAvailCheck;

  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 20, label: 'Qty Withdrawn (GI)' }]
  QtyWithdrawn;

  // --- Group: Customer ---
  @UI.fieldGroup: [{ qualifier: 'GrpCustomer', position: 10, label: 'Sold To Party' }]
  SoldToParty;

  @UI.fieldGroup: [{ qualifier: 'GrpCustomer', position: 20, label: 'Customer Reference' }]
  CustomerReference;

  // --- Group: Warehouse ---
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 10, label: 'WM/EWM Type' }]
  WmEwmType;

  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 20, label: 'Warehouse Number' }]
  WarehouseNumber;

  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 30, label: 'Current Milestone' }]
  CurrentMilestone;

  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 40, label: 'Aging Release (Days)' }]
  AgingRelease;

  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 50, label: 'Aging Bucket', criticality: 'AgingCriticality' }]
  AgingBucket;
}
```

---

## 4. Clean Consumption View (After Moving Annotations to MDE)

With the MDE in place, the `ZC_JIPV4_AGING` Consumption View should be stripped of all `@UI` annotations, keeping only the structural annotations:

```abap
@AbapCatalog.sqlViewName: 'ZVCJIPV4AGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Milestone Aging - OData V2 Consumption'
@VDM.viewType: #CONSUMPTION

@OData.publish: true

@Metadata.allowExtensions: true    -- REQUIRED: enables Metadata Extension

define view ZC_JIPV4_AGING
  as select from ZI_JIPV4_PartsComposite
{
  key ReservationNumber,
  key ReservationItem,

      WorkOrderNumber,
      MaterialNumber,
      ABCIndicator,

      Plant,
      StorageLocation,
      OrderType,
      ActivityType,

      CurrentMilestone,
      AgingBucket,

      WmEwmType,
      WarehouseNumber,

      SoldToParty,
      CustomerReference,
      EquipmentNumber,
      EquipmentSortField,

      WOCreationDate,
      AgingRelease,

      RequirementQty,
      QtyAvailCheck,
      QtyWithdrawn,

      SDHApprovalDate,
      ReleaseDate,
      WM_TRDate,
      WM_ReceivedDate,
      WM_TRNumber,
      EWM_ConfirmedAt,
      EWM_WTNumber,
      GIDate,
      GINumber,

      PeriodMonth,

      -- Criticality (still in CDS — needed by MDE references)
      case AgingBucket
        when '70+' then 1
        when '60+' then 2
        else 3
      end as AgingCriticality
}
```

> **Critical:** The annotation `@Metadata.allowExtensions: true` MUST be added to `ZC_JIPV4_AGING` for the MDE to work. Without it, the system ignores the Metadata Extension.

---

## 5. Chart Card ↔ Annotation Mapping

How each OVP dashboard card maps to the MDE annotations:

| Card | Title | Chart Qualifier | PresentationVariant | Chart Type |
|------|-------|-----------------|--------------------|----|
| 1 | Total JIP per Plant | `ChartJIPPerPlant` | `PVChartByPlant` | BAR (horizontal) |
| 2 | Historical JIP ALL Plants | `ChartHistoricalJIP` | `PVChartHistorical` | COLUMN_STACKED |
| 3 | Aging per Plant | `ChartAgingPerPlant` | (uses PVChartHistorical) | COLUMN_STACKED |
| 4 | Activity Breakdown | `ChartActivityBreakdown` | `PVChartActivity` | BAR (horizontal) |
| 5 | Monthly Trend | `ChartMonthlyTrend` | (uses PVChartHistorical) | COLUMN_STACKED |
| 6 | Avg Aging Plant+Activity | `ChartAvgAging` | — | COMBINATION |
| 7 | Detail Table | (lineItem) | `DefaultSort` | TABLE |

---

## 6. Selection Variant Presets

Pre-defined filter presets available in the dashboard filter bar:

| Qualifier | Name | Filter | Use Case |
|-----------|------|--------|----------|
| `SVOpenItems` | Open Items | CurrentMilestone ≠ GI | Show only in-progress parts (default view) |
| `SVCriticalAging` | Critical Aging | AgingBucket ≠ OK | Show only 60+ and 70+ items |
| `SVEWMOnly` | EWM Plants Only | WmEwmType = EWM | Filter to EWM-managed plants only |

---

## 7. Field Group → Object Page Mapping

When a user clicks a row in the detail table, the Object Page displays these grouped sections:

| Section | Qualifier | Fields |
|---------|-----------|--------|
| Work Order Info | `GrpWorkOrder` | WO Number, Order Type, Activity Type, ABC, Creation Date, Equipment |
| Milestone Dates | `GrpMilestones` | SDH Approval, Release (FTRMI), TR Date, Received, EWM Confirmed, GI Date/No |
| Quantities | `GrpQuantities` | Qty Avail Check, Qty Withdrawn |
| Customer | `GrpCustomer` | Sold To Party, Customer Reference |
| Warehouse & Aging | `GrpWarehouse` | WM/EWM Type, Warehouse No, Current Milestone, Aging Release, Aging Bucket |

---

## 8. Implementation Steps

| # | Step | What | Where |
|---|------|------|-------|
| 1 | Add `@Metadata.allowExtensions: true` | To `ZC_JIPV4_AGING` consumption view | Eclipse ADT |
| 2 | Remove all `@UI` annotations from `ZC_JIPV4_AGING` | Keep only structural annotations | Eclipse ADT |
| 3 | Create Metadata Extension `ZE_JIPV4_AGING` | New → Other ABAP → Core Data Services → Metadata Extension | Eclipse ADT |
| 4 | Set layer to `#CUSTOMER` | `@Metadata.layer: #CUSTOMER` | First line of MDE |
| 5 | Paste MDE code | Copy Section 3 above | Eclipse ADT |
| 6 | Activate MDE | Ctrl+F3 | Eclipse ADT |
| 7 | Refresh OData metadata | `/IWFND/MAINT_SERVICE` → Clear metadata cache | SAP GUI |
| 8 | Test in Fiori Launchpad | Open OVP app, verify chart cards and filters | Browser |

---

## 9. Fiori OVP App Descriptor (manifest.json) Card Configuration

Each chart card in the OVP references the MDE qualifiers. Example card configuration:

```json
{
  "card01_JIPPerPlant": {
    "model": "ZC_JIPV4_AGING_CDS",
    "template": "sap.ovp.cards.charts.analytical",
    "settings": {
      "title": "Total JIP per Plant",
      "entitySet": "ZC_JIPV4_AGING",
      "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartJIPPerPlant",
      "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartByPlant",
      "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems"
    }
  },
  "card02_HistoricalJIP": {
    "model": "ZC_JIPV4_AGING_CDS",
    "template": "sap.ovp.cards.charts.analytical",
    "settings": {
      "title": "Historical JIP - All Plants",
      "entitySet": "ZC_JIPV4_AGING",
      "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartHistoricalJIP",
      "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical"
    }
  },
  "card04_ActivityBreakdown": {
    "model": "ZC_JIPV4_AGING_CDS",
    "template": "sap.ovp.cards.charts.analytical",
    "settings": {
      "title": "Activity Type Breakdown",
      "entitySet": "ZC_JIPV4_AGING",
      "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartActivityBreakdown",
      "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartActivity"
    }
  },
  "card07_DetailTable": {
    "model": "ZC_JIPV4_AGING_CDS",
    "template": "sap.ovp.cards.table",
    "settings": {
      "title": "JIP Parts Detail",
      "entitySet": "ZC_JIPV4_AGING",
      "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#DefaultSort",
      "selectionAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionVariant#SVOpenItems"
    }
  }
}
```

---

## 10. Checklist

- [ ] `@Metadata.allowExtensions: true` added to `ZC_JIPV4_AGING`
- [ ] All `@UI` annotations removed from `ZC_JIPV4_AGING` consumption view
- [ ] MDE `ZE_JIPV4_AGING` created with `@Metadata.layer: #CUSTOMER`
- [ ] 7 selection fields configured (Plant, ActivityType, AgingBucket, WmEwmType, WarehouseNumber, CurrentMilestone, ABCIndicator, PeriodMonth)
- [ ] 20 line item columns with position and importance
- [ ] 3 data points with criticality mapping
- [ ] 6 chart definitions with qualifiers matching OVP card config
- [ ] 4 presentation variants (DefaultSort + 3 chart-specific)
- [ ] 3 selection variants (OpenItems, CriticalAging, EWMOnly)
- [ ] 5 field groups for object page sections
- [ ] OData metadata cache cleared after activation
- [ ] Dashboard tested in Fiori Launchpad
