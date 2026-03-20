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

  -- ========== WM PATH (aggregated — 1 row per Plant+Material+MovementType) ==========
  -- 919 = TR_REQUEST, 997 = RECEIVED, 994 = NPB

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_TR
    on  Resv.Plant             = WM_TR.Plant
    and Resv.MaterialNumber    = WM_TR.MaterialNumber
    and WM_TR.MovementType     = '919'

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_RCV
    on  Resv.Plant             = WM_RCV.Plant
    and Resv.MaterialNumber    = WM_RCV.MaterialNumber
    and WM_RCV.MovementType    = '997'

  left outer join ZI_JIPV4_WM_MilestoneAgg as WM_NPB
    on  Resv.Plant             = WM_NPB.Plant
    and Resv.MaterialNumber    = WM_NPB.MaterialNumber
    and WM_NPB.MovementType    = '994'

  -- ========== EWM PATH (aggregated — 1 row per Material+ProcessType) ==========
  -- S919 = TR_REQUEST, S997 = RECEIVED, S994 = NPB

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_TR
    on  Resv.MaterialNumber    = EWM_TR.MaterialNumber
    and EWM_TR.ProcessType     = 'S919'

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_RCV
    on  Resv.MaterialNumber    = EWM_RCV.MaterialNumber
    and EWM_RCV.ProcessType    = 'S997'

  left outer join ZI_JIPV4_EWM_MilestoneAgg as EWM_NPB
    on  Resv.MaterialNumber    = EWM_NPB.MaterialNumber
    and EWM_NPB.ProcessType    = 'S994'

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
      WM_RCV.ConfirmationDate                 as WM_ReceivedDate,
      WM_NPB.ConfirmationDate                 as WM_NPBDate,

      -- ========== MILESTONE DATES — EWM PATH ==========
      EWM_TR.ConfirmedAt                      as EWM_TRConfirmedAt,
      EWM_RCV.ConfirmedAt                     as EWM_RCVConfirmedAt,
      EWM_NPB.ConfirmedAt                     as EWM_NPBConfirmedAt,

      -- Consolidated EWM confirmed date (for backward compatibility with MDE)
      coalesce(EWM_NPB.ConfirmedAt, coalesce(EWM_RCV.ConfirmedAt, EWM_TR.ConfirmedAt))
                                               as EWM_ConfirmedAt,

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
