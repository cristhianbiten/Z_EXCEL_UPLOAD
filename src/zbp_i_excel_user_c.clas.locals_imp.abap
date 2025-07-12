CLASS lhc_ExcelUser DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.

    TYPES: BEGIN OF gty_gr_xl,
             po_number       TYPE string,
             po_item         TYPE string,
             gr_quantity     TYPE string,
             unit_of_measure TYPE string,
             site_id         TYPE string,
             header_text     TYPE string,
             line_number     TYPE string, "Internal Use during Upload
             line_id         TYPE string, "Internal Use during Upload
           END OF gty_gr_xl.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ExcelUser RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE ExcelUser.

    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION ExcelUser~uploadExcelData RESULT result.

    METHODS FillFileStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ExcelUser~FillFileStatus.

    METHODS FillSelectedStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ExcelUser~FillSelectedStatus.

ENDCLASS.

CLASS lhc_ExcelUser IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entities>).

      APPEND CORRESPONDING #( <fs_entities> ) TO mapped-exceluser ASSIGNING FIELD-SYMBOL(<fs_exceluser>).

      <fs_exceluser>-EndUser = lv_user.

      IF <fs_exceluser>-FileId IS INITIAL.
        TRY.
            <fs_exceluser>-FileId = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
            "Do nothing Proceed to other entry
        ENDTRY.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD uploadExcelData.
  ENDMETHOD.

  METHOD FillFileStatus.
  ENDMETHOD.

  METHOD FillSelectedStatus.
  ENDMETHOD.

ENDCLASS.
