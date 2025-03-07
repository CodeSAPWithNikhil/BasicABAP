PROGRAM.

START-OF-SELECTION.
  TYPES: BEGIN OF ty_payload,
           employees TYPE STANDARD TABLE OF ztemployee WITH DEFAULT KEY,
         END OF ty_payload.

  DATA: s_payload TYPE ty_payload,
        v_xml     TYPE string.

  TRY.
      CONCATENATE '<ROOT>' "or root whatever node you define
                     '<EMPLOYEES>'
                          '<ZTEMPLOYEE>'
                              '<MANDT>400</MANDT>'
                              '<EMP_ID>123456</EMP_ID>'
                              '<EMPNAME>Sansa Stark</EMPNAME'
                              '<CITY/>'
                              '<CUKY_FIELD>GOT</CUKY_FIELD>'
                              '<SALARY>200.0</SALARY>'
                          '</ZTEMPLOYEE>'
                    '</EMPLOYEES>'
                  '</ROOT>' INTO v_xml.  "Sample xml

      SELECT * FROM ztemployee INTO CORRESPONDING FIELDS OF TABLE @s_payload-employees UP TO 2 ROWS.

********Using standard id transformation, here data tag becomes root*****************************
      CALL TRANSFORMATION id SOURCE data = s_payload RESULT XML v_xml.
      CALL TRANSFORMATION id SOURCE XML v_xml RESULT data =  s_payload.

********Custom simple transformation based on ddic structure, root node is of type s_payload************
      CALL TRANSFORMATION zemployee_deep SOURCE root = s_payload RESULT XML v_xml.
      CALL TRANSFORMATION zemployee_deep SOURCE XML v_xml RESULT root = s_payload.

    CATCH cx_root INTO DATA(x_dump).
      WRITE x_dump->get_longtext(  ).
      WRITE x_dump->get_text(  ).
  ENDTRY.
