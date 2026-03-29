# JIP V4 — CDS Views Documentation

**Last Updated:** 2026-03-27

---

## View Dependency Tree

```text
ZC_JIPV4_AGING (Consumption — OData V2, Analytics #CUBE)
  └── ZI_JIPV4_PartsComposite (Composite — Main Join Hub)
        ├── ZI_JIPV4_Reservation          (Basic — resb)
        ├── ZI_JIPV4_WorkOrder            (Basic — aufk/afko/afih/iloa/ztwoappr/vbak)
        ├── ZI_JIPV4_GoodsMovement        (Basic — matdoc)
        ├── ZI_JIPV4_EWM_PlantMap         (Basic — /scwm/tmapstloc)
        ├── ZI_JIPV4_WM_MilestoneAgg      (Basic — ltap/ltak, aggregated)
        └── ZI_JIPV4_EWM_MilestoneAgg     (Basic — /scwm/ordim_c/mara, aggregated)

ZE_JIPV4_AGING (MDE — UI annotations for ZC_JIPV4_AGING)

Standalone (not joined in composite but available for reference):
  ├── ZI_JIPV4_TransferOrderWM            (Basic — ltap/ltak, detail level)
  ├── ZI_JIPV4_EWM_WarehouseTask          (Basic — /scwm/ordim_c, detail level)
  └── ZI_JIPV4_EWM_ProductMap             (Basic — mara MATID→MATNR)
```

---

## 1. ZI_JIPV4_Reservation

**Type:** Basic (`#BASIC`) — View Entity
**Source Table:** `resb` (Reservation Items)
**Purpose:** Extract reservation line items linked to work orders.

### Key Fields

| Field               | Source | Description                  |
|---------------------|--------|------------------------------|
| ReservationNumber   | rsnum  | Reservation number (CHAR 10) |
| ReservationItem     | rspos  | Reservation item (CHAR 4)    |
| ReservationCategory | rsart  | Reservation category         |

### Other Fields

| Field           | Source | Description              |
|-----------------|--------|--------------------------|
| WorkOrderNumber | aufnr  | PM Work Order number     |
| MaterialNumber  | matnr  | Material number          |
| Plant           | werks  | Plant                    |
| StorageLocation | lgort  | Storage location         |
| RequirementQty  | bdmng  | Requirement quantity     |
| QtyAvailCheck   | vmeng  | Quantity available check |
| QtyWithdrawn    | enmng  | Quantity withdrawn (GI)  |
| BaseUnit        | meins  | Base unit of measure     |
| MovementType    | bwart  | Movement type            |

### Filters

- `xloek = ''` — not deleted
- `aufnr <> ''` — linked to a work order

---

## 2. ZI_JIPV4_WorkOrder

**Type:** Basic (`#BASIC`) — View Entity
**Source Tables:** `aufk` (Order Header) + `afko` (Production) + `afih` (PM Header) + `iloa` (Functional Location) + `ztwoappr` (Custom Approval) + `vbak` (Sales Order)
**Purpose:** Work order header data including release date, activity type, and approval dates.

### Key Fields

| Field           | Source     | Description          |
|-----------------|------------|----------------------|
| WorkOrderNumber | aufk.aufnr | PM Work Order number |

### Other Fields

| Field            | Source                  | Description                       |
|------------------|-------------------------|-----------------------------------|
| OrderType        | aufk.auart              | Order type                        |
| WOCreationDate   | aufk.erdat              | WO creation date                  |
| Plant            | aufk.werks              | Plant                             |
| SalesOrderNumber | aufk.kdauf              | Sales order reference             |
| ActivityType     | afih.ilart              | PM activity type (SER, OVH, etc.) |
| EquipmentNumber  | afih.equnr              | Equipment number                  |
| ABCIndicator     | iloa.abckz              | ABC indicator (via ILOAN)         |
| WOReleaseDate    | afko.ftrmi              | Actual release date (FTRMI)       |
| AppSDHDate       | ztwoappr.appr_date_lvl3 | SDH approval date (Level 3)       |
| SoldToParty      | vbak.kunnr              | Sold-to party (customer)          |

---

## 3. ZI_JIPV4_GoodsMovement

**Type:** Basic (`#BASIC`) — View Entity
**Source Table:** `matdoc` (Material Document)
**Purpose:** Goods Issue (GI) movements for reservation items.

### Key Fields

| Field             | Source | Description            |
|-------------------|--------|------------------------|
| MaterialDocNumber | mblnr  | Material document no.  |
| MaterialDocYear   | mjahr  | Material document year |
| LineItem          | zeile  | Line item number       |

### Other Fields

| Field             | Source | Description          |
|-------------------|--------|----------------------|
| MaterialNumber    | matnr  | Material number      |
| Plant             | werks  | Plant                |
| WorkOrderNumber   | aufnr  | Work order reference |
| ReservationNumber | rsnum  | Reservation number   |
| ReservationItem   | rspos  | Reservation item     |
| PostingDate       | budat  | GI posting date      |

### Filters

- `bwart = 'Z26'` — Custom GI movement type

---

## 4. ZI_JIPV4_EWM_PlantMap

**Type:** Basic (`#BASIC`) — View Entity
**Source Table:** `/scwm/tmapstloc` (EWM Storage Location Mapping)
**Purpose:** Map SAP ECC plants to EWM warehouse numbers. Used to detect whether a plant is EWM-managed.

### Fields

| Field           | Source | Description       |
|-----------------|--------|-------------------|
| Plant (key)     | plant  | ECC Plant         |
| WarehouseNumber | lgnum  | EWM Warehouse no. |

---

## 5. ZI_JIPV4_EWM_ProductMap

**Type:** Basic (`#BASIC`) — View Entity
**Source Table:** `mara` (Material Master)
**Purpose:** Map EWM Product GUID (`scm_matid_guid16`) to standard material number (`matnr`).

### Fields

| Field          | Source           | Description         |
|----------------|------------------|---------------------|
| ProductGuid    | scm_matid_guid16 | EWM Product GUID    |
| MaterialNumber | matnr            | SAP Material Number |

---

## 6. ZI_JIPV4_WM_MilestoneAgg

**Type:** Basic (`#BASIC`) — SQL View (`ZVIJIPWMAGG`)
**Source Tables:** `ltap` (Transfer Order Items) + `ltak` (Transfer Order Headers)
**Purpose:** Aggregated WM milestone dates — 1 row per Plant + Material + MovementType.

### Key Fields

| Field          | Source     | Description      |
|----------------|------------|------------------|
| Plant          | ltap.werks | Plant            |
| MaterialNumber | ltap.matnr | Material number  |
| MovementType   | ltak.bwlvs | WM movement type |

### Aggregated Fields

| Field            | Aggregation | Source     | Description                         |
|------------------|-------------|------------|-------------------------------------|
| WarehouseNumber  | MAX         | ltap.lgnum | Warehouse number                    |
| TOCreationDate   | MAX         | ltak.bdatu | Latest Transfer Order creation date |
| ConfirmationDate | MAX         | ltap.qdatu | Latest TO item confirmation date    |

### Movement Type Mapping

| MovementType | Milestone  |
|--------------|------------|
| 919          | TR_REQUEST |
| 920          | TR_REQUEST |
| 997          | RECEIVED   |
| 994          | NPB        |

---

## 7. ZI_JIPV4_EWM_MilestoneAgg

**Type:** Basic (`#BASIC`) — SQL View (`ZVIJIPEWMAGG`)
**Source Tables:** `/scwm/ordim_c` (EWM Warehouse Task Confirmed) + `mara`
**Purpose:** Aggregated EWM milestone timestamps — 1 row per Material + ProcessType.

### Key Fields

| Field          | Source         | Description       |
|----------------|----------------|-------------------|
| MaterialNumber | mara.matnr     | Material number   |
| ProcessType    | ordim_c.procty | EWM process type  |

### Aggregated Fields

| Field           | Aggregation | Source               | Description                       |
|-----------------|-------------|----------------------|-----------------------------------|
| ConfirmedAt     | MAX         | ordim_c.confirmed_at | Latest confirmed timestamp (DEC)  |
| WarehouseNumber | MAX         | ordim_c.lgnum        | Warehouse number                  |

### Process Type Mapping

| ProcessType | Milestone  |
|-------------|------------|
| S919        | TR_REQUEST |
| S920        | TR_REQUEST |
| S997        | RECEIVED   |
| S994        | NPB        |

> **Important:** `ConfirmedAt` is `Decimal(15,0)` (timestamp), **NOT** `abap.dats`. Cannot be used with `dats_days_between()`.

---

## 8. ZI_JIPV4_TransferOrderWM

**Type:** Basic (`#BASIC`) — View Entity
**Source Tables:** `ltap` + `ltak`
**Purpose:** Detail-level WM Transfer Order data (not aggregated). Available for reference/debugging.

### Key Fields

| Field             | Source     | Description        |
|-------------------|------------|--------------------|
| WarehouseNumber   | ltap.lgnum | Warehouse number   |
| TransferOrderNo   | ltap.tanum | Transfer order no. |
| TransferOrderItem | ltap.tapos | TO item number     |

### Other Fields

| Field            | Source     | Description            |
|------------------|------------|------------------------|
| MaterialNumber   | ltap.matnr | Material number        |
| Plant            | ltap.werks | Plant                  |
| TOCreationDate   | ltak.bdatu | TO creation date       |
| MovementType     | ltak.bwlvs | WM movement type       |
| ConfirmationDate | ltap.qdatu | TO item confirmed date |

---

## 9. ZI_JIPV4_EWM_WarehouseTask

**Type:** Basic (`#BASIC`) — View Entity
**Source Table:** `/scwm/ordim_c`
**Purpose:** Detail-level EWM Warehouse Tasks. Available for reference/debugging.

### Key Fields

| Field           | Source | Description        |
|-----------------|--------|--------------------|
| WarehouseNumber | lgnum  | EWM warehouse no.  |
| WarehouseTaskNo | tanum  | Warehouse task no. |
| TaskPosition    | tapos  | Task position      |

### Other Fields

| Field              | Source       | Description                       |
|--------------------|-------------|-----------------------------------|
| ProductGuid        | matid       | EWM Product GUID                  |
| ProcessType        | procty      | Process type (S919/S997/S994)     |
| ConfirmedAt        | confirmed_at | Confirmation timestamp (DEC)     |
| CreatedAt          | created_at  | Creation timestamp                |
| WarehouseOrder     | who         | Warehouse order reference         |
| JipMilestone       | (derived)   | Milestone by ProcessType          |
| JipMilestoneByZone | (derived)   | Milestone by Destination Bin zone |
| IsConfirmed        | (derived)   | 'X' if confirmed                  |

---

## 10. ZI_JIPV4_PartsComposite

**Type:** Composite (`#COMPOSITE`) — View Entity
**Purpose:** Main join hub combining reservations, work orders, goods movements, and milestones (WM + EWM paths).

### Source Joins

| Alias   | View                       | Join Type  | Join Condition                          |
|---------|----------------------------|------------|-----------------------------------------|
| Resv    | ZI_JIPV4_Reservation       | FROM       | (base)                                  |
| WO      | ZI_JIPV4_WorkOrder         | LEFT OUTER | Resv.WorkOrderNumber                    |
| PM      | ZI_JIPV4_EWM_PlantMap      | LEFT OUTER | Resv.Plant                              |
| GI      | ZI_JIPV4_GoodsMovement     | LEFT OUTER | Resv.ReservationNumber + Item           |
| WM_TR   | ZI_JIPV4_WM_MilestoneAgg  | LEFT OUTER | Plant + Material + MovementType = '919' |
| WM_RCV  | ZI_JIPV4_WM_MilestoneAgg  | LEFT OUTER | Plant + Material + MovementType = '997' |
| WM_NPB  | ZI_JIPV4_WM_MilestoneAgg  | LEFT OUTER | Plant + Material + MovementType = '994' |
| EWM_TR  | ZI_JIPV4_EWM_MilestoneAgg | LEFT OUTER | Material + ProcessType = 'S919'         |
| EWM_RCV | ZI_JIPV4_EWM_MilestoneAgg | LEFT OUTER | Material + ProcessType = 'S997'         |
| EWM_NPB | ZI_JIPV4_EWM_MilestoneAgg | LEFT OUTER | Material + ProcessType = 'S994'         |

### Key Derived Fields

- **WmEwmType** — `'EWM'` if PM.WarehouseNumber is not null, else `'WM'`
- **CurrentMilestone** — Priority: GI > NPB > RECEIVED > TR_REQUEST > PENDING (EWM and WM paths separated)
- **AgingRelease** — `dats_days_between(AppSDHDate, WOReleaseDate)` — days from SDH approval to release
- **AgingBucket** — `'70+'` / `'60+'` / `'OK'` based on `dats_days_between(AppSDHDate, today)`
- **TargetAgingDays** — 15 days for all activity types (configurable per type)
- **CurrentAging** — Days between consecutive milestones (see `Bugs-Fixing-V5.md` for full CASE logic)
- **RecordCount** — Always 1 (for SUM aggregation in charts)
- **PeriodMonth** — `YYYY-MM` derived from WOCreationDate
- **PeriodYear** — `YYYY` derived from WOCreationDate

---

## 11. ZC_JIPV4_AGING

**Type:** Consumption (`#CONSUMPTION`) — SQL View (`ZVCJIPV4AGN`)
**OData:** `@OData.publish: true` — OData V2 service `ZC_JIPV4_AGING_CDS`
**Analytics:** `@Analytics.dataCategory: #CUBE`
**MDE:** `@Metadata.allowExtensions: true` → `ZE_JIPV4_AGING`
**Purpose:** OData-published consumption view exposing all fields from `ZI_JIPV4_PartsComposite` with proper aggregation annotations.

### Aggregation Roles

| Field             | Aggregation   | Role      |
|-------------------|---------------|-----------|
| ReservationNumber | #NONE (key)   | Key       |
| ReservationItem   | #NONE (key)   | Key       |
| WorkOrderNumber   | (dimension)   | Dimension |
| MaterialNumber    | (dimension)   | Dimension |
| Plant             | (dimension)   | Dimension |
| CurrentMilestone  | (dimension)   | Dimension |
| AgingBucket       | (dimension)   | Dimension |
| PeriodMonth       | (dimension)   | Dimension |
| RecordCount       | #SUM          | Measure   |
| TargetAgingDays   | #SUM          | Measure   |
| CurrentAging      | #SUM          | Measure   |
| AgingRelease      | (default SUM) | Measure   |

### Derived Field

- **AgingCriticality** — `1` (red) for 70+, `2` (yellow) for 60+, `3` (green) for OK

---

## 12. ZE_JIPV4_AGING (MDE — Metadata Extension)

**Type:** Metadata Extension (`@Metadata.layer: #CUSTOMER`)
**Target:** `ZC_JIPV4_AGING`
**Purpose:** UI annotations for SAP Fiori Overview Page (OVP) cards.

### Charts Defined (7 total)

| Qualifier              | Chart Type     | Dimensions               | Measures                      |
|------------------------|----------------|--------------------------|-------------------------------|
| ChartJIPPerPlant       | BAR            | Plant, ActivityType      | RecordCount                   |
| ChartHistoricalJIP     | COLUMN_STACKED | PeriodMonth, AgingBucket | RecordCount                   |
| ChartAgingPerPlant     | COLUMN_STACKED | PeriodMonth, AgingBucket | RecordCount                   |
| ChartActivityBreakdown | COLUMN_STACKED | PeriodMonth, ActivityType | RecordCount                  |
| ChartMonthlyTrend      | COLUMN_STACKED | PeriodMonth, ActivityType | RecordCount                  |
| ChartPendingByActivity | COMBINATION    | ActivityType             | RecordCount, TargetAgingDays  |
| ChartAvgAgingWithTarget | COMBINATION   | PeriodMonth              | AgingRelease, TargetAgingDays |

### LineItem Qualifiers

| Qualifier     | Used By | Columns                                                                              |
|---------------|---------|--------------------------------------------------------------------------------------|
| (default)     | Detail  | All fields with positions 10–200                                                     |
| ActivityAging | Card 08 | WorkOrderNumber, MaterialNumber, Plant, ActivityType, CurrentMilestone, CurrentAging  |

### Field Groups

| Qualifier    | Fields                                                                               |
|--------------|--------------------------------------------------------------------------------------|
| GrpWorkOrder | WorkOrderNumber, OrderType, ActivityType, ABCIndicator, WOCreationDate, EquipmentNumber |
| GrpWarehouse | WmEwmType, WarehouseNumber, CurrentMilestone, AgingRelease, AgingBucket              |
| GrpMilestones | SDHApprovalDate, ReleaseDate, WM_TRDate, WM_ReceivedDate, EWM_ConfirmedAt, GIDate, GINumber |
| GrpQuantities | QtyAvailCheck, QtyWithdrawn                                                         |
| GrpCustomer  | SoldToParty                                                                          |
