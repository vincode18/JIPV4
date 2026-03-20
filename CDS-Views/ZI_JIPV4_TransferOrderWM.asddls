@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 Classic WM Transfer Orders'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_TransferOrderWM
  as select from ltap as LP
  inner join ltak as LK on LP.lgnum = LK.lgnum and LP.tanum = LK.tanum
{
  key LP.lgnum                         as WarehouseNumber,
  key cast(LP.tanum as abap.char(10))  as TransferOrderNo,
  key cast(LP.tapos as abap.char(4))   as TransferOrderItem,
      LP.matnr    as MaterialNumber,
      LP.werks    as Plant,
      LP.tbpos    as RequirementItem,
      LK.bdatu    as TOCreationDate,
      LK.bwlvs    as MovementType,
      LP.qdatu    as ConfirmationDate
}
  