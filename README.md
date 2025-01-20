# SkilletUI

A work-in-progress UI engine for LOVE2D, intended for implementation into OpenSMCE at some point!

## On Hold

This project needs severe refactoring and as such is being halted for the next two weeks.
Please do not fork this project, it is broken! Use the commit `d090a20` for the full feature set.
Don't worry; it will come stronger than ever before!

## What's Done

- Nodes
- Widgets attached to Nodes (texts, boxes, sprites, primitive buttons) with some robust functionality
- Node creation, duplication, removal, ordering, parenting
- Node and widget manipulation with a list of properties
- Layout loading and saving
- Fully functional undo/redo stack with working transactions/groups that will be undone at once

## What's To Do

- Support for editing of some types (shortcuts, images, etc.)
- Node animations via timelines
- All the necessary refactoring and stuff
- Integration into OpenSMCE

## About

There is a series of demo layouts which explains the UI decently for now. This section will be filled in at some point...