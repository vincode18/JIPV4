@AbapCatalog.sqlViewName: 'ZVCJIPV4AGN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Milestone Aging - OData V2 Consumption'
@VDM.viewType: #CONSUMPTION

@OData.publish: true

@Metadata.allowExtensions: true

@Analytics.dataCategory: #CUBE

define view ZC_JIPV4_AGING
  as select from ZI_JIPV4_PartsComposite
{
      -- === KEY FIELDS — skip aggregation ===
      @DefaultAggregation: #NONE
  key ReservationNumber,
      @DefaultAggregation: #NONE
  key ReservationItem,
  key ReservationCategory,

      -- === ID / DIMENSION FIELDS ===
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
      @DefaultAggregation: #NONE
      EquipmentNumber,

      WOCreationDate,

      -- === MEASURES — keep aggregation (SUM) for charts ===
      AgingRelease,

      @DefaultAggregation: #SUM
      RequirementQty,
      @DefaultAggregation: #SUM
      QtyAvailCheck,
      @DefaultAggregation: #SUM
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
      @DefaultAggregation: #SUM
      RecordCount,

      @DefaultAggregation: #SUM
      TargetAgingDays,

      -- Criticality (still in CDS — needed by MDE references)
      case AgingBucket
        when '70+' then 1
        when '60+' then 2
        else 3
      end as AgingCriticality
}
