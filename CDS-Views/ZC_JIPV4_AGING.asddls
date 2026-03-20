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
      -- === KEY FIELDS — skip aggregation ===
      @DefaultAggregation: #NONE
  key ReservationNumber,
      @DefaultAggregation: #NONE
  key ReservationItem,
  key ReservationCategory,

      -- === ID / DIMENSION FIELDS — skip aggregation ===
      @DefaultAggregation: #NONE
      WorkOrderNumber,
      @DefaultAggregation: #NONE
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
      @DefaultAggregation: #NONE
      EquipmentNumber,

      WOCreationDate,

      -- === MEASURES — keep aggregation (SUM) for charts ===
      AgingRelease,

      @DefaultAggregation: #NONE
      RequirementQty,
      @DefaultAggregation: #NONE
      QtyAvailCheck,
      @DefaultAggregation: #NONE
      QtyWithdrawn,

      SDHApprovalDate,
      ReleaseDate,
      WM_TRDate,
      WM_ReceivedDate,
      @DefaultAggregation: #NONE
      EWM_ConfirmedAt,
      GIDate,
      @DefaultAggregation: #NONE
      GINumber,

      PeriodMonth,
      PeriodYear,

      -- === MEASURES — keep aggregation (SUM) for charts ===
      RecordCount,

      TargetAgingDays,

      -- Criticality (still in CDS — needed by MDE references)
      case AgingBucket
        when '70+' then 1
        when '60+' then 2
        else 3
      end as AgingCriticality
}
