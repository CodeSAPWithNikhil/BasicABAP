PROGRAM.

TYPES: BEGIN OF ts_group,
         city       TYPE ztemployee-city,
         cuky_field TYPE ztemployee-cuky_field,
         salary     TYPE ztemployee-salary,
       END OF ts_group.
TYPES tt_grp TYPE TABLE OF ts_group WITH EMPTY KEY.
DATA: t_grouped TYPE TABLE OF ts_group.

START-OF-SELECTION.

  SELECT emp_id, empname, city,cuky_field, salary FROM ztemployee INTO TABLE @DATA(t_employees)
                                                   WHERE empname <> @space.

****************************************************************************************
*****************Group by using nested classical loop **********************************
****************************************************************************************

  LOOP AT t_employees INTO DATA(t_group) GROUP BY ( city       = t_group-city
                                                    cuky_field = t_group-cuky_field ).

    DATA(v_total_salary) = VALUE ztemployee-salary( ).

    LOOP AT GROUP t_group INTO DATA(s_group).
      v_total_salary = v_total_salary + s_group-salary.
    ENDLOOP.

    APPEND CORRESPONDING ts_group( t_group ) TO t_grouped
    ASSIGNING FIELD-SYMBOL(<fs_row>).
    <fs_row>-salary = v_total_salary.
  ENDLOOP.

  cl_demo_output=>write( t_grouped ).


****************************************************************************************
*****************Group by using combined classical and for loop*************************
****************************************************************************************
  CLEAR t_grouped.
  LOOP AT t_employees INTO t_group GROUP BY ( city       = t_group-city
                                              cuky_field = t_group-cuky_field ).

    CLEAR v_total_salary.

    v_total_salary = REDUCE #( INIT lv_total = VALUE ztemployee-salary( )
                                FOR s_group_row IN GROUP t_group
                                NEXT  lv_total = lv_total + s_group_row-salary ).

    APPEND CORRESPONDING ts_group( t_group ) TO t_grouped
    ASSIGNING <fs_row>.
    <fs_row>-salary = v_total_salary.
  ENDLOOP.
  cl_demo_output=>write( t_grouped ).


****************************************************************************************
*****************Group by using nested reduce and for loops*****************************
****************************************************************************************
  CLEAR t_grouped.
  t_grouped = REDUCE #( INIT t_grp = VALUE tt_grp(  )

                        FOR GROUPS OF t_group_for IN t_employees GROUP BY ( city       = t_group_for-city
                                                                            cuky_field = t_group_for-cuky_field )

                        NEXT t_grp = VALUE #( BASE t_grp ( city       = t_group_for-city
                                                           cuky_field = t_group_for-cuky_field
                                                           salary = REDUCE #( INIT total_salary = VALUE ztemployee-salary( )
                                                                              FOR s_group_row IN GROUP t_group_for
                                                                              NEXT total_salary = total_salary + s_group_row-salary )
                                                          )
                                             )
                      ).

  cl_demo_output=>write( t_grouped ).

****************************************************************************************
*****************Group by using nested for loops****************************************
****************************************************************************************

  CLEAR t_grouped.
  t_grouped = VALUE #( FOR GROUPS OF t_group_for IN t_employees GROUP BY ( city       = t_group_for-city
                                                                           cuky_field = t_group_for-cuky_field )
                      ( city       = t_group_for-city
                        cuky_field = t_group_for-cuky_field
                        salary     = REDUCE #( INIT total_salary = VALUE ztemployee-salary( )
                                               FOR s_group_row IN GROUP t_group_for
                                               NEXT total_salary = total_salary + s_group_row-salary )  )  ).

  cl_demo_output=>write( t_grouped ).


****************************************************************************************
*****************Group by using nested for loops and corresponding**********************
****************************************************************************************
  CLEAR t_grouped.
  t_grouped = VALUE #( FOR GROUPS OF t_group_for IN t_employees GROUP BY ( city       = t_group_for-city
                                                                           cuky_field = t_group_for-cuky_field  )

                         LET s_group_first_row = CORRESPONDING ts_group( t_group_for ) IN "Declare temporary work area

                         ( VALUE #( BASE CORRESPONDING #( s_group_first_row )  "Keeping corresponding grouped fields as base

                                         salary = REDUCE #( INIT total_salary = VALUE ztemployee-salary( )  "Calculate total salary seperately
                                                            FOR s_group_row IN GROUP t_group_for
                                                            NEXT total_salary = total_salary + s_group_row-salary ) ) )  ).


  cl_demo_output=>write( t_grouped ).
  cl_demo_output=>display(  ).
