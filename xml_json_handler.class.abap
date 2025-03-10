CLASS z619_xml_json_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS: json_to_tab
      IMPORTING VALUE(lv_json) TYPE string
      CHANGING  ct_data        TYPE STANDARD TABLE, "ALL FIELDS Should be string convert them later

      xml_to_tab
        IMPORTING VALUE(lv_xml) TYPE string
        CHANGING  ct_data       TYPE STANDARD TABLE,
      tab_to_xml
        CHANGING ct_data TYPE STANDARD TABLE
                 cv_xml  TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z619_xml_json_handler IMPLEMENTATION.
  METHOD json_to_tab.
    DATA: ls_struct TYPE REF TO data.

    FIELD-SYMBOLS: <fs_structure> TYPE any,
                   <fs_field>     TYPE any,
                   <fs_table>     TYPE STANDARD TABLE.
    TRY.

        /iwbep/cl_sutil_xml_helper=>shift_json_to_table( EXPORTING iv_xdoc = cl_proxy_service=>cstring2xstring( lv_json )
                                                         IMPORTING et_data = DATA(lt_json_data) ).

        CREATE DATA ls_struct LIKE LINE OF ct_data.

        ASSIGN ls_struct->* TO <fs_structure>.

        ASSIGN ct_data TO <fs_table>.

        DATA(lt_components) = cl_hrpayat_gen_utility=>get_components_of_a_structure( im_structure = <fs_structure> ).

        DATA(lv_last_component) = VALUE #( lt_components[ lines( lt_components ) ]-name OPTIONAL ).

        LOOP AT lt_json_data INTO DATA(lv_json_line) WHERE tag_type = 'D'.
          TRANSLATE lv_json_line-tag_name TO UPPER CASE.
          ASSIGN COMPONENT lv_json_line-tag_name OF STRUCTURE <fs_structure> TO <fs_field>.
          IF sy-subrc = 0 AND <fs_field> IS ASSIGNED.
            IF lv_json_line-tag_value <> 'null'.
              <fs_field> = lv_json_line-tag_value.
            ENDIF.
          ENDIF.

          IF lv_json_line-tag_name = lv_last_component.
            APPEND <fs_structure> TO <fs_table>.
            ASSIGN ls_struct->* TO <fs_structure>.
          ENDIF.

        ENDLOOP.

      CATCH cx_root INTO DATA(lo_unkn).
        DATA(lv_msg) = lo_unkn->get_longtext(  ).
    ENDTRY.
  ENDMETHOD.
  METHOD xml_to_tab.
    DATA: ls_struct TYPE REF TO data.

    FIELD-SYMBOLS: <fs_structure> TYPE any,
                   <fs_field>     TYPE any,
                   <fs_table>     TYPE STANDARD TABLE.
    TRY.

        /iwbep/cl_sutil_xml_helper=>shift_xml_to_table( EXPORTING iv_xdoc = cl_proxy_service=>cstring2xstring( lv_xml )
                                                        IMPORTING et_data = DATA(lt_xml_data) ).

        CREATE DATA ls_struct LIKE LINE OF ct_data.

        ASSIGN ls_struct->* TO <fs_structure>.

        ASSIGN ct_data TO <fs_table>.

        DATA(lt_components) = cl_hrpayat_gen_utility=>get_components_of_a_structure( im_structure = <fs_structure> ).

        DATA(lv_last_component) = VALUE #( lt_components[ lines( lt_components ) ]-name OPTIONAL ).

        LOOP AT lt_xml_data INTO DATA(lv_xml_line) WHERE tag_type = 'D'.
          TRANSLATE lv_xml_line-tag_name TO UPPER CASE.
          ASSIGN COMPONENT lv_xml_line-tag_name OF STRUCTURE <fs_structure> TO <fs_field>.
          IF sy-subrc = 0 AND <fs_field> IS ASSIGNED.
            IF lv_xml_line-tag_value <> 'null'.
              <fs_field> = lv_xml_line-tag_value.
            ENDIF.
          ENDIF.

          IF lv_xml_line-tag_name = lv_last_component.
            APPEND <fs_structure> TO <fs_table>.
            ASSIGN ls_struct->* TO <fs_structure>.
          ENDIF.

        ENDLOOP.

      CATCH cx_root INTO DATA(lo_unkn).
        DATA(lv_msg) = lo_unkn->get_longtext(  ).
    ENDTRY.
  ENDMETHOD.

  METHOD tab_to_xml.
    CHECK ct_data IS NOT INITIAL.
    CALL TRANSFORMATION id SOURCE data = ct_data RESULT XML cv_xml OPTIONS xml_header = 'WITHOUT_ENCODING'.

  ENDMETHOD.

ENDCLASS.