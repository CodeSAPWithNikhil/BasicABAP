REPORT z619_parallel.
TYPES: BEGIN OF ty_out.
TYPES: message TYPE string.
       INCLUDE TYPE zemp.
       TYPES: END OF ty_out.
CLASS cl_process DEFINITION INHERITING FROM cl_abap_parallel.
  PUBLIC SECTION.
    METHODS: do REDEFINITION.
ENDCLASS.

CLASS cl_process IMPLEMENTATION.

  METHOD do.

    DATA: lt_data TYPE TABLE OF zemp WITH EMPTY KEY,
          lt_out  TYPE TABLE OF ty_out.
    TRY.
        IMPORT im_data = lt_data FROM DATA BUFFER p_in.

        IF lt_data IS NOT INITIAL.
          MODIFY zemp FROM TABLE lt_data.
        ENDIF.
        lt_out = CORRESPONDING #( lt_data ).
        LOOP AT lt_out REFERENCE INTO DATA(lo_out).
          lo_out->message = 'Updated successfully'.
        ENDLOOP.
        WAIT UP TO 6 SECONDS.
        EXPORT out = lt_out TO DATA BUFFER p_out.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA: v_input        TYPE xstring,
        t_input        TYPE TABLE OF zemp WITH EMPTY KEY,
        lt_out         TYPE TABLE OF ty_out,
        t_combined_out TYPE TABLE OF ty_out,
        lv_total       TYPE sy-uzeit..
  TRY.
      DATA(o_processor) = NEW cl_process( p_num_tasks = 6 ).

      DATA(t_input_raw) = VALUE cl_abap_parallel=>t_in_tab(  ).

      t_input = VALUE #( ( empno = '100' deptno = '20' empname = 'Dummy1' )
                         ( empno = '200' deptno = '20' empname = 'Dummy2' )
                         ( empno = '300' deptno = '20' empname = 'Dummy3' ) ).

      EXPORT im_data = t_input TO DATA BUFFER v_input.
      APPEND v_input TO t_input_raw.
      CLEAR v_input.
      t_input = VALUE #( ( empno = '400' deptno = '20' empname = 'Dummy4' )
                         ( empno = '500' deptno = '20' empname = 'Dummy5' )
                         ( empno = '600' deptno = '20' empname = 'Dummy6' ) ).

      EXPORT im_data = t_input TO DATA BUFFER v_input.
      APPEND v_input TO t_input_raw.
      CLEAR v_input.
      t_input = VALUE #( ( empno = '700' deptno = '20' empname = 'Dummy7' )
                         ( empno = '800' deptno = '20' empname = 'Dummy8' )
                         ( empno = '900' deptno = '20' empname = 'Dummy9' ) ).

      EXPORT im_data = t_input TO DATA BUFFER v_input.
      APPEND v_input TO t_input_raw.
      CLEAR v_input.
      DELETE FROM zemp.
      DATA(lv_start) = sy-uzeit.
      o_processor->run( EXPORTING  p_in_tab  = t_input_raw
                        IMPORTING  p_out_tab = DATA(lt_out_xtr) ).


      LOOP AT lt_out_xtr INTO DATA(ls_out_xtr).
        IF ls_out_xtr IS NOT INITIAL.
          IMPORT out = lt_out FROM DATA BUFFER ls_out_xtr-result.
          APPEND LINES OF lt_out TO t_combined_out.
        ENDIF.
        CLEAR lt_out.
      ENDLOOP.
      DATA(lv_end) = sy-uzeit.
      lv_total = lv_end - lv_start.

      cl_demo_output=>display( t_combined_out ).
      WRITE : 'Started : ', lv_start.
      WRITE : 'Ended : ',lv_end.
      WRITE : 'Total duration : ', lv_total.
    CATCH cx_root INTO DATA(lo_dump).
      WRITE lo_dump->get_longtext( ).
  ENDTRY.
