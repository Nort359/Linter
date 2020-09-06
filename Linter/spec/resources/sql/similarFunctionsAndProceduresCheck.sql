procedure CONC_LIST 
(
  "fsALLTEXT 444"                      in CUSTOM_TYPE(34),
  fsTEXT                               out VARCHAR2 default sE,
  fsCONC_SYMB                          VARCHAR2 default sE
) as VARCHAR2 ...;

function CONC_LIST
(
  "fsALLTEXT 555"                      VARCHAR2,
  fsTEXT                               out CUSTOM_TYPE(34) default sE,
  fsCONC_SYMB                          VARCHAR2 default sE
) return VARCHAR2 ...;


procedure CONC_LIST_2 as ...;

function CONC_LIST_2 return ...;


FUNCTION GET_ONKO_GIST_MARK_2() return D_CL_SSS ...;

PROCEDURE GET_ONKO_GIST_MARK_2 AS D_CL_SSS ...;