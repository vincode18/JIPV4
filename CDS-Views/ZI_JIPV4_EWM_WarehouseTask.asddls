@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Warehouse Tasks Confirmed'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_WarehouseTask
  as select from /scwm/ordim_c as WT
{
  key WT.lgnum                              as WarehouseNumber,
  key cast(WT.tanum as abap.char(20))       as WarehouseTaskNo,
  key cast(WT.tapos as abap.char(4))        as TaskPosition,

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
      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
      WT.nistm                              as Quantity,
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
