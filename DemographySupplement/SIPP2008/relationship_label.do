
*** This builds a label for relationships (the most complicated form).
* It numbers the labels starting at 1, incrementing by 1.
* You can look at the output of the "label list" in the log to see what number means what.
local lnum = 1
local llist ""
foreach r in BIOCHILD BIOMOM BIODAD STEPCHILD STEPMOM STEPDAD ADOPTCHILD ADOPTMOM ADOPTDAD MOM DAD SPOUSE GRANDCHILD GRANDCHILD_P GRANDPARENT GRANDPARENT_P SIBLING PARTNER CHILDOFPARTNER F_CHILD CHILD F_PARENT PARENT AUNTUNCLE AUNTUNCLE_OR_PARENT PARENT_OR_RELATIVE GREATGRANDCHILD GREATGRANDPARENT NEPHEWNIECE CHILD_OR_NEPHEWNIECE CHILD_OR_RELATIVE COUSIN SIBLING_OR_COUSIN F_SIB OTHER_REL OTHER_REL_P NOREL  FOSTER CONFUSED DONTKNOW {
    local llist = `"`llist' `lnum' "`r'""'
    local lnum = `lnum' + 1
}
label define relationship `llist'
display "String for relationship label"
display `"`llist'"'
display "Label for relationships"
label list relationship
