
*** This builds a label for relationships (the most complicated form).
* It numbers the labels starting at 1, incrementing by 1.
* You can look at the output of the "label list" in the log to see what number means what.
local lnum = 1
local llist ""
foreach r in biochild biomom biodad stepchild stepmom stepdad adoptchild adoptmom adoptdad mom dad spouse grandchild grandchild_p grandparent grandparent_p sibling partner childofpartner f_child child f_parent parent auntuncle auntuncle_or_parent parent_or_relative greatgrandchild greatgrandparent nephewniece child_or_nephewniece child_or_relative cousin sibling_or_cousin f_sib other_rel other_rel_p norel  foster confused dontknow {
    local llist = `"`llist' `lnum' "`r'""'
    local lnum = `lnum' + 1
}
label define relationship `llist'
display "String for relationship label"
display `"`llist'"'
display "Label for relationships"
label list relationship
