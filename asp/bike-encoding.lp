#include "./ooasp.lp".

% domain specific constraints below

% The front and back wheels associated with a frame must be of the same size.
:- ooasp_associated(Instance, "Frame_wheel_front", Frame, FrontWheel),
   ooasp_associated(Instance, "Frame_wheel_back", Frame, BackWheel),
   ooasp_attribute_value(_, "wheel_size", FrontWheel, FrontWheelSize),
   ooasp_attribute_value(_, "wheel_size", BackWheel, BackWheelSize),
   FrontWheelSize != BackWheelSize.

% If child_model is selected for a frame, both wheels associated with said frame cannot be larger than 16.
:- ooasp_attribute_value(_, "child_model", Frame, "TRUE"),
   ooasp_associated(Instance, "Frame_wheel_front", Frame, FrontWheel),
   ooasp_attribute_value(_, "wheel_size", FrontWheel, FrontWheelSize),
   FrontWheelSize > 16.
:- ooasp_attribute_value(_, "child_model", Frame, "TRUE"),
   ooasp_associated(Instance, "Frame_wheel_back", Frame, BackWheel),
   ooasp_attribute_value(_, "wheel_size", BackWheel, BackWheelSize),
   BackWheelSize > 16.

% If child_model is selected for a frame, the selected gears for said frame must be derailleur.
:- ooasp_attribute_value(_, "child_model", Frame, "TRUE"),
   ooasp_attribute_value(_, "gears", Frame, Gears),
   Gears != "Derailleur".