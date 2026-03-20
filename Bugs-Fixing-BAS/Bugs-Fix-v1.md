# Bugs Fix V1 — BAS Lint Errors

**Date:** 2026-03-18  
**Status:** ✅ Fixed  
**Total Errors:** 6 (3 info + 2 warning + 1 info)

---

## Error Summary & Fixes

### 🔧 Fix 1: Missing i18n Keys in annotation.xml (3 errors)

**Error:**
```
Text key or value for 'Open Items (Exclude GI)' is not available in i18n.properties file
Text key or value for 'Critical Aging (60+ and 70+)' is not available in i18n.properties file
Text key or value for 'EWM Plants Only' is not available in i18n.properties file
```

**Root Cause:** Selection Variant `Text` property had hardcoded strings instead of i18n references.

**Fix — annotation.xml:** Changed hardcoded strings to i18n binding syntax:
```diff
- <PropertyValue Property="Text" String="Open Items (Exclude GI)"/>
+ <PropertyValue Property="Text" String="{@i18n>svOpenItemsText}"/>

- <PropertyValue Property="Text" String="Critical Aging (60+ and 70+)"/>
+ <PropertyValue Property="Text" String="{@i18n>svCriticalAgingText}"/>

- <PropertyValue Property="Text" String="EWM Plants Only"/>
+ <PropertyValue Property="Text" String="{@i18n>svEWMOnlyText}"/>
```

**Fix — i18n.properties:** Added 3 new keys:
```properties
svOpenItemsText=Open Items (Exclude GI)
svCriticalAgingText=Critical Aging (60+ and 70+)
svEWMOnlyText=EWM Plants Only
```

---

### 🔧 Fix 2: Unused Namespaces in annotation.xml (2 errors)

**Error:**
```
Unused namespace 'com.sap.vocabularies.Common.v1' with 'Common' alias.
Unused namespace 'com.sap.vocabularies.Communication.v1' with 'Communication' alias.
```

**Root Cause:** The original annotation.xml template included Common and Communication namespace references that were not used by the Selection Variant annotations.

**Fix:** Removed the 2 unused `<edmx:Reference>` blocks:
```diff
- <edmx:Reference Uri="https://sap.github.io/odata-vocabularies/vocabularies/Common.xml">
-     <edmx:Include Namespace="com.sap.vocabularies.Common.v1" Alias="Common"/>
- </edmx:Reference>
- <edmx:Reference Uri="https://sap.github.io/odata-vocabularies/vocabularies/Communication.xml">
-     <edmx:Include Namespace="com.sap.vocabularies.Communication.v1" Alias="Communication"/>
- </edmx:Reference>
```

---

### 🔧 Fix 3: Invalid manifest.json `_version` (1 error)

**Error:**
```
Value is not accepted. Valid values: "1.1.0" ... "1.58.0".
```

**Root Cause:** The auto-generated `_version: "1.60.0"` exceeds the BAS schema validator's known versions.

**Fix — manifest.json:**
```diff
- "_version": "1.60.0",
+ "_version": "1.58.0",
```

---

## Files Changed

| File | Changes |
|------|---------|
| `webapp/annotations/annotation.xml` | Removed 2 unused namespaces, replaced 3 hardcoded SV text strings with i18n bindings |
| `webapp/i18n/i18n.properties` | Added 3 new keys: `svOpenItemsText`, `svCriticalAgingText`, `svEWMOnlyText` |
| `webapp/manifest.json` | Changed `_version` from `1.60.0` to `1.58.0` |
