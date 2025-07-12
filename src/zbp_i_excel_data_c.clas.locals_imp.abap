CLASS lhc_ExcelData DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ExcelData RESULT result.

    METHODS processData FOR MODIFY
      IMPORTING keys FOR ACTION ExcelData~processData RESULT result.

ENDCLASS.

CLASS lhc_ExcelData IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD processData.
  ENDMETHOD.

ENDCLASS.
