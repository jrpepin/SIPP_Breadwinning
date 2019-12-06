
*** Define the label for our compact representation of relationships.
capture label drop ultra_simple_rel
local lnum = 1
local llist ""
foreach r in child sibling grandchild other_adult other_child {
    local llist = `"`llist' `lnum' "`r'""'
    local lnum = `lnum' + 1
}
label define ultra_simple_rel `llist'

