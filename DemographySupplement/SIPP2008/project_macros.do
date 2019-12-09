//================================================================================================//
//===== Children's Household Instability Project                                               
//===== Dataset: SIPP2008                                                                    
//===== Purpose: Create macros of waves, age, month, relationships. 
//===== Also, create program executed by multiple do files to reduce number of relationship categories.
//================================================================================================//

global first_wave 1
global final_wave 15
global second_wave = ${first_wave} + 1
global penultimate_wave = ${final_wave} - 1

global adult_age 18

global refmon 4

** A global macro for the number of transitive closure passes we want to do.
global max_tc 1

//==============================================================================//
//== Function: Computes simplified relationships from the more complex ones
//==
//== Arguments Created: 
//     input_rel - The name of the existing relationship variable.
//     simplified_rel - The name of the variable to be created containing the intermediate simplification of relationships.
//     ultra_simple_rel - The name of the variable to be created containing the most compact form of relationships.
//
//== Note: The program assumes that input_rel uses the value label "relationships".
//==============================================================================//
capture program drop simplify_relationships
program define simplify_relationships
    args input_rel simplified_rel ultra_simple_rel
    * TODO:  It would be friendly to check that all three args are provided and to error out if not.
    gen `simplified_rel' = .
    label values `simplified_rel' relationship
    replace `simplified_rel' = "CHILD":relationship if inlist(`input_rel', "BIOCHILD":relationship, "STEPCHILD":relationship, "ADOPTCHILD":relationship, "CHILDOFPARTNER":relationship, "CHILD":relationship)
    replace `simplified_rel' = "PARENT":relationship if inlist(`input_rel', "BIOMOM":relationship, "STEPMOM":relationship, "ADOPTMOM":relationship, "BIODAD":relationship, "STEPDAD":relationship, "ADOPTDAD":relationship, "PARENT":relationship)
    replace `simplified_rel' = "GRANDCHILD":relationship if inlist(`input_rel', "GRANDCHILD":relationship, "GREATGRANDCHILD":relationship)
    replace `simplified_rel' = "GRANDPARENT":relationship if inlist(`input_rel', "GRANDPARENT":relationship, "GREATGRANDPARENT":relationship)
    replace `simplified_rel' = "SIBLING":relationship if inlist(`input_rel', "SIBLING":relationship)
    replace `simplified_rel' = "OTHER_REL":relationship if inlist(`input_rel', "OTHER_REL":relationship, "SPOUSE":relationship, "AUNTUNCLE_OR_PARENT":relationship, "AUNTUNCLE":relationship, "NEPHEWNIECE":relationship, "SIBLING_OR_COUSIN":relationship, "CHILD_OR_NEPHEWNIECE":relationship)
    replace `simplified_rel' = "NOREL":relationship if inlist(`input_rel', "NOREL":relationship, "PARTNER":relationship)

	replace `simplified_rel' = "FOSTER":relationship if inlist(`input_rel', "F_CHILD":relationship, "F_PARENT":relationship, "F_SIB":relationship)
    replace `simplified_rel' = "GRANDCHILD_P":relationship if inlist(`input_rel', "GRANDCHILD_P":relationship)
    replace `simplified_rel' = "GRANDPARENT_P":relationship if inlist(`input_rel', "GRANDPARENT_P":relationship)
    replace `simplified_rel' = "OTHER_REL_P":relationship if inlist(`input_rel', "OTHER_REL_P":relationship)

    replace `simplified_rel' = "DONTKNOW":relationship if inlist(`input_rel', "DONTKNOW":relationship)

    replace `simplified_rel' = "CONFUSED":relationship if inlist(`input_rel', "CONFUSED":relationship, .a, .m)

    gen `ultra_simple_rel' = .
    label values `ultra_simple_rel' ultra_simple_rel
    replace `ultra_simple_rel' = "CHILD":ultra_simple_rel if (`simplified_rel' == "CHILD":relationship)
    replace `ultra_simple_rel' = "SIBLING":ultra_simple_rel if (`simplified_rel' == "SIBLING":relationship)
    replace `ultra_simple_rel' = "GRANDCHILD":ultra_simple_rel if (`simplified_rel' == "GRANDCHILD":relationship)
    replace `ultra_simple_rel' = "OTHER_CHILD":ultra_simple_rel if (missing(`ultra_simple_rel') & (to_age < $adult_age))
    replace `ultra_simple_rel' = "OTHER_ADULT":ultra_simple_rel if (missing(`ultra_simple_rel'))
end
