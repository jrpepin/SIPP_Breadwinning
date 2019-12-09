
*** Define the label for our compact representation of relationships.
capture label drop ultra_simple_rel
local lnum = 1
local llist ""
foreach r in CHILD SIBLING GRANDCHILD OTHER_ADULT OTHER_CHILD {
    local llist = `"`llist' `lnum' "`r'""'
    local lnum = `lnum' + 1
}
label define ultra_simple_rel `llist'

