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
  key AK.aufnr                         as WorkOrderNumber,
      AK.auart    as OrderType,
      AK.autyp    as OrderCategory,
      AK.erdat    as WOCreationDate,
      AK.werks    as Plant,
      AK.kdauf    as SalesOrderNumber,

      -- PM Header
      AI.ilart    as ActivityType,
      AI.equnr    as EquipmentNumber,

      -- ABC Indicator (via AFIH-ILOAN → ILOA)
      IL.abckz    as ABCIndicator,

      -- Release Date from AFKO-FTRMI
      AO.ftrmi    as WOReleaseDate,

      -- Approval Dates
      -- ZA.lvl2dt   as AppPDHDate,
      ZA.appr_date_lvl3   as AppSDHDate,

      -- Customer Info
      VB.kunnr    as SoldToParty
}
