# PRD 3.0 — JIP V4 Dashboard: Smart Filter Bar with Custom Fields

**Document Version:** 3.0  
**Project:** JIP V4 Dashboard — Filter Enhancement  
**Module:** Smart Filter Bar (SAP UI5 `sap.ui.comp.smartfilterbar.SmartFilterBar`)  
**Status:** Draft  
**Date:** 2025  
**Prepared by:** Product Team  

---

## Table of Contents

- [PRD 3.0 — JIP V4 Dashboard: Smart Filter Bar with Custom Fields](#prd-30--jip-v4-dashboard-smart-filter-bar-with-custom-fields)
  - [Table of Contents](#table-of-contents)
  - [1. Overview](#1-overview)
  - [2. Objectives](#2-objectives)
  - [3. Scope](#3-scope)
    - [In Scope](#in-scope)
    - [Out of Scope](#out-of-scope)
  - [4. Stakeholders](#4-stakeholders)
  - [5. Current State (As-Is)](#5-current-state-as-is)
  - [6. Target State (To-Be)](#6-target-state-to-be)
  - [7. Functional Requirements](#7-functional-requirements)
    - [7.1 Plant — MultiComboBox](#71-plant--multicombobox)
    - [7.2 Activity Type — MultiComboBox](#72-activity-type--multicombobox)
    - [7.3 Aging Bucket — MultiComboBox](#73-aging-bucket--multicombobox)
    - [7.4 Current Milestone — MultiComboBox](#74-current-milestone--multicombobox)
    - [7.5 WM/EWM Type — Custom Switch](#75-wmewm-type--custom-switch)
    - [7.6 Period Month — MultiComboBox](#76-period-month--multicombobox)
  - [8. Non-Functional Requirements](#8-non-functional-requirements)
  - [9. Technical Design](#9-technical-design)
    - [9.1 SmartFilterBar Configuration](#91-smartfilterbar-configuration)
    - [9.2 Custom Field Registration](#92-custom-field-registration)
    - [9.3 Controller Logic](#93-controller-logic)
    - [9.4 OData / Filter Construction](#94-odata--filter-construction)
    - [9.5 Variant Management](#95-variant-management)
  - [10. UI/UX Specification](#10-uiux-specification)
    - [Filter Bar Layout](#filter-bar-layout)
    - [Control Sizing Guidelines](#control-sizing-guidelines)
    - [Token Overflow Behavior](#token-overflow-behavior)
    - [Empty State](#empty-state)
  - [11. Filter Interaction Matrix](#11-filter-interaction-matrix)
  - [12. Acceptance Criteria](#12-acceptance-criteria)
    - [AC-01: Plant MultiComboBox](#ac-01-plant-multicombobox)
    - [AC-02: Activity Type MultiComboBox](#ac-02-activity-type-multicombobox)
    - [AC-03: Aging Bucket MultiComboBox](#ac-03-aging-bucket-multicombobox)
    - [AC-04: Current Milestone MultiComboBox](#ac-04-current-milestone-multicombobox)
    - [AC-05: WM/EWM Type Switch](#ac-05-wmewm-type-switch)
    - [AC-06: Period Month MultiComboBox](#ac-06-period-month-multicombobox)
    - [AC-07: Variant Management](#ac-07-variant-management)
    - [AC-08: Performance](#ac-08-performance)
  - [13. Dependencies \& Risks](#13-dependencies--risks)
    - [Dependencies](#dependencies)
    - [Risks](#risks)
  - [14. Appendix: Field Value Reference](#14-appendix-field-value-reference)
    - [Activity Type Codes](#activity-type-codes)
    - [Aging Bucket Reference](#aging-bucket-reference)
    - [Period Month Reference](#period-month-reference)
    - [WM/EWM Type Reference](#wmewm-type-reference)

---

## 1. Overview

The JIP V4 Dashboard provides plant-level visibility into job inspection progress (JIP) across maintenance activities. Version 3.0 introduces a **redesigned Smart Filter Bar** that replaces the current single-value input fields with richer custom fields — `MultiComboBox` controls and a `Custom Switch` — so that users can filter across multiple values simultaneously and toggle WM/EWM warehouse management modes without navigating away from the dashboard.

This PRD defines all product requirements, UI/UX expectations, and technical guidance for implementing the Smart Filter Bar upgrade using the SAP UI5 component `sap.ui.comp.smartfilterbar.SmartFilterBar` with custom field extensions.

**Reference Implementation:** [SAP UI5 Demo Kit — SmartFilterBar with Custom Field](https://ui5.sap.com/#/entity/sap.ui.comp.smartfilterbar.SmartFilterBar/sample/sap.ui.comp.sample.smartfilterbar.CustomField/code)

---

## 2. Objectives

| # | Objective |
|---|-----------|
| O-01 | Allow users to select **multiple plants** simultaneously in a single filter action |
| O-02 | Allow users to select **multiple activity types** to cross-analyze workload distribution |
| O-03 | Allow users to select **multiple aging bucket values** to view combined aging status |
| O-04 | Allow users to filter by **multiple current milestones** at once |
| O-05 | Provide a **toggle switch** to quickly alternate between WM and EWM warehouse management types |
| O-06 | Allow users to select **multiple period months** for cross-month trend analysis |
| O-07 | Preserve backward compatibility with existing **variant management** and saved filter states |
| O-08 | Ensure filter state is **bookmarkable and shareable** via URL parameters |

---

## 3. Scope

### In Scope

- Smart Filter Bar custom field implementation on the JIP V4 Dashboard
- Six filter controls: Plant, Activity Type, Aging Bucket, Current Milestone, WM/EWM Type Switch, Period Month
- OData filter construction for all controls
- Variant save/load integration
- Responsive layout for desktop and tablet

### Out of Scope

- Period Year filter (existing control, no change in this PRD)
- Work Order filter (existing control, no change in this PRD)
- Mobile / smartphone layout optimization
- Backend OData service changes (assumes existing service supports multi-value EQ filters)

---

## 4. Stakeholders

| Role | Name / Team | Responsibility |
|------|-------------|----------------|
| Product Owner | Maintenance & Reliability Team | Requirement sign-off |
| UX Designer | UI/UX Team | Wireframe & interaction design |
| Frontend Developer | UI5 Team | SmartFilterBar custom field implementation |
| Backend Developer | SAP BTP / OData Team | Multi-value filter support verification |
| QA Engineer | Testing Team | Acceptance test execution |
| Business Analyst | Plant Operations | Business logic validation |

---

## 5. Current State (As-Is)

The existing JIP V4 Dashboard (V2.x) uses a standard SmartFilterBar with the following limitations:

| Filter Field | Current Control | Limitation |
|---|---|---|
| Plant | Single-value input (`=BJM`) | Cannot select multiple plants |
| Activity Type | Single-value input | Cannot select multiple types |
| Aging Bucket | Single-value input | Cannot select multiple buckets |
| WM/EWM Type | Plain text input | No toggle; user must type the value |
| Work Order | Single-value input (`=51365300`) | (No change) |
| Current Milestone | Single-value input | Cannot select multiple milestones |
| Period Year | Single-value input (`=2021`) | (No change) |
| Period Month | Single-value input (`*04*`) | Cannot select multiple months |

**Pain Points Reported:**
- Users must change filter values and re-apply multiple times to compare data across plants or months
- No visual affordance for the WM vs EWM toggle — users are confused about the input format
- Saved variants do not always restore multi-value intent correctly

---

## 6. Target State (To-Be)

The upgraded Smart Filter Bar presents all six custom controls in a single filter bar row. Users can:

1. Select one or more **Plants** via `MultiComboBox`
2. Select one or more **Activity Types** via `MultiComboBox`
3. Select one or more **Aging Bucket** values via `MultiComboBox`
4. Select one or more **Current Milestones** via `MultiComboBox`
5. Toggle **WM / EWM** mode via a labeled `sap.m.Switch`
6. Select one or more **Period Months** via `MultiComboBox`

Upon pressing **Go**, the dashboard charts update to reflect all active filter combinations simultaneously.

---

## 7. Functional Requirements

---

### 7.1 Plant — MultiComboBox

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.MultiComboBox` |
| Filter Bar Label | **Plant** |
| OData Field | `Plant` |
| Filter Operator | `FilterOperator.EQ` (one filter per selection, combined with OR) |
| Placeholder | `Select Plant(s)...` |
| Mode | Multi-selection |

**Description:**  
The Plant field allows the user to select one or more plant codes. Each selected plant generates an individual OData filter with `FilterOperator.EQ`, and all plant filters are combined with an OR condition wrapped in an AND against other active filters.

**Business Rule:**  
- At least one plant must be selected before the Go button enables dashboard refresh
- If no plant is selected, the dashboard retains the previous filter state

**Value List:**  
The plant list is loaded dynamically from the OData value help entity. Example values: `BJM`, `SER`, and other plant codes available in the system.

**Behavior:**
- Supports free-text search within the dropdown
- Selected tokens appear as chips inside the input field
- Tokens are removable individually via the ✕ icon

---

### 7.2 Activity Type — MultiComboBox

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.MultiComboBox` |
| Filter Bar Label | **Activity Type** |
| OData Field | `ActivityType` |
| Filter Operator | `FilterOperator.EQ` |
| Placeholder | `Select Activity Type(s)...` |
| Mode | Multi-selection |

**Description:**  
The Activity Type field allows the user to select one or more maintenance activity types. These types categorize the nature of the work recorded on a work order.

**Fixed Value List (Static):**

| Code | Description |
|------|-------------|
| ADD | Additional Work |
| INS | Inspection |
| LOG | Logistics |
| MID | Mid-Stream Activity |
| NME | New Material Equipment |
| OVH | Overhaul |
| PAP | Preventive — As Per Plan |
| PPM | Planned Preventive Maintenance |
| SER | Service |
| TRS | Transfer |
| UIW | Uninstructed Work |
| USN | Urgent / Unscheduled |

**Behavior:**
- Values are loaded as static items (no OData call needed for this field)
- All 12 activity types are shown in the dropdown
- User can select any combination
- A "Select All" toggle is recommended for convenience

---

### 7.3 Aging Bucket — MultiComboBox

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.MultiComboBox` |
| Filter Bar Label | **Aging Bucket** |
| OData Field | `AgingBucket` |
| Filter Operator | `FilterOperator.EQ` |
| Placeholder | `Select Aging Bucket(s)...` |
| Mode | Multi-selection |

**Description:**  
The Aging Bucket field classifies items by the number of days they have been outstanding beyond their target. Selecting multiple buckets allows visibility into combined aging health.

**Fixed Value List (Static):**

| Code | Description |
|------|-------------|
| OK | Within target aging days |
| 60+ | Outstanding more than 60 days |
| 70+ | Outstanding more than 70 days |

**Behavior:**
- Displayed in order: OK → 60+ → 70+
- Selecting "OK" and "60+" simultaneously shows both OK and overdue items
- Color coding (green for OK, amber for 60+, red for 70+) is applied to tokens as visual indicators if supported by the theme

---

### 7.4 Current Milestone — MultiComboBox

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.MultiComboBox` |
| Filter Bar Label | **Current Milestone** |
| OData Field | `CurrentMilestone` |
| Filter Operator | `FilterOperator.EQ` |
| Placeholder | `Select Milestone(s)...` |
| Mode | Multi-selection |

**Description:**  
The Current Milestone field reflects the latest workflow milestone reached by a job inspection item. Users can select multiple milestones to monitor items at various stages simultaneously.

**Example Values (Dynamic from OData Value Help):**

| Code | Description |
|------|-------------|
| PENDING | Awaiting action |
| TR | Transfer / Ready for Transfer |
| RECEIVED | Received at destination |
| *(additional values from value help)* | |

**Behavior:**
- Values are loaded from the OData value help entity for `CurrentMilestone`
- Supports type-ahead search filtering within the dropdown
- Number of selected milestones is shown as a count badge when collapsed

---

### 7.5 WM/EWM Type — Custom Switch

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.Switch` |
| Filter Bar Label | **WM/EWM Type** |
| OData Field | `WMEWMType` |
| Filter Operator | `FilterOperator.EQ` |
| Switch OFF State | `WM` (Warehouse Management) |
| Switch ON State | `EWM` (Extended Warehouse Management) |
| Default State | OFF (`WM`) |

**Description:**  
The WM/EWM Type control is implemented as a **Custom Switch** inside the Smart Filter Bar. It provides a binary toggle for users to switch between classic Warehouse Management (WM) and Extended Warehouse Management (EWM) data views. This replaces the previous free-text input that required users to manually type the warehouse type code.

**Custom Field Implementation:**  
The switch is registered as a custom field in the SmartFilterBar XML view using the `customFields` aggregation. The controller reads the switch state on the `onBeforeRebindTable` (or equivalent rebind) event and injects the appropriate filter value.

**Behavior:**
- Label to the left of the switch reads: `WM`
- Label to the right of the switch reads: `EWM`
- Toggle animates smoothly between states
- Filter is applied immediately upon pressing **Go**; the switch does not trigger auto-refresh by itself
- State is persisted in SmartFilterBar variants
- Default state on initial load: **OFF** (`WM`)

**OData Filter Logic:**

```javascript
// In onBeforeRebindTable:
const bSwitchValue = this._oCustomSwitch.getState();
mBindingParams.filters.push(
  new Filter(
    "WMEWMType",
    FilterOperator.EQ,
    bSwitchValue ? "EWM" : "WM"
  )
);
```

---

### 7.6 Period Month — MultiComboBox

| Attribute | Value |
|-----------|-------|
| Control | `sap.m.MultiComboBox` |
| Filter Bar Label | **Period Month** |
| OData Field | `PeriodMonth` |
| Filter Operator | `FilterOperator.EQ` |
| Placeholder | `Select Month(s)...` |
| Mode | Multi-selection |

**Description:**  
The Period Month field allows users to select one or multiple months within the selected Period Year. This replaces the previous wildcard pattern (`*04*`) with a structured multi-select control, enabling cross-month trend comparison directly from the dashboard without requiring multiple filter reloads.

**Fixed Value List (Static):**

| Value | Label |
|-------|-------|
| 01 | January |
| 02 | February |
| 03 | March |
| 04 | April |
| 05 | May |
| 06 | June |
| 07 | July |
| 08 | August |
| 09 | September |
| 10 | October |
| 11 | November |
| 12 | December |

**Behavior:**
- Values are always shown in chronological order (01–12)
- Month labels (e.g., "April") are shown alongside the numeric code for clarity
- Selecting multiple months generates one EQ filter per month, combined with OR
- Works in conjunction with the Period Year filter: both must be set for meaningful results
- "Select Q1" / "Select Q2" etc. quick-select buttons are a **nice-to-have** enhancement

---

## 8. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Filter bar initial load time | < 1.5 seconds |
| NFR-02 | Dashboard refresh after Go | < 3 seconds for typical data volume |
| NFR-03 | MultiComboBox dropdown render | < 500ms after user click |
| NFR-04 | Browser support | Chrome 110+, Edge 110+, Firefox 110+ |
| NFR-05 | SAP UI5 version compatibility | UI5 1.120+ (LTS) |
| NFR-06 | Accessibility | WCAG 2.1 AA — keyboard navigation, screen reader labels |
| NFR-07 | Variant persistence | All 6 custom fields must be included in variant save/restore |
| NFR-08 | URL parameter support | Filter state serializable to URL hash for sharing |

---

## 9. Technical Design

### 9.1 SmartFilterBar Configuration

The SmartFilterBar is configured in the XML view with `useToolbar="false"` and custom fields registered in the `customFields` aggregation:

```xml
<smartFilterBar:SmartFilterBar
    id="smartFilterBar"
    entitySet="JIPEntity"
    search="onSearch"
    showButtons="true"
    useToolbar="false"
    filterBarExpanded="true"
    basicSearchFieldName="WorkOrder">

    <smartFilterBar:controlConfiguration>
        <!-- Plant: Hide standard field, replaced by custom MultiComboBox -->
        <smartFilterBar:ControlConfiguration
            key="Plant"
            visibleInFilterBar="false" />

        <!-- ActivityType: Hide standard field -->
        <smartFilterBar:ControlConfiguration
            key="ActivityType"
            visibleInFilterBar="false" />
    </smartFilterBar:controlConfiguration>

    <smartFilterBar:customFields>

        <!-- Custom Field 1: Plant MultiComboBox -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.PlantFilter"
            type="XML" />

        <!-- Custom Field 2: Activity Type MultiComboBox -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.ActivityTypeFilter"
            type="XML" />

        <!-- Custom Field 3: Aging Bucket MultiComboBox -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.AgingBucketFilter"
            type="XML" />

        <!-- Custom Field 4: Current Milestone MultiComboBox -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.MilestoneFilter"
            type="XML" />

        <!-- Custom Field 5: WM/EWM Switch -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.WMEWMSwitch"
            type="XML" />

        <!-- Custom Field 6: Period Month MultiComboBox -->
        <core:Fragment
            fragmentName="com.jip.view.fragment.PeriodMonthFilter"
            type="XML" />

    </smartFilterBar:customFields>

</smartFilterBar:SmartFilterBar>
```

---

### 9.2 Custom Field Registration

Each custom field fragment follows this pattern. Example for **Plant**:

```xml
<!-- PlantFilter.fragment.xml -->
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    xmlns:smartFilterBar="sap.ui.comp.smartfilterbar">

    <smartFilterBar:GroupElement label="Plant" visibleInFilterBar="true">
        <MultiComboBox
            id="multiComboBoxPlant"
            placeholder="Select Plant(s)..."
            selectionChange="onPlantSelectionChange">
            <!-- Items bound to /PlantSet or static -->
        </MultiComboBox>
    </smartFilterBar:GroupElement>

</core:FragmentDefinition>
```

For the **WM/EWM Switch**:

```xml
<!-- WMEWMSwitch.fragment.xml -->
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    xmlns:smartFilterBar="sap.ui.comp.smartfilterbar">

    <smartFilterBar:GroupElement label="WM/EWM Type" visibleInFilterBar="true">
        <HBox alignItems="Center">
            <Label text="WM" class="sapUiTinyMarginEnd"/>
            <Switch
                id="customSwitch"
                customTextOn="EWM"
                customTextOff="WM"
                state="false"
                change="onWMEWMSwitchChange" />
            <Label text="EWM" class="sapUiTinyMarginBegin"/>
        </HBox>
    </smartFilterBar:GroupElement>

</core:FragmentDefinition>
```

---

### 9.3 Controller Logic

```javascript
// SmartFilterBar.controller.js (excerpt)

onInit: function () {
    this._oSmartFilterBar   = this.byId("smartFilterBar");
    this._oPlantMCB         = this.byId("multiComboBoxPlant");
    this._oActivityMCB      = this.byId("multiComboBoxActivityType");
    this._oAgingBucketMCB   = this.byId("multiComboBoxAgingBucket");
    this._oMilestoneMCB     = this.byId("multiComboBoxMilestone");
    this._oCustomSwitch     = this.byId("customSwitch");
    this._oPeriodMonthMCB   = this.byId("multiComboBoxPeriodMonth");
},

onBeforeRebindTable: function (oEvent) {
    var mBindingParams = oEvent.getParameter("bindingParams");

    // --- 1. Plant (MultiComboBox) ---
    this._oPlantMCB.getSelectedItems().forEach(function (oItem) {
        mBindingParams.filters.push(
            new Filter("Plant", FilterOperator.EQ, oItem.getText())
        );
    });

    // --- 2. Activity Type (MultiComboBox) ---
    this._oActivityMCB.getSelectedItems().forEach(function (oItem) {
        mBindingParams.filters.push(
            new Filter("ActivityType", FilterOperator.EQ, oItem.getKey())
        );
    });

    // --- 3. Aging Bucket (MultiComboBox) ---
    this._oAgingBucketMCB.getSelectedItems().forEach(function (oItem) {
        mBindingParams.filters.push(
            new Filter("AgingBucket", FilterOperator.EQ, oItem.getKey())
        );
    });

    // --- 4. Current Milestone (MultiComboBox) ---
    this._oMilestoneMCB.getSelectedItems().forEach(function (oItem) {
        mBindingParams.filters.push(
            new Filter("CurrentMilestone", FilterOperator.EQ, oItem.getKey())
        );
    });

    // --- 5. WM/EWM Type (Switch) ---
    var bEWM = this._oCustomSwitch.getState();
    mBindingParams.filters.push(
        new Filter("WMEWMType", FilterOperator.EQ, bEWM ? "EWM" : "WM")
    );

    // --- 6. Period Month (MultiComboBox) ---
    this._oPeriodMonthMCB.getSelectedItems().forEach(function (oItem) {
        mBindingParams.filters.push(
            new Filter("PeriodMonth", FilterOperator.EQ, oItem.getKey())
        );
    });
},
```

---

### 9.4 OData / Filter Construction

When multiple values are selected for a single field (e.g., Plant = BJM, SER), the OData URL filter must combine them with OR:

```
$filter=(Plant eq 'BJM' or Plant eq 'SER')
  and (ActivityType eq 'SER' or ActivityType eq 'PPM')
  and WMEWMType eq 'WM'
  and (PeriodMonth eq '04' or PeriodMonth eq '05')
```

This is achieved by wrapping multi-value field filters in a parent `Filter` object with `bAnd = false`:

```javascript
// Example: Multi-value Plant filter with OR combination
var aPlantFilters = this._oPlantMCB.getSelectedItems().map(function (oItem) {
    return new Filter("Plant", FilterOperator.EQ, oItem.getText());
});

if (aPlantFilters.length > 0) {
    mBindingParams.filters.push(
        new Filter({ filters: aPlantFilters, and: false }) // OR
    );
}
```

---

### 9.5 Variant Management

Custom fields must implement the `onAfterVariantLoad` and `onBeforeVariantFetch` hooks to ensure their state is saved and restored correctly:

```javascript
onAfterVariantLoad: function () {
    var oData = this._oSmartFilterBar.getFilterData();

    // Restore Plant tokens
    if (oData._CUSTOM && oData._CUSTOM.plant) {
        this._oPlantMCB.setSelectedKeys(oData._CUSTOM.plant);
    }

    // Restore Activity Type tokens
    if (oData._CUSTOM && oData._CUSTOM.activityType) {
        this._oActivityMCB.setSelectedKeys(oData._CUSTOM.activityType);
    }

    // Restore WM/EWM Switch state
    if (oData._CUSTOM && oData._CUSTOM.wmewmType !== undefined) {
        this._oCustomSwitch.setState(oData._CUSTOM.wmewmType === "EWM");
    }

    // Restore Period Month tokens
    if (oData._CUSTOM && oData._CUSTOM.periodMonth) {
        this._oPeriodMonthMCB.setSelectedKeys(oData._CUSTOM.periodMonth);
    }
},

onBeforeVariantFetch: function () {
    var oData = this._oSmartFilterBar.getFilterData();
    oData._CUSTOM = oData._CUSTOM || {};

    oData._CUSTOM.plant         = this._oPlantMCB.getSelectedKeys();
    oData._CUSTOM.activityType  = this._oActivityMCB.getSelectedKeys();
    oData._CUSTOM.agingBucket   = this._oAgingBucketMCB.getSelectedKeys();
    oData._CUSTOM.milestone     = this._oMilestoneMCB.getSelectedKeys();
    oData._CUSTOM.wmewmType     = this._oCustomSwitch.getState() ? "EWM" : "WM";
    oData._CUSTOM.periodMonth   = this._oPeriodMonthMCB.getSelectedKeys();

    this._oSmartFilterBar.setFilterData(oData);
},
```

---

## 10. UI/UX Specification

### Filter Bar Layout

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  Standard ▾                                                               [↗ Export] │
├────────────┬───────────────┬───────────────┬──────────────┬─────────────┬───────────┤
│  Plant     │ Activity Type │ Aging Bucket  │ WM/EWM Type  │ Period Year │ Period    │
│ [BJM ×]    │ [SER ×][PPM×] │ [OK ×][60+ ×] │ WM ◉—— EWM  │ [2021 ×]   │ Month     │
│ [SER ×] ▾  │ [ADD ×]    ▾  │            ▾  │              │             │ [04 ×] ▾  │
├────────────┴───────────────┴───────────────┴──────────────┴─────────────┴───────────┤
│                              [▲ Collapse]  [⭐ Save Variant]   [  Go  ]              │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Control Sizing Guidelines

| Field | Min Width | Max Width | Notes |
|-------|-----------|-----------|-------|
| Plant | 140px | 220px | ~4–6 token display |
| Activity Type | 180px | 280px | Up to 12 options |
| Aging Bucket | 140px | 200px | 3 fixed options |
| Current Milestone | 160px | 260px | Dynamic from OData |
| WM/EWM Type Switch | 120px | 160px | Fixed width HBox |
| Period Month | 140px | 220px | 12 months |

### Token Overflow Behavior

When the number of selected tokens exceeds the visible width of a `MultiComboBox`:
- Tokens wrap to a second line (default UI5 behavior)
- A "+N more" indicator summarizes overflow count
- Hovering over the indicator shows a tooltip listing all selected values

### Empty State

If **Go** is pressed with no filters set:
- Dashboard charts display all available data (no filter applied)
- A toast message: *"Showing all data. Apply filters to narrow results."*

---

## 11. Filter Interaction Matrix

This matrix defines how combinations of filter fields interact when applied together:

| Plant | Activity Type | Aging Bucket | Milestone | WM/EWM | Period Month | Result |
|-------|---------------|-------------|-----------|--------|-------------|--------|
| ✓ | — | — | — | WM | ✓ | Data for selected plant(s) in WM mode for selected months |
| ✓ | ✓ | — | — | WM | ✓ | Above, filtered by activity types |
| ✓ | ✓ | ✓ | — | WM | ✓ | Above, filtered by aging status |
| ✓ | ✓ | ✓ | ✓ | WM | ✓ | Fully filtered result set |
| ✓ | — | — | — | EWM | ✓ | Same as row 1 but using EWM data scope |
| — | — | — | — | WM | — | All data in WM mode (no filter) |

**OR logic applies within each field; AND logic applies between fields.**

---

## 12. Acceptance Criteria

### AC-01: Plant MultiComboBox
- [ ] User can select 1 or more plants from the dropdown
- [ ] Selected plants appear as removable tokens
- [ ] OData request contains one EQ filter per selected plant, combined with OR
- [ ] Clearing all plants removes the Plant filter from the OData request

### AC-02: Activity Type MultiComboBox
- [ ] All 12 activity codes (ADD, INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN) appear in the dropdown
- [ ] User can select multiple types simultaneously
- [ ] OData request contains correct filters for each selected type

### AC-03: Aging Bucket MultiComboBox
- [ ] Values OK, 60+, 70+ appear in the dropdown
- [ ] User can select any combination of the three values
- [ ] Dashboard charts refresh with data matching selected bucket(s)

### AC-04: Current Milestone MultiComboBox
- [ ] Values are loaded dynamically from OData value help
- [ ] Type-ahead search filters the dropdown list
- [ ] Multiple milestones can be selected and generate OR-combined filters

### AC-05: WM/EWM Type Switch
- [ ] Switch renders with WM label (left) and EWM label (right)
- [ ] Default state is OFF (WM)
- [ ] Toggling to ON sends `WMEWMType eq 'EWM'` in the OData filter
- [ ] Toggling to OFF sends `WMEWMType eq 'WM'` in the OData filter
- [ ] Switch state is saved and restored with variant management

### AC-06: Period Month MultiComboBox
- [ ] Months 01–12 are listed with both numeric code and month name
- [ ] User can select multiple months
- [ ] OData request contains one EQ filter per selected month

### AC-07: Variant Management
- [ ] All 6 custom field states are saved when user saves a variant
- [ ] Loading a saved variant correctly restores all 6 custom field states
- [ ] The "Standard" variant (default) initializes with no selections and Switch = WM

### AC-08: Performance
- [ ] Full dashboard refresh after pressing Go completes in < 3 seconds
- [ ] No console errors during filter bar initialization

---

## 13. Dependencies & Risks

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| D-01 | SAP UI5 version ≥ 1.120 deployed on BTP | Basis/BTP Team | Verify |
| D-02 | OData service supports multi-value EQ filter for Plant, ActivityType, AgingBucket, Milestone, PeriodMonth | Backend Team | Verify |
| D-03 | `CurrentMilestone` OData value help entity is available and contains correct values | Backend Team | Verify |
| D-04 | SmartFilterBar `customFields` aggregation available in deployed UI5 lib version | UI5 Dev | Confirm |

### Risks

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R-01 | OData service does not support OR-combined multi-value filters | Medium | High | Test early; fallback to comma-separated IN filter if supported |
| R-02 | Variant serialization of custom field state fails for switch | Low | Medium | Implement explicit `onBeforeVariantFetch` hook with unit test |
| R-03 | MultiComboBox token overflow causes layout issues in compact screens | Medium | Low | Apply max-width and ellipsis styling; test at 1280px width |
| R-04 | Performance degradation when all filters are combined with large datasets | Low | High | Implement server-side paging; add loading indicator on chart rebind |

---

## 14. Appendix: Field Value Reference

### Activity Type Codes

| Code | Full Name | Category |
|------|-----------|----------|
| ADD | Additional Work | Unplanned |
| INS | Inspection | Planned |
| LOG | Logistics | Support |
| MID | Mid-Stream Activity | Operational |
| NME | New Material Equipment | Capital |
| OVH | Overhaul | Major Maintenance |
| PAP | Preventive — As Per Plan | Planned |
| PPM | Planned Preventive Maintenance | Planned |
| SER | Service | Routine |
| TRS | Transfer | Logistics |
| UIW | Uninstructed Work | Unplanned |
| USN | Urgent / Unscheduled | Emergency |

### Aging Bucket Reference

| Bucket | Meaning | Color Indicator |
|--------|---------|-----------------|
| OK | Item is within the target aging day threshold | Green |
| 60+ | Item has been outstanding for > 60 days past target | Amber |
| 70+ | Item has been outstanding for > 70 days past target | Red |

### Period Month Reference

| Value | Month | Quarter |
|-------|-------|---------|
| 01 | January | Q1 |
| 02 | February | Q1 |
| 03 | March | Q1 |
| 04 | April | Q2 |
| 05 | May | Q2 |
| 06 | June | Q2 |
| 07 | July | Q3 |
| 08 | August | Q3 |
| 09 | September | Q3 |
| 10 | October | Q4 |
| 11 | November | Q4 |
| 12 | December | Q4 |

### WM/EWM Type Reference

| Value | Full Name | Description |
|-------|-----------|-------------|
| WM | Warehouse Management | Classic SAP WM module (LG transactions) |
| EWM | Extended Warehouse Management | Advanced EWM module with enhanced process support |

---

*End of PRD 3.0 — JIP V4 Dashboard Smart Filter Bar*

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2023 | Product Team | Initial draft |
| 2.0 | 2024 | Product Team | Added variant management section |
| 3.0 | 2025 | Product Team | Full rewrite — MultiComboBox & Custom Switch upgrade |