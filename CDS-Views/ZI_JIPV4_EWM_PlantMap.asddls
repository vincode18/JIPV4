@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIP V4 EWM Plant-to-Warehouse Mapping'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_PlantMap
  as select from /scwm/tmapstloc as TM
{
  key TM.plant    as Plant,
      TM.lgnum    as WarehouseNumber
}
