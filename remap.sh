#!/bin/bash
# remap up down on my usb-remote to space and shift-space
hidutil property --matching '{"ProductID":273,"VendorID":12867}' --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000052,"HIDKeyboardModifierMappingDst":0x70000002C},{"HIDKeyboardModifierMappingSrc":0x700000052,"HIDKeyboardModifierMappingDst":0xE200002C},{"HIDKeyboardModifierMappingSrc":0x700000051,"HIDKeyboardModifierMappingDst":0x70000002C}]}'


# Reset:
# hidutil property --set '{"UserKeyMapping":[]}'
