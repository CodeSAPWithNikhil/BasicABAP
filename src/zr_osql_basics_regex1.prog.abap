REPORT zr_osql_basics_regex1.
SELECT SINGLE
  length( 'India' ) AS length,  "Result: 5
  initcap( 'mumbai' ) AS initcap,  "Result: Mumbai
  instr( 'Amravati','v' ) AS instr, "Result: 5
  left( '4500000000 order has been created', 10 ) AS left,  "Result: 4500000000   "similar results for right function

  like_regexpr( pcre  = '\d',           "find if there's any digit (0 = not found, 1 = found
                value = '10078' ) AS like_regex,  "Result: 1(found)

  locate_regexpr( pcre = '\d',          "find the offset of the digits in string using \d regex
                  value = 'bruce.wayne28@justiceleague.com',
                  occurrence = 1 ) AS locate_regexpr, "Result: 12 (offset of 2)

  locate_regexpr_after( pcre = '\d',    "find the offset of character that's after the digits
                        value = 'bruce.wayne28@justiceleague.com',
                        occurrence = 2 ) AS locate_regexpr_after, "Result: 14(offset of j)

  occurrences_regexpr( pcre = '\d', "find all the number of occurrences of digit regex
                       value = 'Clark Kent 2025' ) AS occ_regex, "Result: 4

  replace_regexpr( pcre = '^\w+@\w+\.\w{2,}$',     "email id regex
                   value = 'brucewayne@justiceleague.com',
                   with = '#' ) AS replace_regex, "Replaces the email id with # if it matches with regex

  substring_regexpr( pcre = '\d+',                 "number regex
                     value = 'order 4500000000 has been created'
                     ) AS substring_regexpr       "Result: 4500000000

  FROM tvarv
             INTO @DATA(ls_dummy).
cl_demo_output=>display( ls_dummy ).
