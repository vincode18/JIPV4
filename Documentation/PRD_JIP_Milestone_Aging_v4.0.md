# PRD.MD: SAP CDS & Dashboard Requirement Document

## JIP Milestone Aging Dashboard V4

**Version 4.0 — Architecture: Pure CDS (Method 4) — OData V2**

---

## 1. Identity & Context

| Field | Value |
|-------|-------|
| **Project Name** | JIP Milestone Aging Dashboard V4 |
| **Module** | PM (Plant Maintenance) |
| **Developer** | Viandra |
| **Target Users** | Maintenance Planner, Warehouse Manager |
| **Objective** | Track aging of Job-In-Progress parts across all plants (WM & EWM), by Activity Type and milestone stages (TR → Received → NPB → GI), with milestone-to-milestone aging calculation, aging buckets (OK/<60, 60+, 70+), and monthly JIP averages by Activity Type. |
| **Architecture** | Method 4: Pure CDS (no ABAP Report, no Z-Table) |
| **OData Version** | OData V2 via SADL Auto-Publish (`@OData.publish: true`) |

---

## 2. Architecture Overview

### 2.1 Architecture Diagram (Method 4 — Pure CDS)

```
┌─────────────────────────────────────────────────────────────────────┐
│              SOURCE TABLES (Basic Tables Only)                      │
│                                                                     │
│  AUFK, AFKO, AFIH, ILOA, JEST, RESB, MSEG, LTAK, LTAP, LTBK,    │
│  /SCWM/ORDIM_C, /SCWM/BINMAT, /SCWM/TMAPSTLOC,                  │
│  ZTWOAPPR, VBAK, VBKD, MARA, MAKT                                │
└──────────────────────────┬──────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────────┐
│              CDS VIEWS — LAYERED (VDM Architecture)                │
│                                                                     │
│  BASIC VIEWS (Layer 1):                                            │
│  ┌───────────────────┐ ┌─────────────────────┐ ┌────────────────┐  │
│  │ZI_JIPV4_WorkOrder │ │ZI_JIPV4_Reservation │ │ZI_JIPV4_GoodsMvt│ │
│  │AUFK+AFKO+AFIH     │ │RESB                 │ │MSEG+MKPF        │ │
│  │+ILOA+ZTWOAPPR     │ │                     │ │(BWART=Z26)      │ │
│  └───────────────────┘ └─────────────────────┘ └────────────────┘  │
│  ┌───────────────────┐ ┌─────────────────────────┐                 │
│  │ZI_JIPV4_TransfrWM │ │ZI_JIPV4_EWM_WhsTask     │                 │
│  │LTAP+LTAK          │ │/SCWM/ORDIM_C + BINMAT    │                 │
│  │                   │ │(CAST join for MATID)      │                 │
│  └───────────────────┘ └─────────────────────────┘                 │
│  ┌───────────────────┐ ┌─────────────────────────┐                 │
│  │ZI_JIPV4_EWM       │ │ZI_JIPV4_EWM_PlantMap   │                 │
│  │  _ProductMap      │ │/SCWM/TMAPSTLOC          │                 │
│  │/SCWM/BINMAT       │ │(Plant→LGNUM detection)   │                 │
│  └───────────────────┘ └─────────────────────────┘                 │
│                                                                     │
│  COMPOSITE VIEW (Layer 2):                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ ZI_JIPV4_PartsComposite                                     │   │
│  │ Joins all Basic Views + WM/EWM branching + Aging calc       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  CONSUMPTION VIEW (Layer 3):                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ ZC_JIPV4_AGING — @OData.publish: true (OData V2)           │   │
│  │ + UI Annotations for Fiori OVP                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────────┐
│              OData V2 Service (Auto-published via SADL)             │
└──────────────────────────┬──────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────────┐
│              FIORI OVERVIEW PAGE (OVP)                               │
│              6 Chart Cards + 2 Pivot Tables + Detail Table          │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Architecture Decision — Method 4 (Pure CDS)

| Aspect | Decision | Reasoning |
|--------|----------|-----------|
| **Data Processing** | Pure CDS Views (no ABAP Report) | All logic in CDS: joins, aging, WM/EWM branching |
| **MATID Conversion** | **`/SCWM/BINMAT`** table join with `CAST` | Converts MATID (RAW16) → MATNR directly in CDS |
| **WM/EWM Detection** | `/SCWM/TMAPSTLOC` table join | If LGNUM exists for plant+sloc → EWM, otherwise → WM |
| **GI Movement Type** | **BWART = 'Z26'** (custom) | Custom movement type for Goods Issue in this system |
| **Release Date** | **AFKO-FTRMI** | Actual release date from order header operations |
| **Data Storage** | No Z-Table | Real-time data, no staging table, no background job |
| **CDS Layer** | VDM 3-Layer (Basic → Composite → Consumption) | Modular, reusable, maintainable |
| **OData Version** | **OData V2** via `@OData.publish: true` (SADL) | Auto-exposure, no manual SEGW needed |

> **Key Decision: Why Method 4 over Method 3?**
>
> Method 3 (ABAP Report + Z-Table) was rejected. Method 4 achieves the same result using pure CDS:
> - EWM MATID (RAW16) is resolved via `/SCWM/BINMAT` join with `CAST(matid as abap.char(32))` on both sides
> - WM/EWM detection uses `/SCWM/TMAPSTLOC` (plant+sloc → warehouse mapping)
> - No Function Module `CONVERSION_EXIT_MDLPD_OUTPUT` needed
> - No background job scheduling (SM36) required
> - Data is always real-time

---

## 3. Data Source Validation (Strict)

All source tables are **Basic Tables** (transparent tables). No views or structures used.

### 3.1 Primary Entities

| Business Object | Proposed Table | Join Required With | Purpose | Validation Check |
|----------------|---------------|-------------------|---------|-----------------|
| Order Header | AUFK | AFKO, AFIH | WO master data, creation date, plant | ✖ No CAUFV, VIAUFKS |
| Order Operations | AFKO | AUFK via AUFNR | **FTRMI** (Release Date), operations | ✔ Basic table |
| PM Order Header | AFIH | AUFK via AUFNR | Source of ILART (Activity Type), ILOAN | ✔ Basic table |
| **Location/ABC** | **ILOA** | **AFIH via ILOAN** | **ABC Indicator (ABCKZ)** | **✔ Basic table** |
| Order Status | JEST | TJ02T (Status Text) | WO Release / TECO / Closed filtering | Filter: INACT = '' |
| Reservations | RESB | AUFK via AUFNR | Material requirements, qty (VMENG) | ✔ Basic table |
| Goods Issue | MSEG | RESB via MBLNR | GI tracking, posting date | **Filter: BWART = 'Z26'** |
| Customer | VBAK + VBKD | AUFK via KDAUF | Sold-to party + customer ref (BSTKD) | ✔ Basic table |
| EWM Whs Tasks | /SCWM/ORDIM_C | RESB via material/WO | Milestones: PROCTY + NLPLA zones | ✔ EWM base table |
| **EWM Material Map** | **/SCWM/BINMAT** | **/SCWM/ORDIM_C via MATID (CAST)** | **MATID GUID → MATNR resolution** | **✔ EWM base table** |
| EWM Plant Map | /SCWM/TMAPSTLOC | RESB via WERKS+LGORT | Determine if plant/sloc is EWM-managed | ✔ EWM base table |
| Classic WM | LTAP + LTAK + LTBK | RESB via reservation | Transfer orders (non-EWM plants) | ✔ Basic table |
| WO Approval | ZTWOAPPR | AUFK via AUFNR | Approval LVL2/LVL3 dates | ✔ Custom Z-table |
| Material Master | MARA + MAKT | RESB via MATNR | Material text descriptions | ✔ Basic table |

> **Consultant Note (Crosschecked with Blueprint V3):**
> - `VIAUFKS` and `CAUFV` are views — replaced with direct joins to `AUFK`/`AFKO`/`AFIH`
> - **Release Date** sourced from `AFKO-FTRMI` (not IDAT1)
> - **ABC Indicator** sourced from `ILOA-ABCKZ` via `AFIH-ILOAN → ILOA` join
> - **GI Movement Type** is custom `Z26` (not standard 261)
> - **EWM MATID** (RAW16) resolved via `/SCWM/BINMAT` join using `CAST(matid as abap.char(32))` — replaces `/SAPAPO/MATKEY`
> - **WM/EWM detection** via `/SCWM/TMAPSTLOC` (confirmed in blueprint)

### 3.2 EWM MATID → MATNR Resolution (via /SCWM/BINMAT)

| Step | What | How |
|------|------|-----|
| 1 | Read `/SCWM/ORDIM_C` | Field `MATID` is RAW(16) — binary product GUID |
| 2 | Read `/SCWM/BINMAT` | Contains both `MATID` (RAW type) and `MATNR` (CHAR) |
| 3 | CAST both sides | `CAST(WT.matid as abap.char(32)) = CAST(BM.matid as abap.char(32))` |
| 4 | Result | `BM.matnr` gives the readable material number (e.g., 01010-50612) |

**CDS Join Pattern:**
```abap
left outer join /scwm/binmat as BM
  on cast( WT.matid as abap.char(32) ) = cast( BM.matid as abap.char(32) )
```

**Alternative CAST options (if `abap.char(32)` fails):**
- Option A: `cast( WT.matid as abap.raw(16) ) = cast( BM.matid as abap.raw(16) )`
- Option B: `cast( WT.matid as abap.sstring(32) ) = cast( BM.matid as abap.sstring(32) )`

### 3.3 WM vs EWM Detection Logic (via /SCWM/TMAPSTLOC)

| Detection Method | Logic | Result |
|-----------------|-------|--------|
| `/SCWM/TMAPSTLOC` exists for WERKS+LGORT | Record found with LGNUM | **EWM** — use `/SCWM/ORDIM_C` for milestones |
| `/SCWM/TMAPSTLOC` does NOT exist | No LGNUM mapping | **WM** — use LTAP/LTAK for milestones |

**CDS Join Pattern:**
```abap
left outer join /scwm/tmapstloc as TM
  on  Resv.Plant           = TM.werks
  and Resv.StorageLocation = TM.lgort

-- Then:
case when TM.lgnum is not null then 'EWM' else 'WM' end as WmEwmType
```

---

## 4. CDS View Design (Pure CDS — Method 4)

### 4.1 View Inventory

| # | View Name | Layer | Source Table(s) | Purpose |
|---|-----------|-------|----------------|---------|
| 1 | ZI_JIPV4_Reservation | Basic | RESB | Reservation line items |
| 2 | ZI_JIPV4_WorkOrder | Basic | AUFK+AFKO+AFIH+**ILOA**+ZTWOAPPR | WO header + activity type + **ABC indicator** |
| 3 | ZI_JIPV4_TransferOrderWM | Basic | LTAP+LTAK+LTBK | Classic WM transfer orders |
| 4 | ZI_JIPV4_GoodsMovement | Basic | MSEG+MKPF | GI postings (**BWART=Z26**) |
| 5 | ZI_JIPV4_EWM_ProductMap | Basic | **/SCWM/BINMAT** | MATID → MATNR mapping |
| 6 | ZI_JIPV4_EWM_WarehouseTask | Basic | /SCWM/ORDIM_C + **BINMAT** (CAST) | EWM tasks + material resolved |
| 7 | ZI_JIPV4_EWM_PlantMap | Basic | /SCWM/TMAPSTLOC | Plant/SLoc → LGNUM (EWM detection) |
| 8 | ZI_JIPV4_PartsComposite | Composite | All Basic Views | WM/EWM merge + aging calc |
| 9 | ZC_JIPV4_AGING | Consumption | PartsComposite | OData V2 + UI annotations |

### 4.2 Basic Views (Layer 1)

#### ZI_JIPV4_Reservation
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Reservation Items'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_Reservation
  as select from resb
{
  key rsnum    as ReservationNumber,
  key rspos    as ReservationItem,
      aufnr    as WorkOrderNumber,
      matnr    as MaterialNumber,
      werks    as Plant,
      lgort    as StorageLocation,
      bdter    as RequirementDate,
      bdmng    as RequirementQty,
      vmeng    as QtyAvailCheck,
      enmng    as QtyWithdrawn,
      meins    as BaseUnit,
      bwart    as MovementType,
      sobkz    as SpecialStockIndicator,
      kzear    as FinalIssueFlag
}
where xloek  = ''
  and aufnr <> ''
```

#### ZI_JIPV4_WorkOrder (Updated: +ILOA for ABC, AFKO-FTRMI for Release Date)
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Work Order Header'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_WorkOrder
  as select from aufk as AK
  inner join afko as AO on AK.aufnr = AO.aufnr
  inner join afih as AI on AK.aufnr = AI.aufnr
  left outer join iloa as IL on AI.iloan = IL.iloan
  left outer join ztwoappr as ZA on AK.aufnr = ZA.aufnr
  left outer join vbak as VB on AK.kdauf = VB.vbeln
  left outer join vbkd as VD on AK.kdauf = VD.vbeln
{
  key AK.aufnr    as WorkOrderNumber,
      AK.auart    as OrderType,
      AK.autyp    as OrderCategory,
      AK.erdat    as WOCreationDate,
      AK.werks    as Plant,
      AK.kdauf    as SalesOrderNumber,

      -- PM Header
      AI.ilart    as ActivityType,
      AI.equnr    as EquipmentNumber,
      AI.eqfnr    as EquipmentSortField,

      -- ABC Indicator (via AFIH-ILOAN → ILOA)
      IL.abckz    as ABCIndicator,

      -- Release Date from AFKO-FTRMI
      AO.ftrmi    as WOReleaseDate,

      -- Approval Dates
      ZA.lvl2dt   as AppPDHDate,
      ZA.lvl3dt   as AppSDHDate,

      -- Customer Info
      VB.kunnr    as SoldToParty,
      VD.bstkd    as CustomerReference
}
```

#### ZI_JIPV4_TransferOrderWM
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Classic WM Transfer Orders'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_TransferOrderWM
  as select from ltap as LP
  inner join ltak as LK on LP.lgnum = LK.lgnum and LP.tanum = LK.tanum
  left outer join ltbk as LB on LP.lgnum = LB.lgnum and LP.tbnum = LB.tbnum
{
  key LP.lgnum    as WarehouseNumber,
  key LP.tanum    as TransferOrderNo,
  key LP.tapos    as TransferOrderItem,
      LP.matnr    as MaterialNumber,
      LP.werks    as Plant,
      LP.anfnr    as RequirementNumber,
      LP.anfps    as RequirementItem,
      LP.erdat    as TOCreationDate,
      LK.bwlvs    as MovementType,
      LK.qdatu    as ConfirmationDate,
      LP.vsola    as TargetQty,
      LP.meins    as UnitOfMeasure,
      LB.tbnum    as TransferRequestNo
}
```

#### ZI_JIPV4_GoodsMovement (Updated: BWART = Z26)
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Goods Movements (Z26)'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_GoodsMovement
  as select from mseg as MS
  inner join mkpf as MK on MS.mblnr = MK.mblnr and MS.mjahr = MK.mjahr
{
  key MS.mblnr    as MaterialDocNumber,
  key MS.mjahr    as MaterialDocYear,
  key MS.zeession as MaterialDocItem,
      MS.matnr    as MaterialNumber,
      MS.werks    as Plant,
      MS.bwart    as MovementType,
      MS.rsnum    as ReservationNumber,
      MS.rspos    as ReservationItem,
      MS.aufnr    as WorkOrderNumber,
      MS.menge    as Quantity,
      MS.meins    as BaseUnit,
      MK.budat    as PostingDate
}
where MS.bwart = 'Z26'
```

#### ZI_JIPV4_EWM_ProductMap (Updated: /SCWM/BINMAT replaces /SAPAPO/MATKEY)
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Product MATID to MATNR via BINMAT'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_ProductMap
  as select from /scwm/binmat as BM
{
  key BM.matid    as ProductGuid,
      BM.matnr    as MaterialNumber
}
```

#### ZI_JIPV4_EWM_WarehouseTask (Updated: /SCWM/BINMAT CAST join)
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Warehouse Tasks Confirmed'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_WarehouseTask
  as select from /scwm/ordim_c as WT
  left outer join /scwm/binmat as BM
    on cast( WT.matid as abap.char(32) ) = cast( BM.matid as abap.char(32) )
{
  key WT.lgnum                              as WarehouseNumber,
  key WT.tanum                              as WarehouseTaskNo,
  key WT.tapos                              as TaskPosition,

      -- Material (resolved from GUID via /SCWM/BINMAT CAST join)
      WT.matid                              as ProductGuid,
      BM.matnr                              as MaterialNumber,

      -- Process Type (determines milestone)
      WT.procty                             as ProcessType,

      -- Storage
      WT.vltyp                              as SourceStorageType,
      WT.vlpla                              as SourceBin,
      WT.nltyp                              as DestStorageType,
      WT.nlpla                              as DestinationBin,

      -- Timestamps
      WT.created_at                         as CreatedAt,
      WT.confirmed_at                       as ConfirmedAt,

      -- Quantities
      WT.anfme                              as Quantity,
      WT.altme                              as UnitOfMeasure,

      -- Warehouse Order Reference
      WT.who                                as WarehouseOrder,
      WT.trart                              as ProcessCategory,

      -- JIP Milestone based on Process Type (PROCTY)
      case
        when WT.procty = 'S919' then 'TR_REQUEST'
        when WT.procty = 'S920' then 'TR_REQUEST'
        when WT.procty = 'S997' then 'RECEIVED'
        when WT.procty = 'S994' then 'NPB'
        else 'OTHER'
      end                                   as JipMilestone,

      -- JIP Milestone based on Destination Bin (NLPLA) — alternative
      case
        when WT.nlpla like '%PART%' then 'TR_REQUEST'
        when WT.nlpla like '%WPSR%' then 'RECEIVED'
        when WT.nlpla like '%PROD%' then 'NPB'
        else 'OTHER'
      end                                   as JipMilestoneByZone,

      -- Confirmation Status
      case
        when WT.confirmed_at is not initial then 'X'
        else ''
      end                                   as IsConfirmed
}
```

#### ZI_JIPV4_EWM_PlantMap (WM/EWM Detection via /SCWM/TMAPSTLOC)
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Plant-to-Warehouse Mapping'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_PlantMap
  as select from /scwm/tmapstloc as TM
{
  key TM.werks    as Plant,
  key TM.lgort    as StorageLocation,
      TM.lgnum    as WarehouseNumber
}
```

### 4.3 Composite View (Layer 2)

#### ZI_JIPV4_PartsComposite
```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Parts Composite - WM and EWM Combined'
@VDM.viewType: #COMPOSITE

define view entity ZI_JIPV4_PartsComposite
  as select from ZI_JIPV4_Reservation as Resv

  -- Work Order Header
  left outer join ZI_JIPV4_WorkOrder as WO
    on Resv.WorkOrderNumber = WO.WorkOrderNumber

  -- EWM Plant Detection (via /SCWM/TMAPSTLOC)
  left outer join ZI_JIPV4_EWM_PlantMap as PM
    on  Resv.Plant           = PM.Plant
    and Resv.StorageLocation = PM.StorageLocation

  -- Classic WM Transfer Orders
  left outer join ZI_JIPV4_TransferOrderWM as WM
    on  Resv.ReservationNumber = WM.RequirementNumber
    and Resv.MaterialNumber    = WM.MaterialNumber

  -- Goods Movement (GI Z26)
  left outer join ZI_JIPV4_GoodsMovement as GI
    on  Resv.ReservationNumber = GI.ReservationNumber
    and Resv.ReservationItem   = GI.ReservationItem

  -- EWM Warehouse Tasks (MATID resolved via /SCWM/BINMAT CAST join)
  left outer join ZI_JIPV4_EWM_WarehouseTask as EWM
    on Resv.MaterialNumber = EWM.MaterialNumber

{
  key Resv.ReservationNumber,
  key Resv.ReservationItem,

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
      WO.EquipmentSortField,
      WO.WOCreationDate,
      WO.WOReleaseDate,
      WO.SalesOrderNumber,
      WO.AppPDHDate,
      WO.AppSDHDate,
      WO.SoldToParty,
      WO.CustomerReference,

      -- Quantities
      Resv.RequirementQty,
      Resv.QtyAvailCheck,
      Resv.QtyWithdrawn,
      Resv.BaseUnit,

      -- WM/EWM Type Detection (via /SCWM/TMAPSTLOC)
      case
        when PM.WarehouseNumber is not null then 'EWM'
        else 'WM'
      end                                     as WmEwmType,

      -- Warehouse Number
      case
        when PM.WarehouseNumber is not null then PM.WarehouseNumber
        else WM.WarehouseNumber
      end                                     as WarehouseNumber,

      -- Current Milestone
      case
        when GI.PostingDate is not null        then 'GI'
        when EWM.JipMilestone = 'NPB'         then 'NPB'
        when EWM.JipMilestone = 'RECEIVED'    then 'RECEIVED'
        when EWM.JipMilestone = 'TR_REQUEST'  then 'TR_REQUEST'
        when WM.ConfirmationDate is not null  then 'WM_CONFIRMED'
        when WM.TransferOrderNo is not null   then 'TR_REQUEST'
        else 'PENDING'
      end                                     as CurrentMilestone,

      -- Milestone Dates
      WO.AppSDHDate                           as SDHApprovalDate,
      WO.WOReleaseDate                        as ReleaseDate,
      WM.TOCreationDate                       as WM_TRDate,
      WM.ConfirmationDate                     as WM_ReceivedDate,
      WM.TransferRequestNo                    as WM_TRNumber,
      EWM.ConfirmedAt                         as EWM_ConfirmedAt,
      EWM.WarehouseTaskNo                     as EWM_WTNumber,
      GI.PostingDate                          as GIDate,
      GI.MaterialDocNumber                    as GINumber,

      -- Aging: Release (SDH Approved → WO Released via AFKO-FTRMI)
      case
        when WO.AppSDHDate is not null and WO.WOReleaseDate is not null
        then dats_days_between(WO.AppSDHDate, WO.WOReleaseDate)
        else 0
      end                                     as AgingRelease,

      -- Aging Bucket
      case
        when dats_days_between(WO.AppSDHDate, $session.system_date) >= 70 then '70+'
        when dats_days_between(WO.AppSDHDate, $session.system_date) >= 60 then '60+'
        else 'OK'
      end                                     as AgingBucket,

      -- Period Month (YYYY-MM)
      concat(left(cast(WO.WOCreationDate as abap.char(8)), 4),
        concat('-', substring(cast(WO.WOCreationDate as abap.char(8)), 5, 2))
      )                                       as PeriodMonth
}
```

### 4.4 Consumption View (Layer 3)

#### ZC_JIPV4_AGING
```abap
@AbapCatalog.sqlViewName: 'ZVCJIPV4AGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Milestone Aging - OData V2 Consumption'
@VDM.viewType: #CONSUMPTION

@OData.publish: true

@UI.headerInfo: {
  typeName: 'JIP Part',
  typeNamePlural: 'JIP Parts',
  title: { value: 'WorkOrderNumber' },
  description: { value: 'MaterialNumber' }
}

@UI.selectionField: [
  { position: 10, element: 'Plant' },
  { position: 20, element: 'ActivityType' },
  { position: 30, element: 'AgingBucket' },
  { position: 40, element: 'WmEwmType' },
  { position: 50, element: 'WarehouseNumber' },
  { position: 60, element: 'CurrentMilestone' },
  { position: 70, element: 'ABCIndicator' }
]

define view ZC_JIPV4_AGING
  as select from ZI_JIPV4_PartsComposite
{
      @UI.lineItem: [{ position: 10 }]
  key ReservationNumber,
      @UI.lineItem: [{ position: 20 }]
  key ReservationItem,

      @UI.lineItem: [{ position: 30 }]
      WorkOrderNumber,
      @UI.lineItem: [{ position: 40 }]
      MaterialNumber,
      @UI.lineItem: [{ position: 45 }]
      ABCIndicator,

      @UI.lineItem: [{ position: 50 }]
      Plant,
      StorageLocation,
      OrderType,
      @UI.lineItem: [{ position: 60 }]
      ActivityType,

      @UI.lineItem: [{ position: 70 }]
      CurrentMilestone,
      @UI.lineItem: [{ position: 80, criticality: 'AgingCriticality' }]
      AgingBucket,

      WmEwmType,
      WarehouseNumber,

      SoldToParty,
      CustomerReference,
      EquipmentNumber,
      EquipmentSortField,

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

      -- Criticality for color coding
      case AgingBucket
        when '70+' then 1    -- Red (Negative)
        when '60+' then 2    -- Yellow (Critical)
        else 3               -- Green (Positive)
      end                     as AgingCriticality
}
```

> **OData V2 Note:** `@OData.publish: true` generates an OData V2 service via SADL. Activate in `/IWFND/MAINT_SERVICE`. Service name: `ZC_JIPV4_AGING_CDS`. No manual SEGW project needed.

---

## 5. Logic & Calculations

### 5.1 Aging Calculation (Milestone-to-Milestone)

Each aging is calculated as the difference between TWO consecutive milestones (not Today − Date). This measures how long parts stay at each stage.

#### WM (Classic) Aging

| # | Aging Column | From Milestone | To Milestone | WM Formula | SAP Fields |
|---|-------------|---------------|-------------|------------|------------|
| 1 | Aging Release | APP SDH Date | WO Release Date | FTRMI − SDH Date | AFKO-FTRMI minus ZTWOAPPR.APPROVED_DATE |
| 2 | Aging TR/TO | TR Date (TO Created) | Received Date (997 Confirmed) | QDATU(997) − ERDAT | LTAK-QDATU(BWLVS=997) minus LTAP-ERDAT |
| 3 | Aging Parts Received | TR Date (LTAP-ERDAT) | Received Date (LTAK-QDATU 997) | QDATU(997) − ERDAT | LTAK-QDATU(BWLVS=997) minus LTAP-ERDAT |
| 4 | Aging NPB | Received Date (QDATU 997) | NPB Date (QDATU 994) | QDATU(994) − QDATU(997) | LTAK-QDATU(BWLVS=994) minus LTAK-QDATU(BWLVS=997) |
| 5 | Aging GI | NPB Date (QDATU 994) | GI Date (MSEG-BUDAT Z26) | BUDAT(Z26) − QDATU(994) | MSEG-BUDAT(BWART=Z26) minus LTAK-QDATU(BWLVS=994) |

**WM Aging Flow:**
```
SDH Approved → WO Released(FTRMI) → TO Created(LTAP-ERDAT) → 997 Confirmed(LTAK-QDATU) → 994 Confirmed(LTAK-QDATU) → GI Posted(MSEG-BUDAT Z26)
|←─ Aging Release ──→|               |←──── Aging TR/TO ────→|   |←──── Aging NPB ─────→|   |←── Aging GI ──→|
                                      |←─ Aging Received ────→|
```

#### EWM (Zone-Based) Aging

| # | Aging Column | From Zone | To Zone | EWM Formula | PROCTY | NLPLA |
|---|-------------|-----------|---------|-------------|--------|-------|
| 1 | Aging Release | APP SDH Date | WO Release (FTRMI) | Same as WM (not zone-based) | N/A | N/A |
| 2 | Aging TR/TO | PART-ZONE (S919 confirmed) | WPSR-ZONE (S997 confirmed) | CONFIRMED_AT(WPSR) − CONFIRMED_AT(PART) | S919 → S997 | PART → WPSR |
| 3 | Aging Parts Received | PART-ZONE (S919 confirmed) | WPSR-ZONE (S997 confirmed) | CONFIRMED_AT(WPSR) − CONFIRMED_AT(PART) | S919 → S997 | PART → WPSR |
| 4 | Aging NPB | WPSR-ZONE (S997 confirmed) | PROD-ZONE (S994 confirmed) | CONFIRMED_AT(PROD) − CONFIRMED_AT(WPSR) | S997 → S994 | WPSR → PROD |
| 5 | Aging GI | PROD-ZONE (S994 confirmed) | GI Posted (MSEG-BUDAT Z26) | BUDAT(Z26) − CONFIRMED_AT(PROD) | S994 → Z26 | PROD → GI |

**EWM Aging Flow:**
```
WO Released → PROCTY S919 (PART-ZONE) → PROCTY S997 (WPSR-ZONE) → PROCTY S994 (PROD-ZONE) → GI (MSEG Mvt Z26)
|←─ Release ─→|←──── Aging TR/TO ────→|←──── Aging Received ──→|←──── Aging NPB ─────→|←── Aging GI ──→|
```

### 5.2 WM vs EWM Aging Formula Comparison

| Aging | WM From | WM To | WM Formula | EWM From | EWM To | EWM Formula | Difference |
|-------|---------|-------|------------|----------|--------|-------------|------------|
| Release | SDH Date | FTRMI | FTRMI − SDH | SDH Date | FTRMI | FTRMI − SDH | Identical |
| TR/TO | LTAP-ERDAT | LTAK-QDATU(997) | QDATU(997) − ERDAT | CONFIRMED_AT(PART) | CONFIRMED_AT(WPSR) | WPSR − PART | WM: LTAK/LTAP; EWM: zone timestamps |
| Received | LTAP-ERDAT | LTAK-QDATU(997) | QDATU(997) − ERDAT | CONFIRMED_AT(PART) | CONFIRMED_AT(WPSR) | WPSR − PART | Same as TR/TO |
| NPB | LTAK-QDATU(997) | LTAK-QDATU(994) | QDATU(994) − QDATU(997) | CONFIRMED_AT(WPSR) | CONFIRMED_AT(PROD) | PROD − WPSR | WM: BWLVS; EWM: zone |
| GI | LTAK-QDATU(994) | MSEG-BUDAT(Z26) | BUDAT − QDATU(994) | CONFIRMED_AT(PROD) | MSEG-BUDAT(Z26) | BUDAT − PROD | GI always MSEG; start differs |

### 5.3 Aging Buckets

| Bucket | Condition | Color | UI Criticality |
|--------|-----------|-------|---------------|
| OK | Current aging < 60 days | Green | 3 (Positive) |
| 60+ | Current aging ≥ 60 and < 70 days | Yellow | 2 (Critical) |
| 70+ | Current aging ≥ 70 days | Red | 1 (Negative) |

### 5.4 EWM Process Types & Zone Mapping

| PROCTY | NLPLA Zone | JIP Milestone | CONFIRMED_AT Usage | Description |
|--------|-----------|---------------|-------------------|-------------|
| S919 | PART-ZONE | TR_REQUEST | Yes → TR Date | Parts picked and delivered to PART-ZONE staging |
| S920 | PART-ZONE | TR_REQUEST | Yes → TR Date (alt) | Transfer request alternative |
| S997 | WPSR-ZONE | RECEIVED | Yes → Received Date | Parts moved to WPSR-ZONE (Warehouse Parts Staging/Received) |
| S994 | PROD-ZONE | NPB | Yes → NPB Date | Parts sent to PROD-ZONE (Production Supply Area) |
| N/A | N/A (MSEG) | GI | MSEG-BUDAT | Final goods issue (Mvt Z26) — same for WM and EWM |

### 5.5 Classic WM Movement Types (BWLVS)

| BWLVS | Equivalent | JIP Milestone | Source |
|-------|-----------|---------------|--------|
| 919 | S919 (EWM) | TR_REQUEST | LTAK-BWLVS |
| 920 | S920 (EWM) | TR_REQUEST (alt) | LTAK-BWLVS |
| 997 | S997 (EWM) | RECEIVED | LTAK-BWLVS |
| 994 | S994 (EWM) | NPB | LTAK-BWLVS |

---

## 6. UI Design

### 6.1 Dashboard Layout

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║  JIP Milestone Aging Dashboard V4                                              ║
║  FILTER BAR: [Plant ▼] [Activity Type ▼] [Aging Bucket ▼] [WM/EWM ▼] [LGNUM] ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  ROW 1 — Overview (3 Cards)                                                    ║
║  ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐    ║
║  │ Total JIP per Plant  │ │ Historical JIP ALL    │ │ Historical Aging     │    ║
║  │ (Horizontal Bar)     │ │ Plants (Stacked Col)  │ │ per Plant (Stack Col)│    ║
║  │ X: Plant             │ │ X: Month, Y: Count    │ │ X: Month, Stacked    │    ║
║  │ Y: Count             │ │ Stack: Aging Bucket   │ │ by Aging Bucket      │    ║
║  └──────────────────────┘ └──────────────────────┘ └──────────────────────┘    ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  ROW 2 — Detail (2 Cards + 1 Table)                                           ║
║  ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐    ║
║  │ Activity Breakdown   │ │ Monthly Trend         │ │ Avg Aging by         │    ║
║  │ (Horizontal Bar)     │ │ (Stacked Column)      │ │ Plant+Activity       │    ║
║  │ X: Activity Type     │ │ X: Month, Stack by    │ │ (Combination)        │    ║
║  │ Y: Count             │ │ Activity Type         │ │ Bar + Line           │    ║
║  └──────────────────────┘ └──────────────────────┘ └──────────────────────┘    ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  ROW 3 — Tables                                                                ║
║  ┌─────────────────────────────────────┐ ┌────────────────────────────────────┐ ║
║  │ Pivot: Plant × Month Summary        │ │ Pivot: Plant × Activity × Month   │ ║
║  └─────────────────────────────────────┘ └────────────────────────────────────┘ ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

### 6.2 Filter Parameters

| Filter | CDS Field | Type | Values |
|--------|-----------|------|--------|
| Plant | Plant | Dropdown (multi-select) | All Plants (JKT, MDN, BLP, BDI, etc.) |
| Activity Type | ActivityType (ILART) | Dropdown (multi-select) | **INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN** |
| Aging Bucket | AgingBucket | Dropdown | OK, 60+, 70+ |
| WM/EWM | WmEwmType | Toggle | WM / EWM / All |
| Warehouse Number | WarehouseNumber | Dropdown | e.g., WJKT |
| Current Milestone | CurrentMilestone | Dropdown | PENDING, TR_REQUEST, RECEIVED, NPB, GI |
| ABC Indicator | ABCIndicator | Dropdown | A, B, C |

---

## 7. EWM Field Reference

| Field | Technical Name | Table | Data Type | Example | Description |
|-------|---------------|-------|-----------|---------|-------------|
| Warehouse Number | LGNUM | /SCWM/ORDIM_C | CHAR(4) | WJKT | EWM warehouse identifier |
| Product (GUID) | MATID | /SCWM/ORDIM_C | RAW(16) | (binary GUID) | Must resolve via /SCWM/BINMAT |
| Material Number | MATNR | /SCWM/BINMAT | CHAR(40) | 01010-50612 | Converted from MATID via BINMAT join |
| Warehouse Task No | TANUM | /SCWM/ORDIM_C | CHAR(20) | WT-000001234 | Unique warehouse task ID |
| Task Position | TAPOS | /SCWM/ORDIM_C | NUMC(4) | 0001 | Position (pick-up=0001, drop=0002) |
| Process Type | PROCTY | /SCWM/ORDIM_C | CHAR(4) | S919 | S919=TR, S997=Received, S994=NPB |
| Source Storage Type | VLTYP | /SCWM/ORDIM_C | CHAR(4) | 0100 | Storage type picked FROM |
| Dest Storage Type | NLTYP | /SCWM/ORDIM_C | CHAR(4) | 0200 | Storage type moved TO |
| Destination Bin | NLPLA | /SCWM/ORDIM_C | CHAR(18) | PART-ZONE | Determines JIP milestone |
| Confirmed At | CONFIRMED_AT | /SCWM/ORDIM_C | TIMESTAMP | 12.12.2025 09:40:34 | Used for aging calculation |
| Created At | CREATED_AT | /SCWM/ORDIM_C | TIMESTAMP | 12.12.2025 09:35:00 | When task was created |
| Quantity | ANFME | /SCWM/ORDIM_C | QUAN | 5.000 | Requested/confirmed quantity |
| Unit of Measure | ALTME | /SCWM/ORDIM_C | UNIT(3) | EA | Alternative UoM |
| Process Category | TRART | /SCWM/ORDIM_C | CHAR(1) | 1 | 1=Internal, 2=Putaway, 3=Removal |
| Warehouse Order | WHO | /SCWM/ORDIM_C | CHAR(20) | WHO-00001 | Warehouse order reference |

---

## 8. Performance & Volume

| Metric | Value |
|--------|-------|
| Expected Data Volume | 10k – 100k reservation items |
| Pagination | Not required |
| Real-time | Yes (pure CDS, no batch job) |
| OData Version | OData V2 (SADL auto-publish) |
| Performance Hint | Use `@ObjectModel.usageType.dataClass: #MIXED` if needed |
| Index Recommendation | Secondary indexes on RESB(AUFNR), MSEG(RSNUM+RSPOS), LTAP(ANFNR) |

---

## 9. Development Checklist

- [x] Basic Tables only: AUFK, AFKO, AFIH, ILOA, JEST, RESB, MSEG, LTAK, LTAP, LTBK, /SCWM/ORDIM_C, /SCWM/BINMAT, /SCWM/TMAPSTLOC, ZTWOAPPR, VBAK, VBKD
- [x] **EWM MATID → MATNR via `/SCWM/BINMAT` join with `CAST(matid as abap.char(32))` — no FM needed**
- [x] **WM/EWM detection via `/SCWM/TMAPSTLOC` — if LGNUM exists for plant+sloc → EWM**
- [x] **Release Date from `AFKO-FTRMI`** (not IDAT1)
- [x] **ABC Indicator from `ILOA-ABCKZ`** via AFIH-ILOAN → ILOA join
- [x] **GI Movement Type: BWART = 'Z26'** (custom, not standard 261)
- [x] **Activity Types (ILART): INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN**
- [x] **EWM Quantity fields: ANFME / ALTME** (not VSOLM)
- [x] No ABAP Report, no Z-Table, no Background Job (Method 3 rejected)
- [x] `/SCWM/BINMAT` replaces `/SAPAPO/MATKEY` for MATID resolution
- [x] `VIAUFKS`/`CAUFV` views replaced with basic table joins (AUFK+AFKO+AFIH)
- [x] **OData V2 via Auto-Publish (`@OData.publish: true` via SADL)**
- [x] VDM 3-Layer architecture (Basic → Composite → Consumption)
- [x] WM/EWM branching via CASE statements in CDS
- [x] Aging calculated real-time via `dats_days_between()`
- [x] Aging buckets: OK (<60), 60+, 70+
- [x] UI Criticality mapping (1=Red, 2=Yellow, 3=Green)
- [x] All aging is milestone-to-milestone (not single start date)
- [x] EWM milestones: S919/S920=TR, S997=RECEIVED, S994=NPB
- [x] All view names follow V4 convention: `ZI_JIPV4_xxx` / `ZC_JIPV4_AGING`
- [x] Crosschecked with Blueprint V3 Excel (Fix_Blueprint_Rancangan_Dashboard_JIP_V3.xlsx)

---

## 10. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01 | Initial PRD with pure CDS approach |
| 1.2 | 2026-02 | Updated dashboard design, added FM approach for MATID |
| 2.0 | 2026-03 | Changed to Method 3 (ABAP Report + Z-Table + CDS) |
| 3.0 | 2026-03 | Changed to Method 4 (Pure CDS with /SAPAPO/MATKEY join) |
| **4.0** | **2026-03** | **Crosschecked with Blueprint V3 Excel. Major updates: (1) /SCWM/BINMAT replaces /SAPAPO/MATKEY for MATID→MATNR. (2) GI movement type Z26 (not 261). (3) Release Date from AFKO-FTRMI. (4) ABC Indicator via ILOA-ABCKZ. (5) Activity Types expanded: INS, LOG, MID, NME, OVH, PAP, PPM, SER, TRS, UIW, USN. (6) EWM qty fields ANFME/ALTME. (7) V4 naming. (8) /SCWM/TMAPSTLOC for WM/EWM detection. (9) Dashboard renamed "JIP Milestone Aging Dashboard V4".** |
