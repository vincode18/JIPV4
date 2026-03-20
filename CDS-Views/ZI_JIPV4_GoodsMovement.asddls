@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Goods Movements (Z26)'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_GoodsMovement
  as select from matdoc as MD
{
  key MD.mblnr                         as MaterialDocNumber,
  key MD.mjahr                         as MaterialDocYear,
  key MD.zeile                            as LineItem,
      MD.matnr                         as MaterialNumber,
      MD.werks                         as Plant,
      MD.bwart                         as MovementType,
      MD.aufnr                         as WorkOrderNumber,
      cast(MD.rsnum as abap.char(10))  as ReservationNumber,
      cast(MD.rspos as abap.char(4))   as ReservationItem,
      MD.menge    as Quantity,
      MD.meins    as BaseUnit,
      MD.budat    as PostingDate
}
where MD.bwart = 'Z26'
