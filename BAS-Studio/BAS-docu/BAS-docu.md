# BAS Implementation Documentation — JIP Milestone Aging Dashboard V4

**Version:** 1.0  
**Date:** 2026-03-18  
**App ID:** `com.sap.jipv4.zjipv4aging`  
**OData Service:** `ZC_JIPV4_AGING_CDS` (OData V2)  
**BSP App Name:** `ZJIPV4_AG_OVP`

---

## 1. Overview

SAP Fiori Overview Page (OVP) application for JIP Parts Milestone Aging monitoring. Displays 8 interactive dashboard cards with global filter bar.

### Dashboard Layout

```
╔══════════════════════════════╦═══════════════════════════╦══════════════════════════╗
║  CARD 01                     ║  CARD 02                  ║  CARD 03                 ║
║  Total JIP per Plant         ║  Historical JIP           ║  Aging per Plant         ║
║  [BAR]                       ║  [STACKED COLUMN]         ║  [STACKED COLUMN]        ║
╠══════════════════════════════╬═══════════════════════════╬══════════════════════════╣
║  CARD 04                     ║  CARD 05                  ║  CARD 06                 ║
║  Activity Type Breakdown     ║  Monthly Trend            ║  Avg Aging vs Target     ║
║  [BAR]                       ║  [STACKED COLUMN]         ║  [COMBINATION]           ║
╠══════════════════════════════╩═══════════════════════════╬══════════════════════════╣
║  CARD 07                                                 ║  CARD 08                 ║
║  JIP Parts Detail                                        ║  Critical Aging Items    ║
║  [TABLE]                                                 ║  [LIST]                  ║
╚══════════════════════════════════════════════════════════╩══════════════════════════╝
```

---

## 2. Files Modified

| File | Description |
|------|-------------|
| `webapp/manifest.json` | 8 OVP card definitions with `globalFilterEntityType`, `containerLayout: resizable`, `enableLiveFilter: true` |
| `webapp/annotations/annotation.xml` | 3 local Selection Variants: `SVOpenItems`, `SVCriticalAging`, `SVEWMOnly` |
| `webapp/i18n/i18n.properties` | 8 card titles + 8 card subtitles |

---

## 3. Card Configuration Summary

| # | Card ID | Template | Chart Type | Selection Variant | Key Qualifier |
|---|---------|----------|-----------|-------------------|---------------|
| 01 | `card01_JIPPerPlant` | `charts.analytical` | Bar | SVOpenItems | `ChartJIPPerPlant` |
| 02 | `card02_HistoricalJIP` | `charts.analytical` | ColumnStacked | SVOpenItems | `ChartHistoricalJIP` |
| 03 | `card03_AgingPerPlant` | `charts.analytical` | ColumnStacked | — | `ChartAgingPerPlant` |
| 04 | `card04_ActivityBreakdown` | `charts.analytical` | Bar | SVOpenItems | `ChartActivityBreakdown` |
| 05 | `card05_MonthlyTrend` | `charts.analytical` | ColumnStacked | SVOpenItems | `ChartMonthlyTrend` |
| 06 | `card06_AvgAging` | `charts.analytical` | Combination | — | `ChartAvgAgingWithTarget` |
| 07 | `card07_DetailTable` | `table` | Table | SVOpenItems | `DefaultSort` / `LineItem` |
| 08 | `card08_CriticalList` | `list` | List | SVCriticalAging | `DefaultSort` / `LineItem` |

---

## 4. Selection Variants (annotation.xml)

| Qualifier | Purpose | Filter Logic |
|-----------|---------|-------------|
| `SVOpenItems` | Exclude GI-completed parts | `CurrentMilestone ≠ 'GI'` (Exclude) |
| `SVCriticalAging` | Show only critical aging (60+/70+) | `AgingBucket ≠ 'OK'` (Exclude OK) |
| `SVEWMOnly` | Show only EWM-managed plants | `WmEwmType = 'EWM'` (Include) |

---

## 5. Global Filter Bar (8 Filters)

Defined in backend MDE `ZE_JIPV4_AGING` via `@UI.selectionField`:

1. Plant
2. ActivityType
3. AgingBucket
4. WmEwmType
5. WarehouseNumber
6. CurrentMilestone
7. ABCIndicator
8. PeriodMonth

---

## 6. Annotation Source Matrix

| Annotation | Source | File |
|-----------|--------|------|
| `@UI.chart` (6 charts) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.presentationVariant` (6 PVs) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.dataPoint` (4 DPs) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.lineItem` (20 columns) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.selectionField` (8 filters) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.headerInfo` | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.identification` | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| `@UI.fieldGroup` (5 groups) | Backend MDE | `ZC_JIPV4_AGING_CDS_VAN.xml` |
| **`@UI.selectionVariant`** (3 SVs) | **Local** | **`annotations/annotation.xml`** |

> **Note:** `@UI.selectionVariant` with `selectOptions/ranges` is NOT supported in CDS MDE syntax — must be defined in local annotation.xml.

---

## 7. Model Configuration

| Model Alias | Data Source | OData Version |
|-------------|-----------|---------------|
| `mainModel` | `mainService` → `/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/` | 2.0 |

---

## 8. Deployment Configuration

| Property | Value |
|----------|-------|
| Target | ABAP Repository (BSP) |
| Destination | `UTD030_new` |
| BSP App | `ZJIPV4_AG_OVP` |
| Package | `$TMP` |
| FLP Semantic Object | `JIPAging` |
| FLP Action | `display` |

---

## 9. Preview Commands

```bash
# Live backend data
npm run start

# Local with proxy to backend
npm run start-local

# Mock data (offline testing)
npm run start-mock

# Direct index (no FLP)
npm run start-noflp
```

---

## 10. Verification Checklist

- [x] `manifest.json` — Valid JSON syntax
- [x] `manifest.json` — 8 cards configured (6 charts + 1 table + 1 list)
- [x] `manifest.json` — `globalFilterEntityType: ZC_JIPV4_AGINGType`
- [x] `annotation.xml` — 3 Selection Variants defined (SVOpenItems, SVCriticalAging, SVEWMOnly)
- [x] `i18n.properties` — 8 card titles + 8 card subtitles
- [x] All 32 annotation qualifier cross-references verified against backend VAN.xml
- [ ] Preview in BAS — Filter bar shows 8 filters
- [ ] Preview in BAS — All 8 cards render with data
- [ ] Preview in BAS — Criticality colors: Green=OK, Yellow=60+, Red=70+
- [ ] Deploy to ABAP repository
- [ ] FLP tile created and functional
