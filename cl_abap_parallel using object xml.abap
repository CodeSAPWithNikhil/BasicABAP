REPORT z619_parallel_proc2.
TYPES: tt_emp TYPE TABLE OF zemp WITH EMPTY KEY.
CLASS lcl_processor DEFINITION
INHERITING FROM cl_abap_parallel.

  PUBLIC SECTION.
    INTERFACES: if_serializable_object.
    METHODS: constructor
      IMPORTING it_emp          TYPE tt_emp OPTIONAL
                p_num_tasks     TYPE i DEFAULT 8
                p_timeout       TYPE i DEFAULT 200
                p_percentage    TYPE i DEFAULT 50
                p_num_processes TYPE i DEFAULT 20
                p_local_server  TYPE abap_bool OPTIONAL,
      get_data
        RETURNING VALUE(rt_emp) TYPE tt_emp,

      set_message
        IMPORTING VALUE(iv_msg) TYPE string,
      get_message
        RETURNING VALUE(rv_msg) TYPE string,
      do REDEFINITION.

    CLASS-METHODS: transform_object_to_xml
      IMPORTING io_object     TYPE REF TO object
      RETURNING VALUE(rv_xml) TYPE xstring,

      transform_xml_to_object
        IMPORTING iv_xml           TYPE xstring
        RETURNING VALUE(ro_object) TYPE REF TO object.
  PRIVATE SECTION.
    DATA: gt_emp     TYPE tt_emp,
          gv_message TYPE string.
ENDCLASS.

CLASS lcl_processor IMPLEMENTATION.

  METHOD constructor.
    super->constructor(  p_num_tasks     =  p_num_tasks
                         p_timeout       =  p_timeout
                         p_percentage    =  p_percentage
                         p_num_processes =  p_num_processes
                         p_local_server  =  p_local_server ).
    me->gt_emp = it_emp.
  ENDMETHOD.

  METHOD do.
    DATA lo_thread TYPE REF TO lcl_processor.
    lo_thread ?= lcl_processor=>transform_xml_to_object( p_in ).

    IF lo_thread IS BOUND.
      DATA(lt_emp_to_be_updated) = lo_thread->get_data(  ).
      IF lt_emp_to_be_updated IS NOT INITIAL.
        MODIFY zemp FROM TABLE lt_emp_to_be_updated.
        lo_thread->set_message( 'Data updated' ).
        WAIT UP TO 2 SECONDS.
      ELSE.
        lo_thread->set_message( 'Data update failed' ).
      ENDIF.
      CALL TRANSFORMATION id
     SOURCE model = lo_thread
     RESULT XML p_out.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    rt_emp = gt_emp.
  ENDMETHOD.

  METHOD set_message.
    gv_message = iv_msg.
  ENDMETHOD.

  METHOD get_message.
    rv_msg = gv_message.
  ENDMETHOD.

  METHOD transform_object_to_xml.
    CHECK io_object IS BOUND.
    CALL TRANSFORMATION id
     SOURCE model = io_object
     RESULT XML rv_xml.
  ENDMETHOD.

  METHOD transform_xml_to_object.
    CALL TRANSFORMATION id
    SOURCE XML  iv_xml
    RESULT model = ro_object.
  ENDMETHOD.

ENDCLASS.

PARAMETERS: tasks TYPE i DEFAULT 6 OBLIGATORY,
            sets  TYPE i DEFAULT 4 OBLIGATORY.

START-OF-SELECTION.

  DATA(o_thread1) = NEW lcl_processor( it_emp = VALUE tt_emp( ( empno   = '100'
                                                                deptno  = '20'
                                                                empname = 'Dummy1' ) )  ).

  DATA(o_parallel_processor) = NEW lcl_processor( p_num_tasks = tasks  ).


  TYPES: to_thread TYPE REF TO lcl_processor.
  DATA t_threads TYPE TABLE OF to_thread WITH EMPTY KEY.


  DO sets TIMES.
    APPEND NEW lcl_processor( it_emp = VALUE tt_emp( ( empno   = '100' * sy-index
                                                       deptno  = '20'
                                                       empname = 'Dummy' && sy-index ) ) )  TO t_threads.
  ENDDO.

  DATA(o_timer) = cl_abap_runtime=>create_hr_timer( ).
  o_timer->get_runtime(  ).
  o_parallel_processor->run( EXPORTING p_in_tab  = VALUE cl_abap_parallel=>t_in_tab( FOR lo_thread IN t_threads
                                                        ( lcl_processor=>transform_object_to_xml( lo_thread ) ) )
                             IMPORTING p_out_tab = DATA(t_out) ).

  DATA(v_runtime) = o_timer->get_runtime(  ).
  DATA(v_runtime_sec) =  o_timer->get_runtime(  ) / 1000000.
  WRITE:/ |Total runtimes in microseconds : { v_runtime } |.
  WRITE:/ |Total runtimes in seconds : { v_runtime_sec } |.
  DATA o_thread_out TYPE REF TO lcl_processor.
  LOOP AT t_out INTO DATA(s_out).
    CHECK s_out-result IS NOT INITIAL.

    o_thread_out ?= lcl_processor=>transform_xml_to_object( s_out-result ).

    IF o_thread_out IS BOUND.
      WRITE:/ o_thread_out->get_message(  ).
    ENDIF.
  ENDLOOP.