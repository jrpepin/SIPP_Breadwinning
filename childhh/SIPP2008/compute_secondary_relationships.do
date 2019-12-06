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
	* ssuid shhadid swave and intermediate_person in the two files.
    joinby ssuid shhadid swave intermediate_person using `relmerge'

	tab relationship1, m
	tab relationship2, m
	
	* Flag records where we already know relationship of A to C.
	* Using data is pairs for which we already know the relationship
	merge m:1 ssuid shhadid swave relfrom relto using "$tempdir/relationships_tc0_wide"

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

    local all_child_types child biochild stepchild adoptchild
    local all_parent_types mom biomom stepmom adoptmom dad biodad stepdad adoptdad parent

foreach rel1 in `all_child_types' {
  *read as set generate_relationship equal to child if rel1 is any of the child types and rel2 is spouse
  generate_relationship "child"					"`rel1'"	"spouse"
  generate_relationship "child"					"`rel1'"	"partner"
  generate_relationship "greatgrandchild" 		"`rel1'" 	"grandchild"
  generate_relationship "auntuncle_or_parent" 	"`rel1'" 	"grandparent"
  generate_relationship "nephewniece" 			"`rel1'" 	"sibling"
  generate_relationship "cousin" 				"`rel1'" 	"auntuncle"
  generate_relationship "other_rel" 			"spouse" 	"`rel1'" 
  generate_relationship "other_rel_p" 			"partner" 	"`rel1'" 
  
  foreach rel2 in `all_child_types' {
     generate_relationship "grandchild" 		"`rel1'" 	"`rel2'"
  }
  
  foreach rel2 in `all_parent_types' {
     generate_relationship "sibling" 			"`rel1'" 	"`rel2'"
  }

  generate_relationship "other_rel" 			"`rel1'" 	"other_rel"
  generate_relationship "other_rel" 			"other_rel" "`rel1'" 
  generate_relationship "norel" 				"`rel1'" 	"norel"
  generate_relationship "norel" 				"norel" 	"`rel1'" 
  generate_relationship "f_sib" 				"`rel1'" 	"f_child"
  generate_relationship "f_sib" 				"f_child" 	"`rel1'"
  generate_relationship "f_sib" 				"`rel1'" 	"f_parent"
}

foreach rel2 in `all_child_types' {
  generate_relationship "greatgrandchild" 		"grandchild" "`rel2'"
  generate_relationship "parent" "sibling" 		"`rel2'"
  generate_relationship "parent_or_relative" 	"grandparent" "`rel2'"
  generate_relationship "f_sib" "f_child" 		"`rel2'"
}

foreach rel1 in `all_parent_types' {
   foreach rel2 in `all_parent_types' {
      generate_relationship "grandparent" 		"`rel1'" 	"`rel2'"
   }
   
   * Should we call these partnerS?  Or something less certain?
   foreach rel2 in `all_child_types' {
      generate_relationship "partner" 			"`rel1'" 	"`rel2'"
   }

   generate_relationship "greatgrandparent" 	"`rel1'" 	"grandparent"
   generate_relationship "parent" 				"`rel1'" 	"sibling"
   generate_relationship "child_or_relative" 	"`rel1'" 	"grandchild"
   generate_relationship "other_rel" 			"`rel1'" 	"spouse"
   generate_relationship "other_rel_p" 			"`rel1'" 	"partner"
   generate_relationship "other_rel" 			"`rel1'" 	"other_rel"
   generate_relationship "other_rel" 			"other_rel" "`rel1'" 

   generate_relationship "norel" 				"`rel1'" 	"norel"
   generate_relationship "norel" 				"norel" 	"`rel1'" 
}

    foreach rel2 in `all_parent_types' {
        generate_relationship "parent" 			"spouse" "`rel2'"
        generate_relationship "parent" 			"partner" "`rel2'"

        generate_relationship "auntuncle" 		"sibling" "`rel2'"

        generate_relationship "child_or_nephewniece" "grandchild" "`rel2'"

        generate_relationship "greatgrandparent" "grandparent" "`rel2'"

        generate_relationship "norel" 			"f_child" "`rel2'"
    }

*** rel1 == grandchild
generate_relationship "grandchild" 				"grandchild" "spouse"
generate_relationship "grandchild_p" 			"grandchild" "partner"
generate_relationship "other_rel" 				"grandchild" "sibling"
generate_relationship "sibling_or_cousin" 		"grandchild" "grandparent"
generate_relationship "norel" 					"grandchild" "norel"
generate_relationship "other_rel" 				"grandchild" "other_rel"

*** rel2 == grandchild
generate_relationship "norel" 					"norel" "grandchild" 


*** rel1 == grandparent
generate_relationship "other_rel" 				"grandparent" "spouse"
generate_relationship "other_rel_p" 			"grandparent" "partner"
generate_relationship "norel" 					"grandparent" "norel"

*** rel2 == grandparent
generate_relationship "other_rel" 				"other_rel" "grandparent" 
generate_relationship "norel" 					"norel" "grandparent" 


*** rel1 == sibling
generate_relationship "sibling" 				"sibling" "sibling"
generate_relationship "other_rel" 				"sibling" "spouse"
generate_relationship "other_rel_p" 			"sibling" "partner"
generate_relationship "other_rel" 				"sibling" "grandparent"
generate_relationship "other_rel" 				"sibling" "other_rel"
generate_relationship "norel" 					"sibling" "norel"

*** rel2 == sibling
generate_relationship "other_rel" 				"other_rel" "sibling" 
generate_relationship "norel" 					"norel" "sibling" 

*** rel1 == spouse / partner
generate_relationship "grandparent" 			"spouse" "grandparent"
generate_relationship "grandparent_p" 			"partner" "grandparent"
generate_relationship "other_rel" 				"spouse" "grandchild"
generate_relationship "other_rel_p" 			"partner" "grandchild"
generate_relationship "other_rel" 				"spouse" "sibling"
generate_relationship "other_rel_p" 			"partner" "sibling"
generate_relationship "other_rel" 				"spouse" "other_rel"
generate_relationship "other_rel_p" 			"partner" "other_rel"
generate_relationship "norel" 					"spouse" "norel"
generate_relationship "dontknow" 				"partner" "norel"

*** rel2 == spouse / partner
generate_relationship "other_rel_p" 			"other_rel" "partner" 
generate_relationship "other_rel" 				"other_rel" "spouse" 
generate_relationship "norel" 					"norel" "spouse" 
generate_relationship "dontknow" 				"norel" "partner" 

*** rel1 == f_child
generate_relationship "f_child" 				"f_child" "spouse" 
generate_relationship "f_parent" 				"spouse" "f_child"
generate_relationship "f_parent" 				"f_child" "partner"

*** rel2 == f_parent
generate_relationship "f_sib" 					"f_child" "f_parent"
generate_relationship "f_parent" 				"spouse" "f_parent"
generate_relationship "f_parent" 				"partner" "f_parent"
	
*** Other
generate_relationship "other_rel" 				"other_rel" "other_rel" 

generate_relationship "norel" 					"other_rel" "norel"
generate_relationship "norel" 					"norel" "other_rel" 

generate_relationship "dontknow" 				"norel" "norel"

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
 duplicates drop ssuid shhadid swave relfrom relto relationship, force

 gen reason = string(relationship1) + " " + string(relationship2) + " via " + string(intermediate_person)
 drop intermediate_person relationship1 relationship2 reason1 reason2

********************************************************************************
* Section: Checking records with more than one relationship in a wave
*          and select "best" relationship when more than one relationship type.
********************************************************************************

sort ssuid shhadid swave relfrom relto
by ssuid shhadid swave relfrom relto:  gen numrels_tc1 = _N
by ssuid shhadid swave relfrom relto:  gen relnum_tc1 = _n

display "How many relationships have we generated per person-wave?"
tab numrels_tc1

*reshape so that we can compare relationships for pairs (within wave) with more than one relationship type	
reshape wide relationship reason, i(ssuid shhadid swave relfrom relto) j(relnum_tc1)

save "$tempdir/relationships_tc1_wide", $replace

*Make the easy decision that if there is only one piece of information we will take it.
gen relationship:relationship=relationship1 if missing(relationship2)

display "Relationships for which there is only one candidate"
tab relationship
	
* These are lists of relationships. The preferred description of the relationship is the earlier one
* So, for example, if the same relationship is coded as biodad stepdad and auntuncle_or_parent, we'll choose biodad (below)
local dad_relations " biodad stepdad adoptdad dad f_parent parent auntuncle_or_parent other_rel other_rel_p confused dontknow "
local mom_relations " biomom stepmom adoptmom mom f_parent parent auntuncle_or_parent other_rel other_rel_p confused dontknow "
local child_relations " biochild stepchild adoptchild childofpartner f_child child child_or_nephewniece child_or_relative other_rel other_rel_p confused dontknow "
local spouse_relations " spouse partner other_rel other_rel_p norel confused dontknow "
local sibling_relations " sibling sibling_or_cousin  f_sib other_rel other_rel_p norel confused dontknow "
local cousin_relations " cousin sibling_or_cousin other_rel other_rel_p confused dontknow "
local grandparent_relations " grandparent grandparent_p other_rel other_rel_p confused dontknow "
local grandchild_relations " grandchild grandchild_p other_rel other_rel_p confused dontknow "
local greatgrandchild_relations " greatgrandchild other_rel other_rel_p confused dontknow "
local nephewniece_relations " nephewniece other_rel other_rel_p confused dontknow "
local norel_relations " norel confused dontknow "
local otherrel_relations " other_rel other_rel_p confused dontknow "

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
