@AbapCatalog.sqlViewName: 'ZVIJIPEWMAGG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EWM Milestone Agg (1 row per Material)'
@VDM.viewType: #BASIC

define view ZI_JIPV4_EWM_MilestoneAgg
  as select from /scwm/ordim_c as WT
  inner join /scwm/binmat as BM
    on WT.matid = BM.matid
{
  key BM.matnr                              as MaterialNumber,
  key WT.procty                             as ProcessType,

      -- Latest confirmed timestamp per process type
      max(WT.confirmed_at)                  as ConfirmedAt,

      -- Warehouse number (for reference)
      max(WT.lgnum)                         as WarehouseNumber
}
where ( WT.procty = 'S919' or WT.procty = 'S920' or WT.procty = 'S997' or WT.procty = 'S994' )
  and WT.confirmed_at is not initial
group by
  BM.matnr,
  WT.procty
