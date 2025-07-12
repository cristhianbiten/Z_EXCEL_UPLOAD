@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View - Excel Data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_EXCEL_DATA_C
  as select from ztb_excel_data_c
  association to parent ZI_EXCEL_USER_C as _User on  $projection.EndUser = _User.EndUser
                                                 and $projection.FileId  = _User.FileId
{
  key end_user        as EndUser,
  key file_id         as FileId,
  key line_id         as LineId,
  key line_no         as LineNumber,
      po_number       as PoNumber,
      po_item         as PoItem,
      gr_quantity     as GrQuantity,
      unit_of_measure as UnitOfMeasure,
      site_id         as SiteId,
      header_text     as HeaderText,

      _User
}
