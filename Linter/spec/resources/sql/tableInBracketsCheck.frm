<div>
    <cmpDataSet name="tableInBracketsCheck">
        <![CDATA[
            select g.*
            from (table (cast(D_PKG_TOOLS.STR_SEPARATE('1;2;3', ';') as D_CL_STR))) g
        ]]>
    </cmpDataSet>
</div>