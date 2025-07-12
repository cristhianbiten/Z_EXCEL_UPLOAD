@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection Entity - Excel Data'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_EXCEL_DATA_C
  as projection on ZI_EXCEL_DATA_C
{
  key EndUser,
  key FileId,
  key LineId,
  key LineNumber,
      PoNumber,
      PoItem,
      GrQuantity,
      UnitOfMeasure,
      SiteId,
      HeaderText,
      /* Associations */
      _User : redirected to parent ZC_EXCEL_USER_C
}
