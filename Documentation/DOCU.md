# Step-by-Step Implementation Guide

## JIP Milestone Aging Dashboard V4 — CDS Views (Pure CDS Method 4)

**Project:** JIP Milestone Aging Dashboard V4  
**Architecture:** Method 4 — Pure CDS (VDM 3-Layer) — OData V2  
**Developer:** Viandra  
**Created:** March 2026

---

## Table of Contents

- [Step-by-Step Implementation Guide](#step-by-step-implementation-guide)
  - [JIP Milestone Aging Dashboard V4 — CDS Views (Pure CDS Method 4)](#jip-milestone-aging-dashboard-v4--cds-views-pure-cds-method-4)
  - [Table of Contents](#table-of-contents)
  - [1. Prerequisites](#1-prerequisites)
  - [Step 1 — Create Development Package (ZJIPV4)](#step-1--create-development-package-zjipv4)
    - [1.1 Open Eclipse ADT](#11-open-eclipse-adt)
    - [1.2 Create Package](#12-create-package)
    - [1.3 Verify Package](#13-verify-package)
  - [Step 2 — Create Basic Interface View: ZI\_JIPV4\_Reservation](#step-2--create-basic-interface-view-zi_jipv4_reservation)
    - [2.1 Create the CDS View](#21-create-the-cds-view)
    - [2.2 Replace with the following code](#22-replace-with-the-following-code)
    - [2.3 Activate](#23-activate)
    - [2.4 Key Points](#24-key-points)
  - [Step 3 — Create Basic Interface View: ZI\_JIPV4\_WorkOrder](#step-3--create-basic-interface-view-zi_jipv4_workorder)
    - [3.1 Create the CDS View](#31-create-the-cds-view)
    - [3.2 Replace with the following code](#32-replace-with-the-following-code)
    - [3.3 Activate](#33-activate)
    - [3.4 Key Points](#34-key-points)
  - [Step 4 — Create Basic Interface View: ZI\_JIPV4\_TransferOrderWM](#step-4--create-basic-interface-view-zi_jipv4_transferorderwm)
    - [4.1 Create the CDS View](#41-create-the-cds-view)
    - [4.2 Replace with the following code](#42-replace-with-the-following-code)
    - [4.3 Activate](#43-activate)
    - [4.4 Key Points](#44-key-points)
  - [Step 5 — Create Basic Interface View: ZI\_JIPV4\_GoodsMovement](#step-5--create-basic-interface-view-zi_jipv4_goodsmovement)
    - [5.1 Create the CDS View](#51-create-the-cds-view)
    - [5.2 Replace with the following code](#52-replace-with-the-following-code)
    - [5.3 Activate](#53-activate)
    - [5.4 Key Points](#54-key-points)
  - [Step 6 — Create Basic Interface View: ZI\_JIPV4\_EWM\_ProductMap](#step-6--create-basic-interface-view-zi_jipv4_ewm_productmap)
    - [6.1 Create the CDS View](#61-create-the-cds-view)
    - [6.2 Replace with the following code](#62-replace-with-the-following-code)
    - [6.3 Activate](#63-activate)
    - [6.4 Key Points](#64-key-points)
  - [Step 7 — Create Basic Interface View: ZI\_JIPV4\_EWM\_WarehouseTask](#step-7--create-basic-interface-view-zi_jipv4_ewm_warehousetask)
    - [7.1 Create the CDS View](#71-create-the-cds-view)
    - [7.2 Replace with the following code](#72-replace-with-the-following-code)
    - [7.3 Activate](#73-activate)
    - [7.4 Key Points](#74-key-points)
  - [Step 8 — Create Basic Interface View: ZI\_JIPV4\_EWM\_PlantMap](#step-8--create-basic-interface-view-zi_jipv4_ewm_plantmap)
    - [8.1 Create the CDS View](#81-create-the-cds-view)
    - [8.2 Replace with the following code](#82-replace-with-the-following-code)
    - [8.3 Activate](#83-activate)
    - [8.4 Key Points](#84-key-points)
  - [Step 9 — Create Composite Interface View: ZI\_JIPV4\_PartsComposite](#step-9--create-composite-interface-view-zi_jipv4_partscomposite)
    - [9.1 Create the CDS View](#91-create-the-cds-view)
    - [9.2 Replace with the following code](#92-replace-with-the-following-code)
    - [9.3 Activate](#93-activate)
    - [9.4 Key Points](#94-key-points)
  - [Step 10 — Create Consumption View: ZC\_JIPV4\_AGING](#step-10--create-consumption-view-zc_jipv4_aging)
    - [10.1 Create the CDS View](#101-create-the-cds-view)
    - [10.2 Replace with the following code](#102-replace-with-the-following-code)
    - [10.3 Activate](#103-activate)
    - [10.4 Key Points](#104-key-points)
    - [10.5 Why `define view` instead of `define view entity`?](#105-why-define-view-instead-of-define-view-entity)
  - [Step 11 — Create Metadata Extension: ZE\_JIPV4\_AGING](#step-11--create-metadata-extension-ze_jipv4_aging)
    - [11.1 Create the Metadata Extension](#111-create-the-metadata-extension)
    - [11.2 Replace with the following code](#112-replace-with-the-following-code)
    - [11.3 Activate](#113-activate)
    - [11.4 Key Points](#114-key-points)
    - [11.5 Benefits of MDE Separation](#115-benefits-of-mde-separation)
  - [Step 12 — Activate OData V2 Service](#step-12--activate-odata-v2-service)
    - [12.1 Register Service in SAP Gateway](#121-register-service-in-sap-gateway)
    - [12.2 Clear Metadata Cache](#122-clear-metadata-cache)
    - [12.3 Test OData Service](#123-test-odata-service)
  - [Step 13 — Test and Validate](#step-13--test-and-validate)
    - [13.1 Data Preview in Eclipse ADT](#131-data-preview-in-eclipse-adt)
    - [13.2 Validate MDE Annotations](#132-validate-mde-annotations)
    - [13.3 Fiori Launchpad Test](#133-fiori-launchpad-test)
  - [Architecture Diagram](#architecture-diagram)
  - [Activation Order](#activation-order)
  - [Troubleshooting](#troubleshooting)
    - [Common Errors](#common-errors)
    - [Useful Transactions](#useful-transactions)
  - [Summary Checklist](#summary-checklist)

---

## 1. Prerequisites

Before starting, ensure the following:

| # | Prerequisite | Details |
|---|-------------|---------|
| 1 | **Eclipse ADT** | Eclipse with ABAP Development Tools (ADT) plugin installed |
| 2 | **SAP System Access** | Developer authorization key for the target SAP system |
| 3 | **Transport Request** | A Workbench transport request created for the project |
| 4 | **Source Tables Exist** | Confirm all source tables exist: `AUFK`, `AFKO`, `AFIH`, `ILOA`, `RESB`, `MATDOC`, `LTAP`, `LTAK`, `LTBK`, `/SCWM/ORDIM_C`, `/SCWM/BINMAT`, `/SCWM/TMAPSTLOC`, `ZTWOAPPR`, `VBAK` |
| 5 | **Custom Table** | `ZTWOAPPR` (WO Approval table) must be created beforehand with fields: `AUFNR`, `LVL2DT`, `LVL3DT` |
| 6 | **EWM License** | EWM component active (for `/SCWM/*` tables) |

---

## Step 1 — Create Development Package (ZJIPV4)

### 1.1 Open Eclipse ADT

1. Launch **Eclipse IDE**
2. Open the **ABAP Perspective** (`Window` > `Perspective` > `Open Perspective` > `ABAP`)
3. Connect to your SAP system in the **Project Explorer**

### 1.2 Create Package

1. In **Project Explorer**, right-click on your SAP system connection
2. Select **New** > **ABAP Package**
3. Fill in the details:

| Field | Value |
|-------|-------|
| **Package** | `ZJIPV4` |
| **Description** | `JIP Milestone Aging Dashboard V4 - Pure CDS` |
| **Software Component** | `HOME` (or your designated component) |
| **Application Component** | `PM` (Plant Maintenance) |
| **Transport Layer** | Select your transport layer |
| **Super Package** | (leave blank or select parent package) |

4. Click **Next**
5. Select or create a **Transport Request**
6. Click **Finish**

### 1.3 Verify Package

- The package `ZJIPV4` should now appear in the Project Explorer
- All subsequent objects will be created inside this package

---

## Step 2 — Create Basic Interface View: ZI_JIPV4_Reservation

**Layer:** Basic (Layer 1)  
**Source Table:** `RESB`  
**Purpose:** Reservation line items — the primary driving entity for all JIP parts

### 2.1 Create the CDS View

1. Right-click on package `ZJIPV4`
2. Select **New** > **Other ABAP Repository Object**
3. Expand **Core Data Services** > select **Data Definition**
4. Click **Next**
5. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_Reservation` |
| **Description** | `JIP V4 Reservation Items` |
| **Referenced Object** | (leave blank) |

6. Click **Next** > Select your **Transport Request** > Click **Next**
7. Select template: **Define View Entity** > Click **Finish**

### 2.2 Replace with the following code

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
  key rsart    as ReservationCategory,
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

### 2.3 Activate

- Press **Ctrl+F3** to activate
- Verify no errors in the **Problems** view

### 2.4 Key Points

- **`xloek = ''`** — Excludes deleted reservation items
- **`aufnr <> ''`** — Only reservation items linked to a Work Order
- **Key fields:** `ReservationNumber` + `ReservationItem` + `ReservationCategory` (composite key from RESB)

---

## Step 3 — Create Basic Interface View: ZI_JIPV4_WorkOrder

**Layer:** Basic (Layer 1)  
**Source Tables:** `AUFK` + `AFKO` + `AFIH` + `ILOA` + `ZTWOAPPR` + `VBAK`  
**Purpose:** Work Order header with Activity Type, ABC Indicator, Release Date, Approval dates, and Customer info

### 3.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_WorkOrder` |
| **Description** | `JIP V4 Work Order Header` |

4. Select template: **Define View Entity** > **Finish**

### 3.2 Replace with the following code

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

      -- ABC Indicator (via AFIH-ILOAN > ILOA)
      IL.abckz    as ABCIndicator,

      -- Release Date from AFKO-FTRMI
      AO.ftrmi    as WOReleaseDate,

      -- Approval Dates
      -- ZA.lvl2dt   as AppPDHDate,
      ZA.appr_by_lvl3   as AppSDHDate,

      -- Customer Info
      VB.kunnr    as SoldToParty
}
```

### 3.3 Activate

- Press **Ctrl+F3** to activate

### 3.4 Key Points

- **Join chain:** `AUFK` > `AFKO` (Release Date) > `AFIH` (Activity Type) > `ILOA` (ABC Indicator)
- **`AFKO.FTRMI`** — Actual release date (not IDAT1)
- **`ILOA.ABCKZ`** — ABC Indicator accessed via `AFIH.ILOAN` > `ILOA.ILOAN` join
- **`ZTWOAPPR`** — Custom approval table (LVL2 = PDH, LVL3 = SDH)
- **`VBAK`** — Customer info via Sales Order (`AUFK.KDAUF`)

---

## Step 4 — Create Basic Interface View: ZI_JIPV4_TransferOrderWM

**Layer:** Basic (Layer 1)  
**Source Tables:** `LTAP` + `LTAK`  
**Purpose:** Classic WM Transfer Orders for non-EWM plants

### 4.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_TransferOrderWM` |
| **Description** | `JIP V4 Classic WM Transfer Orders` |

4. Select template: **Define View Entity** > **Finish**

### 4.2 Replace with the following code

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Classic WM Transfer Orders'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_TransferOrderWM
  as select from ltap as LP
  inner join ltak as LK on LP.lgnum = LK.lgnum and LP.tanum = LK.tanum
{
  key LP.lgnum    as WarehouseNumber,
  key LP.tanum    as TransferOrderNo,
  key LP.tapos    as TransferOrderItem,
      LP.matnr    as MaterialNumber,
      LP.werks    as Plant,
      LP.tbpos    as RequirementItem,
      LK.bdatu    as TOCreationDate,
      LK.bwlvs    as MovementType,
      LP.qdatu    as ConfirmationDate
}
```

### 4.3 Activate

- Press **Ctrl+F3** to activate

### 4.4 Key Points

- **`LTAP`** — Transfer Order Item (material, `QDATU` confirmation date, `TBPOS` TR item)
- **`LTAK`** — Transfer Order Header (movement type `BWLVS`, creation date `BDATU`)
- **No direct WO link:** LTAK/LTAP do not link directly to work orders; use reservation (`RSNUM`) for WO correlation
- **WM Movement Types:** `919`=TR, `920`=TR alt, `997`=Received, `994`=NPB

---

## Step 5 — Create Basic Interface View: ZI_JIPV4_GoodsMovement

**Layer:** Basic (Layer 1)  
**Source Table:** `MATDOC` (native S/4HANA)  
**Purpose:** Goods Issue postings filtered to custom movement type Z26

### 5.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_GoodsMovement` |
| **Description** | `JIP V4 Goods Movements (Z26)` |

4. Select template: **Define View Entity** > **Finish**

### 5.2 Replace with the following code

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Goods Movements (Z26)'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_GoodsMovement
  as select from matdoc as MD
{
  key MD.mblnr    as MaterialDocNumber,
  key MD.mjahr    as MaterialDocYear,
      MD.matnr    as MaterialNumber,
      MD.werks    as Plant,
      MD.bwart    as MovementType,
      MD.aufnr    as WorkOrderNumber,
      MD.rsnum    as ReservationNumber,
      MD.rspos    as ReservationItem,
      MD.menge    as Quantity,
      MD.meins    as BaseUnit,
      MD.budat    as PostingDate
}
where MD.bwart = 'Z26'
  and MD.cancelled = ''
```

### 5.3 Activate

- Press **Ctrl+F3** to activate

### 5.4 Key Points

- **`BWART = 'Z26'`** — Custom movement type for Goods Issue (not standard 261)
- **`MATDOC`** — Native S/4HANA table (not MSEG compatibility view) — returns actual data
- **`CANCELLED = ''`** — Excludes reversed/cancelled documents
- **`BUDAT`** — Posting date from MATDOC (no MKPF join needed)
- **`RSNUM` + `RSPOS`** — Links back to reservation for composite join

---

## Step 6 — Create Basic Interface View: ZI_JIPV4_EWM_ProductMap

**Layer:** Basic (Layer 1)  
**Source Table:** `/SCWM/BINMAT`  
**Purpose:** MATID (RAW16 GUID) to MATNR (material number) mapping for EWM

### 6.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_EWM_ProductMap` |
| **Description** | `JIP V4 EWM Product MATID to MATNR via BINMAT` |

4. Select template: **Define View Entity** > **Finish**

### 6.2 Replace with the following code

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EWM Product MATID to MATNR Mapping'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_ProductMap
  as select from /scwm/binmat as BM
{
  key BM.matid    as ProductGuid,
      BM.matnr    as MaterialNumber
}
```

### 6.3 Activate

- Press **Ctrl+F3** to activate

### 6.4 Key Points

- **`/SCWM/BINMAT`** replaces `/SAPAPO/MATKEY` for MATID resolution
- This view is a standalone lookup; the actual CAST join happens in `ZI_JIPV4_EWM_WarehouseTask`
- **`MATID`** is RAW(16) — a binary GUID for EWM products

---

## Step 7 — Create Basic Interface View: ZI_JIPV4_EWM_WarehouseTask

**Layer:** Basic (Layer 1)  
**Source Table:** `/SCWM/ORDIM_C`  
**Purpose:** EWM confirmed warehouse tasks with MATID (raw GUID), milestone mapping by PROCTY and NLPLA. Material resolution (MATID→MATNR) happens in composite view via BINMAT bridge.

### 7.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_EWM_WarehouseTask` |
| **Description** | `JIP V4 EWM Warehouse Tasks Confirmed` |

4. Select template: **Define View Entity** > **Finish**

### 7.2 Replace with the following code

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Warehouse Tasks Confirmed'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_WarehouseTask
  as select from /scwm/ordim_c as WT
{
  key WT.lgnum                              as WarehouseNumber,
  key WT.tanum                              as WarehouseTaskNo,
  key WT.tapos                              as TaskPosition,

      -- Material (MATID - will be resolved in composite view)
      WT.matid                              as ProductGuid,

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

      -- Quantities (from /SCWM/ORDIM_C, not /SCWM/BINMAT)
      WT.nista                              as Quantity,
      WT.meins                              as UnitOfMeasure,

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

### 7.3 Activate

- Press **Ctrl+F3** to activate

### 7.4 Key Points

- **No CAST join needed:** `/SCWM/ORDIM_C` uses MATID directly — material resolution happens in composite view via BINMAT bridge
- **RESV→BINMAT→ORDIM_C chain:** 
  - RESV.MaterialNumber = BINMAT.MaterialNumber (CHAR=CHAR)
  - BINMAT.ProductGuid = ORDIM_C.ProductGuid (RAW16=RAW16)
- **PROCTY mapping:** `S919`/`S920` = TR_REQUEST, `S997` = RECEIVED, `S994` = NPB
- **NLPLA zone mapping (alternative):** `PART` zone = TR, `WPSR` zone = Received, `PROD` zone = NPB
- **`CONFIRMED_AT`** — Timestamp used for EWM aging calculations
- **`NISTA`** — Actual quantity field in `/SCWM/ORDIM_C`

---

## Step 8 — Create Basic Interface View: ZI_JIPV4_EWM_PlantMap

**Layer:** Basic (Layer 1)  
**Source Table:** `/SCWM/TMAPSTLOC`  
**Purpose:** Maps Plant to EWM Warehouse Number — used to detect if a plant is WM or EWM managed

### 8.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_EWM_PlantMap` |
| **Description** | `JIP V4 EWM Plant-to-Warehouse Mapping` |

4. Select template: **Define View Entity** > **Finish**

### 8.2 Replace with the following code

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Plant-to-Warehouse Mapping'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_PlantMap
  as select from /scwm/tmapstloc as TM
{
  key TM.plant    as Plant,
      TM.lgnum    as WarehouseNumber
}
```
### 8.3 Activate

- Press **Ctrl+F3** to activate

### 8.4 Key Points

- **WM/EWM detection logic:** If a record exists in `/SCWM/TMAPSTLOC` for a given `PLANT` the plant is **EWM**; otherwise it is **WM**
- This is used in the composite view via `left outer join` — if `WarehouseNumber IS NOT NULL` then EWM
- **Field mapping:** `TM.plant` → `Plant`, `TM.lgnum` → `WarehouseNumber`

---

## Step 9 — Create Composite Interface View: ZI_JIPV4_PartsComposite

**Layer:** Composite (Layer 2)  
**Source Views:** All 7 Basic Views  
**Purpose:** Joins all basic views together, implements WM/EWM branching, milestone determination, aging calculation, aging buckets, and period month

### 9.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZI_JIPV4_PartsComposite` |
| **Description** | `Parts Composite - WM and EWM` |

4. Select template: **Define View Entity** > **Finish**

### 9.2 Replace with the following code

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
    on Resv.Plant = PM.Plant

  -- Classic WM Transfer Orders
  left outer join ZI_JIPV4_TransferOrderWM as WM
    on  Resv.Plant          = WM.Plant
    and Resv.MaterialNumber = WM.MaterialNumber

  -- Goods Movement (GI Z26)
  left outer join ZI_JIPV4_GoodsMovement as GI
    on  Resv.ReservationNumber = GI.ReservationNumber
    and Resv.ReservationItem   = GI.ReservationItem

  -- EWM Product Map (bridge for material resolution)
  left outer join ZI_JIPV4_EWM_ProductMap as BM
    on Resv.MaterialNumber = BM.MaterialNumber

  -- EWM Warehouse Tasks (linked via MATID from BINMAT)
  left outer join ZI_JIPV4_EWM_WarehouseTask as EWM
    on BM.ProductGuid = EWM.ProductGuid

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
      WO.WOCreationDate,
      WO.WOReleaseDate,
      WO.SalesOrderNumber,
      WO.AppSDHDate,
      WO.SoldToParty,

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
      WM.TransferOrderNo                     as WM_TRNumber,
      EWM.ConfirmedAt                         as EWM_ConfirmedAt,
      EWM.WarehouseTaskNo                     as EWM_WTNumber,
      GI.PostingDate                          as GIDate,
      GI.MaterialDocNumber                    as GINumber,

      -- Aging: Release (SDH Approved > WO Released via AFKO-FTRMI)
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

### 9.3 Activate

- Press **Ctrl+F3** to activate
- **Important:** All 7 Basic Views (Steps 2-8) must be activated BEFORE activating this view

### 9.4 Key Points

- **VDM Type:** `#COMPOSITE` — this is the central business logic layer
- **WM/EWM Detection:** `PM.WarehouseNumber IS NOT NULL` = EWM; else = WM
- **Milestone Priority:** GI > NPB > RECEIVED > TR_REQUEST > WM_CONFIRMED > TR_REQUEST > PENDING
- **`dats_days_between()`** — Built-in CDS function for date difference in days
- **`$session.system_date`** — Current system date for real-time aging bucket calculation
- **Aging Buckets:** OK (less than 60 days), 60+ (60-69 days), 70+ (70+ days)

---

## Step 10 — Create Consumption View: ZC_JIPV4_AGING

**Layer:** Consumption (Layer 3)  
**Source View:** `ZI_JIPV4_PartsComposite`  
**Purpose:** OData V2 service endpoint via SADL auto-publish — clean view with NO `@UI` annotations (handled by MDE)

### 10.1 Create the CDS View

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. **Core Data Services** > **Data Definition** > **Next**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZC_JIPV4_AGING` |
| **Description** | `JIP V4 Milestone Aging - OData V2 Consumption` |

4. Select template: **Define View** (NOT View Entity — needed for `@OData.publish`) > **Finish**

### 10.2 Replace with the following code

```abap
@AbapCatalog.sqlViewName: 'ZVCJIPV4AGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Milestone Aging - OData V2 Consumption'
@VDM.viewType: #CONSUMPTION

@OData.publish: true

@Metadata.allowExtensions: true

define view ZC_JIPV4_AGING
  as select from ZI_JIPV4_PartsComposite
{
  key ReservationNumber,
  key ReservationItem,
  key ReservationCategory,

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

### 10.3 Activate

- Press **Ctrl+F3** to activate
- **Important:** `ZI_JIPV4_PartsComposite` (Step 9) must be activated BEFORE this view

### 10.4 Key Points

- **`@OData.publish: true`** — Auto-generates an OData V2 service via SADL. Service name: `ZC_JIPV4_AGING_CDS`
- **`@Metadata.allowExtensions: true`** — **CRITICAL** — Enables the Metadata Extension (Step 11) to attach UI annotations. Without this, the MDE is ignored.
- **`@AbapCatalog.sqlViewName: 'ZVCJIPV4AGN'`** — Required for `define view` (not `define view entity`). Max 16 characters.
- **`AgingCriticality`** — Kept in the CDS view (not in MDE) because MDE annotations reference it for criticality coloring
- **No `@UI` annotations** — All UI presentation is delegated to the Metadata Extension

### 10.5 Why `define view` instead of `define view entity`?

`@OData.publish: true` (SADL auto-publish for OData V2) requires the classic `define view` syntax with an `sqlViewName`. The newer `define view entity` does not support `@OData.publish`. If migrating to OData V4 (RAP) in the future, this would change to `define view entity` with a Service Definition + Service Binding instead.

---

## Step 11 — Create Metadata Extension: ZE_JIPV4_AGING

**Type:** Metadata Extension (`.asddlx`)  
**Target View:** `ZC_JIPV4_AGING`  
**Purpose:** All UI annotations separated from the CDS view — filter bar, table columns, charts, data points, presentation/selection variants, field groups

### 11.1 Create the Metadata Extension

1. Right-click on package `ZJIPV4` > **New** > **Other ABAP Repository Object**
2. Expand **Core Data Services** > select **Metadata Extension**
3. Click **Next**
4. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `ZE_JIPV4_AGING` |
| **Description** | `JIP V4 Milestone Aging - MDE UI Annotations` |
| **Annotated Entity** | `ZC_JIPV4_AGING` |

5. Click **Next** > Select your **Transport Request** > Click **Finish**

### 11.2 Replace with the following code

```abap
@Metadata.layer: #CUSTOMER

// =====================================================================
// ENTITY-LEVEL ANNOTATIONS (must be BEFORE the { block)
// =====================================================================

@UI.headerInfo: {
  typeName: 'JIP Part',
  typeNamePlural: 'JIP Parts Aging',
  title: { type: #STANDARD, value: 'WorkOrderNumber' },
  description: { type: #STANDARD, value: 'MaterialNumber' }
}

// --- CHART DEFINITIONS ---
@UI.chart: [
  {
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
  },
  {
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
  },
  {
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
  },
  {
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
  },
  {
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
  },
  {
    qualifier: 'ChartAvgAging',
    title: 'Avg Aging by Plant & Activity',
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
  }
]

// --- PRESENTATION VARIANTS ---
@UI.presentationVariant: [
  {
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
  },
  {
    qualifier: 'PVChartByPlant',
    text: 'By Plant',
    sortOrder: [{ by: 'Plant', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartJIPPerPlant'
    }]
  },
  {
    qualifier: 'PVChartHistorical',
    text: 'Historical',
    sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartHistoricalJIP'
    }]
  },
  {
    qualifier: 'PVChartActivity',
    text: 'By Activity',
    sortOrder: [{ by: 'ActivityType', direction: #ASC }],
    visualizations: [{
      type: #AS_CHART,
      qualifier: 'ChartActivityBreakdown'
    }]
  }
]

annotate view ZC_JIPV4_AGING with

{
  // =====================================================================
  // FIELD-LEVEL ANNOTATIONS (each field appears ONCE with all annotations)
  // =====================================================================

  // --- WorkOrderNumber ---
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 10, label: 'Work Order' }]
  WorkOrderNumber;

  // --- MaterialNumber ---
  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  @UI.identification: [{ position: 20 }]
  MaterialNumber;

  // --- ABCIndicator ---
  @UI.lineItem: [{ position: 25, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 70 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 40, label: 'ABC Indicator' }]
  ABCIndicator;

  // --- Plant ---
  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  @UI.selectionField: [{ position: 10 }]
  @UI.identification: [{ position: 30 }]
  Plant;

  // --- ActivityType ---
  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @UI.selectionField: [{ position: 20 }]
  @UI.identification: [{ position: 40 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 30, label: 'Activity Type' }]
  ActivityType;

  // --- AgingBucket ---
  @UI.lineItem: [{ position: 50, importance: #HIGH, criticality: 'AgingCriticality' }]
  @UI.selectionField: [{ position: 30 }]
  @UI.identification: [{ position: 50, criticality: 'AgingCriticality' }]
  @UI.dataPoint: { title: 'Aging Bucket', criticality: 'AgingCriticality' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 50, label: 'Aging Bucket', criticality: 'AgingCriticality' }]
  AgingBucket;

  // --- CurrentMilestone ---
  @UI.lineItem: [{ position: 60, importance: #HIGH }]
  @UI.selectionField: [{ position: 60 }]
  @UI.dataPoint: { title: 'Current Milestone' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 30, label: 'Current Milestone' }]
  CurrentMilestone;

  // --- WmEwmType ---
  @UI.lineItem: [{ position: 70, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 40 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 10, label: 'WM/EWM Type' }]
  WmEwmType;

  // --- WarehouseNumber ---
  @UI.lineItem: [{ position: 80, importance: #MEDIUM }]
  @UI.selectionField: [{ position: 50 }]
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 20, label: 'Warehouse Number' }]
  WarehouseNumber;

  // --- SoldToParty ---
  @UI.lineItem: [{ position: 90, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpCustomer', position: 10, label: 'Sold To Party' }]
  SoldToParty;

  // --- AgingRelease ---
  @UI.lineItem: [{ position: 100, importance: #MEDIUM }]
  @UI.dataPoint: { title: 'Aging Release (Days)', criticality: 'AgingCriticality' }
  @UI.fieldGroup: [{ qualifier: 'GrpWarehouse', position: 40, label: 'Aging Release (Days)' }]
  AgingRelease;

  // --- QtyAvailCheck ---
  @UI.lineItem: [{ position: 110, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 10, label: 'Qty Avail Check' }]
  QtyAvailCheck;

  // --- QtyWithdrawn ---
  @UI.lineItem: [{ position: 120, importance: #MEDIUM }]
  @UI.fieldGroup: [{ qualifier: 'GrpQuantities', position: 20, label: 'Qty Withdrawn (GI)' }]
  QtyWithdrawn;

  // --- SDHApprovalDate ---
  @UI.lineItem: [{ position: 130, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 10, label: 'SDH Approval' }]
  SDHApprovalDate;

  // --- ReleaseDate ---
  @UI.lineItem: [{ position: 140, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 20, label: 'Release Date (FTRMI)' }]
  ReleaseDate;

  // --- WM_TRDate ---
  @UI.lineItem: [{ position: 150, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 30, label: 'TR Date (WM)' }]
  WM_TRDate;

  // --- WM_ReceivedDate ---
  @UI.lineItem: [{ position: 160, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 40, label: 'Received Date (WM)' }]
  WM_ReceivedDate;

  // --- EWM_ConfirmedAt ---
  @UI.lineItem: [{ position: 170, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 50, label: 'Confirmed At (EWM)' }]
  EWM_ConfirmedAt;

  // --- GIDate ---
  @UI.lineItem: [{ position: 180, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 60, label: 'GI Date' }]
  GIDate;

  // --- GINumber ---
  @UI.lineItem: [{ position: 190, importance: #LOW }]
  @UI.fieldGroup: [{ qualifier: 'GrpMilestones', position: 70, label: 'GI Number' }]
  GINumber;

  // --- PeriodMonth ---
  @UI.lineItem: [{ position: 200, importance: #LOW }]
  @UI.selectionField: [{ position: 80 }]
  PeriodMonth;

  // --- OrderType (no lineItem, only fieldGroup) ---
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 20, label: 'Order Type' }]
  OrderType;

  // --- WOCreationDate (no lineItem, only fieldGroup) ---
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 50, label: 'WO Creation Date' }]
  WOCreationDate;

  // --- EquipmentNumber (no lineItem, only fieldGroup) ---
  @UI.fieldGroup: [{ qualifier: 'GrpWorkOrder', position: 60, label: 'Equipment' }]
  EquipmentNumber;
}
```

### 11.3 Activate

- Press **Ctrl+F3** to activate
- **Important:** `ZC_JIPV4_AGING` (Step 10) must be activated BEFORE activating this MDE

### 11.4 Key Points

- **`@Metadata.layer: #CUSTOMER`** — Customer layer (highest priority, overrides `#CORE` and `#PARTNER`)
- **`annotate view ZC_JIPV4_AGING with`** — Must match the consumption view name exactly
- **Entity-level annotations BEFORE `{`:** `@UI.headerInfo`, `@UI.chart`, `@UI.presentationVariant`
- **Field-level annotations INSIDE `{`:** `@UI.lineItem`, `@UI.selectionField`, `@UI.identification`, `@UI.dataPoint`, `@UI.fieldGroup`
- **Each field appears ONCE** with all its annotations stacked above (no duplicate field entries)
- **MDE contains:**
  - 8 selection fields (filter bar)
  - 20 line item columns (detail table)
  - 3 data points (KPIs with criticality)
  - 6 chart definitions (OVP chart cards)
  - 4 presentation variants (sort orders)
  - 5 identification fields (object page header)
  - 5 field groups (object page sections: WorkOrder, Milestones, Quantities, Customer, Warehouse)
- **Selection variants NOT supported** in CDS MDE — must be configured in Fiori app manifest

### 11.5 Benefits of MDE Separation

| Benefit | Explanation |
|---------|-------------|
| **No CDS reactivation** | Changing UI layout only touches MDE — no need to reactivate the CDS view |
| **Faster OData metadata load** | SADL caches annotation layer independently |
| **Transport independence** | MDE and CDS can be transported separately |
| **Clean separation** | CDS = data logic; MDE = presentation logic |

---

## Step 12 — Activate OData V2 Service

After activating the consumption view `ZC_JIPV4_AGING`, the OData V2 service is auto-generated by SADL. You must register it in the SAP Gateway.

### 12.1 Register Service in SAP Gateway

1. Open **SAP GUI** > Transaction `/IWFND/MAINT_SERVICE`
2. Click **Add Service**
3. Set **System Alias** = `LOCAL` (or your RFC destination)
4. Click **Get Services**
5. Search for: **`ZC_JIPV4_AGING_CDS`**
6. Select it > Click **Add Selected Services**
7. Confirm the **System Alias** and **Package Assignment**
8. Click **Continue**

### 12.2 Clear Metadata Cache

1. In `/IWFND/MAINT_SERVICE`, select `ZC_JIPV4_AGING_CDS`
2. Click **SAP Gateway Client** (or **ICF Node** > **Clear Cache**)
3. Alternatively: Transaction `/IWFND/CACHE_CLEANUP` > Execute

### 12.3 Test OData Service

1. In `/IWFND/MAINT_SERVICE`, select `ZC_JIPV4_AGING_CDS`
2. Click **SAP Gateway Client**
3. Test these URLs:

| Test | URL | Expected |
|------|-----|----------|
| Service Document | `/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/` | XML with entity sets |
| Metadata | `/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/$metadata` | Full metadata with UI annotations |
| Data | `/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/ZC_JIPV4_AGING?$top=10` | First 10 records |
| Filtered | `/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/ZC_JIPV4_AGING?$filter=Plant eq '1000'` | Filtered data |

---

## Step 13 — Test and Validate

### 13.1 Data Preview in Eclipse ADT

For each CDS view, right-click > **Open With** > **Data Preview** (or press **F8**):

| # | View | What to Check |
|---|------|---------------|
| 1 | `ZI_JIPV4_Reservation` | Reservation items exist, `xloek` filter works |
| 2 | `ZI_JIPV4_WorkOrder` | WO data with Activity Type, ABC Indicator, Release Date |
| 3 | `ZI_JIPV4_TransferOrderWM` | WM transfer orders with confirmation dates |
| 4 | `ZI_JIPV4_GoodsMovement` | Only `BWART = Z26` records |
| 5 | `ZI_JIPV4_EWM_ProductMap` | MATID to MATNR mapping |
| 6 | `ZI_JIPV4_EWM_WarehouseTask` | EWM tasks with MaterialNumber resolved (not blank) |
| 7 | `ZI_JIPV4_EWM_PlantMap` | Plant/SLoc to Warehouse Number |
| 8 | `ZI_JIPV4_PartsComposite` | Full data with WmEwmType, CurrentMilestone, AgingBucket |
| 9 | `ZC_JIPV4_AGING` | Same as #8 + AgingCriticality (1/2/3) |

### 13.2 Validate MDE Annotations

1. Open `ZC_JIPV4_AGING` in Eclipse ADT
2. Check the **Element Info** panel — annotations from `ZE_JIPV4_AGING` should appear
3. Alternatively, check `$metadata` in OData — look for `com.sap.vocabularies.UI.v1` annotations

### 13.3 Fiori Launchpad Test

1. Open the Fiori Launchpad
2. Create an OVP application tile (or test via Fiori Elements Preview)
3. Verify:
   - Filter bar shows 8 selection fields
   - Table shows 20 columns with correct positions
   - AgingBucket has color coding (Green/Yellow/Red)
   - Chart cards render correctly

---

## Architecture Diagram

```
+---------------------------------------------------------------------+
|              SOURCE TABLES (Basic Tables Only)                       |
|  AUFK, AFKO, AFIH, ILOA, RESB, MSEG, MKPF, LTAK, LTAP, LTBK,    |
|  /SCWM/ORDIM_C, /SCWM/BINMAT, /SCWM/TMAPSTLOC,                   |
|  ZTWOAPPR, VBAK, VBKD                                              |
+---------------------------------+-----------------------------------+
                                  |
    +-----------------------------v-------------------------------+
    |    BASIC VIEWS       (Layer 1 - VDM #BASIC)                 |
    |    Step 2:  ZI_JIPV4_Reservation        <-- RESB            |
    |    Step 3:  ZI_JIPV4_WorkOrder          <-- AUFK+AFKO+AFIH  |
    |    Step 4:  ZI_JIPV4_TransferOrderWM    <-- LTAP+LTAK        |
    |    Step 5:  ZI_JIPV4_GoodsMovement      <-- MSEG+MKPF       |
    |    Step 6:  ZI_JIPV4_EWM_ProductMap     <-- /SCWM/BINMAT    |
    |    Step 7:  ZI_JIPV4_EWM_WarehouseTask  <-- /SCWM/ORDIM_C   |
    |    Step 8:  ZI_JIPV4_EWM_PlantMap       <-- /SCWM/TMAPSTLOC |
    +-----------------------------+-------------------------------+
                                  |
    +-----------------------------v-------------------------------+
    |    COMPOSITE VIEW    (Layer 2 - VDM #COMPOSITE)              |
    |    Step 9:  ZI_JIPV4_PartsComposite                          |
    |             Joins all Basic Views                             |
    |             + WM/EWM branching + Aging calc                   |
    +-----------------------------+-------------------------------+
                                  |
    +-----------------------------v-------------------------------+
    |    CONSUMPTION VIEW  (Layer 3 - VDM #CONSUMPTION)            |
    |    Step 10: ZC_JIPV4_AGING                                    |
    |             @OData.publish: true                               |
    |             @Metadata.allowExtensions: true                    |
    |                                                               |
    |    METADATA EXTENSION                                         |
    |    Step 11: ZE_JIPV4_AGING                                    |
    |             All @UI annotations (charts, filters, table)      |
    +-----------------------------+-------------------------------+
                                  |
    +-----------------------------v-------------------------------+
    |    OData V2 Service  (Auto-published via SADL)               |
    |    Step 12: /sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/          |
    +-----------------------------+-------------------------------+
                                  |
    +-----------------------------v-------------------------------+
    |    FIORI OVP         (Overview Page Dashboard)               |
    |    Step 13: Test & Validate                                   |
    |    6 Chart Cards + Detail Table + Object Page                 |
    +-------------------------------------------------------------+
```

---

## Activation Order

Objects **MUST** be activated in this exact order due to dependencies:

| Order | Object | Type | Depends On |
|-------|--------|------|------------|
| 1 | `ZJIPV4` | Package | -- |
| 2 | `ZI_JIPV4_Reservation` | CDS View Entity (Basic) | RESB table |
| 3 | `ZI_JIPV4_WorkOrder` | CDS View Entity (Basic) | AUFK, AFKO, AFIH, ILOA, ZTWOAPPR, VBAK, VBKD tables |
| 4 | `ZI_JIPV4_TransferOrderWM` | CDS View Entity (Basic) | LTAP, LTAK tables |
| 5 | `ZI_JIPV4_GoodsMovement` | CDS View Entity (Basic) | MSEG, MKPF tables |
| 6 | `ZI_JIPV4_EWM_ProductMap` | CDS View Entity (Basic) | /SCWM/BINMAT table |
| 7 | `ZI_JIPV4_EWM_WarehouseTask` | CDS View Entity (Basic) | /SCWM/ORDIM_C, /SCWM/BINMAT tables |
| 8 | `ZI_JIPV4_EWM_PlantMap` | CDS View Entity (Basic) | /SCWM/TMAPSTLOC table |
| 9 | `ZI_JIPV4_PartsComposite` | CDS View Entity (Composite) | Steps 2-8 (all Basic views) |
| 10 | `ZC_JIPV4_AGING` | CDS View (Consumption) | Step 9 (Composite view) |
| 11 | `ZE_JIPV4_AGING` | Metadata Extension | Step 10 (Consumption view) |

> **Tip:** You can activate Steps 2-8 in any order (they are independent of each other). Steps 9-11 must be sequential.

---

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Table /SCWM/BINMAT not found` | EWM component not active | Ensure EWM is installed and active on the system |
| `CAST type not compatible` | `abap.char(32)` not supported on older releases | Try `abap.raw(16)` or `abap.sstring(32)` as CAST alternatives |
| `Metadata Extension not applied` | Missing `@Metadata.allowExtensions: true` | Add this annotation to `ZC_JIPV4_AGING` and reactivate |
| `OData service not found` | Service not registered | Run `/IWFND/MAINT_SERVICE` and Add Service |
| `$metadata has no UI annotations` | MDE not activated or cache not cleared | Reactivate MDE + run `/IWFND/CACHE_CLEANUP` |
| `View entity cannot use @OData.publish` | Using `define view entity` instead of `define view` | Change `ZC_JIPV4_AGING` to `define view` with `sqlViewName` |
| `sqlViewName exceeds 16 characters` | SQL view name too long | Use short name like `ZVCJIPV4AGN` |
| `dats_days_between returns negative` | Start date is after end date | Verify SDH date precedes release date |

### Useful Transactions

| Transaction | Purpose |
|-------------|---------|
| `/IWFND/MAINT_SERVICE` | Register and manage OData services |
| `/IWFND/CACHE_CLEANUP` | Clear OData metadata cache |
| `/IWFND/GW_CLIENT` | Test OData URLs directly |
| `SE11` | Check table structures and data |
| `SE80` | Browse package contents |
| `ST05` | SQL Trace (performance analysis) |

---

## Summary Checklist

- [ ] Package `ZJIPV4` created
- [ ] `ZI_JIPV4_Reservation` — activated and data preview OK
- [ ] `ZI_JIPV4_WorkOrder` — activated with ILOA ABC + AFKO FTRMI
- [ ] `ZI_JIPV4_TransferOrderWM` — activated with WM TOs
- [ ] `ZI_JIPV4_GoodsMovement` — activated with BWART=Z26 filter
- [ ] `ZI_JIPV4_EWM_ProductMap` — activated with BINMAT mapping
- [ ] `ZI_JIPV4_EWM_WarehouseTask` — activated with CAST join + milestone mapping
- [ ] `ZI_JIPV4_EWM_PlantMap` — activated with TMAPSTLOC detection
- [ ] `ZI_JIPV4_PartsComposite` — activated with all joins + aging logic
- [ ] `ZC_JIPV4_AGING` — activated with `@OData.publish` + `@Metadata.allowExtensions`
- [ ] `ZE_JIPV4_AGING` — activated with all UI annotations
- [ ] OData service `ZC_JIPV4_AGING_CDS` registered in `/IWFND/MAINT_SERVICE`
- [ ] OData metadata cache cleared
- [ ] Data preview verified for all views
- [ ] `$metadata` shows UI annotations from MDE
- [ ] Fiori dashboard tested in Launchpad

---

## Step 11.1 — Enhancement: Card 06 Target Line (v4.2)

**Purpose:** Add a target reference line to Card 06 (Avg Aging vs Target) showing the KPI target for each Activity Type.

### 11.1.1 Add `TargetAgingDays` to Composite View

In `ZI_JIPV4_PartsComposite`, add this CASE statement after `AgingBucket`:

```abap
-- Target Aging Days per Activity Type (hardcoded — customize per ILART)
case WO.ActivityType
  when 'ADD' then 15
  when 'INS' then 15
  when 'LOG' then 15
  when 'MID' then 15
  when 'NME' then 15
  when 'OVH' then 15
  when 'PAP' then 15
  when 'PPM' then 15
  when 'SER' then 15
  when 'TRS' then 15
  when 'UIW' then 15
  when 'USN' then 15
  else 15
end as TargetAgingDays,
```

### 11.1.2 Expose in Consumption View

In `ZC_JIPV4_AGING`, add to the select list:

```abap
TargetAgingDays,
```

### 11.1.3 Update Metadata Extension

Replace the old `ChartAvgAging` with `ChartAvgAgingWithTarget` in `ZE_JIPV4_AGING`:

**Old Chart (remove):**
```abap
{
  qualifier: 'ChartAvgAging',
  title: 'Avg Aging by Plant & Activity',
  chartType: #COMBINATION,
  dimensions: ['Plant', 'ActivityType'],
  measures: ['AgingRelease'],
  ...
}
```

**New Chart (add):**
```abap
{
  qualifier: 'ChartAvgAgingWithTarget',
  title: 'Avg Aging vs Target by Plant & Activity',
  chartType: #COMBINATION,
  dimensions: ['PeriodMonth'],
  measures: ['AgingRelease', 'TargetAgingDays'],
  dimensionAttributes: [
    { dimension: 'PeriodMonth', role: #CATEGORY }
  ],
  measureAttributes: [
    {
      measure: 'AgingRelease',
      role: #AXIS_1,
      asDataPoint: true
    },
    {
      measure: 'TargetAgingDays',
      role: #AXIS_1,
      asDataPoint: true
    }
  ]
}
```

Add new presentation variant:
```abap
{
  qualifier: 'PVAvgAgingTarget',
  text: 'Avg Aging vs Target',
  sortOrder: [{ by: 'PeriodMonth', direction: #ASC }],
  visualizations: [{
    type: #AS_CHART,
    qualifier: 'ChartAvgAgingWithTarget'
  }]
}
```

Add datapoint annotation (in field-level section):
```abap
// --- TargetAgingDays ---
@UI.dataPoint: {
  title: 'Target Aging (Days)',
  targetValue: 'TargetAgingDays'
}
TargetAgingDays;
```

### 11.1.4 Activation Order

1. Activate `ZI_JIPV4_PartsComposite` (Ctrl+F3)
2. Activate `ZC_JIPV4_AGING` (Ctrl+F3)
3. Activate `ZE_JIPV4_AGING` (Ctrl+F3)
4. Clear metadata cache: `/IWFND/CACHE_CLEANUP`

### 11.1.5 How It Works

The COMBINATION chart renders:
- **Bars** = `AgingRelease` (actual average aging days)
- **Line** = `TargetAgingDays` (target reference — appears as flat horizontal line)

Since `TargetAgingDays` is constant per Activity Type (via CASE statement), it displays as a flat reference line. When the user changes the Activity Type filter, the target line adjusts automatically.

### 11.1.6 Future Enhancement: Z-Table Approach

To allow business users to maintain targets without development:

**Create Z-Table `ZTJIP_TARGETS`:**

| Field | Type | Description |
|-------|------|-------------|
| MANDT | CLNT | Client |
| ILART | CHAR(3) | Activity Type (key) |
| TARGET_DAYS | INT4 | Target aging days |
| DESCRIPTION | CHAR(40) | Description |

**Update CDS:**
```abap
left outer join ztjip_targets as TGT
  on WO.ActivityType = TGT.ilart

-- In select:
coalesce(TGT.target_days, 15) as TargetAgingDays
```

Create SM30 maintenance view for business users. This is optional Phase 2 enhancement.