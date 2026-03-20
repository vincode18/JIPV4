@AbapCatalog.sqlViewName: 'ZVIJIPWMAGG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WM Milestone Agg (1 row per Material)'
@VDM.viewType: #BASIC

define view ZI_JIPV4_WM_MilestoneAgg
  as select from ltap as LP
  inner join ltak as LK
    on  LP.lgnum = LK.lgnum
    and LP.tanum = LK.tanum
{
  key LP.werks                                  as Plant,
  key LP.matnr                                  as MaterialNumber,
  key LK.bwlvs                                 as MovementType,

      max(LP.lgnum)                             as WarehouseNumber,
      max(LK.bdatu)                             as TOCreationDate,
      max(LP.qdatu)                             as ConfirmationDate
}
where ( LK.bwlvs = '919' or LK.bwlvs = '920' or LK.bwlvs = '997' or LK.bwlvs = '994' )
group by
  LP.werks,
  LP.matnr,
  LK.bwlvs
