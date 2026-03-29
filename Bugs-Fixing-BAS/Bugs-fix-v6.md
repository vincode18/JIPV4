# Bugs-Fix-V6 — Custom Filter Fragment & Manifest Errors

**Date:** 2026-03-27  
**Application:** `com.sap.jipv4.zjipv4aging` (SAP Fiori OVP)  
**Status:** Fixed  

---

## 1. Error Summary

After implementing PRD 3.0 Custom Filter Enhancement, two sets of errors appeared:

**Phase A — Runtime Errors (browser console):**

| # | Error Message | Root Cause |
|---|---------------|------------|
| 1 | `The "ControlConfiguration" class can't have an empty ID attribute when flexEnabled is "true"` | Missing stable `id` on ControlConfiguration elements |
| 2 | `Unknown attribute key: visibleInFilterBar` | Wrong property name (should be `visibleInAdvancedArea`) |
| 3 | `The "Item" / "HBox" / "Label" class can't have an empty ID attribute` | Missing stable `id` on Item, HBox, Label elements |
| 4 | `Property customFilter is not allowed.` | Invalid `customFilter` property in `sap.ovp` manifest section |

**Phase B — Build Error (BAS terminal):**

| # | Error Message | Root Cause |
|---|---------------|------------|
| 5 | `fiori run` — `Command run failed with error :` (silent crash) | Missing `sap.ui.viewExtensions` registration in manifest.json |

---

## 2. Root Cause Analysis

### Bugs 1-3: Missing Stable IDs + Wrong Attribute

When `"flexEnabled": true` is set in `manifest.json`, every control needs an explicit stable `id`. Also `visibleInFilterBar` is not a valid property — the correct one is `visibleInAdvancedArea`.

### Bug 4: Invalid `customFilter` in `sap.ovp`

The `sap.ovp` section does not support a `customFilter` property.

### Bug 5: Missing `sap.ui.viewExtensions` — The Real Fix

Per the **official SAP OVP documentation** ([Adding Custom Filters to the Overview Page](https://ui5.sap.com/docs/topics/4739893805f74a409e241698858ee424.html)), OVP custom filter fragments **must** be registered via `sap.ui.viewExtensions` in the manifest using the key pattern:

```
SmartFilterBarControlConfigurationExtension|{EntitySetName}
```

The OVP framework loads the fragment automatically through this extension point — **no programmatic `Fragment.load()` is needed**.

Additionally, `globalFilterEntitySet` must be set in `sap.ovp` to match the entity set name used in the extension key.

---

## 3. Fixes Applied

### 3.1 manifest.json — Correct OVP Extension Registration

**Added `sap.ui.viewExtensions`** alongside `sap.ui.controllerExtensions`:

```json
"extends": {
    "extensions": {
        "sap.ui.controllerExtensions": {
            "sap.ovp.app.Main": {
                "controllerName": "com.sap.jipv4.zjipv4aging.ext.customFilter.CustomFilterController"
            }
        },
        "sap.ui.viewExtensions": {
            "sap.ovp.app.Main": {
                "SmartFilterBarControlConfigurationExtension|ZC_JIPV4_AGING": {
                    "className": "sap.ui.core.Fragment",
                    "fragmentName": "com.sap.jipv4.zjipv4aging.ext.customFilter.CustomFilter",
                    "type": "XML"
                }
            }
        }
    }
}
```

**Added `globalFilterEntitySet`** to `sap.ovp`:

```json
"globalFilterEntitySet": "ZC_JIPV4_AGING"
```

**Removed** invalid `customFilter` property from `sap.ovp`.

### 3.2 CustomFilter.fragment.xml — Stable IDs + Correct Attributes

All ControlConfiguration elements now have:
- Stable `id` attribute (e.g. `ccPlant`, `ccActivityType`, etc.)
- `groupId="_BASIC"` — places filter in the basic group
- `visibleInAdvancedArea="true"` — makes filter visible on the bar

All child controls (Item, HBox, Label, Switch) also have stable IDs.

**Example (Plant):**

```xml
<smartfilterbar:ControlConfiguration id="ccPlant" groupId="_BASIC" key="Plant"
    label="{i18n>filter_plant}" visibleInAdvancedArea="true">
    <smartfilterbar:customControl>
        <MultiComboBox id="customPlantFilter" ...>
            <core:Item id="itemPlantTemplate" key="{Plant}" text="{Plant}"/>
        </MultiComboBox>
    </smartfilterbar:customControl>
</smartfilterbar:ControlConfiguration>
```

### 3.3 CustomFilterController.js — Simplified (No Fragment.load)

- **Removed** `sap/ui/core/Fragment` import and `_loadCustomFilterFragment()` method
- Fragment is now loaded **automatically** by OVP via `sap.ui.viewExtensions`
- Uses `this.oView.byId()` pattern per official SAP OVP docs
- `_buildCustomFilters()` centralizes filter construction
- `getCustomFilters()` returns the filter array for OVP card rebind
- `getCustomAppStateDataExtension()` / `restoreCustomAppStateDataExtension()` handle variant state

---

## 4. Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `webapp/manifest.json` | Bug Fix | Added `sap.ui.viewExtensions`, `globalFilterEntitySet`; removed invalid `customFilter` |
| `webapp/ext/customFilter/CustomFilter.fragment.xml` | Bug Fix | Added stable IDs, `groupId="_BASIC"`, `visibleInAdvancedArea="true"` |
| `webapp/ext/customFilter/CustomFilterController.js` | Refactor | Removed Fragment.load(); uses `this.oView.byId()` per official OVP docs |

---

## 5. Reference

- **Official SAP Documentation:** [Adding Custom Filters to the Overview Page](https://ui5.sap.com/docs/topics/4739893805f74a409e241698858ee424.html)
- **Key Pattern:** `SmartFilterBarControlConfigurationExtension|{EntitySetName}` in `sap.ui.viewExtensions`

---

## 6. Verification Checklist

- [ ] `npm run start` completes without error on BAS
- [ ] No console errors on application startup
- [ ] All 6 custom filters render in the SmartFilterBar
- [ ] MultiComboBox controls allow multi-selection
- [ ] WM/EWM Switch toggles between WM and EWM
- [ ] Pressing "Go" applies all custom filters to OVP cards
- [ ] Variant management saves and restores custom filter state
