//==============================================================================
//=========== Children's Household Instability Project                                  
//=========== Dataset: SIPP2008                                                 
//=========== Purpose: Uses programs to compute relationships not 
//=========== directly identifiable with parent pointers, spouse pointer, or ERRP  
//================================================================================

********************************************************************************
**  Section: programs to process data to identify relationships transitively
********************************************************************************

* Program generates relationship from relationship1 and relatiosnhip2, 
* where A is [relationship1] of person B.
* Person B is [relationship2] of person C.
* Therefore ego is [relationship] or [result_rel] of person C.
capture program drop generate_relationship
program define generate_relationship
    args result_rel rel1 rel2 /* local macros: result_rel rel1 rels */
    display "Generating `result_rel' from `rel1' `rel2'"
    replace relationship = "`result_rel'":relationship if ((relationship1 == "`rel1'":relationship) & (relationship2 == "`rel2'":relationship))
	*if any relationship is missing:
    if (("`result_rel'":relationship == .) | ("`rel1'":relationship == .) | ("`rel2'":relationship == .)) {
        display as error "relationship not found in one of:  `result_rel' `rel1' `rel2'"
        exit 111
    }
end

* Program to make lists of values associated with each relationship type
* For example, moms can be biomoms, stepmoms, adoptive moms, or moms.  
capture program drop make_relationship_list
program define make_relationship_list, rclass /* results are in r() vector */
    * display `"make_relationship_list args:  `0'"'
    local max_rel = "`1'":relationship
    local my_rel_list "`max_rel'"
    * display "first rel:  `my_rel_list'"
    if (`max_rel' == .) {
        display as error "relationship not found:  `my_rel_list' `max_rel' `1'"
        exit 111
    }
    local i = 2
    while ("``i''" != "") {
        * display "next rel:  ``i''"
        local rel_num = "``i''":relationship
        if (`rel_num' == .) {
            display as error "relationship not found:  `my_rel_list' `max_rel' ``i''"
            exit 111
        }
        * display "next rel:  ``i''  `rel_num'"
        if (`rel_num' < `max_rel') {
            display as error "relationships out of order in make_relationship_list:  `my_rel_list' `max_rel' `rel_num'"
            exit 111
        }
        local max_rel = `rel_num'
        local my_rel_list "`my_rel_list',`rel_num'"
        * display "new rel list:  `my_rel_list'  max: `max_rel'"
        local ++i
    }
    return local rel_list `"`my_rel_list'"'
end

********************************************************************************
**  Section: apply programs to data to identify relationships bewteen ego and
**  every other person in ego's household in the wave.
********************************************************************************

    use "$tempdir/relationships_tc0_wide"

    * We're going to create a dataset that has all the transitive relationships we can find.  So, if we have A --> B and B --> C
    * we generate a dataset that tells us A --> B --> C by joining on B.
    rename relfrom intermediate_person
    rename relationship relationship2
    rename reason reason2
    label variable relationship2 "rel2"
    label variable reason2 "reason2"
    tempfile relmerge
    save `relmerge'


    use "$tempdir/relationships_tc0_wide"
    rename relto intermediate_person
    rename relationship relationship1
    rename reason reason1
    label variable relationship1 "rel1"
    label variable reason1 "reason1"
	
	tab relationship1, m
	
    * Joinby creates a record for every combination of records matching 
	* SSUID SHHADID SWAVE and intermediate_person in the two files.
    joinby SSUID SHHADID SWAVE intermediate_person using `relmerge'

	tab relationship1, m
	tab relationship2, m
	
	* Flag records where we already know relationship of A to C.
	* Using data is pairs for which we already know the relationship
	merge m:1 SSUID SHHADID SWAVE relfrom relto using "$tempdir/relationships_tc0_wide"

	*drop  cases in base_relationships not matched in joinby data because they are in two-person households 
	* and thus can never have an intermediated relationship
	drop if _merge==2

    * We don't keep (or validate correctness of) relationship of self to self.
	* Note that this effectively restricts the joinby data to households with 3 or more people.
    display "Dropping self-relationships"
    drop if (relfrom == relto)
	
	gen already_known=0 
	replace already_known=1 if _merge==3
	drop _merge
	
	display "Is the relationship already known?"
	tab already_known
	
	*drop if we already have a relationship type for the pair
	keep if already_known==0
	drop relationship reason numrels_tc0
	
    display "Tab of A -- > B and B --> C relationships, where we are trying to find A --> C, rowsort"
    tab relationship1 relationship2, rowsort m

    * Now given the A --> B --> C relationships, what can we figure out for A --> C?
    gen relationship = .
    label values relationship relationship

    local all_child_types CHILD BIOCHILD STEPCHILD ADOPTCHILD
    local all_parent_types MOM BIOMOM STEPMOM ADOPTMOM DAD BIODAD STEPDAD ADOPTDAD PARENT

foreach rel1 in `all_child_types' {
  *read as set generate_relationship equal to CHILD if rel1 is any of the child types and rel2 is SPOUSE
  generate_relationship "CHILD"					"`rel1'"	"SPOUSE"
  generate_relationship "CHILD"					"`rel1'"	"PARTNER"
  generate_relationship "GREATGRANDCHILD" 		"`rel1'" 	"GRANDCHILD"
  generate_relationship "AUNTUNCLE_OR_PARENT" 	"`rel1'" 	"GRANDPARENT"
  generate_relationship "NEPHEWNIECE" 			"`rel1'" 	"SIBLING"
  generate_relationship "COUSIN" 				"`rel1'" 	"AUNTUNCLE"
  generate_relationship "OTHER_REL" 			"SPOUSE" 	"`rel1'" 
  generate_relationship "OTHER_REL_P" 			"PARTNER" 	"`rel1'" 
  
  foreach rel2 in `all_child_types' {
     generate_relationship "GRANDCHILD" 		"`rel1'" 	"`rel2'"
  }
  
  foreach rel2 in `all_parent_types' {
     generate_relationship "SIBLING" 			"`rel1'" 	"`rel2'"
  }

  generate_relationship "OTHER_REL" 			"`rel1'" 	"OTHER_REL"
  generate_relationship "OTHER_REL" 			"OTHER_REL" "`rel1'" 
  generate_relationship "NOREL" 				"`rel1'" 	"NOREL"
  generate_relationship "NOREL" 				"NOREL" 	"`rel1'" 
  generate_relationship "F_SIB" 				"`rel1'" 	"F_CHILD"
  generate_relationship "F_SIB" 				"F_CHILD" 	"`rel1'"
  generate_relationship "F_SIB" 				"`rel1'" 	"F_PARENT"
}

foreach rel2 in `all_child_types' {
  generate_relationship "GREATGRANDCHILD" 		"GRANDCHILD" "`rel2'"
  generate_relationship "PARENT" "SIBLING" 		"`rel2'"
  generate_relationship "PARENT_OR_RELATIVE" 	"GRANDPARENT" "`rel2'"
  generate_relationship "F_SIB" "F_CHILD" 		"`rel2'"
}

foreach rel1 in `all_parent_types' {
   foreach rel2 in `all_parent_types' {
      generate_relationship "GRANDPARENT" 		"`rel1'" 	"`rel2'"
   }
   
   * Should we call these PARTNERS?  Or something less certain?
   foreach rel2 in `all_child_types' {
      generate_relationship "PARTNER" 			"`rel1'" 	"`rel2'"
   }

   generate_relationship "GREATGRANDPARENT" 	"`rel1'" 	"GRANDPARENT"
   generate_relationship "PARENT" 				"`rel1'" 	"SIBLING"
   generate_relationship "CHILD_OR_RELATIVE" 	"`rel1'" 	"GRANDCHILD"
   generate_relationship "OTHER_REL" 			"`rel1'" 	"SPOUSE"
   generate_relationship "OTHER_REL_P" 			"`rel1'" 	"PARTNER"
   generate_relationship "OTHER_REL" 			"`rel1'" 	"OTHER_REL"
   generate_relationship "OTHER_REL" 			"OTHER_REL" "`rel1'" 

   generate_relationship "NOREL" 				"`rel1'" 	"NOREL"
   generate_relationship "NOREL" 				"NOREL" 	"`rel1'" 
}

    foreach rel2 in `all_parent_types' {
        generate_relationship "PARENT" 			"SPOUSE" "`rel2'"
        generate_relationship "PARENT" 			"PARTNER" "`rel2'"

        generate_relationship "AUNTUNCLE" 		"SIBLING" "`rel2'"

        generate_relationship "CHILD_OR_NEPHEWNIECE" "GRANDCHILD" "`rel2'"

        generate_relationship "GREATGRANDPARENT" "GRANDPARENT" "`rel2'"

        generate_relationship "NOREL" 			"F_CHILD" "`rel2'"
    }

*** rel1 == GRANDCHILD
generate_relationship "GRANDCHILD" 				"GRANDCHILD" "SPOUSE"
generate_relationship "GRANDCHILD_P" 			"GRANDCHILD" "PARTNER"
generate_relationship "OTHER_REL" 				"GRANDCHILD" "SIBLING"
generate_relationship "SIBLING_OR_COUSIN" 		"GRANDCHILD" "GRANDPARENT"
generate_relationship "NOREL" 					"GRANDCHILD" "NOREL"
generate_relationship "OTHER_REL" 				"GRANDCHILD" "OTHER_REL"

*** rel2 == GRANDCHILD
generate_relationship "NOREL" 					"NOREL" "GRANDCHILD" 


*** rel1 == GRANDPARENT
generate_relationship "OTHER_REL" 				"GRANDPARENT" "SPOUSE"
generate_relationship "OTHER_REL_P" 			"GRANDPARENT" "PARTNER"
generate_relationship "NOREL" 					"GRANDPARENT" "NOREL"

*** rel2 == GRANDPARENT
generate_relationship "OTHER_REL" 				"OTHER_REL" "GRANDPARENT" 
generate_relationship "NOREL" 					"NOREL" "GRANDPARENT" 


*** rel1 == SIBLING
generate_relationship "SIBLING" 				"SIBLING" "SIBLING"
generate_relationship "OTHER_REL" 				"SIBLING" "SPOUSE"
generate_relationship "OTHER_REL_P" 			"SIBLING" "PARTNER"
generate_relationship "OTHER_REL" 				"SIBLING" "GRANDPARENT"
generate_relationship "OTHER_REL" 				"SIBLING" "OTHER_REL"
generate_relationship "NOREL" 					"SIBLING" "NOREL"

*** rel2 == SIBLING
generate_relationship "OTHER_REL" 				"OTHER_REL" "SIBLING" 
generate_relationship "NOREL" 					"NOREL" "SIBLING" 

*** rel1 == SPOUSE / PARTNER
generate_relationship "GRANDPARENT" 			"SPOUSE" "GRANDPARENT"
generate_relationship "GRANDPARENT_P" 			"PARTNER" "GRANDPARENT"
generate_relationship "OTHER_REL" 				"SPOUSE" "GRANDCHILD"
generate_relationship "OTHER_REL_P" 			"PARTNER" "GRANDCHILD"
generate_relationship "OTHER_REL" 				"SPOUSE" "SIBLING"
generate_relationship "OTHER_REL_P" 			"PARTNER" "SIBLING"
generate_relationship "OTHER_REL" 				"SPOUSE" "OTHER_REL"
generate_relationship "OTHER_REL_P" 			"PARTNER" "OTHER_REL"
generate_relationship "NOREL" 					"SPOUSE" "NOREL"
generate_relationship "DONTKNOW" 				"PARTNER" "NOREL"

*** rel2 == SPOUSE / PARTNER
generate_relationship "OTHER_REL_P" 			"OTHER_REL" "PARTNER" 
generate_relationship "OTHER_REL" 				"OTHER_REL" "SPOUSE" 
generate_relationship "NOREL" 					"NOREL" "SPOUSE" 
generate_relationship "DONTKNOW" 				"NOREL" "PARTNER" 

*** rel1 == F_CHILD
generate_relationship "F_CHILD" 				"F_CHILD" "SPOUSE" 
generate_relationship "F_PARENT" 				"SPOUSE" "F_CHILD"
generate_relationship "F_PARENT" 				"F_CHILD" "PARTNER"

*** rel2 == F_PARENT
generate_relationship "F_SIB" 					"F_CHILD" "F_PARENT"
generate_relationship "F_PARENT" 				"SPOUSE" "F_PARENT"
generate_relationship "F_PARENT" 				"PARTNER" "F_PARENT"
	
*** Other
generate_relationship "OTHER_REL" 				"OTHER_REL" "OTHER_REL" 

generate_relationship "NOREL" 					"OTHER_REL" "NOREL"
generate_relationship "NOREL" 					"NOREL" "OTHER_REL" 

generate_relationship "DONTKNOW" 				"NOREL" "NOREL"

display "How are we doing at finding relationships?"
mdesc relationship 

* Report relationship pairs we're not handling yet.
 preserve
	display "Keeping just missing relationships so we can show the pairs"
	keep if (missing(relationship))
	display "Relationship pairs we do not currently handle, rowsort"
	tab relationship1 relationship2, rowsort m
 restore

 * Save just records for which we understand A --> C.
 display "Keeping only those pairs for which we understand relationships"
 keep if (!missing(relationship))

 * We force the drop because we don't care about the details if the end result is the same.
 duplicates drop SSUID SHHADID SWAVE relfrom relto relationship, force

 gen reason = string(relationship1) + " " + string(relationship2) + " via " + string(intermediate_person)
 drop intermediate_person relationship1 relationship2 reason1 reason2

********************************************************************************
* Section: Checking records with more than one relationship in a wave
*          and select "best" relationship when more than one relationship type.
********************************************************************************

sort SSUID SHHADID SWAVE relfrom relto
by SSUID SHHADID SWAVE relfrom relto:  gen numrels_tc1 = _N
by SSUID SHHADID SWAVE relfrom relto:  gen relnum_tc1 = _n

display "How many relationships have we generated per person-wave?"
tab numrels_tc1

*reshape so that we can compare relationships for pairs (within wave) with more than one relationship type	
reshape wide relationship reason, i(SSUID SHHADID SWAVE relfrom relto) j(relnum_tc1)

save "$tempdir/relationships_tc1_wide", $replace

*Make the easy decision that if there is only one piece of information we will take it.
gen relationship:relationship=relationship1 if missing(relationship2)

display "Relationships for which there is only one candidate"
tab relationship
	
* These are lists of relationships. The preferred description of the relationship is the earlier one
* So, for example, if the same relationship is coded as biodad stepdad and auntuncle_or_parent, we'll choose biodad (below)
local dad_relations " BIODAD STEPDAD ADOPTDAD DAD F_PARENT PARENT AUNTUNCLE_OR_PARENT OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local mom_relations " BIOMOM STEPMOM ADOPTMOM MOM F_PARENT PARENT AUNTUNCLE_OR_PARENT OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local child_relations " BIOCHILD STEPCHILD ADOPTCHILD CHILDOFPARTNER F_CHILD CHILD CHILD_OR_NEPHEWNIECE CHILD_OR_RELATIVE OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local spouse_relations " SPOUSE PARTNER OTHER_REL OTHER_REL_P NOREL CONFUSED DONTKNOW "
local sibling_relations " SIBLING SIBLING_OR_COUSIN  F_SIB OTHER_REL OTHER_REL_P NOREL CONFUSED DONTKNOW "
local cousin_relations " COUSIN SIBLING_OR_COUSIN OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local grandparent_relations " GRANDPARENT GRANDPARENT_P OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local grandchild_relations " GRANDCHILD GRANDCHILD_P OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local greatgrandchild_relations " GREATGRANDCHILD OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local nephewniece_relations " NEPHEWNIECE OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "
local norel_relations " NOREL CONFUSED DONTKNOW "
local otherrel_relations " OTHER_REL OTHER_REL_P CONFUSED DONTKNOW "

foreach r in dad mom child spouse sibling cousin grandparent grandchild greatgrandchild nephewniece norel otherrel {
   make_relationship_list ``r'_relations'
   * The error statement does nothing if no error was returned.  If there was, it passes the error back to the caller.
   error _rc
   
   local `r'_rel_list = "`r(rel_list)'"
   display "`r'_rel_list = ``r'_rel_list'"
}

display "Relationship 1 and 2 where there is more than one relationship"
tab relationship1 relationship2 if missing(relationship)

display "Now working on resolving relationships"
 foreach r in dad mom child spouse sibling grandparent grandchild greatgrandchild nephewniece norel otherrel {
   display "Looking for `r'"
   gen best_rel = .
   
   * Going through each identified relationship, starting with relationship1
   * set bestrel to equal that relationship if it is not missing and it has a lower value
   * in the set of relations in this set of `r' relationship types.
   * For example, if the relationship is biodad and stepdad, set to biodad.
   foreach v of varlist relationship* {
     display "Processing `v'"
     replace best_rel = `v' if ((!missing(`v')) & (`v' < best_rel) & inlist(`v', ``r'_rel_list'))
     replace best_rel = 0 if ((!missing(`v')) & (!inlist(`v', ``r'_rel_list')))
   }
   replace relationship = best_rel if (missing(relationship) & (best_rel > 0))
   drop best_rel
}

display "Where do we stand with relationships?"
tab relationship, m

tab relationship1 relationship2 if missing(relationship)

drop relationship1 relationship2 relationship3 numrels_tc1

*Append base relationships file (iteration 0). No overlap because dropped matched cases earlier.
append using "$tempdir/relationships_tc0_wide"

tab relationship, m

save "$tempdir/relationship_pairs_bywave", $replace

********************************************************************************
*Note: File still has one observation per pair PER WAVE. 
********************************************************************************
