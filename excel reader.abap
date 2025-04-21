CLASS cl_ehhss_bo_hsm_excel_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_cell_data,
        row    TYPE int4,
        column TYPE int4,
        value  TYPE string,
      END OF ty_cell_data .
    TYPES:
      tty_cell_data TYPE SORTED TABLE OF ty_cell_data WITH UNIQUE KEY row column .
    TYPES:
      BEGIN OF ty_sheet,
        sheet_name  TYPE string, "excel_sheet,
        cell_data   TYPE tty_cell_data,
        is_proteced TYPE abap_bool,
      END OF ty_sheet .
    TYPES:
      tty_sheet TYPE STANDARD TABLE OF ty_sheet WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_excel_data,
        sheet_name TYPE string,
        cell_data  TYPE tty_cell_data,
      END OF ty_excel_data .
    TYPES:
      tty_excel_data TYPE STANDARD TABLE OF ty_excel_data WITH DEFAULT KEY .

    METHODS create_excel
      IMPORTING
        !it_sheets           TYPE tty_sheet
      RETURNING
        VALUE(rv_excel_data) TYPE xstring
      RAISING
        cx_ehhss_bo_hsm_common .
    METHODS read_excel
      IMPORTING
        !iv_data             TYPE xstring
      RETURNING
        VALUE(rt_excel_data) TYPE tty_excel_data
      RAISING
        cx_ehhss_bo_hsm_common .
  PROTECTED SECTION.
    CONSTANTS:
      gc_encoding                 TYPE abap_encoding  VALUE 'UTF-8' ##NO_TEXT,
      gc_xmlheader                TYPE string VALUE '<?xml version="1.0" encoding="UTF-8"?>' ##NO_TEXT,
      gc_workbook_start           TYPE string VALUE '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' ##NO_TEXT,
      gc_workbook_end             TYPE string VALUE '</workbook>' ##NO_TEXT,
      gc_all_sheets_start         TYPE string VALUE '<sheets>' ##NO_TEXT,
      gc_all_sheets_end           TYPE string VALUE '</sheets>' ##NO_TEXT,
      gc_sheet_start              TYPE string VALUE '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' ##NO_TEXT,
      gc_sheet_end                TYPE string VALUE '</worksheet>' ##NO_TEXT,
      gc_sheet_data_start         TYPE string VALUE '<sheetData>' ##NO_TEXT,
      gc_sheet_data_end           TYPE string VALUE '</sheetData>' ##NO_TEXT,
      gc_row_end                  TYPE string VALUE '</row>' ##NO_TEXT,
      gc_sheet_protection         TYPE string VALUE '<sheetProtection scenarios="1" objects="1" sheet="1"/>' ##NO_TEXT,
      gc_sharedstring_start       TYPE string VALUE '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' ##NO_TEXT,
      gc_sharedstring_end         TYPE string VALUE '</sst>' ##NO_TEXT,
      gc_sharedstring_value_start TYPE string VALUE '<si><t>' ##NO_TEXT,
      gc_sharedstring_value_end   TYPE string VALUE '</t></si>' ##NO_TEXT.

    TYPES:
      BEGIN OF ty_xml_sharedstring,
        index TYPE i,
        value TYPE string,
      END OF ty_xml_sharedstring .
    TYPES:
      tty_xml_sharedstring TYPE SORTED TABLE OF ty_xml_sharedstring WITH UNIQUE KEY index.

    TYPES:
      BEGIN OF ty_xml_sheet,
        row   TYPE i,
        cell  TYPE string,
        type  TYPE string,
        index TYPE i,
        value TYPE string,
      END OF ty_xml_sheet.

    METHODS add_sheet
      IMPORTING
        iv_sheet_index       TYPE int4        "Starting at zero
        iv_name              TYPE string
        it_export_cells      TYPE tty_cell_data
        iv_sheet_protected   TYPE abap_bool DEFAULT abap_false
      CHANGING
        cr_workbook          TYPE REF TO cl_xlsx_workbookpart
        co_workbook_bin_conv TYPE REF TO cl_abap_conv_out_ce
        ct_shared_strings    TYPE tty_xml_sharedstring
      RAISING
        cx_openxml_format cx_openxml_not_found cx_openxml_not_allowed.

    METHODS create_sharedstring_xml
      IMPORTING
        it_shared_strings TYPE tty_xml_sharedstring
      CHANGING
        lr_workbook       TYPE REF TO cl_xlsx_workbookpart
      RAISING
        cx_openxml_not_allowed.

    METHODS beautify_excel
      CHANGING
        cr_excel_document TYPE REF TO cl_xlsx_document.

  PRIVATE SECTION.
    METHODS convert_int_to_string
      IMPORTING
        iv_int         TYPE i
      RETURNING
        VALUE(rv_char) TYPE string.

    METHODS convert_char_to_int
      IMPORTING
        iv_char       TYPE string
      RETURNING
        VALUE(rv_int) TYPE i.

    METHODS replace_string_symbols
      IMPORTING
        iv_char        TYPE string
      RETURNING
        VALUE(rv_char) TYPE  string.

ENDCLASS.



CLASS CL_EHHSS_BO_HSM_EXCEL_HANDLER IMPLEMENTATION.


  METHOD add_sheet.
    " Start Worksheet
    DATA lr_worksheet TYPE REF TO cl_xlsx_worksheetpart.
    DATA(lr_worksheet_parts) = cr_workbook->get_worksheetparts( ).

    IF lr_worksheet_parts IS BOUND.
      lr_worksheet ?= lr_worksheet_parts->get_part( iv_sheet_index ).
    ENDIF.

    IF lr_worksheet IS NOT BOUND.
      lr_worksheet = cr_workbook->add_worksheetpart( ).
    ENDIF.

    DATA(lo_bin_conv) = cl_abap_conv_out_ce=>create( encoding = gc_encoding ).
    lo_bin_conv->write( gc_xmlheader ).
    lo_bin_conv->write( gc_sheet_start ).

    lo_bin_conv->write( |<sheetViews>| ).
    lo_bin_conv->write( |<sheetView workbookViewId="0" tabSelected="0"/>| ).
    lo_bin_conv->write( |</sheetViews>| ).

    CASE iv_sheet_index.
      WHEN 0.
        lo_bin_conv->write( |<cols>| ).
        lo_bin_conv->write( |<col customWidth="1" width="20" max="2" min="1"/>| ).
        lo_bin_conv->write( |</cols>| ).
      WHEN 1.
        lo_bin_conv->write( |<cols>| ).
        lo_bin_conv->write( |<col customWidth="1" width="33" max="20" min="1"/>| ).
        lo_bin_conv->write( |</cols>| ).
    ENDCASE..

    lo_bin_conv->write( gc_sheet_data_start ).

    " Add Cells
    LOOP AT it_export_cells REFERENCE INTO DATA(rs_row) GROUP BY rs_row->row.
      lo_bin_conv->write( |<row r="{ rs_row->row }">| ).

      LOOP AT it_export_cells REFERENCE INTO DATA(rs_export_cell) WHERE row = rs_row->row.
        READ TABLE ct_shared_strings WITH KEY value = rs_export_cell->value INTO DATA(ls_shared_string).

        "add shared string if the value not found
        IF sy-subrc <> 0.
          DATA(lv_index) = lines( ct_shared_strings ). "Because index starts at zero
          DATA(ls_new_shared_string) = VALUE ty_xml_sharedstring( index = lv_index value = replace_string_symbols( rs_export_cell->value ) ).
          INSERT ls_new_shared_string INTO TABLE ct_shared_strings.
          ls_shared_string-index = lv_index.
        ENDIF.
        DATA(lv_column) = me->convert_int_to_string( iv_int = rs_export_cell->column ).
*        data(lv_string) = cond #( when iv_sheet_index = 0 and rs_export_cell->column = 1
*                            then |<c r="{ lv_column }{ rs_row->row }" s="1" t="s"><v>{ ls_shared_string-index }</v></c>|
*                            else  |<c r="{ lv_column }{ rs_row->row }" t="s"><v>{ ls_shared_string-index }</v></c>| ).
        DATA(lv_string) = |<c r="{ lv_column }{ rs_row->row }" t="s"><v>{ ls_shared_string-index }</v></c>|.
        lo_bin_conv->write( lv_string ).
      ENDLOOP.

      lo_bin_conv->write( gc_row_end ).
    ENDLOOP.

    " End Worksheet
    lo_bin_conv->write( gc_sheet_data_end ).

    IF iv_sheet_protected = abap_true.
      lo_bin_conv->write( gc_sheet_protection ).
    ENDIF.

    lo_bin_conv->write( gc_sheet_end ).
    lr_worksheet->feed_data( lo_bin_conv->get_buffer( ) ).

    DATA(lv_sheet_id) = iv_sheet_index + 1.
    co_workbook_bin_conv->write( |<sheet name="{ iv_name }" sheetId="{ lv_sheet_id }" r:id="rId{ lv_sheet_id }" />|  ).
  ENDMETHOD.


  METHOD beautify_excel.
    DATA ixml_factory TYPE REF TO if_ixml.
    DATA stream_factory TYPE REF TO if_ixml_stream_factory.
    DATA xml_document  TYPE REF TO if_ixml_document.

    TRY.
        ixml_factory = cl_ixml=>create( ).
        stream_factory = ixml_factory->create_stream_factory( ).

        DATA(istream) = stream_factory->create_istream_xstring( cr_excel_document->get_package_data( ) ).
        xml_document = ixml_factory->create_document( ).
        DATA(parser) = ixml_factory->create_parser( stream_factory = stream_factory istream = istream  document = xml_document ).


*        data(cell_element) = xml_document->create_attribute_ns( ).


      CATCH cx_openxml_not_found cx_openxml_format INTO DATA(open_xml_error).
    ENDTRY.
  ENDMETHOD.


  METHOD convert_char_to_int.
    DATA:
      lc_abc(26)  TYPE c VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      input       TYPE string,
      cc          TYPE c VALUE '',
      strl        TYPE i,
      cnt         TYPE i VALUE 0,
      ascii_val   TYPE i,
      ascii_val_a TYPE i.

*--> Just allow chars
    CHECK iv_char CO lc_abc.
    input = iv_char.

*--> Get int for char
    ascii_val_a = cl_abap_conv_out_ce=>uccp( 'A' ).
    TRANSLATE input TO UPPER CASE.
    strl = strlen( input ) - 1.

    WHILE strl >= 0.
      cc = input+cnt(1).
      ascii_val = cl_abap_conv_out_ce=>uccp( cc ).
      IF cc >= 'A' AND cc <= 'Z'.
        rv_int = rv_int + ( ascii_val - ascii_val_a + 1 ) * 26 ** strl .
        cnt = cnt + 1.
        strl = strl - 1 .
      ELSE.
        rv_int = 0.
        EXIT.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.


  METHOD convert_int_to_string.
    DATA:
      lv_frag       TYPE f,
      lv_input      TYPE i,
      lv_c_i_val    TYPE i,
      lv_cc         TYPE sychar02 VALUE '',
      lx_c_x_val(2) TYPE x.

    IF iv_int IS INITIAL OR iv_int < 1.
      EXIT.
    ENDIF.

    IF iv_int = 1.
      rv_char = 'A'.
      EXIT.
    ENDIF.

    rv_char = ''.
    lv_frag = iv_int.

    WHILE lv_frag > 1 .
      lv_input = floor( lv_frag ).
      lv_c_i_val = lv_input MOD 26.
      IF lv_c_i_val = 0.
        lv_c_i_val = 26.
        lv_input = lv_input - 25.
      ENDIF.
      lx_c_x_val = lv_c_i_val + cl_abap_conv_out_ce=>uccp( 'A' ) - 1.
      lv_cc = cl_abap_conv_in_ce=>uccp( lx_c_x_val ).
      rv_char = lv_cc && rv_char.
      lv_frag = lv_input / 26 .
    ENDWHILE.
  ENDMETHOD.


  METHOD create_excel.
    TRY.
        DATA(lo_bin_conv) = cl_abap_conv_out_ce=>create( encoding = gc_encoding ).
        DATA(lr_document) = cl_xlsx_document=>create_document( ).
        DATA(lt_sharedstrings) = VALUE tty_xml_sharedstring( ).

        " Start Workbook
        DATA(lr_workbook) = lr_document->get_workbookpart( ).
        lo_bin_conv->write( gc_xmlheader ).
        lo_bin_conv->write( gc_workbook_start ).
        lo_bin_conv->write( gc_all_sheets_start ).

        " Add Sheets
        LOOP AT it_sheets REFERENCE INTO DATA(ls_sheet).
          me->add_sheet(
            EXPORTING
              iv_sheet_index       = sy-tabix - 1 "Sheet Index starts at zero
              iv_name              = ls_sheet->sheet_name
              it_export_cells      = ls_sheet->cell_data
              iv_sheet_protected   = ls_sheet->is_proteced
            CHANGING
              cr_workbook          = lr_workbook
              co_workbook_bin_conv = lo_bin_conv
              ct_shared_strings    = lt_sharedstrings
          ).
        ENDLOOP.

        " End Workbook
        lo_bin_conv->write( gc_all_sheets_end ).
        lo_bin_conv->write( gc_workbook_end ).
        lr_workbook->feed_data( lo_bin_conv->get_buffer( )  ).

        " Add Shared Strings
        me->create_sharedstring_xml(
            EXPORTING
                it_shared_strings = lt_sharedstrings
          CHANGING
            lr_workbook = lr_workbook  ).

        rv_excel_data = lr_document->get_package_data( ).
      CATCH cx_openxml_format
          cx_openxml_not_found
          cx_openxml_not_allowed
          cx_sy_codepage_converter_init
          cx_sy_conversion_codepage
          cx_parameter_invalid_type
          cx_parameter_invalid_range
      .
        RAISE EXCEPTION TYPE cx_ehhss_bo_hsm_common
          EXPORTING
            textid = cx_mdq_rulemgmt_data_exchange=>cx_excel_file_cant_be_created.
    ENDTRY.
  ENDMETHOD.


  METHOD create_sharedstring_xml.
    DATA(lo_bin_conv) = cl_abap_conv_out_ce=>create( encoding = gc_encoding ).

    TRY.
        DATA(lr_shared_strings) = lr_workbook->get_sharedstringspart( ).
      CATCH cx_openxml_not_found cx_openxml_format.
        lr_shared_strings = lr_workbook->add_sharedstringspart( ).
    ENDTRY.

    lo_bin_conv->write( gc_xmlheader ).
    lo_bin_conv->write( gc_sharedstring_start ).

    LOOP AT it_shared_strings REFERENCE INTO DATA(rs_shared_string).
      lo_bin_conv->write( gc_sharedstring_value_start ).
      lo_bin_conv->write( rs_shared_string->value ).
      lo_bin_conv->write( gc_sharedstring_value_end ).
    ENDLOOP.

    lo_bin_conv->write( gc_sharedstring_end ).
    lr_shared_strings->feed_data( lo_bin_conv->get_buffer( ) ).
  ENDMETHOD.


  METHOD read_excel.
    DATA:
      lo_worksheet        TYPE REF TO cl_xlsx_worksheetpart,
      lo_part             TYPE REF TO cl_openxml_part,
      lv_index_sheet      TYPE i VALUE 1,
      lt_xml_sheet        TYPE STANDARD TABLE OF ty_xml_sheet,
      ls_xml_sheet        TYPE ty_xml_sheet,
      ls_xml_sharedstring TYPE ty_xml_sharedstring,
      lt_xml_sharedstring TYPE tty_xml_sharedstring,
      lv_row_str          TYPE string,
      lv_cell             TYPE string,
      ls_cell_data        TYPE ty_cell_data,
      lt_cell_data        TYPE tty_cell_data.

    TRY.
        DATA(lo_xlsx)        = cl_xlsx_document=>load_document( iv_data ).
        DATA(lo_workbook)    = lo_xlsx->get_workbookpart( ).
        DATA(lo_collection)  = lo_workbook->get_worksheetparts( ).
        DATA(lv_count_sheet) = lo_collection->get_count( ).

        "Loop at all excel sheets
        WHILE lv_index_sheet <= lv_count_sheet.
          CLEAR lt_xml_sheet.
          CLEAR lt_cell_data.
          CLEAR lt_xml_sharedstring.
          CLEAR ls_xml_sharedstring.

          lo_worksheet ?= lo_workbook->get_part_by_id( |rId{ lv_index_sheet }| ) ##NO_TEXT.
          IF lo_worksheet IS BOUND.
            "Create Excel sheet parser
            DATA(lo_ixml_factory)  = cl_ixml=>create( ).
            DATA(lo_streamfactory) = lo_ixml_factory->create_stream_factory( ).
            DATA(lo_stream)        = lo_streamfactory->create_istream_xstring( lo_worksheet->get_data( ) ).
            DATA(lo_document)      = lo_ixml_factory->create_document( ).
            DATA(lo_parser)        = lo_ixml_factory->create_parser( stream_factory = lo_streamfactory
                                                                     istream        = lo_stream
                                                                     document       = lo_document ).
            IF lo_parser->parse( ) NE 0.
*              raise exception unsupported_format
            ENDIF.

            DATA(lo_ref_ixml_elem) = lo_document->get_root_element( ).
            DATA(lo_nodes)         = lo_ref_ixml_elem->get_elements_by_tag_name( name = 'row' ) ##NO_TEXT.
            DATA(lo_node_iterator) = lo_nodes->create_iterator( ).
            DATA(lo_node)          = lo_node_iterator->get_next( ).

            "Loop at rows of current sheet
            WHILE lo_node IS NOT INITIAL.
              DATA(lo_att)           = lo_node->get_attributes( ).
              ls_xml_sheet-row = lo_att->get_named_item( 'r' )->get_value( ) ##NO_TEXT.

              DATA(lo_node_iterator_r) = lo_node->get_children( )->create_iterator( ).
              DATA(lo_node_r)          = lo_node_iterator_r->get_next( ).

              "Loop at cells of current row
              WHILE lo_node_r IS NOT INITIAL AND lo_node_r IS BOUND.
                lo_att            = lo_node_r->get_attributes( ).
                ls_xml_sheet-cell = lo_att->get_named_item( 'r' )->get_value( ) ##NO_TEXT.

                DATA(lo_att_child) = lo_att->get_named_item( 't' ) ##NO_TEXT.
                IF lo_att_child IS BOUND.
                  ls_xml_sheet-type = lo_att_child->get_value( ).
                ENDIF.

                ls_xml_sheet-value = lo_node_r->get_value( ).

                APPEND ls_xml_sheet TO lt_xml_sheet.
                CLEAR: ls_xml_sheet-cell,
                       ls_xml_sheet-type,
                       ls_xml_sheet-index.
                lo_node_r = lo_node_iterator_r->get_next( ).
              ENDWHILE.
              lo_node = lo_node_iterator->get_next( ).
            ENDWHILE.
          ENDIF.

          "Read shared string (only once)
          IF lt_xml_sharedstring IS INITIAL.
            DATA(lo_sharedstring)  = lo_workbook->get_sharedstringspart( ).
            IF lo_sharedstring IS BOUND.
              lo_ixml_factory  = cl_ixml=>create( ).
              lo_streamfactory = lo_ixml_factory->create_stream_factory( ).
              lo_stream        = lo_streamfactory->create_istream_xstring( lo_sharedstring->get_data( ) ).
              lo_document      = lo_ixml_factory->create_document( ).
              lo_parser        = lo_ixml_factory->create_parser( stream_factory = lo_streamfactory
                                                                 istream        = lo_stream
                                                                 document       = lo_document ).

              IF lo_parser->parse( ) NE 0.
*              raise exception
              ENDIF.

              lo_ref_ixml_elem = lo_document->get_root_element( ).
              lo_nodes         = lo_ref_ixml_elem->get_elements_by_tag_name( name = 'si' ) ##NO_TEXT.
              lo_node_iterator = lo_nodes->create_iterator( ).
              lo_node = lo_node_iterator->get_next( ).
              sy-tabix = 0.
              WHILE lo_node IS NOT INITIAL.
                ls_xml_sharedstring = VALUE #( index = sy-tabix value = lo_node->get_value( ) ).
                APPEND ls_xml_sharedstring TO lt_xml_sharedstring.
                lo_node = lo_node_iterator->get_next( ).
              ENDWHILE.
            ENDIF.
          ENDIF.

          LOOP AT lt_xml_sheet INTO ls_xml_sheet.
            ls_cell_data-row  = ls_xml_sheet-row.
            "get column index
            lv_cell = ls_xml_sheet-cell.
            lv_row_str = ls_cell_data-row.
            CONDENSE lv_row_str NO-GAPS.
            REPLACE lv_row_str IN lv_cell WITH space.
            ls_cell_data-column = convert_char_to_int( lv_cell ).
            lv_row_str         = ls_cell_data-row.

            IF ls_xml_sheet-type EQ 's' ##NO_TEXT.
              READ TABLE lt_xml_sharedstring INTO ls_xml_sharedstring
              WITH KEY index = ls_xml_sheet-value BINARY SEARCH.
              IF sy-subrc EQ 0.
                ls_cell_data-value = ls_xml_sharedstring-value.
              ENDIF.
            ELSE.
              ls_cell_data-value = ls_xml_sheet-value.
            ENDIF.
            INSERT ls_cell_data INTO TABLE lt_cell_data.
          ENDLOOP.

          rt_excel_data = VALUE #( BASE rt_excel_data ( sheet_name = lv_index_sheet
                                                        cell_data      = lt_cell_data ) ).

          lv_index_sheet = lv_index_sheet + 1.
        ENDWHILE.

      CATCH cx_openxml_not_found cx_openxml_format.
        RAISE EXCEPTION TYPE cx_ehhss_bo_hsm_common
          EXPORTING
            textid = cx_mdq_rulemgmt_data_exchange=>cx_excel_file_cannot_be_read.
    ENDTRY.
  ENDMETHOD.


  METHOD replace_string_symbols.
    CLEAR rv_char.
    rv_char = iv_char.
    REPLACE ALL OCCURRENCES OF '&' IN rv_char WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_char WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_char WITH '&gt;'.
  ENDMETHOD.
ENDCLASS.