# CDS Fix — Separated WM / EWM with Aggregated Helper Views

**Date:** 2026-03-20  
**Problem:** `CX_SADL_DUMP_DATABASE_FAILURE` → HANA out-of-memory (GLOBAL_ALLOCATION_LIM)  
**Root Cause:** LEFT OUTER JOINs to EWM/WM tables return multiple rows per material, causing billions of cross-product rows  
**Solution:** Pre-aggregated helper views that return exactly **1 row per Material per Milestone** using `GROUP BY`

---

## Architecture Overview

```
BEFORE (broken):
  Reservation ──┬── WO (1:1 ✅)
                ├── PlantMap (1:1 ✅)
                ├── GI (1:1 ✅)
                ├── WM TransferOrder (1:N ❌ fan-out)
                ├── EWM ProductMap (1:N ❌ fan-out)
                └── EWM WarehouseTask (1:N ❌ fan-out)
                = BILLIONS of rows → OOM crash

AFTER (fixed):
  Reservation ──┬── WO (1:1 ✅)
                ├── PlantMap (1:1 ✅)
                ├── GI (1:1 ✅)
                ├── WM_LatestTO (1:1 ✅ aggregated)
                ├── EWM_MilestoneAgg NPB (1:1 ✅ aggregated)
                ├── EWM_MilestoneAgg RCV (1:1 ✅ aggregated)
                └── EWM_MilestoneAgg TR (1:1 ✅ aggregated)
                = Same as RESB count → no fan-out
```

---

## What to Create / Change

| # | View Name | Action | Purpose |
|---|-----------|--------|---------|
| 1 | `ZI_JIPV4_EWM_MilestoneAgg` | **CREATE NEW** | EWM: 1 row per Material × Milestone (GROUP BY) |
| 2 | `ZI_JIPV4_WM_MilestoneAgg` | **CREATE NEW** | WM: 1 row per Plant × Material × Milestone (GROUP BY) |
| 3 | `ZI_JIPV4_PartsComposite` | **REPLACE** | Use aggregated views, separate WM/EWM milestone logic |
| 4 | `ZC_JIPV4_AGING` | **RE-ACTIVATE** | Dependent on composite |
| 5 | `ZE_JIPV4_AGING` | **RE-ACTIVATE** | Dependent on consumption |

**Existing views that stay unchanged:** `ZI_JIPV4_Reservation`, `ZI_JIPV4_WorkOrder`, `ZI_JIPV4_GoodsMovement`, `ZI_JIPV4_EWM_PlantMap`, `ZI_JIPV4_EWM_ProductMap`, `ZI_JIPV4_EWM_WarehouseTask`, `ZI_JIPV4_TransferOrderWM`

---

## Step 1 — CREATE: ZI_JIPV4_EWM_MilestoneAgg

**Purpose:** Collapses ALL EWM warehouse tasks into exactly **1 row per MaterialNumber per JipMilestone**.  
Joins `/SCWM/ORDIM_C` directly to `/SCWM/BINMAT` to resolve MATID → MATNR, then GROUP BY.

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EWM Milestone Agg (1 row per Material)'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_MilestoneAgg
  as select from /scwm/ordim_c as WT
  inner join /scwm/binmat as BM
    on WT.matid = BM.matid
{
  key BM.matnr                              as MaterialNumber,
  key case
        when WT.procty = 'S919' then 'TR_REQUEST'
        when WT.procty = 'S920' then 'TR_REQUEST'
        when WT.procty = 'S997' then 'RECEIVED'
        when WT.procty = 'S994' then 'NPB'
        else 'OTHER'
      end                                   as JipMilestone,

      -- Latest confirmed timestamp per milestone
      max(WT.confirmed_at)                  as ConfirmedAt,

      -- Latest warehouse task number
      max(cast(WT.tanum as abap.char(20)))  as WarehouseTaskNo,

      -- Warehouse number (for reference)
      max(WT.lgnum)                         as WarehouseNumber
}
where WT.procty in ('S919','S920','S997','S994')
  and WT.confirmed_at is not initial
group by
  BM.matnr,
  case
    when WT.procty = 'S919' then 'TR_REQUEST'
    when WT.procty = 'S920' then 'TR_REQUEST'
    when WT.procty = 'S997' then 'RECEIVED'
    when WT.procty = 'S994' then 'NPB'
    else 'OTHER'
  end
```

**Result:** For material `01010-50612` with 20 S919 tasks + 15 S997 tasks + 10 S994 tasks → only **3 rows** (one per milestone), not 45.

---

## Step 2 — CREATE: ZI_JIPV4_WM_MilestoneAgg

**Purpose:** Collapses ALL WM Transfer Orders into exactly **1 row per Plant × Material × Milestone**.  
WM uses `LTAK.BWLVS` codes: 919/920 = TR_REQUEST, 997 = RECEIVED, 994 = NPB.

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WM Milestone Agg (1 row per Material)'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_WM_MilestoneAgg
  as select from ltap as LP
  inner join ltak as LK
    on  LP.lgnum = LK.lgnum
    and LP.tanum = LK.tanum
{
  key LP.werks                                  as Plant,
  key LP.matnr                                  as MaterialNumber,
  key case
        when LK.bwlvs = '919' then 'TR_REQUEST'
        when LK.bwlvs = '920' then 'TR_REQUEST'
        when LK.bwlvs = '997' then 'RECEIVED'
        when LK.bwlvs = '994' then 'NPB'
        else 'OTHER'
      end                                       as JipMilestone,

      max(LP.lgnum)                             as WarehouseNumber,
      max(cast(LP.tanum as abap.char(10)))      as TransferOrderNo,
      max(LK.bdatu)                             as TOCreationDate,
      max(LP.qdatu)                             as ConfirmationDate
}
where LK.bwlvs in ('919','920','997','994')
group by
  LP.werks,
  LP.matnr,
  case
    when LK.bwlvs = '919' then 'TR_REQUEST'
    when LK.bwlvs = '920' then 'TR_REQUEST'
    when LK.bwlvs = '997' then 'RECEIVED'
    when LK.bwlvs = '994' then 'NPB'
    else 'OTHER'
  end
```

**Result:** For material `2529` in plant `BDI` with 10 TOs across history → only **up to 3 rows** (one per milestone), not 10.

---

## Step 3 — REPLACE: ZI_JIPV4_PartsComposite

**Key changes:**
- WM and EWM milestone detection is **completely separated**
- All JOINs are now **1:1** (guaranteed by GROUP BY in helper views)
- `WmEwmType` field lets user filter by `'WM'` or `'EWM'` globally
- Milestone dates are cleanly split: `WM_TRDate`, `WM_ReceivedDate`, `WM_NPBDate` vs `EWM_TRConfirmedAt`, `EWM_RCVConfirmedAt`, `EWM_NPBConfirmedAt`

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Parts Composite - WM and EWM Separated'
@VDM.viewType: #COMPOSITE

define view entity ZI_JIPV4_PartsComposite
  as select from ZI_JIPV4_Reservation as Resv

  -- Work Order Header (1:1)
  left outer join ZI_JIPV4_WorkOrder as WO
    on Resv.WorkOrderNumber = WO.WorkOrderNumber

  -- EWM Plant Detection (1:1)
  left outer join ZI_JIPV4_EWM_PlantMap as PM
    on Resv.Plant = PM.Plant

  -- Goods Movement / GI (1:1 via ResvNo + ResvItem)
  left outer join ZI_JIPV4_GoodsMovement as GI
    on  Resv.ReservationNumber = GI.ReservationNumber
    and Resv.ReservationItem   = GI.ReservationItem

  -- ========== WM PATH (aggregated — 1 row per Plant+Material+Milestone) ==========

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_TR
    on  Resv.Plant             = WM_TR.Plant
    and Resv.MaterialNumber    = WM_TR.MaterialNumber
    and WM_TR.JipMilestone     = 'TR_REQUEST'

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_RCV
    on  Resv.Plant             = WM_RCV.Plant
    and Resv.MaterialNumber    = WM_RCV.MaterialNumber
    and WM_RCV.JipMilestone    = 'RECEIVED'

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_NPB
    on  Resv.Plant             = WM_NPB.Plant
    and Resv.MaterialNumber    = WM_NPB.MaterialNumber
    and WM_NPB.JipMilestone    = 'NPB'

  -- ========== EWM PATH (aggregated — 1 row per Material+Milestone) ==========

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_TR
    on  Resv.MaterialNumber    = EWM_TR.MaterialNumber
    and EWM_TR.JipMilestone    = 'TR_REQUEST'

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_RCV
    on  Resv.MaterialNumber    = EWM_RCV.MaterialNumber
    and EWM_RCV.JipMilestone   = 'RECEIVED'

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_NPB
    on  Resv.MaterialNumber    = EWM_NPB.MaterialNumber
    and EWM_NPB.JipMilestone   = 'NPB'

{
  key Resv.ReservationNumber,
  key Resv.ReservationItem,
  key Resv.ReservationCategory,

      -- Material
      Resv.MaterialNumber,
      Resv.WorkOrderNumber,
      Resv.StorageLocation,

      -- Work Order Header
      WO.Plant,
      WO.OrderType,
      WO.ActivityType,
      WO.ABCIndicator,
      WO.EquipmentNumber,
      WO.WOCreationDate,
      WO.WOReleaseDate,
      WO.SalesOrderNumber,
      WO.AppSDHDate,
      WO.SoldToParty,

      -- Quantities
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      Resv.RequirementQty,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      Resv.QtyAvailCheck,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      Resv.QtyWithdrawn,
      Resv.BaseUnit,

      -- ========== WM / EWM Type Detection ==========
      case
        when PM.WarehouseNumber is not null then 'EWM'
        else 'WM'
      end                                     as WmEwmType,

      -- Warehouse Number
      case
        when PM.WarehouseNumber is not null then PM.WarehouseNumber
        else WM_TR.WarehouseNumber
      end                                     as WarehouseNumber,

      -- ========== CURRENT MILESTONE — WM and EWM separated ==========
      case
        -- GI is always from MATDOC regardless of WM/EWM
        when GI.PostingDate is not null then 'GI'

        -- EWM milestones (only when plant is EWM)
        when PM.WarehouseNumber is not null and EWM_NPB.MaterialNumber is not null then 'NPB'
        when PM.WarehouseNumber is not null and EWM_RCV.MaterialNumber is not null then 'RECEIVED'
        when PM.WarehouseNumber is not null and EWM_TR.MaterialNumber  is not null then 'TR_REQUEST'

        -- WM milestones (only when plant is NOT EWM)
        when PM.WarehouseNumber is null and WM_NPB.MaterialNumber is not null then 'NPB'
        when PM.WarehouseNumber is null and WM_RCV.MaterialNumber is not null then 'RECEIVED'
        when PM.WarehouseNumber is null and WM_TR.MaterialNumber  is not null then 'TR_REQUEST'

        else 'PENDING'
      end                                     as CurrentMilestone,

      -- ========== MILESTONE DATES — WM PATH ==========
      WO.AppSDHDate                           as SDHApprovalDate,
      WO.WOReleaseDate                        as ReleaseDate,

      -- WM dates (separate per milestone)
      WM_TR.TOCreationDate                    as WM_TRDate,
      WM_TR.TransferOrderNo                   as WM_TRNumber,
      WM_RCV.ConfirmationDate                 as WM_ReceivedDate,
      WM_NPB.ConfirmationDate                 as WM_NPBDate,

      -- ========== MILESTONE DATES — EWM PATH ==========
      EWM_TR.ConfirmedAt                      as EWM_TRConfirmedAt,
      EWM_TR.WarehouseTaskNo                  as EWM_TRTaskNo,
      EWM_RCV.ConfirmedAt                     as EWM_RCVConfirmedAt,
      EWM_RCV.WarehouseTaskNo                 as EWM_RCVTaskNo,
      EWM_NPB.ConfirmedAt                     as EWM_NPBConfirmedAt,
      EWM_NPB.WarehouseTaskNo                 as EWM_NPBTaskNo,

      -- Consolidated EWM fields (for backward compatibility with MDE)
      coalesce(EWM_NPB.ConfirmedAt, coalesce(EWM_RCV.ConfirmedAt, EWM_TR.ConfirmedAt))
                                               as EWM_ConfirmedAt,
      coalesce(EWM_NPB.WarehouseTaskNo, coalesce(EWM_RCV.WarehouseTaskNo, EWM_TR.WarehouseTaskNo))
                                               as EWM_WTNumber,

      -- GI
      GI.PostingDate                          as GIDate,
      GI.MaterialDocNumber                    as GINumber,

      -- ========== AGING CALCULATIONS ==========

      -- Aging Release: SDH Approval → WO Release (same for WM and EWM)
      cast( case
              when WO.AppSDHDate is not null and WO.WOReleaseDate is not null
              then dats_days_between(WO.AppSDHDate, WO.WOReleaseDate)
              else 0
            end as abap.dec(10,2) )            as AgingRelease,

      -- Aging Bucket: Overall aging from SDH to today
      case
        when dats_days_between(WO.AppSDHDate, $session.system_date) >= 70 then '70+'
        when dats_days_between(WO.AppSDHDate, $session.system_date) >= 60 then '60+'
        else 'OK'
      end                                     as AgingBucket,

      -- Target Aging Days per Activity Type
      cast( case WO.ActivityType
              when 'ADD' then 15  when 'INS' then 15  when 'LOG' then 15
              when 'MID' then 15  when 'NME' then 15  when 'OVH' then 15
              when 'PAP' then 15  when 'PPM' then 15  when 'SER' then 15
              when 'TRS' then 15  when 'UIW' then 15  when 'USN' then 15
              else 15
            end as abap.dec(10,2) )            as TargetAgingDays,

      -- Record Count (DEC to prevent overflow)
      cast(1 as abap.dec(10,0))                as RecordCount,

      -- Period Month (YYYY-MM)
      concat(left(cast(WO.WOCreationDate as abap.char(8)), 4),
        concat('-', substring(cast(WO.WOCreationDate as abap.char(8)), 5, 2))
      )                                       as PeriodMonth,

      -- Period Year (YYYY)
      left(cast(WO.WOCreationDate as abap.char(8)), 4)
                                              as PeriodYear
}
```

---

## Step 4 — Update ZC_JIPV4_AGING (if new fields needed)

The consumption view may need the new WM/EWM separated fields added. At minimum, re-activate it. If you want the separated milestone dates exposed to OData, add them:

```abap
-- Add these new fields to ZC_JIPV4_AGING if needed for drill-down:
      @DefaultAggregation: #NONE
      WM_TRDate,
      @DefaultAggregation: #NONE
      WM_TRNumber,
      @DefaultAggregation: #NONE
      WM_ReceivedDate,
      @DefaultAggregation: #NONE
      WM_NPBDate,
      @DefaultAggregation: #NONE
      EWM_TRConfirmedAt,
      @DefaultAggregation: #NONE
      EWM_TRTaskNo,
      @DefaultAggregation: #NONE
      EWM_RCVConfirmedAt,
      @DefaultAggregation: #NONE
      EWM_RCVTaskNo,
      @DefaultAggregation: #NONE
      EWM_NPBConfirmedAt,
      @DefaultAggregation: #NONE
      EWM_NPBTaskNo,
```

**Or keep the existing consolidated fields** (`EWM_ConfirmedAt`, `EWM_WTNumber`, `WM_TRDate`, `WM_ReceivedDate`) for backward compatibility — the composite still exposes them.

---

## Step 5 — Activation Order

```
1. CREATE + Activate  ZI_JIPV4_EWM_MilestoneAgg    (Ctrl+F3)
2. CREATE + Activate  ZI_JIPV4_WM_MilestoneAgg     (Ctrl+F3)
3. EDIT  + Activate  ZI_JIPV4_PartsComposite       (Ctrl+F3)
4. RE-ACTIVATE        ZC_JIPV4_AGING                (Ctrl+F3)
5. RE-ACTIVATE        ZE_JIPV4_AGING                (Ctrl+F3)
6. SAP GUI:           /IWFND/CACHE_CLEANUP
```

---

## Step 6 — Verification Queries (SQL Console in Eclipse ADT)

### Check 1: Row count should match RESB

```sql
-- Composite count (should be close to RESB)
SELECT count(*) FROM ZI_JIPV4_PartsComposite WHERE Plant = 'BLP';

-- Compare with raw RESB
SELECT count(*) FROM resb WHERE werks = 'BLP' AND xloek = '' AND aufnr <> '';

-- These two numbers should be very close (ideally equal)
```

### Check 2: No more fan-out

```sql
-- Check for duplicates — should return ZERO rows
SELECT ReservationNumber, ReservationItem, count(*) as cnt
FROM ZI_JIPV4_PartsComposite
GROUP BY ReservationNumber, ReservationItem
HAVING count(*) > 1;
```

### Check 3: EWM aggregation works

```sql
-- Should return MAX 3 rows per material (TR/RCV/NPB)
SELECT MaterialNumber, JipMilestone, ConfirmedAt, WarehouseTaskNo
FROM ZI_JIPV4_EWM_MilestoneAgg
WHERE MaterialNumber = '01010-50612';
```

### Check 4: WM aggregation works

```sql
-- Should return MAX 3 rows per plant+material (TR/RCV/NPB)
SELECT Plant, MaterialNumber, JipMilestone, TransferOrderNo, ConfirmationDate
FROM ZI_JIPV4_WM_MilestoneAgg
WHERE Plant = 'BDI' AND MaterialNumber = '2529';
```

### Check 5: Filter by WmEwmType works

```sql
-- EWM plants only
SELECT Plant, count(*) FROM ZI_JIPV4_PartsComposite
WHERE WmEwmType = 'EWM'
GROUP BY Plant;

-- WM plants only
SELECT Plant, count(*) FROM ZI_JIPV4_PartsComposite
WHERE WmEwmType = 'WM'
GROUP BY Plant;
```

---

## Why This Works

| Before | After | Why |
|--------|-------|-----|
| JOIN to `ZI_JIPV4_TransferOrderWM` on Plant+Material → N rows | JOIN to `ZI_JIPV4_WM_MilestoneAgg` on Plant+Material+Milestone → **1 row** | GROUP BY collapses all TOs into 1 per milestone |
| JOIN to `ZI_JIPV4_EWM_ProductMap` on MaterialNumber → N MATIDs | Aggregated view joins BINMAT internally → **1 MATNR** | GROUP BY on MATNR collapses all MATIDs |
| JOIN to `ZI_JIPV4_EWM_WarehouseTask` on ProductGuid → N tasks | JOIN to `ZI_JIPV4_EWM_MilestoneAgg` on Material+Milestone → **1 row** | GROUP BY collapses all tasks per milestone |
| 100K RESB × 100x fan-out = **10 BILLION rows** | 100K RESB × 1 = **100K rows** | All JOINs are now 1:1 |
