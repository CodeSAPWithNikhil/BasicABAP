REPORT zr_osql_basics_regex1.
SELECT SINGLE
  length( 'India' ) AS length,  "Result: 5
  initcap( 'michael scott' ) AS initcap,  "Result: Michael Scott
  instr( 'Amravati','v' ) AS instr, "Result: 5
  left( '4500000000 order has been created', 10 ) AS left,  "Result: 4500000000   "similar results for right function

  like_regexpr( pcre  = '\d', value = '10078' ) AS like_regex,  "find if there's any digit (0= not found,1= found) || Result: 1(found)

  like_regexpr( pcre  = '^\w+@\w+\.\w{2,}$', value = 'brucewayne@wayneterprises.com' ) AS is_email_valid,
                                                " Result: 1(positive)

  locate_regexpr( pcre = '\d',          "find the offset of the digits in string using \d regex
                  value = 'stan.edger28@vought.com',
                  occurrence = 1 ) AS locate_regexpr, "Result: 11 (offset of 2)

  locate_regexpr_after( pcre = '\d',    "find the offset of character that's after the digits
                        value = 'mufasa.singh28@milele.com',
                        occurrence = 2 ) AS locate_regexpr_after, "Result: 15(offset of @)

  occurrences_regexpr( pcre = '\d', "count all the number of occurrences of digit regex
                       value = 'Clark Scott 2025' ) AS occ_regex, "Result: 4

  replace_regexpr( pcre = '[^\d]',     "non-digit regex
                   value = 'USD9000#',
                   with = @space ) AS replace_regex, "Result: 900

  substring_regexpr( pcre = '\d+',                 "number regex
                     value = 'order 4500000000 has been created'
                     ) AS substring_regexpr       "Result: 4500000000

  FROM tvarv
             INTO @DATA(ls_dummy).
cl_demo_output=>display( ls_dummy ).
