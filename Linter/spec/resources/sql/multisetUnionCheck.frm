<div>
    <cmpAction name="multisetUnionCheck">
        <![CDATA[
            declare
                rREC     D_CL_SCHPERIODS := D_CL_SCHPERIODS();
                RESULT   D_CL_SCHPERIODS := D_CL_SCHPERIODS();
            begin
                RESULT := RESULT multiset union rREC;
            end;
        ]]>
    </cmpAction>
</div>