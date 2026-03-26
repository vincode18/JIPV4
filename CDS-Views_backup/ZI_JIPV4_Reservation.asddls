@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Reservation Items'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_Reservation
  as select from resb
{
  key cast(rsnum as abap.char(10))  as ReservationNumber,
  key cast(rspos as abap.char(4))   as ReservationItem,
  key rsart                         as ReservationCategory,
      aufnr                         as WorkOrderNumber,
      matnr                         as MaterialNumber,
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
