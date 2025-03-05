TRY.
    " Define a structure for data
    TYPES: BEGIN OF ts_data,
             field1 TYPE string,
             field2 TYPE string,
           END OF ts_data.

    " Define a structure for JSON representation
    TYPES: BEGIN OF ty_json,
             dat TYPE TABLE OF ts_data WITH EMPTY KEY,
           END OF ty_json.

    " Declare internal data variable
    DATA ls_data TYPE ty_json.

    " Define a JSON string
    DATA(lv_json) = '{"dat":[{"field1": "ABAP", "field2":"JSON"},
                             {"field1": "ABAP2","field2":"JSON2"}]}'. 

    " Output the raw JSON string
    cl_demo_output=>write_json( lv_json ).

    " Deserialize JSON into internal table
    /blg/cl_util_json_v2=>deserialize(
      EXPORTING json = lv_json
      CHANGING data = ls_data ).

    " Display deserialized data
    cl_demo_output=>write( 'JSON deserialized:' ).
    cl_demo_output=>write( ls_data-dat ).

    " Serialize back to JSON
    DATA(lv_json_serialized) = /blg/cl_util_json_v2=>serialize(
      EXPORTING 
        data        = ls_data
        pretty_name = abap_true ).

    " Output the serialized JSON
    cl_demo_output=>write( 'JSON serialized:' ).
    cl_demo_output=>write_json( lv_json_serialized ).

    " Display output
    cl_demo_output=>display().

CATCH cx_root INTO DATA(lo_root).
    WRITE: lo_root->get_longtext( ).
ENDTRY.
