@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EWM Product MATID to MATNR Mapping'
@VDM.viewType: #BASIC

define view entity ZI_JIPV4_EWM_ProductMap
  as select from /scwm/binmat as BM
{
  key BM.matid    as ProductGuid,
      BM.matnr    as MaterialNumber
}
