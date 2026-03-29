# CDS View SQL Console Test Queries

Replace `'BJM'` with your plant code. Run each query in SAP SQL Console.

---

```sql
/SCWM/ORDIM_C
TANUM = 300198

===EWM WO
WO: 51362354
WT: 300198
WHO Created : 300000159
I:ZSTP:000 WHO Created : 300000160
I:ZSTP:000 WHO Created : 300000162


===WM CLASSIC
WO: 51365300
TR Created : 0000414378
TO : 1565450

TR Created : 0000414375
TO: 1565447
GI: M7 060 4928000136 2026
```

## Test 1 — ZI_JIPV4_Reservation

```sql
SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  RequirementQty
FROM ZI_JIPV4_Reservation
WHERE Plant = 'BJM'
ORDER BY ReservationNumber DESC
```

---

## Test 2 — ZI_JIPV4_WorkOrder

```sql
SELECT
  WorkOrderNumber,
  OrderType,
  ABCIndicator,
  WOReleaseDate,
  AppSDHDate
FROM ZI_JIPV4_WorkOrder
WHERE Plant = 'BJM'
ORDER BY WOCreationDate DESC
```
````
SELECT
  WorkOrderNumber
FROM ZI_JIPV4_WorkOrder
WHERE WorkOrderNumber = '000051365300'
ORDER BY WOCreationDate 
````
---

## Test 3 — ZI_JIPV4_TransferOrderWM

```sql
SELECT
  TransferOrderNo,
  MaterialNumber,
  ConfirmationDate
FROM ZI_JIPV4_TransferOrderWM
WHERE Plant = 'BJM'
ORDER BY TOCreationDate DESC
```

---

## Test 4 — ZI_JIPV4_GoodsMovement

```sql
-- Debug 1: Check raw matdoc for this MBLNR
SELECT mblnr, mjahr, bwart, aufnr, matnr, budat, cancelled
FROM matdoc
WHERE mblnr = '4928000136'
```

```sql
-- Debug 2: Search CDS by MBLNR only (no other filters)
SELECT MaterialDocNumber, MaterialDocYear, PostingDate, MovementType, WorkOrderNumber
FROM ZI_JIPV4_GoodsMovement
WHERE MaterialDocNumber = '4928000136'
```

```sql
-- Debug 3: Track all GI for Work Order
SELECT MaterialDocNumber, MaterialNumber, WorkOrderNumber, PostingDate, ReservationNumber, ReservationItem
FROM ZI_JIPV4_GoodsMovement
WHERE WorkOrderNumber = '000051365300'
ORDER BY PostingDate
```

---

## Test 5 — ZI_JIPV4_EWM_ProductMap (via MARA.SCM_MATID_GUID16)

```sql
SELECT
  ProductGuid,
  MaterialNumber
FROM ZI_JIPV4_EWM_ProductMap
LIMIT 50
```

```sql
SELECT
  ProductGuid,
  MaterialNumber
FROM ZI_JIPV4_EWM_ProductMap
WHERE MaterialNumber = '02896-11008'
```

```sql
-- Verify mapping: cross-check MARA.SCM_MATID_GUID16 vs /SCWM/ORDIM_C.MATID
SELECT
  MA.matnr,
  MA.scm_matid_guid16,
  WT.matid,
  WT.tanum
FROM mara AS MA
INNER JOIN /scwm/ordim_c AS WT
  ON MA.scm_matid_guid16 = WT.matid
WHERE MA.matnr = '02896-11008'
LIMIT 10
```

---

## Test 6 — ZI_JIPV4_EWM_WarehouseTask

```sql
SELECT
  WarehouseTaskNo,
  MaterialNumber,
  JipMilestone,
  IsConfirmed
FROM ZI_JIPV4_EWM_WarehouseTask
WHERE IsConfirmed = 'X'
LIMIT 50
```

```sql
SELECT
  WarehouseTaskNo,
  ProductGuid,
  ProcessType,
  JipMilestone,
  ConfirmedAt,
  Quantity,
  UnitOfMeasure
FROM ZI_JIPV4_EWM_WarehouseTask
WHERE WarehouseTaskNo = '000000300198'
```

---

## Test 7 — ZI_JIPV4_EWM_PlantMap

```sql
SELECT
  Plant,
  StorageLocation,
  WarehouseNumber
FROM ZI_JIPV4_EWM_PlantMap
WHERE Plant = 'BJM'
```

---

## Test 8 — ZI_JIPV4_PartsComposite

```sql
SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  WmEwmType,
  CurrentMilestone,
  AgingBucket
FROM ZI_JIPV4_PartsComposite
WHERE Plant = 'BJM'
ORDER BY ReservationNumber DESC
```

```sql
SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  WmEwmType,
  CurrentMilestone,
  AgingBucket,
  WarehouseNumber,
  GINumber
FROM ZI_JIPV4_PartsComposite
WHERE WorkOrderNumber = '000051365300'
-- OR WorkOrderNumber = '000050717695'

SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  WmEwmType,
  CurrentMilestone,
  AgingBucket,
  WarehouseNumber,
  GINumber
FROM ZI_JIPV4_PartsComposite
WHERE WorkOrderNumber = '000050717695'
```

---

## Test 9 — ZC_JIPV4_AGING

```sql
SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  CurrentMilestone,
  AgingBucket,
  AgingCriticality
FROM ZC_JIPV4_AGING
WHERE Plant = 'BJM'
ORDER BY AgingBucket DESC
```

```sql
SELECT
  ReservationNumber,
  WorkOrderNumber,
  MaterialNumber,
  CurrentMilestone,
  AgingBucket,
  AgingCriticality,
  GINumber,
  GIDate,
  Plant
FROM ZC_JIPV4_AGING
WHERE GINumber = '4928000136'
  AND MaterialNumber = '02896-11008'
```

---

## Test 10 — CurrentAging Field Verification (Card 08)

Verify `CurrentAging` returns 6 days for WO 51365300 / material 600-211-1231 (NPB milestone).

```sql
SELECT
  WorkOrderNumber,
  MaterialNumber,
  Plant,
  WmEwmType,
  CurrentMilestone,
  CurrentAging
FROM ZI_JIPV4_PartsComposite
WHERE WorkOrderNumber = '0000 '
```

```sql
SELECT
  WorkOrderNumber,
  MaterialNumber,
  Plant,
  WmEwmType,
  CurrentMilestone,
  CurrentAging,
  AgingBucket
FROM ZC_JIPV4_AGING
WHERE WorkOrderNumber = '000051365300'
```

Expected result: `CurrentAging = 6`, `CurrentMilestone = NPB`
