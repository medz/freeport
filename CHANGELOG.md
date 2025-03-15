## 0.0.2 (Unreleased)

### Bug Fixes

- Fixed resource leak in `isAvailablePort` function by properly closing the Socket after port testing [#2](https://github.com/medz/freeport/pull/2)
- Improved port testing logic to ensure network resources are released after checks

### Improvements

- Refactored the implementation of `isAvailablePort` function with better Future handling
- Enhanced handling of port 0 logic

### Credits

- Thanks to @FourLeafTec for submitting PR #2, fixing the Socket resource leak issue

## 0.0.1

- Initial version.
