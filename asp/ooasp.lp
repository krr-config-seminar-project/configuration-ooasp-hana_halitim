% Please insert the names and email addresses of the group members:
% Hana Halitim
% hana.halitim@uni-potsdam.de
% Mohamed Boulhen
% mohamed.boulhen@uni-potsdam.de

#const max_instance_per_leaf_class = 10.
#const int_domain_max = 20.

possible_instance_id(1..max_instance_per_leaf_class).

% generate attribute values
int_value(1..int_domain_max).
bool_value("TRUE").
bool_value("FALSE").

% input handling
ooasp_instantiation(M,I) :- partial(ooasp_instantiation(M,I)).
ooasp_isa(I,C,O) :- partial(ooasp_isa(I,C,O)).
ooasp_associated(I,A,O1,O2) :- partial(ooasp_associated(I,A,O1,O2)).
ooasp_attribute_value(I,AT,O,V) :- partial(ooasp_attribute_value(I,AT,O,V)).


% generate instantiation 
ooasp_instantiation(M, I) :- ooasp_isa(I, C, O), ooasp_class(M, C).

% instantiate objects using possible instance ids
{ ooasp_isa(I, C, (C,O)) } :-
	ooasp_instantiation(M, I), ooasp_class(M, C), not ooasp_subclass(M, _, C), possible_instance_id(O).

%
% Your encoding goes here...
%

% Associate objects with one another in the context of the model
{ooasp_associated(Instance, Relation, Obj1, Obj2) : 
    ooasp_instantiation(Model, Instance), 
    ooasp_assoc(Model, Relation, Class1, MinC1, MaxC1, Class2, MinC2, MaxC2), 
    ooasp_isa(Instance, Class1, Obj1), ooasp_isa(Instance, Class2, Obj2)}.

% Propagate associations to subclasses
ooasp_assoc(Model, Relation, ClassA, MinA, MaxA, SubClassB, MinB, MaxB) :- 
    ooasp_assoc(Model, Relation, ClassA, MinA, MaxA, ClassB, MinB, MaxB), 
    ooasp_subclass(Model, SubClassB, ClassB).
ooasp_assoc(Model, Relation, SubClassA, MinA, MaxA, ClassB, MinB, MaxB) :- 
    ooasp_assoc(Model, Relation, ClassA, MinA, MaxA, ClassB, MinB, MaxB), 
    ooasp_subclass(Model, SubClassA, ClassA).

% Finalize associations between non-subclassed leaf classes
final(Model, Relation, ClassA, ClassB) :- 
    ooasp_assoc(Model, Relation, ClassA, MinA, MaxA, ClassB, MinB, MaxB), 
    not ooasp_subclass(Model, _, ClassA), 
    not ooasp_subclass(Model, _, ClassB).

% Assign values to attributes based on their defined type
{ooasp_attribute_value(Instance, Attribute, Object, Value) : 
    ooasp_instantiation(Model, Instance), 
    ooasp_isa(Instance, Class, Object), 
    ooasp_attribute(Model, Class, Attribute, Type),
    valid_value(Type, Value)}.

% Define valid values for each attribute type
valid_value("integer", Value) :- int_value(Value).
valid_value("boolean", Value) :- bool_value(Value).
valid_value("string", Value) :- ooasp_attribute_enum(Model, Class, Attribute, Value).

% Inherit attributes from parent classes to subclasses
ooasp_attribute(Model, SubClass, Attribute, DataType) :- 
    ooasp_attribute(Model, ParentClass, Attribute, DataType), 
    ooasp_subclass(Model, SubClass, ParentClass).

% Validate attributes with conditions
valid_attribute(Model, Instance, Class, Attribute, Value) :-
    ooasp_instantiation(Model, Instance),
    ooasp_attribute(Model, Class, Attribute, DataType),
    ooasp_attribute_value(Instance, Attribute, Object, Value).

% Ensure attribute values respect the minimum constraint
:- valid_attribute(Model, Instance, Class, Attribute, Value),
   ooasp_attribute_minInclusive(Model, Class, Attribute, Min),
   Value < Min.

% Ensure attribute values respect the maximum constraint
:- valid_attribute(Model, Instance, Class, Attribute, Value),
   ooasp_attribute_maxInclusive(Model, Class, Attribute, Max),
   Value > Max.

% Constraints

% Helper rule to count associated objects on the right side of an association
count_associations_right(Instance, Relation, Obj1, Count) :-
    ooasp_instantiation(Model, Instance),
    ooasp_assoc(Model, Relation, ClassA, _, _, ClassB, _, _),
    ooasp_isa(Instance, ClassA, Obj1),
    Count = #count {
        Obj2 : ooasp_isa(Instance, SubClassB, Obj2),
        final(Model, Relation, SubClassA, SubClassB),
        ooasp_associated(Instance, Relation, Obj1, Obj2)
    }.

% Enforce minimum cardinality constraints on the right side
:- ooasp_assoc(Model, Relation, _, _, _, _, MinB, _),
    count_associations_right(Instance, Relation, Obj1, Count),
    Count < MinB.

% Enforce maximum cardinality constraints on the right side
:- ooasp_assoc(Model, Relation, _, _, _, _, _, MaxB),
    count_associations_right(Instance, Relation, Obj1, Count),
    Count > MaxB.

% Helper rule to count associated objects on the left side of an association
count_associations_left(Instance, Relation, Obj2, Count) :-
    ooasp_instantiation(Model, Instance),
    ooasp_assoc(Model, Relation, _, _, _, ClassB, _, _),
    ooasp_isa(Instance, ClassB, Obj2),
    Count = #count {
        Obj1 : ooasp_isa(Instance, SubClassA, Obj1),
        final(Model, Relation, SubClassA, SubClassB),
        ooasp_associated(Instance, Relation, Obj1, Obj2)
    }.

% Enforce minimum cardinality constraints on the left side
:- ooasp_assoc(Model, Relation, _, MinA, _, _, _, _),
    count_associations_left(Instance, Relation, Obj2, Count),
    Count < MinA.

% Enforce maximum cardinality constraints on the left side
:- ooasp_assoc(Model, Relation, _, _, MaxA, _, _, _),
    count_associations_left(Instance, Relation, Obj2, Count),
    Count > MaxA.

% Attribute constraints

% Ensure every attribute has exactly one assigned value
:- ooasp_instantiation(Model, Instance), 
    ooasp_attribute(Model, Class, Attribute, DataType), 
    ooasp_isa(Instance, Class, Object), 
    not ooasp_attribute_value(Instance, Attribute, Object, _).

% Prevent multiple conflicting values for a single attribute
:- ooasp_attribute_value(Instance, Attribute, Object, Value1), 
    ooasp_attribute_value(Instance, Attribute, Object, Value2), 
    Value1 != Value2.

% symmetry breaking and minimization

% instantiation of objects must be done in ascending order with no
% gaps, unless the objects is given as part of the input partial
% instantiation
:- ooasp_isa(I, C, (C,ID1)), not partial(ooasp_isa(I, C, (C,ID1))),
	 possible_instance_id(ID2), ID2 < ID1, not ooasp_isa(I, C, (C,ID2)).

% for each association, the mapping from the first object to the
% second must be monotonic, unless the association is given as part of
% the input partial instantiation
:- ooasp_associated(I,A,O1,O2), not partial(ooasp_associated(I,A,O1,O2)),
	 ooasp_associated(I,A,O3,O4),  not partial(ooasp_associated(I,A,O3,O4)),
	 O1 < O3, O4 < O2.

% minimize number of instantiated objects
#minimize { 1, I, C, O : ooasp_isa(I, C, O) }.

#show ooasp_instantiation/2.
#show ooasp_isa/3.
#show ooasp_associated/4.
#show ooasp_attribute_value/4.

#defined ooasp_attribute_enum/4.
#defined partial/1.
