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
    DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lt_excel        TYPE STANDARD TABLE OF gty_gr_xl,
          lt_data         TYPE TABLE FOR CREATE zi_excel_user_c\_Data,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lv_content      TYPE string,
          lv_index        TYPE sy-index.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    READ ENTITIES OF zi_excel_user_c IN LOCAL MODE
    ENTITY ExcelUser
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-attachment.
    CHECK lv_attachment IS NOT INITIAL.

    "Move Excel Data to Internal Table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content( iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select( lo_selection_pattern )->row_stream( )->operation->write_to( REF #( lt_excel ) ).
    lo_execute->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    "Get number of columns in upload file for validation
    TRY.
        lo_table_descr  = CAST #( cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ) ).
        lo_struct_descr = CAST #( lo_table_descr->get_table_line_type( ) ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        "Implement error handling
    ENDTRY.

    "Validate Header record
    DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
    IF ls_excel IS NOT INITIAL.

      DO lv_no_of_cols TIMES.
        lv_index = sy-index.

        ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO FIELD-SYMBOL(<fs_col_header>).
        CHECK <fs_col_header> IS ASSIGNED.

        DATA(lv_value) = to_upper( <fs_col_header> ).
        DATA(lv_has_error) = abap_false.

        CASE lv_index.
          WHEN 1.
            lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
          WHEN 2.
            lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
          WHEN 3.
            lv_has_error = COND #( WHEN lv_value <> 'GR QUANTITY' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'UNIT OF MEASURE' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
          WHEN 6.
            lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
          WHEN 9. "More than 7 columns (error)
            lv_has_error = abap_true.
        ENDCASE.

        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-exceluser.
          APPEND VALUE #( %tky     = lt_file_entity[ 1 ]-%tky
                          %msg     = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Wrong File Format!!' ) ) TO reported-exceluser.
          UNASSIGN <fs_col_header>.
          EXIT.
        ENDIF.

        UNASSIGN <fs_col_header>.
      ENDDO.

    ENDIF.

    CHECK lv_has_error = abap_false.

    DELETE lt_excel INDEX 1.
    DELETE lt_excel WHERE po_number IS INITIAL.

    "Fill Line ID / Line Number
    TRY.
        DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.
    LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
      <lfs_excel>-line_id     = lv_line_id.
      <lfs_excel>-line_number = sy-tabix.
    ENDLOOP.

    "Prepare Data for  Child Entity (ExcelData)
    lt_data = VALUE #(
        (   %cid_ref  = keys[ 1 ]-%cid_ref
            %is_draft = keys[ 1 ]-%is_draft
            EndUser   = keys[ 1 ]-EndUser
            FileId    = keys[ 1 ]-FileId
            %target   = VALUE #(
                FOR ls_excel_aux IN lt_excel (
                    %cid         = keys[ 1 ]-%cid_ref
                    %is_draft    = keys[ 1 ]-%is_draft
                    %data = VALUE #(
                        EndUser         = keys[ 1 ]-EndUser
                        FileId          = keys[ 1 ]-FileId
                        LineId          = ls_excel_aux-line_id
                        LineNumber      = ls_excel_aux-line_number
                        PoNumber        = ls_excel_aux-po_number
                        PoItem          = ls_excel_aux-po_item
                        GrQuantity      = ls_excel_aux-gr_quantity
                        UnitOfMeasure   = ls_excel_aux-unit_of_measure
                        SiteId          = ls_excel_aux-site_id
                        HeaderText      = ls_excel_aux-header_text
                    )
                    %control = VALUE #(
                        EndUser         = if_abap_behv=>mk-on
                        FileId          = if_abap_behv=>mk-on
                        LineId          = if_abap_behv=>mk-on
                        LineNumber      = if_abap_behv=>mk-on
                        PoNumber        = if_abap_behv=>mk-on
                        PoItem          = if_abap_behv=>mk-on
                        GrQuantity      = if_abap_behv=>mk-on
                        UnitOfMeasure   = if_abap_behv=>mk-on
                        SiteId          = if_abap_behv=>mk-on
                        HeaderText      = if_abap_behv=>mk-on
                    )
                )
            )
        )
    ).

    "Delete Existing entry for user if any
    READ ENTITIES OF zi_excel_user_c IN LOCAL MODE
    ENTITY ExcelUser BY \_Data
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_existing_data).
    IF lt_existing_data IS NOT INITIAL.

      MODIFY ENTITIES OF zi_excel_user_c IN LOCAL MODE
      ENTITY ExcelData DELETE FROM VALUE #(
        FOR ls_data IN lt_existing_data (
          %key        = ls_data-%key
          %is_draft   = ls_data-%is_draft
        )
      )
      MAPPED DATA(lt_del_mapped)
      REPORTED DATA(lt_del_reported)
      FAILED DATA(lt_del_failed).

    ENDIF.

    "Add New Entry for ExcelData (association)
    MODIFY ENTITIES OF zi_excel_user_c IN LOCAL MODE
    ENTITY ExcelUser CREATE BY \_Data
    AUTO FILL CID WITH lt_data.

    "Modify Status
    MODIFY ENTITIES OF zi_excel_user_c IN LOCAL MODE
    ENTITY ExcelUser
    UPDATE FROM VALUE #(  ( %tky                = lt_file_entity[ 1 ]-%tky
                            FileStatus          = 'File Uploaded'
                            %control-FileStatus = if_abap_behv=>mk-on ) )
    MAPPED DATA(lt_upd_mapped)
    FAILED DATA(lt_upd_failed)
    REPORTED DATA(lt_upd_reported).

    "Read Updated Entry
    READ ENTITIES OF zi_excel_user_c IN LOCAL MODE
    ENTITY ExcelUser ALL FIELDS WITH CORRESPONDING #( Keys )
    RESULT DATA(lt_updated_user).

    "Send Status back to front end
    result = VALUE #(
      FOR ls_upd_head IN lt_updated_user (
        %tky    = ls_upd_head-%tky
        %param  = ls_upd_head
      )
    ).
  ENDMETHOD.

  METHOD FillFileStatus.
    "Read the data to be modified to get the transactional keys (%tky)
    READ ENTITIES OF zi_excel_user_c IN LOCAL MODE
      ENTITY ExcelUser FIELDS ( FileStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_user).

    "Exit if no data was found
    CHECK lt_user IS NOT INITIAL.

    "Update the File Status for all entries in a single operation
    MODIFY ENTITIES OF zi_excel_user_c IN LOCAL MODE
      ENTITY ExcelUser
      UPDATE FIELDS ( FileStatus )
      WITH VALUE #( FOR ls_user IN lt_user (
          %tky                = ls_user-%tky
          %data-FileStatus    = 'File Not Selected'
          %control-FileStatus = if_abap_behv=>mk-on
      ) ).
  ENDMETHOD.

  METHOD FillSelectedStatus.
    " 1. Read parent (ExcelUser) and child (ExcelData) entities in a single call
    READ ENTITIES OF zi_excel_user_c IN LOCAL MODE
      ENTITY ExcelUser
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_user)
      ENTITY ExcelUser BY \_Data
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_data).

    " 2. Delete existing child data (if any)
    " This part is already efficient.
    IF lt_data IS NOT INITIAL.
      MODIFY ENTITIES OF zi_excel_user_c IN LOCAL MODE
        ENTITY ExcelData DELETE FROM VALUE #(
          FOR ls_data IN lt_data (
            %key      = ls_data-%key
            %is_draft = ls_data-%is_draft
          )
        ).
    ENDIF.

    " 3. Update the parent entity's status in a single, mass operation
    " Exit if no parent data was read.
    CHECK lt_user IS NOT INITIAL.

    MODIFY ENTITIES OF zi_excel_user_c  IN LOCAL MODE
      ENTITY ExcelUser
      UPDATE FIELDS ( FileStatus )
      WITH VALUE #(
        FOR ls_user IN lt_user (
          %tky                = ls_user-%tky
          %data-FileStatus    = COND #( WHEN ls_user-Attachment IS INITIAL
                                        THEN 'File Not Selected'
                                        ELSE 'File Selected' )
          %control-FileStatus = if_abap_behv=>mk-on
        )
      ).
  ENDMETHOD.

ENDCLASS.
