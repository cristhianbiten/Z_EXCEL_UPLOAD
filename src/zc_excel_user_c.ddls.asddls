@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection Entity - Excel User'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_EXCEL_USER_C
  provider contract transactional_query
  as projection on ZI_EXCEL_USER_C
{
  key EndUser,
  key FileId,
      FileStatus,
      @Semantics.largeObject:
          { mimeType: 'Mimetype',
          fileName: 'Filename',
          acceptableMimeTypes: [ 'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ],
          contentDispositionPreference: #INLINE }
      Attachment,
      Mimetype,
      Filename,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _Data : redirected to composition child ZC_EXCEL_DATA_C
}
