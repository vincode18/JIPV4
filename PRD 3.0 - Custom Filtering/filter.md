# PRD 3.0 — Smart Filter Bar with Custom Fields

## JIP V4 Milestone Aging Dashboard — Global Filter Enhancement

**Version:** 1.0  
**Date:** 2026-03-27  
**Application:** `com.sap.jipv4.zjipv4aging` (SAP Fiori OVP)  
**Status:** Draft  

---

## 1. Background & Motivation

The JIP V4 Milestone Aging Dashboard currently uses the default SAP OVP global filter bar, which renders standard input fields for each property listed in `UI.SelectionFields`. These default controls have limitations:

- **No multi-select capability** — users must type or use value help one value at a time
- **No predefined option lists** — fields like Activity Type and Aging Bucket have a known, fixed set of values that should be presented as selectable items
- **No toggle control** — the WM/EWM Type filter should be a simple ON/OFF switch rather than a text input

This PRD defines the enhancement to replace selected default filter controls with **custom SmartFilterBar fields** using `sap.m.MultiComboBox` and `sap.m.Switch` controls, following the SAP UI5 pattern documented in:

> **Reference:** [SmartFilterBar with Custom Fields](https://ui5.sap.com/#/entity/sap.ui.comp.smartfilterbar.SmartFilterBar/sample/sap.ui.comp.sample.smartfilterbar.CustomField/code)

---

## 2. Current Architecture

```
webapp/
├── Component.js              ← extends sap/ovp/app/Component (no custom controller)
├── manifest.json             ← OVP config, globalFilterModel, cards
├── annotations/
│   └── annotation.xml        ← local UI annotations (SelectionVariants, LineItems)
├── localService/mainService/
│   ├── metadata.xml          ← OData entity type ZC_JIPV4_AGINGType
│   └── ZC_JIPV4_AGING_CDS_VAN.xml  ← backend annotations (UI.SelectionFields, Charts, etc.)
└── i18n/
    └── i18n.properties       ← i18n texts
```

### Current Global Filter Fields (`UI.SelectionFields`)

| # | Property | Control | Type |
|---|----------|---------|------|
| 1 | Plant | Default input + value help | Standard |
| 2 | ActivityType | Default input + value help | Standard |
| 3 | WorkOrderNumber | Default input + value help | Standard |
| 4 | WmEwmType | Default input + value help | Standard |
| 5 | CurrentMilestone | Default input + value help | Standard |
| 6 | AgingBucket | Default input + value help | Standard |
| 7 | PeriodMonth | Default input + value help | Standard |
| 8 | PeriodYear | Default input + value help | Standard |

**Problem:** All fields use generic input controls. No multi-select, no predefined items, no toggle.

---

## 3. Target Architecture

### 3.1 New File Structure

```
webapp/
├── Component.js
├── manifest.json                  ← MODIFIED: add extension controller registration
├── annotations/
│   └── annotation.xml
├── ext/                           ← NEW FOLDER
│   ├── customFilter/
│   │   ├── CustomFilter.fragment.xml   ← NEW: custom filter controls (MultiComboBox, Switch)
│   │   └── CustomFilterController.js   ← NEW: extension controller with filter logic
├── localService/mainService/
│   ├── metadata.xml
│   └── ZC_JIPV4_AGING_CDS_VAN.xml     ← MODIFIED: update UI.SelectionFields if needed
└── i18n/
    └── i18n.properties                 ← MODIFIED: add filter label texts
```

### 3.2 Architecture Pattern

The SAP OVP SmartFilterBar supports custom fields via the **OVP Extension Controller** pattern:

1. **Custom XML Fragment** (`CustomFilter.fragment.xml`) — defines the `sap.m.MultiComboBox` and `sap.m.Switch` controls
2. **Extension Controller** (`CustomFilterController.js`) — implements:
   - `getCustomFilters()` — reads values from custom controls and returns `sap.ui.model.Filter` objects
   - `onBeforeRebindPageExtension(oEvent)` — injects custom filters into the OData binding before each card rebind
   - `getCustomAppStateDataExtension(oCustomData)` — persists custom filter state for navigation/bookmarking
   - `restoreCustomAppStateDataExtension(oCustomData)` — restores custom filter state
3. **manifest.json** — registers the extension controller under `sap.ui5 > extends > extensions`

### 3.3 Data Flow

```
User selects values in MultiComboBox / Switch
        │
        ▼
SmartFilterBar fires "search" event
        │
        ▼
OVP calls onBeforeRebindPageExtension(oEvent)
        │
        ▼
Extension reads custom control values → builds sap.ui.model.Filter[]
        │
        ▼
Filters appended to oEvent bindingParams.filters
        │
        ▼
OData $filter sent to backend with custom filter conditions
```

---

## 4. Filter Field Specifications

### 4.1 Plant — `sap.m.MultiComboBox` (Dynamic)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.MultiComboBox` |
| **ID** | `customPlantFilter` |
| **OData Property** | `Plant` |
| **Items Source** | Dynamic — bound to OData entity set, distinct `Plant` values |
| **Binding** | `{path: '/ZC_JIPV4_AGING', parameters: {select: 'Plant'}, sorter: {path: 'Plant'}}` |
| **Default** | No selection (show all) |
| **Filter Operator** | `FilterOperator.EQ` per selected item, combined with `OR` |

**Behavior:** On app load, the MultiComboBox fetches distinct Plant values from the OData service. User can select one or more plants. When no plant is selected, no filter is applied (show all).

### 4.2 Activity Type — `sap.m.MultiComboBox` (Static)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.MultiComboBox` |
| **ID** | `customActivityTypeFilter` |
| **OData Property** | `ActivityType` |
| **Items Source** | Static list |
| **Default** | No selection (show all) |
| **Filter Operator** | `FilterOperator.EQ` per selected item, combined with `OR` |

**Static Items:**

| Key | Text |
|-----|------|
| ADD | ADD |
| INS | INS |
| LOG | LOG |
| MID | MID |
| NME | NME |
| OVH | OVH |
| PAP | PAP |
| PPM | PPM |
| SER | SER |
| TRS | TRS |
| UIW | UIW |
| USN | USN |

### 4.3 Aging Bucket — `sap.m.MultiComboBox` (Static)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.MultiComboBox` |
| **ID** | `customAgingBucketFilter` |
| **OData Property** | `AgingBucket` |
| **Items Source** | Static list |
| **Default** | No selection (show all) |
| **Filter Operator** | `FilterOperator.EQ` per selected item, combined with `OR` |

**Static Items:**

| Key | Text |
|-----|------|
| OK | OK |
| 60+ | 60+ |
| 70+ | 70+ |

### 4.4 WM/EWM Type — `sap.m.Switch` (Custom Toggle)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.Switch` |
| **ID** | `customWmEwmSwitch` |
| **OData Property** | `WmEwmType` |
| **State OFF** | No filter applied → show ALL records (WM + EWM) |
| **State ON** | Filter `WmEwmType eq 'EWM'` → show EWM only |
| **Default** | OFF (show all) |
| **Custom State Text** | `customTextOn: "EWM"`, `customTextOff: "ALL"` |

**Behavior:**
- **Switch OFF (default):** No filter on `WmEwmType` — all warehouse types displayed
- **Switch ON:** Applies filter `WmEwmType eq 'EWM'` — only EWM warehouse records shown
- The switch label displays "WM/EWM Type" with state text "ALL" / "EWM"

### 4.5 Work Order — Standard Input (Unchanged)

| Property | Value |
|----------|-------|
| **Control** | Default SmartFilterBar input with value help |
| **OData Property** | `WorkOrderNumber` |
| **Behavior** | No change — remains as standard free-text input with value help dialog |

### 4.6 Current Milestone — `sap.m.MultiComboBox` (Static)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.MultiComboBox` |
| **ID** | `customMilestoneFilter` |
| **OData Property** | `CurrentMilestone` |
| **Items Source** | Static list |
| **Default** | No selection (show all) |
| **Filter Operator** | `FilterOperator.EQ` per selected item, combined with `OR` |

**Static Items:**

| Key | Text |
|-----|------|
| PENDING | PENDING |
| TR | TR |
| RECEIVED | RECEIVED |
| GI | GI |

> **Note:** Additional milestone values may be added in the future. The static list should be maintained in the fragment XML or i18n.

### 4.7 PeriodMonth — `sap.m.MultiComboBox` (Static)

| Property | Value |
|----------|-------|
| **Control** | `sap.m.MultiComboBox` |
| **ID** | `customPeriodMonthFilter` |
| **OData Property** | `PeriodMonth` |
| **Items Source** | Static list (01–12) |
| **Default** | No selection (show all) |
| **Filter Operator** | `FilterOperator.EQ` per selected item, combined with `OR` |

**Static Items:**

| Key | Text |
|-----|------|
| 01 | 01 |
| 02 | 02 |
| 03 | 03 |
| 04 | 04 |
| 05 | 05 |
| 06 | 06 |
| 07 | 07 |
| 08 | 08 |
| 09 | 09 |
| 10 | 10 |
| 11 | 11 |
| 12 | 12 |

### 4.8 PeriodYear — Standard Input (Unchanged)

| Property | Value |
|----------|-------|
| **Control** | Default SmartFilterBar input with value help |
| **OData Property** | `PeriodYear` |
| **Behavior** | No change — remains as standard free-text input with value help dialog |

---

## 5. Technical Implementation Details

### 5.1 Custom Filter Fragment — `ext/customFilter/CustomFilter.fragment.xml`

This XML fragment defines all custom controls that replace the default SmartFilterBar fields. Each custom control is wrapped in a `controlConfiguration` item and identified by its OData property name.

```xml
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    xmlns:smartfilterbar="sap.ui.comp.smartfilterbar">

    <!-- Plant: MultiComboBox with dynamic OData binding -->
    <MultiComboBox id="customPlantFilter"
        selectionChange=".onCustomFilterChange">
        <!-- Items bound dynamically in controller init -->
    </MultiComboBox>

    <!-- Activity Type: MultiComboBox with static items -->
    <MultiComboBox id="customActivityTypeFilter"
        selectionChange=".onCustomFilterChange">
        <core:Item key="ADD" text="ADD"/>
        <core:Item key="INS" text="INS"/>
        <core:Item key="LOG" text="LOG"/>
        <core:Item key="MID" text="MID"/>
        <core:Item key="NME" text="NME"/>
        <core:Item key="OVH" text="OVH"/>
        <core:Item key="PAP" text="PAP"/>
        <core:Item key="PPM" text="PPM"/>
        <core:Item key="SER" text="SER"/>
        <core:Item key="TRS" text="TRS"/>
        <core:Item key="UIW" text="UIW"/>
        <core:Item key="USN" text="USN"/>
    </MultiComboBox>

    <!-- Aging Bucket: MultiComboBox with static items -->
    <MultiComboBox id="customAgingBucketFilter"
        selectionChange=".onCustomFilterChange">
        <core:Item key="OK" text="OK"/>
        <core:Item key="60+" text="60+"/>
        <core:Item key="70+" text="70+"/>
    </MultiComboBox>

    <!-- WM/EWM Type: Custom Switch -->
    <Switch id="customWmEwmSwitch"
        customTextOn="EWM"
        customTextOff="ALL"
        state="false"
        change=".onCustomFilterChange"/>

    <!-- Current Milestone: MultiComboBox with static items -->
    <MultiComboBox id="customMilestoneFilter"
        selectionChange=".onCustomFilterChange">
        <core:Item key="PENDING" text="PENDING"/>
        <core:Item key="TR" text="TR"/>
        <core:Item key="RECEIVED" text="RECEIVED"/>
        <core:Item key="GI" text="GI"/>
    </MultiComboBox>

    <!-- PeriodMonth: MultiComboBox with static months -->
    <MultiComboBox id="customPeriodMonthFilter"
        selectionChange=".onCustomFilterChange">
        <core:Item key="01" text="01"/>
        <core:Item key="02" text="02"/>
        <core:Item key="03" text="03"/>
        <core:Item key="04" text="04"/>
        <core:Item key="05" text="05"/>
        <core:Item key="06" text="06"/>
        <core:Item key="07" text="07"/>
        <core:Item key="08" text="08"/>
        <core:Item key="09" text="09"/>
        <core:Item key="10" text="10"/>
        <core:Item key="11" text="11"/>
        <core:Item key="12" text="12"/>
    </MultiComboBox>

</core:FragmentDefinition>
```

### 5.2 Extension Controller — `ext/customFilter/CustomFilterController.js`

The extension controller implements the OVP extension hooks to read custom control values and inject them as OData filters.

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `onInit()` | Get references to custom controls; bind Plant MultiComboBox to OData |
| `onCustomFilterChange()` | Trigger SmartFilterBar search on any custom control change |
| `onBeforeRebindPageExtension(oEvent)` | Build `sap.ui.model.Filter` array from custom controls and add to binding |
| `getCustomAppStateDataExtension(oCustomData)` | Save custom filter state for bookmarking |
| `restoreCustomAppStateDataExtension(oCustomData)` | Restore custom filter state from bookmark |

**Filter Construction Logic (pseudocode):**

```javascript
onBeforeRebindPageExtension: function(oEvent) {
    var aFilters = [];

    // Plant MultiComboBox
    var aPlants = this._oPlantCombo.getSelectedKeys();
    if (aPlants.length > 0) {
        var aPlantFilters = aPlants.map(function(sKey) {
            return new Filter("Plant", FilterOperator.EQ, sKey);
        });
        aFilters.push(new Filter({ filters: aPlantFilters, and: false }));
    }

    // Activity Type MultiComboBox
    var aActivities = this._oActivityCombo.getSelectedKeys();
    if (aActivities.length > 0) {
        var aActivityFilters = aActivities.map(function(sKey) {
            return new Filter("ActivityType", FilterOperator.EQ, sKey);
        });
        aFilters.push(new Filter({ filters: aActivityFilters, and: false }));
    }

    // Aging Bucket MultiComboBox
    var aBuckets = this._oAgingBucketCombo.getSelectedKeys();
    if (aBuckets.length > 0) {
        var aBucketFilters = aBuckets.map(function(sKey) {
            return new Filter("AgingBucket", FilterOperator.EQ, sKey);
        });
        aFilters.push(new Filter({ filters: aBucketFilters, and: false }));
    }

    // WM/EWM Switch
    var bEwmOnly = this._oWmEwmSwitch.getState();
    if (bEwmOnly) {
        aFilters.push(new Filter("WmEwmType", FilterOperator.EQ, "EWM"));
    }
    // If switch OFF → no filter → show ALL

    // Current Milestone MultiComboBox
    var aMilestones = this._oMilestoneCombo.getSelectedKeys();
    if (aMilestones.length > 0) {
        var aMilestoneFilters = aMilestones.map(function(sKey) {
            return new Filter("CurrentMilestone", FilterOperator.EQ, sKey);
        });
        aFilters.push(new Filter({ filters: aMilestoneFilters, and: false }));
    }

    // PeriodMonth MultiComboBox
    var aMonths = this._oPeriodMonthCombo.getSelectedKeys();
    if (aMonths.length > 0) {
        var aMonthFilters = aMonths.map(function(sKey) {
            return new Filter("PeriodMonth", FilterOperator.EQ, sKey);
        });
        aFilters.push(new Filter({ filters: aMonthFilters, and: false }));
    }

    // Combine all filters with AND
    if (aFilters.length > 0) {
        var oCombinedFilter = new Filter({ filters: aFilters, and: true });
        oEvent.getSource().getBinding("items").filter(oCombinedFilter);
    }
}
```

### 5.3 manifest.json — Extension Registration

Add the following under `sap.ui5` to register the OVP extension controller:

```json
"extends": {
    "extensions": {
        "sap.ui.controllerExtensions": {
            "sap.ovp.app.Main": {
                "controllerName": "com.sap.jipv4.zjipv4aging.ext.customFilter.CustomFilterController",
                "sap.ui.generic.app": {
                    "OVPGlobalFilterExtend": {
                        "controllerName": "com.sap.jipv4.zjipv4aging.ext.customFilter.CustomFilterController"
                    }
                }
            }
        }
    }
}
```

### 5.4 Annotation Changes — `UI.SelectionFields`

The `UI.SelectionFields` in `ZC_JIPV4_AGING_CDS_VAN.xml` should keep only the fields that remain as **standard** SmartFilterBar controls:

```xml
<Annotation Term="UI.SelectionFields">
    <Collection>
        <PropertyPath>Plant</PropertyPath>
        <PropertyPath>ActivityType</PropertyPath>
        <PropertyPath>WorkOrderNumber</PropertyPath>
        <PropertyPath>WmEwmType</PropertyPath>
        <PropertyPath>CurrentMilestone</PropertyPath>
        <PropertyPath>AgingBucket</PropertyPath>
        <PropertyPath>PeriodMonth</PropertyPath>
        <PropertyPath>PeriodYear</PropertyPath>
    </Collection>
</Annotation>
```

> **Note:** Custom controls will **replace** the default rendering for Plant, ActivityType, AgingBucket, WmEwmType, CurrentMilestone, and PeriodMonth. WorkOrderNumber and PeriodYear remain standard.

### 5.5 i18n Additions — `i18n.properties`

```properties
# ========================================
# Custom Filter Labels (PRD 3.0)
# ========================================
#XFLD: Plant filter label
filter_plant=Plant

#XFLD: Activity Type filter label
filter_activityType=Activity Type

#XFLD: Aging Bucket filter label
filter_agingBucket=Aging Bucket

#XFLD: WM/EWM Type switch label
filter_wmEwmType=WM/EWM Type

#XFLD: Current Milestone filter label
filter_milestone=Current Milestone

#XFLD: Period Month filter label
filter_periodMonth=Period Month
```

---

## 6. UI Layout — Filter Bar

The enhanced filter bar will render as follows:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  Standard ▾                                                            🔍  ≡ ▾  │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  Plant:          Activity Type:    Aging Bucket:    WM/EWM Type:                │
│  ┌──────────┐    ┌──────────┐     ┌──────────┐    ┌─────────────┐              │
│  │ ▾ multi  │    │ ▾ multi  │     │ ▾ multi  │    │ ALL ○── EWM │              │
│  └──────────┘    └──────────┘     └──────────┘    └─────────────┘              │
│                                                                                  │
│  Work Order:     Current          PeriodYear:     PeriodMonth:                  │
│  ┌──────────┐    Milestone:       ┌──────────┐   ┌──────────┐                  │
│  │ std input│    ┌──────────┐     │ std input│   │ ▾ multi  │                  │
│  └──────────┘    │ ▾ multi  │     └──────────┘   └──────────┘                  │
│                  └──────────┘                                  Adapt Filters    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Acceptance Criteria

### 7.1 Functional

| # | Criteria | Expected Result |
|---|----------|-----------------|
| AC-01 | Plant MultiComboBox loads distinct values | Dropdown shows all unique plants from OData |
| AC-02 | Activity Type shows 12 static items | ADD, INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN |
| AC-03 | Aging Bucket shows 3 items | OK, 60+, 70+ |
| AC-04 | WM/EWM Switch OFF → all records shown | No filter on WmEwmType |
| AC-05 | WM/EWM Switch ON → EWM only | Only records with WmEwmType = 'EWM' |
| AC-06 | Current Milestone shows static items | PENDING, TR, RECEIVED, GI |
| AC-07 | PeriodMonth shows 01–12 | All 12 months selectable |
| AC-08 | Multi-select works for all MultiComboBox | Can select 2+ values, filter uses OR logic |
| AC-09 | Combined filters use AND | Plant=BJM AND ActivityType=SER → only SER in BJM |
| AC-10 | Work Order unchanged | Standard input with value help |
| AC-11 | PeriodYear unchanged | Standard input with value help |
| AC-12 | All cards respect custom filters | Every OVP card filters data based on custom selections |

### 7.2 Non-Functional

| # | Criteria |
|---|----------|
| NF-01 | Filter bar loads within 2 seconds |
| NF-02 | Custom controls render consistently with standard SmartFilterBar styling |
| NF-03 | Browser back/forward preserves filter state |
| NF-04 | "Adapt Filters" dialog still works for remaining standard fields |

---

## 8. Implementation Phases

| Phase | Description | Files |
|-------|-------------|-------|
| **Phase 1** | Create extension folder structure and empty files | `ext/customFilter/` |
| **Phase 2** | Build `CustomFilter.fragment.xml` with all custom controls | Fragment XML |
| **Phase 3** | Build `CustomFilterController.js` with filter logic | Controller JS |
| **Phase 4** | Register extension in `manifest.json` | manifest.json |
| **Phase 5** | Update `i18n.properties` with filter labels | i18n.properties |
| **Phase 6** | Test all filter combinations | Manual testing |
| **Phase 7** | Update `UI.SelectionFields` annotation if needed | VAN.xml / annotation.xml |

---

## 9. Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| OVP extension controller may not support all custom controls in filter bar | Verify with SAP UI5 version 1.120.0+ (current `minUI5Version`) |
| Plant dynamic binding may cause performance issues with large datasets | Use `$select=Plant` and `$orderby=Plant` with distinct |
| Custom filter state may not persist on F5 refresh | Implement `getCustomAppStateDataExtension` / `restoreCustomAppStateDataExtension` |
| Backend `UI.SelectionFields` may override local annotation | Ensure backend CDS annotation matches local changes |

---

## 10. References

- **SAP UI5 SmartFilterBar Custom Field Sample:** [ui5.sap.com — SmartFilterBar CustomField](https://ui5.sap.com/#/entity/sap.ui.comp.smartfilterbar.SmartFilterBar/sample/sap.ui.comp.sample.smartfilterbar.CustomField/code)
- **SAP OVP Extension Documentation:** [SAP Fiori OVP Application Extension](https://sapui5.hana.ondemand.com/#/topic/fd26fee0e3c44c33b6ae6b94a6aa4a08)
- **sap.m.MultiComboBox API:** [MultiComboBox](https://ui5.sap.com/#/api/sap.m.MultiComboBox)
- **sap.m.Switch API:** [Switch](https://ui5.sap.com/#/api/sap.m.Switch)
- **Current Project:** `com.sap.jipv4.zjipv4aging` — OVP with `mainModel` → `ZC_JIPV4_AGING_CDS`