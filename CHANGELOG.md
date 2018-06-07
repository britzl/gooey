## Gooey 6.3.1 [britzl released 2018-06-04]
FIX: Text width measurements were wrong when the input text node was scaled. This caused problems with the positioning of the cursor.

## Gooey 6.3.0 [britzl released 2018-05-31]
NEW: Custom themes can now get some common functions set up using gooey.create_theme(). This will return a table with functions to acquire and release focus and to check and set if components are enabled
NEW: Dirty Larry, KenneyBlue and RPG themes now have set_enabled() and is_enabled() functions

## Gooey 6.2.1 [britzl released 2018-05-25]
FIX: gooey.is_enabled() didn't work for hierarchies where not all parents were disabled.

## Gooey 6.2.0 [britzl released 2018-05-23]
NEW: Multi-touch support for clickable components

## Gooey 6.1.0 [britzl released 2018-05-07]
FIX: Marked text handling wasn't working for text input
NEW: The returned data from gooey.input() now contains a `total_width` value containing width of text including marked text.

## Gooey 6.0.3 [britzl released 2018-04-23]
FIX: Typing a space in an input field caused a Lua crash
FIX: Masked text (password) for input fields didn't work
FIX: Issue with text input and focus loss

## Gooey 6.0.2 [britzl released 2018-04-18]
FIX: Buttons and other clickable components was still flagged as clicked even when the click disabled the component

## Gooey 6.0.1 [britzl released 2018-04-17]
FIX: Error when not using input groups

## Gooey 6.0.0 [britzl released 2018-04-16]
NEW: All components have a `consumed` boolean indicating if input could be considered consumed (pressed, released, scroll, input etc)
NEW: Clickable components (button, checkbox, radio button) has a `clicked` boolean
BREAKING CHANGE: radio and input components no longer exposes a `selected_now` value. Use `pressed_now` and `selected` to get the equivalent behaviour.

## Gooey 5.3.0 [britzl released 2018-03-25]
NEW: Mouse wheel support for scrolling of lists

## Gooey 5.2.0 [britzl released 2018-03-23]
NEW: The dynamic lists of the the Dirtylarry, RPG and Kenney themes now call tostring() on the data before setting the text. This means that it's now possible to have complex data models with the use __tostring meta method and other primitive data types than string

## Gooey 5.1.0 [britzl released 2018-03-23]
NEW: gooey.dynamic_list() can now handle that the data changes and grow and shrink the scrollable area as needed

## Gooey 5.0.2 [britzl released 2018-03-23]
FIX: Problem with empty dynamic lists

## Gooey 5.0.1 [britzl released 2018-03-23]
FIX: set_visible() on buttons didn't work

## Gooey 5.0.0 [britzl released 2018-03-23]
CHANGE: gooey.static_list() has changed it's function signature
CHANGE: checkbox.check() renamed to checkbox.set_checked(true|false)
CHANGE: radio.select() renamed to radio.set_selected(true|false)
NEW: set_visible() for button, checkbox and radio

## Gooey 4.0.1 [britzl released 2018-03-23]
FIX: Argument mismatch for gooey.dynamic_list()
FIX: Documentation

## Gooey 4.0.0 [britzl released 2018-03-23]
NEW: gooey.dynamic_list(). Dynamic lists generate and reuse list items automatically. Perfect for showing large data sets.
CHANGE: gooey.list() is deprecated. Use gooey.static_list() instead.
CHANGE: The `items` table of a static list used to contain a list of gui nodes. This has changed so that each list item in the `items` list now is a table containing `root` (the root node of the item), `nodes` (currently unused) and `index`. 

## Gooey 3.2.0 [britzl released 2018-03-19]
NEW: Added support for initial states for radio buttons and checkboxes:

```
dirtylarry.checkbox("checkbox_id").check()
dirtylarry.radio("radio_id").select()
```

## Gooey 3.1.2 [britzl released 2018-02-04]
FIX: Return key on HTML5 generates a carriage return that should be ignored

## Gooey 3.1.1 [britzl released 2018-01-21]
FIX: List item fix for RPG theme

## Gooey 3.1 [britzl released 2018-01-20]
FIX: Radiogroups weren't working properly
NEW: RPG theme

## Gooey 3.0 [britzl released 2017-12-24]
FIX: List items outside the visible area of the list could be picked.

BREAKING CHANGE: gooey.list() now requires a new stencil_id argument (see documentation).

## Gooey 2.1.2 [britzl released 2017-12-09]
FIX: Trailing whitespace weren't measured properly causing the cursor to get an incorrect position. Thanks @nicloay 

## Gooey 2.1.1 [britzl released 2017-12-09]
FIX: Detect reload and clear state if this has happened

## Gooey 2.1 [britzl released 2017-12-09]
NEW: gooey.input() will now correctly ignore keyboard arrow keys.

## Gooey 2.0 [britzl released 2017-12-09]
BREAKING CHANGE: If you're using the predefined Kenney or Dirty Larry themes and the input() function then the last argument to kenney.input() and dirtylarry.input() have changed to an optional config table. Supports ```max_length``` and ```empty_text```.

NEW: Added an optional config table as last argument to gooey.input(). Currently supports ```max_length```.

## Gooey 1.1 [britzl released 2017-10-13]
FIX: Issue with list item selection

## Gooey 1.0 [britzl released 2017-09-28]
First public release

